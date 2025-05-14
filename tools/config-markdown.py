#!/usr/bin/env python3

import os
import sys
import json
import argparse
import re
from pathlib import Path

def extract_module_options_from_sh_files(directory):
    module_options = {}

    sh_files = Path(directory).glob("*.sh")
    pattern = re.compile(r'\[\s*"(?P<module>[^"]+?),(?P<key>[^"]+?)"\s*\]\s*=\s*"(?P<value>[^"]*?)"')

    for sh_file in sh_files:
        with open(sh_file, 'r', encoding='utf-8') as f:
            content = f.read()
            for match in pattern.finditer(content):
                module = match.group("module")
                key = match.group("key")
                value = match.group("value")

                if module not in module_options:
                    module_options[module] = {}
                module_options[module][key] = value

    return module_options

SCRIPT_DIR = Path(__file__).resolve().parent
CONFIG_PATH = SCRIPT_DIR.parent / 'lib' / 'armbian-config' / 'config.jobs.json'
IMAGES_DIR = SCRIPT_DIR / 'include' / 'images'
MARKDOWN_DIR = SCRIPT_DIR / 'include' / 'markdown'
DOCS_DIR = Path('docs')

module_options = extract_module_options_from_sh_files(str(SCRIPT_DIR.parent / 'lib' / 'armbian-config'))

if not CONFIG_PATH.exists():
    print("Error: The configuration file 'config.jobs.json' was not found.")
    sys.exit(1)

with open(CONFIG_PATH, 'r') as f:
    data = json.load(f)

def format_arch_labels(arch_string):
    colors = {
        "x86-amd64": ("#d0ebff", "#003865"),
        "arm64":     ("#d3f9d8", "#1b5e20"),
        "armhf":     ("#fff3bf", "#7c4d00"),
        "riscv64":   ("#f3d9fa", "#6a1b9a"),
    }
    label_template = '<span style="background-color:{bg}; color:{fg}; padding:3px 6px; border-radius:4px; font-size:90%;">{arch}</span>'
    arches = arch_string.strip().split()
    return " ".join(label_template.format(bg=colors.get(arch, ("#e0e0e0", "#333333"))[0], fg=colors.get(arch, ("#e0e0e0", "#333333"))[1], arch=arch) for arch in arches)

def generate_anchor_links(item, level=0, parent_path=""):
    links = []
    current_id = item['id'].lower()
    indent = '  ' * level
    links.append(f"{indent}- [{item.get('short', item.get('description', ''))}](#{current_id})")
    if 'sub' in item:
        for sub_item in item['sub']:
            links.extend(generate_anchor_links(sub_item, level + 1))
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
        header_prefix = "#" * level
        md.append(f"{header_prefix} {item.get('short', item.get('description', ''))}\n")
        if item.get('short') and item.get('description') and item.get('short') != item.get('description'):
            md.append(f"\n{item.get('description')}\n")
        md.extend(insert_images_and_header(item))

    if show_meta and level == 1:
        if item.get('status'):
            md.append(f"__Status:__ {item['status']}  ")
        if item.get('module'):
            module = item['module']
            if module in module_options:
                architecture = module_options[module].get('arch')
                formatted_arch = format_arch_labels(architecture)
                if formatted_arch:
                    md.append(f"__Architecture:__ {formatted_arch}  ")
                maintainer = module_options[module].get('maintainer')
                if maintainer:
                    md.append(f"__Maintainer:__ {maintainer}  ")
                doc_link = module_options[module].get('doc_link')
                if doc_link:
                    md.append(f"__Documentation:__ [Link]({doc_link})  ")

    if item.get('command') and not skip_commands:
        cmd = item['command'][0] if isinstance(item['command'], list) else item['command']
        md.append(f"\n~~~ custombash\narmbian-config --cmd {item['id']}\n~~~\n")

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
                    header_prefix = "#" * (level + 1)
                    md.append(f"{header_prefix} {sub_item.get('short', sub_item.get('description', ''))}\n")
                    if sub_item.get('short') and sub_item.get('description') and sub_item.get('short') != sub_item.get('description'):
                        md.append(f"\n{sub_item.get('description')}\n")
                    md.extend(insert_images_and_header(sub_item))

                    # Insert unified edit line for header/footer only once
                    base_name = sub_item['id']
                    edit_parts = []
                    for section in ['footer', 'header']:
                        section_filename = f"{base_name}-{section}.md"
                        section_file = Path(__file__).parent / 'include' / 'markdown' / section_filename
                        rel_path = f"tools/include/markdown/{section_filename}"
                        edit_mode = "edit" if section_file.is_file() else "new"
                        url = f"https://github.com/armbian/configng/{edit_mode}/main/{rel_path}"
                        edit_parts.append(f"[{section}]({url})")
                    md.append(f"__Edit:__ {' '.join(edit_parts)}  ")

                    if sub_item.get('status'):
                        md.append(f"__Status:__ {sub_item['status']}  ")
                    module = sub_item.get('module')
                    if module in module_options:
                        arch = module_options[module].get('arch')
                        if arch:
                            md.append(f"__Architecture:__ {format_arch_labels(arch)}  ")
                        maintainer = module_options[module].get('maintainer')
                        if maintainer:
                            md.append(f"__Maintainer:__ {maintainer}  ")
                        doc_link = module_options[module].get('doc_link')
                        if doc_link:
                            md.append(f"__Documentation:__ [Link]({doc_link})  ")
                    first_sub = False

                if sub_item.get('command'):
                    cmd = sub_item['command'][0] if isinstance(sub_item['command'], list) else sub_item['command']
                    fence = "custombash" if first_command else "bash"
                    title = "" if fence == "custombash" else f" title=\"{sub_item.get('short', sub_item.get('description', ''))}:\""
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

if __name__ == "__main__":
    main()
