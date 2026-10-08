#!/usr/bin/env python3
"""Migrate a Logseq-imported Obsidian vault to PARA + links (driven by mapping.yaml).

  vault_migrate.py --plan                       report only, writes nothing in the vault
  vault_migrate.py --apply --target DIR         copy vault to DIR, migrate the copy
  vault_migrate.py --apply --target SOURCE      migrate in place (use git!)
"""
import argparse, collections, csv, fnmatch, os, re, shutil, sys
import yaml

HERE = os.path.dirname(os.path.abspath(__file__))
SKIP_DIRS = {".obsidian", ".trash", ".git", ".stfolder"}
KEEP_ROOT = {".stignore", ".gitignore", ".DS_Store"}

FENCE = re.compile(r"^\s*(```|~~~)")
TASK = re.compile(r"^\s*(?:[-*+]|\d+\.)\s+\[[ xX/\-]\]\s")
TAG = re.compile(r"(?<![\w/#&\]\)\\])#([A-Za-z](?:[\w/-]*\w)?)")
WIKI = re.compile(r"(!?)\[\[([^\]|#]*)(#[^\]|]*)?(?:\|([^\]]*))?\]\]")
ASSET_MD = re.compile(r"(!?)\[([^\]]*)\]\(\.\./assets/([^)]+)\)")
PROTECT = re.compile(r"`[^`]*`|\[\[[^\]]*\]\]|\]\([^)]*\)|<[^>\s]+://[^>]*>|https?://[^\s)\]>]+")
PROP = re.compile(r"^\s*(?:-\s+)?([\w-]+)::\s")
JOURNAL_US = re.compile(r"^Journals/(\d{4})_(\d{2})_(\d{2})( ?\(?conflicted.*)?\.md$")
DATE_SUFFIX = re.compile(r"\s*—\s*(due|scheduled|start)\s+\[\[(\d{4}-\d{2}-\d{2})\]\]")
DEADLINE = re.compile(r"^(\s*)(DEADLINE|SCHEDULED):\s*<(\d{4}-\d{2}-\d{2})[^>]*>\s*$")
SIGNIFIER = re.compile(r"\s*([⏫🔼🔽]|[📅⏳🛫]\s\d{4}-\d{2}-\d{2})")
DATE_EMOJI = {"due": "📅", "scheduled": "⏳", "start": "🛫", "DEADLINE": "📅", "SCHEDULED": "⏳"}


def list_name(tag):
    return "To " + tag[3:].replace("/", " ")


def stem(p):
    return os.path.splitext(os.path.basename(p))[0]


class Migration:
    def __init__(self, root, mapping, assets_dir=None):
        self.root = root
        self.assets_dir = assets_dir
        self.m = mapping
        self.stats = collections.Counter()
        self.unmapped = collections.Counter()
        self.notes = []          # human-readable warnings
        self.files = {}          # src rel path -> content (str for .md/.canvas, None for binary)
        self.dest = {}           # src rel -> dest rel | "TRASH"
        self.merges = []         # (src, dest)
        self.created = {}        # dest rel -> content
        self.out = {}            # dest rel -> content (final, md only)
        self.links = {k.lower(): v for k, v in mapping.get("links", {}).items()}
        self.renames = {k.lower(): v for k, v in mapping.get("renames", {}).items()}
        self.task_only = {k.lower(): v for k, v in mapping.get("task_only", {}).items()}
        self.everywhere = {k.lower(): v for k, v in mapping.get("everywhere", {}).items()}
        self.drop = {t.lower() for t in mapping.get("drop", [])}
        self.keep = [k.lower() for k in mapping.get("keep", [])]
        self.links_replace = {k.lower(): v for k, v in mapping.get("links_replace", {}).items()}
        self.drop_props = set(mapping.get("drop_properties", []))

    # ── 1. index ──────────────────────────────────────────────────────────
    def load(self):
        for d, dirs, fs in os.walk(self.root):
            dirs[:] = [x for x in dirs if x not in SKIP_DIRS]
            for f in fs:
                rel = os.path.relpath(os.path.join(d, f), self.root)
                if rel in KEEP_ROOT or f == ".DS_Store":
                    continue
                if f.endswith((".md", ".canvas")):
                    with open(os.path.join(d, f), encoding="utf-8", errors="surrogateescape") as fh:
                        self.files[rel] = fh.read()
                else:
                    self.files[rel] = None

    # ── 2. destinations ───────────────────────────────────────────────────
    def plan_moves(self):
        moves = self.m.get("moves", {})
        existing = set(self.files)
        for rel in sorted(self.files):
            if rel in moves:
                v = moves[rel]
                if v == "TRASH":
                    self.dest[rel] = "TRASH"
                elif v.startswith("MERGE:"):
                    self.merges.append((rel, v[6:]))
                    self.dest[rel] = "MERGED"
                else:
                    self.dest[rel] = v
            elif rel.startswith(("00 Inbox/", "10 Projects/", "20 Areas/", "30 Resources/",
                                 "40 Archive/", "Templates/", "Attachments/")):
                self.dest[rel] = rel          # already migrated (rerun)
            elif "conflicted" in rel:
                self.dest[rel] = f"00 Inbox/_conflicts/{rel.replace('/', '__')}"
            elif (mj := JOURNAL_US.match(rel)):
                new = f"Journals/{mj[1]}-{mj[2]}-{mj[3]}.md"
                if new in existing:
                    self.merges.append((rel, new))
                    self.dest[rel] = "MERGED"
                else:
                    self.dest[rel] = new
            elif rel.startswith("Journals/"):
                self.dest[rel] = rel
            elif self.files[rel] is None and "/" not in rel:
                self.dest[rel] = f"Attachments/{rel}"
            elif self.files[rel] is None:
                self.dest[rel] = rel
            else:
                self.dest[rel] = f"00 Inbox/{os.path.basename(rel)}"
                self.notes.append(f"unlisted note -> 00 Inbox: {rel}")
        for k in moves:
            if k not in self.files:
                self.stats["move source already gone (rerun?)"] += 1

    # name resolution: any way a link could have referred to a source note -> new stem
    def build_resolver(self):
        self.resolve = {}
        exact = {}
        by_stem = collections.defaultdict(list)
        for src, dst in list(self.dest.items()) + [(s, d) for s, d in self.merges]:
            if not (src.endswith(".md") or src.endswith(".canvas")):
                continue
            target = dst if dst not in ("TRASH", "MERGED") else None
            if dst == "MERGED":
                target = dict(self.merges)[src]
            if target is None:
                continue
            new = stem(target)
            noext = os.path.splitext(src)[0]
            exact[noext.lower()] = new
            if noext.startswith("Logseq/"):
                exact[noext[7:].lower()] = new             # Logseq namespace form
            by_stem[stem(src).lower()].append((src, new))
        for s, cands in by_stem.items():
            if len(cands) == 1:
                self.resolve[s] = cands[0][1]
            else:   # prefer the note whose name is unchanged
                same = [n for src, n in cands if n.lower() == s]
                self.resolve[s] = same[0] if same else cands[0][1]
        self.resolve.update(exact)
        canon = [n for g in self.m.get("stubs", []) for n in g["names"]]
        canon += [mm.group(1) for v in self.m.get("links", {}).values() for mm in [re.match(r"\[\[([^\]]+)\]\]", v)] if mm]
        for n in canon:
            self.resolve.setdefault(n.lower(), n)
        # journal underscore names
        for src, dst in self.dest.items():
            if JOURNAL_US.match(src):
                self.resolve[stem(src).lower()] = stem(dst if dst != "MERGED" else dict(self.merges)[src])
        self.final_stems = {stem(d).lower() for d in self.dest.values() if d not in ("TRASH", "MERGED")}
        # to/* list notes
        self.list_notes = {}

    # ── content transforms ───────────────────────────────────────────────
    def fix_link(self, m):
        bang, target, heading, alias = m.group(1), m.group(2).strip(), m.group(3) or "", m.group(4)
        key = target.lower()
        if not bang and key in self.links_replace:
            self.stats[f"link [[{target}]] -> {self.links_replace[key]}"] += 1
            return self.links_replace[key]
        if bang or os.path.splitext(target)[1].lower() not in ("", ".md"):
            # attachment / embed: shortest path = basename
            base = os.path.basename(target)
            if base != target:
                self.stats["attachment link -> basename"] += 1
            return f"{bang}[[{base}{heading}{'|' + alias if alias is not None else ''}]]"
        key = os.path.splitext(key)[0]
        new = self.resolve.get(key)
        if new is None and key.startswith("logseq/"):
            key, target = key[7:], target[7:]
            new = self.resolve.get(key)
        if new is None and key.startswith("journals/"):
            new = target[9:]
        if new is None and key.startswith("to/"):
            self.list_notes.setdefault(key, list_name(key))
            self.stats["[[to/x]] link -> #to/x tag"] += 1
            return "#" + key
        if new is None:
            new = target          # unresolved: keep (minus Logseq/ prefix)
            if new == m.group(2).strip():
                return m.group(0)
        # alias cleanup: drop path-like / redundant aliases from the importer
        if alias is not None:
            a = alias.strip()
            if "/" in a and self.resolve.get(a.lower().removeprefix("logseq/"), None) == new \
               or a.lower().startswith(("logseq/", "journals/")) or a.lower() == new.lower():
                alias = None
        elif stem(target).lower() != new.lower() and "/" not in target:
            alias = target
        out = f"[[{new}{heading}{'|' + alias if alias else ''}]]"
        if out != m.group(0):
            self.stats["link normalised"] += 1
        return out

    def tag_replacement(self, tag, is_task, line_links):
        k = tag.lower()
        if k in self.overrides:
            rep = self.overrides[k]
            link = re.match(r"\[\[([^\]]+)\]\]", rep)
            if link:
                line_links.add(link.group(1).lower())
            self.stats["per-file override"] += 1
            return rep, False
        if is_task and k in self.task_only:
            self.stats[f"task #{k}"] += 1
            return self.task_only[k], True
        if k in self.everywhere:
            self.stats[f"#{k} -> {self.everywhere[k] or '(removed)'}"] += 1
            return self.everywhere[k], False
        if k in self.links:
            rep = self.links[k]
            link = re.match(r"\[\[([^\]]+)\]\]", rep)
            if link and link.group(1).lower() in line_links:
                rep = rep[link.end():].strip()          # link already on this line
            elif link:
                line_links.add(link.group(1).lower())
            self.stats["tag -> link"] += 1
            return rep, False
        if k in self.renames:
            self.stats["tag renamed"] += 1
            return self.renames[k], False
        if k in self.drop:
            self.stats[f"#{k} dropped"] += 1
            return "", False
        if not any(fnmatch.fnmatch(k, p) for p in self.keep):
            self.unmapped[k] += 1
        if k.startswith("to/"):
            self.list_notes.setdefault(k, list_name(k))
        if tag != k:
            self.stats["tag lowercased"] += 1
        return "#" + k, False

    def transform_line(self, line):
        # Logseq ../assets/ markdown links -> wikilinks
        # link rewrites only outside inline code
        parts = re.split(r"(`[^`]*`)", line)
        for i in range(0, len(parts), 2):
            parts[i] = ASSET_MD.sub(lambda m: (self.stats.update(["../assets link -> wikilink"]) or
                                               f"{m[1]}[[{m[3]}{'|' + m[2] if m[2] and not m[1] else ''}]]"), parts[i])
            parts[i] = WIKI.sub(self.fix_link, parts[i])
        line = "".join(parts)
        is_task = bool(TASK.match(line))
        line_links = {m.group(2).strip().lower() for m in WIKI.finditer(line)}
        # protect code / links / urls, then rewrite tags
        saved = []
        def protect(m):
            saved.append(m.group(0))
            return f"\x00{len(saved) - 1}\x00"
        body = PROTECT.sub(protect, line)
        signifiers = []
        def tag_sub(m):
            rep, is_sig = self.tag_replacement(m.group(1), is_task, line_links)
            if is_sig:
                signifiers.append(rep)
                return ""
            return rep
        new = TAG.sub(tag_sub, body)
        if new != body:
            indent = re.match(r"^\s*", new).group(0)
            new = indent + re.sub(r"[ \t]{2,}", " ", new[len(indent):]).rstrip()
        seen = set()
        def dedupe(m):
            k = m.group(1).lower()
            if k in seen:
                self.stats["duplicate tag on line removed"] += 1
                return ""
            seen.add(k)
            return m.group(0)
        deduped = TAG.sub(dedupe, new)
        if deduped != new:
            indent = re.match(r"^\s*", deduped).group(0)
            new = indent + re.sub(r"[ \t]{2,}", " ", deduped[len(indent):]).rstrip()
        new = re.sub(r"\x00(\d+)\x00", lambda m: saved[int(m.group(1))], new)
        if is_task:
            new = DATE_SUFFIX.sub(lambda m: signifiers.append(f"{DATE_EMOJI[m[1]]} {m[2]}") or "", new)
            if signifiers or SIGNIFIER.search(new):
                existing = SIGNIFIER.findall(new)
                new = SIGNIFIER.sub("", new).rstrip()
                sigs = []
                for s in existing + signifiers:
                    if s and s not in sigs:
                        sigs.append(s)
                pri = [s for s in sigs if s in "⏫🔼🔽"][:1]
                new = " ".join([new] + pri + [s for s in sigs if s not in "⏫🔼🔽"])
                pass
            if new != line:
                self.stats["task line rewritten"] += 1
        return new

    def transform_frontmatter(self, fm_lines, extra_props):
        drop = {t.lower() for t in self.m.get("frontmatter_tags_drop", [])}
        to_type = self.m.get("frontmatter_tags_to_type", {})
        out, types, in_tags = [], [], False
        for ln in fm_lines:
            if "../assets/" in ln:
                ln = ASSET_MD.sub(lambda m: f"[[{m[3]}]]", ln)
                ln = re.sub(r"\.\./assets/(\S+)", r'"[[\1]]"', ln)
                self.stats["frontmatter assets path fixed"] += 1
            if re.match(r"^tags:\s*$", ln):
                in_tags = True
                out.append(ln)
                continue
            if in_tags and re.match(r"^\s+-\s", ln):
                val = ln.split("-", 1)[1].strip()
                if val in to_type:
                    types.append(to_type[val]); self.stats["frontmatter tag -> type"] += 1
                elif val.lower() in drop:
                    self.stats["frontmatter tag dropped"] += 1
                else:
                    out.append(ln)
                continue
            in_tags = False
            out.append(ln)
        # remove empty tags: key
        cleaned = []
        for i, ln in enumerate(out):
            if re.match(r"^tags:\s*$", ln) and (i + 1 >= len(out) or not re.match(r"^\s+-\s", out[i + 1])):
                continue
            cleaned.append(ln)
        props = dict(extra_props or {})
        if types and "type" not in props:
            props["type"] = types[0]
        for k, v in props.items():
            if any(re.match(rf"^{re.escape(k)}:", ln) for ln in cleaned):
                continue
            v = f'"{v}"' if isinstance(v, str) and ("[[" in v or ":" in v) else v
            cleaned.append(f"{k}: {v}")
            self.stats["property added"] += 1
        return cleaned

    def transform(self, text, dest_rel, src_rel=None):
        self.overrides = {k.lower(): v for k, v in
                          self.m.get("file_overrides", {}).get(src_rel, {}).items()}
        lines = text.split("\n")
        fm, start = [], 0
        if lines and lines[0].strip() == "---":
            for i in range(1, len(lines)):
                if lines[i].strip() == "---":
                    fm, start = lines[1:i], i + 1
                    break
        props = self.m.get("properties", {}).get(dest_rel)
        fm2 = self.transform_frontmatter(fm, props) if (fm or props) else []
        body, infence = [], False
        for ln in lines[start:]:
            if FENCE.match(ln):
                infence = not infence
                body.append(ln); continue
            if infence:
                body.append(ln); continue
            pm = PROP.match(ln)
            if pm and pm.group(1) in self.drop_props:
                self.stats["logseq property line dropped"] += 1
                continue
            dm = DEADLINE.match(ln)
            if dm and body:
                # attach as signifier to the task/block above
                prev = body[-1]
                if TASK.match(prev):
                    body[-1] = f"{prev.rstrip()} {DATE_EMOJI[dm[2]]} {dm[3]}"
                else:
                    body[-1] = f"{prev.rstrip()} ({dm[2].lower()} {dm[3]})"
                self.stats["DEADLINE/SCHEDULED converted"] += 1
                continue
            body.append(self.transform_line(ln))
        out = "\n".join(body)
        if fm2:
            out = "---\n" + "\n".join(fm2) + "\n---\n" + out.lstrip("\n")
        return out

    # ── run ───────────────────────────────────────────────────────────────
    def run(self):
        self.load()
        self.plan_moves()
        self.build_resolver()
        for src, dst in self.dest.items():
            if dst in ("TRASH", "MERGED") or self.files[src] is None:
                continue
            if src.endswith(".canvas"):
                self.out[dst] = self.files[src]; continue
            self.out[dst] = self.transform(self.files[src], dst, src)
        for src, dst in self.merges:
            body = self.transform(self.files[src], dst, src)
            body = re.sub(r"^---\n.*?\n---\n", "", body, flags=re.S).strip()
            if f"## Merged from {src}" not in self.out.get(dst, ""):
                self.out[dst] = self.out.get(dst, "").rstrip() + f"\n\n## Merged from {src}\n\n{body}\n"
                self.stats["notes merged"] += 1
        self.make_stubs()
        self.make_query_notes()
        self.recover_assets()

    def recover_assets(self):
        self.recovered = {}
        if not self.assets_dir:
            return
        have = {os.path.basename(d).lower() for s, d in self.dest.items() if self.files[s] is None}
        for t in self.out.values():
            for m in WIKI.finditer(t):
                name = m.group(2).strip()
                if os.path.splitext(name)[1].lower() in ("", ".md") or name.lower() in have:
                    continue
                src = os.path.join(self.assets_dir, name)
                if os.path.exists(src):
                    self.recovered[f"Attachments/{name}"] = src
                    have.add(name.lower())
        self.stats["attachments recovered from logseq assets"] = len(self.recovered)

    def _has_note(self, name):
        return any(stem(p).lower() == name.lower() for p in self.out)

    def make_stubs(self):
        for grp in self.m.get("stubs", []):
            for name in grp["names"]:
                if self._has_note(name):
                    continue
                fm = "\n".join(f'{k}: "{v}"' if "[[" in str(v) else f"{k}: {v}"
                               for k, v in grp.get("properties", {}).items())
                path = f"{grp['folder']}/{name}.md"
                self.out[path] = f"---\n{fm}\n---\n" if fm else ""
                self.created[path] = "stub"

    def make_query_notes(self):
        wanted = dict(self.m.get("query_notes", {}))
        for tag, name in self.list_notes.items():
            wanted.setdefault(name, "#" + tag)
        for name, tag in wanted.items():
            block = f"```query\ntag:{tag}\n```"
            path = next((p for p in self.out if stem(p).lower() == name.lower()), None)
            if path:
                if block not in self.out[path]:
                    self.out[path] = self.out[path].rstrip() + f"\n\n## Tagged {tag}\n\n{block}\n"
                    self.stats["query appended to existing note"] += 1
            else:
                path = f"30 Resources/Lists/{name}.md"
                self.out[path] = f"{block}\n"
                self.created[path] = "query"

    # ── verification ─────────────────────────────────────────────────────
    @staticmethod
    def unresolved(md_texts, all_paths):
        names = set()
        for p in all_paths:
            names.add(os.path.basename(p).lower())
            names.add(os.path.splitext(p)[0].lower())
            if p.endswith(".md"):
                names.add(stem(p).lower())
        bad = collections.Counter()
        for p, t in md_texts.items():
            refs = [m.group(2) for m in WIKI.finditer(t or "")] + [m.group(3) for m in ASSET_MD.finditer(t or "")]
            for tgt in refs:
                tgt = tgt.strip()
                if tgt and tgt.lower() not in names and os.path.splitext(tgt)[0].lower() not in names:
                    bad[tgt] += 1
        return bad

    def verify(self):
        before = self.unresolved({k: v for k, v in self.files.items() if k.endswith(".md")}, self.files)
        after_paths = set(self.out) | {d for s, d in self.dest.items() if self.files[s] is None} | set(self.recovered)
        after = self.unresolved(self.out, after_paths)
        stems = collections.Counter(stem(p).lower() for p in self.out if p.endswith(".md"))
        dupes = {s for s, n in stems.items() if n > 1}
        return before, after, dupes

    # ── output ────────────────────────────────────────────────────────────
    def report(self, path):
        before, after, dupes = self.verify()
        norm = lambda t: t.lower().removeprefix("logseq/").removeprefix("journals/")
        before_n = {norm(t) for t in before}
        newly = sorted(t for t in after if norm(t) not in before_n)
        trashed_names = {stem(s).lower() for s, d in self.dest.items() if d == "TRASH"}
        newly_real = [t for t in newly if t.lower() not in trashed_names
                      and t.lower().removeprefix("logseq/") not in trashed_names]
        with open(path, "w") as f:
            w = f.write
            w("# Vault migration report\n\n")
            w(f"- files scanned: {len(self.files)}\n- notes written: {len(self.out)}\n")
            w(f"- moved/renamed: {sum(1 for s, d in self.dest.items() if d not in ('TRASH', 'MERGED') and d != s)}\n")
            w(f"- trashed: {sum(1 for d in self.dest.values() if d == 'TRASH')}\n")
            w(f"- merged: {len(self.merges)}\n- created: {len(self.created)}\n\n")
            w(f"## Link check\n\n- unresolved before: {sum(before.values())} ({len(before)} distinct)\n")
            w(f"- unresolved after: {sum(after.values())} ({len(after)} distinct)\n")
            w(f"- **newly unresolved: {len(newly_real)}**\n")
            for t in newly_real:
                w(f"  - `{t}` ({after[t]}x)\n")
            gone = [t for t in newly if t not in newly_real]
            if gone:
                w(f"- unresolved because target was trashed (expected): {', '.join(gone)}\n")
            fixed = sorted(set(before) - set(after))
            w(f"- resolved by migration: {len(fixed)}\n\n")
            w(f"## Duplicate note names after migration: {sorted(dupes) or 'none'}\n\n")
            w("## Rule counts\n\n")
            for k, n in sorted(self.stats.items(), key=lambda x: -x[1]):
                if n:
                    w(f"- {k}: {n}\n")
            w("\n## Unmapped tags (left as lowercase tags)\n\n")
            w(", ".join(f"#{k} ({n})" for k, n in self.unmapped.most_common()) + "\n")
            w("\n## Created notes\n\n")
            for p, kind in sorted(self.created.items()):
                w(f"- {kind}: {p}\n")
            w("\n## Merges\n\n")
            for s, d in self.merges:
                w(f"- {s} -> {d}\n")
            if self.notes:
                w("\n## Warnings\n\n" + "".join(f"- {n}\n" for n in self.notes))
        with open(os.path.join(os.path.dirname(path), "moves.csv"), "w", newline="") as f:
            cw = csv.writer(f)
            cw.writerow(["source", "destination"])
            for s, d in sorted(self.dest.items()):
                if d != s:
                    cw.writerow([s, dict(self.merges).get(s, d) if d == "MERGED" else d])
        return len(newly_real), dupes

    def apply(self, target):
        if os.path.abspath(target) != os.path.abspath(self.root):
            if os.path.exists(target):
                sys.exit(f"target {target} exists; remove it first")
            shutil.copytree(self.root, target, symlinks=True)
        T = lambda p: os.path.join(target, p)
        trash = T(".trash")
        os.makedirs(trash, exist_ok=True)
        # move binaries first, then remove old md sources, then write new md
        for src, dst in self.dest.items():
            if self.files[src] is None and dst != src:
                os.makedirs(os.path.dirname(T(dst)), exist_ok=True)
                shutil.move(T(src), T(dst))
        for src, dst in self.dest.items():
            if self.files[src] is None:
                continue
            if dst == "TRASH":
                tdst = os.path.join(trash, src.replace("/", "__"))
                shutil.move(T(src), tdst)
            elif os.path.exists(T(src)) and src not in self.out:
                os.remove(T(src))
        for p, src in self.recovered.items():
            os.makedirs(os.path.dirname(T(p)), exist_ok=True)
            shutil.copy2(src, T(p))
        for p, content in self.out.items():
            os.makedirs(os.path.dirname(T(p)) or target, exist_ok=True)
            with open(T(p), "w", encoding="utf-8", errors="surrogateescape") as fh:
                fh.write(content)
        # remove now-empty folders
        for d, dirs, fs in os.walk(target, topdown=False):
            rel = os.path.relpath(d, target)
            if rel != "." and not rel.split(os.sep)[0] in SKIP_DIRS and not os.listdir(d):
                os.rmdir(d)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--source", default=os.path.expanduser("~/syncthing/obsidian_vault"))
    ap.add_argument("--mapping", required=True)
    ap.add_argument("--out", default=os.getcwd(), help="dir for report.md / moves.csv")
    ap.add_argument("--plan", action="store_true")
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--target")
    ap.add_argument("--assets", default=os.path.expanduser("~/pcloud/dutch-dataworks/logseq_kb/assets"))
    ap.add_argument("--force", action="store_true", help="apply even with new broken links")
    a = ap.parse_args()
    mig = Migration(a.source, yaml.safe_load(open(a.mapping)), a.assets)
    mig.run()
    new_broken, dupes = mig.report(os.path.join(a.out, "report.md"))
    print(f"report: {os.path.join(a.out, 'report.md')}  newly unresolved: {new_broken}  dupes: {sorted(dupes)}")
    if a.apply:
        if not a.target:
            sys.exit("--apply needs --target")
        if (new_broken or dupes) and not a.force:
            sys.exit("refusing to apply: fix newly unresolved links / duplicate names (or --force)")
        mig.apply(a.target)
        print(f"applied to {a.target}")


if __name__ == "__main__":
    main()
