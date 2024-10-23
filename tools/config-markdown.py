#!/usr/bin/env python3

import json
import os
import argparse

# Get the absolute path of the script's directory
script_dir = os.path.dirname(os.path.abspath(__file__))

# Construct the path to the external JSON file (e.g., 'config.ng.jobs.json')
json_path = os.path.join(script_dir, '..', 'lib', 'armbian-configng', 'config.ng.jobs.json')

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
    user_content = f"<a id=\"{item['id'].lower()}\" style=\"display:none;\"></a>\n"
    # if above A link is not working, use below line
    #user_content += f"{'#' * level} {item['id']}\n"
    user_content += f"# {item.get('description', '')}\n"
    
    if 'about' in item and item['about']:
        user_content += f"{item['about']}\n\n"
    
    if 'command' in item:
        user_content += f"**Command:** \n~~~\n--cmd {item['id']}\n~~~\n\n"
    
    if 'author' in item:
        user_content += f"**Author:** {item['author']}\n\n"
    
    if 'status' in item:
        user_content += f"**Status:** {item['status']}\n\n"
    
    user_content += '\n\n***\n\n'  # Add extra line for spacing
    
    # Recursively add sub-items if they exist
    if 'sub' in item:
        for sub_item in item['sub']:
            user_content += create_markdown_user(sub_item, level + 1)
    
    return user_content


####################
def write_markdown_files(data):
    """Write Markdown files for both technical and user documentation."""
    # Create 'docs' directory if it doesn't exist
    if not os.path.exists('docs'):
        os.makedirs('docs')

    for item in data['menu']:
        # Create a directory for the top-level item
        item_dir = os.path.join('docs', item['id'])
        if not os.path.exists(item_dir):
            os.makedirs(item_dir)

        # Generate anchor links for the top-level item
        anchor_links = generate_anchor_links(item)
        anchor_links_content = "\n".join(anchor_links) + "\n\n"

        # Technical documentation files
        file_name_technical = f"{item['id']}.technical.md"
        file_path_technical = os.path.join(item_dir, file_name_technical)

        # Generate the Markdown content for technical documentation
        markdown_content_technical = create_markdown_technical(item)

        # Combine anchor links and Markdown content
        full_content_technical = anchor_links_content + markdown_content_technical

        # Write to the technical Markdown file
        with open(file_path_technical, 'w') as f:
            f.write(full_content_technical)

        # User documentation files
        file_name_user = f"{item['id']}.user.md"
        file_path_user = os.path.join(item_dir, file_name_user)

        # Generate the Markdown content for user documentation
        markdown_content_user = create_markdown_user(item)

        # Combine anchor links and Markdown content for users
        full_content_user = anchor_links_content + markdown_content_user

        # Write to the user Markdown file
        with open(file_path_user, 'w') as f:
            f.write(full_content_user)

        # If 'sub' level exists, create separate files for each sub-level
        if 'sub' in item:
            for sub_item in item['sub']:
                # Technical documentation for sub-item
                file_name_sub_technical = f"{sub_item['id']}.technical.md"
                file_path_sub_technical = os.path.join(item_dir, file_name_sub_technical)

                # Generate the Markdown content for technical sub-item
                markdown_content_sub_technical = create_markdown_technical(sub_item)

                # Combine anchor links for the sub-item
                sub_anchor_links = generate_anchor_links(sub_item)
                sub_anchor_links_content = "\n".join(sub_anchor_links) + "\n\n"
                full_content_sub_technical = sub_anchor_links_content + markdown_content_sub_technical

                # Write to the technical Markdown file for the sub-item
                with open(file_path_sub_technical, 'w') as f:
                    f.write(full_content_sub_technical)

                # User documentation for sub-item
                file_name_sub_user = f"{sub_item['id']}.user.md"
                file_path_sub_user = os.path.join(item_dir, file_name_sub_user)

                # Generate the Markdown content for user sub-item
                markdown_content_sub_user = create_markdown_user(sub_item)

                # Combine anchor links and Markdown content for user sub-item
                full_content_sub_user = sub_anchor_links_content + markdown_content_sub_user

                # Write to the user Markdown file for the sub-item
                with open(file_path_sub_user, 'w') as f:
                    f.write(full_content_sub_user)
#######################
import os

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

        anchor_links = generate_anchor_links(item)
        anchor_links_content = "\n".join(anchor_links) + "\n\n"

        file_name_user = f"{item['id']}.user.md"
        file_path_user = os.path.join(item_dir, file_name_user)
        markdown_content_user = create_markdown_user(item)
        full_content_user = anchor_links_content + markdown_content_user

        with open(file_path_user, 'w') as f:
            f.write(full_content_user)

        if 'sub' in item:
            for sub_item in item['sub']:
                file_name_sub_user = f"{sub_item['id']}.user.md"
                file_path_sub_user = os.path.join(item_dir, file_name_sub_user)
                markdown_content_sub_user = create_markdown_user(sub_item)
                sub_anchor_links = generate_anchor_links(sub_item)
                sub_anchor_links_content = "\n".join(sub_anchor_links) + "\n\n"
                full_content_sub_user = sub_anchor_links_content + markdown_content_sub_user

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
        print("Usage: config-markdown --[-u|-t]\nOptions:\n  -u  Generate user documentation\n  -t  Generate technical documentation")
    
    

if __name__ == "__main__":
    main()

# Main script execution
#write_markdown_files(data)
#write_user_markdown_files(data)
#write_technical_markdown_files(data)
#print("Markdown files created in 'docs' directory, organized by top-level folders for both technical and user documentation.")
