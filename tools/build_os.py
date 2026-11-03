#!/usr/bin/env python3
"""build_os.py — produce one platform edition of the course from the master tree.

    python3 tools/build_os.py --os ubuntu|macos|windows|all --out build/<os>

What it does, in order:
  1. copies the course tree (pages, env, tools, labs, logsleuth, seed, program and the
     top-level scripts) into --out;
  2. resolves <!-- os:X Y --> … <!-- /os --> blocks in every .md file: the block
     body is kept when the target OS is listed (or for 'all'), otherwise removed;
     the marker lines themselves never survive;
  3. applies tools/os-variants.json: every exact 'match' must occur exactly once in
     each listed file (unless optional) and is replaced by the OS text (null = keep;
     "" = delete);
  4. applies the regex variants for the OS (no occurrence check);
  5. regenerates trainer/M01…M09, A10, CAP01 from the resolved student pages and
     callouts with tools/merge_trainer.py (M00 is hand-merged and was resolved in
     step 3 like any other file);
  6. stamps the edition name into README-STUDENT.md / README-TRAINER.md and
     env/README.md and writes build/<os>/EDITION.txt.

The master tree is never modified. Exit status 1 on any unmatched variant.
"""
import argparse, json, os, re, shutil, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EDITIONS = {
    "ubuntu":  ("Ubuntu/Debian edition", "ubuntu"),
    "macos":   ("macOS edition (Intel & Apple Silicon)", "macos"),
    "windows": ("Windows 11 edition (inside WSL 2 Ubuntu)", "windows"),
    "all":     ("all-platform master", "all"),
}
COPY = ["student", "trainer", "env", "README-STUDENT.md", "README-TRAINER.md",
        "BLUEPRINT.md", "CONTINUATION-MANIFEST.md", "tools",
        "labs", "logsleuth", "seed", "program", "manuals", "tools-check.sh", "grade-all.sh", "prove_all.sh"]
MARK = re.compile(r"^<!-- os:([a-z ]+?) -->\n(.*?)^<!-- /os -->\n", re.S | re.M)
INLINE = re.compile(r"<!-- os:([a-z ]+?) -->(.*?)<!-- /os -->", re.S)


def resolve_markers(text, osname):
    def keep(m):
        tags = m.group(1).split()
        return m.group(2) if (osname == "all" or osname in tags) else ""
    return INLINE.sub(keep, MARK.sub(keep, text))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--os", required=True, choices=EDITIONS)
    ap.add_argument("--out", required=True)
    a = ap.parse_args()
    osname = a.os
    out = os.path.abspath(a.out)
    if os.path.exists(out):
        shutil.rmtree(out)
    os.makedirs(out)
    for item in COPY:
        src = os.path.join(ROOT, item)
        dst = os.path.join(out, item)
        (shutil.copytree if os.path.isdir(src) else shutil.copy2)(src, dst)

    # 2. markers
    for dp, dns, fns in os.walk(out):
        dns[:] = [d for d in dns if d not in ("labs", "logsleuth", "seed", "program")]  # markers live in the pages only
        for fn in fns:
            if fn.endswith(".md"):
                p = os.path.join(dp, fn)
                s = open(p, encoding="utf-8").read()
                r = resolve_markers(s, osname)
                if r != s:
                    open(p, "w", encoding="utf-8").write(r)

    # 3. exact variants
    spec = json.load(open(os.path.join(ROOT, "tools", "os-variants.json"), encoding="utf-8"))
    errors = 0
    for v in spec["variants"]:
        repl = v.get(osname)  # None → keep master text
        for rel in v["files"]:
            p = os.path.join(out, rel)
            s = open(p, encoding="utf-8").read()
            n = s.count(v["match"])
            if n != 1:
                if v.get("optional") and n == 0:
                    continue
                print(f"ERROR: {rel}: match occurs {n} times: {v['match'][:70]!r}", file=sys.stderr)
                errors += 1
                continue
            if repl is not None:
                open(p, "w", encoding="utf-8").write(s.replace(v["match"], repl))
    if errors:
        sys.exit(1)

    # 4. regex variants
    for v in spec.get("regex_variants", []):
        if osname not in v:
            continue
        rx = re.compile(v["pattern"])
        for rel in v["files"]:
            p = os.path.join(out, rel)
            s = open(p, encoding="utf-8").read()
            r = rx.sub(v[osname], s)
            if r != s:
                open(p, "w", encoding="utf-8").write(r)

    # 5. regenerate merged trainer pages
    merge = os.path.join(ROOT, "tools", "merge_trainer.py")
    for fn in sorted(os.listdir(os.path.join(out, "student"))):
        if not fn.endswith(".md") or fn.startswith("M00"):
            continue
        key = fn.split("-")[0]  # M01 … M09, A10, CAP01
        callouts = os.path.join(out, "trainer", "callouts", f"{key}.callouts.md")
        if not os.path.exists(callouts):
            print(f"ERROR: no callouts for {fn}", file=sys.stderr); sys.exit(1)
        trainer = os.path.join(out, "trainer", fn)
        with open(trainer, "w", encoding="utf-8") as fh:
            subprocess.run([sys.executable, merge, os.path.join(out, "student", fn), callouts],
                           check=True, stdout=fh)

    # 6. edition stamp
    label, slug = EDITIONS[osname]
    stamp = (f"\n> **Platform edition:** {label}. Built from the all-platform master by "
             f"`tools/build_os.py --os {osname}`; do not edit this copy — edit the master and rebuild.\n")
    if osname != "all":
        for rel in ["README-STUDENT.md", "README-TRAINER.md", "env/README.md"]:
            p = os.path.join(out, rel)
            s = open(p, encoding="utf-8").read()
            first_nl = s.find("\n")
            open(p, "w", encoding="utf-8").write(s[:first_nl + 1] + stamp + s[first_nl + 1:])
    open(os.path.join(out, "EDITION.txt"), "w").write(f"{slug}\n{label}\n")
    print(f"built {label} → {out}")


if __name__ == "__main__":
    main()
