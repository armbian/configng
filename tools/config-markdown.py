#!/usr/bin/env python3

import os
import sys
import json
import argparse
from pathlib import Path

# Setup paths
SCRIPT_DIR = Path(__file__).resolve().parent
CONFIG_PATH = SCRIPT_DIR.parent / 'lib' / 'armbian-config' / 'config.jobs.json'
IMAGES_DIR = SCRIPT_DIR / 'include' / 'images'
MARKDOWN_DIR = SCRIPT_DIR / 'include' / 'markdown'
DOCS_DIR = Path('docs')

# Load JSON
if not CONFIG_PATH.exists():
    print("Error: The configuration file 'config.jobs.json' was not found.")
    print("Please run 'config_assemble.sh -p' or '-t' first.")
    sys.exit(1)

with open(CONFIG_PATH, 'r') as f:
    data = json.load(f)

# Functions
def generate_anchor_links(item, level=0, parent_path=""):
    """
    Generates a list of Markdown anchor links for a hierarchical item and its sub-items.
    
    Each link corresponds to an item's description linked to its lowercase ID anchor, with indentation reflecting the item's depth in the hierarchy.
    """
    links = []
    current_id = item['id'].lower()
    current_path = f"{parent_path}-{current_id}" if parent_path else current_id
    indent = '  ' * level
    links.append(f"{indent}- [{item['description']}](#{current_id})")
    if 'sub' in item:
        for sub_item in item['sub']:
            links.extend(generate_anchor_links(sub_item, level + 1, current_path))
    return links

def create_markdown_technical(item, level=1):
    """
    Recursively generates technical Markdown documentation for a configuration item and its sub-items.
    
    Each item's section includes its ID, description, optional about text, commands, author, status, and condition. Sub-items are documented as nested sections with incremented header levels.
    
    Args:
        item: A dictionary representing a configuration item.
        level: The Markdown header level to use for this item.
    
    Returns:
        A string containing the generated Markdown content for the item and its sub-items.
    """
    md = [f"{'#' * level} {item['id']}\n"]
    md.append(f"**description:** {item.get('description', '')}\n")

    if item.get('about'):
        md.append(f"**about:**\n{item['about']}\n")

    if item.get('command'):
        md.append(f"**Command:**\n~~~\n{', '.join(item['command'])}\n~~~\n")

    if item.get('author'):
        md.append(f"**Author:** {item['author']}\n")

    if item.get('status'):
        md.append(f"**Status:** {item['status']}\n")

    if item.get('condition'):
        md.append(f"**Condition:**\n~~~\n{item['condition']}\n~~~\n")

    if 'sub' in item:
        for sub_item in item['sub']:
            md.append(create_markdown_technical(sub_item, level + 1))

    return '\n'.join(md)

def create_markdown_user(item, level=1, show_meta=True):
    """
    Generates user-oriented Markdown documentation for a configuration item and its sub-items.
    
    Recursively builds Markdown content for the given item, including headers, optional metadata (status, author, maintainer), embedded images if available, optional header markdown, and command usage examples. Sub-items are processed recursively, displaying metadata only for the first sub-item.
    
    Args:
        item: Dictionary representing a configuration item.
        level: Header level for Markdown formatting.
        show_meta: Whether to display metadata for this item and the first sub-item.
    
    Returns:
        A string containing the generated Markdown content.
    """
    md = []

    # Title
    header_prefix = "#" * level
    md.append(f"{header_prefix} {item.get('description', '')}\n")

    # Only show meta if it has 'command' or 'sub' but not for "category" level
    if show_meta and item.get('command'):
        if item.get('status'):
            md.append(f"**Status:** {item['status']}\n")
        if item.get('author'):
            md.append(f"**Author:** {item['author']}\n")
        if item.get('maintainer'):
            md.append(f"**Maintainer:** {item['maintainer']}\n")

    # Image if exists
    for ext in ('png', 'webp'):
        image_file = Path(__file__).parent / 'include' / 'images' / f"{item['id']}.{ext}"
        if image_file.is_file():
            rel_path = f"tools/include/images/{item['id']}.{ext}"
            md.append(f"\n<!--- section image START from {rel_path} --->")
            md.append(f"[![{item['description']}](/images/{item['id']}.{ext})](#)")
            md.append(f"<!--- section image STOP from {rel_path} --->\n")
            break

    # Header if exists
    header_file = Path(__file__).parent / 'include' / 'markdown' / f"{item['id']}-header.md"
    if header_file.is_file():
        rel_path = f"tools/include/markdown/{item['id']}-header.md"
        md.append(f"\n<!--- header START from {rel_path} --->")
        md.append(header_file.read_text())
        md.append(f"<!--- header STOP from {rel_path} --->\n")

    # Commands
    if item.get('command'):
        for cmd in item['command']:
            md.append(f"\n~~~ bash title=\"{item.get('description', '')}:\"\narmbian-config --cmd {item['id']}\n~~~\n")

    # Sub-items
    if 'sub' in item:
        first = True
        for sub_item in item['sub']:
            # Only the first subitem shows meta info
            md.append(create_markdown_user(sub_item, level + 1, show_meta=first))
            first = False

    return '\n'.join(md)

def write_technical_markdown_files(data):
    """
    Generates and writes technical Markdown documentation files for each menu item and its sub-items.
    
    For each top-level menu item in the data, creates a subdirectory and writes a technical Markdown file containing anchor links and detailed technical content. Also generates separate technical Markdown files for each sub-item within the corresponding directory.
    """
    DOCS_DIR.mkdir(exist_ok=True)

    for item in data['menu']:
        item_dir = DOCS_DIR / item['id']
        item_dir.mkdir(exist_ok=True)

        anchors = "\n".join(generate_anchor_links(item)) + "\n\n"
        technical_md = create_markdown_technical(item)

        (item_dir / f"{item['id']}.technical.md").write_text('---\ncomments: true\n---\n\n' + anchors + technical_md)

        if 'sub' in item:
            for sub_item in item['sub']:
                sub_anchors = "\n".join(generate_anchor_links(sub_item)) + "\n\n"
                sub_technical_md = create_markdown_technical(sub_item)
                (item_dir / f"{sub_item['id']}.technical.md").write_text('---\ncomments: true\n---\n\n' + sub_anchors + sub_technical_md)

def write_user_markdown_files(data):
    """
    Generates user-oriented Markdown documentation files for each menu item and its sub-items.
    
    For each top-level item in the configuration data, creates a directory and writes a user Markdown file with embedded metadata. Also generates separate user Markdown files for each sub-item.
    """
    DOCS_DIR.mkdir(exist_ok=True)

    for item in data['menu']:
        item_dir = DOCS_DIR / item['id']
        item_dir.mkdir(exist_ok=True)

        user_md = create_markdown_user(item)
        (item_dir / f"{item['id']}.user.md").write_text('---\ncomments: true\n---\n\n' + user_md)

        if 'sub' in item:
            for sub_item in item['sub']:
                sub_user_md = create_markdown_user(sub_item)
                (item_dir / f"{sub_item['id']}.user.md").write_text('---\ncomments: true\n---\n\n' + sub_user_md)

def main():
    """
    Parses command-line arguments to generate user or technical Markdown documentation.
    
    Depending on the provided flags, generates either user-oriented or technical documentation
    files in the 'docs' directory. Prints usage instructions if no valid option is specified.
    """
    parser = argparse.ArgumentParser(description="Generate Markdown documentation.")
    parser.add_argument('-u', '--user', action='store_true', help="Generate user documentation")
    parser.add_argument('-t', '--technical', action='store_true', help="Generate technical documentation")
    args = parser.parse_args()

    if args.user:
        write_user_markdown_files(data)
        print("User Markdown files created in 'docs' directory.")
    elif args.technical:
        write_technical_markdown_files(data)
        print("Technical Markdown files created in 'docs' directory.")
    else:
        print("Usage: config-markdown [-u|-t]")
        print("Options:\n  -u  Generate user documentation\n  -t  Generate technical documentation")

if __name__ == "__main__":
    main()
