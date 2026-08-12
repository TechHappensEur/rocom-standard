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
clean = re.sub(r'^# (?:FILE:|===.*)', '', raw, flags=re.M)
try:
    result = subprocess.run(
        ['pandoc', '-f', 'markdown', '-t', 'html', '--standalone=no', '--wrap=none'],
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

# Supplements page
python3 - "$REPO_DIR" "$OUTPUT_DIR" "$TEMPLATE" << 'PYEOF'
import sys, os, glob, re, subprocess
repo_dir, output_dir, template = sys.argv[1:]

content = "<div class='doc-meta'><strong>Supplementary Documents</strong></div>"
for sp in sorted(glob.glob(os.path.join(repo_dir, 'spec', 'supplements', '*.md'))):
    sn = os.path.basename(sp).replace('.md', '')
    with open(sp) as f:
        raw = f.read()
    clean = re.sub(r'^# (?:FILE:|===.*)', '', raw, flags=re.M)
    try:
        result = subprocess.run(
            ['pandoc', '-f', 'markdown', '-t', 'html', '--standalone=no', '--wrap=none'],
            input=clean, capture_output=True, text=True, check=True
        )
        body = result.stdout
    except Exception:
        body = clean
    content += f'<h2>{sn}</h2>{body}<hr/>'

with open(template) as f:
    tpl = f.read()
html = tpl.replace('{{TITLE}}', 'Supplements').replace('{{CONTENT}}', content)
with open(os.path.join(output_dir, 'supplements.html'), 'w') as f:
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
