module_options+=(
	["module_desktop_packages,author"]="@igorpecovnik"
	["module_desktop_packages,feature"]="module_desktop"
	["module_desktop_packages,desc"]="Generate desktop packages list"
	["module_desktop_packages,de"]="budgie cinnamon deepin enlightenment gnome i3-wm kde-plasma mate xfce xmonad"
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
			# budgie
		;;
		"${de[1]}")
			# cinnamon
		;;
		"${de[2]}")
			# deepin
		;;
		"${de[3]}")
			# enlightenment
		;;
		"${de[4]}")
			# gnome
			packages+=(
				"apt-xapian-index"
				"at-spi2-core"
				"colord"
				"dbus-x11"
				"dconf-cli"
				"dmz-cursor-theme"
				"foomatic-db-compressed-ppds"
				"fonts-noto-cjk"
				"fonts-ubuntu"
				"fonts-ubuntu-console"
				"gdebi"
				"gdm3"
				"gnome-control-center"
				"gnome-desktop3-data"
				"gnome-disk-utility"
				"gnome-disk-utility"
				"gnome-keyring"
				"gnome-menus"
				"gnome-packagekit"
				"gnome-screenshot"
				"gnome-session"
				"gnome-shell"
				"gnome-shell-extension-appindicator"
				"gnome-system-monitor"
				"gnome-terminal"
				"gvfs-backends"
				"inputattach"
				"libnotify-bin"
				"lm-sensors"
				"nautilus"
				"nautilus-extension-gnome-terminal"
				"pavucontrol"
				"pulseaudio"
				"pulseaudio-module-bluetooth"
				"software-properties-gtk"
				"synaptic"
				"x11-apps"
				"x11-session-utils"
				"x11-utils"
				"x11-xserver-utils"
				"xdg-user-dirs"
				"xdg-user-dirs-gtk"
				"xfonts-base"
				"xserver-xorg"
				"xwayland"
				"zenity"
			)
		;;
		"${de[5]}")
			# i3-wm
		;;
		"${de[6]}")
			# kde-plasma
		;;
		"${de[7]}")
			# mate
		;;
		"${de[8]}")
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
		"${de[9]}")
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
				"libfontembed1"
				"update-manager"
				"update-manager-core"
			)
		;;
		"${release[1]}")
			# trixie
			packages+=(
				"accountsservice"
				"libu2f-udev"
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
