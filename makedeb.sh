#!/bin/bash

clear
directory="$(dirname "$(readlink -f "$0")")"
cd "${directory}" || exit;

debdir="${directory}/debs" ;
tmpddir="/tmp/build" ;
codename=$( grep VERSION_CODENAME /etc/os-release | cut -d"="  -f2 )

build_debs(){
# Loop through files in the bin/ directory
for file in "$directory"/usr/bin/*; do

    filename=$(basename "$file") 

    [[ ! -d "${tmpddir}" ]] && mkdir -p "${tmpddir}/usr/bin" ;
    [[ ! -d "${directory}/debs/" ]] && mkdir -p "${directory}/debs/" ;

    # Check if the file is not named config
    if [[ "$(basename "$file")" != "config" ]]; then
        
        # Perform an action for this file
        echo -e "Processing file: $file"
        cp -r "${directory}/DEBIAN/DEBIAN_${filename}" "${tmpddir}/DEBIAN" ;
        catagory=$( grep Section ${tmpddir}/DEBIAN/control | cut -d" "  -f2 )
        version=$( grep Version ${tmpddir}/DEBIAN/control | cut -d" "  -f2 )
        debname=$( printf '%s' "armbian-${codename}-${catagory}-${filename}.${version}" )
        cp "${directory}/usr/bin/${filename}" "${tmpddir}/usr/bin/" ;
        echo "${directory}/usr/bin/${filename}" "${tmpddir}/usr/bin/" ;
        
        dpkg-deb --build "${tmpddir}" "${directory}/debs/${debname}.deb"
        echo -e "\n"
        dpkg-deb -I "${debdir}/${debname}.deb" ;
        echo
        dpkg-deb -c "${debdir}/${debname}.deb" ;
        echo
        tree /tmp/build
        echo

        elif [[ "$(basename "$file")" == "config" ]]; then
        # Perform an action for the config file
        # ...


        build_all
        else
        # Handle any other cases
        echo "Error: Unknown file"

    fi
    
    unset filename debname catagory version ;
    [[ -d $tmpddir ]] && rm -r "${tmpddir}" ;

done

}
build_all(){
    # Perform an action for this file
    echo -e "Processing file: $file"
    cp -r "${directory}/DEBIAN/DEBIAN_${filename}" "${tmpddir}/DEBIAN" ;
    catagory=$( grep Section ${tmpddir}/DEBIAN/control | cut -d" "  -f2 )
    version=$( grep Version ${tmpddir}/DEBIAN/control | cut -d" "  -f2 )
    debname=$( printf '%s' "armbian-${codename}-${catagory}-${filename}.${version}" )
    cp "${directory}/usr/bin/${filename}" "${tmpddir}/usr/bin/" ;
    cp -r "${directory}/usr/lib/${filename}" "${tmpddir}/usr/lib/" ;
    echo "${directory}/usr/bin/${filename}" "${tmpddir}/usr/bin/" ;

    dpkg-deb --build "${tmpddir}" "${directory}/debs/${debname}.deb"
    echo -e "\n"
    dpkg-deb -I "${debdir}/${debname}.deb" ;
    echo
    dpkg-deb -c "${debdir}/${debname}.deb" ;
    echo
    tree /tmp/build
    echo




cp -r "$directory/DEBIAN/DEBIAN_config/" "$tmpddir/DEBIAN" ;
cp -r "$directory/usr/bin/" "$tmpddir"/usr/bin/ ;
cp -r "$directory/usr/lib/" "$tmpddir"/usr/lib/ ;

dpkg-deb --build "$tmpddir" "$directory/debs/$debname.deb"
echo -e "\n"
dpkg-deb -I "$debdir/$debname.deb" ;
echo
dpkg-deb -c "$debdir/$debname.deb" ;

[[ -d $tmpddir ]] && rm -r "$tmpddir" ;

}

build_debs