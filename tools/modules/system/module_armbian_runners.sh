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
	#
	# Assigned with printf -v against an allow-list rather than eval: these
	# values come straight off the command line, and `eval "$feature=$value"`
	# ran anything a value contained. Splitting on the FIRST '=' only also
	# keeps values that themselves contain '=' intact - the old
	# IFS='=' read -a split kept just the first field, silently truncating
	# such a value.
	local var kv key value
	for var in "$@"; do
		# shellcheck disable=SC2086 # deliberate word split: one argument may carry several key=value pairs
		for kv in ${var}; do
			[[ "${kv}" == *=* ]] || continue
			key="${kv%%=*}"
			value="${kv#*=}"
			case "${key}" in
				gh_token|runner_name|start|stop|label_primary|label_secondary|organisation|owner|repository)
					printf -v "${key}" '%s' "${value}" ;;
			esac
		done
	done

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_armbian_runners,example"]}"

	# Derive the GitHub registration target (org or owner/repo) for ALL
	# subcommands — not just install — so remove/remove_online/purge can
	# reach the API too. Previously these lived inside the install case, so
	# every other subcommand built a malformed '//actions/runners' URL.
	local registration_url="${organisation:-armbian}"
	local prefix="orgs"
	if [[ -n "${owner}" && -n "${repository}" ]]; then
		registration_url="${owner}/${repository}"
		prefix="repos"
	fi

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
				${module_options["module_armbian_runners,feature"]} ${commands[5]}
				exit 1
			fi

			# default values if not defined
			local gh_token="${gh_token}"
			local runner_name="${runner_name:-armbian}"
			local start="${start:-01}"
			local stop="${stop:-01}"
			local organisation="${organisation:-armbian}"
			local owner="${owner}"
			local repository="${repository}"

			# workaround. Remove when parameters handling is fixed
			label_primary="${label_primary//_/,}"
			label_secondary="${label_secondary//_/,}"

			# Label fallback.
			#
			# These used to be "${label_primary:-alfa}" and
			# "${label_secondary:-fast,images}", but :- cannot tell an empty
			# value from an unset one, so deliberately clearing the secondary
			# label silently brought back "fast,images" on every runner after
			# the first. An empty secondary now means "label them like the
			# first one", and an empty primary falls back to the label GitHub
			# gives every self-hosted runner anyway.
			[[ -z "${label_primary}" ]] && label_primary="self-hosted"
			[[ -z "${label_secondary}" ]] && label_secondary="${label_primary}"

			# Docker preinstall is needed for our build framework
			pkg_installed docker-ce || module_docker install
			pkg_update
			pkg_install jq curl libicu-dev mktorrent rsync

			# download latest runner package
			local temp_dir=$(mktemp -d)
			trap '{ rm -rf -- "$temp_dir"; }' EXIT

			# That trap is shell-scoped, not function-scoped: it fires when
			# armbian-config exits, not when this returns. Without an explicit
			# call the directory survives every early return, and on success the
			# ~200MB runner tarball sits there for the rest of the session.
			runner_temp_cleanup() { rm -rf -- "${temp_dir}"; trap - EXIT; }
			[[ "$ARCH" == "x86_64" ]] && local arch=x64 || local arch=arm64
			# Ask GitHub for the latest runner release, authenticated with the
			# same token the registration calls use: unauthenticated api.github.com
			# allows 60 requests an hour per IP, and once that is spent the reply
			# is an error object rather than the expected array, which used to end
			# as `jq: Cannot index object with number` and an empty LATEST.
			#
			# releases/latest rather than tags[0]: it states which release is
			# current instead of trusting the order tags come back in.
			local LATEST
			LATEST=$(curl -fsSL \
				-H "Accept: application/vnd.github+json" \
				${gh_token:+-H "Authorization: Bearer ${gh_token}"} \
				-H "X-GitHub-Api-Version: 2022-11-28" \
				https://api.github.com/repos/actions/runner/releases/latest | jq -r '.tag_name // empty' | sed "s/^v//")

			# Everything below removes the running runners before reinstalling
			# them, so refuse to start when the version lookup failed - otherwise
			# a rate-limited API call deletes the fleet and cannot rebuild it.
			if [[ ! "${LATEST}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
				echo "Could not determine the latest actions/runner release (got '${LATEST:-<empty>}')." >&2
				echo "Pass a GitHub token if you are being rate limited; no runners were touched." >&2
				runner_temp_cleanup
				return 1
			fi

			local runner_tarball="${temp_dir}/actions-runner-linux-${ARCH}-${LATEST}.tar.gz"
			# --fail, or curl writes the 404 body to the file, reports 100% and
			# leaves tar to complain that stdin is not in gzip format.
			if ! curl --fail --progress-bar --create-dirs --output-dir ${temp_dir} -o \
				actions-runner-linux-${ARCH}-${LATEST}.tar.gz -L \
				https://github.com/actions/runner/releases/download/v${LATEST}/actions-runner-linux-${arch}-${LATEST}.tar.gz; then
				echo "Download of actions-runner ${LATEST} (${arch}) failed; no runners were touched." >&2
				runner_temp_cleanup
				return 1
			fi

			# Verify the archive before anything is removed.
			if ! tar tzf "${runner_tarball}" >/dev/null 2>&1; then
				echo "Downloaded actions-runner ${LATEST} archive is not a valid tarball; no runners were touched." >&2
				runner_temp_cleanup
				return 1
			fi

			# make runners each under its own user.
			#
			# The index list is materialised first so the "is this the first
			# runner" test can compare against what seq actually produced.
			# seq -w pads to the width of the widest bound, so `start=1
			# stop=10` yields 01..10 and the old `[[ "$i" == "${start}" ]]`
			# never matched - with unpadded bounds no runner got the primary
			# label at all.
			local -a runner_indices=()
			mapfile -t runner_indices < <(seq -w "${start}" "${stop}")
			if [[ ${#runner_indices[@]} -eq 0 ]]; then
				echo "Refusing to install: start='${start}' stop='${stop}' selects no runners." >&2
				runner_temp_cleanup
				return 1
			fi
			local first_index="${runner_indices[0]}"
			local install_failed=0

			echo "Installing runners ${runner_indices[0]}..${runner_indices[-1]} for ${prefix}/${registration_url}"
			echo "  ${runner_name}-${first_index} labels: ${label_primary}"
			if [[ ${#runner_indices[@]} -gt 1 ]]; then
				echo "  remaining runners labels: ${label_secondary}"
			fi

			local i
			for i in "${runner_indices[@]}"
			do
				local token
				token=$(curl -s \
				-X POST \
				-H "Accept: application/vnd.github+json" \
				-H "Authorization: Bearer ${gh_token}"\
				-H "X-GitHub-Api-Version: 2022-11-28" \
				https://api.github.com/${prefix}/${registration_url}/actions/runners/registration-token | jq -r '.token // empty')

				# A rejected token, a wrong org or a rate limit all return a
				# JSON error object here. Without this the empty/"null" token
				# was handed to config.sh, which failed after the user had
				# already been created and the old runner removed.
				if [[ -z "${token}" ]]; then
					echo "Could not get a registration token for ${prefix}/${registration_url} (runner ${i}); check the GitHub token and its scopes." >&2
					install_failed=1
					continue
				fi

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

				# add to sudoers via a drop-in, validated before it counts.
				# Appending to /etc/sudoers directly means one malformed line
				# locks every user out of sudo on the machine, with no way
				# back in without a rescue boot.
				install -d -m 0755 /etc/sudoers.d
				local sudoers_tmp="/etc/sudoers.d/.actions-runner-${i}.tmp"
				printf '%s ALL=(ALL) NOPASSWD: ALL\n' "actions-runner-${i}" > "${sudoers_tmp}"
				chmod 0440 "${sudoers_tmp}"
				if visudo -cf "${sudoers_tmp}" >/dev/null 2>&1; then
					mv -f "${sudoers_tmp}" "/etc/sudoers.d/actions-runner-${i}"
				else
					rm -f "${sudoers_tmp}"
					echo "Refusing to grant sudo to actions-runner-${i}: generated sudoers rule did not validate" >&2
					install_failed=1
					continue
				fi
				usermod -aG docker actions-runner-${i}
				tar xzf "${runner_tarball}" -C /home/actions-runner-${i}
				chown -R actions-runner-${i}:actions-runner-${i} /home/actions-runner-${i}

				# 1st runner has different labels
				local label="${label_secondary}"
				if [[ "${i}" == "${first_index}" ]]; then
					label="${label_primary}"
				fi

				# config.sh is what actually registers the runner with GitHub. Its
				# exit status has to be checked: svc.sh ships inside the tarball, so
				# the -f test below is true whether or not registration succeeded, and
				# installing a service for an unregistered runner leaves a unit that
				# can never start. Unchecked, a failure here also left install_failed
				# at 0 and the whole install reported success.
				if ! runuser -l "actions-runner-${i}" -c \
					"./config.sh --url https://github.com/${registration_url} \
					--token ${token} --labels '${label}' --name '${runner_name}-${i}' --unattended"; then
					echo "Failed to register runner ${runner_name}-${i} with ${registration_url}; skipping its service install." >&2
					install_failed=1
					continue
				fi
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
				# Per-job workspace chown. Docker builds leave root-owned
				# files under _work that break the next job's checkout
				# cleanup. The runner runs this after every job via
				# ACTIONS_RUNNER_HOOK_JOB_COMPLETED (wired into each
				# runner's .env below).
				# The GitHub runner validates the hook path and rejects it
				# unless it ends in .sh/.ps1/.js, so the installed name keeps
				# the .sh extension. Remove the old extensionless copy left by
				# earlier installs.
				install -m 0755 "${cleanup_src}/runner-job-completed.sh" /usr/local/sbin/runner-job-completed.sh
				rm -f /usr/local/sbin/runner-job-completed
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

				# Wire the post-job chown hook into every runner's .env. The
				# runner loads ACTIONS_RUNNER_HOOK_JOB_COMPLETED from .env at
				# service start and runs it (as the runner user, which has
				# passwordless sudo) after each job. Idempotent; covers
				# already-installed runners too. Takes effect on each runner's
				# next (re)start, so we don't force-restart busy ones here.
				local job_hook_path="/usr/local/sbin/runner-job-completed.sh"
				local runner_home runner_owner env_file
				for runner_home in /home/actions-runner-*; do
					[[ -d "$runner_home" ]] || continue
					runner_owner="$(stat -c '%U' "$runner_home")"
					env_file="${runner_home}/.env"
					touch "$env_file"
					if grep -q '^ACTIONS_RUNNER_HOOK_JOB_COMPLETED=' "$env_file"; then
						sed -i "s#^ACTIONS_RUNNER_HOOK_JOB_COMPLETED=.*#ACTIONS_RUNNER_HOOK_JOB_COMPLETED=${job_hook_path}#" "$env_file"
					else
						echo "ACTIONS_RUNNER_HOOK_JOB_COMPLETED=${job_hook_path}" >> "$env_file"
					fi
					chown "${runner_owner}:${runner_owner}" "$env_file"
				done
			else
				echo "Warning: runner-cleanup assets not found in source tree next to module or at /usr/share/armbian-config/runner-cleanup; skipping maintenance helper install" >&2
			fi

			runner_temp_cleanup
			return $install_failed

		;;
		"${commands[1]}")
			# `remove` is called two ways:
			#   * internally by install/purge with positional args:
			#       remove <runner_name> <index>
			#   * directly via --api with named params and an index range:
			#       remove runner_name=<n> start=<a> stop=<b> [organisation=..]
			# A bare (no '=') $2 is the positional form; otherwise the named
			# params parsed above drive a start..stop range.
			if [[ -z "${gh_token}" ]]; then
				echo "Error: Github token is mandatory" >&2
				${module_options["module_armbian_runners,feature"]} ${commands[5]}
				return 1
			fi

			local rm_name rm_indices
			if [[ -n "$2" && "$2" != *=* ]]; then
				rm_name="$2"
				rm_indices="$3"
			else
				rm_name="${runner_name:-armbian}"
				if [[ -n "${start}" || -n "${stop}" ]]; then
					rm_indices="$(seq -w "${start:-01}" "${stop:-01}")"
				fi
			fi

			local rm_failed=0 idx target runner_home
			for idx in ${rm_indices:-__bare__}; do
				if [[ "$idx" == "__bare__" ]]; then
					target="${rm_name}"
				else
					target="${rm_name}-${idx}"
				fi

				echo "Removing runner ${target} on GitHub"
				if ! ${module_options["module_armbian_runners,feature"]} ${commands[2]} "${target}"; then
					# Most common failure: GitHub returned 422 because
					# the runner is currently running a job. Don't proceed
					# with the local cleanup — that would leave a state
					# where GitHub still thinks the runner exists, the
					# host has no install, and the subsequent config.sh
					# would fail with 'A runner exists with the same name'.
					echo "Skipping local removal of actions-runner-${idx} — GitHub delete failed (runner likely busy)" >&2
					rm_failed=1
					continue
				fi

				# Without an index we can't map to a local user — GitHub-only.
				[[ "$idx" == "__bare__" ]] && continue

				echo "Removing runner ${idx} locally"
				runner_home=$(getent passwd "actions-runner-${idx}" | cut -d: -f6)
				if [[ -f "${runner_home}/svc.sh" ]]; then
					sh -c "cd ${runner_home} ; sudo ./svc.sh stop actions-runner-${idx} >/dev/null; sudo ./svc.sh uninstall actions-runner-${idx} >/dev/null"
				fi
				userdel -r -f actions-runner-${idx} 2>/dev/null
				groupdel actions-runner-${idx} 2>/dev/null
				rm -f "/etc/sudoers.d/actions-runner-${idx}"
				# Older installs appended straight to /etc/sudoers; clear those too.
				sed -i "/^actions-runner-${idx}[[:space:]]/d" /etc/sudoers
				[[ -n "${runner_home}" && ${runner_home} != "/" ]] && rm -rf "${runner_home}"
			done
			return $rm_failed
		;;
		"${commands[2]}")
			local DELETE="$2"
			if [[ -z "${gh_token}" ]]; then
				echo "Error: Github token is mandatory" >&2
				return 1
			fi
			if [[ -z "${DELETE}" ]]; then
				echo "Error: no runner name given to ${commands[2]}" >&2
				return 1
			fi

			# Failure flag — set on any non-204 DELETE response. The
			# most common case is HTTP 422 'runner is currently
			# running a job', which we don't want to silently swallow:
			# without it the caller proceeds with local cleanup and
			# leaves a half-state where GitHub thinks the runner exists
			# but the host has nothing for it.
			local delete_failed=0 x=1 page_body page_code listed
			local per_page=100

			# Walk pages until one comes back short. The old loop asked for
			# pages 1..9 unconditionally - nine API calls to delete one
			# runner, and its own comment admitted a tenth page was out of
			# reach. per_page=100 means one call covers most fleets.
			while true; do
				page_body=$(mktemp)
				page_code=$(curl -s -L \
				-H "Accept: application/vnd.github+json" \
				-H "Authorization: Bearer ${gh_token}" \
				-H "X-GitHub-Api-Version: 2022-11-28" \
				-o "${page_body}" -w '%{http_code}' \
				"https://api.github.com/${prefix}/${registration_url}/actions/runners?per_page=${per_page}&page=${x}")

				# A bad token, a missing scope or a wrong org returns a JSON
				# error object, whose .runners is null. Piping that straight
				# into `.runners[]` is what produced
				#   jq: error (at <stdin>:4): Cannot iterate over null (null)
				# and then carried on as if no runners existed.
				if [[ "${page_code}" != "200" ]]; then
					echo "Listing runners for ${prefix}/${registration_url} failed with HTTP ${page_code}:" >&2
					jq -r '.message // empty' "${page_body}" >&2 2>/dev/null || cat "${page_body}" >&2
					rm -f "${page_body}"
					return 1
				fi

				if ! listed=$(jq -r '(.runners // [])[] | "\(.id),\(.name)"' "${page_body}" 2>/dev/null); then
					echo "Could not parse the runner list for ${prefix}/${registration_url}" >&2
					rm -f "${page_body}"
					return 1
				fi
				rm -f "${page_body}"

				[[ -z "${listed}" ]] && break

				local DATA RUNNER_ID RUNNER_NAME
				while IFS= read -r DATA; do
					[[ -z "${DATA}" ]] && continue
					RUNNER_ID="${DATA%%,*}"
					RUNNER_NAME="${DATA#*,}"
					# Quoted: an unquoted right-hand side is a glob, so a
					# runner name containing * or ? matched - and deleted -
					# every other runner in the org.
					if [[ "${RUNNER_NAME}" == "${DELETE}" ]]; then
						echo "Delete existing: ${RUNNER_NAME}"
						local resp_body http_code
						resp_body=$(mktemp)
						http_code=$(curl -s -L \
						-X DELETE \
						-H "Accept: application/vnd.github+json" \
						-H "Authorization: Bearer ${gh_token}"\
						-H "X-GitHub-Api-Version: 2022-11-28" \
						-o "${resp_body}" -w '%{http_code}' \
						"https://api.github.com/${prefix}/${registration_url}/actions/runners/${RUNNER_ID}")
						if [[ "$http_code" != "204" ]]; then
							echo "  ! DELETE ${RUNNER_NAME} returned HTTP ${http_code}:" >&2
							cat "${resp_body}" >&2
							echo >&2
							delete_failed=1
						fi
						rm -f "${resp_body}"
					fi
				done <<< "${listed}"

				# A short page is the last page.
				[[ "$(printf '%s\n' "${listed}" | wc -l)" -lt "${per_page}" ]] && break
				x=$(( x + 1 ))
			done
			return $delete_failed
		;;
		"${commands[3]}")
			if [[ -z $gh_token ]]; then
				echo "Error: Github token is mandatory"
				${module_options["module_armbian_runners,feature"]} ${commands[5]}
				exit 1
			fi
			# seq with empty bounds errors out; default them the way remove does.
			local purge_failed=0 i
			for i in $(seq -w "${start:-01}" "${stop:-01}"); do
				${module_options["module_armbian_runners,feature"]} ${commands[1]} "${runner_name:-armbian}" "${i}" || purge_failed=1
			done
			return $purge_failed
		;;
		"${commands[4]}")
			if [[ $(systemctl list-units --type=service --no-legend 2>/dev/null | grep -c actions.runner) -gt 0 ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[5]}")
			echo -e "\nUsage: ${module_options["module_armbian_runners,feature"]} <command> [switches]"
			echo -e "Commands:  install remove remove_online purge status help"
			echo -e "Available commands:\n"
			echo -e "\tinstall\t\t- Install or reinstall $title."
			echo -e "\tremove\t\t- Remove a single runner (locally and on GitHub)."
			echo -e "\tremove_online\t- Remove matching runners on GitHub only."
			echo -e "\tpurge\t\t- Purge $title."
			echo -e "\tstatus\t\t- Status of $title."
			echo -e "\thelp\t\t- Show this help."
			echo -e "\nAvailable switches:\n"
			echo -e "\tgh_token\t- token with rights to admin runners."
			echo -e "\trunner_name\t- name of the runner (series)."
			echo -e "\tstart\t\t- start of serie (01)."
			echo -e "\tstop\t\t- stop (01)."
			echo -e "\tlabel_primary\t- runner tags for first runner (empty: self-hosted)."
			echo -e "\tlabel_secondary\t- runner tags for all others (empty: same as label_primary)."
			echo -e "\torganisation\t- GitHub organisation name (armbian)."
			echo -e "\towner\t\t- GitHub owner."
			echo -e "\trepository\t- GitHub repository (if adding only for repo)."
			echo ""
		;;
		*)
			${module_options["module_armbian_runners,feature"]} ${commands[5]}
		;;
	esac
}
