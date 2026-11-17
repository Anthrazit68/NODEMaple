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
NODEMaple Beam Design (EC5_6, all loadcases, XML export)

Full beam ULS design driven from Grasshopper:

  - project metadata (project number, title, client)
  - position metadata (position number, text)
  - material + section via library calls (GetMaterialdata /
    GetSectiondata), registered in the catalogues for XML export
  - multiple load cases, calculated one after another through
    NODETimberGUI:-Main_EC5_6("CalculateAllLoadcases")
  - input saved to a NODEMaple-compatible .xml file
    (NODEXML:-XMLFileInOut("export", ..., filename) - requires the
    headless filename extension in NODEXML.mm)

IMPORTANT: ALL Maple procedures are called with their explicit
module prefix (NODEFunctions:-LibInitCommon, NODEFunctions:-
MASTERALARM, ...). Unqualified names are UNASSIGNED in a fresh
cmaple session - the call silently returns unevaluated and
WhateverYouNeed stays empty.

PERCENT RULE (applies PER LINE, not per script): a script line that
is substituted through Python's % operator must double its literal
Maple printf specifiers (%%s); a line assembled without %
substitution keeps them single (%s). Most of this script is plain
string assembly (single %s); the few lines with "% <value>" carry
doubled literals.

Load case tree contract (input "loadcases", set access to Tree):
  one branch per load case, exactly 7 numbers per branch:
      [0] alpha   [deg]     (0 = parallel to grain,
                             90 = perpendicular)
      [1] F_xd    [kN]      (tension +, compression -)
      [2] M_yd    [kNm]
      [3] M_zd    [kNm]
      [4] V_yd    [kN]
      [5] V_zd    [kN]
      [6] M_td    [kNm]
  Missing items count as 0 - so an EMPTY branch produces a
  loadcase with all-zero forces and (correctly) zero etas.
  "loadcase_names" (List access) holds one name per branch.

Design values are stored directly (d-fields), Gk/Qk fields are set
to "false" - mirroring the stored calculations of existing files
(e.g. Limtreboka example 1). Main_EC5_6 picks the checks
(6.1.x / 6.2.x / 6.3) automatically from the force combination.

Emits records:
  REC|lc|<name>|etamax|<value>
  REC|eta|<name>|<check>|<value>       one per executed check
  REC|code|<name>|<code>|<description>
  REC|summary|etamax|<value>
  REC|summary|governingloadcase|<name>
  REC|summary|governingcode|<code>
  REC|saved|text|<path>
  ERR|<message>

Input:
  project_number, project_title, client : project metadata (strings)
  position_number, position_text        : position metadata (strings)
  grade          : e.g. "GL 30c" (or full name "GL 30c / Service class 1 / ...")
  service_class  : "1" | "2" | "3"
  load_duration  : "Permanent" | "Long-term" | "Medium-term" | "Short-term" | "Instantaneous"
  section_name   : e.g. "Rectangular / 140x585"
  l_ky, l_kz, l_efy, l_efz : buckling / effective lengths [m]
  loadcases      : tree, 7 numbers per branch (see contract above)
  loadcase_names : list of strings, one per branch
  xml_path       : target .xml file
  overwrite      : if True, an existing file is deleted before the run
  maple_version  : Maple year, e.g. "2026" (ignored if MAPLE env var set)

Output:
  loadcase_list  : names in calculation order
  eta_tree       : branch per loadcase -> eta per executed check (sorted)
  etamax_tree    : branch per loadcase -> max eta of that loadcase
  code_tree      : branch per loadcase -> "<code> <description>"
  eta_max        : global maximum utilization
  governing_loadcase, governing_code : name / code of governing case
  saved          : True if the XML file was written
  error          : error message or None
  debug          : summary + raw Maple output

Requires the NODEXML.mm patch: XMLFileInOut and XMLWrite accept an
optional filename argument and skip all dialogs when it is given.

NOTE: the Maple<->Python protocol is ASCII-only ("|" as separator).
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

CALCULATIONTYPE = "NS-EN 1995-1-1, Section 6: Ultimate limit state design principles"
CALCULATIONTYPE_SHORT = "Eurocode 5 part 1-1 ULS"


def run_maple_script(script, timeout=180):
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
    """Python string -> safe Maple string literal, | stripped from it."""
    s = str(s).strip().replace("|", "/")
    return s.replace("\\", "\\\\").replace('"', '\\"')


def mnum(v, unit=None):
    """Python number -> Maple literal, with unit attached when given."""
    try:
        v = float(v)
    except (TypeError, ValueError):
        v = 0.0
    if v == 0.0:
        return "0"
    if unit:
        return "%.10g*Unit(%s)" % (v, unit)
    return "%.10g" % v


# ---------------------------------------------------------------------------
# Inputs
# ---------------------------------------------------------------------------

grade = str(grade).strip() if grade else ""
if "/" in grade or not (grade and service_class and load_duration):
    material_name = grade                       # assume full name given
else:
    material_name = "%s / Service class %s / %s" % (
        grade, str(service_class).strip(), str(load_duration).strip())
section_name = str(section_name).strip() if section_name else ""
xml_path = str(xml_path).strip() if xml_path else ""
overwrite = bool(overwrite)

if xml_path and overwrite and os.path.exists(xml_path):
    try:
        os.remove(xml_path)
    except OSError:
        pass

# loadcases tree -> ordered list of (name, [7 values])
if hasattr(loadcases, "Branches"):
    branches = [list(br) for br in loadcases.Branches]
else:
    branches = [list(loadcases)] if loadcases else []

if loadcase_names:
    names = [str(n) for n in loadcase_names]
else:
    names = ["LC%d" % (i + 1) for i in range(len(branches))]
while len(names) < len(branches):
    names.append("LC%d" % (len(names) + 1))

cases = []
for i, br in enumerate(branches):
    vals = [0.0] * 7
    for j in range(min(7, len(br))):
        try:
            vals[j] = float(br[j])
        except (TypeError, ValueError):
            vals[j] = 0.0
    cases.append((names[i], vals))

if not cases:
    raise ValueError("no loadcases given - connect a tree with one "
                     "branch (7 numbers) per loadcase")
if not material_name:
    raise ValueError("material name missing - connect grade/"
                     "service_class/load_duration or a full name")
if not section_name:
    raise ValueError("section name missing, e.g. \"Rectangular / 140x585\"")
if not xml_path:
    raise ValueError("xml_path missing - target file for the calculation")

# ---------------------------------------------------------------------------
# Maple script assembly
# PERCENT RULE per line: lines with "% <value>" use %%s for literal Maple
# specifiers; all other lines use plain %s / %a.
# ---------------------------------------------------------------------------

L = []
A = L.append

A('kernelopts(printbytes=false):')
A('interface(prettyprint=0):')
A('WhateverYouNeed := table():')
A('')
A('# --- skeleton: tables, catalogs, calculationtype, storeitems ---------')
A('# NOTE: explicit module prefix - unqualified calls do NOT resolve')
A('# in a fresh cmaple session!')
A('NODEFunctions:-LibInitCommon(WhateverYouNeed, "%s"):'
  % mstr(CALCULATIONTYPE))
A('if not assigned(WhateverYouNeed["warnings"]) then')
A('    printf("ERR|LibInitCommon did not initialize WhateverYouNeed\\n"):')
A('    quit:')
A('end if:')
A('NODETimberGUI:-InitSpecific_EC5_6():')
A('WhateverYouNeed["calculations"]["calculationtype_short"] := "%s":'
  % mstr(CALCULATIONTYPE_SHORT))
A('WhateverYouNeed["calculations"]["suppress_gui"] := true:')
A('WhateverYouNeed["material"] := "timber":')
A('')
A('# --- project and position metadata ------------------------------------')
A('WhateverYouNeed["projectdata"] := table([')
A('    "projectnumber" = "%s",' % mstr(project_number))
A('    "projecttitle"  = "%s",' % mstr(project_title))
A('    "client"        = "%s"' % mstr(client))
A(']):')
A('WhateverYouNeed["calculations"]["positionnumber"] := "%s":'
  % mstr(position_number))
A('WhateverYouNeed["calculations"]["positiontitle"] := "%s":'
  % mstr(position_text))
A('WhateverYouNeed["calculations"]["loadvariables"] := {"alpha", '
  '"F_xGk", "F_xQk", "F_xd", "V_yGk", "V_yQk", "V_yd", "V_zGk", "V_zQk", '
  '"V_zd", "M_yGk", "M_yQk", "M_yd", "M_zGk", "M_zQk", "M_zd", "M_tGk", '
  '"M_tQk", "M_td"}:')
A('')
A('# --- active material and section, registered for XML export ----------')
A('matname := "%s":' % mstr(material_name))
A('sectname := "%s":' % mstr(section_name))
A('NODETimberEN1995:-GetMaterialdata(matname, WhateverYouNeed):')
A('NODETimberEN1995:-GetSectiondata(sectname, WhateverYouNeed):')
A('if not assigned(WhateverYouNeed["materialdata"]["name"]) then')
A('    WhateverYouNeed["materialdata"]["name"] := matname:')
A('end if:')
A('if not assigned(WhateverYouNeed["sectiondata"]["name"]) then')
A('    WhateverYouNeed["sectiondata"]["name"] := sectname:')
A('end if:')
A('if not assigned(WhateverYouNeed["sectiondata"]["sectiontype"]) then')
A('    WhateverYouNeed["sectiondata"]["sectiontype"] := "Rectangular":')
A('end if:')
A('WhateverYouNeed["materials"][matname] := '
  'eval(WhateverYouNeed["materialdata"]):')
A('WhateverYouNeed["sections"][sectname] := '
  'eval(WhateverYouNeed["sectiondata"]):')
A('WhateverYouNeed["calculations"]["activesettings"]["activematerial"] '
  ':= matname:')
A('WhateverYouNeed["calculations"]["activesettings"]["activesection"] '
  ':= sectname:')
A('')
A('# --- structure: straight prismatic beam + buckling lengths -----------')
A('structure := WhateverYouNeed["calculations"]["structure"]:')
A('structure["code_64"] := table(["ConstructionType" = "-", '
  '"alpha_ap" = 0, "tapered_N" = "false", "r_in" = 0, "l_curve" = 0, '
  '"t_lam" = 0]):')
A('structure["buckling"] := table([')
A('    "l_ky"  = %s,' % mnum(l_ky, "'m'"))
A('    "l_kz"  = %s,' % mnum(l_kz, "'m'"))
A('    "l_efy" = %s,' % mnum(l_efy, "'m'"))
A('    "l_efz" = %s' % mnum(l_efz, "'m'"))
A(']):')
A('structure["code_652"] := table(["endnotched" = "false", '
  '"endnotchedType" = "6.11(b)", "h_ef" = 80*Unit(mm), '
  '"l_incl" = 100*Unit(mm), "x_652" = 0]):')
A('structure["code_622"] := table(["h_622" = '
  'eval(WhateverYouNeed["sectiondata"]["h"])]):')
A('structure["code_615"] := table(["type_615" = "b", "a_615" = 0, '
  '"l_615" = 225*Unit(mm), "l1_615" = 7500*Unit(mm)]):')
A('try')
A('    NODETimberEN1995:-calculate_k_64():')
A('catch:')
A('    printf("ERR|calculate_k_64 failed: %a\\n", lastexception):')
A('end try:')
A('if not assigned(WhateverYouNeed["results"]["k_64"]["k_m_alpha"]) then')
A('    WhateverYouNeed["results"]["k_64"] := table(')
A('        ["k_m_alpha" = 1, "k_r" = 1, "k_l" = 1]):')
A('end if:')
A('')
A('# --- loadcases (design values, Gk/Qk false - as stored sheets) --------')

for i, (cname, vals) in enumerate(cases):
    alpha, fxd, myd, mzd, vyd, vzd, mtd = vals
    if alpha == 0:
        a_s = "0"
    else:
        a_s = "%.10g*Unit(degrees)" % alpha
    A('lc := table([')
    A('    "name"   = "%s",' % mstr(cname))
    A('    "alpha"  = %s,' % a_s)
    A('    "F_xGk"  = "false", "F_xQk" = "false", "F_xd"  = %s,'
      % mnum(fxd, "kN"))
    A('    "M_yGk"  = "false", "M_yQk" = "false", "M_yd"  = %s,'
      % mnum(myd, "'kN*m'"))
    A('    "M_zGk"  = "false", "M_zQk" = "false", "M_zd"  = %s,'
      % mnum(mzd, "'kN*m'"))
    A('    "V_yGk"  = "false", "V_yQk" = "false", "V_yd"  = %s,'
      % mnum(vyd, "kN"))
    A('    "V_zGk"  = "false", "V_zQk" = "false", "V_zd"  = %s,'
      % mnum(vzd, "kN"))
    A('    "M_tGk"  = "false", "M_tQk" = "false", "M_td"  = %s'
      % mnum(mtd, "'kN*m'"))
    A(']):')
    A('WhateverYouNeed["calculations"]["loadcases"]["%s"] := eval(lc):'
      % mstr(cname))
    A('')

A('loadcasenames := [%s]:' % ", ".join('"%s"' % mstr(c) for c, _ in cases))
A('WhateverYouNeed["calculations"]["calculatingAllLoadcases"] := true:')
A('')
A('# --- run all loadcases, capture per-case results ----------------------')
A('overallmax := 0:')
A('maxlc := "":')
A('maxcode := "":')
A('maxdesc := "":')
A('aborted := false:')
A('for lcname in loadcasenames do')
A('    WhateverYouNeed["calculations"]["activesettings"]'
  '["activeloadcase"] := lcname:')
A('    try')
A('        NODETimberGUI:-Main_EC5_6("CalculateAllLoadcases"):')
A('    catch:')
A('        printf("ERR|Main_EC5_6 failed for %s: %a\\n", lcname, '
  '[lastexception]):')
A('        aborted := true:')
A('        break:')
A('    end try:')
A('    etatab := eval(WhateverYouNeed["results"]["eta"]):')
A('    codetab := eval(WhateverYouNeed["results"]["comments"]):')
A('    emax := evalf(etatab["max"]):')
A('    printf("REC|lc|%s|etamax|%a\\n", lcname, emax):')
A('    for k in [indices(etatab)] do')
A('        if op(k) <> "max" then')
A('            printf("REC|eta|%s|%a|%a\\n", lcname, op(k), '
  'evalf(etatab[op(k)])):')
A('        end if:')
A('    end do:')
A('    printf("REC|code|%s|%a|%a\\n", lcname, '
  'codetab["usedcode"], codetab["usedcodeDescription"]):')
A('    if emax > overallmax then')
A('        overallmax := emax:')
A('        maxlc := lcname:')
A('        maxcode := codetab["usedcode"]:')
A('        maxdesc := codetab["usedcodeDescription"]:')
A('    end if:')
A('    if NODEFunctions:-MASTERALARM(WhateverYouNeed["warnings"]) then')
A('        printf("ERR|fatal warning in loadcase %s\\n", lcname):')
A('        aborted := true:')
A('        break:')
A('    end if:')
A('end do:')
A('WhateverYouNeed["calculations"]["calculatingAllLoadcases"] := false:')
A('')
A('# --- set governing loadcase active, save to XML -----------------------')
A('if maxlc <> "" then')
A('    WhateverYouNeed["calculations"]["activesettings"]'
  '["activeloadcase"] := maxlc:')
A('end if:')
A('printf("REC|summary|etamax|%a\\n", overallmax):')
A('printf("REC|summary|governingloadcase|%s\\n", maxlc):')
A('printf("REC|summary|governingcode|%s\\n", maxcode):')
A('printf("REC|summary|governingdescription|%s\\n", maxdesc):')
A('if aborted = false then')
A('    try')
A('        NODEXML:-XMLFileInOut("export", WhateverYouNeed, "%s"):'
  % mstr(xml_path.replace("\\", "/")))
# NOTE: this line IS %-formatted (path substitution below), so the
# literal Maple specifier is doubled -> Maple receives a single %s.
A('        printf("REC|saved|text|%%s\\n", "%s"):'
  % mstr(xml_path.replace("\\", "/")))
A('    catch:')
A('        printf("ERR|XML export failed: %a\\n", [lastexception]):')
A('    end try:')
A('end if:')
A('quit:')

script = "\n".join(L) + "\n"

raw = run_maple_script(script)

# ---------------------------------------------------------------------------
# Parse results
# ---------------------------------------------------------------------------

lc_max = {}          # {name: float}
lc_eta = {}          # {name: [(check, value), ...]}
lc_code = {}         # {name: (code, description)}
summary_max = None
gov_lc = ""
gov_code = ""
saved = False
err = None

for line in raw.splitlines():
    s = line.strip()
    parts = s.split("|")
    if s.startswith("REC|lc|") and len(parts) == 5:
        try:
            lc_max[parts[2]] = float(parts[4])
        except ValueError:
            pass
    elif s.startswith("REC|eta|") and len(parts) == 5:
        try:
            lc_eta.setdefault(parts[2], []).append(
                (parts[3], float(parts[4])))
        except ValueError:
            pass
    elif s.startswith("REC|code|") and len(parts) >= 5:
        lc_code[parts[2]] = (parts[3], parts[4])
    elif s.startswith("REC|summary|etamax|") and len(parts) == 4:
        try:
            summary_max = float(parts[3])
        except ValueError:
            pass
    elif s.startswith("REC|summary|governingloadcase|") and len(parts) == 4:
        gov_lc = parts[3]
    elif s.startswith("REC|summary|governingcode|") and len(parts) == 4:
        gov_code = parts[3]
    elif s.startswith("REC|saved|"):
        saved = True
    elif s.startswith("ERR|") and err is None:
        err = s[len("ERR|"):]

# order outputs by input order
loadcase_list = [n for n, _ in cases]

eta_tree = Grasshopper.DataTree[object]()
etamax_tree = Grasshopper.DataTree[object]()
code_tree = Grasshopper.DataTree[object]()

for i, cname in enumerate(loadcase_list):
    checks = sorted(lc_eta.get(cname, []))
    eta_tree.AddRange([v for _, v in checks], GH_Path(i))
    m = lc_max.get(cname)
    etamax_tree.AddRange([m if m is not None else -1.0], GH_Path(i))
    c = lc_code.get(cname, ("", ""))
    code_tree.AddRange(["%s %s" % c], GH_Path(i))

eta_max = summary_max if summary_max is not None else \
    (max(lc_max.values()) if lc_max else None)

governing_loadcase = gov_lc
governing_code = gov_code

error = err

debug = ("material : %s\nsection  : %s\n"
         "loadcases: %s\nxml_path : %s\n"
         "parsed %d loadcase results, %d check records\n"
         % (material_name, section_name, ", ".join(loadcase_list),
            xml_path, len(lc_max), sum(len(v) for v in lc_eta.values()))
         ) + raw
