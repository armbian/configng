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


# This function is used to generate a extention to help meassage of all functions and their descriptions.
generate_list() {
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

# This function is used to generate a help message.
generate_help(){
cat << EOF 
Usage: ${filename%.*} [flag] [option]
  flags:
    -h,   Print this help.
    -d,   Generate Documentation.  
    -t,   Show a TUI fallback read.

    --help,   Prints Help message of long flag options.
    --run,    Run a function.
EOF
generate_list
}

generate_doc(){
    
    cd "$(dirname "$(dirname "$(realpath "$0")")")/share/armbian-configng/" || exit
    
    generate_markdown > "../../readme.md" ;
    chmod 755 "../../readme.md" ;
    echo "$filename About readme.md" ;

    generate_html > "$filename-table.html" ;
    chmod 755 "$filename-table.html" ;
    echo "$filename -   $filename-table.html" ;

    generate_markdown > readme.md  
    chmod 755 readme.md
    echo "Markdown  -   generated readme.md " ;

    generate_html5 > "$filename-spa.html" ;
    chmod 755 "$filename-spa.html" ;
    echo "HTML5     -   generated $filename-spa.html" ;
    
    generate_json > "data/$filename.json" 
    chmod 755 "data/$filename.json"
    echo "JSON      -   generated data/$filename.json" ;

    generate_csv > "data/$filename.csv" ;
    chmod 755 "data/$filename.csv" ;
    echo "CSV       -   generated data/$filename.csv" ;

    return 0 ;
}