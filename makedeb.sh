#!/bin/bash
directory="$(dirname "$(readlink -f "$0")")"
cd $directory ;


codename=$( grep VERSION_CODENAME /etc/os-release | cut -d"="  -f2 )
catagory=$( grep Section DEBIAN/control | cut -d" "  -f2 )
version=$( grep Version DEBIAN/control | cut -d" "  -f2 )
debname=$( echo "armbian-${codename}-${catagory}-config.${version}" )
debdir="$directory/debs" ;
tmpddir="/tmp/build" ;

# Loop through files in the bin/ directory
for file in $directory/usr/bin/; do
    # Check if the file is not named config
    if [[ "$(basename "$file")" != "config" ]]; then
        # Perform an action for this file
        echo "Processing file: $file"
    fi
done

[[ ! -d $tmpddir ]] && mkdir -p /tmp/build/usr/ ;
[[ ! -d $directory/debs/ ]] && mkdir -p "$directory/debs/" ;

cp -r "$directory/DEBIAN/" /tmp/build/ ;
cp -r "$directory/usr/bin/" /tmp/build/usr/bin/ ;
cp -r "$directory/usr/lib/" /tmp/build/usr/lib/ ;

dpkg-deb --build /tmp/build "$directory/debs/$debname.deb"
echo -e "\n"
dpkg-deb -I "$debdir/$debname.deb" ;
echo
dpkg-deb -c "$debdir/$debname.deb" ;

[[ -d $tmpddir ]] && rm -r "$tmpddir" ;

