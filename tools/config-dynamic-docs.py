#!/usr/bin/env python3

import json
import os

# Get the absolute path of the script's directory
script_dir = os.path.dirname(os.path.abspath(__file__))

# Construct the path to the external JSON file (e.g., 'menu_data.json')
json_path = os.path.join(script_dir, '..', 'lib', 'armbian-configng', 'config.ng.jobs.json')

# Load the JSON data from the external file
with open(json_path, 'r') as json_file:
    data = json.load(json_file)

def gather_markdown_links(item, collected_links, level=1):
    """Recursively gather Markdown links for all IDs and descriptions."""
    link_text = f"{'  ' * (level - 1)}- [{item['id']}](#{item['id'].lower()})"
    description = f": {item.get('description', '')}"
    collected_links.append(f"{link_text}{description}")
    
    if 'sub' in item:
        for sub_item in item['sub']:
            gather_markdown_links(sub_item, collected_links, level + 1)

def create_markdown(item, level=1):
    """Recursively create Markdown content from JSON."""
    md_content = f"{'#' * level} {item['id']}\n\n"
    md_content += f"**Description:** {item.get('description', '')}\n\n"
    
    if 'prompt' in item and item['prompt']:
        md_content += f"**Prompt:** \n{item['prompt']}\n\n"
    
    if 'command' in item:
        md_content += f"**Command:** \n~~~\n{', '.join(item['command'])}\n~~~\n\n"
    
    if 'author' in item:
        md_content += f"**Author:** {item['author']}\n\n"
    
    if 'status' in item:
        md_content += f"**Status:** {item['status']}\n\n"
    
    if 'condition' in item:
        md_content += f"**Condition:**\n~~~\n {item['condition']}\n~~~\n"
    
    md_content += '\n'  # Add extra line for spacing
    
    if 'sub' in item:
        for sub_item in item['sub']:
            md_content += create_markdown(sub_item, level + 1)
    
    return md_content

def create_markdown_user(item, level=1):
    """Recursively create user-focused Markdown content from JSON."""
    user_content = f"{'#' * level} {item['id']}\n\n"
    user_content += f"**Description:** {item.get('description', '')}\n\n"
    
    if 'prompt' in item and item['prompt']:
        user_content += f"**Prompt:** \n{item['prompt']}\n\n"
    
    if 'command' in item:
        user_content += f"**Command:** \n~~~\n--cmd {item['id']}\n~~~\n\n"
    
    if 'author' in item:
        user_content += f"**Author:** {item['author']}\n\n"
    
    if 'status' in item:
        user_content += f"**Status:** {item['status']}\n\n"
        
    user_content += '\n'  # Add extra line for spacing
    
    if 'sub' in item:
        for sub_item in item['sub']:
            user_content += create_markdown_user(sub_item, level + 1)
    
    return user_content

# Create 'docs' directory if it does not exist
if not os.path.exists('docs'):
    os.makedirs('docs')

# Create Markdown files for technical documentation and user documentation
for menu_item in data['menu']:
    # Gather navigation links
    all_links = []
    gather_markdown_links(menu_item, all_links)
    markdown_links_content = "\n".join(all_links) + "\n\n"

    # Generate the main Markdown content for technical users
    markdown_content = create_markdown(menu_item)
    
    # Combine navigation links and main content for technical users
    full_content_technical = markdown_links_content + markdown_content
    
    # Use the item's id for the technical file name
    file_name_technical = f"{menu_item['id']}.technical.md"
    file_path_technical = os.path.join('docs', file_name_technical)
    
    # Write to the Markdown file for technical users
    with open(file_path_technical, 'w') as f:
        f.write(full_content_technical)

    # Generate the user-focused Markdown content
    user_content = create_markdown_user(menu_item)
    
    # Combine navigation links and main content for users
    full_content_user = markdown_links_content + user_content
    
    # Use the item's id for the user file name
    file_name_user = f"{menu_item['id']}.user.md"
    file_path_user = os.path.join('docs', file_name_user)
    
    # Write to the Markdown file for users
    with open(file_path_user, 'w') as f:
        f.write(full_content_user)

print("Markdown files created in 'docs' directory for both technical and user documentation.")
