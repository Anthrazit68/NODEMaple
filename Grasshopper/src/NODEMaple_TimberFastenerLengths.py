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
NODEMaple Timber Fastener Lengths

Fetches the available lengths for ONE selected fastener member in one
Maple process, as a numeric list ready to populate a value list
(VL_length). This closes the fastener cascade:

  Filter -> VL_member -> THIS COMPONENT -> VL_length -> Properties

Kept as a separate component so that the length selection can be fed
into the Properties component without creating a cyclic dependency.

UNITS POLICY: the Maple module returns all quantities WITH their units.
The module call returns the raw length list (with units); unit
stripping and rounding happen HERE (Grasshopper side), in the printf
of the generated query script, so the value list gets plain numbers.

Maple query used:
  NODETimberFasteners:-Property("value", <type>, <member>, <d>, "-", "lengths")
  -> list of available lengths, WITH units
  (diameter "-" = auto: unique diameter with data)

Input:
  fastener_type : "Nail", "Screw", "Bolt", "Dowel" (from types output)
  member        : "producer@product" (picked from VL_member)
  diameter      : number, e.g. 6.2 (optional - empty -> auto selection)
  maple_version : Maple year, e.g. "2026" (ignored if MAPLE env var is set)

Output:
  lengths : flat list of available lengths (unit-free numbers, ascending)
  lengths_tree : same, as a single-branch tree
  debug   : raw Maple output with a request summary header
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
# Input normalisation
# ---------------------------------------------------------------------------
def norm_str(x):
    """Trim and strip quotes from an input string; '' -> '-' (wildcard)."""
    if x is None:
        return "-"
    s = str(x).strip().strip('"').strip("'").strip()
    return s if s else "-"

def norm_num(x):
    """Normalise a numeric input; empty -> '-' (auto inside Maple)."""
    if x is None:
        return "-"
    s = str(x).strip().strip('"').strip("'").strip()
    if not s:
        return "-"
    try:
        return str(float(s))
    except ValueError:
        return s

def num_or_dash(x):
    """Quote "-" wildcards, pass numbers bare (bare '-' is invalid Maple)."""
    s = norm_num(x)
    return '"-"' if s == "-" else s

ftype = norm_str(fastener_type)
m_in  = norm_str(member)
d_arg = num_or_dash(diameter)

# ---------------------------------------------------------------------------
# Script: fetch the length list of the selected member
# The module returns the raw length list WITH units -> strip HERE
# (Grasshopper side), rounded, and emit one LEN|<value>|<unit> line per
# element so the unit stays visible in debug.
# ---------------------------------------------------------------------------
script = "\n".join([
    "kernelopts(printbytes=false):",
    "interface(prettyprint=0):",
    "try",
    f'  llen := NODETimberFasteners:-Property("value", "{ftype}", "{m_in}", {d_arg}, "-", "lengths"):',
    '  for x in llen do',
    '    q := Units:-Split(x):',
    '    printf("LEN|%a|%a\\n", round(evalf(q[1])), q[2]):',
    "  end do:",
    "catch:",
    "end try:",
    "quit:",
]) + "\n"

raw = run_maple_script(script)

# ---------------------------------------------------------------------------
# Parse results
# ---------------------------------------------------------------------------
lengths = []
for line in raw.splitlines():
    s = line.strip()
    if not s.startswith("LEN|"):
        continue
    parts = s.split("|", 2)
    payload = parts[1].strip() if len(parts) > 1 else ""
    if not payload:
        continue
    t = payload
    if t.endswith("."):            # %a may print 120. -> "120."
        t = t[:-1]
    try:
        lengths.append(float(t))
    except ValueError:
        if "/" in t:               # rational such as 31/5
            try:
                a, b = t.split("/", 1)
                lengths.append(float(a) / float(b))
            except ValueError:
                pass
        else:                      # keep raw rather than drop silently
            lengths.append(t)
lengths.sort(key=lambda v: v if isinstance(v, float) else 0)

# Single-branch tree for the value list
lengths_tree = Grasshopper.DataTree[object]()
if lengths:
    lengths_tree.AddRange(lengths, GH_Path(0))

debug = ("request: type=%s member=%s d=%s, got %d lengths\n"
         % (ftype, m_in, d_arg.replace('"', ""), len(lengths))) + raw