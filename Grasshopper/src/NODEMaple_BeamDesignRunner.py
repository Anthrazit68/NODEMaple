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
NODEMaple Beam Design Runner (block components edition)

Consumes one JSON per worksheet input block (see
"NODEMaple Timber ULS.pdf" for the block definitions):

  project           <- NODEMaple_ProjectParameters   (MANDATORY)
  material          <- NODEMaple_BeamMaterial         (MANDATORY)
  loadcases         <- NODEMaple_LoadDefinition xN    (MANDATORY)
  buckling          <- NODEMaple_BeamBuckling        (OPTIONAL)
  support_check     <- NODEMaple_SupportCheck         (OPTIONAL, 6.1.5)
  angle_compression <- NODEMaple_AngleCompression     (OPTIONAL, 6.2.2)
  tapered_curved    <- NODEMaple_TaperedCurved        (OPTIONAL, 6.4)
  end_notch         <- NODEMaple_EndNotch             (OPTIONAL, 6.5.2)

Unconnected OPTIONAL blocks fall back to the defaults below; the
debug output lists "structure block defaults in use" so a result
computed on defaults is always identifiable.

FLATTEN all Item-access group inputs so this component runs ONCE.

Outputs per loadcase (branch i = loadcase i, order = input order):
  eta_tree    : eta per executed check, sorted by value ascending
                (governing check = last item in a branch)
  check_tree   : check code for each eta ("616" etc.)
  etamax_tree  : max eta of that loadcase
  code_tree    : governing check "<code> <description>" of that case

Defaults for optional blocks (matching the worksheet examples):
  buckling:          all lengths 0 m (-> dispatch may flag warnings)
  support_check:     type b, a=0, l=225 mm, l1=7500 mm
  angle_compression: h = section height
  tapered_curved:    prismatic ("-"), all values 0
  end_notch:         not notched, h_ef=80, l_incl=100 mm, x=0

Input:
  project           : JSON from NODEMaple_ProjectParameters (mandatory)
  material          : JSON from NODEMaple_BeamMaterial (mandatory)
  loadcases         : JSON strings from NODEMaple_LoadDefinition
                      xN (mandatory; flattened list)
  buckling          : JSON from NODEMaple_BeamBuckling (optional)
  support_check     : JSON from NODEMaple_SupportCheck (optional, 6.1.5)
  angle_compression : JSON from NODEMaple_AngleCompression
                      (optional, 6.2.2)
  tapered_curved    : JSON from NODEMaple_TaperedCurved (optional, 6.4)
  end_notch         : JSON from NODEMaple_EndNotch (optional, 6.5.2)
  xml_path          : target .xml file for the NODEMaple export
                      (mandatory when run=True)
  overwrite         : True -> delete existing xml_path before export
                      (prevents a stale file surviving a failed run)
  run               : True -> execute (spawn cmaple, calculate, export);
                      False -> dry run: validate and echo inputs in
                      debug without spawning Maple
  maple_version     : Maple year, e.g. "2026" (ignored when the
                      MAPLE environment variable is set)

Output:
  loadcase_list      : names in calculation order (index key for
                       the trees below)
  eta_tree           : eta per executed check, sorted by value
                       ascending (branch i = loadcase i; governing
                       check = last item of a branch)
  check_tree         : check code per eta - item i labels item i
                       in eta_tree (Maple-quoted, "616" etc.)
  etamax_tree        : max eta per loadcase (-1 if none)
  code_tree          : governing check "<code> <description>"
                       per loadcase
  eta_max            : global maximum utilization over all cases
  governing_loadcase : name of the governing loadcase
  governing_code     : code of the governing case's governing check
  saved              : True if the XML file was written
  error              : first ERR| message of the run, or None
  debug              : header (inputs, blocks in use/on defaults,
                       parsed record counts, force echoes) followed
                       by the raw Maple output

CONSTRUCTION RULE (supersedes the old percent rule):
  Script lines are built with STRING CONCATENATION only. Python
  %-formatting is BANNED inside the A(...) script assembly, because
  mixing Python format specifiers with Maple printf specifiers on
  one line caused three separate bugs. Concatenation needs no
  doubling: every % sign written in a concatenated line reaches
  Maple exactly as written, single.
  Exception: lines with NO % sign at all may use % formatting.
  (The REC|saved line also switched to concatenation.)
Protocol is ASCII-only; mstr() transliterates as a safety net.
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


def _parse_json(value, label):
    """Parse one group-component JSON; empty/None -> {} (block absent)."""
    if value is None:
        return {}
    txt = str(value).strip()
    if not txt:
        return {}
    try:
        return json.loads(txt)
    except (ValueError, TypeError):
        raise ValueError("%s input is not valid JSON" % label)


# ---------------------------------------------------------------------------
# Parse group inputs (JSON) - clear errors instead of silent zeros
# ---------------------------------------------------------------------------

P = _parse_json(project, "project")
for k in ("project_number", "project_title", "client",
          "position_number", "position_text"):
    P.setdefault(k, "")

M = _parse_json(material, "material")
material_name = str(M.get("material_name", "")).strip()
section_name = str(M.get("section_name", "")).strip()

BK = _parse_json(buckling, "buckling")
def _bk(k):
    try:
        return float(BK.get(k, 0.0))
    except (TypeError, ValueError):
        return 0.0

SC = _parse_json(support_check, "support_check")
def _sc(k, d):
    v = SC.get(k, d)
    try:
        return float(v)
    except (TypeError, ValueError):
        return d
sc_type = str(SC.get("type", "b")).strip() or "b"

AC = _parse_json(angle_compression, "angle_compression")
try:
    ac_h = float(AC.get("h", 0.0))
except (TypeError, ValueError):
    ac_h = 0.0

TC = _parse_json(tapered_curved, "tapered_curved")
tc_ct = str(TC.get("construction_type", "-")).strip() or "-"
tc_N = str(TC.get("tapered_N", "false")).strip() or "false"
def _tc(k):
    try:
        return float(TC.get(k, 0.0))
    except (TypeError, ValueError):
        return 0.0

EN = _parse_json(end_notch, "end_notch")
en_notched = str(EN.get("endnotched", "false")).strip() or "false"
en_type = str(EN.get("notch_type", "6.11(b)")).strip() or "6.11(b)"
def _en(k, d):
    try:
        return float(EN.get(k, d))
    except (TypeError, ValueError):
        return d

# block sources for the DBG|block| echoes
src_buckling = "buckling" if BK else "default"
src_615 = "support_check" if SC else "default"
src_622 = "angle_compression" if AC else "default_section_h"
src_64 = "tapered_curved" if TC else "default_prismatic"
src_652 = "end_notch" if EN else "default"

blocks_defaults = []
if not BK:
    blocks_defaults.append("buckling (lengths -> 0)")
if not SC:
    blocks_defaults.append("support_check (type b, 0/225/7500)")
if not AC:
    blocks_defaults.append("angle_compression (h -> section h)")
if not TC:
    blocks_defaults.append("tapered_curved (prismatic)")
if not EN:
    blocks_defaults.append("end_notch (not notched)")

# loadcases
cases = []
for item in _flatten(loadcases):
    try:
        r = json.loads(item) if not isinstance(item, dict) else item
    except (ValueError, TypeError):
        raise ValueError("loadcases input contains invalid JSON: %r" % item)
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
        msgs.append("material: material_name missing - connect "
                    "NODEMaple_BeamMaterial")
    if not section_name:
        msgs.append("material: section_name missing - connect "
                    "NODEMaple_BeamMaterial")
    if not cases:
        msgs.append("loadcases: none - connect at least one "
                    "NODEMaple_LoadDefinition")
    if not xml_path:
        msgs.append("xml_path missing")
    # 6.1.5 support check needs real bearing geometry: refuse to run
    # it on the Limtreboka placeholder defaults. Trigger condition is
    # a proxy for the library's dispatch: compression with a force
    # component at an angle to the grain (alpha > 0, F_xd < 0).
    if not SC and any(v[1] < 0 and v[0] > 0 for _, v in cases):
        msgs.append("support_check: MISSING - a loadcase has angled "
                    "compression (F_xd < 0, alpha > 0) which triggers "
                    "the 6.1.5 support check. Connect "
                    "NODEMaple_SupportCheck with the bearing geometry "
                    "(type a/b, a, l, l1). Calculating 6.1.5 on "
                    "undocumented default values is refused.")
    return msgs

problems = _validate()

if not run:
    loadcase_list = [n for n, _ in cases]
    eta_tree = Grasshopper.DataTree[object]()
    check_tree = Grasshopper.DataTree[object]()
    etamax_tree = Grasshopper.DataTree[object]()
    code_tree = Grasshopper.DataTree[object]()
    eta_max = None
    governing_loadcase = ""
    governing_code = ""
    saved_flag = False
    error = "DRY RUN (run=False)" if not problems else "; ".join(problems)
    debug = ("DRY RUN - inputs parsed:\n"
             "material : %s\nsection  : %s\n"
             "loadcases: %s\nxml_path : %s\n"
             "blocks in use     : %s\n"
             "blocks on defaults: %s\nproblems : %s\n"
             % (material_name, section_name,
                ", ".join("%s %s" % (n, v) for n, v in cases),
                xml_path,
                ", ".join([s for s in (src_buckling, src_615, src_622,
                                       src_64, src_652)
                           if not s.startswith("default")]) or "none",
                "; ".join(blocks_defaults) or "none",
                "; ".join(problems) or "none"))
else:
    if problems:
        raise ValueError("; ".join(problems))

    if xml_path and overwrite and os.path.exists(xml_path):
        try:
            os.remove(xml_path)
        except OSError:
            pass

    fwd_xml_path = xml_path.replace("\\", "/")

    # -----------------------------------------------------------------------
    # Maple script assembly - CONCATENATION ONLY inside A(...) lines
    # (see docstring CONSTRUCTION RULE). No Python % formatting on
    # lines that contain Maple printf specifiers.
    # -----------------------------------------------------------------------

    L = []
    A = L.append

    A('kernelopts(printbytes=false):')
    A('interface(prettyprint=0):')
    A('with(Units[Simple]):')
    A('WhateverYouNeed := table():')
    A('')
    A('# --- skeleton ---------------------------------------------------------')
    A('NODEFunctions:-LibInitCommon(WhateverYouNeed, "' +
      mstr(CALCULATIONTYPE) + '"):')
    A('if not assigned(WhateverYouNeed["warnings"]) then')
    A('    printf("ERR|LibInitCommon did not initialize WhateverYouNeed\\n"):')
    A('    quit:')
    A('end if:')
    A('NODETimberGUI:-InitSpecific_EC5_6():')
    A('WhateverYouNeed["calculations"]["calculationtype_short"] := "' +
      mstr(CALCULATIONTYPE_SHORT) + '":')
    A('WhateverYouNeed["calculations"]["suppress_gui"] := true:')
    A('WhateverYouNeed["material"] := "timber":')
    A('')
    A('# --- project and position metadata ------------------------------------')
    A('WhateverYouNeed["projectdata"] := table([')
    A('    "projectnumber" = "' + mstr(P["project_number"]) + '",')
    A('    "projecttitle"  = "' + mstr(P["project_title"]) + '",')
    A('    "client"        = "' + mstr(P["client"]) + '"')
    A(']):')
    A('WhateverYouNeed["calculations"]["positionnumber"] := "' +
      mstr(P["position_number"]) + '":')
    A('WhateverYouNeed["calculations"]["positiontitle"] := "' +
      mstr(P["position_text"]) + '":')
    A('WhateverYouNeed["calculations"]["loadvariables"] := {"alpha", '
      '"F_xGk", "F_xQk", "F_xd", "V_yGk", "V_yQk", "V_yd", "V_zGk", "V_zQk", '
      '"V_zd", "M_yGk", "M_yQk", "M_yd", "M_zGk", "M_zQk", "M_zd", "M_tGk", '
      '"M_tQk", "M_td"}:')
    A('')
    A('# --- active material and section --------------------------------------')
    A('matname := "' + mstr(material_name) + '":')
    A('sectname := "' + mstr(section_name) + '":')
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
    A('# --- structure blocks --------------------------------------------------')
    A('structure := WhateverYouNeed["calculations"]["structure"]:')

    # 6.4 tapered / curved (prismatic defaults when block absent)
    a_64 = mnum(_tc("alpha_ap"), "degrees") if _tc("alpha_ap") else "0"
    r_64 = mnum(_tc("r_in"), "'m'") if _tc("r_in") else "0"
    l_64 = mnum(_tc("l_curve"), "'m'") if _tc("l_curve") else "0"
    t_64 = mnum(_tc("t_lam"), "mm") if _tc("t_lam") else "0"
    A('structure["code_64"] := table(')
    A('    ["ConstructionType" = "' + mstr(tc_ct) + '", '
      '"alpha_ap" = ' + a_64 + ', "tapered_N" = "' + tc_N + '", '
      '"r_in" = ' + r_64 + ', "l_curve" = ' + l_64 + ', '
      '"t_lam" = ' + t_64 + ']):')
    A('printf("DBG|block|code_64|' + src_64 + '\\n"):')

    # buckling lengths
    A('structure["buckling"] := table([')
    A('    "l_ky"  = ' + mnum(_bk("l_ky"), "'m'") + ',')
    A('    "l_kz"  = ' + mnum(_bk("l_kz"), "'m'") + ',')
    A('    "l_efy" = ' + mnum(_bk("l_efy"), "'m'") + ',')
    A('    "l_efz" = ' + mnum(_bk("l_efz"), "'m'"))
    A(']):')
    A('printf("DBG|block|buckling|' + src_buckling + '\\n"):')

    # 6.1.5 support check
    a_615 = mnum(_sc("a", 0.0), "mm") if _sc("a", 0.0) else "0"
    l_615 = mnum(_sc("l", 225.0), "mm") if _sc("l", 225.0) else "0"
    l1_615 = mnum(_sc("l1", 7500.0), "mm") if _sc("l1", 7500.0) else "0"
    A('structure["code_615"] := table(["type_615" = "' + mstr(sc_type) +
      '", "a_615" = ' + a_615 + ', "l_615" = ' + l_615 +
      ', "l1_615" = ' + l1_615 + ']):')
    A('printf("DBG|block|code_615|' + src_615 + '\\n"):')

    # 6.2.2 compression at an angle: h from block, else section height
    h_622 = mnum(ac_h) if ac_h else "0"
    A('structure["code_622"] := table(["h_622" = if %g > 0 then %s*Unit(mm) '
      'else eval(WhateverYouNeed["sectiondata"]["h"]) end if]):'
      % (ac_h, h_622))
    A('printf("DBG|block|code_622|' + src_622 + '\\n"):')

    # 6.5.2 end notch
    hef_652 = mnum(_en("h_ef", 80.0), "mm") if _en("h_ef", 80.0) else "0"
    lincl_652 = mnum(_en("l_incl", 100.0), "mm") if _en("l_incl", 100.0) else "0"
    x_652 = mnum(_en("x", 0.0), "mm") if _en("x", 0.0) else "0"
    A('structure["code_652"] := table(["endnotched" = "' + en_notched +
      '", "endnotchedType" = "' + mstr(en_type) + '", "h_ef" = ' + hef_652 +
      ', "l_incl" = ' + lincl_652 + ', "x_652" = ' + x_652 + ']):')
    A('printf("DBG|block|code_652|' + src_652 + '\\n"):')
    A('')
    A('try')
    A('    NODETimberEN1995:-calculate_k_64():')
    A('catch:')
    A('        printf("ERR|calculate_k_64 failed: %a\\n", [lastexception]):')
    A('end try:')
    A('printf("DBG|k_64|k_m_alpha=%a,k_r=%a,k_l=%a\\n", '
      'WhateverYouNeed["results"]["k_64"]["k_m_alpha"], '
      'WhateverYouNeed["results"]["k_64"]["k_r"], '
      'WhateverYouNeed["results"]["k_64"]["k_l"]):')
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
        A('    "name"   = "' + mstr(cname) + '",')
        A('    "alpha"  = ' + a_s + ',')
        A('    "F_xGk"  = "false", "F_xQk" = "false", "F_xd"  = ' +
          mnum(fxd, "kN") + ',')
        A('    "M_yGk"  = "false", "M_yQk" = "false", "M_yd"  = ' +
          mnum(myd, "'kN*m'") + ',')
        A('    "M_zGk"  = "false", "M_zQk" = "false", "M_zd"  = ' +
          mnum(mzd, "'kN*m'") + ',')
        A('    "V_yGk"  = "false", "V_yQk" = "false", "V_yd"  = ' +
          mnum(vyd, "kN") + ',')
        A('    "V_zGk"  = "false", "V_zQk" = "false", "V_zd"  = ' +
          mnum(vzd, "kN") + ',')
        A('    "M_tGk"  = "false", "M_tQk" = "false", "M_td"  = ' +
          mnum(mtd, "'kN*m'"))
        A(']):')
        A('WhateverYouNeed["calculations"]["loadcases"]["' + mstr(cname) +
          '"] := eval(lc):')
        A('')

    names_str = ", ".join('"' + mstr(c) + '"' for c, _ in cases)
    A('loadcasenames := [' + names_str + ']:')
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
    A('        NODEXML:-XMLFileInOut("export", WhateverYouNeed, "' +
      mstr(fwd_xml_path) + '"):')
    A('        printf("REC|saved|text|%s\\n", "' + mstr(fwd_xml_path) + '"):')
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
    blk_echo = {}
    summary_max = None
    gov_lc = ""
    gov_code = ""
    saved = False
    err = None

    for line in raw.splitlines():
        s = line.strip()
        parts = s.split("|")
        if s.startswith("DBG|block|") and len(parts) >= 4:
            blk_echo[parts[2]] = "|".join(parts[3:])
        elif s.startswith("DBG|lc|") and len(parts) >= 4:
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
             "structure blocks in use     : %s\n"
             "structure blocks on defaults: %s\n"
             "parsed %d loadcase results, %d check records\n"
             % (material_name, section_name, ", ".join(loadcase_list),
                xml_path,
                ", ".join(blk_echo.get(k, "?")
                          for k in ("code_64", "buckling", "code_615",
                                    "code_622", "code_652")),
                "; ".join(blocks_defaults) or "none",
                len(lc_max), sum(len(v) for v in lc_eta.values())))
    for cname in loadcase_list:
        debug += "forces %-12s: %s\n" % (cname,
                                         lc_echo.get(cname, "<no echo>"))
    debug += "\n" + raw

saved = saved_flag if run else False
