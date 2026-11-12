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
NODEMaple Timber Fastener Filter

Filters the timber fastener members by type and (optionally) diameter
and/or producer, returning the matching "producer@product" list in one
Maple process. First half of the former combined component — pair it
with NODEMaple_TimberFastenerProperties.py, whose "member" input is fed
from a value list populated by this component's output.

Typical workflow:
  Canvas 1 (Definitions) -> this filter -> value list (user picks one)
  -> TimberFastenerProperties (values per variable)

Maple query used:
  NODETimberFasteners:-Property(<type>, <d>, <producer>, "members")
  Pass "-" for d or producer to leave that filter open.

Input:
  fastener_type : "Nail", "Screw", "Bolt", "Dowel" (from types output)
  diameter      : number, e.g. 6.2 (optional - empty widens the filter;
                  decimals supported, tolerant comparison)
  producer      : producer name (optional - empty widens the filter)
  maple_version : Maple year, e.g. "2026" (ignored if MAPLE env var is set)

Output:
  filtered_members : flat list of members matching type+diameter/producer
  filtered_tree    : same, as a single-branch tree
  debug            : raw Maple output with a filter summary header
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
    """Normalise a numeric input; empty -> '-' (wildcard)."""
    if x is None:
        return "-"
    s = str(x).strip().strip('"').strip("'").strip()
    if not s:
        return "-"
    try:
        return str(float(s))
    except ValueError:
        return s

ftype = norm_str(fastener_type)
d_in  = norm_num(diameter)
p_in  = norm_str(producer)

# Diameter argument for the Maple statement: a bare number when given
# (e.g. 6.2), or the quoted string "-" when empty. Inserting a bare '-'
# would be a Maple syntax error (unary minus without operand).
if d_in == "-":
    d_arg = '"-"'
else:
    d_arg = d_in

# ---------------------------------------------------------------------------
# Script: filtered member list
# ---------------------------------------------------------------------------
script = "\n".join([
    "kernelopts(printbytes=false):",
    "interface(prettyprint=0):",
    f'FMEM := NODETimberFasteners:-Property("{ftype}", {d_arg}, "{p_in}", "members"):',
    "for e in FMEM do",
    '  printf("MEM|%s\\n", e):',
    "end do:",
    "quit:",
]) + "\n"

raw = run_maple_script(script)

# ---------------------------------------------------------------------------
# Parse results
# ---------------------------------------------------------------------------
filtered_members = []
for line in raw.splitlines():
    s = line.strip()
    if s.startswith("MEM|"):
        entry = s.split("|", 1)[1].strip().strip('"')
        if entry:
            filtered_members.append(entry)

# Single-branch tree for the filtered list
filtered_tree = Grasshopper.DataTree[object]()
if filtered_members:
    filtered_tree.AddRange(filtered_members, GH_Path(0))

debug = ("filters: type=%s d=%s producer=%s, got %d members\n"
         % (ftype, d_in, p_in, len(filtered_members))) + raw