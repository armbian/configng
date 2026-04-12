#!/usr/bin/env python3
"""
Parse desktop YAML definitions and output bash-compatible variables.

Tier model
----------
Every DE YAML defines its packages under a `tiers:` map with three tiers,
in order of inclusion: minimal -> mid -> full. Each tier is the union of
itself plus all lower tiers, so installing 'full' implies 'mid' implies
'minimal'. Tiers are mandatory; there is no flat top-level `packages:`
list anymore.

common.yaml carries the per-tier defaults that apply to every desktop
(branding, base apps, browser slot). Per-DE YAMLs can add packages to a
tier or remove ones inherited from common, via `tiers.<tier>.packages`
and `tiers.<tier>.packages_remove`.

The literal token `browser` inside any tier resolves to the per-arch
package name from common.yaml's `browser:` map (e.g. chromium on
arm64/amd64/armhf, firefox on riscv64).

Per-DE per-tier per-arch overrides live under `tier_overrides:`, with
the same shape as the release block. Use this to drop packages that
do not exist on a particular arch (e.g. blender/inkscape on armhf).

Per-release deltas (architecture support, packages_remove for the
release as a whole, extra packages per release) keep their existing
top-level `releases:` block — the release filter is orthogonal to the
tier filter and applies after all tier merging is done.

Usage
-----
  parse_desktop_yaml.py <yaml_dir> <de_name> <release> <arch> --tier <tier>
  parse_desktop_yaml.py <yaml_dir> --list <release> <arch>
  parse_desktop_yaml.py <yaml_dir> --list-json <release> <arch>
  parse_desktop_yaml.py <yaml_dir> --primaries <release> <arch>

Output (bash eval-friendly):
  DESKTOP_PACKAGES="pkg1 pkg2 ..."
  DESKTOP_PACKAGES_UNINSTALL="pkg1 pkg2 ..."
  DESKTOP_PRIMARY_PKG="xfce4"
  DESKTOP_DM="lightdm"
  DESKTOP_STATUS="supported"
  DESKTOP_SUPPORTED="yes"
  DESKTOP_DESC="..."
  DESKTOP_TIER="full"
  DESKTOP_REPO_URL="..."       (optional, for custom repos)
  DESKTOP_REPO_KEY_URL="..."   (optional)
  DESKTOP_REPO_KEYRING="..."   (optional)
  DESKTOP_REPO_PREFS_COUNT="N" (optional; 0 when no APT pins)
  DESKTOP_REPO_PREFS_<n>_ORIGIN="..."   (for n in 0..N-1)
  DESKTOP_REPO_PREFS_<n>_SUITE="..."
  DESKTOP_REPO_PREFS_<n>_PRIORITY="1200"
"""

import sys
import os
import yaml


TIERS_IN_ORDER = ("minimal", "mid", "full")


def shell_escape(s):
    """Escape characters that are special inside double-quoted shell strings."""
    return str(s).replace('\\', '\\\\').replace('"', '\\"').replace('$', '\\$').replace('`', '\\`')


def _as_dict(node):
    """Return node if it's a mapping, else {} — tolerates None/empty/wrong-type YAML nodes."""
    return node if isinstance(node, dict) else {}


def _as_list(node):
    """Return node if it's a list, else [] — prevents `arch in 'arm64'` substring matches when 'architectures: arm64' is written instead of '[arm64]'."""
    return node if isinstance(node, list) else []


def _tiers_up_to(target):
    """Return the ordered list of tier names from minimal up to and including target."""
    if target not in TIERS_IN_ORDER:
        print(f"Error: invalid tier '{target}', must be one of {','.join(TIERS_IN_ORDER)}", file=sys.stderr)
        sys.exit(1)
    return list(TIERS_IN_ORDER[:TIERS_IN_ORDER.index(target) + 1])


def _load_yaml(path):
    if not os.path.exists(path):
        return {}
    with open(path) as f:
        data = yaml.safe_load(f)
    return data if isinstance(data, dict) else {}


def load_common(yaml_dir):
    """Load common.yaml as a dict (or empty dict if missing)."""
    return _load_yaml(os.path.join(yaml_dir, "common.yaml"))


def _merge_tier(packages, removes, source, tier):
    """Merge a tier block from a YAML source into packages/removes lists.

    Each tier block looks like:
        tiers:
          <tier>:
            packages: [...]
            packages_remove: [...]   # filter out from earlier tiers / common
    """
    tier_block = _as_dict(_as_dict(source.get("tiers")).get(tier))
    for pkg in _as_list(tier_block.get("packages")):
        if pkg not in packages:
            packages.append(pkg)
    for pkg in _as_list(tier_block.get("packages_remove")):
        if pkg in packages:
            packages.remove(pkg)
        if pkg not in removes:
            removes.append(pkg)


def _resolve_browser(packages, common, release, arch):
    """Substitute the literal token `browser` with the right package per release+arch.

    The browser map in common.yaml has two layers:

      browser:
        amd64: chromium       # default fallback for any release on this arch
        ...
        bookworm:
          amd64: chromium     # per-release per-arch override
          riscv64: firefox-esr

    Lookup order:
      1. browser.<release>.<arch>  (most specific)
      2. browser.<arch>             (per-arch fallback)
      3. drop the token altogether (silently — install proceeds without
         a browser rather than failing on a literal 'browser' apt name)

    The per-release layer is needed because the same arch can resolve
    differently across releases:
      - Debian has 'firefox-esr' but no 'firefox'
      - Ubuntu's 'chromium' is a snap-shim deb that requires snapd
      - 'chromium' isn't built for riscv64 in Debian or Ubuntu
    """
    browser_map = _as_dict(common.get("browser"))
    if "browser" not in packages:
        return
    # Try per-release per-arch first (browser.<release> is a dict of arch->pkg).
    release_map = _as_dict(browser_map.get(release))
    pkg = release_map.get(arch) if release_map else None
    # Fall back to top-level per-arch if no per-release entry exists. Only
    # consider top-level keys that are arch names — skip release-name keys
    # by checking that the value is a string, not a dict.
    if not pkg:
        candidate = browser_map.get(arch)
        if isinstance(candidate, str):
            pkg = candidate
    if not pkg:
        # No browser defined for this combo — silently drop the token rather
        # than passing 'browser' to apt and breaking the install. The dialog
        # layer can warn the user separately if it cares.
        packages.remove("browser")
        return
    idx = packages.index("browser")
    packages[idx] = pkg


def _apply_tier_overrides(packages, source, tier, release, arch):
    """Apply tier_overrides from a YAML source.

    Schema:

      tier_overrides:
        <tier>:
          architectures:
            <arch>:
              packages_remove: [...]   # remove on this arch in any release
          releases:
            <release>:
              architectures:
                <arch>:
                  packages_remove: [...]   # remove on this release+arch combo

    Both layers are applied. Use the per-arch layer for permanent
    arch-wide holes (e.g. blender always missing on armhf), and the
    per-release-per-arch layer for transient holes (e.g. loupe missing
    on bookworm because GNOME 43 didn't have it).
    """
    tier_block = _as_dict(_as_dict(source.get("tier_overrides")).get(tier))

    # Per-arch (any release) layer.
    archs = _as_dict(tier_block.get("architectures"))
    arch_block = _as_dict(archs.get(arch))
    for pkg in _as_list(arch_block.get("packages_remove")):
        if pkg in packages:
            packages.remove(pkg)

    # Per-release-per-arch layer.
    releases = _as_dict(tier_block.get("releases"))
    release_block = _as_dict(releases.get(release))
    release_archs = _as_dict(release_block.get("architectures"))
    release_arch_block = _as_dict(release_archs.get(arch))
    for pkg in _as_list(release_arch_block.get("packages_remove")):
        if pkg in packages:
            packages.remove(pkg)


def _gather_de_pkgs_at_tier(de_data, tier):
    """Collect just the DE-specific packages declared at a tier level (no common, no release).

    Used to identify the primary package — it has to come from the DE's own
    declarations, not from common.yaml (otherwise every DE would share the
    same primary).
    """
    de_pkgs = []
    de_removes = []
    for t in _tiers_up_to(tier):
        _merge_tier(de_pkgs, de_removes, de_data, t)
    return de_pkgs


def parse_desktop(yaml_dir, de_name, release, arch, tier):
    """Parse a single desktop definition at the requested tier."""
    yaml_file = os.path.join(yaml_dir, f"{de_name}.yaml")

    # Reject path traversal: de_name comes from CLI input on a tool that may run
    # as root, so confine the resolved file to yaml_dir.
    abs_yaml_dir = os.path.realpath(yaml_dir)
    abs_yaml_file = os.path.realpath(yaml_file)
    if os.path.commonpath([abs_yaml_dir, abs_yaml_file]) != abs_yaml_dir:
        print(f"Error: invalid desktop name '{de_name}'", file=sys.stderr)
        sys.exit(1)

    if not os.path.exists(yaml_file):
        print(f"Error: no definition for '{de_name}'", file=sys.stderr)
        sys.exit(1)

    de_data = _load_yaml(yaml_file)
    if not de_data:
        print(f"Error: invalid YAML in '{de_name}'", file=sys.stderr)
        sys.exit(1)

    common = load_common(yaml_dir)

    # 1. Walk tiers from minimal -> target. At each step, merge the
    #    tier's packages from common and the DE, then apply both
    #    common and per-DE tier_overrides for that tier. Walking
    #    tier_overrides in the same loop as packages means a hole
    #    declared at the mid tier (e.g. 'loupe' missing on bookworm)
    #    is honoured for ALL tiers >= mid, including full.
    packages = []
    removes = []
    for t in _tiers_up_to(tier):
        _merge_tier(packages, removes, common, t)
        _merge_tier(packages, removes, de_data, t)
        _apply_tier_overrides(packages, common, t, release, arch)
        _apply_tier_overrides(packages, de_data, t, release, arch)

    # 2. Resolve the `browser` virtual token per release+arch.
    _resolve_browser(packages, common, release, arch)

    # 4. Apply the orthogonal release block — packages_remove + packages
    #    declared per release. The release block is independent of tier.
    releases = _as_dict(de_data.get("releases"))
    release_data = _as_dict(releases.get(release))
    supported_archs = _as_list(release_data.get("architectures"))
    is_supported = arch in supported_archs and release in releases

    for pkg in _as_list(release_data.get("packages_remove")):
        if pkg in packages:
            packages.remove(pkg)
    for pkg in _as_list(release_data.get("packages")):
        if pkg not in packages:
            packages.append(pkg)

    # 5. packages_uninstall is collected from minimal-tier (common + DE) +
    #    release-level packages_uninstall. The remove path uses this to purge
    #    packages that get pulled in transitively but we don't want.
    uninstall = []
    for src in (common, de_data):
        tier_block = _as_dict(_as_dict(src.get("tiers")).get("minimal"))
        for pkg in _as_list(tier_block.get("packages_uninstall")):
            if pkg not in uninstall:
                uninstall.append(pkg)
    for pkg in _as_list(release_data.get("packages_uninstall")):
        if pkg not in uninstall:
            uninstall.append(pkg)

    # 6. Primary package: first DE-specific package (not from common) that
    #    survived all the filters. Used by `module_desktops status` to detect
    #    whether the desktop is currently installed.
    de_pkgs_at_tier = _gather_de_pkgs_at_tier(de_data, tier)
    # filter against the same release_remove that applied to the main set
    release_removes = set(_as_list(release_data.get("packages_remove")))
    # also against tier_overrides for this arch
    overrides = _as_dict(_as_dict(_as_dict(de_data.get("tier_overrides")).get(tier)).get("architectures"))
    arch_block = _as_dict(overrides.get(arch))
    arch_removes = set(_as_list(arch_block.get("packages_remove")))
    effective_de_pkgs = [p for p in de_pkgs_at_tier
                         if p not in release_removes and p not in arch_removes]
    primary_pkg = effective_de_pkgs[0] if effective_de_pkgs else ""

    # output bash variables (shell-escaped)
    print(f'DESKTOP_PACKAGES="{shell_escape(" ".join(packages))}"')
    print(f'DESKTOP_PACKAGES_UNINSTALL="{shell_escape(" ".join(uninstall))}"')
    print(f'DESKTOP_PRIMARY_PKG="{shell_escape(primary_pkg)}"')
    print(f'DESKTOP_DM="{shell_escape(de_data.get("display_manager", "lightdm"))}"')
    print(f'DESKTOP_STATUS="{shell_escape(de_data.get("status", "unsupported"))}"')
    print(f'DESKTOP_SUPPORTED="{"yes" if is_supported else "no"}"')
    print(f'DESKTOP_DESC="{shell_escape(de_data.get("description", de_name))}"')
    print(f'DESKTOP_TIER="{shell_escape(tier)}"')

    # repo info
    repo = _as_dict(de_data.get("repo"))
    if repo:
        print(f'DESKTOP_REPO_URL="{shell_escape(repo.get("url", ""))}"')
        print(f'DESKTOP_REPO_KEY_URL="{shell_escape(repo.get("key_url", ""))}"')
        print(f'DESKTOP_REPO_KEYRING="{shell_escape(repo.get("keyring", ""))}"')

        # Optional APT pin preferences written to /etc/apt/preferences.d/<de>.
        # Each entry must be a mapping with origin + suite + priority. The
        # triple (o=<origin>, n=<suite>) is the match criterion; priority
        # is a positive integer (apt treats >1000 as "allow downgrades").
        prefs = _as_list(repo.get("preferences"))
        valid_prefs = []
        for p in prefs:
            p = _as_dict(p)
            origin = str(p.get("origin", "")).strip()
            suite = str(p.get("suite", "")).strip()
            priority = p.get("priority")
            if not origin or not suite or not isinstance(priority, int):
                print(
                    f"Warning: ignoring malformed repo.preferences entry for {de_name}: {p!r}",
                    file=sys.stderr,
                )
                continue
            valid_prefs.append((origin, suite, priority))
        print(f'DESKTOP_REPO_PREFS_COUNT="{len(valid_prefs)}"')
        for i, (origin, suite, priority) in enumerate(valid_prefs):
            print(f'DESKTOP_REPO_PREFS_{i}_ORIGIN="{shell_escape(origin)}"')
            print(f'DESKTOP_REPO_PREFS_{i}_SUITE="{shell_escape(suite)}"')
            print(f'DESKTOP_REPO_PREFS_{i}_PRIORITY="{priority}"')


def list_primaries(yaml_dir, release, arch):
    """Print '<name>\\t<primary_pkg>' for every desktop, applying release overrides.

    Used by `module_desktops installed` to detect whether any desktop is
    currently installed without spawning one Python process per desktop.
    The primary package is computed at the minimal tier — that is enough
    to identify "any tier of this DE is installed".
    """
    common = load_common(yaml_dir)
    for fname in sorted(os.listdir(yaml_dir)):
        if not fname.endswith(".yaml") or fname == "common.yaml":
            continue
        fpath = os.path.join(yaml_dir, fname)
        if not os.path.isfile(fpath):
            continue
        de_data = _load_yaml(fpath)
        if not de_data:
            continue

        de_pkgs = _gather_de_pkgs_at_tier(de_data, "minimal")
        release_data = _as_dict(_as_dict(de_data.get("releases")).get(release))
        release_removes = set(_as_list(release_data.get("packages_remove")))
        # release-block additions COULD contribute the primary if the DE has
        # an empty minimal tier (no DEs do today, but be tolerant)
        for pkg in _as_list(release_data.get("packages")):
            if pkg not in de_pkgs:
                de_pkgs.append(pkg)
        effective = [p for p in de_pkgs if p not in release_removes]
        if effective:
            name = fname[:-len(".yaml")]
            print(f"{name}\t{effective[0]}")


def list_desktops(yaml_dir, release, arch, fmt="tsv"):
    """List all desktops with support status."""
    import json as jsonlib

    entries = []
    for fname in sorted(os.listdir(yaml_dir)):
        if not fname.endswith(".yaml") or fname == "common.yaml":
            continue
        fpath = os.path.join(yaml_dir, fname)
        if not os.path.isfile(fpath):
            continue  # skip directories like 'foo.yaml/' that would IsADirectoryError on open()
        de_data = _load_yaml(fpath)
        if not de_data:
            continue
        name = fname.replace(".yaml", "")
        status = de_data.get("status", "unsupported")
        desc = de_data.get("description", name)
        dm = de_data.get("display_manager", "lightdm")
        releases = _as_dict(de_data.get("releases"))
        release_data = _as_dict(releases.get(release))
        archs = _as_list(release_data.get("architectures"))
        supported = arch in archs and release in releases

        entries.append({
            "name": name,
            "description": desc,
            "display_manager": dm,
            "status": status,
            "supported": supported,
            "architectures": archs,
        })

    # filter to only supported entries
    supported_entries = [e for e in entries if e["supported"]]

    if fmt == "json":
        print(jsonlib.dumps(supported_entries, indent=2))
    else:
        for e in supported_entries:
            arch_str = " ".join(e["architectures"]) if e["architectures"] else "-"
            print(f"{e['name']}\t{e['status']}\t{'yes' if e['supported'] else 'no'}\t{arch_str}")


def _usage():
    prog = sys.argv[0]
    print(f"Usage: {prog} <yaml_dir> <de_name> <release> <arch> --tier <minimal|mid|full>", file=sys.stderr)
    print(f"       {prog} <yaml_dir> --list <release> <arch>", file=sys.stderr)
    print(f"       {prog} <yaml_dir> --list-json <release> <arch>", file=sys.stderr)
    print(f"       {prog} <yaml_dir> --primaries <release> <arch>", file=sys.stderr)
    sys.exit(1)


if __name__ == "__main__":
    if len(sys.argv) < 4:
        _usage()

    yaml_dir = sys.argv[1]

    if sys.argv[2] in ("--list", "--list-json"):
        if len(sys.argv) < 5:
            _usage()
        fmt = "json" if sys.argv[2] == "--list-json" else "tsv"
        list_desktops(yaml_dir, sys.argv[3], sys.argv[4], fmt=fmt)
    elif sys.argv[2] == "--primaries":
        if len(sys.argv) < 5:
            _usage()
        list_primaries(yaml_dir, sys.argv[3], sys.argv[4])
    else:
        # parse_desktop: yaml_dir de_name release arch --tier <tier>
        # The --tier flag is mandatory in the new schema.
        if len(sys.argv) != 7 or sys.argv[5] != "--tier":
            _usage()
        parse_desktop(yaml_dir, sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[6])
