#!/bin/bash

clear
directory="$(dirname "$(readlink -f "$0")")"
cd "${directory}" || exit;

debdir="${directory}/debs" ;
tmpddir="/tmp/build" ;



codename=$( grep VERSION_CODENAME /etc/os-release | cut -d"="  -f2 )

# Loop through files in the bin/ directory
for file in "$directory"/usr/bin/*; do
    filename=$(basename "$file")
    
    debname=$( printf '%s' "armbian-${codename}-${catagory}-${filename}.${version}" )
    # Check if the file is not named config
    if [[ "$(basename "$file")" != "config" ]]; then
        
        # Perform an action for this file
        echo -e "Processing file: $file"

        [[ ! -d "${tmpddir}" ]] && mkdir -p "${tmpddir}/usr/bin" ;
        [[ ! -d "${directory}/debs/" ]] && mkdir -p "${directory}/debs/" ;

        cp -r "${directory}/DEBIAN/DEBIAN_${filename}" "${tmpddir}/DEBIAN" ;
        cp "${directory}/usr/bin/${filename}" "${tmpddir}/usr/bin/" ;
        echo "${directory}/usr/bin/${filename}" "${tmpddir}/usr/bin/" ;

        catagory=$( grep Section ${tmpddir}/DEBIAN/control | cut -d" "  -f2 )
        version=$( grep Version ${tmpddir}/DEBIAN/control | cut -d" "  -f2 )


        dpkg-deb --build "${tmpddir}" "${directory}/debs/${debname}.deb"
        echo -e "\n"
        dpkg-deb -I "${debdir}/${debname}.deb" ;
        echo
        dpkg-deb -c "${debdir}/${debname}.deb" ;

        [[ -d $tmpddir ]] && rm -r "${tmpddir}" ;
    fi
done


build_all(){

[[ ! -d "$tmpddir" ]] && mkdir -p "$tmpddir/usr/" ;
[[ ! -d "$directory/debs/" ]] && mkdir -p "$directory/debs/" ;

cp -r "$directory/DEBIAN/" "$tmpddir" ;
cp -r "$directory/usr/bin/" "$tmpddir"/usr/bin/ ;
cp -r "$directory/usr/lib/" "$tmpddir"/usr/lib/ ;

dpkg-deb --build "$tmpddir" "$directory/debs/$debname.deb"
echo -e "\n"
dpkg-deb -I "$debdir/$debname.deb" ;
echo
dpkg-deb -c "$debdir/$debname.deb" ;

[[ -d $tmpddir ]] && rm -r "$tmpddir" ;

}