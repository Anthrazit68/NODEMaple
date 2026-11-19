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
NODEMaple Beam Design Runner (groups edition, with check_tree)

Consumes JSON group objects from the group components:

  project   <- NODEMaple_ProjectParameters  (Item access, 1 JSON,
                                               FLATTEN this input)
  structure <- NODEMaple_BeamStructure       (Item access, 1 JSON,
                                               FLATTEN this input)
  loadcases <- NODEMaple_LoadDefinition xN   (Item access, N JSONs,
              FLATTEN this input; connect several components'
              outputs, Grasshopper merges them, Flatten collapses
              branches so the component runs ONCE)

JSON contracts:

  project  : {"project_number": "...", "project_title": "...",
              "client": "...", "position_number": "...",
              "position_text": "..."}
  structure: {"material_name": "GL 30c / Service class 1 / Permanent",
              "section_name": "Rectangular / 140x585",
              "l_ky": .., "l_kz": .., "l_efy": .., "l_efz": ..}
  loadcase : {"name": "...", "alpha": .., "F_xd": .., "M_yd": ..,
              "M_zd": .., "V_yd": .., "V_zd": .., "M_td": ..}

Per loadcase Main_EC5_6 picks the checks (6.1.x / 6.2.x / 6.3)
automatically from the force combination. Bending routes through
6.3.3 lateral-torsional buckling using the buckling lengths.

Outputs per loadcase (branch i = loadcase i, order = input order):
  eta_tree    : eta per executed check, SORTED BY VALUE ascending
                (governing check = last item in a branch)
  check_tree  : check code for each eta in eta_tree - item i in
                check_tree labels item i in eta_tree ("616" etc.)
  etamax_tree : max eta of that loadcase
  code_tree   : governing check "<code> <description>" of that case

Emits records (debug):
  DBG|lc|<name>|alpha=..,F_xd=..,...   echo of parsed forces
  REC|lc|<name>|etamax|<value>
  REC|eta|<name>|<check>|<value>       one per executed check
  REC|code|<name>|<code>|<description>
  REC|summary|etamax|<value>
  REC|summary|governingloadcase|<name>
  REC|summary|governingcode|<code>
  REC|saved|text|<path>
  ERR|<message>

Input:
  project, structure : JSON strings from the group components
  loadcases          : JSON strings from LoadDefinition components
  xml_path           : target .xml file
  overwrite          : True -> delete existing file first
  run                : True -> execute; False -> only echo inputs
                       (dry run without spawning Maple)
  maple_version      : Maple year, e.g. "2026" (ignored if MAPLE set)

Output:
  loadcase_list       : names in calculation order
  eta_tree            : eta per executed check (sorted by value)
  check_tree          : check code per eta (labels eta_tree items)
  etamax_tree         : max eta per loadcase
  code_tree           : governing code+description per loadcase
  eta_max             : global maximum utilization
  governing_loadcase  : name of governing case
  governing_code      : code of governing case
  saved               : True if the XML file was written
  error               : error message or None
  debug               : summary + raw Maple output

Requires the NODEXML.mm patch: XMLFileInOut and XMLWrite accept an
optional filename argument and skip all dialogs when it is given.

NOTE: the Maple<->Python protocol is ASCII-only ("|" as separator);
human strings are transliterated by the group components and again
by mstr() here.
NOTE: PERCENT RULE per line: lines with "% <value>" use %%s for
literal Maple specifiers; lines without keep %s single.
"""

import os
import json
import subprocess
import Grasshopper
from Grasshopper.Kernel.Data import GH_Path

# ---------------------------------------------------------------------------
# ASCII transliteration (safety net; group components also apply it)
# ---------------------------------------------------------------------------

TRANSLATE = {
    "å": "a", "ø": "o", "æ": "ae", "Å": "A", "Ø": "O", "Æ": "AE",
    "ä": "a", "ö": "o", "ü": "u", "Ä": "A", "Ö": "O", "Ü": "U",
    "é": "e", "è": "e", "ê": "e", "É": "E",
    "ñ": "n", "Ñ": "N", "ç": "c", "Ç": "C",
}


def ascii_safe(s):
    return "".join(TRANSLATE.get(ch, ch) for ch in s)


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
    """Python string -> safe Maple string literal (ASCII-safe)."""
    s = "" if s is None else str(s).strip().replace("|", "/")
    s = ascii_safe(s)
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


def _flatten(v):
    """Item/List-access input: unwrap tree/list into a flat list."""
    if v is None:
        return []
    if hasattr(v, "Branches"):
        out = []
        for br in v.Branches:
            out.extend(x for x in br)
        return out
    if isinstance(v, (list, tuple)):
        out = []
        for x in v:
            if isinstance(x, (list, tuple)):
                out.extend(x)
            else:
                out.append(x)
        return out
    return [v]


# ---------------------------------------------------------------------------
# Parse group inputs (JSON) - clear errors instead of silent zeros
# ---------------------------------------------------------------------------

# project
try:
    P = json.loads(project) if project else {}
except (ValueError, TypeError):
    raise ValueError("project input is not valid JSON - connect "
                      "NODEMaple_ProjectParameters")
for k in ("project_number", "project_title", "client",
          "position_number", "position_text"):
    P.setdefault(k, "")

# structure
try:
    S = json.loads(structure) if structure else {}
except (ValueError, TypeError):
    raise ValueError("structure input is not valid JSON - connect "
                      "NODEMaple_BeamStructure")
material_name = str(S.get("material_name", "")).strip()
section_name = str(S.get("section_name", "")).strip()
for k in ("l_ky", "l_kz", "l_efy", "l_efz"):
    try:
        S[k] = float(S.get(k, 0.0))
    except (TypeError, ValueError):
        S[k] = 0.0

# loadcases
cases = []
for item in _flatten(loadcases):
    try:
        r = json.loads(item) if not isinstance(item, dict) else item
    except (ValueError, TypeError):
        raise ValueError("loadcases input contains invalid JSON: %r - "
                          "connect NODEMaple_LoadDefinition outputs" % item)
    vals = []
    for k in ("alpha", "F_xd", "M_yd", "M_zd", "V_yd", "V_zd", "M_td"):
        try:
            vals.append(float(r.get(k, 0.0)))
        except (TypeError, ValueError):
            vals.append(0.0)
    cases.append((str(r.get("name", "LC")).strip() or "LC", vals))

xml_path = "" if xml_path is None else str(xml_path).strip()
overwrite = bool(overwrite)
run = bool(run)

# ---------------------------------------------------------------------------
# Validation & dry-run mode
# ---------------------------------------------------------------------------

def _validate():
    msgs = []
    if not material_name:
        msgs.append("structure: material_name missing")
    if not section_name:
        msgs.append("structure: section_name missing")
    if not cases:
        msgs.append("loadcases: none - connect at least one "
                    "NODEMaple_LoadDefinition")
    if not xml_path:
        msgs.append("xml_path missing")
    return msgs

problems = _validate()

if not run:
    # dry run - show what would be sent, no Maple spawn
    loadcase_list = [n for n, _ in cases]
    eta_tree = Grasshopper.DataTree[object]()
    check_tree = Grasshopper.DataTree[object]()
    etamax_tree = Grasshopper.DataTree[object]()
    code_tree = Grasshopper.DataTree[object]()
    eta_max = None
    governing_loadcase = ""
    governing_code = ""
    saved = False
    error = "DRY RUN (run=False)" if not problems else \
            "; ".join(problems)
    debug = ("DRY RUN - inputs parsed:\n"
             "material : %s\nsection  : %s\n"
             "loadcases: %s\nxml_path : %s\nproblems : %s\n"
             % (material_name, section_name,
                ", ".join("%s %s" % (n, v) for n, v in cases),
                xml_path, "; ".join(problems) or "none"))
else:
    if problems:
        raise ValueError("; ".join(problems))

    if xml_path and overwrite and os.path.exists(xml_path):
        try:
            os.remove(xml_path)
        except OSError:
            pass

    # -----------------------------------------------------------------------
    # Maple script assembly (percent rule per line)
    # -----------------------------------------------------------------------

    L = []
    A = L.append

    A('kernelopts(printbytes=false):')
    A('interface(prettyprint=0):')
    A('WhateverYouNeed := table():')
    A('')
    A('# --- skeleton ---------------------------------------------------------')
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
    A('    "projectnumber" = "%s",' % mstr(P["project_number"]))
    A('    "projecttitle"  = "%s",' % mstr(P["project_title"]))
    A('    "client"        = "%s"' % mstr(P["client"]))
    A(']):')
    A('WhateverYouNeed["calculations"]["positionnumber"] := "%s":'
      % mstr(P["position_number"]))
    A('WhateverYouNeed["calculations"]["positiontitle"] := "%s":'
      % mstr(P["position_text"]))
    A('WhateverYouNeed["calculations"]["loadvariables"] := {"alpha", '
      '"F_xGk", "F_xQk", "F_xd", "V_yGk", "V_yQk", "V_yd", "V_zGk", "V_zQk", '
      '"V_zd", "M_yGk", "M_yQk", "M_yd", "M_zGk", "M_zQk", "M_zd", "M_tGk", '
      '"M_tQk", "M_td"}:')
    A('')
    A('# --- active material and section --------------------------------------')
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
    A('# --- structure --------------------------------------------------------')
    A('structure := WhateverYouNeed["calculations"]["structure"]:')
    A('structure["code_64"] := table(["ConstructionType" = "-", '
      '"alpha_ap" = 0, "tapered_N" = "false", "r_in" = 0, "l_curve" = 0, '
      '"t_lam" = 0]):')
    A('structure["buckling"] := table([')
    A('    "l_ky"  = %s,' % mnum(S["l_ky"], "'m'"))
    A('    "l_kz"  = %s,' % mnum(S["l_kz"], "'m'"))
    A('    "l_efy" = %s,' % mnum(S["l_efy"], "'m'"))
    A('    "l_efz" = %s' % mnum(S["l_efz"], "'m'"))
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
    A('# --- loadcases --------------------------------------------------------')

    for cname, vals in cases:
        alpha, fxd, myd, mzd, vyd, vzd, mtd = vals
        a_s = "0" if alpha == 0 else "%.10g*Unit(degrees)" % alpha
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

    A('loadcasenames := [%s]:'
      % ", ".join('"%s"' % mstr(c) for c, _ in cases))
    A('WhateverYouNeed["calculations"]["calculatingAllLoadcases"] := true:')
    A('')
    A('# --- run all loadcases -------------------------------------------------')
    A('overallmax := 0:')
    A('maxlc := "":')
    A('maxcode := "":')
    A('maxdesc := "":')
    A('aborted := false:')
    A('for lcname in loadcasenames do')
    A('    force := WhateverYouNeed["calculations"]["loadcases"][lcname]:')
    A('    printf("DBG|lc|%s|alpha=%a,F_xd=%a,M_yd=%a,M_zd=%a,'
      'V_yd=%a,V_zd=%a,M_td=%a\\n",')
    A('           lcname, evalf(force["alpha"]), evalf(force["F_xd"]), '
      'evalf(force["M_yd"]), evalf(force["M_zd"]),')
    A('           evalf(force["V_yd"]), evalf(force["V_zd"]), '
      'evalf(force["M_td"])):')
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
    A('# --- governing loadcase active, save to XML ----------------------------')
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
    # NOTE: %-formatted line -> literal Maple specifier doubled
    A('        printf("REC|saved|text|%%s\\n", "%s"):'
      % mstr(xml_path.replace("\\", "/")))
    A('    catch:')
    A('        printf("ERR|XML export failed: %a\\n", [lastexception]):')
    A('    end try:')
    A('end if:')
    A('quit:')

    script = "\n".join(L) + "\n"
    raw = run_maple_script(script)

    # -----------------------------------------------------------------------
    # Parse results
    # -----------------------------------------------------------------------

    lc_max = {}
    lc_eta = {}      # {name: [(check, value), ...]}
    lc_code = {}
    lc_echo = {}
    summary_max = None
    gov_lc = ""
    gov_code = ""
    saved = False
    err = None

    for line in raw.splitlines():
        s = line.strip()
        parts = s.split("|")
        if s.startswith("DBG|lc|") and len(parts) >= 4:
            lc_echo[parts[2]] = parts[3]
        elif s.startswith("REC|lc|") and len(parts) == 5:
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

    loadcase_list = [n for n, _ in cases]

    # trees: branch i = loadcase i; eta values sorted ascending,
    # check_tree carries the matching check code per value
    eta_tree = Grasshopper.DataTree[object]()
    check_tree = Grasshopper.DataTree[object]()
    etamax_tree = Grasshopper.DataTree[object]()
    code_tree = Grasshopper.DataTree[object]()

    for i, cname in enumerate(loadcase_list):
        checks = sorted(lc_eta.get(cname, []),
                        key=lambda cv: (cv[1], cv[0]))
        eta_tree.AddRange([v for _, v in checks], GH_Path(i))
        check_tree.AddRange([k for k, _ in checks], GH_Path(i))
        m = lc_max.get(cname)
        etamax_tree.AddRange([m if m is not None else -1.0], GH_Path(i))
        c = lc_code.get(cname, ("", ""))
        code_tree.AddRange(["%s %s" % c], GH_Path(i))

    eta_max = summary_max if summary_max is not None else \
        (max(lc_max.values()) if lc_max else None)
    governing_loadcase = gov_lc
    governing_code = gov_code
    saved_flag = saved
    error = err

    debug = ("material : %s\nsection  : %s\n"
             "loadcases: %s\nxml_path : %s\n"
             "parsed %d loadcase results, %d check records\n"
             % (material_name, section_name, ", ".join(loadcase_list),
                xml_path, len(lc_max), sum(len(v) for v in lc_eta.values())))
    for cname in loadcase_list:
        debug += "forces %-12s: %s\n" % (cname,
                                         lc_echo.get(cname, "<no echo>"))
    debug += "\n" + raw

saved = saved_flag if run else False
