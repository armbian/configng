#!/bin/bash
set +e
# overwrite stock lightdm greeter configuration
if [ -d /etc/armbian/lightdm ]; then cp -R /etc/armbian/lightdm /etc/; fi


#Adjust xsettings.xml for NumixBlue Theme Ubuntu
if [ -f /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml ]; then sed -i 's/Xfce-dusk/NumixBlue/g' /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml; fi

# Adjust menu
if [ -f /etc/xdg/menus/xfce-applications.menu ]; then
sed -i -n '/<Menuname>Settings<\/Menuname>/{p;:a;N;/<Filename>xfce4-session-logout.desktop<\/Filename>/!ba;s/.*\n/\
\t<Separator\/>\n\t<Merge type="all"\/>\n        <Separator\/>\n        <Filename>armbian-donate.desktop<\/Filename>\
\n        <Filename>armbian-support.desktop<\/Filename>\n/};p' /etc/xdg/menus/xfce-applications.menu
fi

# XFCE has no default applications list. Without it, PDF and images
# open in Chrome and text in LibreOffice Writer. The data directory keeps
# /etc/xdg/mimeapps.list in control.
install -d /usr/share/applications
cat > /usr/share/applications/xfce-mimeapps.list <<EOF
[Default Applications]
application/pdf=org.gnome.Papers.desktop;org.gnome.Evince.desktop;
text/plain=org.xfce.mousepad.desktop;
image/bmp=org.xfce.ristretto.desktop;viewnior.desktop;
image/gif=org.xfce.ristretto.desktop;viewnior.desktop;
image/jpeg=org.xfce.ristretto.desktop;viewnior.desktop;
image/png=org.xfce.ristretto.desktop;viewnior.desktop;
image/tiff=org.xfce.ristretto.desktop;viewnior.desktop;
image/webp=org.xfce.ristretto.desktop;viewnior.desktop;
EOF

# Hide few items
if [ -f /usr/share/applications/display-im6.q16.desktop ]; then mv /usr/share/applications/display-im6.q16.desktop /usr/share/applications/display-im6.q16.desktop.hidden; fi
if [ -f /usr/share/applications/display-im6.desktop ]; then  mv /usr/share/applications/display-im6.desktop /usr/share/applications/display-im6.desktop.hidden; fi
if [ -f /usr/share/applications/vim.desktop ]; then  mv /usr/share/applications/vim.desktop /usr/share/applications/vim.desktop.hidden; fi
if [ -f /usr/share/applications/libreoffice-startcenter.desktop ]; then mv /usr/share/applications/libreoffice-startcenter.desktop /usr/share/applications/libreoffice-startcenter.desktop.hidden; fi

# Disable Pulseaudio timer scheduling which does not work with sndhdmi driver
if [ -f /etc/pulse/default.pa ]; then sed "s/load-module module-udev-detect$/& tsched=0/g" -i  /etc/pulse/default.pa; fi
