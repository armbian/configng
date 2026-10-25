OBS Studio for **arm64 Rockchip** boards, built by [obs-jfmpp](https://github.com/HeyMeco/obs-jfmpp) against jellyfin-ffmpeg with Rockchip MPP and RGA. It adds *Rockchip MPP H.264/HEVC* hardware encoders to the Simple and Advanced output modes, a Rockchip HDMI Input source for RK3588 HDMI-in, a Rockchip camera source for MIPI CSI sensors, and the browser source.

The menu entry only appears on arm64 boards with a Rockchip SoC running Debian Trixie or Ubuntu Resolute, the releases the package is built for. Hardware encoding and HDMI input need a vendor kernel (`/dev/mpp_service`, `/dev/rga`).

The package is `obs-studio-rockchip` from the Armbian repository (`<release>-desktop`). It provides and replaces the distribution's `obs-studio`, and installs a udev rule that gives the `video` group and the desktop user access to the MPP, RGA and DMA heap devices.
