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
NODEMaple Material Properties
Fetches property values for a single material grade in one Maple process.

Workflow:
  material -> grade -> variables -> values

Accepts the variable list from the metadata branch (or any list of
property names). Returns parallel lists, so values[i] / units[i] /
texts[i] all belong to names_in[i].

Steel: use the composite grade "S 275 H@NS-EN 10210-1" to select the
standard; the "@code" suffix is split off and passed as the 3rd
Property argument.

Input:
  category      : "steel", "timber", "concrete"
  grade         : e.g. "C24", "S 275 H@NS-EN 10210-1"
  prop_names    : list of property names to fetch (List Access!)
  maple_version : Maple year, e.g. "2026" (ignored if MAPLE env var is set)

Output:
  names_in : echo of the requested property names (ordered)
  values   : parallel list of numeric values (None for text properties)
  units    : parallel list of unit strings ("" where none)
  texts    : parallel list of text values (None for numeric properties)
  table    : display list, "name = value unit" one line per property
  debug    : raw Maple output, preceded by a send/receive summary

NOTE: the Maple<->Python protocol is ASCII-only ("|" as field separator).
Non-ASCII separators do not survive the cmaple stdin/stdout round trip.
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

    out, _ = proc.communicate(input=script, timeout=timeout)
    return out

def category_to_module(category):
    """Map a material category to its Maple module name."""
    return "NODE" + category.capitalize() + "Material"

# ---------------------------------------------------------------------------
# Main execution
# ---------------------------------------------------------------------------
category = str(category).strip().lower()
module_name = category_to_module(category)
grade = str(grade).strip()

# Normalise the incoming names: trim whitespace and any surrounding quotes.
prop_list = []
for p in (prop_names if prop_names else []):
    s = str(p).strip().strip('"').strip("'")
    if s:
        prop_list.append(s)

# Steel: split composite grade "S 275 H@NS-EN 10210-1" into grade + code.
if "@" in grade:
    g, code = grade.rsplit("@", 1)
    query_line = f'pval := {module_name}:-Property("{g}", "{code}", pname):'
else:
    g = grade
    query_line = f'pval := {module_name}:-Property("{g}", pname):'

# Pass the property list into Maple as a quoted list literal.
# Names contain commas ("f_m,k"), so every element MUST be quoted.
maple_list = "[" + ", ".join('"%s"' % p for p in prop_list) + "]"

# One record per property, fixed field layout:
#   REC|<name>|num|<value>|<unit>
#   REC|<name>|text|<string>
#   REC|<name>|skip|
# "|" is ASCII and proven to survive the pipe. Neither property names
# nor unit expressions contain it.
script = (
    f'kernelopts(printbytes=false):\n'
    f'interface(prettyprint=0):\n'
    f'props := {maple_list}:\n'
    f'for i from 1 to numelems(props) do\n'
    f'  pname := props[i]:\n'
    f'  {query_line}\n'
    f'  if type(pval, string) then\n'
    f'    printf("REC|%s|text|%s\\n", pname, pval):\n'
    f'  else\n'
    f'    try\n'
    f'      q := Units:-Split(pval):\n'
    f'      printf("REC|%s|num|%a|%a\\n", pname, evalf(q[1]), q[2]):\n'
    f'    catch:\n'
    f'      try\n'
    f'        printf("REC|%s|num|%a|\\n", pname, evalf(pval)):\n'
    f'      catch:\n'
    f'        printf("REC|%s|skip|\\n", pname):\n'
    f'      end try:\n'
    f'    end try:\n'
    f'  end if:\n'
    f'end do:\n'
    f'quit:\n'
)

raw = run_maple_script(script)

# ---------------------------------------------------------------------------
# Parse results — output order follows the requested prop_list
# ---------------------------------------------------------------------------
names_in = list(prop_list)
values = []
units = []
texts = []
table = []

recs = {}          # {name: (kind, payload, unit)}
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
        table.append("%s = <not evaluable>" % name)

debug = "sent %d names, parsed %d records\n" % (len(names_in), len(recs)) + raw