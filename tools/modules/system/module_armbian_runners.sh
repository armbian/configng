#declare -A module_options
module_options+=(
	["module_armbian_runners,author"]="@igorpecovnik"
	["module_armbian_runners,feature"]="module_armbian_runners"
	["module_armbian_runners,desc"]="Manage self hosted runners"
	["module_armbian_runners,example"]="install remove status help"
	["module_armbian_runners,port"]=""
	["module_armbian_runners,status"]="Active"
	["module_armbian_runners,arch"]=""
)
#
# Module Armbian self hosted Github runners
#
function module_armbian_runners () {
	local title="runners"
	local condition=$(which "$title" 2>/dev/null)

	local gh_token=$2
	local runner_name="${3:-armbian}"
	local start="${4:-01}"
	local stop="${5:-01}"
	local label_primary="${6:-alfa}"
	local label_secondary="${7:-fast,images}"
	local organisation="${8:-armbian}"
	local owner="${9}"
	local repository="${10}"

	# we can generate per org or per repo
	local registration_url="${organisation}"
	local prefix="orgs"
	if [[ -n "${owner}" && -n "${repository}" ]]; then
   		registration_url="${owner}/${repository}"
    	prefix=repos
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_armbian_runners,example"]}"

	case "$1" in
		"${commands[0]}")
			#pkg_installed docker-ce || module_docker install
			pkg_update
			pkg_install libxml2-utils jq curl

			# download latest runner package
			local temp_dir=$(mktemp -d)
			local LATEST=$(curl -sL https://github.com/actions/runner/releases/ \
			| xmllint -html -xpath '//a[contains(@href, "release")]/text()' - 2> /dev/null \
			| grep -P '^v' | head -n1 | sed "s/v//g")
			curl --create-dir --output-dir ${temp_dir} -o \
			actions-runner-linux-${ARCH}-${LATEST}.tar.gz -L \
			https://github.com/actions/runner/releases/download/v${LATEST}/actions-runner-linux-${ARCH}-${LATEST}.tar.gz

			# make runners each under its own user
			for i in $(seq -w $start $stop)
			do
				local token=$(curl -s \
				-X POST \
				-H "Accept: application/vnd.github+json" \
				-H "Authorization: Bearer ${gh_token}"\
	  			-H "X-GitHub-Api-Version: 2022-11-28" \
	  			https://api.github.com/${prefix}/${registration_url}/actions/runners/registration-token | jq -r .token)

				adduser --quiet --disabled-password --shell /bin/bash \
				--home /home/actions-runner-${i} --gecos "actions-runner-${i}" actions-runner-${i}
	
				# add to sudoers
				if ! sudo grep -q "actions-runner-${i}" /etc/sudoers; then
        	    	echo "actions-runner-${i} ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers
        		fi
				usermod -aG docker actions-runner-${i}
				tar xzf ${temp_dir}/actions-runner-linux-${ARCH}-${LATEST}.tar.gz -C /home/actions-runner-${i}
				chown -R actions-runner-${i}:actions-runner-${i} /home/actions-runner-${i}

	        	# 1st runner has different labels
    	    	local label=$label_secondary
        		if [[ "$i" == "${START}" ]]; then
					local label=$label_primary
				fi

				runuser -l actions-runner-${i} -c \
				"./config.sh --url https://github.com/${registration_url} \
				--token ${token} --labels ${label} --name ${runner_name}-${i} --unattended"
				sh -c "cd /home/actions-runner-${i} ; \
				sudo ./svc.sh install actions-runner-${i} 2>/dev/null; \
				sudo ./svc.sh start actions-runner-${i} >/dev/null"
			done
			echo "$start $stop $label_primary $label_secondary $organisation"
		;;
		"${commands[1]}")
			for i in $(seq -w $start $stop); do
				# delete if previous already exists
				if id "actions-runner-${i}" >/dev/null 2>&1; then
					runner_delete "$NAME-${i}"
					runner_home=$(getent passwd "actions-runner-${i}" | cut -d: -f6)
					sh -c "cd ${runner_home} ; \
					sudo ./svc.sh stop actions-runner-${i} >/dev/null; \
					sudo ./svc.sh uninstall actions-runner-${i} >/dev/null"
					sudo userdel -r -f actions-runner-${i} 2>/dev/null
					sudo groupdel actions-runner-${i} 2>/dev/null
					sudo sed -i "/^actions-runner-${i}.*/d" /etc/sudoers
					sudo rm -rf "${runner_home}"
				fi
			done
		;;
		"${commands[2]}")
			DELETE=$1
			x=1
			while [ $x -le 9 ] # need to do it different as it can be more then 9 pages
			do
			RUNNER=$(
			curl -s -L \
	  		-H "Accept: application/vnd.github+json" \
	  		-H "Authorization: Bearer ${gh_token}" \
	  		-H "X-GitHub-Api-Version: 2022-11-28" \
	  		https://api.github.com/${prefix}/${registration_url}/actions/runners\?page\=${x} \
			| jq -r '.runners[] | .id, .name' | xargs -n2 -d'\n' | sed -e 's/ /,/g')

			while IFS= read -r DATA; do
				RUNNER_ID=$(echo $DATA | cut -d"," -f1)
				RUNNER_NAME=$(echo $DATA | cut -d"," -f2)
				# deleting a runner
				if [[ $RUNNER_NAME == ${DELETE} ]]; then
					echo "Delete existing: $RUNNER_NAME"
					curl -s -L \
					-X DELETE \
					-H "Accept: application/vnd.github+json" \
					-H "Authorization: Bearer ${gh_token}"\
					-H "X-GitHub-Api-Version: 2022-11-28" \
					https://api.github.com/${prefix}/${registration_url}/actions/runners/${RUNNER_ID}
				fi
			done <<< $RUNNER
			x=$(( $x + 1 ))
			done
		;;
		"${commands[6]}")
			echo -e "\nUsage: ${module_options["module_armbian_runners,feature"]} <command>"
			echo -e "Commands:  ${module_options["module_armbian_runners,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title."
			echo -e "\t\t  token [runner_name] [start] [stop] [labels_primary] [labels_secondary] [organisation]/[owner repository]"
			echo -e "\tremove\t- Remove $title."
			echo -e "\tstatus\t- Installation status $title."
			echo
		;;
		*)
			${module_options["module_armbian_runners,feature"]} ${commands[6]}
		;;
	esac
}
#module_armbian_runners "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9" "$10"