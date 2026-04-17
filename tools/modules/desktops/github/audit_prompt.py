#!/usr/bin/env python3
"""
Format the audit report into a prompt for Claude Code.

Reads the JSON report produced by audit.py and writes a single text
file containing the system instructions + the audit findings. This
file is consumed by anthropic/claude-code-action via the prompt_file
parameter.

Usage
-----
  audit_prompt.py --report audit-report.json --output claude-prompt.txt
"""

import argparse
import json
import sys
from pathlib import Path

PROMPT_TEMPLATE = """\
You are an Armbian configng maintainer. You're auditing the desktop
YAML matrix in tools/modules/desktops/yaml/ for two kinds of problems:

1. Package holes — packages that the resolved DESKTOP_PACKAGES set
   names, but that don't actually exist in the upstream Debian/Ubuntu
   archive for the requested (release, arch). When the install runs,
   apt fails with "E: Unable to locate package <name>".

2. Missing releases — releases that armbian/build supports but no DE
   YAML has a release block for. These desktops can't be installed on
   those releases at all.

Your job is to propose minimal YAML edits that fix ALL the audit
findings without breaking the existing matrix. Specifically:

- Address EVERY missing release in the report, not just one. Each
  missing release needs a release block added to every DE YAML with
  `status: supported`. Do NOT add release blocks to YAMLs with
  `status: community` or `status: unsupported` — those are
  opt-in / vendor-specific and should only grow coverage when a
  maintainer explicitly asks for it.

- For package holes, prefer adding entries to common.yaml's
  tier_overrides block (one place, applies to every DE) rather than
  duplicating the same removal in every per-DE YAML. Use the per-
  release-per-arch nesting (`tier_overrides.<tier>.releases.<release>.
  architectures.<arch>.packages_remove`) for transient holes; use the
  per-arch nesting (`tier_overrides.<tier>.architectures.<arch>.
  packages_remove`) for permanent arch-wide holes.

- For missing releases, add a release block to each DE YAML with
  `status: supported`. Copy the shape from an existing release block
  (e.g. trixie or noble) and adjust per-release deltas only when
  needed. The list of currently-supported DEs can be inferred from
  the YAMLs themselves — do not rely on hardcoded names in these
  instructions, as the support tier of a DE can change over time.

- Always add a comment explaining WHY a hole exists. Future readers
  should be able to tell whether the entry is a transient archive
  hole (that may go away in a later release) or a permanent
  upstream-port limitation.

- Never edit YAML files outside tools/modules/desktops/yaml/.
  Also update common.yaml's browser map if a new release needs
  browser entries.

- Preserve the existing tab/space indentation style. The YAML files
  use 2-space indentation; do not introduce tabs.

- When you finish, provide a summary of what you changed and why.

---

# Desktop matrix audit report

The deterministic audit script (tools/modules/desktops/github/audit.py)
just ran against the current state of tools/modules/desktops/yaml/ and
the list of supported releases in armbian/build's config/distributions/.
Here's what it found.

## Package holes ({hole_count} total)

These are packages that the resolved DESKTOP_PACKAGES set lists but
that don't exist in the upstream archive for that (release, arch).
The install would fail with `E: Unable to locate package` if it ran.

```json
{holes_json}
```

## Missing releases ({missing_release_count} total)

These releases are listed in armbian/build's config/distributions/
with a non-EOS status, but no DE YAML has a release block for them.
Desktops can't be installed on these releases until we add coverage.

```json
{missing_releases_json}
```

## Stats

- {desktops} DE YAMLs scanned
- {scope} (release, arch) combinations in scope
- {package_lookups} package availability checks performed

## What I want from you

Read the existing YAML files first to understand the current pattern,
then make the edits. Address ALL missing releases and ALL package holes
in a single pass. When done, provide a clear summary listing every
file you changed and why.

If there are no holes and no missing releases, say so explicitly
and don't make any edits.
"""


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--report", type=Path, required=True,
                    help="path to the JSON report from audit.py")
    ap.add_argument("--output", type=Path, required=True,
                    help="path to write the formatted prompt")
    args = ap.parse_args()

    if not args.report.is_file():
        print(f"error: --report not found: {args.report}", file=sys.stderr)
        sys.exit(1)

    report = json.loads(args.report.read_text())
    holes = report.get("package_holes", [])
    missing = report.get("missing_releases", [])

    if not holes and not missing:
        # Nothing to do — write a minimal prompt that tells Claude
        # to do nothing. The workflow's 'actionable' gate should
        # have prevented us from reaching here, but belt-and-suspenders.
        args.output.write_text(
            "The desktop matrix audit found no package holes and no "
            "missing releases. No changes are needed. Just confirm "
            "this by saying 'No changes needed.'\n"
        )
        print("audit_prompt.py: no findings, wrote no-op prompt")
        return

    prompt = PROMPT_TEMPLATE.format(
        hole_count=len(holes),
        missing_release_count=len(missing),
        holes_json=json.dumps(holes, indent=2),
        missing_releases_json=json.dumps(missing, indent=2),
        desktops=report["stats"]["desktops"],
        scope=report["stats"]["scope"],
        package_lookups=report["stats"]["package_lookups"],
    )

    args.output.write_text(prompt)
    print(f"audit_prompt.py: wrote {len(prompt)} chars to {args.output}")


if __name__ == "__main__":
    main()
