

# This function is used to generate a text-based user interface (TUI) for navigating the menus.
generate_tui() {
    local options=()
    local i=0
    declare -A categories_array
    for category in "${categories[@]}"; do
        local category_name="${category##*/}"
        local category_description=""
        local category_file="$category/readme.md"

        if [[ -f "$category_file" ]]; then
            category_description=$(grep -oP "(?<=# @description ).*" "$category_file")
        fi

        categories_array["$i"]="$category_name"
        description_array["$i"]="$category_description"
        options+=("$i" "${categories_array[$i]} - ${description_array[$i]}")
        ((++i))
    done
    options+=("$i" "Legacy - Run Legacy configuration")
    ((++i))
    options+=("$i" "Help   - Documentation, support, sources" )
    ((++i))

    local choice
    
    choice=$($dialogue --menu "Select a category:" 0 0 9 "${options[@]}" 3>&1 1>&2 2>&3)
    
   if [[ -n $choice ]]; then
        
        if ((choice == "$i - 1")); then
            generate_help | armbian-interface -o
            exit ;
        elif ((choice == "$i - 2")); then
            armbian-config
            exit ;
        else
            generate_sub_tui "${categories_array[$choice]}"
        fi
    fi
}

# This function is used to generate a text-based user interface (TUI) for navigating the menus.
generate_sub_tui() {
    local category="$1"
    local options=()
    local i=0
    declare -A functions_array
    for file in "$libpath/$category"/*.sh; do
        mapfile -t functions_in_file < <(grep -oP '(?<=function\s)\w+::\w+' "$file")
        for function in "${functions_in_file[@]}"; do
            key="${category##*/}:${file##*/}:${function}"
            functions_array["$i"]="$function"
            options+=("$i" "${functions["$key,function_name"]} - ${functions["$key,description"]}")
            ((++i))
        done
    done

    local choice
    
    choice=$($dialogue --menu "Select a function:" 0 0 9 "${options[@]}" 3>&1 1>&2 2>&3)
    
    if [[ -n $choice ]]; then
        generate_action "${functions_array[$choice]}"
    fi

}

# This function is used to generate a whiptail/dialog text-based user interface (TUI) for navigating the menus.
generate_action() {
    local function_name="$1"
            ${function_name}
}

# This function is used to generate a bash text-based user interface (TUI) for navigating the menus.
generate_read() {
    echo
    echo "Please select an action:"
    echo
    # Initialize an empty array to store the function keys
    declare -a function_keys

    # Loop through each key in the functions array
    local i=1
    local current_category=""
    for key in "${!functions[@]}"; do
        if [[ $key == *",function_name" ]]; then
            # Add the key to the function_keys array
            function_keys[i]="${key%,function_name}"

            # Check if the category has changed and display it if so
            local category="${functions["${function_keys[i]},category"]}" # < editor"
            if [[ "$category" != "$current_category" ]]; then
                echo "Category: $category"
                current_category="$category"
            fi

            # Display the function and its description as an option in the menu
            echo "  $i. ${functions["${function_keys[i]},group_name"]} ${functions[$key]}  - ${functions["${function_keys[i]},description"]}" #" < for my editor
            ((i++))
        fi
    done

    echo
    echo "$i. Show help"
    ((i++))
    echo "$i. Exit"

    read -p "Enter your choice: " choice

    if ((choice == i-1)); then
        generate_help
        generate_list
    elif ((choice == i)); then
        exit 0
    elif ((choice >= 1 && choice <= ${#function_keys[@]})); then
        # Call the selected function using variable indirection
        eval "${functions["${function_keys[choice]},group_name"]}::${functions["${function_keys[choice]},function_name"]}" #" < for my editor
    else
        echo "Invalid choice"
    fi
}

# This function is used to generate a JSON file containing all functions and their descriptions.
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

# This function is used to generate a Single page app for website
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

# This function is used to generate a Single page app for website
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

# This function is used to generate readme.md file
generate_markdown() {
cat << EOF
# Armbian ConfigNG
Refactor of [armbian-config](https://github.com/armbian/config)
## relaease
2021-09-01
# User guide
## Quick start
Run the following commands:

    sudo apt install git
    cd ~/
    git clone https://github.com/armbian/configng.git
    bash ~/configng/bin/armbian-configng -h

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
 - Markdown
 - JSON
 - Text User Interface
 - Command Line Interface
 - Help message
 - launch a feature

## Up to date list of functions
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
[Bash Utility (https://labbots.github.io/bash-utility)

 This allows for functional programming in Bash. Error handling and validation are also included.
The idea is to provide an API in Bash that can be called from a Command line interface, Text User interface and others.

 Why Bash? Well, because it's going to be in every distribution. Striped down distributions
may not include Python, C/C++, etc. build/runtime environments )

EOF
}

# This function is used to parse the action name and return the full function name.
parse_action() {
    local group=$1
    local action=$2

    # Construct the full function name
    local function_name="${group}::${action}"

    # Check if the function exists
    if declare -f "$function_name" > /dev/null; then
        # Return the function name
        echo "$function_name"
    else
        echo "Error: Unknown action '$action' for group '$group'"
        return 1
    fi
}