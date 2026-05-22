# runner-cleanup

Maintenance for self-hosted GitHub Actions runner hosts provisioned by
`module_armbian_runners`. Wipes per-runner work directories and prunes
Docker (containers, untagged images, unused volumes / networks / build
cache, and any image not in the operator-curated allowlist).

## Safety model

Per-operation, not per-host — busy fleets keep getting cleaned:

| Step | Behaviour with busy runners |
|------|-----------------------------|
| `_work/` wipe of each runner | Only IDLE runners, and only those NOT in `KEEP_RUNNERS_WORK`. For each one: `systemctl stop <unit>` → `find -delete` → `systemctl start <unit>`. The stop closes the window where the listener could accept a new job mid-wipe; systemd's graceful stop waits for any job that lands between our `pgrep` and the `stop` to finish, so no in-flight job is aborted. Unit name is discovered by grepping `User=` in `/etc/systemd/system/actions.runner.*.service`; if no unit is found (runner under a different supervisor) the wipe runs without stop/start with a warning. |
| `docker image rm` (per image not in `KEEP_IMAGES` + not in any container) | Always runs. Docker rejects removal of in-use images, so a missed entry just logs a "skipped — still in use" line. |
| `docker container prune -f` | Always runs. Only touches stopped containers. |
| `docker image prune -f` (dangling) | Always runs. Only `<none>:<none>`. |
| `docker network prune -f` | Always runs. Only unused networks. |
| `docker builder prune -af` | Always runs. Drops build cache — cold-cache slowdown for an in-flight build, doesn't break it. |
| `docker volume prune -af` | Skipped while ANY runner is busy. A volume between job steps can briefly look unused; `-a` would remove it. Picked up the next pass once the fleet is idle. |
| `apt-get clean` | Always runs. Just deletes the `/var/cache/apt/archives/*.deb` download cache. Safe; jobs don't depend on it. |
| `journalctl --vacuum-size=$JOURNAL_MAX_SIZE` (default `500M`) | Always runs. Drops the oldest journal entries beyond the cap. Recent history stays. |
| Prune `~/_diag/{Runner,Worker}_*.log` older than `$DIAG_LOG_KEEP_DAYS` days (default `14`) | Always runs. Diag logs are per-past-job traces; the runner rotates them too lazily. |
| Truncate `/var/lib/docker/containers/*/*-json.log` larger than `$DOCKER_LOG_MAX_MB` MB (default `512`) | Always runs. Long-running containers (SWAG, openssh-server) often accumulate multi-GB logs. Truncating mid-flight is safe — Docker keeps writing to the same fd. |
| `apt-get autoremove --purge -y` | OFF by default. Set `RUN_APT_AUTOREMOVE=1` in conf to enable. Can rarely remove a package the operator wanted kept but forgot to `apt-mark manual`. Strips orphans + old kernels. |
| Reap stuck `Runner.Worker` processes alive longer than `$RUNNER_JOB_MAX_HOURS` (default `4`) | Always runs, BEFORE the busy/idle partition. SIGTERM → 5 s grace → SIGKILL if still alive. The Listener requeues the abandoned job. Targets the failure mode where a Worker deadlocks (hung artifact upload, network black hole) and holds GBs of RAM indefinitely while the Listener reports the job as "still running". |

So a typical pass on a 24-runner host with 4 idle: 4 work-dirs wiped, all the safe Docker prunes run, the aggressive volume prune deferred to a quieter hour, and the system-level caches always get the trim regardless of runner state. The systemwide bits are usually the difference between "ran out of disk overnight" and "trending flat".

## Schedule

`runner-cleanup.timer` fires **hourly** with up to a 10-minute random
delay (so a fleet doesn't all hit Docker Hub / ghcr at the same
second). All the safety gates above mean most runs no-op against an
idle workload in under a second; meaningful work only fires when
there's actually something to clean. On hosts that "often run out of
space" the higher cadence catches the long-tail accumulation
(container logs, journal, apt cache) before it bites.

## Concurrency + watchdog

Two layers of protection against a stuck or runaway cleanup:

- **Single-instance flock** (`/var/lock/runner-cleanup.lock`).
  Belt-and-suspenders to systemd's natural same-unit-can't-run-twice
  behaviour — also covers the case where an admin runs
  `./runner-cleanup` manually while a timer-triggered pass is in
  flight. Second invocation exits cleanly with rc=0.

- **`RuntimeMaxSec=30min`** on `runner-cleanup.service`. A run that's
  somehow exceeded the timeout is sent SIGTERM, then SIGKILL after
  a 30 s `TimeoutStopSec` grace window. An in-script EXIT trap
  ensures any runner whose unit was stopped but not yet restarted
  is brought back online before the script exits, so a kill mid-wipe
  doesn't leave a runner offline.

## Files

| File | Destination | Mode |
|------|-------------|------|
| `runner-cleanup`         | `/usr/local/sbin/runner-cleanup`              | 0755 |
| `runner-cleanup.conf`    | `/etc/armbian/runner-cleanup.conf`            | 0644 |
| `runner-cleanup.service` | `/etc/systemd/system/runner-cleanup.service`  | 0644 |
| `runner-cleanup.timer`   | `/etc/systemd/system/runner-cleanup.timer`    | 0644 |

## Install

The script + systemd units are overwritten on every install (that's
where fixes land). The `runner-cleanup.conf` is left alone if it
already exists — your `KEEP_IMAGES` / `KEEP_RUNNERS_WORK` edits
survive an upgrade. The template is dropped next to it as
`runner-cleanup.conf.dist` so you can diff and merge by hand.

```sh
# Script + systemd units: always overwrite.
sudo install -m 0755 runner-cleanup         /usr/local/sbin/runner-cleanup
sudo install -m 0644 runner-cleanup.service /etc/systemd/system/runner-cleanup.service
sudo install -m 0644 runner-cleanup.timer   /etc/systemd/system/runner-cleanup.timer

# Config: only install if absent. Template always goes to .dist
# alongside so a future maintainer can spot new defaults.
sudo install -d /etc/armbian
if [ ! -e /etc/armbian/runner-cleanup.conf ]; then
    sudo install -m 0644 runner-cleanup.conf /etc/armbian/runner-cleanup.conf
fi
sudo install -m 0644 runner-cleanup.conf /etc/armbian/runner-cleanup.conf.dist

sudo systemctl daemon-reload
sudo systemctl enable --now runner-cleanup.timer
```

To compare your live conf against the new template after an upgrade:

```sh
diff -u /etc/armbian/runner-cleanup.conf{,.dist}
```

## Configure

Edit `/etc/armbian/runner-cleanup.conf`. Two arrays:

```sh
# Docker images to keep across cleanup passes.
# Exact <repository>:<tag>; tag mandatory.
KEEP_IMAGES=(
    lscr.io/linuxserver/swag:latest             # shipped default
    lscr.io/linuxserver/openssh-server:latest   # shipped default
    ghcr.io/armbian/builder:latest
)

# Runners whose _work/ must NOT be wiped. By module_armbian_runners
# convention the first runner of a series carries the primary label
# (alfa) and is the natural home of warm caches (kernel ccache,
# toolchain downloads). Defaulted to actions-runner-01; add or change
# entries to match your fleet's "primary" naming.
KEEP_RUNNERS_WORK=(
    actions-runner-01
)
```

## Test manually

```sh
sudo /usr/local/sbin/runner-cleanup --dry-run --verbose
```

Successful no-op output on an idle host with an empty `KEEP_IMAGES`
looks like:

```
runner-cleanup: no actions-runner-* users on this host — nothing to do.
```

or, with runners present and idle:

```
wipe /home/actions-runner-01/_work/
keep image ghcr.io/armbian/builder:latest
rm image ubuntu:24.04 (sha256:...)
[dry-run] docker container prune -f
...
```

## Check the timer

```sh
systemctl list-timers runner-cleanup.timer
journalctl -u runner-cleanup.service --since '1 day ago'
```

## Per-job _diag/pages/ cleanup

GitHub Actions runners create per-job diagnostic page files under
`~/_diag/pages/`. If a runner restarts (crash, OOM, manual restart) while
a job page file still exists, the next job fails with:

```
The file '/home/actions-runner-NN/_diag/pages/<uuid>.log' already exists.
```

The **hourly** `runner-cleanup.timer` eventually clears these, but a runner
that restarts within the hour still hits the collision.

### Event-driven layer: systemd hooks

`install-runner-hooks` wires `ExecStartPre` and `ExecStopPost` into every
`actions.runner.*.service` unit. These hooks run `runner-clean-pages` on
every runner start **and** stop (including SIGKILL / OOM / hard reboot),
clearing `~/_diag/pages/` event-driven instead of waiting for the hourly
timer.

#### Installation

```sh
# Copy the helper script to a system path
sudo install -m 0755 runner-clean-pages /usr/local/sbin/runner-clean-pages

# Run the hook installer (creates drop-ins for all runner units)
sudo ./install-runner-hooks
```

#### How it works

`install-runner-hooks` scans `/etc/systemd/system/actions.runner.*.service`
and creates a drop-in `10-clean-pages.conf` for each unit:

```ini
[Service]
ExecStartPre=-/usr/local/sbin/runner-clean-pages
ExecStopPost=-/usr/local/sbin/runner-clean-pages
```

The `-` prefix makes cleanup failures non-fatal — the runner unit must still
start/stop even if the cleanup script has an issue. All failures log to
journald under `runner-clean-pages` for visibility.

#### Environment handling

`runner-clean-pages` determines the runner's home directory by:
1. Using `$HOME` if set (typical when run manually)
2. Falling back to `getent passwd $(id -un)` when `$HOME` is unset

This fallback handles the case where systemd doesn't propagate `HOME` in
`ExecStartPre`/`ExecStopPost` hooks, even though the service runs as the
correct user.
