OBS Studio with hardware acceleration auto-selected for the board, the same approach as the Jellyfin module.

- **arm64 Rockchip RK3588** (vendor kernel, Debian Trixie or Ubuntu Resolute): installs `obs-studio-rockchip`, built by [obs-jfmpp](https://github.com/HeyMeco/obs-jfmpp) against jellyfin-ffmpeg with Rockchip MPP and RGA — *Rockchip MPP H.264/HEVC* hardware encoders, a Rockchip HDMI Input source for RK3588 HDMI-in, a Rockchip camera source for MIPI CSI sensors, and the browser source. Hardware encoding and HDMI input need a vendor kernel (`/dev/mpp_service`, `/dev/rga`); it provides and replaces the distribution's `obs-studio` and installs a udev rule for the MPP, RGA and DMA heap devices.
- **x86 with an NVIDIA GPU**: the distribution's `obs-studio`, which uses *NVENC* at runtime (needs the proprietary NVIDIA driver).
- **x86 Intel/AMD**: the distribution's `obs-studio`, using *VAAPI* via `/dev/dri`.
- **anything else** on amd64/arm64: the distribution's `obs-studio` with *x264* software encoding.

The menu entry appears on amd64 and arm64. The install reports which package and acceleration it selected for the current board.
