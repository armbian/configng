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


def load_common(yaml_dir):
    """Load common packages from common.yaml."""
    common_file = os.path.join(yaml_dir, "common.yaml")
    if os.path.exists(common_file):
        with open(common_file) as f:
            data = yaml.safe_load(f)
        return data.get("packages", [])
    return []


def parse_desktop(yaml_dir, de_name, release, arch):
    """Parse a single desktop definition."""
    yaml_file = os.path.join(yaml_dir, f"{de_name}.yaml")
    if not os.path.exists(yaml_file):
        print(f"Error: no definition for '{de_name}'", file=sys.stderr)
        sys.exit(1)

    with open(yaml_file) as f:
        data = yaml.safe_load(f)

    # common + base packages
    common_pkgs = load_common(yaml_dir)
    base_pkgs = common_pkgs + data.get("packages", [])
    base_uninstall = data.get("packages_uninstall", [])

    # release-specific overrides
    releases = data.get("releases", {})
    release_data = releases.get(release, {})

    # architecture support
    supported_archs = release_data.get("architectures", [])
    is_supported = arch in supported_archs and release in releases

    # merge release overrides
    release_pkgs = release_data.get("packages", [])
    release_remove = release_data.get("packages_remove", [])
    release_uninstall = release_data.get("packages_uninstall", [])

    # combine and filter
    all_pkgs = base_pkgs + release_pkgs
    all_uninstall = base_uninstall + release_uninstall
    final_pkgs = [p for p in all_pkgs if p not in release_remove]

    # output bash variables
    print(f'DESKTOP_PACKAGES="{" ".join(final_pkgs)}"')
    print(f'DESKTOP_PACKAGES_UNINSTALL="{" ".join(all_uninstall)}"')
    print(f'DESKTOP_DM="{data.get("display_manager", "lightdm")}"')
    print(f'DESKTOP_STATUS="{data.get("status", "unsupported")}"')
    print(f'DESKTOP_SUPPORTED="{"yes" if is_supported else "no"}"')
    print(f'DESKTOP_DESC="{data.get("description", de_name)}"')

    # repo info
    repo = data.get("repo", {})
    if repo:
        print(f'DESKTOP_REPO_URL="{repo.get("url", "")}"')
        print(f'DESKTOP_REPO_KEY_URL="{repo.get("key_url", "")}"')
        print(f'DESKTOP_REPO_KEYRING="{repo.get("keyring", "")}"')


def list_desktops(yaml_dir, release, arch, fmt="tsv"):
    """List all desktops with support status."""
    import json as jsonlib

    entries = []
    for fname in sorted(os.listdir(yaml_dir)):
        if not fname.endswith(".yaml") or fname == "common.yaml":
            continue
        fpath = os.path.join(yaml_dir, fname)
        with open(fpath) as f:
            data = yaml.safe_load(f)
        name = fname.replace(".yaml", "")
        status = data.get("status", "unsupported")
        desc = data.get("description", name)
        dm = data.get("display_manager", "lightdm")
        releases = data.get("releases", {})
        release_data = releases.get(release, {})
        archs = release_data.get("architectures", [])
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
        sys.exit(1)

    yaml_dir = sys.argv[1]

    if sys.argv[2] == "--list":
        list_desktops(yaml_dir, sys.argv[3], sys.argv[4])
    elif sys.argv[2] == "--list-json":
        list_desktops(yaml_dir, sys.argv[3], sys.argv[4], fmt="json")
    else:
        parse_desktop(yaml_dir, sys.argv[2], sys.argv[3], sys.argv[4])
