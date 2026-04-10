#!/usr/bin/env python3
"""
Parse desktop YAML definitions and output bash-compatible variables.

Usage:
  parse_desktop_yaml.py <yaml_dir> <de_name> <release> <arch>
  parse_desktop_yaml.py <yaml_dir> --list <release> <arch>

Output (bash eval-friendly):
  DESKTOP_PACKAGES="pkg1 pkg2 ..."
  DESKTOP_PACKAGES_UNINSTALL="pkg1 pkg2 ..."
  DESKTOP_DM="lightdm"
  DESKTOP_STATUS="supported"
  DESKTOP_SUPPORTED="yes"
  DESKTOP_DESC="XFCE - lightweight and fast desktop"
  DESKTOP_REPO_URL="..."       (optional, for custom repos)
  DESKTOP_REPO_KEY_URL="..."   (optional)
  DESKTOP_REPO_KEYRING="..."   (optional)
"""

import sys
import os
import yaml


def shell_escape(s):
    """Escape characters that are special inside double-quoted shell strings."""
    return str(s).replace('\\', '\\\\').replace('"', '\\"').replace('$', '\\$').replace('`', '\\`')


def _as_dict(node):
    """Return node if it's a mapping, else {} — tolerates None/empty/wrong-type YAML nodes."""
    return node if isinstance(node, dict) else {}


def _as_list(node):
    """Return node if it's a list, else [] — prevents `arch in 'arm64'` substring matches when 'architectures: arm64' is written instead of '[arm64]'."""
    return node if isinstance(node, list) else []


def load_common(yaml_dir):
    """Load common packages from common.yaml."""
    common_file = os.path.join(yaml_dir, "common.yaml")
    if not os.path.exists(common_file):
        return []
    with open(common_file) as f:
        data = yaml.safe_load(f)
    if not isinstance(data, dict):
        print(f"Error: common.yaml must be a mapping (root object), got {type(data).__name__}", file=sys.stderr)
        sys.exit(1)
    pkgs = data.get("packages", [])
    if not isinstance(pkgs, list):
        print(f"Error: 'packages' in common.yaml must be a list, got {type(pkgs).__name__}", file=sys.stderr)
        sys.exit(1)
    return pkgs


def parse_desktop(yaml_dir, de_name, release, arch):
    """Parse a single desktop definition."""
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

    with open(yaml_file) as f:
        data = yaml.safe_load(f)

    if not isinstance(data, dict):
        print(f"Error: invalid YAML in '{de_name}'", file=sys.stderr)
        sys.exit(1)

    # validate package lists are actually lists
    if not isinstance(data.get("packages", []), list):
        print(f"Error: 'packages' must be a list in '{de_name}'", file=sys.stderr)
        sys.exit(1)

    de_pkgs = data.get("packages", [])

    # common + base packages
    common_pkgs = load_common(yaml_dir)
    base_pkgs = common_pkgs + de_pkgs
    base_uninstall = _as_list(data.get("packages_uninstall"))

    # release-specific overrides
    releases = _as_dict(data.get("releases"))
    release_data = _as_dict(releases.get(release))

    # architecture support
    supported_archs = _as_list(release_data.get("architectures"))
    is_supported = arch in supported_archs and release in releases

    # merge release overrides
    release_pkgs = _as_list(release_data.get("packages"))
    release_remove = _as_list(release_data.get("packages_remove"))
    release_uninstall = _as_list(release_data.get("packages_uninstall"))

    # combine and filter
    all_pkgs = base_pkgs + release_pkgs
    all_uninstall = base_uninstall + release_uninstall
    final_pkgs = [p for p in all_pkgs if p not in release_remove]

    # primary package: first DE-specific package that survives release_remove.
    # Must NOT come from final_pkgs[0] (that's a common.yaml package and would
    # be identical across every desktop, breaking status/remove).
    effective_de_pkgs = [p for p in (de_pkgs + release_pkgs) if p not in release_remove]
    primary_pkg = effective_de_pkgs[0] if effective_de_pkgs else ""

    # output bash variables (shell-escaped)
    print(f'DESKTOP_PACKAGES="{shell_escape(" ".join(final_pkgs))}"')
    print(f'DESKTOP_PACKAGES_UNINSTALL="{shell_escape(" ".join(all_uninstall))}"')
    print(f'DESKTOP_PRIMARY_PKG="{shell_escape(primary_pkg)}"')
    print(f'DESKTOP_DM="{shell_escape(data.get("display_manager", "lightdm"))}"')
    print(f'DESKTOP_STATUS="{shell_escape(data.get("status", "unsupported"))}"')
    print(f'DESKTOP_SUPPORTED="{"yes" if is_supported else "no"}"')
    print(f'DESKTOP_DESC="{shell_escape(data.get("description", de_name))}"')

    # repo info
    repo = _as_dict(data.get("repo"))
    if repo:
        print(f'DESKTOP_REPO_URL="{shell_escape(repo.get("url", ""))}"')
        print(f'DESKTOP_REPO_KEY_URL="{shell_escape(repo.get("key_url", ""))}"')
        print(f'DESKTOP_REPO_KEYRING="{shell_escape(repo.get("keyring", ""))}"')


def list_primaries(yaml_dir, release, arch):
    """Print '<name>\\t<primary_pkg>' for every desktop, applying release overrides.

    Used by `module_desktops installed` to detect whether any desktop is currently
    installed without spawning one Python process per desktop.
    """
    for fname in sorted(os.listdir(yaml_dir)):
        if not fname.endswith(".yaml") or fname == "common.yaml":
            continue
        fpath = os.path.join(yaml_dir, fname)
        if not os.path.isfile(fpath):
            continue
        with open(fpath) as f:
            data = yaml.safe_load(f)
        if not isinstance(data, dict):
            continue
        de_pkgs = data.get("packages", [])
        if not isinstance(de_pkgs, list):
            continue
        release_data = _as_dict(_as_dict(data.get("releases")).get(release))
        release_pkgs = _as_list(release_data.get("packages"))
        release_remove = _as_list(release_data.get("packages_remove"))
        # Same logic as parse_desktop's primary_pkg: first DE-specific package
        # that survives release_remove. Common packages are excluded.
        effective = [p for p in (de_pkgs + release_pkgs) if p not in release_remove]
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
        with open(fpath) as f:
            data = yaml.safe_load(f)
        if not isinstance(data, dict):
            continue
        name = fname.replace(".yaml", "")
        status = data.get("status", "unsupported")
        desc = data.get("description", name)
        dm = data.get("display_manager", "lightdm")
        releases = _as_dict(data.get("releases"))
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


if __name__ == "__main__":
    if len(sys.argv) < 4:
        print(f"Usage: {sys.argv[0]} <yaml_dir> <de_name> <release> <arch>", file=sys.stderr)
        print(f"       {sys.argv[0]} <yaml_dir> --list <release> <arch>", file=sys.stderr)
        print(f"       {sys.argv[0]} <yaml_dir> --primaries <release> <arch>", file=sys.stderr)
        sys.exit(1)

    yaml_dir = sys.argv[1]

    if sys.argv[2] in ("--list", "--list-json"):
        if len(sys.argv) < 5:
            print(f"Usage: {sys.argv[0]} <yaml_dir> {sys.argv[2]} <release> <arch>", file=sys.stderr)
            sys.exit(1)
        fmt = "json" if sys.argv[2] == "--list-json" else "tsv"
        list_desktops(yaml_dir, sys.argv[3], sys.argv[4], fmt=fmt)
    elif sys.argv[2] == "--primaries":
        if len(sys.argv) < 5:
            print(f"Usage: {sys.argv[0]} <yaml_dir> --primaries <release> <arch>", file=sys.stderr)
            sys.exit(1)
        list_primaries(yaml_dir, sys.argv[3], sys.argv[4])
    else:
        if len(sys.argv) < 5:
            print(f"Usage: {sys.argv[0]} <yaml_dir> <de_name> <release> <arch>", file=sys.stderr)
            sys.exit(1)
        parse_desktop(yaml_dir, sys.argv[2], sys.argv[3], sys.argv[4])
