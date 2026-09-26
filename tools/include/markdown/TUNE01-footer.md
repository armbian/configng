=== "Profiles"

    | Profile | For | Swappiness | Dirty limit | Writeback | ext4 commit | CPU bias |
    |---------|-----|------------|-------------|-----------|-------------|----------|
    | `sbc` | SD card or eMMC boot | 100 | 20% of RAM | 120 s | 120 s | power |
    | `balanced` | No strong role | 60 | 20% of RAM | 5 s | 5 s | default |
    | `desktop` | Interactive use | 10 | 10%, max 2 GiB | 5 s | 15 s | balance_performance |
    | `builder` | Compiling, CI on SSD/NVMe | 1 | 10%, max 4 GiB | 5 s | 30 s | performance |
    | `nas` | File server | 10 | 20%, max 8 GiB | 15 s | 30 s | balance_power |

    `sbc` is the closest match to Armbian's historical defaults. If you have never
    changed anything and you are running from a memory card, that is roughly what
    you already have.

    **Dirty limits scale with the machine.** A percentage on its own does not
    travel: 20% is 200 MB on a 1 GB board and 25 GB on a 128 GB server, and 25 GB
    is far more unwritten data than any single flush should ever have to clear. The
    percentage keeps small machines sane, the cap keeps a flush bounded in *time* on
    large ones, and a 32 MiB floor stops a very small board throttling its writers
    constantly.

=== "Choosing a profile"

    - **Booting from a memory card?** Use `sbc`. Card wear is a real failure mode
      and this is what protects it.
    - **Root on SSD, NVMe or a spinning disk, general use?** `balanced` is a safe
      default; `desktop` if it is a workstation you sit in front of.
    - **Compiling, building images, or running CI?** `builder`. This is the profile
      that keeps `sync` cheap, which matters more than it sounds — see *Why this
      matters*.
    - **Serving files?** `nas`. Larger buffers absorb streaming writes without
      making a client's `fsync` wait behind a huge backlog.

    Only one profile is active at a time, and switching is not cumulative: each
    apply rewrites the configuration rather than layering on top of the last one.

=== "What the settings do"

    - **`vm.swappiness`** (0–100): how readily the kernel swaps anonymous pages.
      High values suit ZRAM, where "swapping" means compressing into RAM. Low
      values suit machines with RAM to spare, where swapping costs more than it
      saves. `builder` uses 1 rather than 0, so swap remains an emergency backstop
      — a runaway build gets slow instead of being killed.
    - **Dirty limits** (`vm.dirty_bytes` / `vm.dirty_ratio`): how much modified data
      may sit in RAM unwritten. The larger this is, the longer a full flush takes.
      Note the byte and ratio forms are mutually exclusive — setting one zeroes the
      other, which is why each profile commits to one form.
    - **`vm.dirty_writeback_centisecs`**: how often flusher threads wake. At the SBC
      default of 12000 they wake every two minutes; anything asking for a flush in
      between finds almost nothing already written.
    - **`vm.dirty_expire_centisecs`**: how old a dirty page must be before writeback
      will take it.
    - **ext4 `commit`**: how long the journal batches metadata. Longer means fewer
      writes and larger transactions; a flush that forces a commit then has much
      more to do, and other processes block on the journal while it happens.
    - **CPU energy/performance preference**: only present on `intel_pstate` and
      `amd-pstate-epp`. Most ARM cpufreq drivers have no such knob, and on those
      boards the profile simply does not set one.

=== "Why this matters"

    Deferring writeback looks free, because its cost is not paid when the data is
    written. It is paid later, all at once, by whatever next asks for the data to be
    on disk — an `fsync`, a `sync`, unmounting a filesystem, or a package manager
    committing an install.

    That bill grows with the deferral. Two minutes of accumulated writes on a
    machine with a large page cache can be many gigabytes, and a flush must clear
    all of it before it returns.

    Three things make that worse than a slow flush:

    - **A process waiting on writeback cannot be interrupted.** It sits in
      uninterruptible sleep, where signals are not delivered — `SIGKILL` included.
      A timeout around the operation does not bound it, because the timeout cannot
      actually cancel it.
    - **Load average counts those processes.** So the load figure climbs into the
      hundreds while the CPU is largely idle, which is a confusing thing to
      diagnose: the machine looks overloaded and is in fact waiting.
    - **`sync` is global.** It flushes every filesystem, not just the caller's. On a
      machine running several unrelated jobs, each one's flush waits on all the
      others' unwritten data, so the delay is shared out rather than contained.

    The pattern is easy to recognise once seen: a load average far above the core
    count, a high `%wa` and a high `%id` at the same time, and many processes in
    state `D`.

    ```sh
    uptime                                    # load average
    vmstat 1 5                                # look at the wa and id columns
    ps -eo state,comm | awk '$1=="D"'         # processes blocked on I/O
    ```

    This is why the profiles for machines with real storage cap unwritten data
    rather than maximising it. A few gigabytes on a device sustaining hundreds of
    megabytes per second is a flush measured in seconds — short enough that nothing
    queues behind it, and short enough that a timeout around it means something.

    On a memory card the trade genuinely runs the other way, which is what `sbc` is
    for: fewer, larger writes extend the life of the card, and the occasional long
    flush is a price worth paying for hardware that wears out.

=== "Command line"

    ```sh
    # What is available, and what each is for
    armbian-config --api module_tuning_profile list

    # Apply one
    armbian-config --api module_tuning_profile apply builder

    # Active profile plus the values actually in effect
    armbian-config --api module_tuning_profile status

    # Back to distribution defaults
    armbian-config --api module_tuning_profile reset
    ```

    `status` exits non-zero when no profile is applied, so it can be used as a
    condition in scripts:

    ```sh
    if ! armbian-config --api module_tuning_profile status >/dev/null; then
        armbian-config --api module_tuning_profile apply nas
    fi
    ```

=== "Troubleshooting"

    - **Swappiness is not what the profile says**: another drop-in is overriding it.
      `systemd-sysctl` applies `/etc/sysctl.d/` in filename order and the last file
      wins. The profile is deliberately named `99-armbian-tuning-profile.conf` so it
      sorts after `99-armbian-memory.conf`, which the Memory module writes with its
      own value. A hand-written file sorting later still beats it — check with
      `grep -r swappiness /etc/sysctl.d/`.
    - **`vm.dirty_ratio` reads 0**: expected on `desktop`, `builder` and `nas`.
      Those use the byte-based form, and setting `vm.dirty_bytes` zeroes the ratio.
      The limit is in `vm.dirty_bytes`.
    - **ext4 commit interval still set after `reset`**: `reset` takes the option out
      of `/etc/fstab`, but the filesystem stays mounted as it is until the next
      reboot. Apply the default immediately with `mount -o remount,commit=5 /` if
      you need it now.
    - **`apply` says the commit interval was not changed**: the fstab edit refused
      because something about the root entry was not what it expected — most often
      more than one line mounting `/`. Nothing was modified; `grep ' / ' /etc/fstab`
      will usually show why.
    - **CPU bias not applied**: check whether the knob exists —
      `ls /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference`. Most
      ARM boards do not have it, and the profile does not pretend otherwise.
    - **Nothing changed on a non-ext4 root**: the commit interval is an ext4 mount
      option. On btrfs, f2fs or xfs that part is skipped; the sysctl and CPU
      settings still apply.

=== "Configuration Files"

    - **`/etc/sysctl.d/99-armbian-tuning-profile.conf`**: the kernel parameters.
      Rewritten on every apply — edit the profile, not this file.
    - **`/etc/systemd/system/armbian-tuning-profile.service`**: applies the CPU bias
      at boot. Only installed on hardware that has the knob — on a board without
      one there is no unit, rather than a unit that does nothing.
    - **`/etc/default/armbian-tuning-profile`**: records which profile is active and
      when it was applied.
    - **`/etc/fstab`**: the ext4 commit interval, on the root line. This is where a
      mount option belongs, so that `findmnt` and `fstab` agree about how the
      filesystem is mounted.

    The fstab edit touches only the `commit=` token on the root entry. Every other
    option and every other line is left byte-for-byte alone, a timestamped backup is
    kept as `/etc/fstab.armbian-tuning.<date>`, and the result is checked before it
    is installed — exactly one root entry, its device, mount point and filesystem
    type unchanged, and the option in the state that was asked for. If any of that
    does not hold, the backup is restored and nothing changes.
