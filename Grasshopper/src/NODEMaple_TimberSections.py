# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2026 <your name>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.  For more details:
# https://www.gnu.org/licenses/gpl-3.0.txt

"""
NODEMaple Timber Sections

Walks the NODETimberSections data API (exported tables timbertype,
section_b, section_h) and returns the standard dimension catalogue as
Grasshopper data trees:

  timber type  ->  available widths (b)  ->  available heights (h)

Data shape (per Data_NODETimberSections.mm):
  section_b[tt]        = SET of unit-carrying widths
  section_h[tt, b]     = SET of unit-carrying heights, indexed by the
                         PLAIN number b (no unit)

The Maple walker converts sets via op(), sorts them, and strips units
before printing, so the Python parser sees plain numbers throughout.

Emits records:
  REC|tt|<index>|<timber type name>
  REC|b|<tt>|num|<width>
  REC|h|<tt>|<b>|num|<height>

Input:
  maple_version : Maple year, e.g. "2026" (ignored if MAPLE env var set)

Output:
  timber_types  : ordered list of timber type names
  b_tree        : branch per timber type -> list of widths [mm]
  h_tree        : branch path {typeIdx, widthIdx} -> list of heights [mm]
  table         : display list, one line per width with its heights
  debug         : send/receive summary + raw Maple output

Usage: feed timber_types into a Value List; picking a type gives a
branch of b_tree; picking a width gives the {type,width} branch of
h_tree - the cascade select timber type -> width -> heights.

NOTE: the Maple<->Python protocol is ASCII-only ("|" as field separator).
NOTE: this script string is NOT Python %-formatted, so Maple printf
      specifiers are written plainly (%d, %s, %a).
NOTE: indices(...,'nolist') flattens multi-dimensional table keys, so
      the two-dimensional section_h walk uses indices WITHOUT nolist
      and iterates over the returned index lists.
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


# ---------------------------------------------------------------------------
# Maple script: walk timbertype -> section_b -> section_h
# ---------------------------------------------------------------------------

script = (
    'kernelopts(printbytes=false):\n'
    'interface(prettyprint=0):\n'
    'S := NODETimberSections:\n'
    '\n'
    '# unit-free evalf of a (possibly unit-carrying) catalogue value\n'
    'uf := proc(v)\n'
    '  if type(v, with_unit) then\n'
    '    evalf(convert(v, unit_free));\n'
    '  else\n'
    '    evalf(v);\n'
    '  end if;\n'
    'end proc:\n'
    '\n'
    'try\n'
    '  tts := sort([indices(S:-section_b, nolist)]):\n'
    '  for i from 1 to numelems(tts) do\n'
    '    printf("REC|tt|%d|%s\\n", i, tts[i]):\n'
    '  end do:\n'
    '\n'
    '  # section_b[tt] is a SET of unit-carrying widths:\n'
    '  # op() -> list, map(uf,...) strips units, sort orders numerically\n'
    '  for tt in tts do\n'
    '    bs := sort(map(uf, [op(S:-section_b[tt])])):\n'
    '    for b in bs do\n'
    '      printf("REC|b|%s|num|%a\\n", tt, b):\n'
    '    end do:\n'
    '  end do:\n'
    '\n'
    '  # section_h is TWO-dimensional: indices WITHOUT nolist returns a\n'
    '  # sequence of index lists, e.g. ["CLT", 120] - iterating over those\n'
    '  # keeps tt and b intact (nolist would flatten into single elements)\n'
    '  for idx in [indices(S:-section_h)] do\n'
    '    tt := idx[1]:\n'
    '    bb := uf(idx[2]):\n'
    '    hs := sort(map(uf, [op(S:-section_h[op(idx)])])):\n'
    '    for h in hs do\n'
    '      printf("REC|h|%s|%a|num|%a\\n", tt, bb, h):\n'
    '    end do:\n'
    '  end do:\n'
    'catch:\n'
    '  printf("ERR|%a\\n", lastexception):\n'
    'end try:\n'
    'quit:\n'
)

raw = run_maple_script(script)

# ---------------------------------------------------------------------------
# Parse results
# ---------------------------------------------------------------------------

tt_by_idx = {}          # {index: name}
widths = {}             # {tt: [b, ...]}
heights = {}            # {(tt, b): [h, ...]}
err = None


def _f(payload):
    try:
        return float(payload)
    except ValueError:
        return None


for line in raw.splitlines():
    s = line.strip()
    if s.startswith("REC|tt|"):
        parts = s.split("|", 3)
        if len(parts) == 4:
            try:
                tt_by_idx[int(parts[2])] = parts[3].strip()
            except ValueError:
                pass
    elif s.startswith("REC|b|"):
        parts = s.split("|", 4)
        if len(parts) == 5:
            tt = parts[2].strip()
            if parts[3] == "num":
                v = _f(parts[4])
                if v is not None:
                    widths.setdefault(tt, []).append(v)
    elif s.startswith("REC|h|"):
        parts = s.split("|", 5)
        if len(parts) == 6:
            tt = parts[2].strip()
            b = _f(parts[3])
            if parts[4] == "num":
                v = _f(parts[5])
                if b is not None and v is not None:
                    heights.setdefault((tt, b), []).append(v)
    elif s.startswith("ERR|") and err is None:
        err = s[len("ERR|"):]

timber_types = [tt_by_idx[i] for i in sorted(tt_by_idx)]

# de-duplicate while preserving order
def _dedupe(seq):
    seen = set()
    out = []
    for x in seq:
        if x not in seen:
            seen.add(x)
            out.append(x)
    return out

b_tree = Grasshopper.DataTree[object]()
h_tree = Grasshopper.DataTree[object]()

table = []
for ti, tt in enumerate(timber_types):
    blist = _dedupe(sorted(widths.get(tt, [])))
    b_tree.AddRange(blist, GH_Path(ti))

    line = "%s:" % tt
    for bi, b in enumerate(blist):
        hlist = _dedupe(sorted(heights.get((tt, b), [])))
        h_tree.AddRange(hlist, GH_Path(ti, bi))
        line += "\n  b = %g -> h: %s" % (
            b, ", ".join("%g" % h for h in hlist) if hlist else "(none)")
    table.append(line)

if err:
    table.append("ERROR = %s" % err)
if not timber_types:
    table.append("<no timber types returned - check debug output>")

debug = "fetched %d timber types, %d widths, %d (type,width) height sets\n" \
    % (len(timber_types),
       sum(len(v) for v in widths.values()),
       len(heights)) + raw
