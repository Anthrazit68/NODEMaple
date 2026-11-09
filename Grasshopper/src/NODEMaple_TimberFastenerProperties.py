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
NODEMaple Timber Fastener Properties

Fetches the mechanical properties for ONE selected fastener member in
one Maple process. Second half of the former combined component — the
"member" input is fed from a value list populated by
NODEMaple_TimberFastenerFilter.py.

Workflow:
  Filter -> value list (user picks) -> this component, together with the
  variable names from the Definitions component's metadata branch.

Variables (from the metadata branch of the Definitions component):
    fm, prod, bet, descr, serviceclass, d, l, dh, M_y_Rk, f_ax_k,
    f_head_k, f_tens_k, l1, l3, f_uk, B_max
  - numeric quantities return unit-bearing values (Units:-Split)
  - l (lengths) and dh (head diameters) vary with length ->
    returned as comma-joined, unit-free, rounded TEXT lists
  - descr/serviceclass are plain text

Auto-selections inside the Maple module (pass "-" / leave empty):
  - diameter: unique diameter with data for this product, otherwise
    an explicit diameter must be supplied
  - length  : shortest available length (or the supplied length,
    snapped to the nearest available key with tolerance)

Input:
  fastener_type : "Nail", "Screw", "Bolt", "Dowel" (from types output)
  member        : "producer@product" (picked from the value list)
  diameter      : number, e.g. 6.2 (optional - empty -> auto selection)
  length        : number, e.g. 120 (optional - empty -> shortest)
  prop_names    : list of variable names to fetch (List Access!)
  maple_version : Maple year, e.g. "2026" (ignored if MAPLE env var is set)

Output:
  names_in : echo of the requested variable names (ordered)
  values   : parallel list of numeric values (None for text properties)
  units    : parallel list of unit strings ("" where none)
  texts    : parallel list of text values (None for numeric properties)
  table    : display list, "name = value unit" one line per variable
  debug    : raw Maple output, preceded by a send/receive summary
"""

import os
import subprocess

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

    try:
        out, _ = proc.communicate(input=script, timeout=timeout)
        return out
    except subprocess.TimeoutExpired:
        proc.kill()
        proc.communicate()
        raise RuntimeError("Maple timed out after %s s" % timeout)

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
ls_arg = num_or_dash(length)

# Normalise the variable name list.
prop_list = []
for p in (prop_names if prop_names else []):
    s = str(p).strip().strip('"').strip("'")
    if s:
        prop_list.append(s)

# ---------------------------------------------------------------------------
# Script: one record per requested variable
# ---------------------------------------------------------------------------
if prop_list and m_in != "-":
    # Quoted list literal — quote every name for uniformity with
    # NODEMaple_MaterialProperties.py.
    maple_list = "[" + ", ".join('"%s"' % p for p in prop_list) + "]"
    script = "\n".join([
        "kernelopts(printbytes=false):",
        "interface(prettyprint=0):",
        f'vars := {maple_list}:',
        "for i from 1 to numelems(vars) do",
        "  pname := vars[i]:",
        "  try",
        f'    pval := NODETimberFasteners:-Property("value", "{ftype}", "{m_in}", {d_arg}, {ls_arg}, pname):',
        "  catch:",
        '    printf("REC|%s|skip|\\n", pname):',
        "    next;",
        "  end try;",
        "  if type(pval, string) then",
        '    printf("REC|%s|text|%s\\n", pname, pval):',
        "  else",
        "    try",
        "      q := Units:-Split(pval):",
        '      printf("REC|%s|num|%a|%a\\n", pname, evalf(q[1]), q[2]):',
        "    catch:",
        "      try",
        '        printf("REC|%s|num|%a|\\n", pname, evalf(pval)):',
        "      catch:",
        '        printf("REC|%s|skip|\\n", pname):',
        "      end try;",
        "    end try:",
        "  end if:",
        "end do:",
        "quit:",
    ]) + "\n"
    raw = run_maple_script(script)
else:
    # Nothing requested — no member or no variable list connected.
    raw = ""
    if not prop_list:
        raw = "(no prop_names connected, nothing fetched)\n"
    if m_in == "-":
        raw += "(no member connected, nothing fetched)\n"

# ---------------------------------------------------------------------------
# Parse results — output order follows the requested prop_list
# ---------------------------------------------------------------------------
names_in = list(prop_list)
values = []
units = []
texts = []
table = []

recs = {}
for line in raw.splitlines():
    s = line.strip()
    if not s.startswith("REC|"):
        continue
    parts = s.split("|")
    if len(parts) < 3:
        continue
    name = parts[1].strip()
    kind = parts[2].strip()
    payload = parts[3].strip() if len(parts) > 3 else ""
    unit = parts[4].strip() if len(parts) > 4 else ""
    recs[name] = (kind, payload, unit)

for name in names_in:
    kind, payload, unit = recs.get(name, ("missing", "", ""))
    if kind == "num":
        try:
            val = float(payload)
        except ValueError:
            val = None
        values.append(val)
        units.append(unit)
        texts.append(None)
        table.append("%s = %s %s" % (name, val, unit))
    elif kind == "text":
        values.append(None)
        units.append("")
        texts.append(payload)
        table.append("%s = %s" % (name, payload))
    elif kind == "missing":
        values.append(None)
        units.append("")
        texts.append(None)
        table.append("%s = <no record returned>" % name)
    else:
        values.append(None)
        units.append("")
        texts.append(None)
        table.append("%s = <not available>" % name)

debug = ("request: type=%s member=%s d=%s ls=%s, sent %d names, "
         "parsed %d records\n"
         % (ftype, m_in, d_arg.replace('"', ""), ls_arg.replace('"', ""),
            len(names_in), len(recs))) + raw