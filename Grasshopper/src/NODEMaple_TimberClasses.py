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
NODEMaple Timber Classes

Queries the service-class and load-duration-class enums from the
NODETimberEN1995 library (exported procs GetServiceclasses /
GetLoaddurationclasses, added next to kmod in Timber/EC5_general.mm),
plus the k_mod matrix via the now-exported kmod, and gamma_M /
timbertype for a chosen grade.

All class definitions come from the library itself - nothing is
mirrored in this component.

Emits records:
  REC|sc|<index>|<service class name>
  REC|ldc|<index>|<load duration class name>
  REC|kmod|<sc>|<ldc>|<value>
  REC|gamma_M|num|<value>|
  REC|timbertype|text|<string>

Input:
  grade         : representative grade, e.g. "GL 30c" (drives gamma_M
                   and timbertype; k_mod itself is grade-independent)
  maple_version : Maple year, e.g. "2026" (ignored if MAPLE env var set)

Output:
  service_classes        : ["1", "2", "3"]              -> Value List
  load_duration_classes  : ["Permanent", ...]            -> Value List
  kmod_tree              : branch per service class -> k_mod per ldc
  kmod_zeroes            : combinations where kmod returned 0
                           (should always be 0)
  gamma_M                : partial factor for the grade's timber type
  timbertype             : e.g. "Glued laminated timber"
  table                  : display list, one line per combination
  debug                  : send/receive summary + raw Maple output

Requires: NODETimberEN1995 rebuilt with GetServiceclasses,
GetLoaddurationclasses exported and kmod moved from local to export.

NOTE: the Maple<->Python protocol is ASCII-only ("|" as field separator).
NOTE: Maple printf specifiers inside the script string are written as
      %%d / %%s / %%a so Python's %-formatting leaves them alone; only
      %(g)s is a live Python placeholder.
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


def mstr(s):
    """Make a Python string safe as a double-quoted Maple string literal."""
    return str(s).replace("\\", "\\\\").replace('"', '\\"')


grade = str(grade).strip() if grade else "GL 30c"

# ---------------------------------------------------------------------------
# Maple script: enums and k_mod straight from the library
# ---------------------------------------------------------------------------

# NOTE: all Maple printf specifiers are doubled (%%d, %%s, %%a) because
# the string is processed with Python %-formatting below. The only
# live Python placeholder is %(g)s.
script = (
    'kernelopts(printbytes=false):\n'
    'interface(prettyprint=0):\n'
    'scs := NODETimberEN1995:-GetServiceclasses():\n'
    'ldcs := NODETimberEN1995:-GetLoaddurationclasses():\n'
    'for i from 1 to numelems(scs) do\n'
    '  printf("REC|sc|%%d|%%s\\n", i, scs[i]):\n'
    'end do:\n'
    'for i from 1 to numelems(ldcs) do\n'
    '  printf("REC|ldc|%%d|%%s\\n", i, ldcs[i]):\n'
    'end do:\n'
    'for sc in scs do\n'
    '  for ldc in ldcs do\n'
    '    printf("REC|kmod|%%s|%%s|%%a\\n", sc, ldc, '
    'evalf(NODETimberEN1995:-kmod(ldc, sc))):\n'
    '  end do:\n'
    'end do:\n'
    '# gamma_M and timbertype for the chosen grade\n'
    'WhateverYouNeed := table(["warnings" = table()]):\n'
    'try\n'
    '  NODETimberEN1995:-GetMaterialdata("%(g)s", WhateverYouNeed):\n'
    '  gM := NODETimberEN1995:-gamma_M(WhateverYouNeed["materialdata"]["timbertype"]):\n'
    '  printf("REC|gamma_M|num|%%a|\\n", evalf(gM)):\n'
    '  printf("REC|timbertype|text|%%s\\n", '
    'WhateverYouNeed["materialdata"]["timbertype"]):\n'
    'catch:\n'
    '  printf("ERR|%%s\\n", lasterror):\n'
    'end try:\n'
    'quit:\n'
) % {"g": mstr(grade)}

raw = run_maple_script(script)

# ---------------------------------------------------------------------------
# Parse results
# ---------------------------------------------------------------------------

sc_by_idx = {}
ldc_by_idx = {}
kmod = {}        # {(sc, ldc): float}
gamma_M = None
timbertype = None
err = None

for line in raw.splitlines():
    s = line.strip()
    if s.startswith("REC|sc|") or s.startswith("REC|ldc|"):
        parts = s.split("|", 3)
        if len(parts) == 4:
            try:
                idx = int(parts[2])
            except ValueError:
                continue
            if parts[1] == "sc":
                sc_by_idx[idx] = parts[3].strip()
            else:
                ldc_by_idx[idx] = parts[3].strip()
    elif s.startswith("REC|kmod|"):
        parts = s.split("|")
        if len(parts) >= 5:
            try:
                kmod[(parts[2].strip(), parts[3].strip())] = float(parts[4])
            except ValueError:
                kmod[(parts[2].strip(), parts[3].strip())] = None
    elif s.startswith("REC|gamma_M|"):
        parts = s.split("|")
        try:
            gamma_M = float(parts[3])
        except (ValueError, IndexError):
            gamma_M = None
    elif s.startswith("REC|timbertype|"):
        parts = s.split("|", 3)
        if len(parts) == 4:
            timbertype = parts[3].strip()
    elif s.startswith("ERR|") and err is None:
        err = s[len("ERR|"):]

# preserve the library's order
service_classes = [sc_by_idx[i] for i in sorted(sc_by_idx)]
load_duration_classes = [ldc_by_idx[i] for i in sorted(ldc_by_idx)]

# k_mod matrix: branch per service class, values per load-duration class
kmod_tree = Grasshopper.DataTree[object]()
zeroes = 0
for i, sc in enumerate(service_classes):
    vals = []
    for ldc in load_duration_classes:
        v = kmod.get((sc, ldc))
        if not v:          # None or 0.0
            zeroes += 1
        vals.append(v)
    kmod_tree.AddRange(vals, GH_Path(i))

table = []
for ldc in load_duration_classes:
    row = ["%-13s" % ldc]
    for sc in service_classes:
        v = kmod.get((sc, ldc))
        row.append("SC %s: %s" % (sc, ("%.2f" % v) if v else "0 (!)"))
    table.append("k_mod  " + "   ".join(row))
if gamma_M is not None:
    table.append("gamma_M = %.2f  (%s)" % (gamma_M, timbertype or "?"))
if err:
    table.append("ERROR   = %s" % err)

kmod_zeroes = zeroes
debug = "grade    : %s\nfetched %d service classes, %d load-duration classes\n" \
    % (grade, len(service_classes), len(load_duration_classes)) + raw
