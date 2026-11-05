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
NODEMaple SteelProfiles

Discovers steel profile families and, per family, the section list and
the section property names — in a single Maple process.

Hierarchy (one level deeper than materials):
  NODESteelProfiles:-Property("allmembers")       -> families
  NODESteelProfiles_<family>:-Property(...)       -> sections, metadata

Module names are constructed dynamically (NODESteelProfiles_<family>),
so new families are picked up automatically — no static lookup table.

Input:
  maple_version : Maple year, e.g. "2026" (ignored if MAPLE env var is set)

Output:
  families      : ordered list of family names (branch keys)
  sections_tree : tree, branch per family -> section names
  metadata_tree : tree, branch per family -> section property names
  debug         : raw Maple output; SKIP|<family> lines report failures
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

def run_maple_script(script, timeout=60):
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

def query_section_data():
    """Fetch families, sections and metadata in one Maple process.

    Emits: CAT|<family>            once per family, in order
           LIST|sec|<family>|<section name>
           LIST|meta|<family>|<property name>
           SKIP|<family>           if the family module cannot be resolved

    Module resolution is dynamic: parse(cat("NODESteelProfiles_", f)).
    If that fails to trigger the toolbox autoloader for a family,
    the try/catch reports it as SKIP instead of aborting the run.
    """
    script_lines = [
        "kernelopts(printbytes=false):",
        "interface(prettyprint=0):",
        'fams := NODESteelProfiles:-Property("allmembers"):',
        "for f in fams do",
        '  printf("CAT|%s\\n", f):',
        "  try",
        '    M := parse(cat("NODESteelProfiles_", f)):',
        '    for e in M:-Property("allmembers") do',
        '      printf("LIST|sec|%s|%s\\n", f, e):',
        "    end do:",
        '    for e in M:-Property("metadata") do',
        '      printf("LIST|meta|%s|%s\\n", f, e):',
        "    end do:",
        "  catch:",
        '    printf("SKIP|%s\\n", f):',
        "  end try:",
        "end do:",
        "quit:",
    ]
    return run_maple_script("\n".join(script_lines) + "\n")

# ---------------------------------------------------------------------------
# Main execution
# ---------------------------------------------------------------------------
raw = query_section_data()

families = []                 # ordered family names (= branch keys)
sections_by_fam = {}          # {"I": ["IPE 200", ...]}
metadata_by_fam = {}          # {"I": ["A_x", ...]}

for line in raw.splitlines():
    s = line.strip()
    if s.startswith("CAT|"):
        fam = s.split("|", 1)[1].strip()
        if fam:
            families.append(fam)
            sections_by_fam.setdefault(fam, [])
            metadata_by_fam.setdefault(fam, [])
    elif s.startswith("LIST|sec|") or s.startswith("LIST|meta|"):
        parts = s.split("|", 3)
        if len(parts) == 4:
            _, kind, fam, entry = parts
            entry = entry.strip().strip('"')
            if not entry:
                continue
            if kind == "sec":
                sections_by_fam.setdefault(fam, []).append(entry)
            else:
                metadata_by_fam.setdefault(fam, []).append(entry)

# Build the trees — branch index i corresponds to families[i]
sections_tree = Grasshopper.DataTree[object]()
metadata_tree = Grasshopper.DataTree[object]()

for i, fam in enumerate(families):
    path = GH_Path(i)
    sections_tree.AddRange(sections_by_fam.get(fam, []), path)
    metadata_tree.AddRange(metadata_by_fam.get(fam, []), path)

debug = raw