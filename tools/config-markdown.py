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

def format_container_badge(item):
    """Generate a badge for container-based software"""
    container_type = item.get('container_type')

    if not container_type:
        return ""

    colors = {
	"docker": ("#ffffff", "#039BE5", "🐳"),
	"podman": ("#ffffff", "#3B4C6C", "🐳"),
	"lxc":    ("#ffffff", "#00A8E1", "📦"),
	"kvm":    ("#ffffff", "#E95420", "💿"),
    }

    bg, fg, icon = colors.get(container_type, ("#757575", "#ffffff", "🐳"))

    label_template = '<span style="background-color:{bg}; color:{fg}; padding:3px 6px; border-radius:4px; font-size:90%;">{icon} {type}</span>'
    return label_template.format(
        bg=bg,
        fg=fg,
        icon=icon,
        type=container_type.capitalize()
    )

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
            parts.append(f"![{item.get('short', item.get('description', ''))}](/images/{item['id']}.{ext})")
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

    if item.get('command') and not skip_commands:
        cmd = item['command'][0] if isinstance(item['command'], list) else item['command']
        md.append(f"\n~~~ bash\narmbian-config --cmd {item['id']}\n~~~\n")

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
                    first_sub = False

                if sub_item.get('command'):
                    cmd = sub_item['command'][0] if isinstance(sub_item['command'], list) else sub_item['command']
                    title = f" title=\"{sub_item.get('short', sub_item.get('description', ''))}\""
                    md.append(f"\n~~~ bash{title}\narmbian-config --cmd {sub_item['id']}\n~~~\n")
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

def slugify(text):
    """netdata -> netdata, 'Uptime Kuma' -> uptime-kuma, NetAlertX -> netalertx."""
    return re.sub(r'[^a-z0-9]+', '-', (text or '').lower()).strip('-')


def yaml_quote(text):
    """Double-quote a value for YAML front-matter. mkdocs parses front-matter as
    YAML, where an unquoted scalar containing ': ' (colon-space) is read as a
    nested mapping and the value is lost — so titles/descriptions MUST be quoted."""
    return '"' + str(text).replace('\\', '\\\\').replace('"', '\\"') + '"'


def _group_key(item):
    """Identity that ties an app's install/remove/purge items together: the
    module referenced by the item's command (e.g. `module_qbittorrent install`
    -> module_qbittorrent). Grouping on the module (rather than an id prefix)
    keeps distinct apps apart even if their ids share a prefix, while still
    grouping an app's own actions. Falls back to the item id so unrelated
    generic-command items never merge."""
    cmd = item.get('command')
    cmd = (cmd[0] if isinstance(cmd, list) else cmd) or ''
    m = re.search(r'module_[A-Za-z0-9_-]+', cmd)
    return m.group(0) if m else item.get('id', '')


def group_software(sub_items):
    """Split a category's flat `sub` list into per-software groups, one group per
    app (keyed by its command module via _group_key). The name-bearing item
    leads each group; its remove/purge actions follow. Returns a list of groups."""
    order, groups = [], {}
    for it in sub_items:
        key = _group_key(it)
        if key not in groups:
            groups[key] = []
            order.append(key)
        groups[key].append(it)
    result = []
    for key in order:
        g = groups[key]
        if not g[0].get('short'):   # lead with the name-bearing (install) item
            lead = next((i for i in g if i.get('short')), None)
            if lead:
                g = [lead] + [x for x in g if x is not lead]
        if g[0].get('short'):
            result.append(g)
    return result


def _blurb(item_id):
    """First real sentence of an app's header/footer markdown, for when the JSON
    description is just the app name. Strips HTML comments and edit/meta lines."""
    for section in ('header', 'footer'):
        f = MARKDOWN_DIR / f"{item_id}-{section}.md"
        if not f.is_file():
            continue
        text = re.sub(r'<!--.*?-->', '', f.read_text(), flags=re.DOTALL)
        lines = [ln.strip() for ln in text.splitlines()
                 if ln.strip() and not ln.strip().startswith(('__', '#', '!', '['))]
        if not lines:
            continue
        # first *declarative* sentence (skip a rhetorical "What is X?" lead-in)
        for sentence in re.split(r'(?<=[.!?])\s', ' '.join(lines)):
            sentence = sentence.strip()
            if len(sentence) > 20 and not sentence.endswith('?'):
                return sentence[:160].rstrip()
    return None


def _page_image_path(item):
    """Return the site-absolute path of the item's logo, or None."""
    for ext in ('png', 'webp'):
        if (IMAGES_DIR / f"{item['id']}.{ext}").is_file():
            return f"/images/{item['id']}.{ext}"
    return None


def render_software_page(group, category):
    """One installable app -> a standalone page keyed by its slug, with SEO
    front-matter (title + description + og image) pulled from the JSON entry
    that already exists. The body reuses the normal per-software rendering."""
    install = group[0]
    short = install.get('short') or install.get('description') or install['id']
    slug = slugify(short)
    desc = (install.get('description') or short).strip().rstrip('.')
    # drop a redundant leading app name ("Netdata - monitoring..." -> "monitoring...")
    desc = re.sub(rf'^{re.escape(short)}\s*[-–:]\s*', '', desc, flags=re.IGNORECASE).strip()
    # when the JSON description is just the app name, borrow the header/footer blurb
    if not desc or desc.lower() == short.lower():
        desc = _blurb(install['id']) or short

    # Keyword-bearing description: the app name + what it is + the platform.
    # People search "install <app> <board> arm64", not the category name.
    meta_desc = f"Install and run {short} on Armbian — {desc.rstrip('.')}. Runs on ARM64 and x86 single-board computers."

    fm = ['---', f"title: {yaml_quote(short)}", f"description: {yaml_quote(meta_desc)}"]
    img = _page_image_path(install)
    if img:
        fm.append(f"image: {img}")
    # Category id ties the page to its section in the left nav (the docs repo
    # groups app pages under their category from this field) and to the hub page.
    fm.append(f"category: {yaml_quote(category['id'])}")
    fm += ['comments: true', '---', '']

    body = [f"# {short}\n"]
    # Show one description: the fuller header blurb is rendered inside the group;
    # only add the short JSON line when there is no header file (avoids the
    # "monitoring real-time metrics" + full-paragraph duplication).
    has_header = (MARKDOWN_DIR / f"{install['id']}-header.md").is_file()
    if not has_header and desc and desc.lower() != short.lower():
        body.append(f"\n{desc}\n")
    cat_short = re.sub(r'(?<=[a-z])(?=[A-Z])', ' ', category['id'])
    menu_path = f"Software → {cat_short} → {short}"
    body.append(render_software_group(group, level=1, with_title=False, menu_path=menu_path))

    # Simple category back-link (plain text, no heading — so it doesn't add a
    # TOC entry). The category's other apps are already in the left nav.
    cat_name = category.get('description', category['id'])
    body.append(f"\n---\n\n_Part of Armbian's [{cat_name}](/User-Guide_Armbian-Software/{category['id']}/) software._")
    return slug, '\n'.join(fm) + '\n'.join(body) + '\n'


def render_category_index(category):
    """A category page becomes an internal-linking hub: a short intro plus a
    list that links out to each app's own page, instead of a wall of anchors."""
    cat_desc = category.get('description', category['id'])
    # short label for the nav / <title> ("HomeAutomation" -> "Home Automation");
    # the descriptive sentence stays as the page H1 below.
    cat_short = re.sub(r'(?<=[a-z])(?=[A-Z])', ' ', category['id'])
    groups = group_software(category.get('sub', []))
    meta_desc = f"{cat_desc} for Armbian on ARM64 and x86 single-board computers: " \
                + ", ".join(g[0]['short'] for g in groups) + "."
    fm = ['---', f"title: {yaml_quote(cat_short)}", f"description: {yaml_quote(meta_desc[:180])}", 'comments: true', '---', '']
    md = [f"# {cat_desc}\n"]
    md.extend(insert_images_and_header(category))
    md.append("\nInstall and configure these applications through "
              "[`armbian-config`](/armbian-config/) or from the pages below:\n")
    for g in groups:
        short = g[0]['short']
        one_liner = (g[0].get('description') or short).strip().rstrip('.')
        md.append(f"- [{short}](/software/{slugify(short)}/) — {one_liner}")
    return '\n'.join(fm) + '\n'.join(md) + '\n'


def _footer_md(item_id):
    """The included footer block for a command, or ''."""
    f = MARKDOWN_DIR / f"{item_id}-footer.md"
    if not f.is_file():
        return ""
    rel = f"tools/include/markdown/{item_id}-footer.md"
    return f"\n<!--- footer START from {rel} --->\n{f.read_text()}\n<!--- footer STOP from {rel} --->\n"


def _image_md(item):
    """Just the logo image (split out so a facts bar can sit under it), or ''."""
    for ext in ('png', 'webp'):
        if (IMAGES_DIR / f"{item['id']}.{ext}").is_file():
            rel = f"tools/include/images/{item['id']}.{ext}"
            alt = item.get('short', item.get('description', ''))
            return (f"\n<!--- section image START from {rel} --->\n"
                    f"![{alt}](/images/{item['id']}.{ext})\n"
                    f"<!--- section image STOP from {rel} --->\n")
    return ""


def _header_blurb_md(item):
    """Just the header description block, or ''."""
    f = MARKDOWN_DIR / f"{item['id']}-header.md"
    if not f.is_file():
        return ""
    rel = f"tools/include/markdown/{item['id']}-header.md"
    return f"\n<!--- header START from {rel} --->\n{f.read_text()}\n<!--- header STOP from {rel} --->\n"


def render_software_group(sub_items, level=1, with_title=True, menu_path=None):
    """Render one app: logo + description, then an action-first layout — the
    install command (with an armbian-config menu-path hint) comes first, the
    Status/Architecture/Maintainer metadata sits below it, and remove/purge
    follow. `with_title=False` skips the H1 (the page adds its own); `menu_path`
    (e.g. "Software → Monitoring → Netdata") drives the hint line."""
    lead = sub_items[0]
    md = []
    if with_title:
        md.append(f"{'#' * level} {lead.get('short', lead.get('description', ''))}\n")
        if lead.get('short') and lead.get('description') and lead.get('short') != lead.get('description'):
            md.append(f"\n{lead.get('description')}\n")

    md.append(_image_md(lead))   # logo

    # Iconized one-line facts bar, directly under the logo. Only the facts that
    # help someone decide/use: hardware it runs on, how it is packaged, where
    # the docs are, and how to reach it. Each icon carries a hover title.
    meta = []
    module = lead.get('module')
    opts = module_options.get(module, {})
    if opts.get('arch'):
        meta.append(f':material-cpu-64-bit:{{ title="Architecture" }} {format_arch_labels(opts["arch"])}')
    badge = format_container_badge(lead)
    if badge:
        meta.append(badge)
    if opts.get('doc_link'):
        meta.append(f':material-book-open-variant:{{ title="Documentation" }} [Documentation]({opts["doc_link"]})')
    ports = (opts.get('port') or '').split()
    if ports:
        scheme = opts.get('protocol', 'http')   # http default; https / redis / postgresql / ...
        # only the first port — the web / main protocol; extra ports (sync,
        # discovery, ...) just clutter the one-line facts bar.
        meta.append(f':material-lan-connect:{{ title="Access port" }} '
                    f'`{scheme}://<your.IP>:{ports[0]}`')
    if meta:
        md.append('\n' + ' · '.join(meta) + '\n')

    md.append(_header_blurb_md(lead))   # description

    def api_cmd(item):
        # Machine/API form: `armbian-config --api <helper>` runs the helper
        # directly (e.g. "module_netdata install") — readable and scriptable,
        # unlike the opaque menu id used by `--cmd`.
        c = item['command']
        return (c[0] if isinstance(c, list) else c).strip()

    def action_label(item):
        # Human label for the commands table. Prefer the item description; for
        # the install action (a plain "install") just say "Install"; fall back
        # to the command's action word (server/client/qrcode/...).
        cmd = api_cmd(item)
        arg = cmd.split(None, 1)[1].strip() if ' ' in cmd else ''
        if arg == 'install':
            return 'Install'
        desc = (item.get('description') or '').strip()
        short = item.get('short') or ''
        if desc and desc.lower() != short.lower():
            return desc
        return (arg or short).replace('_', ' ').strip().capitalize() or 'Run'

    cmd_items = [s for s in sub_items if s.get('command')]

    app_short = lead.get('short') or lead.get('description') or lead['id']

    # install (first command) — with a friendly menu path, then the metadata
    if cmd_items:
        install = cmd_items[0]
        iarg = api_cmd(install).split(None, 1)[1].strip() if ' ' in api_cmd(install) else ''
        ititle = "CLI install" if iarg == 'install' else action_label(install)
        if menu_path:
            md.append(f"\nInstall from **[armbian-config](/armbian-config/) → {menu_path}**")
        md.append(f"\n~~~ custombash title=\"{ititle}\"\narmbian-config --cmd {install['id']}\n~~~\n")
        md.append(_footer_md(install['id']))

    # The module's full command surface — read from its own `example` list
    # (exactly what `armbian-config --api <module> help` prints), not just the
    # menu's install/remove/purge subset. Label with the richer menu
    # descriptions where we have them; fall back to the subcommand name.
    module = lead.get('module')
    opts = module_options.get(module, {})
    fn = opts.get('feature') or module
    subcmds = opts.get('example', '').split()
    menu_label = {}
    for s in cmd_items:
        parts = api_cmd(s).split(None, 1)
        if len(parts) > 1:
            menu_label[parts[1].strip()] = action_label(s)
    if fn and subcmds:
        md.append("\n**All `armbian-config` commands**\n")
        md.append("| Action | Command |")
        md.append("| --- | --- |")
        for sub in subcmds:
            label = menu_label.get(sub) or sub.capitalize()
            md.append(f"| {label} | `armbian-config --api {fn} {sub}` |")
    elif len(cmd_items) > 1:   # module has no `example` list — use the menu items
        md.append("\n**All `armbian-config` commands**\n")
        md.append("| Action | Command |")
        md.append("| --- | --- |")
        for s in cmd_items:
            md.append(f"| {action_label(s)} | `armbian-config --api {api_cmd(s)}` |")

    return '\n'.join(x for x in md if x)


# Top-level menu id whose sub-categories are public "software" (SEO) pages.
SOFTWARE_TOP_ID = "Software"


def write_software_section(top):
    """Emit, for the Software section: a per-app page docs/software/<slug>.md
    (SEO front-matter, own URL) for every installable app, plus each category
    page rewritten as a link hub. Returns the app page count."""
    cat_dir = DOCS_DIR / top['id']
    cat_dir.mkdir(parents=True, exist_ok=True)
    apps_dir = DOCS_DIR / 'software'
    apps_dir.mkdir(parents=True, exist_ok=True)
    # clear stale app pages so a renamed/removed slug does not linger as an orphan
    for old in apps_dir.glob('*.md'):
        old.unlink()

    # keep the section overview page as-is (still rsynced/linked)
    (cat_dir / f"{top['id']}.md").write_text('---\ncomments: true\n---\n\n' + create_markdown_user(top))

    count = 0
    for category in top.get('sub', []):
        (cat_dir / f"{category['id']}.md").write_text(render_category_index(category))
        for group in group_software(category.get('sub', [])):
            slug, page = render_software_page(group, category)
            (apps_dir / f"{slug}.md").write_text(page)
            count += 1
    return count


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
        # The Software section is published as per-app pages (own URL + SEO
        # front-matter) with category pages as link hubs; everything else keeps
        # the original single-page-per-category layout.
        if item['id'] == SOFTWARE_TOP_ID:
            n = write_software_section(item)
            print(f"Software section: {n} per-app pages + {len(item.get('sub', []))} category hubs.")
            continue
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
