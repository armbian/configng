#!/bin/bash

# Choose a dialog frontend if one not specified
if [ -z "${DIALOG_FRONTEND}" ]; then
    [ -x /usr/bin/whiptail ] && DIALOG_FRONTEND=/usr/bin/whiptail
    [ -x /usr/bin/dialog ] && DIALOG_FRONTEND=/usr/bin/dialog
    if [ ! -z "${DISPLAY}" ]; then
	[ -x /usr/bin/kdialog ] && DIALOG_FRONTEND=/usr/bin/kdialog
	[ -x /usr/bin/gdialog ] && DIALOG_FRONTEND=/usr/bin/gdialog
    fi
fi

# Dialog wrapper
xdialog() {

    # Output variable
    OUTVAR="$1"
    shift

    # Console based frontends need special handling to get output
    case "${DIALOG_FRONTEND}" in
	/usr/bin/dialog | /usr/bin/whiptail)
	    exec 3>&1
            SELECT=$("${DIALOG_FRONTEND}" "$@" 2>&1 1>&3 )
            RC=$?
	    clear
            exec 3>&-
	    ;;

	*)
	    SELECT=$("${DIALOG_FRONTEND}" "$@" 2>&1)
            RC=$?
	    ;;
    esac

    # Return status
    eval "$OUTVAR=\"$SELECT\""
    return $RC
}

# Menu system
menu_system() {

    # Arguments
    local MENU_ROOT="$1"                # Menu root on filesystem
    local MENU_PATH=$(realpath -m "$2") # Current position in menu

    # What's here?
    local FS_PATH="${MENU_ROOT}/${MENU_PATH##\/}"
    if [ -d "${FS_PATH}" ]; then

	while true; do

	    # Directores are submenus, build dialog menu from contents
	    pushd "${FS_PATH}" > /dev/null
	    shopt -s nullglob
	    local TAGS=(*)
	    if [ "${#TAGS[@]}" -eq 0 ]; then
		# Empty directory, nothing to select
		xdialog SELECTION --msgbox "$(gettext -s 'empty menu')" 0 0
		return
	    fi

	    # Menu title
	    local MENU_TITLE=$(gettext -s "${MENU_PATH}")
	    local ARGS=( --menu "${MENU_TITLE}" )
	    if [ "$(basename "${DIALOG_FRONTEND}")" != "kdialog" ]; then
		ARGS+=( 0 0 0 )
	    fi

	    # Generate list of selectable options
	    for TAG in "${TAGS[@]}"; do
		local TAG_PATH=$(realpath -m "/${MENU_PATH}/${TAG}")
		ARGS+=( "${TAG}" "$(gettext -s "${TAG_PATH}")" )
	    done
	    popd > /dev/null

	    # Ask user what to do
	    xdialog SELECTION "${ARGS[@]}"
	    if [ $? -ne 0 ]; then
		return;
	    elif [ ! -z "${SELECTION}" ]; then
		menu_system "${MENU_ROOT}" "${MENU_PATH}/${SELECTION}"
	    fi

	done

    elif [ -x "${FS_PATH}" ]; then

	# Leaf nodes of menu systems are simply scripts
	"${FS_PATH}"
	return $?

    else
	xdialog --msgbox "Invalid menu location: ${FS_PATH}" 0 0
    fi
}
