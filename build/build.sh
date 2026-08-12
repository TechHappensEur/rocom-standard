#!/usr/bin/env bash
set -euo pipefail

OUTPUT_DIR="${1:-_site}"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE="$REPO_DIR/build/template.html"

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

echo "=== Building Rocom spec site ==="

# Convert a single MD file to HTML using template
convert_md() {
  python3 - "$REPO_DIR" "$1" "$2" "$OUTPUT_DIR" "$TEMPLATE" << 'PYEOF'
import sys, subprocess, re, os

repo_dir, src, out, output_dir, template = sys.argv[1:]

with open(src) as f:
    raw = f.read()

# Title from first # heading (skip comment lines like # === or # FILE:)
title = os.path.basename(src).replace('.md', '')
for line in raw.splitlines():
    if line.startswith('# ') and not line.startswith('# ===') and not line.startswith('# FILE:'):
        title = line[2:].strip()
        break

# Status/license from comment headers
status = ''
lic = ''
for line in raw.splitlines():
    if line.startswith('# Status:'):
        status = line[len('# Status:'):].strip()
    if line.startswith('# License:'):
        lic = line[len('# License:'):].strip()

# Doc-meta block
meta = ''
if status and lic:
    badge = 'DRAFT'
    cls = 'status-draft'
    if any(w in status.lower() for w in ('final', 'published')):
        badge = 'FINAL'
        cls = 'status-final'
    meta = (
        f"<div class='doc-meta'>"
        f"<strong>Document:</strong> {title} &nbsp;"
        f"<span class='status-badge {cls}'>{badge}</span>"
        f"<br><strong>Status:</strong> {status}"
        f"<br><strong>License:</strong> {lic}"
        f"</div>"
    )

# Strip comment-header lines, pandoc convert
clean = raw
for pat in [r'^# FILE:.*', r'^# ===.*']:
    clean = re.sub(pat, '', clean, flags=re.M)
clean = re.sub(r'\n{3,}', '\n\n', clean)
try:
    result = subprocess.run(
        ['pandoc', '-f', 'markdown', '-t', 'html', '--wrap=none'],
        input=clean, capture_output=True, text=True, check=True
    )
    body = result.stdout
except Exception:
    # Fallback: basic conversion
    body = clean.replace('\n', '<br>')

# Read template and substitute
with open(template) as f:
    tpl = f.read()

content = meta + '\n' + body if meta else body
html = tpl.replace('{{TITLE}}', title).replace('{{CONTENT}}', content)

with open(os.path.join(output_dir, out), 'w') as f:
    f.write(html)
PYEOF
}

# Index
[ -f "$REPO_DIR/README.md" ]      && convert_md "$REPO_DIR/README.md"      "index.html"       && echo "  index.html"
[ -f "$REPO_DIR/GOVERNANCE.md" ]    && convert_md "$REPO_DIR/GOVERNANCE.md"    "governance.html"  && echo "  governance.html"
[ -f "$REPO_DIR/CONTRIBUTING.md" ]  && convert_md "$REPO_DIR/CONTRIBUTING.md"  "contributing.html" && echo "  contributing.html"

# Spec parts
[ -f "$REPO_DIR/spec/part-01-overview/OVERVIEW.md" ]     && convert_md "$REPO_DIR/spec/part-01-overview/OVERVIEW.md"     "part-01-overview.html"     && echo "  part-01-overview.html"
[ -f "$REPO_DIR/spec/part-01-overview/ARM.md" ]          && convert_md "$REPO_DIR/spec/part-01-overview/ARM.md"          "part-01-arm.html"            && echo "  part-01-arm.html"
[ -f "$REPO_DIR/spec/part-02-conformance/CONFORMANCE.md" ] && convert_md "$REPO_DIR/spec/part-02-conformance/CONFORMANCE.md" "part-02-conformance.html" && echo "  part-02-conformance.html"
[ -f "$REPO_DIR/spec/part-05-transport/PROFILE.md" ]       && convert_md "$REPO_DIR/spec/part-05-transport/PROFILE.md"       "part-05-transport.html"       && echo "  part-05-transport.html"

# YAML modules page
python3 - "$REPO_DIR" "$OUTPUT_DIR" "$TEMPLATE" << 'PYEOF'
import sys, os, glob, re
repo_dir, output_dir, template = sys.argv[1:]

content = "<div class='doc-meta'><strong>YAML Modules</strong> — Specification modules authored in YAML.</div>"
for yp in sorted(glob.glob(os.path.join(repo_dir, 'spec', 'part-*', '*.yaml'))):
    yn = os.path.basename(yp)
    lp = os.path.basename(os.path.dirname(yp))
    with open(yp) as f:
        yml = f.read()
    # Escape HTML
    yml = yml.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
    content += f'<h2>{lp}: {yn}</h2><pre><code>{yml}</code></pre><hr/>'

with open(template) as f:
    tpl = f.read()
html = tpl.replace('{{TITLE}}', 'Specification Modules').replace('{{CONTENT}}', content)
with open(os.path.join(output_dir, 'modules.html'), 'w') as f:
    f.write(html)
PYEOF
echo "  modules.html"

# Supplements page — each gets its own page, plus an index
python3 - "$REPO_DIR" "$OUTPUT_DIR" "$TEMPLATE" << 'PYEOF'
import sys, os, glob, re, subprocess
repo_dir, output_dir, template = sys.argv[1:]

supps = sorted(glob.glob(os.path.join(repo_dir, 'spec', 'supplements', '*.md')))

# Build index page
content = "<div class='doc-meta'><strong>Supplementary Documents</strong></div>"
if supps:
    content += '<ul>'
    for sp in supps:
        sn = os.path.basename(sp).replace('.md', '')
        content += f'<li><a href="supplement-{sn}.html">{sn}</a></li>'
    content += '</ul>'
else:
    content += '<p>No supplementary documents yet.</p>'

with open(template) as f:
    tpl = f.read()
html = tpl.replace('{{TITLE}}', 'Supplements').replace('{{CONTENT}}', content)
with open(os.path.join(output_dir, 'supplements.html'), 'w') as f:
    f.write(html)

# Build individual pages
for sp in supps:
    sn = os.path.basename(sp).replace('.md', '')
    with open(sp) as f:
        raw = f.read()
    # Strip all comment-header lines (# FILE:, # ===, # Sup-xxx, # Status:, # License:, # Scope:, # NOTE:, and indented # lines)
    clean = raw
    for pat in [r'^# FILE:.*', r'^# ===.*', r'^# Status:.*', r'^# License:.*', r'^# Scope:.*', r'^# NOTE:.*', r'^#[A-Z]{3}-\d+.*', r'^#\s+.+']:
        clean = re.sub(pat, '', clean, flags=re.M)
    clean = re.sub(r'\n{3,}', '\n\n', clean)

    # Extract metadata from comment headers
    status = ''
    lic = ''
    for line in raw.splitlines():
        if line.startswith('# Status:'): status = line[len('# Status:'):].strip()
        if line.startswith('# License:'): lic = line[len('# License:'):].strip()

    # Title from comment header (# Sup-001 ...) or filename with dashes replaced
    title = sn.replace('-', ' ').title()
    for line in raw.splitlines():
        if line.startswith('# Sup-') or line.startswith('# sup-'):
            title = line[2:].strip()
            break

    # Doc-meta
    meta = ''
    if status and lic:
        badge = 'PROPOSAL'
        cls = 'status-draft'
        meta = (
            f"<div class='doc-meta'>"
            f"<strong>Document:</strong> {title} &nbsp;"
            f"<span class='status-badge {cls}'>{badge}</span>"
            f"<br><strong>Status:</strong> {status}"
            f"<br><strong>License:</strong> {lic}"
            f"</div>"
        )

    # Convert
    try:
        result = subprocess.run(
        ['pandoc', '-f', 'markdown', '-t', 'html', '--wrap=none'],
            input=clean, capture_output=True, text=True, check=True
        )
        body = result.stdout
    except Exception:
        body = '<pre>' + clean.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;') + '</pre>'

    full_content = (meta + '\n' + body) if meta else body
    with open(template) as f:
        tpl = f.read()
    html = tpl.replace('{{TITLE}}', title).replace('{{CONTENT}}', full_content)
    with open(os.path.join(output_dir, f'supplement-{sn}.html'), 'w') as f:
        f.write(html)
PYEOF
echo "  supplements.html"

# CNAME for custom domain
if [ -f "$REPO_DIR/build/CNAME" ]; then
  cp "$REPO_DIR/build/CNAME" "$OUTPUT_DIR/CNAME"
  echo "  CNAME (custom domain)"
fi

echo ""
echo "Done: $(find "$OUTPUT_DIR" -name '*.html' | wc -l) pages in $OUTPUT_DIR/"
