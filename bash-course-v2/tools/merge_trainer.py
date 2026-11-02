#!/usr/bin/env python3
"""merge_trainer.py STUDENT.md CALLOUTS.md > TRAINER.md

Builds a Full Trainer Edition page from the Student Edition page plus anchored
TRAINER ONLY blocks, so the student text is reproduced verbatim by construction
(edition parity).

CALLOUTS.md format — blocks separated by anchor lines:
    === ANCHOR: TOP ===            insert after the first line (the edition line)
    === ANCHOR: END ===            append at the end of the page
    === ANCHOR: <heading text> === insert at the END of that heading's section
                                   (just before the next heading or '---')
The block body is plain markdown; it is emitted as a blockquote (`> `), which the
Notion converter renders as a TRAINER ONLY callout.
"""
import re, sys

def parse_callouts(text):
    blocks, anchor, body = [], None, []
    for line in text.split('\n'):
        m = re.match(r'^=== ANCHOR: (.*?) ===\s*$', line)
        if m:
            if anchor is not None:
                blocks.append((anchor, body))
            anchor, body = m.group(1).strip(), []
        elif anchor is not None:
            body.append(line)
    if anchor is not None:
        blocks.append((anchor, body))
    return blocks

def as_quote(body):
    # trim leading/trailing blank lines, then quote every line
    while body and body[0].strip() == '': body = body[1:]
    while body and body[-1].strip() == '': body = body[:-1]
    return ['> ' + l if l.strip() else '>' for l in body]

def section_end(lines, start):
    """index of the first heading/rule line after `start`, or len(lines)."""
    for i in range(start + 1, len(lines)):
        s = lines[i]
        if s.startswith('## ') or s.startswith('### ') or s.startswith('# ') or re.match(r'^-{3,}\s*$', s):
            return i
    return len(lines)

def merge(student, callouts):
    lines = student.split('\n')
    # edition line: the first line that carries the Student Edition label
    for i, l in enumerate(lines[:5]):
        if '**Student Edition' in l:
            lines[i] = l.replace('**Student Edition', '**FULL TRAINER EDITION', 1)
            break
    top, end, anchored = [], [], []
    for anchor, body in callouts:
        if anchor == 'TOP': top.append(body)
        elif anchor == 'END': end.append(body)
        else: anchored.append((anchor, body))
    # anchored inserts, processed from the bottom up so indices stay valid
    targets = []
    for anchor, body in anchored:
        idx = next((i for i, l in enumerate(lines) if l.strip() == anchor.strip()), None)
        if idx is None:
            sys.exit(f'anchor not found: {anchor!r}')
        targets.append((section_end(lines, idx), body))
    for pos, body in sorted(targets, key=lambda t: t[0], reverse=True):
        block = [''] + as_quote(body) + ['']
        lines[pos:pos] = block
    # TOP blocks go after the header block (title + edition line + time split),
    # i.e. at the first blank line after the edition line.
    ed = next((i for i, l in enumerate(lines[:6]) if 'TRAINER EDITION' in l or 'Student Edition' in l), 0)
    at = next((i for i in range(ed + 1, len(lines)) if lines[i].strip() == ''), ed + 1)
    for body in reversed(top):
        lines[at:at] = [''] + as_quote(body) + ['']
    for body in end:
        lines += [''] + as_quote(body)
    return '\n'.join(lines)

if __name__ == '__main__':
    student = open(sys.argv[1]).read()
    callouts = parse_callouts(open(sys.argv[2]).read())
    sys.stdout.write(merge(student, callouts))
