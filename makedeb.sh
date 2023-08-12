#!/bin/bash
directory="$(dirname "$(readlink -f "$0")")"
cd $directory || echo "You seem to be in the correct folder" ;
codename=$( grep VERSION_CODENAME /etc/os-release | cut -d"="  -f2 )
catagory=$( grep Section DEBIAN/control | cut -d" "  -f2 )
version=$( grep Version DEBIAN/control | cut -d" "  -f2 )
debname=$( echo "armbian-${codename}-${catagory}-config.${version}" )

# Loop through files in the bin/ directory
for file in bin/*; do
    # Check if the file is not named config
    if [[ "$(basename "$file")" != "config" ]]; then
        # Perform an action for this file
        echo "Processing file: $file"
    fi
done

[[ ! -d /tmp/build ]] && mkdir -p /tmp/build/usr/ ;
[[ ! -d $directory/debs/ ]] && mkdir -p $directory/debs/ ;

cp -r $directory/DEBIAN/ /tmp/build/ ;
cp -r $directory/usr/bin/ /tmp/build/usr/bin/ ;
cp -r $directory/usr/lib/ /tmp/build/usr/lib/ ;
dpkg-deb --build /tmp/build $directory/debs/$debname.deb
dpkg-deb --contents $directory/debs/$debname.deb

[[ -d /tmp/build ]] && rm -r /tmp/build ;
