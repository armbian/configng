
module_options+=(
	["module_qr_code,author"]="@igorpecovnik"
	["module_qr_code,ref_link"]=""
	["module_qr_code,feature"]="qr_code"
	["module_qr_code,desc"]="Show or generate QR code for Google OTP"
	["module_qr_code,example"]="module_qr_code generate"
	["module_qr_code,status"]="Active"
)
#
# check dpkg status of $1 -- currently only 'not installed at all' case caught
#
function module_qr_code() {

	clear
	if [[ "$1" == "generate" ]]; then
		google-authenticator -t -d -f -r 3 -R 30 -W -q
		cp /root/.google_authenticator /etc/skel
		update_skel
	fi
	export TOP_SECRET=$(head -1 /root/.google_authenticator)
	qrencode -m 2 -d 9 -8 -t ANSI256 "otpauth://totp/test?secret=$TOP_SECRET"
	echo -e '
Scan QR code with your OTP application on mobile phone
'
	read -n 1 -s -r -p "Press any key to continue"

}

