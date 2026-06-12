#!/usr/bin/env bash
#
# runner-job-completed — GitHub Actions ACTIONS_RUNNER_HOOK_JOB_COMPLETED hook.
#
# Armbian builds run inside Docker as root and bind-mount the runner's
# workspace, so they leave files under _work owned by root (cache/sources,
# cache/aptcache, rootfs, …). The *next* job's actions/checkout runs as the
# runner user (no sudo) and then fails to clean the workspace with:
#   EACCES: permission denied, rmdir '.../cache/aptcache/lists'
#
# The GitHub runner process runs continuously and does NOT restart between
# jobs, so systemd start/stop hooks can't fire per-job — but the runner DOES
# invoke ACTIONS_RUNNER_HOOK_JOB_COMPLETED after every job, as the runner
# user. We use that to hand ownership of the root-owned leftovers back to the
# runner user, so the next checkout can clean them.
#
# Wired per runner via ACTIONS_RUNNER_HOOK_JOB_COMPLETED in each runner's
# .env (see module_armbian_runners). Runs as the runner user, which has
# passwordless sudo — required because only root can chown root-owned files.
#
# Selective by design: chown only files NOT already owned by the runner user
# or group, so we touch just the handful of root-owned paths instead of a
# full recursive chown of a multi-GB workspace after every job.

set -u

me_u="$(id -un)"
me_g="$(id -gn)"

# Work-folder root to fix. Prefer the parent of this job's workspace
# (RUNNER_WORKSPACE is .../_work/<repo>), fall back to ~/_work.
work_root=""
if [[ -n "${RUNNER_WORKSPACE:-}" ]]; then
	work_root="$(dirname "${RUNNER_WORKSPACE}")"
fi
[[ -d "${work_root}" ]] || work_root="${HOME}/_work"
[[ -d "${work_root}" ]] || exit 0

# Only chown what isn't already ours. Non-fatal: a hook that exits non-zero
# is just logged by the runner, and the job has already finished anyway.
sudo find "${work_root}" \( ! -user "${me_u}" -o ! -group "${me_g}" \) \
	-exec chown "${me_u}:${me_g}" {} + 2> /dev/null || true

exit 0
