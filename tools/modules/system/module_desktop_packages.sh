module_options+=(
	["module_desktop_packages,author"]="@igorpecovnik"
	["module_desktop_packages,feature"]="module_desktop"
	["module_desktop_packages,desc"]="Generate desktop packages list"
	["module_desktop_packages,de"]="budgie cinnamon deepin enlightenment gnome i3-wm kde-plasma mate xfce xmonad"
	["module_desktop_packages,release"]="bookworm noble plucky"
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
			# xfce
			packages+=(
				"apt-xapian-index"
				"blueman"
				"bluez"
				"bluez-cups"
				"bluez-tools"
				"brltty"
				"brltty-x11"
				"cifs-utils"
				"colord"
				"cups-bsd"
				"cups-client"
				"cups-filters"
				"dbus-x11"
				"dmz-cursor-theme"
				"evince"
				"evince-common"
				"fontconfig"
				"fontconfig-config"
				"fonts-noto-cjk"
				"fonts-ubuntu"
				"fonts-ubuntu-console"
				"foomatic-db-compressed-ppds"
				"gdebi"
				"ghostscript-x"
				"gnome-disk-utility"
				"gnome-font-viewer"
				"gnome-screenshot"
				"gnome-system-monitor"
				"gstreamer1.0-packagekit"
				"gstreamer1.0-plugins-base-apps"
				"gstreamer1.0-pulseaudio"
				"gtk2-engines"
				"gtk2-engines-murrine"
				"gtk2-engines-pixbuf"
				"gvfs-backends"
				"hplip"
				"ayatana-indicator-printers"
				"inputattach"
				"inxi"
				"keyutils"
				"laptop-detect"
				"libatk-adaptor"
				"libfontconfig1"
				"libfontembed1"
				"libfontenc1"
				"libgail-common"
				"libgl1-mesa-dri"
				"libgsettings-qt1"
				"libgtk2.0-bin"
				"libnotify-bin"
				"libpam-gnome-keyring"
				"libproxy1-plugin-gsettings"
				"libwmf0.2-7-gtk"
				"libxcursor1"
				"lightdm"
				"lm-sensors"
				"lxtask"
				"mesa-utils"
				"mousepad"
				"mousetweaks"
				"numix-gtk-theme"
				"numix-icon-theme"
				"numix-icon-theme-circle"
				"openprinting-ppds"
				"orca"
				"p7zip-full"
				"pamix"
				"pasystray"
				"pavucontrol"
				"pavumeter"
				"policykit-1"
				"pulseaudio"
				"pulseaudio-module-bluetooth"
				"qalculate-gtk"
				"redshift"
				"slick-greeter"
				"smbclient"
				"software-properties-gtk"
				"spice-vdagent"
				"synaptic"
				"system-config-printer-common"
				"thunar-volman"
				"update-inetd"
				"update-manager"
				"update-manager-core"
				"viewnior"
				"x11-apps"
				"x11-utils"
				"x11-xserver-utils"
				"xapps-common"
				"xauth"
				"xbacklight"
				"xcursor-themes"
				"xdg-user-dirs"
				"xdg-user-dirs-gtk"
				"xfce4"
				"xfce4-notifyd"
				"xfce4-power-manager"
				"xfce4-screenshooter"
				"xfce4-terminal"
				"xfonts-100dpi"
				"xfonts-75dpi"
				"xfonts-base"
				"xfonts-encodings"
				"xfonts-scalable"
				"xfonts-utils"
				"xorg-docs-core"
				"xscreensaver"
				"xsensors"
				"xserver-xorg"
				"xserver-xorg-video-fbdev"
				"xwallpaper"
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
			# noble
			packages+=(
				"polkitd"
				"pkexec"
				"libu2f-udev"
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
		"${release[2]}")
			# plucky
			packages+=(
				"polkitd"
				"pkexec"
				"libu2f-udev"
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
