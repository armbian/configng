# Borgmatic module
module_options+=(
	["module_borgmatic,author"]=""
	["module_borgmatic,maintainer"]="@igorpecovnik"
	["module_borgmatic,feature"]="module_borgmatic"
	["module_borgmatic,example"]="install remove purge status help"
	["module_borgmatic,desc"]="Install Borgmatic backup container (local repo, rsync pull)"
	["module_borgmatic,status"]="Active"
	["module_borgmatic,doc_link"]="https://github.com/borgmatic-collective/docker-borgmatic"
	["module_borgmatic,group"]="Management"
	["module_borgmatic,port"]=""
	["module_borgmatic,arch"]="x86-64 arm64"
)

#
# Module borgmatic
#
function module_borgmatic () {
	local title="borgmatic"
	local condition
	condition=$(which "$title" 2>/dev/null || true)

	# Local-repo variant:
	# $2 = BORG_PASSPHRASE  (optional, default: armbian)
	# $3 = BACKUP_CRON      (optional, default: 0 1 * * *)
	local BORG_PASSPHRASE="$2"
	local BACKUP_CRON="$3"

	if pkg_installed docker-ce; then
		local container
		container=$(docker ps -q -f "name=^borgmatic$")
		local image
		image=$(docker images -q ghcr.io/borgmatic-collective/borgmatic)
	fi

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_borgmatic,example"]}"

	BORG_BASE="${SOFTWARE_FOLDER}/borgmatic"

	case "$1" in
		"${commands[0]}") # install
			if [[ -t 1 ]]; then
				# Interactive mode: ask for passphrase and cron if not provided
				if [[ -z "$BORG_PASSPHRASE" ]]; then
					BORG_PASSPHRASE=$($DIALOG --title "Borgmatic passphrase" \
						--passwordbox "Encryption passphrase for Borg repository:" \
						8 60 3>&1 1>&2 2>&3)
				fi

				if [[ -z "$BACKUP_CRON" ]]; then
					BACKUP_CRON=$($DIALOG --title "Backup schedule (cron)" \
						--inputbox "Cron expression for automatic backups:" \
						8 60 "0 1 * * *" 3>&1 1>&2 2>&3)
				fi

				[[ -z "$BORG_PASSPHRASE" ]] && BORG_PASSPHRASE="armbian"
				[[ -z "$BACKUP_CRON" ]] && BACKUP_CRON="0 1 * * *"

				clear
			else
				# Non-interactive defaults
				[[ -z "$BORG_PASSPHRASE" ]] && BORG_PASSPHRASE="armbian"
				[[ -z "$BACKUP_CRON" ]] && BACKUP_CRON="0 1 * * *"
			fi

			pkg_installed docker-ce || module_docker install

			[[ -d "$BORG_BASE" ]] || mkdir -p "$BORG_BASE" || { echo "Couldn't create storage directory: $BORG_BASE"; exit 1; }

			# Layout:
			#   $BORG_BASE/config        -> /etc/borgmatic.d
			#   $BORG_BASE/repo          -> /repo       (local Borg repo)
			#   $BORG_BASE/.config/borg  -> /root/.config/borg
			#   $BORG_BASE/.ssh          -> /root/.ssh
			#   $BORG_BASE/.cache/borg   -> /root/.cache/borg
			#   $BORG_BASE/.state        -> /root/.local/state/borgmatic
			mkdir -p \
				"$BORG_BASE/config" \
				"$BORG_BASE/repo" \
				"$BORG_BASE/.config/borg" \
				"$BORG_BASE/.ssh" \
				"$BORG_BASE/.cache/borg" \
				"$BORG_BASE/.state"

			# If no config exists yet, create a minimal Home Assistant config
			if [[ ! -f "${BORG_BASE}/config/config.yaml" ]]; then
				cat > "${BORG_BASE}/config/config.yaml" << 'EOF'
location:
  # Local directories inside the container (populated by rsync)
  source_directories:
    - /mnt/homeassistant

  # Local Borg repository inside the container (persisted via volume)
  repositories:
    - /repo

  archive_name_format: 'backup-{now:%Y-%m-%dT%H:%M:%S}'

storage:
  # Provided by environment variable BORG_PASSPHRASE
  encryption_passphrase: !ENV BORG_PASSPHRASE
  compression: zstd

retention:
  keep_daily: 7
  keep_weekly: 4
  keep_monthly: 6

consistency:
  checks:
    - repository
    - archives
  check_last: 3

hooks:
  before_backup:
    - mkdir -p /mnt/homeassistant

    # Sync Home Assistant config from remote host "homeassistant"
    # Adjust host/path and SSH key as needed.
    - echo "Syncing Home Assistant..."
    - rsync -a --delete -e "ssh -i /root/.ssh/id_homeassistant" \
        homeassistant:/config/ /mnt/homeassistant/

  after_backup:
    - echo "Backup finished successfully."

  on_error:
    - echo "Backup FAILED." >&2
EOF
				echo "Created initial config at: ${BORG_BASE}/config/config.yaml"
				echo "Adjust 'homeassistant:/config/' and SSH key path in hooks.before_backup as needed."
			fi

			# Pull latest image
			docker pull ghcr.io/borgmatic-collective/borgmatic:latest

			# Stop/remove existing container if present
			if docker ps -a --format '{{.Names}}' | grep -q '^borgmatic$'; then
				docker rm -f borgmatic >/dev/null 2>&1 || true
			fi

			# Environment arguments
			local env_args=(
				"-e" "TZ=$(cat /etc/timezone)"
				"-e" "BORG_PASSPHRASE=${BORG_PASSPHRASE}"
				"-e" "BACKUP_CRON=${BACKUP_CRON}"
			)

			# Run container – local repo at /repo, rsync from Home Assistant
			if ! docker run -d \
				--name=borgmatic \
				"${env_args[@]}" \
				-v "${BORG_BASE}/config:/etc/borgmatic.d" \
				-v "${BORG_BASE}/repo:/repo" \
				-v "${BORG_BASE}/.config/borg:/root/.config/borg" \
				-v "${BORG_BASE}/.ssh:/root/.ssh" \
				-v "${BORG_BASE}/.cache/borg:/root/.cache/borg" \
				-v "${BORG_BASE}/.state:/root/.local/state/borgmatic" \
				--restart unless-stopped \
				ghcr.io/borgmatic-collective/borgmatic:latest ; then
				echo "❌ Failed to start Borgmatic container"
				exit 1
			fi

			echo
			echo "Borgmatic container (local repo, rsync from Home Assistant) is running."
			echo "Repository path on host: ${BORG_BASE}/repo"
			echo "Config path:            ${BORG_BASE}/config/config.yaml"
			echo "SSH keys path:          ${BORG_BASE}/.ssh"
			echo
			echo "IMPORTANT:"
			echo "  • Place SSH key for Home Assistant at: ${BORG_BASE}/.ssh/id_homeassistant"
			echo "  • Ensure that key has access to 'homeassistant:/config'."
			echo "  • First-time repo init (inside container), for example:"
			echo "        docker exec -it borgmatic /bin/sh"
			echo "        borgmatic init --encryption repokey"
			echo
		;;
		"${commands[1]}") # remove
			if [[ -n "${container}" ]]; then
				docker container rm -f "$container" >/dev/null
			fi
		;;
		"${commands[2]}") # purge
			${module_options["module_borgmatic,feature"]} ${commands[1]}
			if [[ -n "${image}" ]]; then
				docker image rm "$image" >/dev/null
			fi
			if [[ -n "${BORG_BASE}" && "${BORG_BASE}" != "/" ]]; then
				rm -rf "${BORG_BASE}"
			fi
		;;
		"${commands[3]}") # status
			if [[ "${container}" && "${image}" ]]; then
				return 0
			else
				return 1
			fi
		;;
		"${commands[4]}") # help
			echo -e "\nUsage: ${module_options["module_borgmatic,feature"]} <command> [options]"
			echo -e "Commands:  ${module_options["module_borgmatic,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Install $title container (local repo, rsync from Home Assistant)."
			echo -e "\tremove\t- Remove $title container (keep data)."
			echo -e "\tpurge\t- Remove $title container and data."
			echo -e "\tstatus\t- Installation status of $title."
			echo -e "\thelp\t- Show this help message."
			echo
			echo "Install parameters (optional, can be prompted interactively):"
			echo -e "\t${module_options["module_borgmatic,feature"]} install [BORG_PASSPHRASE] [BACKUP_CRON]"
			echo
			echo -e "\tBORG_PASSPHRASE\tEncryption passphrase (default: armbian)"
			echo -e "\tBACKUP_CRON\tCron expression (default: \"0 1 * * *\")"
			echo
			echo "Notes:"
			echo "  • Local Borg repo is stored under: ${SOFTWARE_FOLDER}/borgmatic/repo (mounted as /repo in container)."
			echo "  • Default config pulls from 'homeassistant:/config' via rsync in hooks.before_backup."
			echo "  • Put SSH key for Home Assistant at: ${SOFTWARE_FOLDER}/borgmatic/.ssh/id_homeassistant"
			echo
		;;
		*)
			${module_options["module_borgmatic,feature"]} ${commands[4]}
		;;
	esac
}
