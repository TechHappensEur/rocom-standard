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

# Strip comment-header lines, pandoc convert
clean = raw
for pat in [r'^# FILE:.*', r'^# ===.*', r'^# Status:.*', r'^# License:.*']:
    clean = re.sub(pat, '', clean, flags=re.M)
clean = re.sub(r'\n{3,}', '\n\n', clean)
try:
    result = subprocess.run(
        ['pandoc', '-f', 'markdown', '-t', 'html', '--wrap=none'],
        input=clean, capture_output=True, text=True, check=True
    )
    body = result.stdout
except Exception:
    body = clean.replace('\n', '<br>')

# Build nested TOC from headings (DICOM-style)
def build_toc(html_body):
    headings = re.findall(r'<h([1-6])(?:\s[^>]*)?>(.*?)</h\1>', html_body, re.DOTALL)
    if len(headings) < 2:
        return ''
    def clean_text(t):
        return re.sub(r'<[^>]+>', '', t).strip()
    def make_slug(t):
        s = re.sub(r'[^\w\s-]', '', t[:60]).lower()
        return '-'.join(s.split())
    # Compute depth relative to shallowest heading
    levels = [int(l) for l, _ in headings]
    base = min(levels)
    items = [(int(lvl) - base, make_slug(clean_text(txt)), clean_text(txt)) for lvl, txt in headings]
    # Simple renderer: track current depth, emit open/close as needed
    out = ['<div class="toc"><div class="toc-title">Contents</div>']
    cur_depth = -1
    prev_depth = -1
    for i, (depth, slug, txt) in enumerate(items):
        # Going deeper: open new <ul> for each level
        while cur_depth < depth:
            out.append('<ul>')
            cur_depth += 1
        # Going shallower: close </li></ul> for each level, then close parent <li>
        while cur_depth > depth:
            out.append('</li></ul>')
            cur_depth -= 1
            if depth >= 0:
                out.append('</li>')
        # Same level as previous: close previous <li>
        if i > 0 and depth == prev_depth:
            out.append('</li>')
        out.append(f'<li><a href="#{slug}">{txt}</a>')
        prev_depth = depth
    # Close remaining open lists
    while cur_depth >= 0:
        out.append('</li></ul>')
        cur_depth -= 1
    out.append('</div>')
    return ''.join(out)

toc = build_toc(body)

# Doc-meta block
meta = ''
if status and lic:
    badge = 'DRAFT'
    cls = 'badge-draft'
    if any(w in status.lower() for w in ('final', 'published')):
        badge = 'FINAL'
        cls = 'badge-final'
    meta = (
        f"<div class='doc-meta'>"
        f"<strong>Document:</strong> {title} &nbsp;"
        f"<span class='badge {cls}'>{badge}</span>"
        f"<br><strong>Status:</strong> {status}"
        f"<br><strong>License:</strong> {lic}"
        f"</div>"
    )

# Read template and substitute
with open(template) as f:
    tpl = f.read()

content = meta + toc + '<div class="content">' + body + '</div>'
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

# Principles & Architecture
[ -f "$REPO_DIR/docs/principles-and-architecture/PRINCIPLES.md" ] && convert_md "$REPO_DIR/docs/principles-and-architecture/PRINCIPLES.md" "principles.html" && echo "  principles.html"

# YAML modules page — render as formatted requirement tables
python3 - "$REPO_DIR" "$OUTPUT_DIR" "$TEMPLATE" << 'PYEOF'
import sys, os, glob, re, subprocess
repo_dir, output_dir, template = sys.argv[1:]

def html_esc(s):
    return str(s).replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;').replace('"', '&quot;')

def render_principles(principles):
    if not principles:
        return ''
    rows = ''
    for p in principles:
        pid = html_esc(p.get('id', ''))
        stmt = html_esc(p.get('statement', ''))
        rows += f'<tr><td><code>{pid}</code></td><td>{stmt}</td></tr>\n'
    return f'<table><thead><tr><th style="width:140px">ID</th><th>Principle</th></tr></thead><tbody>\n{rows}</tbody></table>'

def render_requirements(reqs):
    if not reqs:
        return ''
    # Group by level
    by_level = {}
    for r in reqs:
        lvl = r.get('level', 'unknown')
        by_level.setdefault(lvl, []).append(r)
    level_names = {'L1': 'L1 — Pilot / Lab', 'L2': 'L2 — Production Single Site', 'L3': 'L3 — Production Multi-Site', 'L1+': 'All Levels'}
    sections = ''
    for lvl in ['L1', 'L2', 'L3', 'L1+']:
        items = by_level.get(lvl, [])
        if not items:
            continue
        rows = ''
        for r in items:
            rid = html_esc(r.get('id', ''))
            stmt = html_esc(r.get('statement', ''))
            ver = html_esc(r.get('verification', ''))
            rows += f'<tr><td><code>{rid}</code></td><td>{stmt}</td><td><small>{ver}</small></td></tr>\n'
        lbl = level_names.get(lvl, lvl)
        sections += f'<h3>{lbl}</h3>\n<table><thead><tr><th style="width:110px">ID</th><th>Requirement</th><th style="width:200px">Verification</th></tr></thead><tbody>\n{rows}</tbody></table>\n'
    return sections

content = "<div class='doc-meta'><strong>Specification Modules</strong> — YAML modules rendered as requirement tables.</div><div class='content'>"
for yp in sorted(glob.glob(os.path.join(repo_dir, 'spec', 'part-*', '*.yaml'))):
    yn = os.path.basename(yp)
    lp = os.path.basename(os.path.dirname(yp))
    with open(yp) as f:
        raw = f.read()
    # Strip comment headers for pandoc
    clean = raw
    for pat in [r'^# FILE:.*', r'^# ===.*', r'^# Status:.*', r'^# License:.*', r'^# Scope:.*', r'^# NOTE:.*']:
        clean = re.sub(pat, '', clean, flags=re.M)
    # Try to render intro text via pandoc
    intro = ''
    try:
        result = subprocess.run(['pandoc', '-f', 'markdown', '-t', 'html', '--wrap=none'],
            input=clean[:500], capture_output=True, text=True, check=True)
        intro = result.stdout.strip()
    except:
        pass
    # Parse YAML for tables
    import yaml
    try:
        data = yaml.safe_load(raw)
    except:
        data = {}
    content += f'<h2>{html_esc(lp)}: {html_esc(yn)}</h2>\n'
    if intro:
        content += intro + '\n'
    content += render_principles(data.get('principals', data.get('principles', [])))
    content += render_requirements(data.get('requirements', []))
    # Data classes table
    if data.get('data_classes'):
        rows = ''
        for dc in data['data_classes']:
            c = html_esc(dc.get('class', ''))
            d = html_esc(dc.get('definition', ''))
            pd = html_esc(dc.get('personal_data', ''))
            rows += f'<tr><td><strong>{c}</strong></td><td>{d}</td><td>{pd}</td></tr>\n'
        content += f'<h3>Data Classes</h3>\n<table><thead><tr><th>Class</th><th>Definition</th><th>Personal Data?</th></tr></thead><tbody>\n{rows}</tbody></table>\n'
    # Regulatory mapping
    if data.get('regulatory_mapping'):
        rows = ''
        for rm in data['regulatory_mapping']:
            reg = html_esc(rm.get('regime', ''))
            rel = html_esc(rm.get('relevance', ''))
            rows += f'<tr><td><strong>{reg}</strong></td><td>{rel}</td></tr>\n'
        content += f'<h3>Regulatory Mapping</h3>\n<table><thead><tr><th>Regime</th><th>Relevance</th></tr></thead><tbody>\n{rows}</tbody></table>\n'
    content += '<hr/>\n'
content += '</div>'

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
content = "<div class='doc-meta'><strong>Supplementary Documents</strong></div><div class='content'>"
if supps:
    content += '<ul>'
    for sp in supps:
        sn = os.path.basename(sp).replace('.md', '')
        content += f'<li><a href="supplement-{sn}.html">{sn}</a></li>'
    content += '</ul>'
else:
    content += '<p>No supplementary documents yet.</p>'
content += '</div>'

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
        cls = 'badge-draft'
        if any(w in status.lower() for w in ('final', 'published')):
            badge = 'FINAL'
            cls = 'badge-final'
        meta = (
            f"<div class='doc-meta'>"
            f"<strong>Document:</strong> {title} &nbsp;"
            f"<span class='badge {cls}'>{badge}</span>"
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

    full_content = meta + '<div class="content">' + body + '</div>'
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
