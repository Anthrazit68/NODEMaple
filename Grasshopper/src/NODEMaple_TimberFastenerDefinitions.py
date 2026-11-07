# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2026 Andreas Zieritz
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
NODEMaple Timber Fastener Definitions

Discovers timber fastener types (Nail, Screw, Bolt, Dowel, ...) and, per
type, the member list, the variable names, the producers and the
diameters — in a single Maple process. Mirrors
NODEMaple_MaterialDefinitions.py, but with two additional trees.

Hierarchy (one Property call per output tree):
  NODETimberFasteners:-Property("allmembers")     -> types
  NODETimberFasteners:-Property(t, "allmembers")  -> members "producer@product"
  NODETimberFasteners:-Property(t, "metadata")    -> variable names
  NODETimberFasteners:-Property(t, "producers")   -> producer names
  NODETimberFasteners:-Property(t, "diameters")  -> unit-free diameters (6, 6.2, ...)

Diameter handling (robust against Maple number formats):
  - Maple emits evalf(e), forcing decimal form (avoids rationals like 31/5)
  - Python accepts plain floats, and falls back to:
      * fraction parsing "a/b" -> a/b
      * keeping the raw string in the tree (nothing is dropped silently)
  - the debug summary lists rejected raw values, if any, so the
    actual Maple output format is always visible

Input:
  maple_version : Maple year, e.g. "2026" (ignored if MAPLE env var is set)

Output:
  types         : ordered list of fastener types (branch keys)
  members_tree  : tree, branch per type -> "producer@product" designations
  metadata_tree : tree, branch per type -> variable names
  producers_tree: tree, branch per type -> producer names
  diameters_tree: tree, branch per type -> diameters (numbers when parseable)
  debug         : raw Maple output with a count/reject summary header
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

def query_fastener_data():
    """Fetch types, members, metadata, producers and diameters in one
    Maple process.

    Emits: CAT|<type>               once per fastener type, in order
           LIST|mem|<type>|producer@product
           LIST|meta|<type>|<variable name>
           LIST|prod|<type>|<producer>
           LIST|dia|<type>|<diameter, evalf-decimal>
           SKIP|<type>              if the type cannot be queried

    NOTE: every Maple statement is terminated with ":" or ";".
    Omitting a terminator lets the parser swallow the following line,
    producing misleading syntax errors.
    """
    script_lines = [
        "kernelopts(printbytes=false):",
        "interface(prettyprint=0):",
        'types := NODETimberFasteners:-Property("allmembers"):',
        "for t in types do",
        '  printf("CAT|%s\\n", t):',
        "  try",
        "# Product designations of this fastener type (producer@product)",
        '    for e in NODETimberFasteners:-Property(t, "allmembers") do',
        '      printf("LIST|mem|%s|%s\\n", t, e):',
        "    end do:",
        "# Variable names (shared metadata table for all types)",
        '    for e in NODETimberFasteners:-Property(t, "metadata") do',
        '      printf("LIST|meta|%s|%s\\n", t, e):',
        "    end do:",
        "# Producers offering at least one product of this type",
        '    for e in NODETimberFasteners:-Property(t, "producers") do',
        '      printf("LIST|prod|%s|%s\\n", t, e):',
        "    end do:",
        "# Diameters: evalf forces decimal form (no rationals such as 31/5)",
        '    for e in NODETimberFasteners:-Property(t, "diameters") do',
        '      printf("LIST|dia|%s|%a\\n", t, evalf(e)):',
        "    end do:",
        "  catch:",
        '    printf("SKIP|%s\\n", t):',
        "  end try:",
        "end do:",
        "quit:",
    ]
    return run_maple_script("\n".join(script_lines) + "\n")

# ---------------------------------------------------------------------------
# Main execution
# ---------------------------------------------------------------------------
raw = query_fastener_data()

types = []                    # ordered fastener types (= branch keys)
members_by_type = {}          # {"Screw": ["Rotblau@ASSY 4 CSMP", ...]}
metadata_by_type = {}         # {"Screw": ["fm", "prod", ...]}
producers_by_type = {}        # {"Screw": ["Rotblau", "Wuerth", ...]}
diameters_by_type = {}        # {"Screw": [3.0, 3.5, 4.0, ...]}
dia_rejects = []              # values that were not plain-parseable

def parse_diameter(text):
    """Best-effort numeric parse of a Maple-emitted diameter.

    Returns (value, ok). Handles plain floats ("24.0", "24."), Maple
    fractions ("31/5") and falls back to the raw string otherwise —
    nothing is dropped silently.
    """
    t = text.strip()
    try:
        return float(t), True
    except ValueError:
        pass
    if "/" in t:
        try:
            a, b = t.split("/", 1)
            return float(a.strip()) / float(b.strip()), True
        except ValueError:
            pass
    return t, False

for line in raw.splitlines():
    s = line.strip()
    if s.startswith("CAT|"):
        typ = s.split("|", 1)[1].strip()
        if typ:
            types.append(typ)
            members_by_type.setdefault(typ, [])
            metadata_by_type.setdefault(typ, [])
            producers_by_type.setdefault(typ, [])
            diameters_by_type.setdefault(typ, [])
    elif s.startswith("LIST|"):
        parts = s.split("|", 3)
        if len(parts) == 4:
            _, kind, typ, entry = parts
            typ = typ.strip()
            entry = entry.strip().strip('"')
            if not entry:
                continue
            if kind == "mem":
                members_by_type.setdefault(typ, []).append(entry)
            elif kind == "meta":
                metadata_by_type.setdefault(typ, []).append(entry)
            elif kind == "prod":
                producers_by_type.setdefault(typ, []).append(entry)
            elif kind == "dia":
                val, ok = parse_diameter(entry)
                diameters_by_type.setdefault(typ, []).append(val)
                if not ok:
                    # Keep the value, but record it so the debug output
                    # reveals the exact format Maple produced.
                    dia_rejects.append((typ, entry))

# Build the trees — branch index i corresponds to types[i]
members_tree = Grasshopper.DataTree[object]()
metadata_tree = Grasshopper.DataTree[object]()
producers_tree = Grasshopper.DataTree[object]()
diameters_tree = Grasshopper.DataTree[object]()

for i, typ in enumerate(types):
    path = GH_Path(i)
    members_tree.AddRange(members_by_type.get(typ, []), path)
    metadata_tree.AddRange(metadata_by_type.get(typ, []), path)
    producers_tree.AddRange(producers_by_type.get(typ, []), path)
    diameters_tree.AddRange(diameters_by_type.get(typ, []), path)

counts = ("parsed per kind: mem=%d meta=%d prod=%d dia=%d (%d unparseable, "
          "kept as raw text)" % (
              sum(len(v) for v in members_by_type.values()),
              sum(len(v) for v in metadata_by_type.values()),
              sum(len(v) for v in producers_by_type.values()),
              sum(len(v) for v in diameters_by_type.values()),
              len(dia_rejects)))
if dia_rejects:
    counts += "\nunparseable diameters: " + \
        "; ".join("[%s] %r" % (t, v) for t, v in dia_rejects[:20])
debug = counts + "\n" + raw