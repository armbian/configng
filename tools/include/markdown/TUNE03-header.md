Set the CPU frequency governor, the minimum and maximum frequency, and boost. Set them for all CPUs or for one CPU cluster.

On big.LITTLE and DynamIQ systems (for example RK3399, RK3588, S922X), each cluster has its own frequency table. Give each cluster its own limits and governor, for example `performance` on the big cores only.

Changes apply immediately and at every boot. The settings are in `/etc/default/cpufrequtils`. The build framework writes the board defaults to this file, and **Return to board defaults** restores them.

| Key | Scope |
|-----|-------|
| `GOVERNOR`, `MIN_SPEED`, `MAX_SPEED` | all CPUs (kHz) |
| `POLICY<n>_GOVERNOR`, `POLICY<n>_MIN_SPEED`, `POLICY<n>_MAX_SPEED` | the cluster that starts at CPU `<n>` |
| `BOOST` | `true` = on, `off` = off, `false` = kernel default |

Command line:

```sh
armbian-config --api module_tuning_profile cpu status
armbian-config --api module_tuning_profile cpu set policy4 governor performance
armbian-config --api module_tuning_profile cpu set all max 1800000
armbian-config --api module_tuning_profile cpu reset
```
