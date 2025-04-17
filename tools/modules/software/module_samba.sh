module_options+=(
	["module_samba,author"]="@Tearran"
	["module_samba,maintainer"]="@Tearran"
	["module_samba,feature"]="module_samba"
	["module_samba,example"]="help install remove start stop enable disable configure default status"
	["module_samba,desc"]="Samba setup and service setting."
	["module_samba,status"]="Active"
	["module_samba,doc_link"]="https://www.samba.org/samba/docs/"
	["module_samba,group"]="Networking"
	["module_samba,port"]="445"
	["module_samba,arch"]="x86-64 arm64 armhf"
)

_check_samba_config(){
	# Check if /etc/samba/smb.conf exists
		if [[ ! -f "/etc/samba/smb.conf" ]]; then
			if [[ -f "/usr/share/samba/smb.conf" ]]; then
				cp "/usr/share/samba/smb.conf" "/etc/samba/smb.conf"
			else
				echo "Warning: Missing configuration file. Use the <configure> option."
			fi
		fi
}

_set_samba_default(){
# Check if the default Samba configuration file and directory exist
	if [[ -f "/usr/share/samba/smb.conf" && -d "/etc/samba" ]]; then
		echo "Found default configuration and target directory."
		cp /usr/share/samba/smb.conf /etc/samba/smb.conf
		echo "Default configuration copied to /etc/samba/smb.conf."
	else
		# Provide more specific error messages
		if [[ ! -f "/usr/share/samba/smb.conf" ]]; then
		echo "Error: Default configuration file /usr/share/samba/smb.conf not found."
		fi
		if [[ ! -d "/etc/samba" ]]; then
		echo "Error: Target directory /etc/samba does not exist."
		fi
		return 1
	fi
}

_pipe_service_state(){
	local title="$1"
			## check samba status
	if srv_active $title ; then
		echo "active."
		return 0
	elif ! srv_enabled $title ; then
		echo "inactive"
		return 1
	else
		echo "$title service is in an unknown state."
		return 1
	fi
}

function module_samba() {
	local title="samba"
	local feature="module_samba"
	local condition
	condition=$(command -v smbd)
	# Convert the example string to an array
	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_samba,example"]}"

	case "$1" in
		"${commands[0]}") _software_help_module "$title" "$feature" ;;
		"${commands[1]}") pkg_install samba && _check_samba_config ;;
		"${commands[2]}") srv_disable smbd && pkg_remove samba ;;
		"${commands[3]}") srv_start smbd ;;
		"${commands[4]}") srv_stop smbd ;;
		"${commands[5]}") srv_enable smbd ;;
		"${commands[6]}") srv_disable smbd ;;
		"${commands[7]}"|"${commands[8]}") _set_samba_default ;;
		"${commands[9]}") _pipe_service_state smbd ;;
		*) _software_help_module "Samba services" module_samba true ;;
	esac
}
