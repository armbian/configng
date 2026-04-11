#!/usr/bin/env python3
"""
Desktop coverage audit.

Walks the desktop YAML matrix in tools/modules/desktops/yaml/ against
the list of supported releases from armbian/build's config/distributions/
and against the actual published binary packages on
packages.debian.org / packages.ubuntu.com.

Outputs a JSON report describing two things:

  1. "missing_releases" — releases declared in armbian/build that no DE
     YAML covers yet (or covers only partially across the arches build
     supports). These are candidates for "add a new release block to
     each DE YAML".

  2. "package_holes" — packages that DESKTOP_PACKAGES (the resolved
     install set) names but that don't exist in the upstream archive
     for the requested (release, arch). These would cause apt to fail
     with 'E: Unable to locate package' if the install actually ran.

The audit is deterministic: package availability is determined by
fetching packages.debian.org / packages.ubuntu.com and parsing the
HTTP response. No LLM is involved here.

A second script (audit_apply.py) consumes this JSON and uses the
Claude API to propose YAML edits.

Usage
-----
  audit.py --build-repo /path/to/build/checkout \\
           --configng-repo /path/to/configng/checkout \\
           --output report.json

  audit.py ... --tier minimal           # only audit one tier
  audit.py ... --release noble           # only audit one release
  audit.py ... --skip-network            # don't actually fetch, dry-run

Exit codes
----------
  0 — audit ran successfully (regardless of whether holes were found)
  1 — script error (missing inputs, parser failure, etc.)
"""

import argparse
import json
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

# Mapping of release codename -> distro family. Used to pick the right
# packages.* host. Releases not in this map are skipped with a warning
# (the audit only knows how to check Debian and Ubuntu archives).
DEBIAN_RELEASES = {"bookworm", "trixie", "forky", "sid"}
UBUNTU_RELEASES = {"jammy", "noble", "oracular", "plucky", "questing", "resolute"}
SKIP_RELEASES = {"buster", "bullseye", "focal"}  # EOS, never going to gain a desktop

# Architecture name normalization. armbian/build uses 'amd64' / 'arm64'
# / 'armhf' / 'riscv64'. packages.debian.org uses the same names.
SUPPORTED_ARCHES = {"amd64", "arm64", "armhf", "riscv64"}

# How long to wait between HTTP requests to one host. Be polite to
# packages.debian.org / packages.ubuntu.com.
HTTP_DELAY_SECONDS = 0.1
HTTP_TIMEOUT_SECONDS = 15
HTTP_RETRIES = 2
USER_AGENT = "armbian-configng-desktop-audit/1.0 (+https://github.com/armbian/configng)"


# ----------------------------------------------------------------------
# armbian/build distributions parser
# ----------------------------------------------------------------------

def parse_build_distributions(build_repo: Path) -> dict:
    """
    Read armbian/build's config/distributions/ directory and return a
    map of {release_codename: {name, support, architectures}}.

    Each release is a directory containing the files: name, support,
    architectures (CSV), order, upgrade.
    """
    dist_dir = build_repo / "config" / "distributions"
    if not dist_dir.is_dir():
        die(f"build repo distributions dir not found at {dist_dir}")

    out = {}
    for child in sorted(dist_dir.iterdir()):
        if not child.is_dir():
            continue
        codename = child.name
        try:
            name = (child / "name").read_text().strip()
            support = (child / "support").read_text().strip()
            arches_csv = (child / "architectures").read_text().strip()
        except FileNotFoundError:
            # malformed entry, skip
            continue
        out[codename] = {
            "name": name,
            "support": support,
            "architectures": [a.strip() for a in arches_csv.split(",") if a.strip()],
        }
    return out


# ----------------------------------------------------------------------
# Desktop YAML matrix
# ----------------------------------------------------------------------

def list_desktops(yaml_dir: Path) -> list[str]:
    """Return the list of DE names declared in tools/modules/desktops/yaml/."""
    return sorted(
        f.stem for f in yaml_dir.glob("*.yaml")
        if f.name != "common.yaml"
    )


def parse_desktop_yaml(yaml_dir: Path, parser_path: Path,
                      de: str, release: str, arch: str, tier: str) -> dict:
    """
    Run parse_desktop_yaml.py and capture the DESKTOP_* output as a dict.
    Returns {} on parse failure (with stderr printed).
    """
    cmd = [
        sys.executable, str(parser_path), str(yaml_dir),
        de, release, arch, "--tier", tier,
    ]
    try:
        proc = subprocess.run(
            cmd, capture_output=True, text=True, check=False, timeout=30,
        )
    except subprocess.TimeoutExpired:
        warn(f"parser timed out: {de} {release} {arch} {tier}")
        return {}

    if proc.returncode != 0:
        # parser refuses to run for various legitimate reasons (release
        # block missing, arch not supported by the YAML, etc.); we
        # don't treat this as a script failure.
        return {}

    out = {}
    for line in proc.stdout.splitlines():
        m = re.match(r'^([A-Z_]+)="(.*)"$', line)
        if m:
            out[m.group(1)] = m.group(2)
    return out


# ----------------------------------------------------------------------
# Package availability
# ----------------------------------------------------------------------

def package_url(release: str, arch: str, package: str) -> str | None:
    """Return the canonical packages.debian.org / packages.ubuntu.com URL."""
    if release in DEBIAN_RELEASES:
        return f"https://packages.debian.org/{release}/{arch}/{package}"
    if release in UBUNTU_RELEASES:
        return f"https://packages.ubuntu.com/{release}/{arch}/{package}"
    return None


def package_exists(release: str, arch: str, package: str,
                   cache: dict, skip_network: bool) -> bool | None:
    """
    True if the package is published in (release, arch). False if not.
    None if we couldn't tell (unknown release, network error, etc.).

    Results are memoised in `cache` to avoid hammering the archive.
    """
    key = (release, arch, package)
    if key in cache:
        return cache[key]

    url = package_url(release, arch, package)
    if url is None:
        cache[key] = None
        return None

    if skip_network:
        cache[key] = None
        return None

    last_err = None
    for attempt in range(HTTP_RETRIES + 1):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
            with urllib.request.urlopen(req, timeout=HTTP_TIMEOUT_SECONDS) as resp:
                # 200 = page exists. packages.debian.org returns 200
                # with a "no such package" body for missing packages,
                # so we have to peek at the body.
                body = resp.read(8192).decode("utf-8", errors="replace")
                exists = "No such package" not in body and "is not available" not in body
                cache[key] = exists
                time.sleep(HTTP_DELAY_SECONDS)
                return exists
        except urllib.error.HTTPError as e:
            if e.code == 404:
                cache[key] = False
                return False
            last_err = e
        except (urllib.error.URLError, TimeoutError) as e:
            last_err = e
        # backoff before retry
        time.sleep(0.5 * (attempt + 1))

    warn(f"network error checking {package} on {release}/{arch}: {last_err}")
    cache[key] = None
    return None


# ----------------------------------------------------------------------
# Audit logic
# ----------------------------------------------------------------------

def audit(build_repo: Path, configng_repo: Path,
          tier_filter: str | None, release_filter: str | None,
          skip_network: bool) -> dict:
    distributions = parse_build_distributions(build_repo)
    yaml_dir = configng_repo / "tools" / "modules" / "desktops" / "yaml"
    parser_path = (configng_repo / "tools" / "modules" / "desktops" /
                   "scripts" / "parse_desktop_yaml.py")
    if not parser_path.exists():
        die(f"parser not found at {parser_path}")

    desktops = list_desktops(yaml_dir)
    info(f"found {len(desktops)} DE YAMLs: {', '.join(desktops)}")

    # Walk the build distributions and figure out which (release, arch)
    # pairs are in scope for the audit. Skip end-of-support releases.
    in_scope = []
    for codename, meta in distributions.items():
        if codename in SKIP_RELEASES:
            continue
        if release_filter and codename != release_filter:
            continue
        if codename not in DEBIAN_RELEASES and codename not in UBUNTU_RELEASES:
            warn(f"skipping {codename}: unknown release family")
            continue
        for arch in meta["architectures"]:
            if arch not in SUPPORTED_ARCHES:
                continue
            in_scope.append((codename, arch, meta["support"]))

    # Find releases that build supports but no DE YAML covers. We use
    # the set of release names that appear in any DE YAML's `releases:`
    # block as the universe.
    yaml_releases = set()
    for de in desktops:
        for tier in ("minimal",):  # release block is orthogonal to tier
            data = parse_desktop_yaml(yaml_dir, parser_path, de,
                                      release="trixie", arch="amd64", tier=tier)
            # we only care about side-effect of importing the YAML, but
            # we can't easily extract `releases` keys from the parser's
            # output. Read the YAML directly instead.
        try:
            import yaml as pyyaml
            with (yaml_dir / f"{de}.yaml").open() as f:
                doc = pyyaml.safe_load(f) or {}
            for rel in (doc.get("releases") or {}).keys():
                yaml_releases.add(rel)
        except Exception as e:
            warn(f"could not load {de}.yaml: {e}")

    missing_releases = []
    for codename, _arch, support in in_scope:
        if codename not in yaml_releases:
            # Skip end-of-support releases — there's no point asking
            # the LLM to add YAML coverage for a release the build is
            # winding down. Only flag releases the build is actively
            # maintaining.
            if support in ("eos", "wip"):
                continue
            entry = {
                "release": codename,
                "support_status": support,
                "name": distributions[codename]["name"],
                "architectures": distributions[codename]["architectures"],
            }
            if entry not in missing_releases:
                missing_releases.append(entry)

    # Audit packages: for every supported DE × in-scope (release, arch)
    # × tier, parse the YAML and check each resolved package against
    # the upstream archive. Cache results aggressively — most packages
    # are shared across DEs.
    cache = {}
    package_holes = []  # list of {de, release, arch, tier, missing: [pkgs]}

    tiers_to_check = [tier_filter] if tier_filter else ["minimal", "mid", "full"]

    for de in desktops:
        for codename, arch, _support in in_scope:
            if codename not in yaml_releases:
                # no point checking a release that the YAML doesn't list
                # — there are no resolved packages for it.
                continue
            for tier in tiers_to_check:
                parsed = parse_desktop_yaml(yaml_dir, parser_path, de,
                                            codename, arch, tier)
                if not parsed.get("DESKTOP_SUPPORTED") == "yes":
                    # the YAML doesn't support this (DE, release, arch);
                    # skip it.
                    continue
                pkgs = parsed.get("DESKTOP_PACKAGES", "").split()
                missing = []
                for pkg in pkgs:
                    exists = package_exists(codename, arch, pkg, cache, skip_network)
                    if exists is False:
                        missing.append(pkg)
                if missing:
                    package_holes.append({
                        "de": de,
                        "release": codename,
                        "arch": arch,
                        "tier": tier,
                        "missing": missing,
                    })
                    info(f"hole: {de} {codename}/{arch} {tier} → {', '.join(missing)}")

    return {
        "scanned_releases": sorted(yaml_releases),
        "build_distributions": distributions,
        "missing_releases": missing_releases,
        "package_holes": package_holes,
        "stats": {
            "desktops": len(desktops),
            "scope": len(in_scope),
            "holes": len(package_holes),
            "package_lookups": len(cache),
        },
    }


# ----------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------

def die(msg: str):
    print(f"audit.py: error: {msg}", file=sys.stderr)
    sys.exit(1)


def warn(msg: str):
    print(f"audit.py: warning: {msg}", file=sys.stderr)


def info(msg: str):
    print(f"audit.py: {msg}", file=sys.stderr)


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--build-repo", type=Path, required=True,
                    help="path to an armbian/build checkout")
    ap.add_argument("--configng-repo", type=Path, required=True,
                    help="path to an armbian/configng checkout")
    ap.add_argument("--output", type=Path, default=Path("audit-report.json"),
                    help="output JSON report path (default: audit-report.json)")
    ap.add_argument("--tier", choices=["minimal", "mid", "full"], default=None,
                    help="audit only this tier (default: all three)")
    ap.add_argument("--release", default=None,
                    help="audit only this release codename")
    ap.add_argument("--skip-network", action="store_true",
                    help="don't actually fetch packages.* — useful for dry runs")
    args = ap.parse_args()

    if not args.build_repo.is_dir():
        die(f"--build-repo not a directory: {args.build_repo}")
    if not args.configng_repo.is_dir():
        die(f"--configng-repo not a directory: {args.configng_repo}")

    report = audit(args.build_repo, args.configng_repo,
                   args.tier, args.release, args.skip_network)

    args.output.write_text(json.dumps(report, indent=2))
    info(f"wrote {args.output}")
    info(f"summary: {report['stats']['holes']} package holes, "
         f"{len(report['missing_releases'])} releases not covered by any DE YAML")


if __name__ == "__main__":
    main()
