#!/bin/bash

# This file is part of Armbian configuration utility.

module_options+=(
	["generate_readme,author"]="@Tearran"
	["generate_readme,ref_link"]=""
	["generate_readme,feature"]="generate_readme"
	["generate_readme,desc"]="Generate Document files."
	["generate_readme,example"]="generate_readme"
	["generate_readme,status"]="review"
)
#
# Function to generate the README.md file
#
function generate_readme() {

	# Get the current date
	local current_date=$(date)
	# setup doc folders
	#mkdir -p "$script_dir/../share/doc/armbian-config"

	echo -e "Sorting data\nUpdating documentation" # current_date ;

	cat << EOF_DOC > "$script_dir/../DOCUMENTATION.md"

# Armbian Configuration Utility

<img src="https://raw.githubusercontent.com/armbian/configng/main/share/icons/hicolor/scalable/configng-tux.svg">

Utility for configuring your board, adjusting services, and installing applications. It comes with Armbian by default.

To start the Armbian configuration utility, use the following command:
~~~
sudo armbian-config
~~~

$(see_full_list)

## Install
Armbian installation
~~~
sudo apt install armbian-config
~~~

3rd party Debian based distributions
~~~
{
	sudo wget https://apt.armbian.com/armbian.key -O key
	sudo gpg --dearmor < key | sudo tee /usr/share/keyrings/armbian.gpg > /dev/null
	sudo chmod go+r /usr/share/keyrings/armbian.gpg
	echo << EOF | sudo tee /etc/apt/sources.list.d/armbian.sources
	Types: deb
	URIs: https://apt.armbian.com
	Suites: $(lsb_release -cs)
	Components: main $(lsb_release -cs)-utils $(lsb_release -cs)-desktop
	Architectures: $(dpkg --print-architecture)
	Signed-By: /usr/share/keyrings/armbian.gpg
	EOF
	sudo apt update
	sudo apt install armbian-config
}
~~~

***

## CLI options
Command line options.

Use:
~~~
armbian-config --help
~~~

Outputs:
~~~
$(see_cmd_list)
~~~

## Legacy options
Backward Compatible options.

Use:
~~~
armbian-config main=Help
~~~

Outputs:
~~~
$(see_cli_legacy)
~~~

***

## Development

Development is divided into three sections:

Click for more info:

<details>
<summary><b>Jobs / JSON Object</b></summary>

A list of the jobs defined in the Jobs file.
~~~
$(see_jq_menu_list)
~~~
</details>


<details>
<summary><b>Jobs API / Helper Functions</b></summary>

These helper functions facilitate various operations related to job management, such as creation, updating, deletion, and listing of jobs, acting as a practical API for developers.

$(see_function_table_md)


</details>


<details>
<summary><b>Runtime / Board Statuses</b></summary>

(WIP)

This section outlines the runtime environment to check configurations and statuses for dynamically managing jobs based on JSON data.

(WIP)

</details>


## Testing and contributing

<details>
<summary><b>Get Development</b></summary>

Install the dependencies:
~~~
sudo apt install git jq whiptail
~~~

Get Development and contribute:
~~~
{
git clone https://github.com/armbian/configng
cd configng
./armbian-config --help
}
~~~

Install and test Development deb:
~~~
{
	sudo apt install whiptail
	latest_release=\$(curl -s https://api.github.com/repos/armbian/configng/releases/latest)
	deb_url=\$(echo "\$latest_release" | jq -r '.assets[] | select(.name | endswith(".deb")) | .browser_download_url')
	curl -LO "\$deb_url"
	deb_file=\$(echo "\$deb_url" | awk -F"/" '{print \$NF}')
	sudo dpkg -i "\$deb_file"
	sudo dpkg --configure -a
	sudo apt --fix-broken install
}
~~~

</details>

EOF_DOC

}

module_options+=(
	["serve_doc,author"]="@Tearran"
	["serve_doc,ref_link"]=""
	["serve_doc,feature"]="serve_doc"
	["serve_doc,desc"]="Serve the edit and debug server."
	["serve_doc,example"]="serve_doc"
	["serve_doc,status"]="active"
	["serve_doc,doc_link"]=""
)
#
# Function to serve the edit and debug server
#
function serve_doc() {
	if [[ "$(id -u)" == "0" ]]; then
		echo "Red alert! not for sudo user"
		exit 1
	fi
	if [[ -z $CODESPACES ]]; then
		# Start the Python server in the background
		python3 -m http.server > /tmp/config.log 2>&1 &
		local server_pid=$!
		local input=("
	Starting server...
		Server PID: $server_pid

	Press [Enter] to exit"
		)

		$DIALOG --title "Message Box" --msgbox "$input" 0 0

		# Stop the server
		kill "$server_pid"
	else
		echo "Info:GitHub Codespace"
		exit 0
	fi
}

module_options+=(
	["see_use,author"]="@Tearran"
	["see_use,ref_link"]=""
	["see_use,feature"]="see_use"
	["see_use,desc"]="Show the usage of the functions."
	["see_use,example"]="see_use"
	["see_use,status"]="review"
	["see_use,doc_link"]=""
)
#
# Function to parse the key-pairs  (WIP)
#
function see_use() {
	mod_message="Usage: \n\n"
	# Iterate over the options
	for key in "${!module_options[@]}"; do
		# Split the key into function_name and type
		IFS=',' read -r function_name type <<< "$key"
		# If the type is 'long', append the option to the help message
		if [[ "$type" == "feature" ]]; then
			mod_message+="${module_options["$function_name,feature"]} - ${module_options["$function_name,desc"]}\n"
			mod_message+="  ${module_options["$function_name,example"]}\n\n"
		fi
	done

	echo -e "$mod_message"
}

module_options+=(
	["generate_json_options,author"]="@Tearran"
	["generate_json_options,ref_link"]=""
	["generate_json_options,feature"]="generate_json"
	["generate_json_options,desc"]="Generate JSON-like object file."
	["generate_json_options,example"]="generate_json"
	["generate_json_options,status"]="review"
	["generate_json_options,doc_link"]=""
)
#
# Function to generate a JSON-like object file
#
function generate_json_options() {
	echo -e "{\n\"configng-helpers\" : ["
	features=()
	for key in "${!module_options[@]}"; do
		if [[ $key == *",feature" ]]; then
			features+=("${module_options[$key]}")
		fi
	done

	for index in "${!features[@]}"; do
		feature=${features[$index]}
		desc_key="${feature},desc"
		example_key="${feature},example"
		author_key="${feature},author"
		ref_key="${feature},ref_link"
		status_key="${feature},status"
		doc_key="${feature},doc_link"
		author="${module_options[$author_key]}"
		ref_link="${module_options[$ref_key]}"
		status="${module_options[$status_key]}"
		doc_link="${module_options[$doc_key]}"
		desc="${module_options[$desc_key]}"
		example="${module_options[$example_key]}"
		echo "  {"
		echo "    \"id\": \"$feature\","
		echo "    \"Author\": \"$author\","
		echo "    \"src_reference\": \"$ref_link\","
		echo "    \"description\": \"$desc\","
		echo "    \"command\": [ \"$example\" ]",
		echo "    \"status\": \"$status\","
		echo "    \"doc_link\": \"$doc_link\""
		if [ $index -ne $((${#features[@]} - 1)) ]; then
			echo "  },"
		else
			echo "  }"
		fi
	done
	echo "]"
	echo "}"
}

module_options+=(
	["generate_svg,author"]="@Tearran"
	["generate_svg,ref_link"]=""
	["generate_svg,feature"]="generate_svg"
	["generate_svg,desc"]="Generate 'Armbian CPU logo' SVG for document file."
	["generate_svg,example"]="generate_svg"
	["generate_svg,status"]="review"
	["generate_svg,doc_link"]=""
)
#
# This function is used to generate a armbian CPU logo
#
function generate_svg() {

	cat << EOF
<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 300 300">
	<g transform="translate(-490 -250)">
		<path d="m531.27 266.49c-18.24 0-24.775 6.5634-24.775 24.775-2.7972 0-17.438-1.6276-14.991 4.3366 1.5539 3.7891 11.675 2.0864 14.991 2.0864v7.3409h-15.599c0.28666 8.7296 8.9244 6.423 15.599 6.423v6.4229h-15.599c0.28668 8.6209 9.0411 6.4229 15.599 6.4229v6.4229c-3.6404 0-11.14-1.425-14.127 0.94235-7.9785 6.3216 11.963 6.3985 14.127 6.3985v6.4229h-15.599v5.5055h15.599v7.3409c-6.6746 0-15.313-2.3064-15.599 6.4229 6.4474 0 14.957-1.9998 15.599 6.423-6.5579 0-15.313-2.1978-15.599 6.4229 6.4474 0 14.957-1.9999 15.599 6.4229-2.1649 0-22.106 0.0767-14.127 6.3985 2.988 2.3673 10.486 0.94233 14.127 0.94233-0.3013 9.2518-8.4634 7.3409-15.599 7.3409v5.5055h15.599v7.3408h-15.599c0.28666 8.7296 8.9244 6.423 15.599 6.423v6.4229h-15.599c0.28666 8.7296 8.9244 6.423 15.599 6.423v6.4229h-15.599v6.423h15.599v7.3408h-15.599v5.5055c7.1357 0 15.298-1.9116 15.599 7.3409-6.6746 0-15.313-2.3064-15.599 6.4229l15.599 0.9176v5.5055c-6.5579 0-15.313-2.1978-15.599 6.4229h15.599v7.3409h-15.599c0.28666 8.7296 8.9244 6.423 15.599 6.423v7.3408h-15.599c0.60794 7.8026 9.6604 5.5055 15.599 5.5055 0 18.486 6.2886 24.775 24.775 24.775 0 2.7972-1.6276 17.438 4.3366 14.991 3.789-1.5539 2.0865-11.675 2.0865-14.991 9.2518 0.30131 7.3409 8.4634 7.3409 15.599 8.7296-0.28665 6.4229-8.9244 6.4229-15.599h6.4229v15.599c8.7296-0.28665 6.423-8.9244 6.423-15.599h6.4229c0 3.6404-1.4249 11.14 0.94234 14.127 6.3216 7.9784 6.3985-11.963 6.3985-14.127h6.4229v15.599h5.5055v-15.599h7.3408c0 3.6404-1.4249 11.14 0.94236 14.127 6.3216 7.9784 6.3985-11.963 6.3985-14.127h6.4229v15.599c8.6209-0.28668 6.423-9.0411 6.423-15.599h6.4229v15.599c8.7296-0.28665 6.423-8.9244 6.423-15.599h6.4229c0 2.9095-1.7644 17.416 4.3139 14.991 3.8146-1.5216 2.1092-11.679 2.1092-14.991h7.3408c0 2.9095-1.7644 17.416 4.314 14.991 3.8146-1.5217 2.1092-11.679 2.1092-14.991h6.423v15.599h6.4229v-15.599h6.4229c0 2.1648 0.0767 22.106 6.3985 14.127 2.3674-2.988 0.94236-10.486 0.94236-14.127h6.4229v15.599c8.6209-0.28668 6.423-9.0411 6.423-15.599h6.4229c0 2.1648 0.077 22.106 6.3985 14.127 2.3674-2.988 0.94237-10.486 0.94237-14.127 8.423 0.64261 6.4229 9.1516 6.4229 15.599 8.6209-0.28668 6.423-9.0411 6.423-15.599h6.4229v15.599h6.423v-15.599h7.3408v15.599c7.8026-0.60793 5.5055-9.6604 5.5055-15.599 18.486 0 24.775-6.2886 24.775-24.775 5.9389 0 14.991 2.2972 15.599-5.5055-7.1356 0-15.298 1.9116-15.599-7.3408 6.6746 0 15.313 2.3064 15.599-6.423-7.1356 0-15.298 1.9116-15.599-7.3409h15.599c-0.28665-8.6209-9.0417-6.4229-15.599-6.4229v-5.5055l15.599-0.9176c-0.28655-8.7296-8.9244-6.4229-15.599-6.4229 0.30124-9.2518 8.4633-7.3409 15.599-7.3409v-5.5055h-15.599v-7.3408h15.599c-0.28655-8.7296-8.9244-6.423-15.599-6.423v-6.4229c6.6746 0 15.313 2.3064 15.599-6.423h-15.599v-6.4229c6.6746 0 15.313 2.3064 15.599-6.423h-15.599v-7.3408h15.599v-5.5055c-7.1356 0-15.298 1.9116-15.599-7.3409 3.6404 0 11.14 1.4249 14.127-0.94233 7.9784-6.3216-11.963-6.3985-14.127-6.3985 0.64246-8.423 9.1516-6.4229 15.599-6.4229-0.28655-8.7296-8.9244-6.4229-15.599-6.4229 0.64259-8.4231 9.1516-6.423 15.599-6.423v-6.4229h-15.599v-7.3409h15.599v-5.5055h-15.599v-6.4229c2.1647 0 22.106-0.0771 14.127-6.3985-2.988-2.3674-10.486-0.94235-14.127-0.94235v-6.4229c6.6746 0 15.313 2.3064 15.599-6.4229-6.4474 0-14.957 1.9998-15.599-6.4229 6.6746 0 15.313 2.3064 15.599-6.423-7.1356 0-15.298 1.9116-15.599-7.3409 2.9095 0 17.416 1.7644 14.991-4.3139-1.5217-3.8146-11.679-2.1092-14.991-2.1092 0-18.218-6.4413-24.775-24.775-24.775v-15.599c-7.8026 0.60791-5.5055 9.6604-5.5055 15.599h-7.3408c0-2.9095 1.7644-17.417-4.314-14.991-3.8146 1.5217-2.1092 11.679-2.1092 14.991h-6.4229c0-6.6746 2.3064-15.313-6.423-15.599v15.599h-6.4229c0-3.596 1.5526-12.144-1.5951-14.652-6.8474-5.4551-5.7455 12.046-5.7455 14.652h-6.4229c0-2.7971 1.6276-17.438-4.3366-14.991-3.7891 1.5539-2.0865 11.675-2.0865 14.991h-6.4229c0-2.1648-0.0769-22.106-6.3985-14.127-2.3672 2.9878-0.94232 10.486-0.94232 14.127h-6.423c0-3.3122 1.7055-13.47-2.1092-14.991-6.0784-2.4247-4.3139 12.082-4.3139 14.991h-6.423c0-6.6746 2.3064-15.313-6.4229-15.599v15.599h-7.3408c0-3.3122 1.7054-13.47-2.1092-14.991-6.0784-2.4247-4.314 12.082-4.314 14.991h-6.4229c0-3.3122 1.7054-13.47-2.1092-14.991-6.0784-2.4247-4.314 12.082-4.314 14.991h-6.423c0-6.5579 2.1978-15.313-6.4229-15.599v15.599h-6.4229c0-2.6541 1.038-19.691-5.8702-14.638-3.0623 2.2398-1.4705 11.253-1.4705 14.638h-7.3408c0-2.8517 1.6823-15.015-2.7528-15.015-4.435 0-2.7528 12.164-2.7528 15.015h-6.4229c0-3.596 1.5526-12.144-1.5951-14.652-6.8474-5.4551-5.7456 12.046-5.7456 14.652h-6.4229c0-6.5579 2.1978-15.313-6.4229-15.599v15.599h-6.4229c0-2.9095 1.7644-17.417-4.314-14.991-3.8145 1.5217-2.1092 11.679-2.1092 14.991h-7.3409c0-3.0107 1.7488-15.887-3.5606-15.172-4.6127 0.62178-2.8625 11.954-2.8625 15.172zm115.49 140.65c-0.5047-0.16836-2.0979-0.56777-3.5404-0.88755l-2.6228-0.58152 0.59477-18.539c0.32711-10.196 0.24693-21.508-0.17822-25.137-0.74355-6.3472-0.69577-6.6178 1.2546-7.1076 1.1152-0.27988 2.6841-0.76082 3.4867-1.0688 1.3039-0.50035 1.3956 0.62178 0.86184 10.548-0.43689 8.1256-0.31302 11.108 0.46131 11.108 0.58225 0 1.0586-0.65115 1.0586-1.4469 0-2.5955 5.1051-6.8114 8.2478-6.8114 4.3109 0 6.3961 1.5301 8.5488 6.2721 2.4632 5.4269 2.592 17.07 0.25032 22.631-3.4321 8.1513-11.877 13.202-18.424 11.019zm10.172-5.4807c4.149-2.7186 5.7466-18.431 2.5411-24.993-1.3399-2.7429-2.2945-3.5429-4.484-3.7574-4.767-0.46712-6.8914 2.8352-7.9564 12.366-1.0133 9.0729-0.45363 16.736 1.3083 17.913 1.481 0.98906 5.9661 0.19091 8.591-1.5288zm-117.88 0.7066c-1.8883-3.7766-1.394-6.5243-0.15968-11.108 1.6742-6.2177 6.8883-9.3593 15.534-9.3593h4.0267l-0.50923-3.7966c-0.28008-2.0882-1.1596-4.4469-1.9544-5.2418-1.8146-1.8146-7.6847-1.6732-11.454 0.27594-2.6304 1.3603-2.8228 1.3338-3.8176-0.52477-1.2429-2.3224-0.44211-3.0404 5.0996-4.5722 4.8229-1.3331 11.951-0.59052 14.243 1.484 2.8979 2.6227 3.6171 7.256 3.5247 22.71l-0.0863 14.44h-2.6434c-2.4006 0-2.6434-0.28997-2.6434-3.1574 0-1.7365-0.41291-3.4126-0.91763-3.7245-0.50466-0.31187-0.9176-0.0223-0.9176 0.64341 0 0.66581-1.049 2.3418-2.3311 3.7245-1.8556 2.0013-3.1491 2.514-6.3417 2.514-3.3078 0-7.1302-1.2651-8.6515-4.3074zm16.004-3.4837c1.866-2.4465 2.4732-4.3431 2.57-8.0292 0.12551-4.7725 0.095-4.8288-2.7622-5.1063-8.7803-0.85274-14.459 7.529-9.432 13.921 2.8094 3.5715 6.5323 3.2677 9.6237-0.78545zm15.825-11.249c-0.15507-10.471-0.28188-19.084-0.28188-19.137 0-0.0532 1.342-0.35304 2.9822-0.66526l2.9821-0.56767v4.565c0 2.5107 0.41292 4.565 0.9176 4.565s0.91761-0.67387 0.91761-1.4974c0-1.9538 6.0872-7.6786 8.1647-7.6786 1.2679 0 1.525 0.58604 1.2069 2.7527-0.31162 2.1233-0.87613 2.7528-2.4686 2.7528-2.5046 0-6.6917 3.9917-7.6096 7.2547-0.36828 1.3088-0.66959 7.8502-0.66959 14.536v12.157l-5.8594 2e-3zm20.822 1.8356c0-9.4631-0.33749-18.134-0.75001-19.269-0.62855-1.7302-0.43303-2.0646 1.2073-2.0646 1.0765 0 2.7561-0.42742 3.7322-0.94991 1.6209-0.86741 1.7749-0.62286 1.7749 2.8181v3.768l3.0906-3.2769c2.5321-2.6848 3.7466-3.2769 6.7222-3.2769 3.6404 0 7.6218 2.7869 7.6218 5.3352 0 1.6218 0.43336 1.3886 3.9456-2.1236 2.626-2.626 3.8976-3.2115 6.9738-3.2115 2.5387 0 4.3589 0.59679 5.5972 1.8351 1.6706 1.6706 1.8351 3.0586 1.8351 15.471 0 7.4996 0.26257 15.551 0.58351 17.893l0.58353 4.2572h-6.6727v-15.992c0-13.315-0.24141-16.234-1.4419-17.434-1.9467-1.9467-5.2323-1.8167-7.8618 0.31102-2.1237 1.7184-2.1662 2.0609-2.1662 17.432v15.68l-6.426 3e-3 2e-3 -15.5c1e-3 -13.955-0.17279-15.692-1.7465-17.434-2.3459-2.5957-5.2577-2.438-7.9558 0.43105-2.1392 2.2745-2.2357 2.9434-2.5157 17.434l-0.29153 15.069-5.8408 6e-4zm82.881 0.30382c0.191-10.716-0.0541-17.566-0.66972-18.717-0.82246-1.5368-0.63594-1.8983 1.2193-2.364 1.2046-0.30236 2.7448-0.76248 3.4225-1.0226 1.0077-0.38669 1.2322 3.1235 1.2322 19.266v19.738l-5.5055 2e-3zm14.811 14.577c-1.7094-1.8194-2.2525-3.5614-2.5037-8.0292-0.54565-9.7043 4.215-14.423 14.551-14.423h4.7382l-0.50926-3.7966c-0.28005-2.0882-1.121-4.4084-1.8688-5.1561-1.7466-1.7467-7.9351-1.6737-11.432 0.13455-2.573 1.3306-2.7362 1.2959-3.6827-0.78154-0.91377-2.0055-0.70904-2.2864 2.6434-3.6278 1.9987-0.79967 5.8901-1.454 8.6478-1.454 4.2417 0 5.475 0.41197 8.0102 2.6755l2.9967 2.6755 0.57231 34.105h-2.8094c-2.689 0-2.8108-0.16727-2.8386-3.8998-0.0274-3.6777-0.1081-3.7952-1.4133-2.0646-4.0451 5.3633-4.9463 5.9643-8.944 5.9643-3.0674 0-4.4738-0.53067-6.1579-2.3236zm13.196-5.0214c2.3332-2.7729 4.0332-9.7349 3.0212-12.372-0.63441-1.6533-4.6117-1.8095-8.8103-0.34588-2.0256 0.70616-3.4 2.0268-4.266 4.0997-1.6716 4.0006-1.6165 4.8438 0.54742 8.3931 2.4465 4.0125 6.2452 4.1023 9.5083 0.22503zm15.736-11.457v-18.8l2.6603-0.92693c1.4632-0.50983 2.8052-0.92696 2.9822-0.92696 0.17698 0 0.32187 1.5258 0.32187 3.3908v3.3908l3.1059-3.3908c2.7107-2.9595 3.6381-3.3908 7.2896-3.3908 3.0984 0 4.8507 0.57382 6.7552 2.2122l2.5719 2.2122 0.66196 35.032h-6.2312l0.34952-14.452c0.21707-8.9794-0.0238-15.413-0.63719-16.992-1.9642-5.0566-8.4585-5.0929-11.753-0.0657-1.4169 2.162-1.6537 4.5983-1.6537 17.016v14.492l-6.423-3.2e-4zm-44.044-27.078c-0.94906-2.9902 0.32893-5.5055 2.7971-5.5055 1.6001 0 2.3753 0.63983 2.7934 2.3059 1.0568 4.2109-4.297 7.2749-5.5905 3.1996z" style="fill:none;stroke:#ff0000"/>
	</g>
</svg>

EOF

}

module_options+=(
	["generate_jobs_from_json,author"]="@Tearran"
	["generate_jobs_from_json,ref_link"]=""
	["generate_jobs_from_json,feature"]="generate_jobs_from_json"
	["generate_jobs_from_json,desc"]="Generate jobs from JSON file."
	["generate_jobs_from_json,example"]="generate_jobs_from_json"
	["generate_jobs_from_json,status"]="review"
	["generate_jobs_from_json,doc_link"]=""
)
#
# This function is used to generate jobs links Table from JSON file.
#
function see_jobs_from_json_md() {

	echo -e "\n"

	# Use jq to parse the JSON
	menu_items=$(jq -r '.menu | length' "$json_file")

	for ((i = 0; i < $menu_items; i++)); do
		cat=$(jq -r ".menu[$i].id" "$json_file")
		description=$(jq -r ".menu[$i].description" "$json_file")
		#echo -e "## $cat\n"
		#echo -e "$description\n"
		echo -e "| "$cat" | ID  | Description | Documents | Status |"
		echo -e "|:------ | :-- | :---------- | --------: | ------:|"

		sub_items=$(jq -r ".menu[$i].sub | length" "$json_file")

		for ((j = 0; j < $sub_items; j++)); do
			id=$(jq -r ".menu[$i].sub[$j].id" "$json_file")
			id_link=$(jq -r ".menu[$i].sub[$j].id" "$json_file" | tr '[:upper:]' '[:lower:]')
			description=$(jq -r ".menu[$i].sub[$j].description" "$json_file")
			command=$(jq -r ".menu[$i].sub[$j].command" "$json_file")
			status=$(jq -r ".menu[$i].sub[$j].status" "$json_file")
			doc_link=$(jq -r ".menu[$i].sub[$j].doc_link" "$json_file")

			# Check if src_reference and doc_link are null
			[ -z "$doc_link" ] && doc_link="#$id_link" || doc_link="[Document]($doc_link)"

			echo -e "| | $id | $description | $doc_link | $status |"

		done
		echo -e "\n"
	done

}



function see_full_list() {
	# Use jq to parse the JSON into markdown
		menu_items=$(echo "$json_data" | jq -r '.menu | length')

	for ((i = 0; i < menu_items; i++)); do
		cat=$(jq -r ".menu[$i].id" "$json_file")
		description=$(jq -r ".menu[$i].description" "$json_file")

		echo -e "- ## **$cat** \n"

		sub_items=$(jq -r ".menu[$i].sub | length" "$json_file")

		for ((j = 0; j < sub_items; j++)); do
			id=$(jq -r ".menu[$i].sub[$j].id" "$json_file")
			sub_description=$(jq -r ".menu[$i].sub[$j].description" "$json_file")

			echo -e "  - ### $sub_description"

			# Handle nested sub-items
			nested_sub_items=$(jq -r ".menu[$i].sub[$j].sub | length" "$json_file")

			# Check if nested sub-items are present
			if [ "$nested_sub_items" -gt 0 ]; then
				for ((k = 0; k < nested_sub_items; k++)); do
					nested_id=$(jq -r ".menu[$i].sub[$j].sub[$k].id" "$json_file")
					nested_description=$(jq -r ".menu[$i].sub[$j].sub[$k].description" "$json_file")

					echo -e "    - ### $nested_description"
				done
			fi

			echo -e "\n"
		done
		echo -e "\n"
	done
}

module_options+=(
	["see_function_table_md,author"]="@Tearran"
	["see_function_table_md,ref_link"]=""
	["see_function_table_md,feature"]="see_function_table_md"
	["see_function_table_md,desc"]="Generate this markdown table of all module_options"
	["see_function_table_md,example"]="see_function_table_md"
	["see_function_table_md,status"]="review"
	["see_function_table_md,doc_link"]=""
)
#
# This function is used to generate a markdown table from the module_options array
#
function see_function_table_md() {
	mod_message="| Description | Example | Credit |\n"
	mod_message+="|:----------- | ------- |:------:|\n"
	# Iterate over the options
	for key in "${!module_options[@]}"; do
		# Split the key into function_name and type
		IFS=',' read -r function_name type <<< "$key"
		# If the type is 'feature', append the option to the help message
		if [[ "$type" == "feature" ]]; then
			status=${module_options["$function_name,status"]}
			ref_link=${module_options["$function_name,ref_link"]}
			doc_link=${module_options["$function_name,doc_link"]}
			ref_link_md=$([[ -n "$ref_link" ]] && echo "[Source]($ref_link)" || echo "X")
			doc_link_md=$([[ -n "$doc_link" ]] && echo "[Document]($doc_link)" || echo "X")
			status_md=$([[ -z "$ref_link" ]] && echo "source link Needed" || ([[ (-n "$ref_link" && -n "$doc_link") ]] && echo "Review" || echo "$status"))
			mod_message+="| ${module_options["$function_name,desc"]} | ${module_options["$function_name,example"]} | ${module_options["$function_name,author"]} \n"
		fi
	done

	echo -e "$mod_message"
}

module_options+=(
	["see_jq_menu_list,author"]="@Tearran"
	["see_jq_menu_list,ref_link"]=""
	["see_jq_menu_list,feature"]="see_jq_menu_list"
	["see_jq_menu_list,desc"]="Generate a markdown list json objects using jq."
	["see_jq_menu_list,example"]="see_jq_menu_list"
	["see_jq_menu_list,status"]="review"
	["see_jq_menu_list,doc_link"]=""
)
#
# This function is used to generate a markdown list from the json object using jq.
#
function see_jq_menu_list() {
	jq -r '
	.menu[] |
	.sub[] |
	"### " + .id + "\n\n" +
	(.description // "No description available") + "\n\nJobs:\n\n~~~\n" +
	((.command // ["No commands available"]) | join("\n")) +
	"\n~~~\n"
' $json_file
}

module_options+=(
	["see_cmd_list,author"]="@Tearran"
	["see_cmd_list,ref_link"]=""
	["see_cmd_list,feature"]="see_cmd_list"
	["see_cmd_list,desc"]="Generate a Help message for cli commands."
	["see_cmd_list,example"]="see_cmd_list [category]"
	["see_cmd_list,status"]="review"
	["see_cmd_list,doc_link"]=""
)
#
# See command options
#
see_cmd_list() {
	local help_menu="$1"

	if [[ -n "$help_menu" && "$help_menu" != "cmd" ]]; then
		echo "$json_data" | jq -r --arg menu "$help_menu" '
		def recurse_menu(menu; level):
		menu | .id as $id | .description as $desc |
		if has("sub") then
			if level == 0 then
				"\n  \($id) - \($desc)\n" + (.sub | map(recurse_menu(. ; level + 1)) | join("\n"))
			elif level == 1 then
				"    \($id) - \($desc)\n" + (.sub | map(recurse_menu(. ; level + 1)) | join("\n"))
			else
				"      \($id) - \($desc)\n" + (.sub | map(recurse_menu(. ; level + 1)) | join("\n"))
			end
		else
			if level == 0 then
				"  --cmd \($id) - \($desc)"
			elif level == 1 then
				"    --cmd \($id) - \($desc)"
			else
				"\t--cmd \($id) - \($desc)"
			end
		end;

		# Find the correct menu if $menu is passed, otherwise show all
		if $menu == "" then
			.menu | map(recurse_menu(. ; 0)) | join("\n")
		else
			.menu | map(select(.id == $menu) | recurse_menu(. ; 0)) | join("\n")
		end
		'
	elif [[ -z "$1" || "$1" == "cmd" ]]; then
		echo "$json_data" | jq -r --arg menu "$help_menu" '
		def recurse_menu(menu; level):
		menu | .id as $id | .description as $desc |
		if has("sub") then
			if level == 0 then
				"\n  \($id) - \($desc)\n" + (.sub | map(recurse_menu(. ; level + 1)) | join("\n"))
			elif level == 1 then
				"    \($id) - \($desc)\n" + (.sub | map(recurse_menu(. ; level + 1)) | join("\n"))
			else
				"      \($id) - \($desc)\n" + (.sub | map(recurse_menu(. ; level + 1)) | join("\n"))
			end
		else
			if level == 0 then
				"  --cmd \($id) - \($desc)"
			elif level == 1 then
				"    --cmd \($id) - \($desc)"
			else
				"\t--cmd \($id) - \($desc)"
			end
		end;
		.menu | map(recurse_menu(. ; 0)) | join("\n")
		'

	else
		echo "nope"
	fi
}


module_options+=(
	["see_cli_legacy,author"]="@Tearran"
	["see_cli_legacy,ref_link"]=""
	["see_cli_legacy,feature"]="see_cli_legacy"
	["see_cli_legacy,desc"]="Generate a Help message legacy cli commands."
	["see_cli_legacy,example"]="see_cli_legacy"
	["see_cli_legacy,status"]="review"
	["see_cli_legacy,doc_link"]=""
)
function see_cli_legacy() {
	local script_name=$(basename "$0")
	cat << EOF
Legacy Options (Backward Compatible)
Please use 'armbian-config --help' for more information.

Usage:  $script_name main=[arguments] selection=[options]

EOF

cat << EOF
	$script_name main=System selection=Headers          -  Install headers:
	$script_name main=System selection=Headers_remove   -  Remove headers:
EOF

	# TODO Migrate following features

	# $script_name main=System   selection=Firmware         -  Update, upgrade and reboot:
	# $script_name main=System   selection=Nightly          -  Switch to nightly builds:
	# $script_name main=System   selection=Stable           -  Switch to stable builds:
	# $script_name main=System   selection=Default          -  Install default desktop:
	# $script_name main=System   selection=ZSH              -  Change to ZSH:
	# $script_name main=System   selection=BASH             -  Change to BASH:
	# $script_name main=System   selection=Stable           -  Change to stable repository [branch=dev]:
	# $script_name main=System   selection=Nightly          -  Change to nightly repository [branch=dev]:
	# $script_name main=Software selection=Source_install   -  Install kernel source:
	# $script_name main=Software selection=Source_remove    -  Remove kernel source:
	# $script_name main=Software selection=Avahi            -  Install Avahi mDNS/DNS-SD daemon:

}
