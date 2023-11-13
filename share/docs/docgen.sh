#!/bin/bash

directory="$(dirname "${BASH_SOURCE[0]}")"
cd "$directory"

# Initialize variables to store metadata and options
title="config"
uptitle=$(echo "$title" | tr '[:lower:]' '[:upper:]')

section="1" # 1 for user doc
version="1.0.0" # conform to your format
description="A command-line tool" # Short description
options_list=("-h" "-l" "-r") # Short options/flags
# Descriptions for Short options/flags
options_desc=("Display a help message and exit" "Expose all groups and functions" "Run the specified function within the specified group")

author_list=("Tearran tearran@*hidden*" "Someone noreply@*hidden*") # Authors
bug_report="https://github.com/Tearran/configng/issues" # Issues address
date=$(date +"%B %d, %Y") # current date

man_page="$title.$section" # file naming

# Function to create Markdown documentation
create_markdown_documentation() {
  cat <<EOF > "$man_page.md"
---
title: $uptitle
section: $section
header: User Manual
footer: $title $version
date: $date
version: $version
---

# NAME

$uptitle - $description

# DESCRIPTION

The \`$title\` command is a command-line tool for $description. It provides a range of options for configuring various aspects of the system.

# SYNOPSIS

\`$title [OPTIONS] [CATEGORY] [FUNCTION]\`

\`$title\` is the script name.

[OPTIONS] are the available options.

[CATEGORY] is the group/category.

[FUNCTION] is the function within the specified group.

# OPTIONS
  -h, --help
    Display a help message and exit.
  -l, --list
    Expose all groups and functions.
  -r [CATEGORY] [FUNCTION]
    Run the specified function within the specified group.

## Groups
  wireless [options]
    set_wifi_nmtui  Enable or Disable the WiFi text user interface.
    set_wpa_connect Enable or Disable WiFi command line.

  benchmark [options]
    see_monitor     Armbian monitor help message and tools.
    see_boot_times  System boot-up performance statistics.

# EXAMPLES
1. Display the help message:
   \`$title -h\`

2. Expose all groups and functions:
   \`$title -l\`

3. Run the 'set_wifi_nmtui' function within the 'wireless' group:
   \`$title -r wireless set_wifi_nmtui\`

4. Display system boot-up performance statistics:
   \`$title -r benchmark see_boot_times\`

# ENVIRONMENT

Lists any environment variables that affect the behavior of the command.

# SEE ALSO

Other relevant commands and resources.

# BUGS

Report bugs to <$bug_report>.

# AUTHORS

$(for author in "${author_list[@]}"; do echo "  $author"; done)

EOF

  echo "Documentation created: $man_page.md"
}

# Main script execution

create_markdown_documentation

# Convert the Markdown documentation to a man page
pandoc -s -f gfm -t man ./"$man_page.md" -o ./"$man_page"

# Display the man page
man ./"$man_page"

# Generate the HTML file using Pandoc
pandoc -s -f gfm -t html ./"$man_page.md" -o ./"$man_page.html"

# Modify the CSS styles in the HTML file to achieve a dark mode appearance
sed -i 's/color: #1a1a1a;/color: #eee;/; s/background-color: #fdfdfd;/background-color: #333;/' "$man_page.html"
