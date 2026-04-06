module_options+=(
	["module_desktop_packages,author"]="@igorpecovnik"
	["module_desktop_packages,feature"]="module_desktop"
	["module_desktop_packages,desc"]="Generate desktop packages list"
	["module_desktop_packages,de"]="budgie cinnamon deepin enlightenment gnome i3-wm kde-neon kde-plasma mate xfce xmonad"
	["module_desktop_packages,release"]="bookworm trixie noble plucky"
	["module_desktop_packages,status"]="Active"
	["module_desktop_packages,arch"]="x86-64"
)
#
# Module desktop packages
#
function module_desktop_packages() {

	# Convert the example string to an array
	local de
	IFS=' ' read -r -a de <<< "${module_options["module_desktop_packages,de"]}"

	local packages=()
	local packages_remove=()
	local packages_uninstall=()
	local architecture=()
	local supported=()

	# Common desktop packages
	packages=(
			"anacron"
			"cups"
			"eject"
			"printer-driver-all"
			"profile-sync-daemon"
			"system-config-printer"
			"terminator"
			"upower"
			"xarchiver"
		)

	case "$1" in
		"${de[0]}")
			# budgie - use meta-packages for clean install/removal
			packages+=(
				"budgie-desktop"
				"budgie-desktop-environment"
				"lightdm"
				"slick-greeter"
				"xserver-xorg"
				"blueman"
				"bluez"
				"bluez-tools"
				"colord"
				"dbus-x11"
				"evince"
				"gdebi"
				"gnome-disk-utility"
				"gnome-screenshot"
				"gnome-terminal"
				"gvfs-backends"
				"lm-sensors"
				"nemo"
				"numix-gtk-theme"
				"numix-icon-theme"
				"numix-icon-theme-circle"
				"pavucontrol"
				"plank"
				"pulseaudio"
				"pulseaudio-module-bluetooth"
				"spice-vdagent"
				"synaptic"
				"viewnior"
				"xdg-user-dirs"
				"xdg-user-dirs-gtk"
			)
			architecture=(
				"arm64"
				"amd64"
			)
			supported=(
				"unsupported"
			)
		;;
		"${de[1]}")
			# cinnamon - use meta-packages for clean install/removal
			packages+=(
				"cinnamon"
				"cinnamon-desktop-environment"
				"lightdm"
				"slick-greeter"
				"blueman"
				"bluez"
				"bluez-tools"
				"colord"
				"dbus-x11"
				"gdebi"
				"gnome-disk-utility"
				"gnome-system-monitor"
				"gvfs-backends"
				"lm-sensors"
				"numix-gtk-theme"
				"numix-icon-theme"
				"numix-icon-theme-circle"
				"pavucontrol"
				"pulseaudio"
				"pulseaudio-module-bluetooth"
				"spice-vdagent"
				"synaptic"
				"viewnior"
				"xdg-user-dirs"
			)
			architecture=(
				"arm64"
				"amd64"
			)
			supported=(
				"supported"
			)
		;;
		"${de[2]}")
			# deepin
		;;
		"${de[3]}")
			# enlightenment
		;;
		"${de[4]}")
			# gnome - use meta-packages for clean install/removal
			packages+=(
				"gnome-session"
				"gnome-shell"
				"gnome-control-center"
				"gnome-terminal"
				"gnome-system-monitor"
				"gnome-disk-utility"
				"gnome-shell-extension-appindicator"
				"gdm3"
				"nautilus"
				"colord"
				"dbus-x11"
				"gdebi"
				"gvfs-backends"
				"lm-sensors"
				"pavucontrol"
				"pulseaudio"
				"pulseaudio-module-bluetooth"
				"synaptic"
				"xdg-user-dirs"
				"xdg-user-dirs-gtk"
				"xserver-xorg"
				"xwayland"
				"zenity"
			)
		;;
		"${de[5]}")
			# i3-wm - tiling window manager
			packages+=(
				"i3"
				"i3status"
				"i3lock"
				"lightdm"
				"slick-greeter"
				"xserver-xorg"
				"xterm"
				"dbus-x11"
				"dunst"
				"feh"
				"lm-sensors"
				"network-manager-gnome"
				"pavucontrol"
				"pulseaudio"
				"pulseaudio-module-bluetooth"
				"rofi"
				"thunar"
				"xdg-user-dirs"
			)
			architecture=(
				"arm64"
				"amd64"
				"armhf"
				"riscv64"
			)
			supported=(
				"supported"
			)
		;;
		"${de[6]}")
			# kde-neon (Ubuntu Noble only, uses neon-desktop meta-package)
			packages+=(
				"neon-desktop"
				"sddm"
				"konsole"
				"dolphin"
				"bluedevil"
				"kscreen"
				"plasma-discover"
				"plasma-nm"
				"plasma-pa"
				"plasma-vault"
				"pipewire-audio"
				"pipewire-pulse"
				"wireplumber"
				"scdaemon"
			)
			architecture=(
				"arm64"
				"amd64"
			)
			supported=(
				"supported"
			)
		;;
		"${de[7]}")
			# kde-plasma - works on both Debian and Ubuntu
			packages+=(
				"kde-plasma-desktop"
				"sddm"
				"konsole"
				"dolphin"
				"bluedevil"
				"kscreen"
				"plasma-nm"
				"plasma-pa"
				"xserver-xorg"
				"colord"
				"dbus-x11"
				"gvfs-backends"
				"lm-sensors"
				"pulseaudio"
				"pulseaudio-module-bluetooth"
				"spice-vdagent"
				"xdg-user-dirs"
			)
			architecture=(
				"arm64"
				"amd64"
			)
			supported=(
				"supported"
			)
		;;
		"${de[8]}")
			# mate - use meta-packages for clean install/removal
			packages+=(
				"mate-desktop-environment"
				"mate-desktop-environment-extras"
				"lightdm"
				"slick-greeter"
				"xserver-xorg"
				"blueman"
				"bluez"
				"bluez-tools"
				"colord"
				"dbus-x11"
				"gdebi"
				"gnome-disk-utility"
				"gnome-system-monitor"
				"gvfs-backends"
				"lm-sensors"
				"numix-gtk-theme"
				"numix-icon-theme"
				"numix-icon-theme-circle"
				"pavucontrol"
				"pulseaudio"
				"pulseaudio-module-bluetooth"
				"spice-vdagent"
				"synaptic"
				"viewnior"
				"xdg-user-dirs"
				"xdg-user-dirs-gtk"
			)
			architecture=(
				"arm64"
				"amd64"
			)
			supported=(
				"supported"
			)
		;;
		"${de[9]}")
			# xfce - use meta-packages for clean install/removal
			packages+=(
				"xfce4"
				"xfce4-goodies"
				"xfce4-power-manager"
				"lightdm"
				"slick-greeter"
				"xserver-xorg"
				"blueman"
				"bluez"
				"bluez-tools"
				"colord"
				"dbus-x11"
				"evince"
				"gdebi"
				"gnome-disk-utility"
				"gnome-system-monitor"
				"gvfs-backends"
				"inxi"
				"libpam-gnome-keyring"
				"lm-sensors"
				"mesa-utils"
				"numix-gtk-theme"
				"numix-icon-theme"
				"numix-icon-theme-circle"
				"pavucontrol"
				"pulseaudio"
				"pulseaudio-module-bluetooth"
				"spice-vdagent"
				"synaptic"
				"viewnior"
				"xdg-user-dirs"
				"xdg-user-dirs-gtk"
			)
			architecture=(
				"arm64"
				"amd64"
				"armhf"
				"riscv64"
			)
			supported=(
				"supported"
			)
		;;
		"${de[10]}")
			# xmonad
		;;
	esac

	local release
	IFS=' ' read -r -a release <<< "${module_options["module_desktop_packages,release"]}"
	case "$2" in
		"${release[0]}")
			# bookworm
			packages+=(
				"accountsservice"
				"gnome-calculator"
				"libu2f-udev"
			)
			packages_remove+=(
				"budgie-desktop-environment"
				"libfontembed1"
				"update-manager"
				"update-manager-core"
			)
		;;
		"${release[1]}")
			# trixie - uses pipewire, pulseaudio conflicts with pipewire-alsa
			packages+=(
				"accountsservice"
				"libu2f-udev"
			)
			packages_remove+=(
				"pulseaudio"
				"pulseaudio-module-bluetooth"
			)
		;;
		"${release[2]}")
			# noble
			packages+=(
				"polkitd"
				"pkexec"
				"libu2f-udev"
				"software-properties-gtk"
			)
			packages_remove+=(
				"qalculate-gtk"
				"hplip"
				"indicator-printers"
				"libfontembed1"
				"policykit-1"
				"printer-driver-all"
			)
			packages_uninstall+=(
				"ubuntu-session"
			)
		;;
		"${release[3]}")
			# plucky
			packages+=(
				"polkitd"
				"pkexec"
				"libu2f-udev"
				"software-properties-gtk"
			)
			packages_remove+=(
				"qalculate-gtk"
				"hplip"
				"indicator-printers"
				"libfontembed1"
				"policykit-1"
				"printer-driver-all"
				"pavumeter"
			)
			packages_uninstall+=(
				"ubuntu-session"
			)
		;;
	esac

	# Remove packages_remove from packages
	filtered_packages=()
	for p in "${packages[@]}"; do
		# Check if $p is in packages_remove
		if [[ ! " ${packages_remove[@]} " =~ " $p " ]]; then
			filtered_packages+=("$p")
		fi
	done
	packages=("${filtered_packages[@]}")

	PACKAGES=${packages[@]}
	PACKAGES_UNINSTALL=${packages_uninstall[@]}
	SUPPORTED=${supported}
	ARCHITECTURE=${architecture}

}
