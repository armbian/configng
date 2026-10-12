module_options+=(
	["module_zotcache,author"]="@project-zot"
	["module_zotcache,maintainer"]="@igorpecovnik"
	["module_zotcache,feature"]="module_zotcache"
	["module_zotcache,example"]="install configure status logs remove purge help"
	["module_zotcache,desc"]="Install zot OCI registry as a pull-through cache + scheduled mirror for ghcr.io/armbian/**"
	["module_zotcache,status"]="Active"
	["module_zotcache,doc_link"]="https://zotregistry.dev/"
	["module_zotcache,group"]="Management"
	["module_zotcache,port"]="5000"
	["module_zotcache,arch"]="x86-64"
	# Pinned image tag. Use the FULL image (not zot-minimal-*) — the minimal
	# variant strips the sync extension and the mirror config is silently
	# ignored. Bump here when upgrading.
	["module_zotcache,dockerimage"]="ghcr.io/project-zot/zot-linux-amd64:v2.1.5"
	["module_zotcache,dockername"]="zot-cache"
)
#
# Module zot-cache
#
function module_zotcache () {
	local title="zot-cache"
	local dockerimage="${module_options["module_zotcache,dockerimage"]}"
	local dockername="${module_options["module_zotcache,dockername"]}"
	local default_port="${module_options["module_zotcache,port"]}"

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_zotcache,example"]}"

	# Persisted operator choices live in /etc/zot/zot-cache.env. Secrets
	# live in their own chmod-600 files (sync-credentials.json, htpasswd)
	# and are NEVER written to this env file.
	local env_file="/etc/zot/zot-cache.env"
	local cfg_file="/etc/zot/config.json"
	local ht_file="/etc/zot/htpasswd"
	local creds_file="/etc/zot/sync-credentials.json"
	local cert_dir="/etc/zot/certs"

	# Defaults sourced first; env_file overrides if present.
	local ZOT_PORT="$default_port"
	local ZOT_STORAGE="/pool/registry"
	local ZOT_POLL="30m"
	local ZOT_PREFIX="armbian/**"
	local ZOT_TAG_REGEX=""
	local ZOT_TLS_CERT="${cert_dir}/zot.crt"
	local ZOT_TLS_KEY="${cert_dir}/zot.key"
	local ZOT_BUILDER_USER="builder"
	local ZOT_ADMIN_USER="admin"
	if [[ -f "$env_file" ]]; then
		# shellcheck disable=SC1090
		source "$env_file"
	fi

	case "$1" in
		"${commands[0]}") # install
			# --- prerequisites ---
			if ! command -v docker >/dev/null 2>&1; then
				echo "Docker not installed; installing via module_docker ..."
				if ! module_docker install; then
					echo "❌ module_docker install failed."
					return 1
				fi
			fi
			if ! docker info >/dev/null 2>&1; then
				echo "❌ Docker daemon is not responding. Start it and retry."
				return 1
			fi
			if ! command -v htpasswd >/dev/null 2>&1; then
				pkg_install apache2-utils || {
					echo "❌ Failed to install apache2-utils (needed for htpasswd)."
					return 1
				}
			fi
			if ! command -v openssl >/dev/null 2>&1; then
				pkg_install openssl || {
					echo "❌ Failed to install openssl."
					return 1
				}
			fi
			if ! command -v jq >/dev/null 2>&1; then
				pkg_install jq || {
					echo "❌ Failed to install jq."
					return 1
				}
			fi

			# --- prompt tunables (defaults pre-loaded above) ---
			if [[ -t 1 ]]; then
				ZOT_STORAGE=$(dialog_inputbox "Storage path"   "Host directory for the registry blob store (will be created if missing)." "$ZOT_STORAGE")
				ZOT_PORT=$(dialog_inputbox    "HTTPS port"     "Port the registry listens on (TLS)." "$ZOT_PORT")
				ZOT_POLL=$(dialog_inputbox    "Pre-warm poll"  "How often the pre-warm sync polls upstream (e.g. 30m, 6h, 24h)." "$ZOT_POLL")
				ZOT_PREFIX=$(dialog_inputbox  "Pre-warm prefix" "Prefix glob to mirror eagerly. 'armbian/**' for the whole org; e.g. 'armbian/build' for one repo." "$ZOT_PREFIX")
				ZOT_TAG_REGEX=$(dialog_inputbox "Tag regex (optional)" "Optional regex to restrict eagerly-mirrored tags (e.g. '^v[0-9]+\\\\.' for release tags). Blank = mirror every tag." "$ZOT_TAG_REGEX")
				clear
			fi
			# Sanity defaults if a prompt was empty / non-interactive.
			ZOT_STORAGE="${ZOT_STORAGE:-/pool/registry}"
			ZOT_PORT="${ZOT_PORT:-5000}"
			ZOT_POLL="${ZOT_POLL:-30m}"
			ZOT_PREFIX="${ZOT_PREFIX:-armbian/**}"

			# --- pull image + detect uid/gid ---
			docker_operation_progress pull "$dockerimage" || {
				echo "❌ Failed to pull $dockerimage"
				return 1
			}

			local id_out zot_uid zot_gid
			id_out=$(docker run --rm --entrypoint id "$dockerimage" 2>/dev/null || true)
			zot_uid=$(echo "$id_out" | grep -oE 'uid=[0-9]+' | head -1 | cut -d= -f2)
			zot_gid=$(echo "$id_out" | grep -oE 'gid=[0-9]+' | head -1 | cut -d= -f2)
			zot_uid="${zot_uid:-1000}"
			zot_gid="${zot_gid:-1000}"

			# --- storage dir, owned by image's runtime uid:gid (NOT root) ---
			install -d -m 0755 "$ZOT_STORAGE" || {
				echo "❌ Failed to create $ZOT_STORAGE"
				return 1
			}
			chown -R "${zot_uid}:${zot_gid}" "$ZOT_STORAGE" || {
				echo "❌ Failed to chown $ZOT_STORAGE to ${zot_uid}:${zot_gid}"
				return 1
			}

			# --- prompt for GHCR PAT, write chmod 600 secrets file ---
			# Skip re-prompt if creds already exist and operator confirms keep.
			local keep_creds=no
			if [[ -f "$creds_file" && -t 1 ]]; then
				dialog_yesno "GHCR credentials" \
					"$creds_file already exists. Keep the stored GitHub PAT?" 10 60 \
					&& keep_creds=yes
			fi
			if [[ "$keep_creds" != "yes" ]]; then
				local gh_user gh_pat
				if [[ -t 1 ]]; then
					gh_user=$(dialog_inputbox    "GitHub username" "GitHub username that owns the PAT (used as the basic-auth username for ghcr.io)." "")
					gh_pat=$(dialog_passwordbox  "GitHub PAT"      "Paste a PAT with the 'read:packages' scope. It is written to $creds_file (chmod 600) and never echoed or logged." 12 70)
					clear
				else
					gh_user="${GHCR_USERNAME:-}"
					gh_pat="${GHCR_PAT:-}"
				fi
				if [[ -z "$gh_user" || -z "$gh_pat" ]]; then
					echo "❌ GHCR credentials are required."
					return 1
				fi
				install -d -m 0755 /etc/zot
				local tmp_creds
				tmp_creds=$(mktemp /etc/zot/.sync-credentials.json.XXXXXX) || return 1
				chmod 0600 "$tmp_creds"
				if ! jq -n --arg user "$gh_user" --arg pass "$gh_pat" \
					'{"ghcr.io": {"username": $user, "password": $pass}}' > "$tmp_creds"
				then
					rm -f "$tmp_creds"
					echo "❌ Failed to write $creds_file (jq)"
					return 1
				fi
				if ! mv "$tmp_creds" "$creds_file"; then
					rm -f "$tmp_creds"
					echo "❌ Failed to install $creds_file (mv)"
					return 1
				fi
				chmod 0600 "$creds_file" || {
					echo "❌ Failed to chmod 0600 $creds_file"
					return 1
				}
				gh_user=""
				gh_pat=""
			fi

			# --- generate htpasswd (builder + admin), show once ---
			local builder_pw admin_pw
			builder_pw=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32)
			admin_pw=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32)
			install -d -m 0755 /etc/zot
			{
				htpasswd -bBn "$ZOT_BUILDER_USER" "$builder_pw"
				htpasswd -bBn "$ZOT_ADMIN_USER"   "$admin_pw"
			} > "$ht_file" || {
				echo "❌ Failed to write $ht_file"
				return 1
			}
			chmod 0640 "$ht_file"
			if [[ -t 1 ]]; then
				dialog_msgbox "zot-cache credentials" \
					"Distribute these credentials to your fleet (shown once).\n\nbuilder (read-only):\n  user: $ZOT_BUILDER_USER\n  pass: $builder_pw\n\nadmin (read/write):\n  user: $ZOT_ADMIN_USER\n  pass: $admin_pw\n\nUse 'builder' on every build host's docker / oras config.\n'admin' is for managing the registry from a workstation." 20 78
			else
				echo "ZOT_BUILDER_USER=$ZOT_BUILDER_USER"
				echo "ZOT_BUILDER_PASSWORD=$builder_pw"
				echo "ZOT_ADMIN_USER=$ZOT_ADMIN_USER"
				echo "ZOT_ADMIN_PASSWORD=$admin_pw"
			fi
			builder_pw=""
			admin_pw=""

			# --- TLS: use operator-supplied cert/key if present, else self-sign ---
			install -d -m 0755 "$cert_dir"
			if [[ ! -f "$ZOT_TLS_CERT" || ! -f "$ZOT_TLS_KEY" ]]; then
				local hostname
				hostname=$(hostname -f 2>/dev/null || hostname)
				if ! openssl req -x509 -nodes -newkey rsa:4096 -days 3650 \
					-keyout "$ZOT_TLS_KEY" -out "$ZOT_TLS_CERT" \
					-subj "/CN=${hostname}" \
					-addext "subjectAltName=DNS:${hostname},IP:${LOCALIPADD:-127.0.0.1}" \
					>/dev/null 2>&1
				then
					echo "❌ openssl cert generation failed."
					return 1
				fi
				chmod 0644 "$ZOT_TLS_CERT"
				chmod 0600 "$ZOT_TLS_KEY"
				echo "⚠️  Generated a self-signed cert for ${hostname}."
				echo "    Distribute $ZOT_TLS_CERT to all build nodes' trust store,"
				echo "    or replace both files with an operator-supplied pair."
			fi

			# --- write config.json (jq-built, no quoting hell) ---
			local tag_clause="null"
			if [[ -n "$ZOT_TAG_REGEX" ]]; then
				tag_clause=$(jq -n --arg re "$ZOT_TAG_REGEX" '{tags: {regex: $re}}')
			fi
			jq -n \
				--arg port "$ZOT_PORT" \
				--arg cert "$ZOT_TLS_CERT" \
				--arg key  "$ZOT_TLS_KEY" \
				--arg poll "$ZOT_POLL" \
				--arg prefix "$ZOT_PREFIX" \
				--arg builder "$ZOT_BUILDER_USER" \
				--arg admin   "$ZOT_ADMIN_USER" \
				--argjson tag_clause "$tag_clause" \
				'
				def content_entry:
					if $tag_clause == null then {prefix: $prefix}
					else {prefix: $prefix} + $tag_clause end;
				{
					distSpecVersion: "1.1.0-dev",
					storage: { rootDirectory: "/var/lib/registry", dedupe: true, gc: true, gcDelay: "1h", gcInterval: "24h" },
					http: {
						address: "0.0.0.0",
						port: $port,
						tls: { cert: $cert, key: $key },
						auth: { htpasswd: { path: "/etc/zot/htpasswd" } },
						accessControl: {
							repositories: {
								"**": {
									policies: [ { users: [$builder], actions: ["read"] } ],
									defaultPolicy: []
								}
							},
							adminPolicy: { users: [$admin], actions: ["read","create","update","delete"] }
						}
					},
					log: { level: "info" },
					extensions: {
						search: { enable: true },
						sync: {
							enable: true,
							credentialsFile: "/etc/zot/sync-credentials.json",
							registries: [
								{ urls: ["https://ghcr.io"], onDemand: false, tlsVerify: true, preserveDigest: true, pollInterval: $poll, content: [ content_entry ] },
								{ urls: ["https://ghcr.io"], onDemand: true,  tlsVerify: true, preserveDigest: true }
							]
						}
					}
				}' > "$cfg_file" || {
					echo "❌ Failed to write $cfg_file"
					return 1
				}
			chmod 0644 "$cfg_file"

			# --- persist tunables for configure / status to read ---
			cat > "$env_file" <<-EOT
				# Operator-tunable values for module_zotcache. Safe to edit by hand;
				# re-run 'module_zotcache configure' to apply changes.
				ZOT_PORT="$ZOT_PORT"
				ZOT_STORAGE="$ZOT_STORAGE"
				ZOT_POLL="$ZOT_POLL"
				ZOT_PREFIX="$ZOT_PREFIX"
				ZOT_TAG_REGEX="$ZOT_TAG_REGEX"
				ZOT_TLS_CERT="$ZOT_TLS_CERT"
				ZOT_TLS_KEY="$ZOT_TLS_KEY"
				ZOT_BUILDER_USER="$ZOT_BUILDER_USER"
				ZOT_ADMIN_USER="$ZOT_ADMIN_USER"
			EOT
			chmod 0644 "$env_file"

			# --- start the container (idempotent: rm any prior first) ---
			docker rm -f "$dockername" >/dev/null 2>&1 || true
			if ! docker_operation_progress run "$dockername" \
				-d \
				--name="$dockername" \
				--init \
				--net=lsio \
				--restart=unless-stopped \
				--user="${zot_uid}:${zot_gid}" \
				--publish "${ZOT_PORT}:${ZOT_PORT}" \
				--volume "${ZOT_STORAGE}:/var/lib/registry" \
				--volume "${cfg_file}:/etc/zot/config.json:ro" \
				--volume "${ht_file}:/etc/zot/htpasswd:ro" \
				--volume "${creds_file}:/etc/zot/sync-credentials.json:ro" \
				--volume "${cert_dir}:/etc/zot/certs:ro" \
				--health-cmd "/usr/local/bin/zot verify /etc/zot/config.json" \
				--health-interval=30s \
				--health-timeout=5s \
				--health-retries=3 \
				"$dockerimage" \
				serve /etc/zot/config.json
			then
				echo "❌ Failed to start zot-cache container."
				echo "   Inspect with: docker logs $dockername"
				return 1
			fi

			echo "✅ zot-cache running on https://${LOCALIPADD:-localhost}:${ZOT_PORT}/"
			echo
			echo "Operator notes:"
			echo "  • Egress firewall: allow BOTH ghcr.io AND pkg-containers.githubusercontent.com"
			echo "    (GHCR redirects blob downloads to a Fastly CDN; manifest-only allow fails layers)."
			echo "  • Build nodes need only inbound LAN access to this host on port ${ZOT_PORT}."
			echo "  • If ${ZOT_STORAGE} is on ZFS, recommended dataset properties:"
			echo "      recordsize=1M  compression=lz4  atime=off  dedup=off"
			echo "    (zot dedups blobs itself; ZFS dedup here only wastes RAM.)"
		;;

		"${commands[1]}") # configure
			if ! docker container ls -a --format '{{.Names}}' | grep -q "^${dockername}$"; then
				echo "zot-cache is not installed. Run: module_zotcache install"
				return 1
			fi

			# Snapshot runtime-affecting values BEFORE prompts. Changes to
			# either need a container recreate (new --publish / --volume),
			# not just a restart — restart re-reads config.json but cannot
			# alter the port mapping or bind mount baked in at run time.
			local old_port="$ZOT_PORT"
			local old_storage="$ZOT_STORAGE"

			if [[ -t 1 ]]; then
				ZOT_STORAGE=$(dialog_inputbox "Storage path"   "Host directory for the registry blob store." "$ZOT_STORAGE")
				ZOT_PORT=$(dialog_inputbox    "HTTPS port"     "Port the registry listens on (TLS)." "$ZOT_PORT")
				ZOT_POLL=$(dialog_inputbox    "Pre-warm poll"  "How often the pre-warm sync polls upstream." "$ZOT_POLL")
				ZOT_PREFIX=$(dialog_inputbox  "Pre-warm prefix" "Prefix glob to mirror eagerly." "$ZOT_PREFIX")
				ZOT_TAG_REGEX=$(dialog_inputbox "Tag regex (optional)" "Optional regex to restrict eagerly-mirrored tags. Blank = mirror every tag." "$ZOT_TAG_REGEX")
				clear

				if dialog_yesno "Rotate GHCR PAT?" \
					"Replace the stored GitHub PAT in $creds_file?" 10 60; then
					local gh_user gh_pat
					gh_user=$(dialog_inputbox   "GitHub username" "GitHub username that owns the PAT." "")
					gh_pat=$(dialog_passwordbox "GitHub PAT"      "PAT with 'read:packages'. Written to $creds_file (chmod 600)." 12 70)
					clear
					if [[ -n "$gh_user" && -n "$gh_pat" ]]; then
						local tmp_creds
						tmp_creds=$(mktemp /etc/zot/.sync-credentials.json.XXXXXX) || return 1
						chmod 0600 "$tmp_creds"
						if ! jq -n --arg user "$gh_user" --arg pass "$gh_pat" \
							'{"ghcr.io": {"username": $user, "password": $pass}}' > "$tmp_creds"
						then
							rm -f "$tmp_creds"
							echo "❌ Failed to rewrite $creds_file (jq)"
							gh_user=""; gh_pat=""
							return 1
						fi
						if ! mv "$tmp_creds" "$creds_file"; then
							rm -f "$tmp_creds"
							echo "❌ Failed to install $creds_file (mv)"
							gh_user=""; gh_pat=""
							return 1
						fi
						chmod 0600 "$creds_file" || {
							echo "❌ Failed to chmod 0600 $creds_file"
							gh_user=""; gh_pat=""
							return 1
						}
					fi
					gh_user=""
					gh_pat=""
				fi

				if dialog_yesno "Rotate registry credentials?" \
					"Regenerate $ht_file? (You'll need to redistribute the new builder password.)" 11 60; then
					local builder_pw admin_pw
					builder_pw=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32)
					admin_pw=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32)
					{
						htpasswd -bBn "$ZOT_BUILDER_USER" "$builder_pw"
						htpasswd -bBn "$ZOT_ADMIN_USER"   "$admin_pw"
					} > "$ht_file" || { echo "❌ Failed to rewrite $ht_file"; return 1; }
					chmod 0640 "$ht_file"
					dialog_msgbox "zot-cache credentials rotated" \
						"builder: $ZOT_BUILDER_USER / $builder_pw\nadmin:   $ZOT_ADMIN_USER / $admin_pw\n\nShown once. Redistribute now." 14 70
					builder_pw=""
					admin_pw=""
				fi
			fi

			# Rewrite config.json with the new values.
			local tag_clause="null"
			if [[ -n "$ZOT_TAG_REGEX" ]]; then
				tag_clause=$(jq -n --arg re "$ZOT_TAG_REGEX" '{tags: {regex: $re}}')
			fi
			jq -n \
				--arg port "$ZOT_PORT" \
				--arg cert "$ZOT_TLS_CERT" \
				--arg key  "$ZOT_TLS_KEY" \
				--arg poll "$ZOT_POLL" \
				--arg prefix "$ZOT_PREFIX" \
				--arg builder "$ZOT_BUILDER_USER" \
				--arg admin   "$ZOT_ADMIN_USER" \
				--argjson tag_clause "$tag_clause" \
				'
				def content_entry:
					if $tag_clause == null then {prefix: $prefix}
					else {prefix: $prefix} + $tag_clause end;
				{
					distSpecVersion: "1.1.0-dev",
					storage: { rootDirectory: "/var/lib/registry", dedupe: true, gc: true, gcDelay: "1h", gcInterval: "24h" },
					http: {
						address: "0.0.0.0", port: $port,
						tls: { cert: $cert, key: $key },
						auth: { htpasswd: { path: "/etc/zot/htpasswd" } },
						accessControl: {
							repositories: { "**": { policies: [ { users: [$builder], actions: ["read"] } ], defaultPolicy: [] } },
							adminPolicy: { users: [$admin], actions: ["read","create","update","delete"] }
						}
					},
					log: { level: "info" },
					extensions: {
						search: { enable: true },
						sync: {
							enable: true,
							credentialsFile: "/etc/zot/sync-credentials.json",
							registries: [
								{ urls: ["https://ghcr.io"], onDemand: false, tlsVerify: true, preserveDigest: true, pollInterval: $poll, content: [ content_entry ] },
								{ urls: ["https://ghcr.io"], onDemand: true,  tlsVerify: true, preserveDigest: true }
							]
						}
					}
				}' > "$cfg_file" || { echo "❌ Failed to rewrite $cfg_file"; return 1; }

			# Persist tunables.
			cat > "$env_file" <<-EOT
				ZOT_PORT="$ZOT_PORT"
				ZOT_STORAGE="$ZOT_STORAGE"
				ZOT_POLL="$ZOT_POLL"
				ZOT_PREFIX="$ZOT_PREFIX"
				ZOT_TAG_REGEX="$ZOT_TAG_REGEX"
				ZOT_TLS_CERT="$ZOT_TLS_CERT"
				ZOT_TLS_KEY="$ZOT_TLS_KEY"
				ZOT_BUILDER_USER="$ZOT_BUILDER_USER"
				ZOT_ADMIN_USER="$ZOT_ADMIN_USER"
			EOT

			# Port or storage change → full recreate (new -p / -v flags can't
			# be applied to an existing container). Everything else (poll,
			# prefix, tag regex, htpasswd, PAT) is in config.json or in
			# bind-mounted files, so a restart is enough.
			if [[ "$ZOT_PORT" != "$old_port" || "$ZOT_STORAGE" != "$old_storage" ]]; then
				if [[ "$ZOT_STORAGE" != "$old_storage" ]]; then
					echo "⚠️  Storage path changed: $old_storage → $ZOT_STORAGE"
					echo "    Existing blobs at $old_storage are NOT migrated automatically."
					install -d -m 0755 "$ZOT_STORAGE" || {
						echo "❌ Failed to create $ZOT_STORAGE"
						return 1
					}
				fi

				# Re-detect uid:gid (image may have been updated since install).
				local id_out zot_uid zot_gid
				id_out=$(docker run --rm --entrypoint id "$dockerimage" 2>/dev/null || true)
				zot_uid=$(echo "$id_out" | grep -oE 'uid=[0-9]+' | head -1 | cut -d= -f2)
				zot_gid=$(echo "$id_out" | grep -oE 'gid=[0-9]+' | head -1 | cut -d= -f2)
				zot_uid="${zot_uid:-1000}"
				zot_gid="${zot_gid:-1000}"
				chown -R "${zot_uid}:${zot_gid}" "$ZOT_STORAGE" || {
					echo "❌ Failed to chown $ZOT_STORAGE to ${zot_uid}:${zot_gid}"
					return 1
				}

				echo "Recreating zot-cache container (port / storage changed) ..."
				docker rm -f "$dockername" >/dev/null 2>&1 || true
				if ! docker_operation_progress run "$dockername" \
					-d \
					--name="$dockername" \
					--init \
					--net=lsio \
					--restart=unless-stopped \
					--user="${zot_uid}:${zot_gid}" \
					--publish "${ZOT_PORT}:${ZOT_PORT}" \
					--volume "${ZOT_STORAGE}:/var/lib/registry" \
					--volume "${cfg_file}:/etc/zot/config.json:ro" \
					--volume "${ht_file}:/etc/zot/htpasswd:ro" \
					--volume "${creds_file}:/etc/zot/sync-credentials.json:ro" \
					--volume "${cert_dir}:/etc/zot/certs:ro" \
					--health-cmd "/usr/local/bin/zot verify /etc/zot/config.json" \
					--health-interval=30s \
					--health-timeout=5s \
					--health-retries=3 \
					"$dockerimage" \
					serve /etc/zot/config.json
				then
					echo "❌ Failed to recreate zot-cache container."
					return 1
				fi
				echo "✅ zot-cache recreated on https://${LOCALIPADD:-localhost}:${ZOT_PORT}/"
			else
				echo "Restarting zot-cache to apply changes ..."
				docker restart "$dockername" >/dev/null || {
					echo "❌ docker restart $dockername failed"
					return 1
				}
				echo "✅ zot-cache reconciled."
			fi
		;;

		"${commands[2]}") # status
			if ! docker container ls -a --format '{{.Names}}' | grep -q "^${dockername}$"; then
				echo "zot-cache: not installed"
				return 1
			fi
			local state health
			state=$(docker inspect -f '{{.State.Status}}'         "$dockername" 2>/dev/null)
			health=$(docker inspect -f '{{.State.Health.Status}}' "$dockername" 2>/dev/null)
			echo "zot-cache: container=${state:-unknown} health=${health:-n/a}"

			if docker exec "$dockername" /usr/local/bin/zot verify /etc/zot/config.json >/dev/null 2>&1; then
				echo "zot verify: OK"
			else
				echo "zot verify: FAILED"
			fi

			# /v2/_catalog probe only if the operator exported a password —
			# we deliberately don't persist plaintext credentials anywhere.
			local probe_user="$ZOT_BUILDER_USER" probe_pass="${ZOT_BUILDER_PASSWORD:-}"
			if [[ -z "$probe_pass" && -n "${ZOT_ADMIN_PASSWORD:-}" ]]; then
				probe_user="$ZOT_ADMIN_USER"
				probe_pass="$ZOT_ADMIN_PASSWORD"
			fi
			if [[ -n "$probe_pass" ]]; then
				local catalog
				catalog=$(curl -sk -u "${probe_user}:${probe_pass}" \
					"https://localhost:${ZOT_PORT}/v2/_catalog" 2>/dev/null)
				if [[ -n "$catalog" ]]; then
					local n_total n_armbian
					n_total=$(jq -r '.repositories | length' <<<"$catalog" 2>/dev/null)
					n_armbian=$(jq -r '.repositories[]? | select(startswith("armbian/"))' <<<"$catalog" 2>/dev/null | wc -l)
					echo "/v2/_catalog: ${n_total} repos (armbian/**: ${n_armbian})"
				else
					echo "/v2/_catalog: probe failed (check port / credentials)"
				fi
			else
				echo "/v2/_catalog: skipped (export ZOT_BUILDER_PASSWORD or ZOT_ADMIN_PASSWORD to probe)"
			fi

			# Presence check (not health check). The menu's "remove"/"purge"
			# items gate on `condition: "module_zotcache status"`, so a 0
			# return must mean "this thing exists and the operator may need
			# to act on it" — even when stopped, restarting, dead, or
			# unhealthy. The non-existence case already returned 1 above.
			[[ -n "$state" ]]
		;;

		"${commands[3]}") # logs
			if ! docker container ls -a --format '{{.Names}}' | grep -q "^${dockername}$"; then
				echo "zot-cache is not installed."
				return 1
			fi
			docker logs -f "$dockername"
		;;

		"${commands[4]}") # remove
			docker_operation_progress rm  "$dockername"
			docker_operation_progress rmi "$dockerimage"
			echo "zot-cache container removed."
			echo "Config in /etc/zot and blob store at $ZOT_STORAGE preserved."
			echo "Run 'module_zotcache purge' to delete them too."
		;;

		"${commands[5]}") # purge
			if ! ${module_options["module_zotcache,feature"]} ${commands[4]}; then
				return 1
			fi

			local delete_data=no
			if [[ -t 1 ]]; then
				dialog_yesno "Delete blob store?" \
					"Also delete the cached blob store at:\n    ${ZOT_STORAGE}\n\nThis is reproducible but re-warm re-downloads every layer from GHCR." 12 70 \
					&& delete_data=yes
			else
				delete_data="${ZOT_PURGE_DATA:-no}"
			fi

			# Secrets always go (PAT / htpasswd / certs are cheap to regenerate
			# and dangerous to leave behind).
			rm -f "$cfg_file" "$ht_file" "$creds_file" "$env_file"
			rm -rf "$cert_dir"

			if [[ "$delete_data" == "yes" ]]; then
				rm -rf "$ZOT_STORAGE"
				rmdir --ignore-fail-on-non-empty /etc/zot 2>/dev/null || true
				echo "zot-cache fully purged (including blob store at $ZOT_STORAGE)."
			else
				rmdir --ignore-fail-on-non-empty /etc/zot 2>/dev/null || true
				echo "zot-cache purged. Blob store kept at $ZOT_STORAGE."
			fi
		;;

		"${commands[6]}") # help
			show_module_help "module_zotcache" "$title" \
				"OCI registry pull-through cache + scheduled mirror for ghcr.io/armbian/**.\n\nImage: ${dockerimage}\nDefault port: ${default_port}\nConfig:      ${cfg_file}\nSecrets:     ${creds_file} (chmod 600)\nBlob store:  ${ZOT_STORAGE}\n\nSubcommands:\n  install   — full bring-up (prompts for storage / port / PAT)\n  configure — re-prompt and reconcile (regenerates config, restarts)\n  status    — container + healthcheck + /v2/_catalog probe\n  logs      — docker logs -f\n  remove    — stop & remove container + image (keeps blob store)\n  purge     — remove + delete config/secrets (optionally blob store)"
		;;

		*)
			${module_options["module_zotcache,feature"]} ${commands[6]}
		;;
	esac
}
