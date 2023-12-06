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

generate_svg(){

cat << EOF
<svg viewBox="0 0 1280 800">
<g transform="translate(320,100)">
<path class="path" d="m127.45 86.884c-29.866 0-40.567 10.747-40.567 40.567-4.5801 0-28.553-2.6651-24.547 7.1008 2.5444 6.2043 19.117 3.4164 24.547 3.4164v12.02h-25.542c0.46939 14.294 14.613 10.517 25.542 10.517v10.517h-25.542c0.46942 14.116 14.804 10.517 25.542 10.517v10.517c-5.9609 0-18.24-2.3333-23.132 1.543-13.064 10.351 19.588 10.477 23.132 10.477v10.517h-25.542v9.0148h25.542v12.02c-10.929 0-25.073-3.7766-25.542 10.517 10.557 0 24.49-3.2746 25.542 10.517-10.738 0-25.073-3.5987-25.542 10.517 10.557 0 24.49-3.2746 25.542 10.517-3.5448 0-36.196 0.12576-23.132 10.477 4.8925 3.8762 17.17 1.543 23.132 1.543-0.49335 15.149-13.858 12.02-25.542 12.02v9.0148h25.542v12.02h-25.542c0.46939 14.294 14.613 10.517 25.542 10.517v10.517h-25.542c0.46939 14.294 14.613 10.517 25.542 10.517v10.517h-25.542v10.517h25.542v12.02h-25.542v9.0148c11.684 0 25.049-3.1301 25.542 12.02-10.929 0-25.073-3.7766-25.542 10.517l25.542 1.5025v9.0148c-10.738 0-25.073-3.5987-25.542 10.517h25.542v12.02h-25.542c0.46939 14.294 14.613 10.517 25.542 10.517v12.02h-25.542c0.99545 12.776 15.818 9.0148 25.542 9.0148 0 30.27 10.297 40.567 40.567 40.567 0 4.5801-2.6651 28.553 7.1008 24.547 6.2041-2.5444 3.4165-19.117 3.4165-24.547 15.149 0.49336 12.02 13.858 12.02 25.542 14.294-0.46939 10.517-14.613 10.517-25.542h10.517v25.542c14.294-0.46939 10.517-14.613 10.517-25.542h10.517c0 5.9609-2.3332 18.24 1.543 23.132 10.351 13.064 10.477-19.588 10.477-23.132h10.517v25.542h9.0148v-25.542h12.02c0 5.9609-2.3332 18.24 1.543 23.132 10.351 13.064 10.477-19.588 10.477-23.132h10.517v25.542c14.116-0.46943 10.517-14.804 10.517-25.542h10.517v25.542c14.294-0.46939 10.517-14.613 10.517-25.542h10.517c0 4.764-2.8891 28.517 7.0637 24.547 6.246-2.4915 3.4536-19.123 3.4536-24.547h12.02c0 4.764-2.8891 28.517 7.0637 24.547 6.2461-2.4917 3.4536-19.123 3.4536-24.547h10.517v25.542h10.517v-25.542h10.517c0 3.5446 0.12575 36.196 10.477 23.132 3.8764-4.8925 1.543-17.17 1.543-23.132h10.517v25.542c14.116-0.46943 10.517-14.804 10.517-25.542h10.517c0 3.5446 0.1262 36.196 10.477 23.132 3.8764-4.8925 1.543-17.17 1.543-23.132 13.792 1.0522 10.517 14.985 10.517 25.542 14.116-0.46943 10.517-14.804 10.517-25.542h10.517v25.542h10.517v-25.542h12.02v25.542c12.776-0.99545 9.0148-15.818 9.0148-25.542 30.27 0 40.567-10.297 40.567-40.567 9.7244 0 24.546 3.7614 25.542-9.0148-11.684 0-25.049 3.1301-25.542-12.02 10.929 0 25.073 3.7766 25.542-10.517-11.684 0-25.049 3.1301-25.542-12.02h25.542c-0.46937-14.116-14.805-10.517-25.542-10.517v-9.0148l25.542-1.5025c-0.46922-14.294-14.613-10.517-25.542-10.517 0.49326-15.149 13.858-12.02 25.542-12.02v-9.0148h-25.542v-12.02h25.542c-0.46922-14.294-14.613-10.517-25.542-10.517v-10.517c10.929 0 25.073 3.7766 25.542-10.517h-25.542v-10.517c10.929 0 25.073 3.7766 25.542-10.517h-25.542v-12.02h25.542v-9.0148c-11.684 0-25.049 3.1301-25.542-12.02 5.9609 0 18.24 2.3332 23.132-1.543 13.064-10.351-19.588-10.477-23.132-10.477 1.052-13.792 14.985-10.517 25.542-10.517-0.46922-14.294-14.613-10.517-25.542-10.517 1.0522-13.792 14.985-10.517 25.542-10.517v-10.517h-25.542v-12.02h25.542v-9.0148h-25.542v-10.517c3.5446 0 36.196-0.12591 23.132-10.477-4.8925-3.8764-17.17-1.543-23.132-1.543v-10.517c10.929 0 25.073 3.7766 25.542-10.517-10.557 0-24.49 3.2746-25.542-10.517 10.929 0 25.073 3.7766 25.542-10.517-11.684 0-25.049 3.1301-25.542-12.02 4.764 0 28.517 2.8891 24.547-7.0637-2.4917-6.246-19.123-3.4536-24.547-3.4536 0-29.83-10.547-40.567-40.567-40.567v-25.542c-12.776 0.9954-9.0148 15.818-9.0148 25.542h-12.02c0-4.764 2.8891-28.518-7.0637-24.547-6.246 2.4917-3.4536 19.123-3.4536 24.547h-10.517c0-10.929 3.7766-25.073-10.517-25.542v25.542h-10.517c0-5.8882 2.5422-19.885-2.6119-23.991-11.212-8.9322-9.4078 19.724-9.4078 23.991h-10.517c0-4.58 2.6651-28.553-7.1008-24.547-6.2043 2.5444-3.4164 19.117-3.4164 24.547h-10.517c0-3.5446-0.12576-36.196-10.477-23.132-3.8762 4.8923-1.543 17.17-1.543 23.132h-10.517c0-5.4235 2.7926-22.056-3.4536-24.547-9.9528-3.9703-7.0637 19.783-7.0637 24.547h-10.517c0-10.929 3.7766-25.073-10.517-25.542v25.542h-12.02c0-5.4235 2.7925-22.056-3.4536-24.547-9.9528-3.9703-7.0637 19.783-7.0637 24.547h-10.517c0-5.4235 2.7925-22.056-3.4536-24.547-9.9528-3.9703-7.0637 19.783-7.0637 24.547h-10.517c0-10.738 3.5987-25.073-10.517-25.542v25.542h-10.517c0-4.3459 1.6997-32.243-9.6119-23.969-5.0142 3.6675-2.4078 18.425-2.4078 23.969h-12.02c0-4.6694 2.7546-24.586-4.5074-24.586-7.262 0-4.5074 19.917-4.5074 24.586h-10.517c0-5.8882 2.5422-19.885-2.6119-23.991-11.212-8.9322-9.4078 19.724-9.4078 23.991h-10.517c0-10.738 3.5987-25.073-10.517-25.542v25.542h-10.517c0-4.764 2.8891-28.518-7.0637-24.547-6.246 2.4917-3.4536 19.123-3.4536 24.547h-12.02c0-4.9298 2.8634-26.014-5.8302-24.842-7.5529 1.0181-4.6871 19.574-4.6871 24.842zm189.1 230.31c-0.82636-0.27566-3.4351-0.92965-5.7971-1.4533l-4.2946-0.95215 0.97387-30.356c0.53563-16.695 0.40433-35.218-0.29181-41.16-1.2175-10.393-1.1393-10.836 2.0543-11.638 1.826-0.45828 4.395-1.2458 5.7091-1.7501 2.135-0.81928 2.2851 1.0181 1.4112 17.272-0.71538 13.305-0.51255 18.189 0.75535 18.189 0.95336 0 1.7334-1.0662 1.7334-2.3692 0-4.2499 8.3591-11.153 13.505-11.153 7.0587 0 10.473 2.5054 13.998 10.27 4.0332 8.886 4.2442 27.95 0.40989 37.057-5.6197 13.347-19.448 21.617-30.167 18.043zm16.656-8.9741c6.7937-4.4515 9.4095-30.179 4.1608-40.924-2.1939-4.4913-3.7571-5.8012-7.3421-6.1524-7.8055-0.76488-11.284 4.6423-13.028 20.249-1.6593 14.856-0.7428 27.403 2.1422 29.331 2.425 1.6195 9.769 0.3126 14.067-2.5033zm-193.02 1.157c-3.0919-6.1838-2.2826-10.683-0.26135-18.189 2.7414-10.181 11.279-15.325 25.435-15.325h6.5933l-0.83382-6.2166c-0.4586-3.4192-1.8987-7.2814-3.2001-8.583-2.9713-2.9713-12.583-2.7396-18.755 0.45185-4.3071 2.2273-4.6222 2.184-6.251-0.85927-2.0352-3.8028-0.72392-4.9784 8.3502-7.4866 7.8971-2.1828 19.568-0.96696 23.321 2.4298 4.7451 4.2944 5.9227 11.881 5.7713 37.186l-0.14138 23.644h-4.3283c-3.9308 0-4.3283-0.47476-4.3283-5.17 0-2.8434-0.67611-5.5878-1.5025-6.0985-0.82635-0.51068-1.5025-0.0367-1.5025 1.0535 0 1.0902-1.7176 3.8344-3.817 6.0985-3.0384 3.2769-5.1563 4.1165-10.384 4.1165-5.4162 0-11.675-2.0714-14.166-7.053zm26.205-5.7043c3.0554-4.006 4.0496-7.1115 4.2082-13.147 0.20545-7.8145 0.15557-7.9067-4.5229-8.3611-14.377-1.3963-23.676 12.328-15.444 22.794 4.6001 5.848 10.696 5.3506 15.758-1.2861zm25.912-18.419c-0.25384-17.146-0.46154-31.248-0.46154-31.335 0-0.0871 2.1974-0.57807 4.883-1.0893l4.883-0.92948v7.4748c0 4.111 0.67611 7.4748 1.5025 7.4748 0.82635 0 1.5025-1.1034 1.5025-2.4519 0-3.1992 9.9672-12.573 13.369-12.573 2.0761 0 2.497 0.95958 1.9762 4.5074-0.51028 3.4767-1.4346 4.5074-4.0422 4.5074-4.101 0-10.957 6.536-12.46 11.879-0.60303 2.1431-1.0964 12.854-1.0964 23.802v19.906l-9.5942 3e-3zm34.095 3.0057c0-15.495-0.55264-29.693-1.2281-31.552-1.0292-2.833-0.70903-3.3806 1.9768-3.3806 1.7627 0 4.5128-0.69989 6.1111-1.5554 2.654-1.4203 2.9062-1.0199 2.9062 4.6144v6.1697l5.0605-5.3656c4.1462-4.3962 6.1347-5.3656 11.007-5.3656 5.9609 0 12.48 4.5633 12.48 8.7359 0 2.6556 0.70959 2.2737 6.4606-3.4773 4.2998-4.2998 6.3819-5.2586 11.419-5.2586 4.1569 0 7.1373 0.97722 9.165 3.0049 2.7354 2.7354 3.0049 5.0082 3.0049 25.332 0 12.28 0.42994 25.464 0.95545 29.298l0.95546 6.9708h-10.926v-26.186c0-21.802-0.39527-26.582-2.361-28.547-3.1876-3.1876-8.5674-2.9747-12.873 0.50925-3.4773 2.8138-3.547 3.3745-3.547 28.544v25.674l-10.522 6e-3 3e-3 -25.38c2e-3 -22.85-0.28292-25.695-2.8598-28.547-3.8412-4.2503-8.6091-3.992-13.027 0.70582-3.5027 3.7243-3.6608 4.8196-4.1192 28.547l-0.47734 24.674-9.5638 1e-3zm135.71 0.49747c0.31275-17.547-0.0886-28.763-1.0966-30.647-1.3467-2.5163-1.0413-3.1084 1.9965-3.8708 1.9724-0.49507 4.4943-1.2485 5.604-1.6744 1.65-0.63319 2.0177 5.1145 2.0177 31.546v32.32l-9.0148 3e-3zm24.251 23.868c-2.799-2.9792-3.6883-5.8314-4.0996-13.147-0.89349-15.89 6.9016-23.616 23.826-23.616h7.7584l-0.83387-6.2166c-0.45855-3.4192-1.8356-7.2183-3.0599-8.4427-2.86-2.86-12.993-2.7406-18.719 0.2204-4.213 2.1787-4.4803 2.1219-6.0301-1.2797-1.4962-3.2838-1.161-3.7437 4.3284-5.9402 3.2727-1.3094 9.6445-2.3808 14.16-2.3808 6.9454 0 8.9649 0.67454 13.116 4.3809l4.9068 4.3809 0.93708 55.844h-4.6002c-4.403 0-4.6024-0.27388-4.648-6.3855-0.0451-6.0219-0.17684-6.2144-2.3141-3.3806-6.6235 8.7819-8.0992 9.766-14.645 9.766-5.0226 0-7.3254-0.86892-10.083-3.8047zm21.607-8.2221c3.8205-4.5404 6.6041-15.94 4.9469-20.258-1.0388-2.7071-7.5512-2.9629-14.426-0.56637-3.3168 1.1563-5.5672 3.3188-6.9853 6.7129-2.737 6.5506-2.6469 7.9312 0.89638 13.743 4.0059 6.5701 10.226 6.7172 15.569 0.36848zm25.766-18.76v-30.784l4.356-1.5178c2.3958-0.83477 4.5932-1.5178 4.883-1.5178 0.28983 0 0.52707 2.4984 0.52707 5.5522v5.5522l5.0857-5.5522c4.4386-4.8459 5.9571-5.5522 11.936-5.5522 5.0734 0 7.9426 0.93961 11.061 3.6223l4.2113 3.6223 1.0839 57.361h-10.203l0.57229-23.664c0.35549-14.703-0.0391-25.238-1.0433-27.823-3.2163-8.2798-13.85-8.3391-19.245-0.10743-2.3201 3.5401-2.7079 7.5293-2.7079 27.862v23.73l-10.517-5.2e-4zm-72.118-44.338c-1.554-4.8961 0.53857-9.0148 4.58-9.0148 2.62 0 3.8893 1.0477 4.574 3.7757 1.7305 6.895-7.0359 11.912-9.1539 5.2391z" style="fill:none;stroke-width:2;stroke:#ff0000"/>
</g>
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
Purpose is to 
- separate the business end from the front end  
- generate user documentation

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
generate_help(){
cat << EOF 
Usage: ${filename%.*} [flag][option]
  flag options:
    -h,      Print this help.
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
    generate_svg > "$filename.svg"
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