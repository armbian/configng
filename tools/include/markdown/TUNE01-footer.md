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
    travel: 20% is 200 MB on a 1 GB board and 25 GB on a 125 GB server, and 25 GB
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
      exists*.
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

=== "Why this exists"

    A worked example, from an Armbian CI build host on 2026-09-26.

    The machine had inherited the SBC defaults: writeback deferred for two minutes,
    ext4 committing every two minutes. The build framework calls `sync` at many
    points, wrapped in a 30-second timeout. With two minutes of deferred writeback
    there was far more than 30 seconds of work to do, so the flush timed out.

    A process blocked in `sync_inodes_sb` is in uninterruptible sleep and **cannot
    be killed** — `SIGKILL` is not delivered until it leaves that state. So each
    timed-out flush leaked, and the caller started another. `sync` is also global:
    it flushes every filesystem, so concurrent builds each waited on the others'
    unwritten data.

    ```
    load average: 874.71, 408.83, 195.12    ← climbing
    1152 processes in D state
    CPU:  us 1-2%,  id 25-51%,  wa 26-74%   ← 32 threads, essentially idle
    NVMe: 68 MB/s on a drive good for GB/s  ← never the constraint
    ```

    It reached 1600 stuck flushes and a load average of 1424 on hardware that was
    doing almost nothing. Not a hardware limit, not a capacity problem — the wrong
    machine's defaults.

    The `builder` profile prevents this by capping unwritten data at a few GB, so a
    full flush completes in seconds on any SSD and always finishes inside such a
    timeout.

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
    - **ext4 commit interval unchanged after `reset`**: `reset` removes the unit but
      does not remount, so the interval stays until the next reboot. Apply it now
      with `mount -o remount,commit=5 /` if you need it immediately.
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
      and the ext4 commit interval at boot. Generated per profile, and only
      containing the parts this hardware supports.
    - **`/etc/default/armbian-tuning-profile`**: records which profile is active and
      when it was applied.

    **`/etc/fstab` is deliberately not touched.** The ext4 commit interval is set
    with `mount -o remount` from the unit above rather than written as a mount
    option, so no tuning profile can leave a machine unbootable, and removing the
    profile removes the change completely.
