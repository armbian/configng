#!/usr/bin/env python3

import json
import os
import sys
import os.path
import argparse

from pathlib import Path

# Get the absolute path of the script's directory
script_dir = os.path.dirname(os.path.abspath(__file__))

# Construct the path to the external JSON file (e.g., 'config.ng.jobs.json')
json_path = os.path.join(script_dir, '..', 'lib', 'armbian-config', 'config.jobs.json')
# Check if the JSON file exists
if not os.path.exists(json_path):
    print("Error: The configuration file 'config.jobs.json' was not found.")
    print("Please run 'config_assemble.sh` `-p` or `-t' first.")
    sys.exit(1)

# Load the JSON data from the external file
with open(json_path, 'r') as json_file:
    data = json.load(json_file)

def generate_anchor_links(item, level=0, parent_path=""):
    """Generate Markdown anchor links for an item with hierarchical structure and indentation."""
    links = []
    # Construct the current path for the link
    current_id = item['id'].lower()
    current_path = f"{parent_path}-{current_id}" if parent_path else current_id
    
    # Add indentation based on the current level
    indent = '  ' * level  # Two spaces for each level
    # Append the current item link with indentation
    links.append(f"{indent}- [{item['description']}](#{item['id'].lower()})")

    # Recursively create links for sub-items if they exist
    if 'sub' in item:
        for sub_item in item['sub']:
            links.extend(generate_anchor_links(sub_item, level + 1, current_path))

    return links


def create_markdown_technical(item, level=1):
    """Recursively create Markdown content for technical documentation from JSON."""
    md_content = f"{'#' * level} {item['id']}\n\n"
    md_content += f"**description:** {item.get('description', '')}\n\n"
    
    if 'about' in item and item['about']:
        md_content += f"**about:** \n{item['about']}\n\n"
    
    if 'command' in item:
        md_content += f"**Command:** \n~~~\n{', '.join(item['command'])}\n~~~\n\n"
    
    if 'author' in item:
        md_content += f"**Author:** {item['author']}\n\n"
    
    if 'status' in item:
        md_content += f"**Status:** {item['status']}\n\n"
    
    if 'condition' in item:
        md_content += f"**Condition:**\n~~~\n{item['condition']}\n~~~\n"
    
    md_content += '\n'  # Add extra line for spacing
    
    # Recursively add sub-items if they exist
    if 'sub' in item:
        for sub_item in item['sub']:
            md_content += create_markdown_technical(sub_item, level + 1)
    
    return md_content

def create_markdown_user(item, level=1):

    """Recursively create Markdown content for user documentation from JSON."""
    #user_content = f"<a id=\"{item['id'].lower()}\" style=\"display:none;\"></a>\n"
    # if above A link is not working, use below line
    #user_content += f"{'#' * level} {item['id']}\n"
    #user_content = f"# {item.get('description', '')}\n"

    # verify if header or footer exists
    image_png_include = Path(os.path.dirname(os.path.abspath(__file__))+'/include/images/'+item['id']+'.png')
    image_webp_include = Path(os.path.dirname(os.path.abspath(__file__))+'/include/images/'+item['id']+'.webp')
    header_include = Path(os.path.dirname(os.path.abspath(__file__))+'/include/markdown/'+item['id']+'-header.md')
    footer_include = Path(os.path.dirname(os.path.abspath(__file__))+'/include/markdown/'+item['id']+'-footer.md')

    user_content = f"{'#' * level} {item.get('description', '')}\n"

    # include png image for section if exists
    if image_png_include.is_file():
        user_content +="\n<!--- section image START from tools/include/images/"+item['id']+".png --->\n"
        with open(image_png_include, 'r') as file:
            user_content += "[!["+ item.get('description', '') + "](/images/"+item['id']+".png)](#)\n"
            user_content +="<!--- section image STOP from tools/include/images/"+item['id']+".png --->\n\n"
    elif image_webp_include.is_file():
        user_content +="\n<!--- section image START from tools/include/images/"+item['id']+".webp --->\n"
        with open(image_webp_include, 'r') as file:
            user_content += "[!["+ item.get('description', '') + "](/images/"+item['id']+".webp)](#)\n"
            user_content +="<!--- section image STOP from tools/include/images/"+item['id']+".webp --->\n\n"

    # include markdown header for section if exists
    if header_include.is_file():
        user_content +="\n<!--- header START from tools/include/markdown/"+item['id']+"-header.md --->\n"
        with open(header_include, 'r') as file:
            user_content += f""+file.read()+"\n"
            user_content +="<!--- header STOP from tools/include/markdown/"+item['id']+"-header.md --->\n\n"

    if 'about' in item and item['about']:
        user_content += f"{item['about']}\n\n"
    
    if 'command' in item:
        user_content += f"**Command:** \n~~~\narmbian-config --cmd {item['id']}\n~~~\n\n"
    
    if 'author' in item:
        user_content += f"**Author:** {item['author']}\n\n"
    
    if 'status' in item:
        user_content += f"**Status:** {item['status']}\n\n"
    
    # include footer for section if exists
    if footer_include.is_file():
        user_content +="\n<!--- footer START from tools/include/markdown/"+item['id']+"-footer.md --->\n"
        with open(footer_include, 'r') as file:
            user_content += f""+file.read()+"\n"
            user_content +="<!--- footer STOP from tools/include/markdown/"+item['id']+"-footer.md --->\n\n"

    user_content += '\n\n***\n\n'  # Add extra line for spacing
    
    # Recursively add sub-items if they exist
    if 'sub' in item:
        for sub_item in item['sub']:
            user_content += create_markdown_user(sub_item, level + 1)
    
    return user_content

def write_technical_markdown_files(data):
    """Write Markdown files for technical documentation."""
    if not os.path.exists('docs'):
        os.makedirs('docs')

    for item in data['menu']:
        item_dir = os.path.join('docs', item['id'])
        if not os.path.exists(item_dir):
            os.makedirs(item_dir)

        anchor_links = generate_anchor_links(item)
        anchor_links_content = "\n".join(anchor_links) + "\n\n"

        file_name_technical = f"{item['id']}.technical.md"
        file_path_technical = os.path.join(item_dir, file_name_technical)
        markdown_content_technical = create_markdown_technical(item)
        full_content_technical = anchor_links_content + markdown_content_technical

        with open(file_path_technical, 'w') as f:
            f.write(full_content_technical)

        if 'sub' in item:
            for sub_item in item['sub']:
                file_name_sub_technical = f"{sub_item['id']}.technical.md"
                file_path_sub_technical = os.path.join(item_dir, file_name_sub_technical)
                markdown_content_sub_technical = create_markdown_technical(sub_item)
                sub_anchor_links = generate_anchor_links(sub_item)
                sub_anchor_links_content = "\n".join(sub_anchor_links) + "\n\n"
                full_content_sub_technical = sub_anchor_links_content + markdown_content_sub_technical

                with open(file_path_sub_technical, 'w') as f:
                    f.write(full_content_sub_technical)

def write_user_markdown_files(data):
    """Write Markdown files for user documentation."""
    if not os.path.exists('docs'):
        os.makedirs('docs')

    for item in data['menu']:
        item_dir = os.path.join('docs', item['id'])
        if not os.path.exists(item_dir):
            os.makedirs(item_dir)

 #       anchor_links = generate_anchor_links(item)
 #       anchor_links_content = "\n".join(anchor_links) + "\n\n"

        file_name_user = f"{item['id']}.user.md"
        file_path_user = os.path.join(item_dir, file_name_user)
        markdown_content_user = create_markdown_user(item)
        #full_content_user = anchor_links_content + markdown_content_user
        full_content_user = markdown_content_user
        with open(file_path_user, 'w') as f:
            f.write(full_content_user)

        if 'sub' in item:
            for sub_item in item['sub']:
                file_name_sub_user = f"{sub_item['id']}.user.md"
                file_path_sub_user = os.path.join(item_dir, file_name_sub_user)
                markdown_content_sub_user = create_markdown_user(sub_item)
                #sub_anchor_links = generate_anchor_links(sub_item)
                #sub_anchor_links_content = "\n".join(sub_anchor_links) + "\n\n"
                #full_content_sub_user = sub_anchor_links_content + markdown_content_sub_user
                full_content_sub_user = markdown_content_sub_user
                with open(file_path_sub_user, 'w') as f:
                    f.write(full_content_sub_user)



def main():
    parser = argparse.ArgumentParser(description="Generate Markdown documentation.")
    parser.add_argument('-u', '--user', action='store_true', help="Generate user documentation")
    parser.add_argument('-t', '--technical', action='store_true', help="Generate technical documentation")
    args = parser.parse_args()

    if args.user:
        write_user_markdown_files(data)
        print("Markdown files created in 'docs' directory, organized by top-level folders for both technical and user documentation.")
    elif args.technical:
        write_technical_markdown_files(data)
        print("Markdown files created in 'docs' directory, organized by top-level folders for both technical and user documentation.")
    else:
        print("Usage: config-markdown [-u|-t]\nOptions:\n  -u  Generate user documentation\n  -t  Generate technical documentation")
    
    

if __name__ == "__main__":
    main()
