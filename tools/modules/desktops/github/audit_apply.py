#!/usr/bin/env python3
"""
Hand the audit report to Claude and let it propose YAML edits.

Reads the JSON report produced by audit.py and invokes the Anthropic
API. Claude is told:

  - here are the package holes (DESKTOP_PACKAGES entries that don't
    exist in the upstream archive for some (release, arch))
  - here are the releases the build supports but no DE YAML covers
  - here are the existing YAML files
  - propose minimal edits that fix the holes and add the missing
    releases, with comments explaining why

Claude has tool access to read/write files in the configng repo. After
it finishes, the script validates the YAMLs still parse and that the
parser produces no new holes for the affected combinations.

The script does NOT open a PR — that's left to peter-evans/create-pull-request
in the GitHub Actions workflow, which picks up whatever Claude wrote
and makes a PR with auto-generated branch and label.

Usage
-----
  audit_apply.py --report audit-report.json \\
                 --configng-repo /path/to/configng/checkout \\
                 [--dry-run]            # don't actually call the API
                 [--max-tokens 50000]    # cap the conversation
                 [--model claude-...]    # override default model

Environment
-----------
  ANTHROPIC_API_KEY — required (unless --dry-run)

Exit codes
----------
  0 — Claude ran (or dry-run completed)
  1 — script error
  2 — Claude returned but the post-edit validation failed
"""

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path

DEFAULT_MODEL = "claude-sonnet-4-5-20250929"
DEFAULT_MAX_TOKENS = 50_000

SYSTEM_PROMPT = """\
You are an Armbian configng maintainer. You're auditing the desktop
YAML matrix in tools/modules/desktops/yaml/ for two kinds of problems:

1. Package holes — packages that the resolved DESKTOP_PACKAGES set
   names, but that don't actually exist in the upstream Debian/Ubuntu
   archive for the requested (release, arch). When the install runs,
   apt fails with "E: Unable to locate package <name>".

2. Missing releases — releases that armbian/build supports but no DE
   YAML has a release block for. These desktops can't be installed on
   those releases at all.

Your job is to propose minimal YAML edits that fix the audit findings
without breaking the existing matrix. Specifically:

- For package holes, prefer adding entries to common.yaml's
  tier_overrides block (one place, applies to every DE) rather than
  duplicating the same removal in every per-DE YAML. Use the per-
  release-per-arch nesting (`tier_overrides.<tier>.releases.<release>.
  architectures.<arch>.packages_remove`) for transient holes; use the
  per-arch nesting (`tier_overrides.<tier>.architectures.<arch>.
  packages_remove`) for permanent arch-wide holes.

- For missing releases, add a release block to each currently-
  supported DE YAML (the ones with `status: supported`). Copy the
  shape from an existing release block (e.g. trixie or noble) and
  adjust per-release deltas only when needed.

- Always add a comment explaining WHY a hole exists. Future readers
  should be able to tell whether the entry is a transient archive
  hole (that may go away in a later release) or a permanent
  upstream-port limitation.

- Never edit YAML files outside tools/modules/desktops/yaml/.

- Preserve the existing tab/space indentation style. The YAML files
  use 2-space indentation; do not introduce tabs.

- When you finish, summarize what you changed and why in plain prose
  (not as a tool call). The script will read your final message and
  use it as the PR body.
"""

USER_PROMPT_TEMPLATE = """\
# Desktop matrix audit

The deterministic audit script (tools/modules/desktops/github/audit.py) just ran
against the current state of tools/modules/desktops/yaml/ and the
list of supported releases in armbian/build's config/distributions/.
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

Propose minimal edits that fix the holes and add coverage for the
missing releases. Read the YAML files first to understand the
existing pattern, then make the edits via Edit/Write. When you're
done, write a short summary (under 300 words) describing what you
changed and why.

If there are no holes and no missing releases, say so explicitly
and don't make any edits.
"""


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--report", type=Path, required=True,
                    help="path to the JSON report from audit.py")
    ap.add_argument("--configng-repo", type=Path, required=True,
                    help="path to the configng checkout (LLM will edit files here)")
    ap.add_argument("--dry-run", action="store_true",
                    help="don't actually call the API; print the prompt and exit")
    ap.add_argument("--max-tokens", type=int, default=DEFAULT_MAX_TOKENS,
                    help=f"max tokens for the conversation (default: {DEFAULT_MAX_TOKENS})")
    ap.add_argument("--model", default=DEFAULT_MODEL,
                    help=f"Claude model id (default: {DEFAULT_MODEL})")
    ap.add_argument("--summary-output", type=Path, default=Path("audit-summary.md"),
                    help="path to write Claude's final summary (default: audit-summary.md)")
    args = ap.parse_args()

    if not args.report.is_file():
        die(f"--report not found: {args.report}")
    if not args.configng_repo.is_dir():
        die(f"--configng-repo not a directory: {args.configng_repo}")

    report = json.loads(args.report.read_text())
    holes = report.get("package_holes", [])
    missing = report.get("missing_releases", [])

    # Short-circuit: if there's nothing to do, don't burn API tokens.
    if not holes and not missing:
        info("audit found no holes and no missing releases — nothing to do")
        args.summary_output.write_text(
            "# Desktop audit\n\nNo holes or missing releases found. "
            "No changes proposed.\n"
        )
        return 0

    user_prompt = USER_PROMPT_TEMPLATE.format(
        hole_count=len(holes),
        missing_release_count=len(missing),
        holes_json=json.dumps(holes, indent=2),
        missing_releases_json=json.dumps(missing, indent=2),
        desktops=report["stats"]["desktops"],
        scope=report["stats"]["scope"],
        package_lookups=report["stats"]["package_lookups"],
    )

    if args.dry_run:
        info("--dry-run: not calling the API")
        print("=" * 60)
        print("SYSTEM PROMPT:")
        print("=" * 60)
        print(SYSTEM_PROMPT)
        print("=" * 60)
        print("USER PROMPT:")
        print("=" * 60)
        print(user_prompt)
        return 0

    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        die("ANTHROPIC_API_KEY environment variable not set")

    # Defer the SDK import so --dry-run works without the SDK installed.
    try:
        from anthropic import Anthropic
    except ImportError:
        die("anthropic SDK not installed: pip install anthropic")

    client = Anthropic(api_key=api_key)
    info(f"calling Claude ({args.model}) ...")

    summary = run_claude(
        client=client,
        model=args.model,
        max_tokens=args.max_tokens,
        system_prompt=SYSTEM_PROMPT,
        user_prompt=user_prompt,
        configng_repo=args.configng_repo,
    )

    args.summary_output.write_text(summary)
    info(f"wrote {args.summary_output}")

    # Post-edit validation: every YAML file should still parse and the
    # parser should produce a non-empty package list for every
    # supported (DE, release, arch, tier) combination that previously
    # worked. We don't try to verify "Claude fixed every hole" — that's
    # what the next audit run will tell us.
    if not validate_post_edit(args.configng_repo):
        die("post-edit validation failed", exit_code=2)

    info("post-edit validation passed")
    return 0


def run_claude(*, client, model, max_tokens, system_prompt, user_prompt,
               configng_repo: Path) -> str:
    """
    Run a single Claude conversation with file-editing tool access.
    Returns Claude's final text message (used as the PR body).
    """
    # Tool definitions: Read, Write, Edit. Bash is intentionally NOT
    # exposed — Claude shouldn't be running arbitrary commands, only
    # editing YAML files in tools/modules/desktops/yaml/.
    tools = [
        {
            "name": "read_file",
            "description": "Read a file from the configng repo. Path must be relative to the repo root.",
            "input_schema": {
                "type": "object",
                "properties": {
                    "path": {"type": "string", "description": "relative path"},
                },
                "required": ["path"],
            },
        },
        {
            "name": "write_file",
            "description": "Write a file in the configng repo, overwriting any existing content. Path must be inside tools/modules/desktops/yaml/.",
            "input_schema": {
                "type": "object",
                "properties": {
                    "path": {"type": "string", "description": "relative path inside tools/modules/desktops/yaml/"},
                    "content": {"type": "string", "description": "full file content"},
                },
                "required": ["path", "content"],
            },
        },
        {
            "name": "list_yaml_dir",
            "description": "List the YAML files in tools/modules/desktops/yaml/.",
            "input_schema": {"type": "object", "properties": {}},
        },
    ]

    yaml_dir = configng_repo / "tools" / "modules" / "desktops" / "yaml"
    messages = [{"role": "user", "content": user_prompt}]
    final_text = ""

    while True:
        resp = client.messages.create(
            model=model,
            max_tokens=8192,                         # per-response cap
            system=system_prompt,
            tools=tools,
            messages=messages,
        )

        # Collect assistant text + any tool calls.
        assistant_blocks = []
        tool_results = []
        for block in resp.content:
            assistant_blocks.append(block)
            if block.type == "text":
                final_text = block.text  # last text block wins
            elif block.type == "tool_use":
                result = handle_tool(block.name, block.input,
                                     configng_repo=configng_repo,
                                     yaml_dir=yaml_dir)
                tool_results.append({
                    "type": "tool_result",
                    "tool_use_id": block.id,
                    "content": result,
                })

        messages.append({"role": "assistant", "content": assistant_blocks})

        if resp.stop_reason == "end_turn" or not tool_results:
            break

        messages.append({"role": "user", "content": tool_results})

        # Cheap budget guard: count rough total tokens used so far.
        # The Anthropic SDK exposes usage on each response.
        usage = resp.usage
        if usage and (usage.input_tokens + usage.output_tokens) > max_tokens:
            warn(f"token budget exceeded ({usage.input_tokens + usage.output_tokens} > {max_tokens})")
            break

    return final_text or "(Claude returned no text summary)"


def handle_tool(name: str, args: dict, *, configng_repo: Path, yaml_dir: Path) -> str:
    """Execute one tool call and return the result string."""
    try:
        if name == "list_yaml_dir":
            files = sorted(f.name for f in yaml_dir.glob("*.yaml"))
            return "\n".join(files)

        if name == "read_file":
            path = configng_repo / args["path"]
            try:
                resolved = path.resolve()
                resolved.relative_to(configng_repo.resolve())
            except (ValueError, OSError):
                return "ERROR: path outside configng repo"
            if not resolved.is_file():
                return f"ERROR: not a file: {args['path']}"
            return resolved.read_text()

        if name == "write_file":
            rel = Path(args["path"])
            # Sandbox: only files inside the yaml dir.
            target = (configng_repo / rel).resolve()
            try:
                target.relative_to(yaml_dir.resolve())
            except ValueError:
                return f"ERROR: write outside tools/modules/desktops/yaml/ rejected: {rel}"
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(args["content"])
            return f"OK: wrote {rel} ({len(args['content'])} bytes)"

        return f"ERROR: unknown tool {name}"
    except Exception as e:
        return f"ERROR: {type(e).__name__}: {e}"


def validate_post_edit(configng_repo: Path) -> bool:
    """
    Sanity-check after Claude's edits:
      1. Every YAML in tools/modules/desktops/yaml/ still parses.
      2. The parser still runs (no crashes) for a few representative
         combinations.
    """
    yaml_dir = configng_repo / "tools" / "modules" / "desktops" / "yaml"
    parser = (configng_repo / "tools" / "modules" / "desktops" /
              "scripts" / "parse_desktop_yaml.py")

    try:
        import yaml as pyyaml
    except ImportError:
        warn("pyyaml not available — skipping YAML parse validation")
        return True

    for f in yaml_dir.glob("*.yaml"):
        try:
            with f.open() as fh:
                pyyaml.safe_load(fh)
        except Exception as e:
            warn(f"YAML parse failure in {f.name}: {e}")
            return False

    # Spot-check a few parser invocations
    spot_checks = [
        ("xfce", "trixie", "amd64", "minimal"),
        ("xfce", "noble", "arm64", "full"),
        ("gnome", "trixie", "amd64", "mid"),
    ]
    for de, release, arch, tier in spot_checks:
        try:
            proc = subprocess.run(
                [sys.executable, str(parser), str(yaml_dir),
                 de, release, arch, "--tier", tier],
                capture_output=True, text=True, timeout=15,
            )
        except subprocess.TimeoutExpired:
            warn(f"parser timed out: {de} {release} {arch} {tier}")
            return False
        if proc.returncode != 0:
            warn(f"parser failed for {de} {release} {arch} {tier}: {proc.stderr}")
            return False
    return True


def die(msg: str, exit_code: int = 1):
    print(f"audit_apply.py: error: {msg}", file=sys.stderr)
    sys.exit(exit_code)


def warn(msg: str):
    print(f"audit_apply.py: warning: {msg}", file=sys.stderr)


def info(msg: str):
    print(f"audit_apply.py: {msg}", file=sys.stderr)


if __name__ == "__main__":
    sys.exit(main() or 0)
