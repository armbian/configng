#!/bin/bash
directory="$(dirname "$(readlink -f "$0")")"
cd $directory || echo "You seem to be in the correct folder" ;
codename=$( grep VERSION_CODENAME /etc/os-release | cut -d"="  -f2 )
catagory=$( grep Section DEBIAN/control | cut -d" "  -f2 )
version=$( grep Version DEBIAN/control | cut -d" "  -f2 )
debname=$( echo "armbian-${codename}-${catagory}-config.${version}" )

echo $debname

[[ ! -d /tmp/build ]] && mkdir -p /tmp/build/usr/ ;

cp -r $directory/DEBIAN/ /tmp/build/ ;
cp -r $directory/usr/bin/ /tmp/build/usr/bin/ ;
cp -r $directory/usr/lib/ /tmp/build/usr/lib/ ;
dpkg-deb --build /tmp/build $directory/debs/$debname.deb
dpkg-deb --contents $directory/debs/$debname.deb

[[ -d /tmp/build ]] && rm -r /tmp/build ;
