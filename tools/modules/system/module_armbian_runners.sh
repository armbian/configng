module_options+=(
	["module_armbian_runners,author"]="@igorpecovnik"
	["module_armbian_runners,feature"]="module_armbian_runners"
	["module_armbian_runners,desc"]="Manage self hosted runners"
	["module_armbian_runners,example"]="install remove remove_online purge status help"
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

	# read parameters from command install
	local parameter
	for var in "$@"; do
		IFS=' ' read -r -a parameter <<< "${var}"
		for feature in gh_token runner_name start stop label_primary label_secondary organisation owner repository; do
			for selected in ${parameter[@]}; do
				IFS='=' read -r -a split <<< "${selected}"
				[[ ${split[0]} == $feature ]] && eval "$feature=${split[1]}"
			done
		done
	done

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_armbian_runners,example"]}"

	case "$1" in

		"${commands[0]}")

			# Prompt using dialog if parameters are missing AND in interactive mode
			if [[ -t 1 ]]; then
				if [[ -z "$gh_token" ]]; then
					gh_token=$(dialog_inputbox "" "Enter your GitHub token:" "" 8 60)
				fi

				if [[ -z "$runner_name" ]]; then
					runner_name=$(dialog_inputbox "" "Enter runner name:" "armbian" 8 60)
				fi

				if [[ -z "$start" ]]; then
					start=$(dialog_inputbox "" "Enter start index:" "01" 8 60)
				fi

				if [[ -z "$stop" ]]; then
					stop=$(dialog_inputbox "" "Enter stop index:" "01" 8 60)
				fi

				if [[ -z "$label_primary" ]]; then
					label_primary=$(dialog_inputbox "" "Enter primary label(s):" "alfa" 8 60)
				fi

				if [[ -z "$label_secondary" ]]; then
					label_secondary=$(dialog_inputbox "" "Enter secondary label(s):" "fast,images" 8 60)
				fi

				if [[ -z "$organisation" ]]; then
					organisation=$(dialog_inputbox "" "Enter GitHub organisation:" "armbian" 8 60)
				fi
			fi

			if [[ -z $gh_token ]]; then
				echo "Error: Github token is mandatory"
				${module_options["module_armbian_runners,feature"]} ${commands[6]}
				exit 1
			fi

			# default values if not defined
			local gh_token="${gh_token}"
			local runner_name="${runner_name:-armbian}"
			local start="${start:-01}"
			local stop="${stop:-01}"
			local label_primary="${label_primary:-alfa}"
			local label_secondary="${label_secondary:-fast,images}"
			local organisation="${organisation:-armbian}"
			local owner="${owner}"
			local repository="${repository}"

			# workaround. Remove when parameters handling is fixed
			local label_primary=$(echo $label_primary | sed "s/_/,/g") # convert
			local label_secondary=$(echo $label_secondary | sed "s/_/,/g") # convert

			# we can generate per org or per repo
			local registration_url="${organisation}"
			local prefix="orgs"
			if [[ -n "${owner}" && -n "${repository}" ]]; then
				registration_url="${owner}/${repository}"
				prefix=repos
			fi

			# Docker preinstall is needed for our build framework
			pkg_installed docker-ce || module_docker install
			pkg_update
			pkg_install jq curl libicu-dev mktorrent rsync

			# download latest runner package
			local temp_dir=$(mktemp -d)
			trap '{ rm -rf -- "$temp_dir"; }' EXIT
			[[ "$ARCH" == "x86_64" ]] && local arch=x64 || local arch=arm64
			local LATEST=$(curl -sL https://api.github.com/repos/actions/runner/tags | jq -r '.[0].zipball_url' | rev | cut -d"/" -f1 | rev | sed "s/v//g")
			curl --progress-bar --create-dir --output-dir ${temp_dir} -o \
			actions-runner-linux-${ARCH}-${LATEST}.tar.gz -L \
			https://github.com/actions/runner/releases/download/v${LATEST}/actions-runner-linux-${arch}-${LATEST}.tar.gz

			# make runners each under its own user
			for i in $(seq -w $start $stop)
			do
				local token=$(curl -s \
				-X POST \
				-H "Accept: application/vnd.github+json" \
				-H "Authorization: Bearer ${gh_token}"\
				-H "X-GitHub-Api-Version: 2022-11-28" \
				https://api.github.com/${prefix}/${registration_url}/actions/runners/registration-token | jq -r .token)

				if ! ${module_options["module_armbian_runners,feature"]} ${commands[1]} ${runner_name} "${i}"; then
					# `remove` returns non-zero when GitHub refused
					# the DELETE — almost always because the runner
					# is currently running a job. Skip this index;
					# the existing runner keeps doing its work
					# untouched, and the next install pass will
					# pick it up when it's idle.
					echo "Skipping install of runner ${i} (${runner_name}-${i}) — currently busy on GitHub" >&2
					continue
				fi

				adduser --quiet --disabled-password --shell /bin/bash \
				--home /home/actions-runner-${i} --gecos "actions-runner-${i}" actions-runner-${i}

				# add to sudoers
				if ! sudo grep -q "actions-runner-${i}" /etc/sudoers; then
					echo "actions-runner-${i} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
				fi
				usermod -aG docker actions-runner-${i}
				tar xzf ${temp_dir}/actions-runner-linux-${ARCH}-${LATEST}.tar.gz -C /home/actions-runner-${i}
				chown -R actions-runner-${i}:actions-runner-${i} /home/actions-runner-${i}

				# 1st runner has different labels
				local label=$label_secondary
				if [[ "$i" == "${start}" ]]; then
					local label=$label_primary
				fi

				runuser -l actions-runner-${i} -c \
				"./config.sh --url https://github.com/${registration_url} \
				--token ${token} --labels ${label} --name ${runner_name}-${i} --unattended"
				if [[ -f /home/actions-runner-${i}/svc.sh ]]; then
					sh -c "cd /home/actions-runner-${i} ; \
					sudo ./svc.sh install actions-runner-${i} 2>/dev/null; \
					sudo ./svc.sh start actions-runner-${i} >/dev/null"
				fi
			done

			# Install the runner-cleanup maintenance helper alongside
			# the runners themselves. Script + systemd units are
			# always overwritten so a `module_armbian_runners install`
			# brings them up to date; the operator-edited conf at
			# /etc/armbian/runner-cleanup.conf is preserved on
			# re-install (template dropped as .conf.dist so admins
			# can diff for new defaults).
			#
			# Asset path resolution: in a source checkout the assets
			# sit next to this module under tools/modules/system/.
			# In the installed .deb they ship to
			# /usr/share/armbian-config/runner-cleanup/ — debian.conf
			# adds the rule, mirroring how the desktops assets are
			# laid out. Try BASH_SOURCE-relative first (dev), fall
			# back to the install path (production).
			local cleanup_src=""
			if [[ -d "$(dirname "${BASH_SOURCE[0]}")/runner-cleanup" ]]; then
				cleanup_src="$(dirname "${BASH_SOURCE[0]}")/runner-cleanup"
			elif [[ -d /usr/share/armbian-config/runner-cleanup ]]; then
				cleanup_src=/usr/share/armbian-config/runner-cleanup
			fi
			if [[ -n "$cleanup_src" ]]; then
				install -m 0755 "${cleanup_src}/runner-cleanup"         /usr/local/sbin/runner-cleanup
				install -m 0644 "${cleanup_src}/runner-cleanup.service" /etc/systemd/system/runner-cleanup.service
				install -m 0644 "${cleanup_src}/runner-cleanup.timer"   /etc/systemd/system/runner-cleanup.timer
				install -d /etc/armbian
				if [[ ! -e /etc/armbian/runner-cleanup.conf ]]; then
					install -m 0644 "${cleanup_src}/runner-cleanup.conf" /etc/armbian/runner-cleanup.conf
				fi
				install -m 0644 "${cleanup_src}/runner-cleanup.conf" /etc/armbian/runner-cleanup.conf.dist
				# Event-driven per-runner _diag/pages cleanup. The hourly
				# runner-cleanup timer is the catch-all; this layer fires
				# on every runner unit start/stop so collisions never
				# survive a quick restart cycle. install-runner-hooks
				# scans every actions.runner.*.service installed by the
				# svc.sh step above and drops in ExecStartPre/StopPost
				# wired to /usr/local/sbin/runner-clean-pages.
				install -m 0755 "${cleanup_src}/runner-clean-pages"     /usr/local/sbin/runner-clean-pages
				systemctl daemon-reload
				# Don't silence errors here — a failed timer install
				# means the cleanup never fires and the host quietly
				# accumulates disk. Show stderr; on the first command's
				# failure, fall back to enable + start separately so we
				# can pinpoint which half went wrong, and log each.
				if ! systemctl enable --now runner-cleanup.timer; then
					echo "Warning: 'systemctl enable --now runner-cleanup.timer' failed; retrying separately" >&2
					systemctl enable runner-cleanup.timer || \
						echo "Error: 'systemctl enable runner-cleanup.timer' failed" >&2
					systemctl start  runner-cleanup.timer || \
						echo "Error: 'systemctl start runner-cleanup.timer' failed" >&2
				fi
				# Wire up the systemd drop-ins for every runner unit
				# that the svc.sh loop above just installed. Runs after
				# daemon-reload so the new drop-ins take effect on the
				# next runner restart cycle. Non-fatal — runner units
				# already started above keep working without hooks
				# until the operator restarts them.
				if ! bash "${cleanup_src}/install-runner-hooks"; then
					echo "Warning: install-runner-hooks failed; runner-clean-pages systemd hooks not in place" >&2
				fi
			else
				echo "Warning: runner-cleanup assets not found in source tree next to module or at /usr/share/armbian-config/runner-cleanup; skipping maintenance helper install" >&2
			fi

		;;
		"${commands[1]}")
			# delete if previous already exists
			echo "Removing runner $3 on GitHub"
			if ! ${module_options["module_armbian_runners,feature"]} ${commands[2]} "$2-$3"; then
				# Most common failure: GitHub returned 422 because
				# the runner is currently running a job. Don't proceed
				# with the local cleanup — that would leave a state
				# where GitHub still thinks the runner exists, the
				# host has no install, and the subsequent config.sh
				# would fail with 'A runner exists with the same name'.
				echo "Skipping local removal of actions-runner-$3 — GitHub delete failed (runner likely busy)" >&2
				return 1
			fi
			echo "Removing runner $3 locally"
			runner_home=$(getent passwd "actions-runner-${3}" | cut -d: -f6)
			if [[ -f "${runner_home}/svc.sh" ]]; then
				sh -c "cd ${runner_home} ; sudo ./svc.sh stop actions-runner-$3 >/dev/null; sudo ./svc.sh uninstall actions-runner-$3 >/dev/null"
			fi
			userdel -r -f actions-runner-$3 2>/dev/null
			groupdel actions-runner-$3 2>/dev/null
			sed -i "/^actions-runner-$3.*/d" /etc/sudoers
			[[ ${runner_home} != "/" ]] && rm -rf "${runner_home}"
		;;
		"${commands[2]}")
			DELETE=$2
			x=1
			# Failure flag — set on any non-204 DELETE response. The
			# most common case is HTTP 422 'runner is currently
			# running a job', which we don't want to silently swallow:
			# without it the caller proceeds with local cleanup and
			# leaves a half-state where GitHub thinks the runner exists
			# but the host has nothing for it.
			local delete_failed=0
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
					local resp_body http_code
					resp_body=$(mktemp)
					http_code=$(curl -s -L \
					-X DELETE \
					-H "Accept: application/vnd.github+json" \
					-H "Authorization: Bearer ${gh_token}"\
					-H "X-GitHub-Api-Version: 2022-11-28" \
					-o "${resp_body}" -w '%{http_code}' \
					https://api.github.com/${prefix}/${registration_url}/actions/runners/${RUNNER_ID})
					if [[ "$http_code" != "204" ]]; then
						echo "  ! DELETE ${RUNNER_NAME} returned HTTP ${http_code}:" >&2
						cat "${resp_body}" >&2
						echo >&2
						delete_failed=1
					fi
					rm -f "${resp_body}"
				fi
			done <<< $RUNNER
			x=$(( $x + 1 ))
			done
			return $delete_failed
		;;
		"${commands[3]}")
			if [[ -z $gh_token ]]; then
				echo "Error: Github token is mandatory"
				${module_options["module_armbian_runners,feature"]} ${commands[6]}
				exit 1
			fi
			for i in $(seq -w $start $stop); do
				${module_options["module_armbian_runners,feature"]} ${commands[1]} ${runner_name}
			done
		;;
		"${commands[4]}")
			if [[ $(systemctl list-units --type=service 2>/dev/null | grep actions.runner) -gt 0 ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[6]}")
			echo -e "\nUsage: ${module_options["module_armbian_runners,feature"]} <command> [switches]"
			echo -e "Commands:  install purge"
			echo -e "Available commands:\n"
			echo -e "\tinstall\t\t- Install or reinstall $title."
			echo -e "\tpurge\t\t- Purge $title."
			echo -e "\tstatus\t\t- Status of $title."
			echo -e "\nAvailable switches:\n"
			echo -e "\tgh_token\t- token with rights to admin runners."
			echo -e "\trunner_name\t- name of the runner (series)."
			echo -e "\tstart\t\t- start of serie (01)."
			echo -e "\tstop\t\t- stop (01)."
			echo -e "\tlabel_primary\t- runner tags for first runner (alfa)."
			echo -e "\tlabel_secondary\t- runner tags for all others (images)."
			echo -e "\torganisation\t- GitHub organisation name (armbian)."
			echo -e "\towner\t\t- GitHub owner."
			echo -e "\trepository\t- GitHub repository (if adding only for repo)."
			echo ""
		;;
		*)
			${module_options["module_armbian_runners,feature"]} ${commands[6]}
		;;
	esac
}
