module_options+=(
	["module_desktops,author"]="@igorpecovnik"
	["module_desktops,feature"]="module_desktops"
	["module_desktops,desc"]="Install and manage desktop environments (YAML-driven)"
	["module_desktops,example"]="install remove status supported help"
	["module_desktops,status"]="Active"
	["module_desktops,arch"]=""
	["module_desktops,help_install"]="Install desktop (de=name)"
	["module_desktops,help_remove"]="Remove desktop (de=name)"
	["module_desktops,help_status"]="Check if installed (de=name)"
	["module_desktops,help_supported"]="JSON list or check one (de=name arch=X release=Y)"
)

#
# Parse YAML desktop definition via Python helper
# Sets: DESKTOP_PACKAGES, DESKTOP_PACKAGES_UNINSTALL, DESKTOP_DM,
#       DESKTOP_STATUS, DESKTOP_SUPPORTED, DESKTOP_DESC,
#       DESKTOP_REPO_URL, DESKTOP_REPO_KEY_URL, DESKTOP_REPO_KEYRING
#
function _desktop_yaml_parse() {
	local de="$1"
	local yaml_dir="${script_dir}/../tools/modules/desktops/yaml"
	local parser="${script_dir}/../tools/modules/desktops/scripts/parse_desktop_yaml.py"
	local arch="${2:-$(dpkg --print-architecture)}"
	local release="${3:-$DISTROID}"

	if [[ ! -f "$parser" ]]; then
		echo "Error: YAML parser not found at $parser" >&2
		return 1
	fi

	# reset variables
	DESKTOP_PACKAGES=""
	DESKTOP_PACKAGES_UNINSTALL=""
	DESKTOP_DM=""
	DESKTOP_STATUS=""
	DESKTOP_SUPPORTED=""
	DESKTOP_DESC=""
	DESKTOP_REPO_URL=""
	DESKTOP_REPO_KEY_URL=""
	DESKTOP_REPO_KEYRING=""

	eval "$(python3 "$parser" "$yaml_dir" "$de" "$release" "$arch")" || return 1
}

#
# List available desktops via Python helper
#
function _desktop_yaml_list() {
	local yaml_dir="${script_dir}/../tools/modules/desktops/yaml"
	local parser="${script_dir}/../tools/modules/desktops/scripts/parse_desktop_yaml.py"
	local arch="${1:-$(dpkg --print-architecture)}"
	local release="${2:-$DISTROID}"

	python3 "$parser" "$yaml_dir" "--list" "$release" "$arch"
}

#
# Set up custom APT repo if desktop requires one
#
function _desktop_setup_repo() {
	if [[ -n "$DESKTOP_REPO_URL" && -n "$DESKTOP_REPO_KEY_URL" ]]; then
		echo "Setting up repository for ${1}..." >&2

		# download GPG key
		curl -fsSL "$DESKTOP_REPO_KEY_URL" | gpg --dearmor -o "$DESKTOP_REPO_KEYRING" 2>/dev/null

		# add source
		cat > "/etc/apt/sources.list.d/${1}.list" <<- EOF
		deb [signed-by=${DESKTOP_REPO_KEYRING}] ${DESKTOP_REPO_URL} ${DISTROID} main
		EOF

		pkg_update
	fi
}

#
# Module to install and manage desktop environments (YAML-driven)
#
function module_desktops() {

	local de=""
	local query_arch=""
	local query_release=""
	local selected
	for selected in "${@:2}"; do
		IFS='=' read -r -a split <<< "${selected}"
		[[ "${split[0]}" == "de" ]] && de="${split[1]}"
		[[ "${split[0]}" == "arch" ]] && query_arch="${split[1]}"
		[[ "${split[0]}" == "release" ]] && query_release="${split[1]}"
	done

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_desktops,example"]}"

	case "$1" in
		"${commands[0]}")
			# install
			if [[ -z "$de" ]]; then
				local available=$(_desktop_yaml_list | cut -f1 | tr '\n' ', ' | sed 's/,$//')
				echo "Error: specify de=name. Available: ${available}" >&2
				return 1
			fi

			_desktop_yaml_parse "$de" || return 1

			if [[ "$DESKTOP_SUPPORTED" != "yes" ]]; then
				echo "Warning: '${de}' is not supported on ${DISTROID}/$(dpkg --print-architecture)" >&2
			fi

			# suppress interactive prompts
			echo "encfs encfs/security-information boolean true" | debconf-set-selections 2>/dev/null || true

			# set up custom repo if needed
			_desktop_setup_repo "$de"

			# update package list
			pkg_update

			# install packages
			pkg_install -o Dpkg::Options::="--force-confold" ${DESKTOP_PACKAGES}

			# install and register display manager
			if [[ -n "$DESKTOP_DM" && "$DESKTOP_DM" != "none" ]]; then
				pkg_install -o Dpkg::Options::="--force-confold" "$DESKTOP_DM"
				which "$DESKTOP_DM" > /etc/X11/default-display-manager 2>/dev/null || true
			fi

			# remove unwanted packages
			if [[ -n "$DESKTOP_PACKAGES_UNINSTALL" ]]; then
				apt-get remove -y --purge ${DESKTOP_PACKAGES_UNINSTALL} 2>/dev/null || true
			fi

			echo "${de} installed."
		;;

		"${commands[1]}")
			# remove
			if [[ -z "$de" ]]; then
				echo "Error: specify de=name" >&2
				return 1
			fi

			_desktop_yaml_parse "$de" || return 1

			# stop display manager
			if [[ -n "$DESKTOP_DM" && "$DESKTOP_DM" != "none" ]]; then
				systemctl stop "$DESKTOP_DM" 2>/dev/null || true
				pkg_remove "$DESKTOP_DM"
			fi

			echo "${de} removed."
		;;

		"${commands[2]}")
			# status
			if [[ -z "$de" ]]; then
				echo "Error: specify de=name" >&2
				return 1
			fi

			_desktop_yaml_parse "$de" || return 1

			# check display manager
			if [[ -n "$DESKTOP_DM" && "$DESKTOP_DM" != "none" ]]; then
				if systemctl is-active --quiet "$DESKTOP_DM" 2>/dev/null; then
					echo "installed"
					return 0
				fi
			fi

			# fallback: check first package
			local first_pkg=$(echo "$DESKTOP_PACKAGES" | awk '{print $1}')
			if dpkg -l "$first_pkg" 2>/dev/null | grep -q "^ii"; then
				echo "installed"
				return 0
			fi

			echo "not installed"
			return 1
		;;

		"${commands[3]}")
			# supported - accepts arch= and release= overrides, outputs JSON
			local use_arch="${query_arch:-$(dpkg --print-architecture)}"
			local use_release="${query_release:-$DISTROID}"
			local yaml_dir="${script_dir}/../tools/modules/desktops/yaml"
			local parser="${script_dir}/../tools/modules/desktops/scripts/parse_desktop_yaml.py"

			if [[ -z "$de" ]]; then
				local result
				result=$(python3 "$parser" "$yaml_dir" "--list-json" "$use_release" "$use_arch")
				echo "$result"
				[[ "$result" == "[]" ]] && return 1
				return 0
			fi

			_desktop_yaml_parse "$de" "$use_arch" "$use_release" || return 1
			if [[ "$DESKTOP_SUPPORTED" == "yes" ]]; then
				echo "true"
				return 0
			else
				echo "false"
				return 1
			fi
		;;

		"${commands[4]}")
			show_module_help "module_desktops" "Desktops" \
				"Examples:\n  module_desktops install de=xfce\n  module_desktops supported\n  module_desktops supported arch=arm64 release=trixie\n  module_desktops supported de=gnome" "native"
		;;

		*)
			show_module_help "module_desktops" "Desktops" \
				"Examples:\n  module_desktops install de=xfce\n  module_desktops supported\n  module_desktops supported arch=arm64 release=trixie\n  module_desktops supported de=gnome" "native"
		;;
	esac
}
