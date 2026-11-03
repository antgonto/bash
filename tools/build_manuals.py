#!/usr/bin/env python3
"""build_manuals.py — build the per-lab PDF manuals (Student and Instructor versions).

    python3 tools/build_manuals.py            # all labs → manuals/student/*.pdf, manuals/instructor/*.pdf
    python3 tools/build_manuals.py lab5       # one lab (any substring of the source file name)
    python3 tools/build_manuals.py --html     # also keep the intermediate HTML next to the PDFs

Sources: manuals/src/*.md — Markdown in the Cisco Networking Academy lab format, with two
extra block types:

    :::instructor            instructor-only prose/code (removed from the Student version;
    ...                      shown in the Instructor version on a gray background)
    :::

    :::answer                instructor-only answer to the question just above it
    ...
    :::

Front matter (YAML-ish, first block of the file):
    title, lab (folder under labs/), module, graded, time, files (comma list: name=role).
"""
import re, sys, os, pathlib, html, json, subprocess, datetime
import markdown

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "manuals" / "src"
OUT = ROOT / "manuals"
COURSE = "Course 0 — Bash Scripting · SecMLOps Program"
YEAR = datetime.date.today().year

CSS = r"""
html, body { margin: 0; padding: 0; }
body { font-family: "Liberation Sans", Arial, Helvetica, sans-serif; font-size: 10.5pt; color: #111; line-height: 1.32; }
.page { padding: 0; }
h1.title { font-size: 17pt; font-weight: bold; margin: 0 0 4pt 0; line-height: 1.25; }
h1.title .ver { color: #c00; font-weight: normal; }
p.instr-note { color: #c00; font-weight: bold; margin: 0 0 10pt 0; font-size: 10pt; }
p.instr-note span { font-weight: normal; }
h2 { font-size: 13.5pt; font-weight: bold; margin: 16pt 0 6pt 0; page-break-after: avoid; }
h3 { font-size: 11.5pt; font-weight: bold; margin: 12pt 0 4pt 0; page-break-after: avoid; }
h4 { font-size: 10.5pt; font-weight: bold; margin: 10pt 0 3pt 0; }
h2.part { font-size: 14pt; }
p, li { margin: 0 0 5pt 0; }
.body > p, .body > ul, .body > ol, .body > pre, .body > table, .body > div.instr, .body > div.answer, .body > div.svg { margin-left: 18pt; }
ul, ol { padding-left: 20pt; }
li > ul, li > ol { margin-top: 3pt; }
code { font-family: "Liberation Mono", "Courier New", monospace; font-size: 9.5pt; }
pre { font-family: "Liberation Mono", "Courier New", monospace; font-size: 9pt; line-height: 1.3; margin: 4pt 0 8pt 0; padding: 0 0 0 10pt; white-space: pre-wrap; word-break: break-all; }
pre code { font-size: 9pt; }
table { border-collapse: collapse; margin: 6pt 0 10pt 0; width: 100%; font-size: 9.5pt; page-break-inside: avoid; table-layout: auto; }
.body > table { width: calc(100% - 18pt); }
td code, th code { word-break: break-all; overflow-wrap: anywhere; }
td, th { overflow-wrap: break-word; }
td:first-child, th:first-child { width: 24%; }
table code { font-size: 8.5pt; }
th, td { border: 1px solid #555; padding: 3pt 6pt; vertical-align: top; text-align: left; }
th { background: #e8e8ec; font-weight: bold; }
.instr, .answer { background: #e6e6e6; padding: 6pt 8pt; margin: 6pt 0 10pt 0; border-left: 3px solid #999; page-break-inside: avoid; }
.instr > :last-child, .answer > :last-child { margin-bottom: 0; }
.instr .lbl, .answer .lbl { color: #c00; font-weight: bold; }
.instr pre, .answer pre { background: #d8d8d8; padding: 4pt 6pt; }
.expected { margin: 2pt 0 8pt 0; }
.expected b { font-weight: bold; }
blockquote { margin: 6pt 0 8pt 0; padding: 4pt 10pt; border-left: 3px solid #bbb; background: #f5f5f5; }
blockquote p { margin: 0 0 3pt 0; }
.svg { margin: 6pt 0 10pt 0; }
hr { border: 0; border-top: 1px solid #999; margin: 12pt 0; }
.toc { display: none; }
strong.q { font-weight: bold; }
.nobreak { page-break-inside: avoid; }
"""

def parse_front(text):
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    meta = {}
    if m:
        for line in m.group(1).splitlines():
            if ":" in line:
                k, v = line.split(":", 1); meta[k.strip()] = v.strip()
        text = text[m.end():]
    return meta, text

def split_blocks(text, keep_instructor):
    """Resolve :::instructor / :::answer blocks. Returns markdown with HTML wrappers."""
    out = []
    i = 0
    lines = text.split("\n")
    while i < len(lines):
        ln = lines[i]
        m = re.match(r"^:::(instructor|answer)\s*$", ln)
        if m:
            kind = m.group(1); j = i + 1; body = []
            while j < len(lines) and lines[j].strip() != ":::":
                body.append(lines[j]); j += 1
            if keep_instructor:
                label = "Instructor Note:" if kind == "instructor" else "Answer:"
                inner = markdown.markdown("\n".join(body), extensions=["tables", "fenced_code", "sane_lists"])
                # put the label inside the first paragraph if there is one
                if inner.startswith("<p>"):
                    inner = '<p><span class="lbl">%s</span> ' % label + inner[3:]
                else:
                    inner = '<p><span class="lbl">%s</span></p>' % label + inner
                out.append('<div class="%s" markdown="0">%s</div>' % ("instr" if kind == "instructor" else "answer", inner))
            i = j + 1
            continue
        out.append(ln); i += 1
    return "\n".join(out)

def topology_svg(meta):
    """A small diagram of the lab folder: starter → work (you edit) → grade.sh → verdict; lab.sh demo."""
    lab = meta.get("lab", "labN")
    files = [f.strip() for f in meta.get("files", "").split(",") if f.strip()]
    main = files[0].split("=")[0] if files else "file"
    w, h = 640, 150
    def box(x, y, bw, bh, lines, fill="#f4f4f4"):
        s = f'<rect x="{x}" y="{y}" width="{bw}" height="{bh}" rx="4" ry="4" fill="{fill}" stroke="#333" stroke-width="1"/>'
        for k, t in enumerate(lines):
            s += f'<text x="{x+bw/2}" y="{y+18+k*14}" font-family="Liberation Sans, Arial" font-size="11" text-anchor="middle" fill="#111">{html.escape(t)}</text>'
        return s
    def arrow(x1, y1, x2, y2, label=""):
        s = f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="#333" stroke-width="1.2" marker-end="url(#ah)"/>'
        if label:
            s += f'<text x="{(x1+x2)/2}" y="{min(y1,y2)-6}" font-family="Liberation Sans, Arial" font-size="9.5" text-anchor="middle" fill="#333">{html.escape(label)}</text>'
        return s
    svg = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">',
           '<defs><marker id="ah" markerWidth="8" markerHeight="8" refX="7" refY="4" orient="auto"><path d="M0,0 L8,4 L0,8 z" fill="#333"/></marker></defs>',
           f'<text x="8" y="14" font-family="Liberation Sans, Arial" font-size="10" fill="#333">labs/{html.escape(lab)}/</text>']
    svg.append(box(10, 28, 150, 52, ["exercise/starter/", main, "(the # TODOs)"]))
    svg.append(arrow(160, 54, 230, 54, "copied once"))
    svg.append(box(230, 28, 150, 52, ["exercise/work/", main, "(you edit here)"], "#fff8d8"))
    svg.append(arrow(380, 54, 450, 54, "bash grade.sh"))
    svg.append(box(450, 28, 180, 52, ["grade.sh", "---- lab: P passed, F failed ----", "re-run until F = 0"]))
    svg.append(box(10, 98, 150, 42, ["lab.sh", "the worked demonstration"]))
    svg.append(arrow(160, 119, 230, 119, "bash lab.sh"))
    svg.append(box(230, 98, 400, 42, ["runs this module's concepts on the fixture logs and asserts the results", "(read it; it is the model for your exercise)"]))
    svg.append("</svg>")
    return '<div class="svg">' + "".join(svg) + "</div>"

def render(md_path, keep_instructor):
    raw = md_path.read_text(encoding="utf-8")
    meta, body = parse_front(raw)
    body = body.replace("{{TOPOLOGY}}", topology_svg(meta))
    body = split_blocks(body, keep_instructor)
    h = markdown.markdown(body, extensions=["tables", "fenced_code", "sane_lists", "md_in_html"])
    # Part / Step headings: style
    h = re.sub(r"<h2>(Part \d+:)", r'<h2 class="part">\1', h)
    title = meta.get("title", md_path.stem)
    ver = " (Instructor Version)" if keep_instructor else ""
    note = ('<p class="instr-note">Instructor Note: <span>Gray boxes and answers marked in red appear in the instructor copy only.</span></p>'
            if keep_instructor else "")
    doc = f"""<!doctype html><html><head><meta charset="utf-8"><title>{html.escape(title)}{ver}</title><style>{CSS}</style></head>
<body><div class="page"><h1 class="title">{html.escape(title)}<span class="ver">{html.escape(ver)}</span></h1>{note}<div class="body">{h}</div></div></body></html>"""
    return meta, doc

def to_pdf(html_path, pdf_path, title):
    js = r"""
const { chromium } = require('playwright');
(async () => {
  const [,, src, dst, header, footer] = process.argv;
  const b = await chromium.launch(); const p = await b.newPage();
  await p.goto('file://' + src, { waitUntil: 'load' });
  await p.pdf({ path: dst, format: 'Letter', printBackground: true, displayHeaderFooter: true,
    headerTemplate: header, footerTemplate: footer,
    margin: { top: '0.85in', bottom: '0.7in', left: '0.75in', right: '0.75in' } });
  await b.close();
})();
"""
    header = ('<div style="width:100%;font-family:Liberation Sans,Arial;font-size:8.5pt;color:#222;padding:0 0.75in;'
              'border-bottom:2px solid #333;margin:0 0.75in;padding-bottom:3pt;display:flex;justify-content:space-between;">'
              f'<span style="font-weight:bold;max-width:62%">{html.escape(title)}</span><span style="max-width:36%;text-align:right">{html.escape(COURSE)}</span></div>')
    footer = ('<div style="width:100%;font-family:Liberation Sans,Arial;font-size:8pt;color:#222;margin:0 0.75in;display:flex;justify-content:space-between;">'
              f'<span>© {YEAR} SecMLOps · Course 0 — Bash Scripting. Course material; not for redistribution outside the course.</span>'
              '<span>Page <span class="pageNumber"></span> of <span class="totalPages"></span></span></div>')
    script = OUT / ".pdf.js"; script.write_text(js)
    subprocess.run(["node", str(script), str(html_path), str(pdf_path), header, footer], check=True)

def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    keep_html = "--html" in sys.argv
    srcs = sorted(SRC.glob("*.md"))
    if args:
        srcs = [s for s in srcs if any(a in s.name for a in args)]
    (OUT / "student").mkdir(parents=True, exist_ok=True)
    (OUT / "instructor").mkdir(parents=True, exist_ok=True)
    for s in srcs:
        for kind, keep in (("student", False), ("instructor", True)):
            meta, doc = render(s, keep)
            base = s.stem + ("" if kind == "student" else "-instructor")
            hp = OUT / kind / (base + ".html"); pp = OUT / kind / (base + ".pdf")
            hp.write_text(doc, encoding="utf-8")
            to_pdf(hp, pp, meta.get("title", s.stem) + (" (Instructor Version)" if keep else ""))
            if not keep_html: hp.unlink()
            print(f"{kind:10s} {pp.relative_to(ROOT)}")
    (OUT / ".pdf.js").unlink(missing_ok=True)

if __name__ == "__main__":
    main()
