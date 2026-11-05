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
NODEMaple Steel Profile Properties

Fetches section properties for a single section in one Maple process.
Mirrors NODEMaple Material Properties (materials), but targets
NODESteelProfiles_<family> modules.

Input:
  family        : family name, e.g. "I", "CF_RHS" (from families output)
  section       : section name, e.g. "IPE 200", "RHS 40 x 20 x 2"
  prop_names    : list of section property names (List Access!)
  maple_version : Maple year, e.g. "2026" (ignored if MAPLE env var is set)

Output:
  names_in : echo of the requested property names (ordered)
  values   : parallel list of numeric values (None for text properties)
  units    : parallel list of unit strings ("" where none)
  texts    : parallel list of text values (None for numeric properties)
  table    : display list, "name = value unit" one line per property
  debug    : raw Maple output, preceded by a send/receive summary """

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
# Main execution
# ---------------------------------------------------------------------------
family = str(family).strip()
module_name = "NODESteelProfiles_" + family
section = str(section).strip()

# Normalize the incoming names: trim whitespace and any surrounding quotes.
prop_list = []
for p in (prop_names if prop_names else []):
    s = str(p).strip().strip('"').strip("'")
    if s:
        prop_list.append(s)

# Build the Maple query line
query_line = f'pval := {module_name}:-Property("{section}", pname):'

# Quoted list literal — names contain commas (e.g. "W_el,y").
maple_list = "[" + ", ".join('"%s"' % p for p in prop_list) + "]"

# Protocol: ASCII "|" separator only, with try/catch for non-servable names.
script = (
    f'kernelopts(printbytes=false):\n'
    f'interface(prettyprint=0):\n'
    f'M := {module_name}:\n'
    f'sect := "{section}":\n'
    f'props := {maple_list}:\n'
    f'for i from 1 to numelems(props) do\n'
    f'  pname := props[i]:\n'
    f'  try\n'
    f'    pval := M:-Property(sect, pname):\n'
    f'  catch:\n'
    f'    printf("REC|%s|skip|\\n", pname):\n'
    f'    next;\n'
    f'  end try:\n'
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

debug = "sent %d names, parsed %d records\n" % (len(names_in), len(recs)) + raw