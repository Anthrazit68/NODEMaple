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
NODEMaple Beam Bending Check (EC5 6.1.6)

Builds the global WhateverYouNeed table from scratch in a fresh cmaple
process (no XML file, no GUI), fills it via the exported library calls
GetMaterialdata / GetSectiondata, applies one design moment, and runs
the bending check EC5_616.

Expected sanity check (Limtreboka example 1):
  GL 30c / SC 1 / Medium-term, Rectangular / 140x585, M_yd = 142 kNm
  sigma_myd = 17.78 N/mm^2, f_md * kh = 20.92 N/mm^2  ->  eta ~ 0.85

Workflow:
  grade + service class + load duration  ->  composed material name
  b, h (or section name)                  ->  "Rectangular / bxh"
  -> GetMaterialdata -> GetSectiondata -> EC5_616(1, 1)

Input:
  maple_version  : Maple year, e.g. "2026" (ignored if MAPLE env var is set)
  grade          : e.g. "GL 30c" (from MaterialDefinitions members tree),
                   OR a full material name "GL 30c / Service class 1 / ..."
  service_class  : "1", "2" or "3"        (ignored if grade is a full name)
  load_duration  : "Permanent" | "Long-term" | "Medium-term"
                   | "Short-term" | "Instantaneous"
  section_name   : e.g. "Rectangular / 140x585"; if empty, composed from b, h
  b              : section width  [mm]   (used if section_name is empty)
  h              : section height [mm]   (used if section_name is empty)
  M_yd           : design moment [kNm] about the strong axis
  kcrity         : lateral-torsional buckling factor, default 1 (unsupported
                   in this v1; later to be produced by EC5_63 / 6.3.3)
  kcritz         : ditto for the weak axis, default 1

Output:
  eta        : utilization (float, None on failure); red if > 1
  utilized   : True if eta > 1
  usedcode   : code clause used, e.g. "6.1.6"
  comment    : description, e.g. "Bending"
  f_md       : design bending strength [N/mm^2]
  W_y        : section modulus [mm^3]
  kh         : size factor for h
  debug      : send/receive summary + raw Maple output

NOTE: the Maple<->Python protocol is ASCII-only ("|" as field separator).
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


def run_maple_script(script, timeout=120):
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


def mstr(s):
    """Make a Python string safe as a double-quoted Maple string literal."""
    return str(s).replace("\\", "\\\\").replace('"', '\\"')


# ---------------------------------------------------------------------------
# Input normalization
# ---------------------------------------------------------------------------

grade = str(grade).strip() if grade else ""
service_class = str(service_class).strip() if service_class else "1"
load_duration = str(load_duration).strip() if load_duration else "Medium-term"

# If the caller passes a full name (contains " / Service class "), use it as is.
if " / Service class " in grade:
    material_name = grade
else:
    material_name = "%s / Service class %s / %s" % (grade, service_class, load_duration)

section_name = str(section_name).strip() if section_name else ""
if not section_name:
    section_name = "Rectangular / %sx%s" % (
        str(b).strip(), str(h).strip())

try:
    M_yd_val = float(M_yd)
except (TypeError, ValueError):
    raise ValueError("M_yd must be a number in kNm")

try:
    kcrity_val = float(kcrity) if kcrity else 1.0
    kcritz_val = float(kcritz) if kcritz else 1.0
except (TypeError, ValueError):
    kcrity_val = 1.0
    kcritz_val = 1.0

# ---------------------------------------------------------------------------
# Maple script
# ---------------------------------------------------------------------------

# Record layout (fixed fields, ASCII separator):
#   REC|<name>|num|<value>|<unit>
#   REC|<name>|text|<string>
#   ERR|<message>
script = (
    'kernelopts(printbytes=false):\n'
    'interface(prettyprint=0):\n'

    '# -- build the global from scratch: no XML, no GUI ----------------\n'
    'WhateverYouNeed := table():\n'
    'WhateverYouNeed["warnings"] := table():\n'
    'WhateverYouNeed["results"] := table():\n'
    'WhateverYouNeed["results"]["k_64"] := table(["k_m_alpha" = 1, "k_r" = 1, "k_l" = 1]):\n'
    'WhateverYouNeed["calculations"] := table():\n'
    'WhateverYouNeed["calculations"]["activesettings"] := '
    'table(["activeloadcase" = "Moment"]):\n'
    'lc := table(["M_yd" = %(M)f * Units:-Unit(kN*m), "M_zd" = 0]):\n'
    'WhateverYouNeed["calculations"]["loadcases"] := table(["Moment" = eval(lc)]):\n'

    '# -- material and section from the library -----------------------\n'
    'try\n'
    '  NODETimberEN1995:-GetMaterialdata("%(mat)s", WhateverYouNeed):\n'
    '  NODETimberEN1995:-GetSectiondata("%(sec)s", WhateverYouNeed):\n'
    'catch:\n'
    '  printf("ERR|%%s\\n", lasterror):\n'
    '  quit:\n'
    'end try:\n'

    '# -- diagnostics --------------------------------------------------\n'
    'md := WhateverYouNeed["materialdata"]:\n'
    'sd := WhateverYouNeed["sectiondata"]:\n'
    'kh_ := NODETimberEN1995:-kh("h", WhateverYouNeed):\n'
    'q := Units:-Split(md["f_md"]):\n'
    '  printf("REC|f_md|num|%%a|%%a\\n", evalf(q[1]), q[2]):\n'
    'q := Units:-Split(sd["W_y"]):\n'
    '  printf("REC|W_y|num|%%a|%%a\\n", evalf(q[1]), q[2]):\n'
    'printf("REC|kh|num|%%a|\\n", evalf(kh_)):\n'

    '# -- bending check 6.1.6 ------------------------------------------\n'
    'try\n'
    '  eta, usedcode, comment := '
    'NODETimberEN1995:-EC5_616(%(kcy)f, %(kcz)f):\n'
    '  try\n'
    '    q := Units:-Split(eta):\n'
    '    printf("REC|eta|num|%%a|\\n", evalf(q[1])):\n'
    '  catch:\n'
    '    printf("REC|eta|num|%%a|\\n", evalf(eta)):\n'
    '  end try:\n'
    '  printf("REC|usedcode|text|%%s\\n", usedcode):\n'
    '  printf("REC|comment|text|%%s\\n", comment):\n'
    'catch:\n'
    '  printf("ERR|%%s\\n", lasterror):\n'
    'end try:\n'
    'quit:\n'
) % {
    "M": M_yd_val,
    "mat": mstr(material_name),
    "sec": mstr(section_name),
    "kcy": kcrity_val,
    "kcz": kcritz_val,
}

raw = run_maple_script(script)

# ---------------------------------------------------------------------------
# Parse results
# ---------------------------------------------------------------------------

recs = {}
err = None

for line in raw.splitlines():
    s = line.strip()
    if s.startswith("REC|"):
        parts = s.split("|")
        if len(parts) >= 3:
            name = parts[1].strip()
            kind = parts[2].strip()
            payload = parts[3].strip() if len(parts) > 3 else ""
            unit = parts[4].strip() if len(parts) > 4 else ""
            recs[name] = (kind, payload, unit)
    elif s.startswith("ERR|") and err is None:
        err = s[len("ERR|"):]

def _num(name):
    kind, payload, _u = recs.get(name, ("missing", "", ""))
    if kind == "num":
        try:
            return float(payload)
        except ValueError:
            return None
    return None

def _text(name):
    kind, payload, _u = recs.get(name, ("missing", "", ""))
    return payload if kind == "text" else None

eta = _num("eta")
f_md = _num("f_md")
W_y = _num("W_y")
kh = _num("kh")
usedcode = _text("usedcode")
comment = _text("comment")

if err is not None:
    eta = None
    utilized = False
else:
    utilized = (eta is not None and eta > 1.0)

table = []
if eta is not None:
    table.append("eta        = %.3f  %s" % (eta, "NOT OK" if utilized else "OK"))
if usedcode:
    table.append("usedcode   = %s (%s)" % (usedcode, comment or ""))
if f_md is not None:
    table.append("f_md       = %.2f N/mm^2" % f_md)
if W_y is not None:
    table.append("W_y        = %.0f mm^3" % W_y)
if err:
    table.append("ERROR      = %s" % err)
if not table:
    table.append("<no records returned>")

debug = "material : %s\nsection  : %s\nM_yd     = %g kNm\nsent 1 moment check, parsed %d records\n" \
    % (material_name, section_name, M_yd_val, len(recs)) + raw
