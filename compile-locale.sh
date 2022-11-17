#!/bin/bash

# Start in known directory
cd $(dirname $(readlink -f "$0"))

cd locale.in
FILES=(*.po)
for PO_FILE in "${FILES[@]}"; do
    BASE=$(basename "${PO_FILE}" .po)
    MO_FILE="../locale/${BASE}/LC_MESSAGES/armbian-reconfig.mo"
    if [ ! -f "${MO_FILE}" -o "${PO_FILE}" -nt "${MO_FILE}" ]; then
	echo -n "Locale \"${BASE}\": "
	mkdir -p $(dirname "${MO_FILE}")
	msgfmt -v -o "${MO_FILE}" "${PO_FILE}"
    fi
done
