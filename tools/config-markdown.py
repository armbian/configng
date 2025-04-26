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
    links = []
    current_id = item['id'].lower()
    current_path = f"{parent_path}-{current_id}" if parent_path else current_id
    indent = '  ' * level
    links.append(f"{indent}- [{item.get('short', item.get('description', ''))}](#{current_id})")
    if 'sub' in item:
        for sub_item in item['sub']:
            links.extend(generate_anchor_links(sub_item, level + 1, current_path))
    return links

def insert_images_and_header(item):
    parts = []
    for ext in ('png', 'webp'):
        image_file = Path(__file__).parent / 'include' / 'images' / f"{item['id']}.{ext}"
        if image_file.is_file():
            rel_path = f"tools/include/images/{item['id']}.{ext}"
            parts.append(f"\n<!--- section image START from {rel_path} --->")
            parts.append(f"[![{item.get('short', item.get('description', ''))}](/images/{item['id']}.{ext})](#)")
            parts.append(f"<!--- section image STOP from {rel_path} --->\n")
            break

    header_file = Path(__file__).parent / 'include' / 'markdown' / f"{item['id']}-header.md"
    if header_file.is_file():
        rel_path = f"tools/include/markdown/{item['id']}-header.md"
        parts.append(f"\n<!--- header START from {rel_path} --->")
        parts.append(header_file.read_text())
        parts.append(f"<!--- header STOP from {rel_path} --->\n")

    return parts

def create_markdown_user(item, level=1, show_meta=True, force_title=False, skip_commands=False):
    md = []

    if level == 1 or force_title:
        header_prefix = "#" if level == 1 else "##"
        md.append(f"{header_prefix} {item.get('short', item.get('description', ''))}\n")
        if item.get('short') and item.get('description') and item.get('short') != item.get('description'):
            md.append(f"\n{item.get('description')}\n")
        md.extend(insert_images_and_header(item))

    if show_meta and level == 1:
        if item.get('author'):
            md.append(f"**Author:** {item['author']}\n")
        if item.get('status'):
            md.append(f"**Status:** {item['status']}\n")

    if item.get('command') and not skip_commands:
        first_command = True
        for cmd in item['command']:
            fence = "custombash" if first_command else "bash"
            title = "" if fence == "custombash" else f" title=\"{item.get('short', item.get('description', ''))}:\""
            md.append(f"\n~~~ {fence}{title}\narmbian-config --cmd {item['id']}\n~~~\n")
            first_command = False

        footer_file = Path(__file__).parent / 'include' / 'markdown' / f"{item['id']}-footer.md"
        if footer_file.is_file():
            rel_path = f"tools/include/markdown/{item['id']}-footer.md"
            md.append(f"\n<!--- footer START from {rel_path} --->")
            md.append(footer_file.read_text())
            md.append(f"<!--- footer STOP from {rel_path} --->\n")

    if 'sub' in item:
        grouped_subs = {}
        for sub_item in item['sub']:
            prefix = sub_item['id'][:3].upper()
            grouped_subs.setdefault(prefix, []).append(sub_item)

        for prefix, sub_items in grouped_subs.items():
            first_sub = True
            first_command = True
            for sub_item in sub_items:
                if first_sub:
                    header_prefix = "##"
                    md.append(f"{header_prefix} {sub_item.get('short', sub_item.get('description', ''))}\n")
                    if sub_item.get('short') and sub_item.get('description') and sub_item.get('short') != sub_item.get('description'):
                        md.append(f"\n{sub_item.get('description')}\n")
                    md.extend(insert_images_and_header(sub_item))
                    if sub_item.get('author'):
                        md.append(f"**Author:** {sub_item['author']}\n")
                    if sub_item.get('status'):
                        md.append(f"**Status:** {sub_item['status']}\n")
                    first_sub = False

                if sub_item.get('command'):
                    fence = "custombash" if first_command else "bash"
                    title = "" if fence == "custombash" else f" title=\"{sub_item.get('short', sub_item.get('description', ''))}:\""
                    for cmd in sub_item['command']:
                        md.append(f"\n~~~ {fence}{title}\narmbian-config --cmd {sub_item['id']}\n~~~\n")
                    first_command = False

                    footer_file = Path(__file__).parent / 'include' / 'markdown' / f"{sub_item['id']}-footer.md"
                    if footer_file.is_file():
                        rel_path = f"tools/include/markdown/{sub_item['id']}-footer.md"
                        md.append(f"\n<!--- footer START from {rel_path} --->")
                        md.append(footer_file.read_text())
                        md.append(f"<!--- footer STOP from {rel_path} --->\n")

            for sub_item in sub_items:
                md.append(create_markdown_user(sub_item, level + 2, show_meta=False, force_title=False, skip_commands=True))

    return '\n'.join(md)

def write_technical_markdown_files(data):
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
    DOCS_DIR.mkdir(exist_ok=True)

    for item in data['menu']:
        item_dir = DOCS_DIR / item['id']
        item_dir.mkdir(exist_ok=True)

        user_md = create_markdown_user(item)
        (item_dir / f"{item['id']}.md").write_text('---\ncomments: true\n---\n\n' + user_md)

        if 'sub' in item:
            for sub_item in item['sub']:
                sub_user_md = create_markdown_user(sub_item)
                (item_dir / f"{sub_item['id']}.md").write_text('---\ncomments: true\n---\n\n' + sub_user_md)

def main():
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
