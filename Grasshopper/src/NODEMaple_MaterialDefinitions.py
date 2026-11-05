# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2026 <your name>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details: https://www.gnu.org/licenses/gpl-3.0.txt

"""
NODEMaple Material Definitions

Queries grade lists ("allmembers") and property definitions ("metadata")
for all material categories in a single Maple process, and returns them
as Grasshopper data trees whose branches correspond to categories.

For steel: grades include standard code (e.g. "S 275 H@NS-EN 10210-1")
to disambiguate grades that appear under multiple standards.

The branch order matches the order reported by NODEFunctions:-Materials(),
so a branch index is valid simultaneously in both trees.

Input:
  maple_version : Maple year, e.g. "2026" (ignored if MAPLE env var is set)

Output:
  members_tree  : tree, branch per category -> list of grade names
  metadata_tree : tree, branch per category -> list of property names
  categories    : ordered list of category names (branch keys, human-readable)
  debug         : raw Maple output; also shows SKIP|<category> lines
"""

import os
import subprocess
import Grasshopper
from Grasshopper.Kernel.Data import GH_Path

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
if os.environ.get("MAPLE"):
    MAPLE_ROOT = os.environ["MAPLE"]
else:
    MAPLE_ROOT = os.path.join(r"C:\Program Files", f"Maple {maple_version}")

MAPLE_PATH = os.path.join(MAPLE_ROOT, "bin.X86_64_WINDOWS", "cmaple.exe")

def run_maple_script(script, timeout=30):
    """Run a Maple script in a fresh cmaple process and return its output."""
    env = dict(os.environ)
    env["MAPLE"] = MAPLE_ROOT
    env["PATH"] = os.path.join(MAPLE_ROOT, "bin.X86_64_WINDOWS") + \
        os.pathsep + env.get("PATH", "")

    proc = subprocess.Popen(
        [MAPLE_PATH, "-q"],
        stdin=subprocess.PIPE, stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT, text=True,
        cwd=os.path.join(MAPLE_ROOT, "bin.X86_64_WINDOWS"),
        env=env,
        creationflags=subprocess.CREATE_NO_WINDOW)

    out, _ = proc.communicate(input=script, timeout=timeout)
    return out

def query_material_data():
    """Fetch categories, grades and metadata in one Maple process.

    For STEEL: outputs CODE@GRADE combinations to disambiguate
    grades appearing under multiple standards (e.g. "S 275 H@NS-EN 10210-1").
    
    Emits: CAT|<category>          once per category, in order
           LIST|mem|<category>|<grade>
           LIST|meta|<category>|<property>
           SKIP|<category>         for unmapped categories

    NOTE: every Maple statement is terminated with ":" or ";".
    Omitting a terminator lets the parser swallow the following line
    (e.g. an inline if-expression), producing misleading syntax errors.
    """
    script_lines = [
        "kernelopts(printbytes=false):",
        "interface(prettyprint=0):",
        '# Category -> module mapping',
        'nodetab := table(["steel"    = NODESteelMaterial,',
        '                  "timber"   = NODETimberMaterial,',
        '                  "concrete" = NODEConcreteMaterial]):',
        '# Categories are discovered at runtime',
        "cats := NODEFunctions:-Materials():",
        "known := [indices(nodetab, 'nolist')]:",
        "for c in cats do",
        '  printf("CAT|%s\\n", c):',
        "  if member(c, known) then",
        "    M := nodetab[c]:",
        '# Steel: special handling for code-grade pairs',
        '  if c = "steel" then',
        '# First get all codes',
        '    codes := M:-Property("allcodes"):',
        '    for code in codes do',
        '# Then grades of this code',
        '      for g in M:-Property(code,"allmembers") do',
        '# Composite grade name: grade@code',
        '        fullname := cat(g,"@",code):',
        '        printf("LIST|mem|%s|%s\\n", c, fullname):',
        "      end do:",
        "    end do:",
        "  else:",
        '# Non-steel: simple grade list',
        '    for e in M:-Property("allmembers") do',
        '      printf("LIST|mem|%s|%s\\n", c, e):',
        "    end do:",
        "  end if:",
        '# Metadata is always simple list',
        '    for e in M:-Property("metadata") do',
        '      printf("LIST|meta|%s|%s\\n", c, e):',
        "    end do:",
        "  else",
        '    printf("SKIP|%s\\n", c):',
        "  end if:",
        "end do:",
        "quit:",
    ]
    return run_maple_script("\n".join(script_lines) + "\n")

# ---------------------------------------------------------------------------
# Main execution
# ---------------------------------------------------------------------------
raw = query_material_data()

categories = []                 # ordered category names (= branch keys)
members_by_cat = {}             # {"timber": [grades...]}
metadata_by_cat = {}            # {"timber": [properties...]}

for line in raw.splitlines():
    s = line.strip()
    if s.startswith("CAT|"):
        cat = s.split("|", 1)[1].strip()
        if cat:
            categories.append(cat)
            members_by_cat.setdefault(cat, [])
            metadata_by_cat.setdefault(cat, [])
    elif s.startswith("LIST|mem|"):
        parts = s.split("|", 3)
        if len(parts) == 4:
            _, kind, cat, entry = parts
            entry = entry.strip().strip('"')
            if entry:
                members_by_cat.setdefault(cat, []).append(entry)
    elif s.startswith("LIST|meta|"):
        parts = s.split("|", 3)
        if len(parts) == 4:
            _, kind, cat, entry = parts
            entry = entry.strip().strip('"')
            if entry:
                metadata_by_cat.setdefault(cat, []).append(entry)

# Build the trees — GH1 recipe
members_tree = Grasshopper.DataTree[object]()
metadata_tree = Grasshopper.DataTree[object]()

for i, cat in enumerate(categories):
    path = GH_Path(i)
    members_tree.AddRange(members_by_cat.get(cat, []), path)
    metadata_tree.AddRange(metadata_by_cat.get(cat, []), path)

debug = raw