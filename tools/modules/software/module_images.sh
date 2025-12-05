#
# Module options: images
#
module_options+=(
	["module_images,author"]=""
	["module_images,maintainer"]="@igorpecovnik"
	["module_images,feature"]="module_images"
	["module_images,example"]="install remove purge status help"
	["module_images,desc"]="Download and flash Armbian OS images for selected hardware"
	["module_images,status"]="Active"
	["module_images,doc_link"]=""
	["module_images,group"]="Management"
	["module_images,arch"]="x86-64 arm64 armhf"
)

#
# Module images
#
function module_images () {
	local title="images"
	local condition="ok"  # dummy, kept for consistency with other modules

	local commands
	IFS=' ' read -r -a commands <<< "${module_options["module_images,example"]}"

	local ALL_IMAGES_JSON_URL="https://github.armbian.com/all-images.json"
	local IMAGES_BASE="${SOFTWARE_FOLDER}/images"
	local IMAGES_JSON_PATH="${IMAGES_BASE}/all-images.json"

	# $1 = command, $2 = board_slug override (optional)
	local CMD="$1"
	local BOARD_SLUG="${2:-${BOARD:-}}"

	# filters (set during install flow)
	PREAPP_FILTER=""
	DOWNLOAD_REPO_FILTER=""   # e.g. "archive" when STABLE is selected
	KERNEL_FILTER=""
	VARIANT_FILTER=""

	# Ensure base directory exists
	[[ -d "$IMAGES_BASE" ]] || mkdir -p "$IMAGES_BASE" || { echo "Couldn't create storage directory: $IMAGES_BASE"; return 1; }

	# Helper: ensure dependencies
	local -a DEPS=("curl" "jq")
	for dep in "${DEPS[@]}"; do
		if ! command -v "$dep" >/dev/null 2>&1; then
			pkg_install "$dep"
		fi
	done

	# Helper: ensure BOARD_SLUG is set, otherwise ask
	ensure_board_slug() {
		if [[ -z "$BOARD_SLUG" ]]; then
			if [[ -n "$DIALOG" ]]; then
				BOARD_SLUG=$($DIALOG --title "Board slug" --inputbox "Enter board slug (e.g. bananapi):" 8 50 3>&1 1>&2 2>&3)
				[[ -z "$BOARD_SLUG" ]] && { echo "Board slug not provided."; return 1; }
			else
				read -rp "Enter board slug (e.g. bananapi): " BOARD_SLUG
				[[ -z "$BOARD_SLUG" ]] && { echo "Board slug not provided."; return 1; }
			fi
		fi
		return 0
	}

	# Helper: fetch/refresh JSON (simple cache, max age 1 day)
	refresh_images_json() {
		local max_age=$((24*60*60))  # 1 day
		local now epoch

		now=$(date +%s)

		if [[ -f "$IMAGES_JSON_PATH" ]]; then
			epoch=$(stat -c %Y "$IMAGES_JSON_PATH" 2>/dev/null || echo 0)
		else
			epoch=0
		fi

		if (( now - epoch > max_age )) || [[ ! -s "$IMAGES_JSON_PATH" ]]; then
			if [[ -n "$DIALOG" ]]; then
				$DIALOG --infobox "Refreshing Armbian images index...\n\n$ALL_IMAGES_JSON_URL" 8 70
			else
				echo "Refreshing Armbian images index from $ALL_IMAGES_JSON_URL ..."
			fi

			if ! curl -fsSL "$ALL_IMAGES_JSON_URL" -o "$IMAGES_JSON_PATH"; then
				echo "Failed to download $ALL_IMAGES_JSON_URL"
				return 1
			fi
		fi
		return 0
	}

	# Helper: let user pick a board_slug from the index (unique list)
	# Only consider records with real flashable images (file_extension NOT .asc/.torrent/.sha*)
	choose_board_slug_from_index() {
		local -a options=()
		local temp_list slug

		temp_list=$(jq -r '
			[
			.. | objects
			| select(.board_slug? != null)
			| select((.file_extension? // "") | test("\\.(asc|torrent|sha)"; "i") | not)
			| .board_slug
			]
			| unique
			| sort
			| to_entries[]
			| "\(.key)|\(.value)"
		' "$IMAGES_JSON_PATH" 2>/dev/null)

		if [[ -z "$temp_list" ]]; then
			echo "No boards found in images index."
			return 1
		fi

		while IFS='|' read -r idx slug; do
			[[ -z "$idx" ]] && continue
			options+=("$idx" "$slug")
		done <<< "$temp_list"

		local selected_idx

		if [[ -n "$DIALOG" ]]; then
			selected_idx=$($DIALOG --title "Select board" \
				--menu "\nNo images found for the current board.\n\nSelect a different board to flash:" 24 76 12 \
				"${options[@]}" \
				3>&1 1>&2 2>&3)
		else
			echo "Boards available in index:"
			local i=0
			while [[ $i -lt ${#options[@]} ]]; do
				echo "  ${options[$i]}: ${options[$((i+1))]}"
				((i+=2))
			done
			read -rp "Enter board index: " selected_idx
		fi

		[[ -z "$selected_idx" ]] && return 1

		BOARD_SLUG=$(jq -r --argjson i "$selected_idx" '
			[
			.. | objects
			| select(.board_slug? != null)
			| select((.file_extension? // "") | test("\\.(asc|torrent|sha)"; "i") | not)
			| .board_slug
			]
			| unique
			| sort
			| .[$i]
		' "$IMAGES_JSON_PATH")

		[[ -z "$BOARD_SLUG" || "$BOARD_SLUG" == "null" ]] && return 1

		return 0
	}

	# Helper: confirm current BOARD_SLUG or choose another from index
	confirm_board_or_choose_other() {
		# If we don't have a board yet, nothing to confirm
		if [[ -z "$BOARD_SLUG" ]]; then
			return 0
		fi

		if [[ -n "$DIALOG" ]]; then
			local choice
			choice=$($DIALOG --title "Confirm board" \
				--menu "\nDetected board: ${BOARD_SLUG}\n\nWhat would you like to do?" 15 76 3 \
				"CURRENT" "Use this board" \
				"OTHER"   "Choose another board from images index" \
				3>&1 1>&2 2>&3)

			[[ -z "$choice" ]] && return 1

			case "$choice" in
				CURRENT)
					# keep BOARD_SLUG as-is
					return 0
					;;
				OTHER)
					# use JSON index and let user pick any board
					choose_board_slug_from_index || return 1
					return 0
					;;
			esac
		else
			echo "Current board slug: $BOARD_SLUG"
			echo "  1) Use this board"
			echo "  2) Choose another board from images index"
			echo "  3) Cancel"
			local ans
			read -rp "Select [1-3]: " ans
			case "$ans" in
				1|"")
					return 0
					;;
				2)
					choose_board_slug_from_index || return 1
					return 0
					;;
				*)
					return 1
					;;
			esac
		fi
	}

	# Helper: select preinstalled_application filter for board
	# PREAPP_FILTER:
	#   ""           -> all
	#   "__EMPTY__"  -> barebone (preinstalled_application == "")
	#   other        -> that exact preinstalled_application
	select_preapp_for_board() {
		local board="$1"
		local -a options=()
		local temp_list app
		local has_barebone=0
		local apps_list=""

		temp_list=$(jq -r --arg board "$board" '
			def norm(s): (s | ascii_downcase | gsub("[^a-z0-9]+"; "-"));
			[
			.. | objects
			| select(.board_slug? != null)
			| select((.file_extension? // "") | test("^img(\\.(xz|gz|zst|bz2|lz4))?$"; "i"))
			| select(.kernel_branch != "cloud")
			| select(norm(.board_slug) == norm($board))
			| .preinstalled_application // ""
			]
			| unique
			| sort
			| to_entries[]
			| "\(.key)|\(.value)"
		' "$IMAGES_JSON_PATH" 2>/dev/null)

		if [[ -z "$temp_list" ]]; then
			PREAPP_FILTER=""
			DOWNLOAD_REPO_FILTER=""
			return 0
		fi

		# Split into barebone flag + list of named apps
		while IFS='|' read -r _ app; do
			if [[ -z "$app" ]]; then
				has_barebone=1
			else
				apps_list+="${app}"$'\n'
			fi
		done <<< "$temp_list"

		# Build clean options list
		options=()
		options+=("ALL"    "All images (barebone + preinstalled)")
		options+=("STABLE" "Stable images only")

		if [[ $has_barebone -eq 1 ]]; then
			options+=("BAREBONE" "Barebone images only (no preinstalled apps)")
		fi

		while IFS= read -r app; do
			[[ -z "$app" ]] && continue
			local desc
			case "$app" in
				homeassistant)
					desc="Home Assistant smart home suite"
				;;
				kali)
					desc="Preinstalled security applications from Kali repository"
				;;
				omv|OMV)
					desc="Openmediavault NAS appliance"
				;;
				openhab|OpenHAB|openHAB)
					desc="Empowering the smart home"
				;;
				*)
					desc="$app"
				;;
			esac
			options+=("$app" "$desc")
		done <<< "$apps_list"

		local selected

		if [[ -n "$DIALOG" ]]; then
			selected=$($DIALOG --title "Prebuild images" \
				--menu "\nSelect image type: stable, barebone, or with preinstalled apps." 22 76 12 \
				"${options[@]}" \
				--default-item STABLE \
				3>&1 1>&2 2>&3)
		else
			echo "Available application filters for $board:"
			local i=0
			while [[ $i -lt ${#options[@]} ]]; do
				echo "  ${options[$i]}: ${options[$((i+1))]}"
				((i+=2))
			done
			read -rp "Enter filter (ALL/STABLE/BAREBONE or app name, empty=ALL): " selected
		fi
		local dlg_exit=$?
		if [[ $dlg_exit -ne 0 ]]; then
			return 1
		fi

		if [[ -z "$selected" || "$selected" == "ALL" ]]; then
			PREAPP_FILTER=""
			DOWNLOAD_REPO_FILTER=""
		elif [[ "$selected" == "STABLE" ]]; then
			# Only stable images: download_repository == "archive"
			PREAPP_FILTER=""
			DOWNLOAD_REPO_FILTER="archive"
		elif [[ "$selected" == "BAREBONE" ]]; then
			PREAPP_FILTER="__EMPTY__"
			DOWNLOAD_REPO_FILTER=""
		else
			PREAPP_FILTER="$selected"
			DOWNLOAD_REPO_FILTER=""
		fi

		return 0
	}

	# Helper: select kernel_branch filter for board
	select_kernel_branch_for_board() {
		local board="$1"
		local -a options=()
		local temp_list kbranch

		temp_list=$(jq -r --arg board "$board" --arg preapp "$PREAPP_FILTER" --arg repo "$DOWNLOAD_REPO_FILTER" '
			def norm(s): (s | ascii_downcase | gsub("[^a-z0-9]+"; "-"));
			def preapp_filter:
			if   $preapp == ""          then .
			elif $preapp == "__EMPTY__" then select((.preinstalled_application // "") == "")
			else select(.preinstalled_application == $preapp)
			end;
			def repo_filter:
			if $repo == "" then .
			else select(.download_repository == $repo)
			end;
			[
			.. | objects
			| select(.board_slug? != null)
			| select((.file_extension? // "") | test("^img(\\.(xz|gz|zst|bz2|lz4))?$"; "i"))
			| select(.kernel_branch != "cloud")
			| select(norm(.board_slug) == norm($board))
			| preapp_filter
			| repo_filter
			| .kernel_branch // "unknown"
			]
			| unique
			| sort
			| to_entries[]
			| "\(.key)|\(.value)"
		' "$IMAGES_JSON_PATH" 2>/dev/null)

		if [[ -z "$temp_list" ]]; then
			# No kernel information – just keep filter empty (all)
			KERNEL_FILTER=""
			return 0
		fi

		# "All" option
		options+=("ALL" "All kernel branches")
		while IFS='|' read -r _ kbranch; do
			[[ -z "$kbranch" ]] && continue
			options+=("$kbranch" "$kbranch")
		done <<< "$temp_list"

		local selected

		if [[ -n "$DIALOG" ]]; then
			selected=$($DIALOG --title "Kernel branch" \
				--menu "\nSelect kernel branch to filter images (or choose All):" 14 70 4 \
				"${options[@]}" \
				3>&1 1>&2 2>&3)
		else
			echo "Available kernel branches for $board (preinstalled=${PREAPP_FILTER:-ALL}, repo=${DOWNLOAD_REPO_FILTER:-all}):"
			echo "  ALL  - All kernel branches"
			while IFS='|' read -r _ kbranch; do
				[[ -z "$kbranch" ]] && continue
				echo "  $kbranch"
			done <<< "$temp_list"
			read -rp "Enter kernel branch to filter (empty/ALL for all): " selected
		fi

		local dlg_exit=$?
		if [[ $dlg_exit -ne 0 ]]; then
			return 1
		fi

		if [[ -z "$selected" || "$selected" == "ALL" ]]; then
			KERNEL_FILTER=""
		else
			KERNEL_FILTER="$selected"
		fi

		return 0
	}

	# Helper: select image_variant filter for board + kernel + preapp
	select_image_variant_for_board() {
		local board="$1"
		local -a options=()
		local temp_list variant

		temp_list=$(jq -r --arg board "$board" --arg kbranch "$KERNEL_FILTER" --arg preapp "$PREAPP_FILTER" --arg repo "$DOWNLOAD_REPO_FILTER" '
			def norm(s): (s | ascii_downcase | gsub("[^a-z0-9]+"; "-"));
			def preapp_filter:
			if   $preapp == ""          then .
			elif $preapp == "__EMPTY__" then select((.preinstalled_application // "") == "")
			else select(.preinstalled_application == $preapp)
			end;
			def repo_filter:
			if $repo == "" then .
			else select(.download_repository == $repo)
			end;
			[
			.. | objects
			| select(.board_slug? != null)
			| select((.file_extension? // "") | test("^img(\\.(xz|gz|zst|bz2|lz4))?$"; "i"))
			| select(.kernel_branch != "cloud")
			| select(norm(.board_slug) == norm($board))
			| preapp_filter
			| repo_filter
			| (if $kbranch != "" then select(.kernel_branch == $kbranch) else . end)
			| .image_variant // "unknown"
			]
			| unique
			| sort
			| to_entries[]
			| "\(.key)|\(.value)"
		' "$IMAGES_JSON_PATH" 2>/dev/null)

		if [[ -z "$temp_list" ]]; then
			VARIANT_FILTER=""
			return 0
		fi

		options+=("ALL" "All image variants")
		while IFS='|' read -r _ variant; do
			[[ -z "$variant" ]] && continue
			options+=("$variant" "$variant")
		done <<< "$temp_list"

		local selected

		if [[ -n "$DIALOG" ]]; then
			selected=$($DIALOG --title "Image variant" \
				--menu "\nSelect image variant to filter (or choose All):" 15 70 5 \
				"${options[@]}" \
				3>&1 1>&2 2>&3)
		else
			echo "Available variants for $board (preinstalled=${PREAPP_FILTER:-ALL}, kernel=${KERNEL_FILTER:-all}, repo=${DOWNLOAD_REPO_FILTER:-all}):"
			echo "  ALL  - All variants"
			while IFS='|' read -r _ variant; do
				[[ -z "$variant" ]] && continue
				echo "  $variant"
			done <<< "$temp_list"
			read -rp "Enter image variant to filter (empty/ALL for all): " selected
		fi

		local dlg_exit=$?
		if [[ $dlg_exit -ne 0 ]]; then
			return 1
		fi

		if [[ -z "$selected" || "$selected" == "ALL" ]]; then
			VARIANT_FILTER=""
		else
			VARIANT_FILTER="$selected"
		fi

		return 0
	}

	# Helper: select image via menu (uses BOARD_SLUG + filters)
	select_image_for_board() {
		local board
		board="$1"

		while true; do
			local temp_list
			local -a options=()
			local idx desc

			temp_list=$(jq -r --arg board "$board" --arg kbranch "$KERNEL_FILTER" --arg variant "$VARIANT_FILTER" --arg preapp "$PREAPP_FILTER" --arg repo "$DOWNLOAD_REPO_FILTER" '
				def norm(s): (s | ascii_downcase | gsub("[^a-z0-9]+"; "-"));
				def preapp_filter:
					if   $preapp == ""          then .
					elif $preapp == "__EMPTY__" then select((.preinstalled_application // "") == "")
					else select(.preinstalled_application == $preapp)
					end;
				def repo_filter:
					if $repo == "" then .
					else select(.download_repository == $repo)
					end;

				def spaces(n): reduce range(0;n) as $i (""; . + " ");
				def pad(s; n):
					(s // "") as $s |
					($s | length) as $l |
					if $l >= n then $s else $s + spaces(n - $l) end;
				def pad_right(s; n):
					(s // "") as $s |
					($s | length) as $l |
					if $l >= n then $s else spaces(n - $l) + $s end;
				def size_mb(x):
					(
						(x.file_size // "0" | try tonumber // 0)
						/ (1024*1024)
						| if . < 1 then 1 else floor end
						| tostring + " MB"
					);
				def show_ver(v):
					(v // "") as $v |
					if ($v | test("-trunk\\.[0-9]+$")) then
						# Example: 26.2.0-trunk.33 -> T-33
						"DEV." + ($v | capture("trunk\\.(?<n>[0-9]+)$").n)
					else
						$v
					end;

				[
				.. | objects
				| select(.board_slug? != null)
				| select((.file_extension? // "") | test("^img(\\.(xz|gz|zst|bz2|lz4))?$"; "i"))
				| select(.kernel_branch != "cloud")
				| select(norm(.board_slug) == norm($board))
				| preapp_filter
				| repo_filter
				| (if $kbranch != "" then select(.kernel_branch == $kbranch) else . end)
				| (if $variant != "" then select(.image_variant == $variant) else . end)
				]
				| sort_by([ (if .promoted=="true" then 0 else 1 end), .armbian_version ])
				| to_entries[]
				| (
					(.key|tostring) + "|" +
					(if .value.promoted=="true" then "\u2605 " else "  " end) +
					pad(show_ver(.value.armbian_version); 10) + " " +
					pad(.value.distro_release // ""; 9) + " " +
					pad(.value.kernel_branch // ""; 10) + " " +
					pad(.value.image_variant // ""; 12) + " " +
					pad_right(size_mb(.value); 7) + " " +
					pad_right((.value.preinstalled_application // ""); 15)
				)
			' "$IMAGES_JSON_PATH" 2>/dev/null)


			if [[ -z "$temp_list" ]]; then
				# No images even after filters – offer to adjust filters
				if [[ -n "$DIALOG" ]]; then
					if $DIALOG --yesno "No images found for:\n\n  board:   $board\n  preapp:  ${PREAPP_FILTER:-ALL}\n  repo:    ${DOWNLOAD_REPO_FILTER:-all}\n  kernel:  ${KERNEL_FILTER:-all}\n  variant: ${VARIANT_FILTER:-all}\n\nWould you like to adjust filters?" 17 72; then
						select_preapp_for_board         "$board" || return 1
						select_kernel_branch_for_board  "$board" || return 1
						select_image_variant_for_board  "$board" || return 1
						continue
					else
						echo "No images found for the selected filters."
						return 1
					fi
				else
					echo "No images found for board=$board, preapp=${PREAPP_FILTER:-ALL}, repo=${DOWNLOAD_REPO_FILTER:-all}, kernel=${KERNEL_FILTER:-all}, variant=${VARIANT_FILTER:-all}."
					read -rp "Adjust filters? [y/N]: " ans
					if [[ "$ans" =~ ^[Yy]$ ]]; then
						select_preapp_for_board         "$board" || return 1
						select_kernel_branch_for_board  "$board" || return 1
						select_image_variant_for_board  "$board" || return 1
						continue
					fi
					return 1
				fi
				local dlg_exit=$?
				if [[ $dlg_exit -ne 0 ]]; then
					return 1
				fi
			fi

			while IFS='|' read -r idx desc; do
				[[ -z "$idx" ]] && continue
				options+=("$idx" "$desc")
			done <<< "$temp_list"

			local selected_index

			if [[ -n "$DIALOG" ]]; then
				selected_index=$($DIALOG --title "Select Armbian image" \
					--menu "\nBoard: $board\nPreinstalled: ${PREAPP_FILTER:-ALL}\nRepo: ${DOWNLOAD_REPO_FILTER:-all}\nKernel: ${KERNEL_FILTER:-all}\nVariant: ${VARIANT_FILTER:-all}\n★ = promoted image\n\n  #   version    release   kernel     variant    size (MB)  [preinstalled]" 26 80 8 \
					"${options[@]}" \
					3>&1 1>&2 2>&3)
			else
				echo "Available images for $board (preapp=${PREAPP_FILTER:-ALL}, repo=${DOWNLOAD_REPO_FILTER:-all}, kernel=${KERNEL_FILTER:-all}, variant=${VARIANT_FILTER:-all}; ★ = promoted):"
				local i=0
				while [[ $i -lt ${#options[@]} ]]; do
					echo "  ${options[$i]}: ${options[$((i+1))]}"
					((i+=2))
				done
				read -rp "Enter index to flash: " selected_index
			fi

			[[ -z "$selected_index" ]] && return 1

			# Return the selected JSON object via global variable
			IMAGE_JSON=$(jq -c --arg board "$board" --arg kbranch "$KERNEL_FILTER" --arg variant "$VARIANT_FILTER" --arg preapp "$PREAPP_FILTER" --arg repo "$DOWNLOAD_REPO_FILTER" --argjson idx "$selected_index" '
				def norm(s): (s | ascii_downcase | gsub("[^a-z0-9]+"; "-"));
				def preapp_filter:
				if   $preapp == ""          then .
				elif $preapp == "__EMPTY__" then select((.preinstalled_application // "") == "")
				else select(.preinstalled_application == $preapp)
				end;
				def repo_filter:
				if $repo == "" then .
				else select(.download_repository == $repo)
				end;
				[
				.. | objects
				| select(.board_slug? != null)
				| select((.file_extension? // "") | test("^img(\\.(xz|gz|zst|bz2|lz4))?$"; "i"))
				| select(.kernel_branch != "cloud")
				| select(norm(.board_slug) == norm($board))
				| preapp_filter
				| repo_filter
				| (if $kbranch != "" then select(.kernel_branch == $kbranch) else . end)
				| (if $variant != "" then select(.image_variant == $variant) else . end)
				]
				| sort_by([ (if .promoted=="true" then 0 else 1 end), .armbian_version ])
				| .[$idx]
			' "$IMAGES_JSON_PATH")

			if [[ -z "$IMAGE_JSON" || "$IMAGE_JSON" == "null" ]]; then
				echo "Failed to obtain image metadata."
				return 1
			fi

			# Update BOARD_SLUG to the final chosen board
			BOARD_SLUG="$board"
			return 0
		done
	}

	# Helper: select target block device
	select_block_device() {
		local -a dev_options=()
		local raw_devices
		local line dev size model bytes

		# Find devices backing /, /boot, /boot/efi
		local rootdev bootdev bootefidev
		local rootdisk="" bootdisk="" bootefidisk=""

		rootdev=$(findmnt -n -o SOURCE / 2>/dev/null || echo "")
		bootdev=$(findmnt -n -o SOURCE /boot 2>/dev/null || echo "")
		bootefidev=$(findmnt -n -o SOURCE /boot/efi 2>/dev/null || echo "")

		# Resolve to parent disks (PKNAME) where possible
		if [[ -n "$rootdev" ]]; then
			local rd
			rd=$(lsblk -no PKNAME "$rootdev" 2>/dev/null || true)
			if [[ -n "$rd" ]]; then
				rootdisk="/dev/$rd"
			else
				# fallback: maybe / itself is a whole disk (e.g. /dev/mmcblk0)
				rootdisk="$rootdev"
			fi
		fi

		if [[ -n "$bootdev" ]]; then
			local bd
			bd=$(lsblk -no PKNAME "$bootdev" 2>/dev/null || true)
			if [[ -n "$bd" ]]; then
				bootdisk="/dev/$bd"
			else
				bootdisk="$bootdev"
			fi
		fi

		if [[ -n "$bootefidev" ]]; then
			local ed
			ed=$(lsblk -no PKNAME "$bootefidev" 2>/dev/null || true)
			if [[ -n "$ed" ]]; then
				bootefidisk="/dev/$ed"
			else
				bootefidisk="$bootefidev"
			fi
		fi

		# List candidate block devices
		raw_devices=$(lsblk -dpno NAME,SIZE,MODEL | grep -E '/dev/(sd|hd|vd|nvme|mmcblk)' || true)

		if [[ -z "$raw_devices" ]]; then
			echo "No suitable block devices found."
			return 1
		fi

		while IFS= read -r line; do
			dev=$(awk '{print $1}' <<< "$line")
			size=$(awk '{print $2}' <<< "$line")
			model=${line#"$dev $size "}
			[[ -z "$model" || "$model" == "$size" ]] && model=""

			# Skip eMMC boot / RPMB pseudo-devices like /dev/mmcblk1boot0, /dev/mmcblk1boot1, /dev/mmcblk1rpmb
			if [[ "$dev" =~ mmcblk[0-9]+boot[0-9]+$ || "$dev" =~ mmcblk[0-9]+rpmb$ ]]; then
				continue
			fi

			# Skip zero-size or invalid devices
			bytes=$(lsblk -bdno SIZE "$dev" 2>/dev/null || echo 0)
			if [[ -z "$bytes" ]]; then
				bytes=0
			fi
			if (( bytes <= 0 )); then
				continue
			fi

			# Skip any disk that contains the root or boot partitions
			if [[ -n "$rootdisk" && "$dev" == "$rootdisk" ]]; then
				continue
			fi
			if [[ -n "$bootdisk" && "$dev" == "$bootdisk" ]]; then
				continue
			fi
			if [[ -n "$bootefidisk" && "$dev" == "$bootefidisk" ]]; then
				continue
			fi

			dev_options+=("$dev" "$size ${model}")
		done <<< "$raw_devices"

		if [[ ${#dev_options[@]} -eq 0 ]]; then
			if [[ -n "$DIALOG" ]]; then
					"$DIALOG" --title "Error" --msgbox "No flashable block devices were found.\n\n(System disks are excluded automatically.)" 10 70
			else
					echo "No flashable block devices (excluding system disks) found."
			fi
			return 1
		fi

		local target

		if [[ -n "$DIALOG" ]]; then
			target=$($DIALOG --title "Select target device" \
				--menu "\nSelect block device to flash.\n\n⚠  ALL DATA ON THE SELECTED DEVICE WILL BE LOST!" 15 76 3 \
				"${dev_options[@]}" \
				3>&1 1>&2 2>&3)
		else
			echo "Available block devices (ALL DATA WILL BE LOST):"
			local i=0
			while [[ $i -lt ${#dev_options[@]} ]]; do
				echo "  ${dev_options[$i]}: ${dev_options[$((i+1))]}"
				((i+=2))
			done
			read -rp "Enter device to flash (e.g. /dev/sdb): " target
		fi

		[[ -z "$target" ]] && return 1

		TARGET_DEVICE="$target"
		return 0
	}

	# Helper: confirmation dialog
	confirm_destroy_device() {
		local dev="$1"
		local msg="WARNING!\n\nYou are about to write a disk image to:\n\n  ${dev}\n\nAll existing data on this device will be irreversibly destroyed.\n\nDo you want to continue?"

		if [[ -n "$DIALOG" ]]; then
			if ! $DIALOG --title "Final confirmation" --yesno "$msg" 15 72; then
				return 1
			fi
		else
			echo -e "$msg"
			read -rp "Type YES to continue: " answer
			[[ "$answer" != "YES" ]] && return 1
		fi
		return 0
	}

	# Helper: download image file
	# Download is always done using file_url (full path)
	# redi_url is only shown to the user as a clean short link
	download_image_file() {
		local file_url redi_url file_ext image_url filename dirname raw_filename

		# Always download using file_url
		file_url=$(jq -r '.file_url' <<< "$IMAGE_JSON")
		redi_url=$(jq -r '.redi_url // ""' <<< "$IMAGE_JSON")
		file_ext=$(jq -r '.file_extension // ""' <<< "$IMAGE_JSON")

		# Determine real downloadable URL (must be file_url)
		case "$file_url" in
			*.img.xz)  image_url="$file_url" ;;
			*.asc|*.torrent|*.sha*) image_url="${file_url%.*}" ;;
			*) image_url="$file_url" ;;
		esac

		filename=$(basename "$image_url")
		raw_filename="${filename%.xz}"

		LOCAL_IMAGE_PATH="${IMAGES_BASE}/${raw_filename}"

		# If already present, ask reuse
		if [[ -f "$LOCAL_IMAGE_PATH" ]]; then
			if [[ -n "$DIALOG" ]]; then
				$DIALOG --title "Note" --yesno \
					"\nUncompressed image already exists in ${IMAGES_BASE}/:\n\n${raw_filename}\n\nReuse this file?" \
					12 70 && return 0
			else
				read -rp "Image $LOCAL_IMAGE_PATH exists. Reuse? [y/N]: " reuse
				[[ "$reuse" =~ ^[Yy]$ ]] && return 0
			fi
			rm -f "$LOCAL_IMAGE_PATH"
		fi

		# File size for pv gauge
		local content_length
		content_length=$(jq -r '(.file_size // "0")' <<< "$IMAGE_JSON")
		[[ -z "$content_length" ]] && content_length=0

		# -------------------------
		# Download + decompress
		# -------------------------
		local display_url="$redi_url"
		[[ -z "$display_url" ]] && display_url="$image_url"

		local rc=0

		if command -v pv >/dev/null 2>&1 && [[ -n "$DIALOG" ]] && (( content_length > 0 )); then
			local gauge_dir
			gauge_dir=$(mktemp -d) || { echo "Failed to create temp dir"; return 1; }
			local gauge_fifo="${gauge_dir}/fifo"
			mkfifo "$gauge_fifo" || { rm -rf "$gauge_dir"; return 1; }

			$DIALOG --title "Armbian imager" \
				--gauge "\nDownloading and decompressing Armbian image...\n\n$display_url" \
				10 70 0 < "$gauge_fifo" &
			local gauge_pid=$!

			{
				curl -fSL "$image_url" 2>/dev/null \
					| pv -n -s "$content_length" 2> "$gauge_fifo" \
					| xz -T0 -dc \
					> "$LOCAL_IMAGE_PATH"
			} || rc=$?

			rm -f "$gauge_fifo"
			rmdir "$gauge_dir" 2>/dev/null || true
			wait "$gauge_pid" 2>/dev/null || true

			(( rc != 0 )) && {
				echo "Failed to download or decompress image: $image_url"
				rm -f "$LOCAL_IMAGE_PATH"
				return 1
			}

		else
			# Fallback simple mode
			if [[ -n "$DIALOG" ]]; then
				$DIALOG --infobox \
					"\nDownloading and decompressing Armbian image...\n\n$display_url" \
					8 70
			else
				echo "Downloading and decompressing: $display_url"
			fi

			curl -fSL "$image_url" \
				| xz -T0 -dc \
				> "$LOCAL_IMAGE_PATH" || {
					echo "Failed to download or decompress: $image_url"
					rm -f "$LOCAL_IMAGE_PATH"
					return 1
				}
		fi

		return 0
	}

	# Helper: flash image with dd + pv + whiptail gauge + verification
	flash_image_to_device() {
		local img="$LOCAL_IMAGE_PATH"
		local dev="$TARGET_DEVICE"

		if [[ ! -b "$dev" ]]; then
			echo "Target device $dev is not a block device."
			return 1
		fi

		if [[ ! -f "$img" ]]; then
			echo "Image file not found: $img"
			return 1
		fi

		# Get uncompressed image size for proper progress and verification
		local img_size_bytes
		img_size_bytes=$(stat -c '%s' "$img" 2>/dev/null || echo 0)

		if ! [[ "$img_size_bytes" =~ ^[0-9]+$ ]] || (( img_size_bytes <= 0 )); then
			echo "Unable to determine image size for $img"
			return 1
		fi

		sync

		# ------------------------------------------------------------
		# FLASH PHASE (with gauge if pv + $DIALOG available)
		# ------------------------------------------------------------
		if command -v pv >/dev/null 2>&1 && [[ -n "$DIALOG" ]]; then
			local gauge_dir
			gauge_dir=$(mktemp -d) || { echo "Failed to create temp dir"; return 1; }
			local gauge_fifo="${gauge_dir}/fifo"
			mkfifo "$gauge_fifo" || { rm -rf "$gauge_dir"; return 1; }

			# Reader: takes percentages from FIFO and feeds whiptail
			{
				while read -r line; do
					echo "$line"
				done < "$gauge_fifo"
			} | "$DIALOG" --title "Armbian imager" \
				--gauge "\nWriting image to $dev...\n\nPlease wait, this may take a while." 10 70 0 &
			local gauge_pid=$!

			# pv reads the image file, dd writes to device; pv stderr → FIFO (0..100)
			{
				pv -n -s "$img_size_bytes" "$img" \
					| dd of="$dev" bs=4M conv=fsync,noerror status=none
			} 2> "$gauge_fifo"

			# Close FIFO and wait for whiptail to exit
			rm -f "$gauge_fifo"
			rmdir "$gauge_dir" 2>/dev/null || true
			wait "$gauge_pid" 2>/dev/null || true
		else
			# Fallback: console progress
			if [[ -n "$DIALOG" ]]; then
				"$DIALOG" --title "Armbian imager" \
					--infobox "\nWriting image to $dev...\n\nProgress is shown in the console." 8 70
			else
				echo "Writing image to $dev ..."
			fi

			if command -v pv >/dev/null 2>&1; then
				pv -s "$img_size_bytes" "$img" \
					| dd of="$dev" bs=4M conv=fsync,noerror status=none
			else
				dd if="$img" of="$dev" bs=4M conv=fsync,noerror status=progress
			fi
		fi

		sync

		# ------------------------------------------------------------
		# VERIFY PHASE (compare img vs device, with optional gauge)
		# ------------------------------------------------------------
		local verify_result=2   # 1 = OK, 0 = FAILED, 2 = SKIPPED

		if command -v cmp >/dev/null 2>&1; then
			local block_size=$((4*1024*1024))
			local blocks=$(( (img_size_bytes + block_size - 1) / block_size ))

			if command -v pv >/dev/null 2>&1 && [[ -n "$DIALOG" ]]; then
				# Gauge for verification
				local gauge_dir
				gauge_dir=$(mktemp -d) || { echo "Failed to create temp dir"; return 1; }
				local gauge_fifo="${gauge_dir}/fifo"
				mkfifo "$gauge_fifo" || { rm -rf "$gauge_dir"; return 1; }
				{
					while read -r line; do
						echo "$line"
					done < "$gauge_fifo"
				} | "$DIALOG" --title "Armbian imager" \
					--gauge "\nVerifying written image on $dev...\n\nPlease wait." 10 70 0 &
				local v_pid=$!

				# dd reads from device, pv tracks progress, cmp compares against img
				verify_result=1
				{
					dd if="$dev" bs=$block_size count=$blocks status=none \
						| pv -n -s "$img_size_bytes" 2> "$gauge_fifo" \
						| cmp -n "$img_size_bytes" "$img" - >/dev/null
				} || verify_result=0

				rm -f "$gauge_fifo"
				rmdir "$gauge_dir" 2>/dev/null || true
				wait "$v_pid" 2>/dev/null || true
			else
				# No gauge, but still verify
				echo "Verifying written image..."
				if cmp -n "$img_size_bytes" \
					"$img" \
					<(dd if="$dev" bs=$block_size count=$blocks status=none) \
					>/dev/null 2>&1; then
					verify_result=1
				else
					verify_result=0
				fi
			fi
		fi

		sync

		# ------------------------------------------------------------
		# FINAL REPORT
		# ------------------------------------------------------------
		if [[ -n "$DIALOG" ]]; then
			case "$verify_result" in
				1)
					# Success: offer actions
					local action
					action=$("$DIALOG" --title "Armbian imager" \
						--menu "\nFlashing and verification completed successfully.\n\nChoose what to do next:" 14 72 3 \
							"REBOOT"   "Reboot system now" \
							"SHUTDOWN" "Power off the system" \
							"EXIT"     "Return to shell/menu" \
							3>&1 1>&2 2>&3)

					case "$action" in
						REBOOT)
							sync
							reboot
							;;
						SHUTDOWN)
							sync
							poweroff   # or: shutdown -h now
							;;
						*)
							# EXIT or dialog cancelled: just return success
							;;
					esac
					;;
				0)
					"$DIALOG" --title "Armbian imager" \
						--msgbox "⚠ Verification FAILED!\n\nData read from $dev does not match the image.\nPlease try again or check the device." 12 75
					return 1
					;;
				*)
					"$DIALOG" --title "Armbian imager" \
						--msgbox "Flashing completed.\n\nVerification was skipped (cmp not available)." 10 70
					;;
			esac
		else
			# Non-dialog / console mode
			case "$verify_result" in
				1)
					echo "Flashing completed and verified OK."
					read -rp "Action: [r]eboot, [s]hutdown, [e]xit? " action
					case "$action" in
						r|R)
							sync
							reboot
							;;
						s|S)
							sync
							poweroff   # or: shutdown -h now
							;;
						*)
							;;
					esac
					;;
				0)
					echo "Verification FAILED."
					return 1
					;;
				*)
					echo "Flashing completed. Verification skipped (cmp not available)."
					;;
			esac
		fi

		return 0
	}

	# Helper: return 0 if cache directory contains any downloaded image
	# (ignores the index file all-images.json). Intended for menu logic.
	images_cache_has_content() {
		[[ -d "$IMAGES_BASE" ]] || return 1
		if find "$IMAGES_BASE" -maxdepth 1 -type f ! -name 'all-images.json' | read -r _; then
			return 0
		fi
		return 1
	}

	case "$CMD" in
		"${commands[0]}")  # install = main interactive flow
			ensure_board_slug                    || return 1
			refresh_images_json                  || return 1
			confirm_board_or_choose_other        || return 1
			select_preapp_for_board         "$BOARD_SLUG" || return 1
			select_kernel_branch_for_board  "$BOARD_SLUG" || return 1
			select_image_variant_for_board  "$BOARD_SLUG" || return 1
			select_image_for_board          "$BOARD_SLUG" || return 1
			select_block_device             || return 1
			confirm_destroy_device "$TARGET_DEVICE" || return 1
			download_image_file             || return 1
			flash_image_to_device           || return 1
		;;
		"${commands[1]}")  # remove = remove downloaded images only
			if [[ -d "$IMAGES_BASE" ]]; then
				if [[ -n "$DIALOG" ]]; then
					if $DIALOG --yesno "Remove all downloaded Armbian images in:\n\n$IMAGES_BASE\n\nThe index file (all-images.json) will be kept." 12 70; then
						find "$IMAGES_BASE" -maxdepth 1 -type f ! -name 'all-images.json' -delete
					fi
				else
					read -rp "Remove all downloaded images (keep all-images.json) in $IMAGES_BASE? [y/N]: " ans
					if [[ "$ans" =~ ^[Yy]$ ]]; then
						find "$IMAGES_BASE" -maxdepth 1 -type f ! -name 'all-images.json' -delete
					fi
				fi
			fi
		;;
		"${commands[2]}")  # purge = remove everything
			if [[ -d "$IMAGES_BASE" ]]; then
				if [[ -n "$DIALOG" ]]; then
					if $DIALOG --yesno "Completely purge the images cache directory?\n\n$IMAGES_BASE\n\nIndex and all downloaded images will be removed." 12 70; then
						rm -rf "$IMAGES_BASE"
					fi
				else
					read -rp "Purge $IMAGES_BASE (remove everything)? [y/N]: " ans
					if [[ "$ans" =~ ^[Yy]$ ]]; then
						rm -rf "$IMAGES_BASE"
					fi
				fi
			fi
		;;
		"${commands[3]}")  # status
			ensure_board_slug || return 1
			if refresh_images_json; then
				local count promoted_count
				if ! count=$(jq -r --arg board "$BOARD_SLUG" '
					def norm(s): (s | ascii_downcase | gsub("[^a-z0-9]+"; "-"));
					[
					.. | objects
					| select(.board_slug? != null)
					| select((.file_extension? // "") | test("\\.(asc|torrent|sha)"; "i") | not)
					| select(norm(.board_slug) == norm($board))
					]
					| length
				' "$IMAGES_JSON_PATH" 2>/dev/null); then
					echo "Images index: FAILED (parse error in $IMAGES_JSON_PATH)"
					return 1
				fi

				promoted_count=$(jq -r --arg board "$BOARD_SLUG" '
					def norm(s): (s | ascii_downcase | gsub("[^a-z0-9]+"; "-"));
					[
					.. | objects
					| select(.board_slug? != null)
					| select((.file_extension? // "") | test("\\.(asc|torrent|sha)"; "i") | not)
					| select(norm(.board_slug) == norm($board))
					| select(.promoted=="true")
					]
					| length
				' "$IMAGES_JSON_PATH" 2>/dev/null)

				echo "Images index: OK"
				echo "Board slug:        $BOARD_SLUG"
				echo "Images available:  $count"
				echo "Promoted images:   $promoted_count"
				[[ -d "$IMAGES_BASE" ]] && echo "Cache directory:   $IMAGES_BASE"
				[[ -n "$(command -v pv)" ]] && echo "Progress helper:   pv (enabled)" || echo "Progress helper:   pv (not installed)"

				# --- NEW: count flashable block devices (excluding system disks) ---
				local blockdev_count=0
				local raw_devices line dev bytes
				local rootdev bootdev bootefidev
				local rootdisk="" bootdisk="" bootefidisk=""

				# Find devices backing /, /boot, /boot/efi
				rootdev=$(findmnt -n -o SOURCE / 2>/dev/null || echo "")
				bootdev=$(findmnt -n -o SOURCE /boot 2>/dev/null || echo "")
				bootefidev=$(findmnt -n -o SOURCE /boot/efi 2>/dev/null || echo "")

				# Resolve to parent disks
				if [[ -n "$rootdev" ]]; then
					local rd
					rd=$(lsblk -no PKNAME "$rootdev" 2>/dev/null || true)
					rootdisk=${rd:+/dev/$rd}
					[[ -z "$rd" ]] && rootdisk="$rootdev"
				fi

				if [[ -n "$bootdev" ]]; then
					local bd
					bd=$(lsblk -no PKNAME "$bootdev" 2>/dev/null || true)
					bootdisk=${bd:+/dev/$bd}
					[[ -z "$bd" ]] && bootdisk="$bootdev"
				fi

				if [[ -n "$bootefidev" ]]; then
					local ed
					ed=$(lsblk -no PKNAME "$bootefidev" 2>/dev/null || true)
					bootefidisk=${ed:+/dev/$ed}
					[[ -z "$ed" ]] && bootefidisk="$bootefidev"
				fi

				# List candidate devices
				raw_devices=$(lsblk -dpno NAME | grep -E '/dev/(sd|hd|vd|nvme|mmcblk)' || true)

				if [[ -n "$raw_devices" ]]; then
					while IFS= read -r dev; do
						bytes=$(lsblk -bdno SIZE "$dev" 2>/dev/null || echo 0)
						(( bytes <= 0 )) && continue

						# Skip system disks
						[[ "$dev" == "$rootdisk" ]]     && continue
						[[ "$dev" == "$bootdisk" ]]     && continue
						[[ "$dev" == "$bootefidisk" ]]  && continue

						(( blockdev_count++ ))
					done <<< "$raw_devices"
				fi

				echo "Flashable devices: $blockdev_count"

				# If none available → fail status
				if (( blockdev_count < 1 )); then
					echo "No flashable block devices detected."
					return 1
				fi
				# --- END NEW ---
			else
				echo "Images index: FAILED (could not fetch $ALL_IMAGES_JSON_URL)"
				return 1
			fi
		;;
		"${commands[4]}")  # help
			echo -e "\nUsage: ${module_options["module_images,feature"]} <command> [board_slug]"
			echo -e "Commands:  ${module_options["module_images,example"]}"
			echo "Available commands:"
			echo -e "\tinstall\t- Interactive: filter by preinstalled app + stability + kernel + variant, select image, flash to device."
			echo -e "\tremove\t- Remove downloaded image files (keep the index all-images.json)."
			echo -e "\tpurge\t- Remove the entire images cache directory (index + images)."
			echo -e "\tstatus\t- Show images index status and counts for the current board."
			echo -e "\thelp\t- Show this help message."
			echo
			echo "Notes:"
			echo "- Board slug defaults to \$BOARD if not given explicitly."
			echo "- Image list is taken from: $ALL_IMAGES_JSON_URL"
			echo "- Only records with real image file_extension are considered; entries whose"
			echo "  file_extension contains .asc, .torrent or .sha* are ignored."
			echo "- You can filter images by:"
			echo "    * preinstalled_application: ALL / STABLE / barebone / specific (OMV, HA, OpenHAB, ...)"
			echo "      - STABLE = download_repository == \"archive\""
			echo "    * kernel_branch"
			echo "    * image_variant"
			echo "- Image selector columns: version | kernel | variant | size (MB) | {preinstalled}."
			echo "- Menu marks promoted images with a leading '★'."
			echo "- Board matching is case- and separator-insensitive (uefi-x86, UEFI_X86, uefi x86, etc.)."
			echo
		;;
		"cache-status")  # internal: exit 0 if cache has any images, else 1
			images_cache_has_content
		;;
		*)
			${module_options["module_images,feature"]} ${commands[4]}
		;;
	esac
}
