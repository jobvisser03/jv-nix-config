#!/usr/bin/env python3
"""Read-only health check of the Obsidian vault.

  audit.py [VAULT]            (default ~/syncthing/obsidian_vault)

Reports: tag inventory (with case variants), tags that duplicate an existing note
name (should be links), unresolved links, notes outside the PARA folders,
attachments outside Attachments/, conflict files, empty stub notes, and
legacy Logseq syntax that is still around.
"""
import collections, os, re, sys

ROOT = os.path.expanduser(sys.argv[1] if len(sys.argv) > 1 else "~/syncthing/obsidian_vault")
SKIP = {".obsidian", ".trash", ".git", ".stfolder"}
PARA = ("00 Inbox/", "10 Projects/", "20 Areas/", "30 Resources/", "40 Archive/",
        "Journals/", "Templates/", "Attachments/")
TAG = re.compile(r"(?<![\w/#&\]\)\\])#([A-Za-z](?:[\w/-]*\w)?)")
WIKI = re.compile(r"!?\[\[([^\]|#]*)(?:#[^\]|]*)?(?:\|[^\]]*)?\]\]")
PROTECT = re.compile(r"`[^`]*`|\[\[[^\]]*\]\]|\]\([^)]*\)|https?://[^\s)\]>]+")
FENCE = re.compile(r"^\s*(```|~~~)")
LEGACY = {
    "logseq path link": re.compile(r"\[\[(Logseq|Journals)/"),
    "logseq property (key:: value)": re.compile(r"^\s*-?\s*[\w-]+:: "),
    "logseq query {{query}}": re.compile(r"\{\{query"),
    "logseq ../assets link": re.compile(r"\]\(\.\./assets/"),
    "#inbox tag": re.compile(r"#inbox\b"),
    "logseq priority #A/#B/#C": re.compile(r"(?<![\w#])#[ABC]\b"),
    "DEADLINE/SCHEDULED": re.compile(r"^\s*(DEADLINE|SCHEDULED):"),
}

files, md = [], {}
for d, dirs, fs in os.walk(ROOT):
    dirs[:] = [x for x in dirs if x not in SKIP]
    for f in fs:
        rel = os.path.relpath(os.path.join(d, f), ROOT)
        if rel in (".stignore", ".gitignore") or f == ".DS_Store":
            continue
        files.append(rel)
        if f.endswith(".md"):
            md[rel] = open(os.path.join(d, f), encoding="utf-8", errors="replace").read()

stems = collections.defaultdict(list)
for p in md:
    stems[os.path.splitext(os.path.basename(p))[0].lower()].append(p)
names = {os.path.basename(p).lower() for p in files} | set(stems) | {os.path.splitext(p)[0].lower() for p in files}

tags, variants, legacy = collections.Counter(), collections.defaultdict(collections.Counter), collections.Counter()
unresolved = collections.Counter()
for p, text in md.items():
    infence, fm = False, text.startswith("---\n")
    for i, line in enumerate(text.split("\n")):
        if fm:
            if i > 0 and line.strip() == "---":
                fm = False
            continue
        if FENCE.match(line):
            infence = not infence
            continue
        if infence:
            continue
        for k, rx in LEGACY.items():
            if rx.search(line):
                legacy[k] += 1
        for m in WIKI.finditer(line):
            t = m.group(1).strip()
            if t and t.lower() not in names and os.path.splitext(t)[0].lower() not in names:
                unresolved[t] += 1
        for m in TAG.finditer(PROTECT.sub("", line)):
            tags[m.group(1).lower()] += 1
            variants[m.group(1).lower()][m.group(1)] += 1

def section(title):
    print(f"\n## {title}")

print(f"# Vault audit: {ROOT}\n{len(md)} notes, {len(files)} files, {len(tags)} distinct tags")

section("Tags (count, case variants)")
for t, n in tags.most_common():
    v = variants[t]
    print(f"{n:5d}  #{t}" + (f"   variants: {dict(v)}" if len(v) > 1 or t not in v else ""))

section("Tags that match an existing note name (probably should be [[links]])")
for t in sorted(tags):
    leaf = t.split("/")[-1]
    for cand in (t, leaf, leaf.replace("-", " ")):
        if cand in stems and f"tag:#{t}" not in md[stems[cand][0]]:   # skip query notes
            print(f"  #{t} -> [[{os.path.splitext(os.path.basename(stems[cand][0]))[0]}]]  ({tags[t]}x)")
            break

section("Duplicate note names (break [[shortest]] links)")
for s, ps in sorted(stems.items()):
    if len(ps) > 1:
        print(f"  {s}: {ps}")

section(f"Unresolved links ({sum(unresolved.values())} total, {len(unresolved)} distinct)")
for t, n in unresolved.most_common(40):
    print(f"{n:5d}  [[{t}]]")

section("Notes outside PARA folders")
for p in sorted(md):
    if not p.startswith(PARA):
        print("  " + p)

section("Attachments outside Attachments/")
for p in sorted(files):
    if not p.endswith((".md", ".canvas", ".base")) and not p.startswith("Attachments/"):
        print("  " + p)

section("Conflict files")
for p in sorted(files):
    if "conflict" in p.lower():
        print("  " + p)

section("Empty / stub-only notes (frontmatter only)")
for p, t in sorted(md.items()):
    body = re.sub(r"^---\n.*?\n---\n?", "", t, flags=re.S).strip()
    if not body and not p.startswith("Journals/"):
        print("  " + p)

section("Legacy Logseq syntax still present (line counts)")
for k, n in legacy.most_common():
    print(f"{n:5d}  {k}")
