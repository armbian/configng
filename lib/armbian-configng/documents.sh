#!/bin/bash

# This function is used to generate a simple JSON file containing all functions and their descriptions.
# pthon is more suited to complex arrays this should be handeled during build time
generate_json() {
    json_objects=()
    for key in "${!functions[@]}"; do
        if [[ $key == *",function_name"* ]]; then
            function_key="${key%,function_name}"
            function_name="${functions[$key]}"
            group_name="${functions["$function_key,group_name"]}"
            description="${functions["$function_key,description"]}"
            options="${functions["$function_key,options"]}"
            category="${functions["$function_key,category"]}"
            category_description="${functions["$function_key,category_description"]}"
            toggle="${functions["$function_key,toggle"]}"
            json_objects+=("{ \"Category Description\": \"$category_description\", \"Category\": \"$category\", \"Group\": \"$group_name\", \"Function\": \"$function_name\",\"Group Description\": \"$description\", \"Options\": \"$options\", \"Toggle\": \"$toggle\" }")
        fi
    done
    IFS=','
    echo "[${json_objects[*]}]" | jq
}

generate_keypairs() {

# Define the output file
output_file="keypairs.sh"

# Define the key-value pairs
declare -A keypairs=(
    ["KEY1"]="VALUE1"
    ["KEY2"]="VALUE2"
    ["KEY3"]="VALUE3"
)

# Write the key-value pairs to the output file
echo "#!/bin/bash" > $output_file
for key in "${!keypairs[@]}"; do
    echo "export $key=${keypairs[$key]}" >> $output_file
done

# Make the output file executable
chmod +x $output_file

}

# This function is used to generate a armbian CPU logo
generate_svg(){

cat << EOF
<svg version="1.1" viewBox="0 0 300 300" xmlns="http://www.w3.org/2000/svg">
	<g transform="translate(-490 -250)">
		<path d="m531.27 266.49c-18.24 0-24.775 6.5634-24.775 24.775-2.7972 0-17.438-1.6276-14.991 4.3366 1.5539 3.7891 11.675 2.0864 14.991 2.0864v7.3409h-15.599c0.28666 8.7296 8.9244 6.423 15.599 6.423v6.4229h-15.599c0.28668 8.6209 9.0411 6.4229 15.599 6.4229v6.4229c-3.6404 0-11.14-1.425-14.127 0.94235-7.9785 6.3216 11.963 6.3985 14.127 6.3985v6.4229h-15.599v5.5055h15.599v7.3409c-6.6746 0-15.313-2.3064-15.599 6.4229 6.4474 0 14.957-1.9998 15.599 6.423-6.5579 0-15.313-2.1978-15.599 6.4229 6.4474 0 14.957-1.9999 15.599 6.4229-2.1649 0-22.106 0.0767-14.127 6.3985 2.988 2.3673 10.486 0.94233 14.127 0.94233-0.3013 9.2518-8.4634 7.3409-15.599 7.3409v5.5055h15.599v7.3408h-15.599c0.28666 8.7296 8.9244 6.423 15.599 6.423v6.4229h-15.599c0.28666 8.7296 8.9244 6.423 15.599 6.423v6.4229h-15.599v6.423h15.599v7.3408h-15.599v5.5055c7.1357 0 15.298-1.9116 15.599 7.3409-6.6746 0-15.313-2.3064-15.599 6.4229l15.599 0.9176v5.5055c-6.5579 0-15.313-2.1978-15.599 6.4229h15.599v7.3409h-15.599c0.28666 8.7296 8.9244 6.423 15.599 6.423v7.3408h-15.599c0.60794 7.8026 9.6604 5.5055 15.599 5.5055 0 18.486 6.2886 24.775 24.775 24.775 0 2.7972-1.6276 17.438 4.3366 14.991 3.789-1.5539 2.0865-11.675 2.0865-14.991 9.2518 0.30131 7.3409 8.4634 7.3409 15.599 8.7296-0.28665 6.4229-8.9244 6.4229-15.599h6.4229v15.599c8.7296-0.28665 6.423-8.9244 6.423-15.599h6.4229c0 3.6404-1.4249 11.14 0.94234 14.127 6.3216 7.9784 6.3985-11.963 6.3985-14.127h6.4229v15.599h5.5055v-15.599h7.3408c0 3.6404-1.4249 11.14 0.94236 14.127 6.3216 7.9784 6.3985-11.963 6.3985-14.127h6.4229v15.599c8.6209-0.28668 6.423-9.0411 6.423-15.599h6.4229v15.599c8.7296-0.28665 6.423-8.9244 6.423-15.599h6.4229c0 2.9095-1.7644 17.416 4.3139 14.991 3.8146-1.5216 2.1092-11.679 2.1092-14.991h7.3408c0 2.9095-1.7644 17.416 4.314 14.991 3.8146-1.5217 2.1092-11.679 2.1092-14.991h6.423v15.599h6.4229v-15.599h6.4229c0 2.1648 0.0767 22.106 6.3985 14.127 2.3674-2.988 0.94236-10.486 0.94236-14.127h6.4229v15.599c8.6209-0.28668 6.423-9.0411 6.423-15.599h6.4229c0 2.1648 0.077 22.106 6.3985 14.127 2.3674-2.988 0.94237-10.486 0.94237-14.127 8.423 0.64261 6.4229 9.1516 6.4229 15.599 8.6209-0.28668 6.423-9.0411 6.423-15.599h6.4229v15.599h6.423v-15.599h7.3408v15.599c7.8026-0.60793 5.5055-9.6604 5.5055-15.599 18.486 0 24.775-6.2886 24.775-24.775 5.9389 0 14.991 2.2972 15.599-5.5055-7.1356 0-15.298 1.9116-15.599-7.3408 6.6746 0 15.313 2.3064 15.599-6.423-7.1356 0-15.298 1.9116-15.599-7.3409h15.599c-0.28665-8.6209-9.0417-6.4229-15.599-6.4229v-5.5055l15.599-0.9176c-0.28655-8.7296-8.9244-6.4229-15.599-6.4229 0.30124-9.2518 8.4633-7.3409 15.599-7.3409v-5.5055h-15.599v-7.3408h15.599c-0.28655-8.7296-8.9244-6.423-15.599-6.423v-6.4229c6.6746 0 15.313 2.3064 15.599-6.423h-15.599v-6.4229c6.6746 0 15.313 2.3064 15.599-6.423h-15.599v-7.3408h15.599v-5.5055c-7.1356 0-15.298 1.9116-15.599-7.3409 3.6404 0 11.14 1.4249 14.127-0.94233 7.9784-6.3216-11.963-6.3985-14.127-6.3985 0.64246-8.423 9.1516-6.4229 15.599-6.4229-0.28655-8.7296-8.9244-6.4229-15.599-6.4229 0.64259-8.4231 9.1516-6.423 15.599-6.423v-6.4229h-15.599v-7.3409h15.599v-5.5055h-15.599v-6.4229c2.1647 0 22.106-0.0771 14.127-6.3985-2.988-2.3674-10.486-0.94235-14.127-0.94235v-6.4229c6.6746 0 15.313 2.3064 15.599-6.4229-6.4474 0-14.957 1.9998-15.599-6.4229 6.6746 0 15.313 2.3064 15.599-6.423-7.1356 0-15.298 1.9116-15.599-7.3409 2.9095 0 17.416 1.7644 14.991-4.3139-1.5217-3.8146-11.679-2.1092-14.991-2.1092 0-18.218-6.4413-24.775-24.775-24.775v-15.599c-7.8026 0.60791-5.5055 9.6604-5.5055 15.599h-7.3408c0-2.9095 1.7644-17.417-4.314-14.991-3.8146 1.5217-2.1092 11.679-2.1092 14.991h-6.4229c0-6.6746 2.3064-15.313-6.423-15.599v15.599h-6.4229c0-3.596 1.5526-12.144-1.5951-14.652-6.8474-5.4551-5.7455 12.046-5.7455 14.652h-6.4229c0-2.7971 1.6276-17.438-4.3366-14.991-3.7891 1.5539-2.0865 11.675-2.0865 14.991h-6.4229c0-2.1648-0.0769-22.106-6.3985-14.127-2.3672 2.9878-0.94232 10.486-0.94232 14.127h-6.423c0-3.3122 1.7055-13.47-2.1092-14.991-6.0784-2.4247-4.3139 12.082-4.3139 14.991h-6.423c0-6.6746 2.3064-15.313-6.4229-15.599v15.599h-7.3408c0-3.3122 1.7054-13.47-2.1092-14.991-6.0784-2.4247-4.314 12.082-4.314 14.991h-6.4229c0-3.3122 1.7054-13.47-2.1092-14.991-6.0784-2.4247-4.314 12.082-4.314 14.991h-6.423c0-6.5579 2.1978-15.313-6.4229-15.599v15.599h-6.4229c0-2.6541 1.038-19.691-5.8702-14.638-3.0623 2.2398-1.4705 11.253-1.4705 14.638h-7.3408c0-2.8517 1.6823-15.015-2.7528-15.015-4.435 0-2.7528 12.164-2.7528 15.015h-6.4229c0-3.596 1.5526-12.144-1.5951-14.652-6.8474-5.4551-5.7456 12.046-5.7456 14.652h-6.4229c0-6.5579 2.1978-15.313-6.4229-15.599v15.599h-6.4229c0-2.9095 1.7644-17.417-4.314-14.991-3.8145 1.5217-2.1092 11.679-2.1092 14.991h-7.3409c0-3.0107 1.7488-15.887-3.5606-15.172-4.6127 0.62178-2.8625 11.954-2.8625 15.172zm115.49 140.65c-0.5047-0.16836-2.0979-0.56777-3.5404-0.88755l-2.6228-0.58152 0.59477-18.539c0.32711-10.196 0.24693-21.508-0.17822-25.137-0.74355-6.3472-0.69577-6.6178 1.2546-7.1076 1.1152-0.27988 2.6841-0.76082 3.4867-1.0688 1.3039-0.50035 1.3956 0.62178 0.86184 10.548-0.43689 8.1256-0.31302 11.108 0.46131 11.108 0.58225 0 1.0586-0.65115 1.0586-1.4469 0-2.5955 5.1051-6.8114 8.2478-6.8114 4.3109 0 6.3961 1.5301 8.5488 6.2721 2.4632 5.4269 2.592 17.07 0.25032 22.631-3.4321 8.1513-11.877 13.202-18.424 11.019zm10.172-5.4807c4.149-2.7186 5.7466-18.431 2.5411-24.993-1.3399-2.7429-2.2945-3.5429-4.484-3.7574-4.767-0.46712-6.8914 2.8352-7.9564 12.366-1.0133 9.0729-0.45363 16.736 1.3083 17.913 1.481 0.98906 5.9661 0.19091 8.591-1.5288zm-117.88 0.7066c-1.8883-3.7766-1.394-6.5243-0.15968-11.108 1.6742-6.2177 6.8883-9.3593 15.534-9.3593h4.0267l-0.50923-3.7966c-0.28008-2.0882-1.1596-4.4469-1.9544-5.2418-1.8146-1.8146-7.6847-1.6732-11.454 0.27594-2.6304 1.3603-2.8228 1.3338-3.8176-0.52477-1.2429-2.3224-0.44211-3.0404 5.0996-4.5722 4.8229-1.3331 11.951-0.59052 14.243 1.484 2.8979 2.6227 3.6171 7.256 3.5247 22.71l-0.0863 14.44h-2.6434c-2.4006 0-2.6434-0.28997-2.6434-3.1574 0-1.7365-0.41291-3.4126-0.91763-3.7245-0.50466-0.31187-0.9176-0.0223-0.9176 0.64341 0 0.66581-1.049 2.3418-2.3311 3.7245-1.8556 2.0013-3.1491 2.514-6.3417 2.514-3.3078 0-7.1302-1.2651-8.6515-4.3074zm16.004-3.4837c1.866-2.4465 2.4732-4.3431 2.57-8.0292 0.12551-4.7725 0.095-4.8288-2.7622-5.1063-8.7803-0.85274-14.459 7.529-9.432 13.921 2.8094 3.5715 6.5323 3.2677 9.6237-0.78545zm15.825-11.249c-0.15507-10.471-0.28188-19.084-0.28188-19.137 0-0.0532 1.342-0.35304 2.9822-0.66526l2.9821-0.56767v4.565c0 2.5107 0.41292 4.565 0.9176 4.565s0.91761-0.67387 0.91761-1.4974c0-1.9538 6.0872-7.6786 8.1647-7.6786 1.2679 0 1.525 0.58604 1.2069 2.7527-0.31162 2.1233-0.87613 2.7528-2.4686 2.7528-2.5046 0-6.6917 3.9917-7.6096 7.2547-0.36828 1.3088-0.66959 7.8502-0.66959 14.536v12.157l-5.8594 2e-3zm20.822 1.8356c0-9.4631-0.33749-18.134-0.75001-19.269-0.62855-1.7302-0.43303-2.0646 1.2073-2.0646 1.0765 0 2.7561-0.42742 3.7322-0.94991 1.6209-0.86741 1.7749-0.62286 1.7749 2.8181v3.768l3.0906-3.2769c2.5321-2.6848 3.7466-3.2769 6.7222-3.2769 3.6404 0 7.6218 2.7869 7.6218 5.3352 0 1.6218 0.43336 1.3886 3.9456-2.1236 2.626-2.626 3.8976-3.2115 6.9738-3.2115 2.5387 0 4.3589 0.59679 5.5972 1.8351 1.6706 1.6706 1.8351 3.0586 1.8351 15.471 0 7.4996 0.26257 15.551 0.58351 17.893l0.58353 4.2572h-6.6727v-15.992c0-13.315-0.24141-16.234-1.4419-17.434-1.9467-1.9467-5.2323-1.8167-7.8618 0.31102-2.1237 1.7184-2.1662 2.0609-2.1662 17.432v15.68l-6.426 3e-3 2e-3 -15.5c1e-3 -13.955-0.17279-15.692-1.7465-17.434-2.3459-2.5957-5.2577-2.438-7.9558 0.43105-2.1392 2.2745-2.2357 2.9434-2.5157 17.434l-0.29153 15.069-5.8408 6e-4zm82.881 0.30382c0.191-10.716-0.0541-17.566-0.66972-18.717-0.82246-1.5368-0.63594-1.8983 1.2193-2.364 1.2046-0.30236 2.7448-0.76248 3.4225-1.0226 1.0077-0.38669 1.2322 3.1235 1.2322 19.266v19.738l-5.5055 2e-3zm14.811 14.577c-1.7094-1.8194-2.2525-3.5614-2.5037-8.0292-0.54565-9.7043 4.215-14.423 14.551-14.423h4.7382l-0.50926-3.7966c-0.28005-2.0882-1.121-4.4084-1.8688-5.1561-1.7466-1.7467-7.9351-1.6737-11.432 0.13455-2.573 1.3306-2.7362 1.2959-3.6827-0.78154-0.91377-2.0055-0.70904-2.2864 2.6434-3.6278 1.9987-0.79967 5.8901-1.454 8.6478-1.454 4.2417 0 5.475 0.41197 8.0102 2.6755l2.9967 2.6755 0.57231 34.105h-2.8094c-2.689 0-2.8108-0.16727-2.8386-3.8998-0.0274-3.6777-0.1081-3.7952-1.4133-2.0646-4.0451 5.3633-4.9463 5.9643-8.944 5.9643-3.0674 0-4.4738-0.53067-6.1579-2.3236zm13.196-5.0214c2.3332-2.7729 4.0332-9.7349 3.0212-12.372-0.63441-1.6533-4.6117-1.8095-8.8103-0.34588-2.0256 0.70616-3.4 2.0268-4.266 4.0997-1.6716 4.0006-1.6165 4.8438 0.54742 8.3931 2.4465 4.0125 6.2452 4.1023 9.5083 0.22503zm15.736-11.457v-18.8l2.6603-0.92693c1.4632-0.50983 2.8052-0.92696 2.9822-0.92696 0.17698 0 0.32187 1.5258 0.32187 3.3908v3.3908l3.1059-3.3908c2.7107-2.9595 3.6381-3.3908 7.2896-3.3908 3.0984 0 4.8507 0.57382 6.7552 2.2122l2.5719 2.2122 0.66196 35.032h-6.2312l0.34952-14.452c0.21707-8.9794-0.0238-15.413-0.63719-16.992-1.9642-5.0566-8.4585-5.0929-11.753-0.0657-1.4169 2.162-1.6537 4.5983-1.6537 17.016v14.492l-6.423-3.2e-4zm-44.044-27.078c-0.94906-2.9902 0.32893-5.5055 2.7971-5.5055 1.6001 0 2.3753 0.63983 2.7934 2.3059 1.0568 4.2109-4.297 7.2749-5.5905 3.1996z" style="fill:none;stroke:#ff0000"/>
	</g>
</svg>
EOF
}

# This function is used to generate a lightbulb SVG for use as web darkmode toggle.
generate_darkmode_svg(){

cat << EOF
<svg version="1.1" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
	<path d="m12.099 2.0342c-0.26941 8.915e-4 -0.53726 0.041372-0.99805 0.12305-2.3225 0.41166-3.9876 1.7713-4.6875 3.8262-0.18094 0.53122-0.23176 0.92741-0.23047 1.8008 0.00214 1.4561 0.27595 2.3199 1.3711 4.3203 1.4741 2.6926 1.7428 3.3185 1.7441 4.0605 3.27e-4 0.18089 0.019628 0.40039 0.019628 0.40039l1.9582 0.32763 0.04756-0.55028c-0.0067-1.0626-0.57099-2.5212-1.8886-4.8789-1.0362-1.8541-1.257-2.5121-1.252-3.7344 0.00316-0.76232 0.054727-1.0687 0.24609-1.4922 0.3285-0.72699 1.0874-1.4689 1.873-1.832 1.0231-0.47285 2.7726-0.4069 3.6074-0.015625 0.81398 0.38151 1.6006 1.1344 1.9062 1.8242 0.19601 0.44241 0.24791 0.75194 0.25195 1.5156 0.0065 1.222-0.21282 1.8784-1.25 3.7344-1.3194 2.3609-1.8821 3.8181-1.8887 4.8848l-0.05111 0.81246 1.9454 0.3255 0.15252-1.513c0.09428-0.75711 0.35511-1.3832 1.2637-3.0176 1.5928-2.8653 1.8263-3.5211 1.8301-5.1719 2e-3 -0.87515-0.04917-1.2685-0.23047-1.8008-0.69474-2.0399-2.4229-3.4381-4.7382-3.832-0.46214-0.078621-0.73254-0.11808-1.002-0.11719z" style="fill:#ffd700"/>
	<path d="m9.3178 16.565 0.1895 1.2545 5.2108 0.79484 0.10528-1.1281zm0.73199 3.9552 0.56879 0.89834c0.32405 0.227 0.65465 0.44121 0.73633 0.47656 0.08168 0.03534 0.48582 0.05091 0.89648 0.03516 0.68461-0.02625 0.79838-0.06547 1.377-0.47656l0.63086-0.44922s-4.1661-0.45254-4.2094-0.48428zm-0.48863-1.9978 0.1895 1.2124 4.7265 0.47901 0.23161-1.0229z" style="fill:#000000"/>
</svg>

EOF
}

# This function is used to generate a CSV file containing all functions and their descriptions.
generate_csv() {
    echo "Function Name,Group Name,Description,Options,Category,Category Description"
    for key in "${!functions[@]}"; do
        if [[ $key == *",function_name"* ]]; then
            function_key="${key%,function_name}"
            function_name="${functions[$key]}"
            group_name="${functions["$function_key,group_name"]}"
            description="${functions["$function_key,description"]}"
            options="${functions["$function_key,options"]}"
            category="${functions["$function_key,category"]}"
            category_description="${functions["$function_key,category_description"]}"
            echo "$function_name,$group_name,$description,$options,$category,$category_description"
        fi
    done
}

# This function is used to generate a Single page app.
generate_html5() {
  cat << EOF
<!doctypehtml>
<html lang=en>
<meta content="no-cache, no-store, must-revalidate" http-equiv=Cache-Control>
<meta content=no-cache http-equiv=Pragma>
<meta content=0 http-equiv=Expires>
<meta content="A single-page web app for Armbian configuration" name=description>
<meta content="The Traveling aspie" name=author>
<meta content="width=device-width,initial-scale=1" name=viewport>
<title>armbian-configng</title>
<style>

	* {
		box-sizing: border-box
	}
    html {
    width: 100%;
    height: 100%;
    }

    body {
    font-family: Arial, sans-serif;
    background-color: #222;
    color: #fff;
    margin: 0;
    padding: 0;
    display: flex;
    flex-direction: column;
    min-height: 100vh;
    }

body::-webkit-scrollbar {
    width: 12px;  /* Width of the scrollbar */
}

body::-webkit-scrollbar-track {
    background: #222;  /* Color of the track */
}

body::-webkit-scrollbar-thumb {
    background-color: #888;  /* Color of the scroll thumb */
    border-radius: 20px;  /* Radius of the scroll thumb */
    border: 3px solid #222;  /* Creates padding around scroll thumb */
}
footer {
    background-color: #333;
    color: #fff;
    text-align: center;
    padding: 10px;
    width: 100%;
    margin-top: auto;
}

    #welcome {
		text-align: center;
		padding: 50px;
		overflow: hidden
	}

	.content, .content iframe {
        margin-top: 20px; 
		width: 100%;
        height: 85vh;
		transition: all 1s ease
	}

	nav ul {
		list-style-type: none;
		margin: 0;
		padding: 0;
		overflow: hidden;
		background-color: #333
	}

	nav ul li {
		float: left
	}

	nav ul li a {
		display: block;
		padding: 10px;
		color: #fff;
		text-decoration: none
	}

	.logo-main {
		width: 300px;
		height: 300px;
		fill: #000
	}

	.dark-mode {
		background-color: #222;
		color: #fff
	}

	.light-mode {
		background-color: #e0e0e0;
		color: #222
	}

	body a {
		color: #00ff26
	}

	.top-right {
		position: absolute;
		top: 0;
		right: 0;
		padding: 10px;
		padding: 10px;
		z-index: 1;
		color: #fff
	}

	.menu {
		display: flex;
		align-items: center;
		justify-content: space-between;
		position: fixed;
		top: 0;
		left: 0;
		width: 100%;
		background-color: #333;
		padding: 10px;
		z-index: 1;
		color: #fff
	}

	.menu ul {
		list-style-type: none;
		padding: 0;
		margin: 0;
		display: block
	}

	.menu li {
		display: inline-block;
		margin-right: 10px
	}

	.menu li a {
		color: #fff;
		text-decoration: none
	}

	.menu li a:hover {
		color: #ccc
	}

	.menu-toggle {
		cursor: pointer;
		font-size: 24px
	}

	.menu-toggle.active+ul {
		display: block
	}

	.menu-toggle+ul {
		display: none;
		position: absolute;
		min-width: 160px;
		z-index: 1
	}

	.menu-toggle.active+ul {
		display: block
	}

	.menu-toggle+ul li {
		display: block
	}

	.menu-container {
		position: relative
	}

	.dropdown {
		display: none;
		position: absolute;
		background-color: #333;
		padding: 10px;
		min-width: 160px;
		box-shadow: 0 8px 16px 0 rgba(0, 0, 0, .2);
		z-index: 1
	}

	.dropdown li {
		display: block;
		padding: 5px 10px
	}

	.icon {
		width: 24px;
		height: 24px;
		fill: #fff
	}

	body.dark-mode .icon {
		fill: #000
	}



</style>
<div class=menu>
	<div class=menu-container>
		<nav>
			<div class=menu-toggle onclick=toggleMenu()>MENU</div>
			<ul class=dropdown id=menu-list></ul>
		</nav>
	</div>
	<div class=top-right><span id=time></span> <a href=# class="button-style icon" onclick=toggleDarkMode()><img alt="Toggle Dark Mode" height=24px src=imgs/darkmode.svg width=24px></a></div>
</div>
<section class=container>
	<div class=page>
		<div class=content id=welcome>
			<h1>Welcome</h1>
			<p><img alt="Armbian Logo" height=300px src=imgs/armbian-cpu.svg width=300px class=logo-main>
			<p>ARM Linux for Single board computor development
		</div>
		<div class=content id=about style=display:none>
				<h1>About</h1>
             	<h1>About</h1>
                <p>This is a single-page web application designed and tested on a <a href="https://www.khadas.com/vim3" target="_blank">Khadas VIM3</a> board running <a href="https://www.armbian.com/" target="_blank">Armbian</a>.</p>
            
                <h2>Why</h2>
                <p>Part of the reason for creating this project was to learn more about 
				<a href="https://www.armbian.com/" target="_blank">Armbian</a> and Document alonge the way.</p>
			
				<h2>How</h2>
				<p>THis app is part of a larger project called <a href="https://github.com/Tearran/configng" target="_blank">configng</a> which is a collection of bash scripts that can be used to configure Armbian.</p>
				<p>This project is written in <a href="https://www.gnu.org/software/bash/" target="_blank">Bash</a> and uses the following libraries:</p>
				<ul>
					<li>GNU Bash</li>
					<li>sed</li>
					<li>awk</li>
					<li>grep</li>
					<li>wget</li>
					<li>jq</li>
					<li>dialog</li>
					<li>git</li>
					<li>apt</li>
					<li>dpkg</li>
					<li>apt-cache</li>

				<ul>
            
            </div>
	</div>
</section>
<footer>
	<p>    <p>&copy; 2022 The Traveling Aspie. All rights reserved. | Armbian &copy; 2022 Armbian authors. All rights reserved.</p>
</footer>
<script>
	fetch("data/armbian-configng.json")
		.then(response => response.json())
		.then(data => {
			var menu = document.querySelector("nav ul");
			var pages = document.querySelector(".page");
			var menuItems = [];
			var pageItems = [];
			// Add Home menu item
			menuItems.push("<li><a href=\"#welcome\">Home</a></li>");
			// Add Table menu item
			menuItems.push("<li><a href=\"#table\">Table</a></li>");
			pageItems.push("<div class=\"content\" id=\"table\" style=\"display: none;\"><iframe src='./table.html' style='width:100%; height:100%; border:none;'></iframe></div>");
			// Add About menu item
			menuItems.push("<li><a href=\"#about\">About</a></li>");
			pageItems.push("<div class=\"content\" id=\"about\" style=\"display: none;\"><h2>About</h2><p>Some information about this website...</p></div>");
			menu.innerHTML = menuItems.join("");
			pages.innerHTML += pageItems.join(""); // Use += to append the new pages without removing the welcome page
			// Add event listeners to menu items
			var menuLinks = menu.querySelectorAll("li a");
			var pageContents = pages.querySelectorAll(".content");
			var menuToggle = document.querySelector(".menu-toggle"); // Get the menu toggle
			for (var i = 0; i < menuLinks.length; i++) {
				menuLinks[i].addEventListener("click", function(e) {
					e.preventDefault();
					// Hide all pages
					for (var j = 0; j < pageContents.length; j++) {
						pageContents[j].style.display = "none";
					}
					// Show selected page
					var targetPage = document.querySelector(this.getAttribute("href"));
					if (targetPage) {
						targetPage.style.display = "block";
					}
					// Close the menu
					menuToggle.classList.remove("active");
				});
			}
		})
		.catch(error => console.error("Error:", error));

	function toggleMenu() {
		const menuToggle = document.querySelector(".menu-toggle");
		const menu = document.querySelector(".menu");
		menuToggle.classList.toggle("active");
		menu.classList.toggle("active");
	}

	function toggleDarkMode() {
		const body = document.body;
		body.classList.toggle("dark-mode");
		body.classList.toggle("light-mode");
	}

	function updateTime() {
		const now = new Date();
		const timeString = now.toLocaleTimeString();
		document.getElementById('time').textContent = timeString;
	}
	// Update the time every second
	setInterval(updateTime, 1000);
</script>

</body>
</html>

EOF

}

# This function is used to generate tabe html file
# used to check proper array generation and output.
generate_html() {
  cat << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Dynamic Table</title>
    <style>
        body {
            background-color: #333;
            color: #fff;
            font-family: Arial, sans-serif;
        }
        table {
            border-collapse: collapse;
            width: 100%;
        }
        th, td {
            text-align: left;
            padding: 8px;
        }
        th {
            background-color: #4CAF50;
            color: white;
        }
        tr:nth-child(even) {color: black; background-color: #f2f2f2; }
    </style>
</head>
<body>
    <table id="dynamicTable">
        <!-- Table data will be inserted here -->
    </table>

    <script>
        // Fetch JSON data
        fetch('data/armbian-configng.json') // Corrected filename here
            .then(response => response.json())
            .then(data => {
                // Get table element
                var table = document.getElementById('dynamicTable');

                // Create table header
                var thead = document.createElement('thead');
                var headerRow = document.createElement('tr');
                Object.keys(data[0]).forEach(function(key) {
                    var th = document.createElement('th');
                    th.textContent = key;
                    headerRow.appendChild(th);
                });
                thead.appendChild(headerRow);
                table.appendChild(thead);

                // Create table body
                var tbody = document.createElement('tbody');
                data.forEach(function(item) {
                    var row = document.createElement('tr');
                    Object.values(item).forEach(function(value) {
                        var td = document.createElement('td');
                        td.textContent = value;
                        row.appendChild(td);
                    });
                    tbody.appendChild(row);
                });
                table.appendChild(tbody);
            })
            .catch(error => console.error('Error:', error));
    </script>
</body>
</html>
EOF
}

# This function is used to generate the main readme.md file
generate_markdown() {
cat << EOF

<p align="center">
    <img src="https://raw.githubusercontent.com/armbian/build/main/.github/armbian-logo.png" alt="Armbian logo" width="144">
    <br>
    Armbian ConfigNG
    <br>
    <a href="https://www.codefactor.io/repository/github/tearran/configng"><img src="https://www.codefactor.io/repository/github/tearran/configng/badge" alt="CodeFactor" /></a>
</p>

# User guide
## Quick start
Run the following commands:

    sudo apt install git
    cd ~/
    git clone https://github.com/armbian/configng.git
    cd configng
    ./bin/${file_name%.*} --dev

If all goes well you should see the Text-Based User Inerface (TUI)

### To see a list of all functions and their descriptions, run the following command:
~~~
bash ~/configng/bin/armbian-configng -h
~~~
## Coding Style
follow the following coding style:
~~~
# @description A short description of the function.
#
# @exitcode 0  If successful.
#
# @options A description if there are options.
function group::string() {s
    echo "hello world"
    return 0
}
~~~
## Codestyle can be used to auto generate
 - [Markdown](share/${file_name%.*}/readme.md)
 - [JSON](share/${file_name%.*}/data/${file_name%.*}.json)
 - [CSV](share/${file_name%.*}/data/${file_name%.*}.csv)
 - [HTML](share/${file_name%.*}/${file_name%.*}-table.html)
 - [github.io](//tearran/github.io/${file_name%.*}/index.html)
## Functions list as of $(date +%Y-%m-%d)
EOF

    for category in "${categories[@]}"; do
        echo "## ${category##*/}"
		echo "${functions["$key,category_description"]}"
        echo

        for file in "$category"/*.sh; do
            echo "### ${file##*/}"
            echo

            mapfile -t functions_in_file < <(grep -oP '(?<=function\s)\w+::\w+' "$file")

            for function in "${functions_in_file[@]}"; do
                key="${category##*/}:${file##*/}:${function}"
                echo " - **Group Name:** ${functions["$key,group_name"]}"
                echo " - **Action Name:** ${functions["$key,function_name"]}"
                echo " - **Options:** ${functions["$key,options"]}"
                echo " - **Description:** ${functions["$key,description"]}"
                echo
            done
        done
    done
cat << EOF

# Inclueded projects
- [Bash Utility](https://labbots.github.io/bash-utility)
- [Armbian config](https://github.com/armbian/config.git)

EOF
}


# This function is used to generate a extention to help meassage of all functions and their descriptions.
generate_list_run() {
    echo "Usage: ${filename%.*} [--run] [option] [action]"
    # Loop through each category
    for category in "${categories[@]}"; do
        # Initialize an empty array to store the group names that have been printed
        declare -A printed_groups

        # Loop through each file in the category
        for file in "$category"/*.sh; do

            # Extract functions from the file
            mapfile -t functions_in_file < <(grep -oP '(?<=function\s)\w+::\w+' "$file")

            # Loop through each function in the file
            for function in "${functions_in_file[@]}"; do
                key="${category##*/}:${file##*/}:${function}"
                group_name=${functions["$key,group_name"]}

                # If the group name has not been printed yet, print it and add it to the array
                declare -A printed_groups
                if [[ -z ${printed_groups["$group_name"]} ]]; then
                    echo "        $group_name,    [action]"
                    printed_groups["$group_name"]=1
                fi

                echo "               ${functions["$key,function_name"]} - ${functions["$key,description"]}"
				echo
            done
        done
    done

}

# This function is used to generate a no flag options help message
generate_list_cli() {

    echo "Usage: ${filename%.*} [group]=[function]"
    # Loop through each category
    for category in "${categories[@]}"; do
        # Initialize an empty array to store the group names that have been printed
        declare -A printed_groups

        # Loop through each file in the category
        for file in "$category"/*.sh; do

            # Extract functions from the file
            mapfile -t functions_in_file < <(grep -oP '(?<=function\s)\w+::\w+' "$file")

            # Loop through each function in the file
            for function in "${functions_in_file[@]}"; do
                key="${category##*/}:${file##*/}:${function}"
                group_name=${functions["$key,group_name"]}
                printf "\t%-20s - \t %s \n" "$group_name=${functions["$key,function_name"]}" "${functions["$key,description"]}"
            done
        done
    done
}


# This function is used to generate a help message.


# THis function is used to make documents
generate_and_print() {
    local generate_func=$1
    local filename=$2
    local file_extension=$3
    local output_message=$4

    "$generate_func" > "$filename.$file_extension" && chmod 755 "$filename.$file_extension"
    echo "$output_message - generated $filename.$file_extension"
}

# This function is used to check for a command-line or X browser
serve_and_open_html() {
    generate_web
    serve_web_open
}

generate_web() {
    # The HTML file to open
    local dir="$(dirname "$(dirname "$(realpath "$0")")")/share"

    if [[ ! -d "$dir/${filename%-dev}/web" ]]; then
        mkdir -p "$dir/${filename}/web/data"
        mkdir -p "$dir/${filename}/web/imgs"
    fi

    web="${filename%-dev}/web"

        generate_darkmode_svg > "$dir/$web/imgs/darkmode.svg"
    generate_svg > "$dir/$web/imgs/armbian-cpu.svg"
    generate_and_print generate_html "$dir/$web/table" html "Table"
    generate_and_print generate_html5 "$dir/$web/index" html "HTML"
    generate_and_print generate_json "$dir/$web/data/$filename" json "JSON"
    generate_and_print generate_csv "$dir/$web/data/${filename%-dev}" csv "CSV"
    cd "$dir/$web" || exit
}

serve_web_open() {
	local html_file="table.html"

    # Determine the command-line browser to use
    local browser_cmd
    if command -v links2 &> /dev/null; then
        browser_cmd="links2"
    elif command -v elinks &> /dev/null; then
        browser_cmd="elinks"
    elif command -v firefox &> /dev/null; then
        browser_cmd="firefox"
    elif command -v google-chrome &> /dev/null; then
        browser_cmd="google-chrome"
    elif command -v chromium &> /dev/null; then
        browser_cmd="chromium"
    else
        echo "No command-line or X browser found."
        return
    fi
    if [[ -z $CODESPACES ]]; then
        if command -v python3 &> /dev/null
        then
            # Start the Python server in the background
            python3 -m http.server > /tmp/config.log 2>&1 &
            local server_pid=$!	
            clear; echo "Starting server..."
            sleep 1
                # Open the HTML file in the browser
            #[[ -n $browser_cmd ]] && $browser_cmd http://localhost:8000/$html_file
            read -p "Press enter to continue"
            # Stop the server
            kill $server_pid
        fi
    else
        echo "GitHub Codespace"
    fi
}

generate_doc() {
    
   
    
    local dir="$(dirname "$(dirname "$(realpath "$0")")")/share"
    
	if [[ ! -d "$dir/doc/${filename%-dev}" ]]; then
        mkdir -p "$dir/doc/${filename%-dev}"
	fi

	doc="doc/${filename%-dev}"

	if [[ ! -d "$dir/man/" ]] ; then
		mkdir -p "$dir/man/man1"
		
    fi

    man="man/man1"

    if [[ ! -d "$dir/${filename%-dev}" ]]; then
        mkdir -p "$dir/${filename}"
    fi

    conf="${filename%-dev}"

    cd "$dir" || exit
	#generate_and_print generate_keypairs "$dir/$conf/$filename" sh "Bash"
    generate_and_print generate_json "$dir/$conf/$filename" json "JSON"
    generate_and_print generate_csv "$dir/$conf/$filename" csv "CSV"
    generate_and_print generate_markdown "$dir/$doc/$filename" md "MAN page"
    
    
    check_dependencies pandoc git whiptail
    [[ -f "$dir/$doc/$filename.md" ]] && pandoc --standalone -t man "$dir/$doc/$filename.md" -o "$dir/$man/$filename.1.gz"
    [[ -f "$dir/$doc/armbianmonitor.md" ]] && pandoc --standalone -t man "$dir/$doc/armbianmonitor.md" -o "$dir/$man/armbianmonitor.1.gz"
    
    return 0

}