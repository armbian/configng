module_options+=(
	["module_git-cli,author"]="@armbian"
	["module_git-cli,maintainer"]="@igorpecovnik"
	["module_git-cli,feature"]="module_git-cli"
	["module_git-cli,example"]="install remove status help"
	["module_git-cli,desc"]="Install git command-line tools"
	["module_git-cli,status"]="Stable"
	["module_git-cli,doc_link"]="https://git-scm.com/doc"
	["module_git-cli,group"]="DevTools"
	["module_git-cli,arch"]="x86-64 arm64 armhf riscv64"
)
#
# Module Git CLI
#
# Installs the git command-line tools (distributed version control) from the
# distribution repositories. Native package - no container.
#
function module_git-cli() {
	local title="git"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_git-cli,example"]}"

	case "$1" in

		"${commands[0]}") # install
			pkg_update
			pkg_install git
		;;

		"${commands[1]}") # remove
			pkg_remove git
		;;

		"${commands[2]}") # status
			if pkg_installed git; then
				return 0
			else
				return 1
			fi
		;;

		"${commands[3]}") # help
			echo -e "\nUsage: ${module_options["module_git-cli,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_git-cli,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\tremove\t- Remove $title."
			echo -e "\tstatus\t- Status $title."
			echo
		;;

		*)
			${module_options["module_git-cli,feature"]} ${commands[3]}
		;;

	esac
}
