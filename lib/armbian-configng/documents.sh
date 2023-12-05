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
            json_objects+=("{ \"Function Name\": \"$function_name\", \"Group Name\": \"$group_name\", \"Description\": \"$description\", \"Options\": \"$options\", \"Category\": \"$category\", \"Category Description\": \"$category_description\" }")
        fi
    done
    IFS=','
    echo "[${json_objects[*]}]" | jq
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

generate_csv_test() {
    for category in "${categories[@]}"; do
        echo "Function Name,Group Name,Description,Options,Category,Category Description" > "$category.csv"
        for key in "${!functions[@]}"; do
            if [[ $key == *",function_name"* ]]; then
                function_key="${key%,function_name}"
                function_name="${functions[$key]}"
                group_name="${functions["$function_key,group_name"]}"
                description="${functions["$function_key,description"]}"
                options="${functions["$function_key,options"]}"
                category="${functions["$function_key,category"]}"
                category_description="${functions["$function_key,category_description"]}"
                if [[ $category == "$category" ]]; then
                    echo "$function_name,$group_name,$description,$options,$category,$category_description" >> "$category.csv"
                fi
            fi
        done
    done
}

# This function is used to generate a Single page app.   
generate_html5() {

html5_content='
<!DOCTYPE html>
<html>
<head>
    <title>
		Armbian '$(echo "$filename")' </title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #222;
            color: #fff;
        }
        .slider {
            width: 100%;
            height: 300px;
            overflow: hidden;
            background-color: #333;
        }
        .slide {
            width: 100%;
            height: 300px;
            transition: all 1s ease;
            background-color: #444;
        }
    </style>
</head>
<body>
    <header>
        <h1>'$(echo "$filename")'</h1>
    </header>
    <nav>
        <ul>
            <!-- MENU -->
        </ul>
    </nav>
    <section class="slider">
        <div class="slide-show">
            <!-- SLIDES -->
        </div>
    </section>

<script>

    // javascript to make a menu from the json data and add it to the html5_content
    var menu = document.querySelector("nav ul");
    var slides = document.querySelector(".slide-show");
	var slideIndex = 0;
	var jsonData ='$(generate_json)' ;
    var data = jsonData;    
    var menuItems = [];
    var slideItems = [];
    var i;
    for (i = 0; i < data.length; i++) {
        menuItems.push("<li><a href=\"#slide" + i + "\">" + data[i]["Function Name"] + "</a></li>");
        slideItems.push("<div class=\"slide\" id=\"slide" + i + "\"><h2>" + data[i]["Function Name"] + "</h2><p>" + data[i]["Description"] + "</p></div>");
    }
    menu.innerHTML = menuItems.join("");
    slides.innerHTML = slideItems.join("")
    showSlides(slideIndex);

</script>

</body>
</html>
'

echo "$html5_content" ;

}

# This function is used to generate tabe html file
# used to check proper array generation and output.
generate_html() {
    html_content='<!DOCTYPE html>
    <html>
    <head>
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
        <table>
            <thead>
                <tr>
                    <th>Function Name</th>
                    <th>Group Name</th>
                    <th>Description</th>
                    <th>Options</th>
                    <th>Category</th>
                    <th>Category Description</th>
                </tr>
            </thead>
            <tbody>'
    for key in "${!functions[@]}"; do
        if [[ $key == *",function_name"* ]]; then
            function_key="${key%,function_name}"
            function_name="${functions[$key]}"
            group_name="${functions["$function_key,group_name"]}"
            description="${functions["$function_key,description"]}"
            options="${functions["$function_key,options"]}"
            category="${functions["$function_key,category"]}"
            category_description="${functions["$function_key,category_description"]}"
            html_content+="<tr><td>$function_name</td><td>$group_name</td><td>$description</td><td>$options</td><td>$category</td><td>$category_description</td></tr>"
        fi
    done
    html_content+='
            </tbody>
        </table>

    </body>
    </html>'

    echo "$html_content"
}

# This function is used to generate the main readme.md file
generate_markdown() {
cat << EOF
# Armbian ConfigNG 
Refactor of [armbian-config](https://github.com/armbian/config)       

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
function group::string() {
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
generate_help(){
cat << EOF 
Usage: ${filename%.*} [flag][option]
  flag options:
    -h,      Print this help.
    -d,      Generate Documentation.  
    -t,      Show a TUI fallback read.
    --help,  Prints Help message of long flag interactive options (WIP)."
    help,    View advanced no-interface options (CURRENT FOCUS)."
EOF
}


generate_and_print() {
    local generate_func=$1
    local filename=$2
    local file_extension=$3
    local output_message=$4

    "$generate_func" > "$filename.$file_extension"
    chmod 755 "$filename.$file_extension"
    echo "$output_message - generated $filename.$file_extension"
}

generate_doc() {
    dir="$(dirname "$(dirname "$(realpath "$0")")")/share/${filename%-dev}"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir/data/"
    fi
    cd "$dir" || exit
    generate_and_print generate_markdown "../../readme" md "readme.md"
    generate_and_print generate_html "$filename-table" html "Table"
    generate_and_print generate_markdown "readme" md "Markdown"
    generate_and_print generate_html5 "index" html "HTML5"
    generate_and_print generate_json "data/$filename" json "JSON"
    generate_and_print generate_csv "data/${filename%-dev}" csv "CSV"
    if [[ "$EUID" -eq 0 ]]; then
        chown -R "$SUDO_USER":"$SUDO_USER" "$(dirname "$dir")"
        cd ../../
        chown  "$SUDO_USER":"$SUDO_USER" readme.md
    fi
    return 0
}