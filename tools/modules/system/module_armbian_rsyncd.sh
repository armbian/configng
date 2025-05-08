module_options+=(
	["module_armbian_rsyncd,author"]="@igorpecovnik"
	["module_armbian_rsyncd,maintainer"]="@igorpecovnik"
	["module_armbian_rsyncd,feature"]="module_armbian_rsyncd"
	["module_armbian_rsyncd,example"]="install remove status help"
	["module_armbian_rsyncd,desc"]="Install and configure Armbian rsyncd."
	["module_armbian_rsyncd,doc_link"]=""
	["module_armbian_rsyncd,group"]="Armbian"
	["module_armbian_rsyncd,status"]="Active"
	["module_armbian_rsyncd,port"]="873"
	["module_armbian_rsyncd,arch"]=""
)

function module_armbian_rsyncd() {
	local title="rsyncd"
	local condition=$(which "$title" 2>/dev/null)

	# Convert the example string to an array
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_armbian_rsyncd,example"]}"

	case "$1" in
		"${commands[0]}")
			if export_path=$(dialog --title \
				"Where is Armbian file storage located?" \
				--inputbox "" 6 60 "/armbian/openssh-server/storage/" 3>&1 1>&2 2>&3); then

				# lets make temporally file
				rsyncd_config=$(mktemp)
				if target_sync=$($DIALOG --title "Select an Option" --checklist \
					"Choose your favorite programming language" 15 60 6 \
					"apt" "Armbian stable packages" ON \
					"dl" "Stable images" ON \
					"beta" "Armbian unstable packages" OFF \
					"archive" "Old images" OFF \
					"oldarhive" "Very old Archive" OFF \
					"cache" "Nighly and community images cache" OFF 3>&1 1>&2 2>&3); then

					for choice in $(echo ${target_sync} | tr -d '"'); do
						cat <<- EOF >> $rsyncd_config
						[$choice]
						path = $export_path/$choice
						max connections = 8
						uid = nobody
						gid = users
						list = yes
						read only = yes
						write only = no
						use chroot = yes
						lock file = /run/lock/rsyncd-$choice
						EOF
					done
					mv $rsyncd_config /etc/rsyncd.conf
					pkg_update
					pkg_install rsync >/dev/null 2>&1
					srv_enable rsync >/dev/null 2>&1
					srv_start rsync >/dev/null 2>&1
				fi
			fi
		;;
		"${commands[1]}")
			srv_stop rsync >/dev/null 2>&1
			rm -f /etc/rsyncd.conf
		;;
		"${commands[2]}")
			if srv_active rsyncd; then
				return 0
			elif ! srv_enabled rsync; then
				return 1
			else
				return 1
			fi
		;;
		"${commands[3]}")
			echo -e "\nUsage: ${module_options["module_armbian_rsyncd,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_armbian_rsyncd,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tstatus\t- Status of $title."
			echo
		;;
		*)
			${module_options["module_armbian_rsyncd,feature"]} ${commands[3]}
		;;
	esac
	}
