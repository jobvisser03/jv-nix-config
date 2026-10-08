#!/usr/bin/env python3
"""Re-run a mapping against an (already migrated) vault in memory and list
every file whose content or location would still change. Empty output = idempotent.

  check_idempotent.py VAULT MAPPING.yaml
"""
import os, sys, difflib
import yaml

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import vault_migrate as vm

vault, mapping = os.path.expanduser(sys.argv[1]), sys.argv[2]
m = vm.Migration(vault, yaml.safe_load(open(mapping)), None)
m.run()
changed = 0
for src, dst in m.dest.items():
    if dst != src:
        print("MOVE:", src, "->", dst); changed += 1
    if m.files[src] is None or dst in ("TRASH", "MERGED"):
        continue
    if m.out.get(dst) != m.files[src]:
        changed += 1
        print("CHANGED:", src)
        for l in list(difflib.unified_diff(m.files[src].splitlines(), m.out[dst].splitlines(),
                                           lineterm="", n=0))[2:8]:
            print("   ", l[:160])
for p in m.created:
    print("CREATE:", p); changed += 1
print(f"{changed} pending change(s)")
