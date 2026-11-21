# =====================================================================
# NODEMaple group components - GHPython components, one block per
# worksheet input block (see "NODEMaple Timber ULS.pdf").
#
# Topology (option A - one plug per block):
#
#   NODEMaple_ProjectParameters --- project -----------+
#   NODEMaple_BeamMaterial -------- material ----------+
#   NODEMaple_BeamBuckling ------- buckling -----------+--> NODEMaple_BeamDesign
#   NODEMaple_LoadDefinition xN -- loadcases ----------+      (Runner)
#   NODEMaple_SupportCheck ------- support_check ------+
#   NODEMaple_AngleCompression --- angle_compression --+
#   NODEMaple_TaperedCurved ------ tapered_curved -----+
#   NODEMaple_EndNotch ----------- end_notch ----------+
#
# Mandatory: project, material, loadcases, xml_path.
# Optional:  buckling, support_check, angle_compression,
#            tapered_curved, end_notch  (runner uses defaults for
#            unconnected optional blocks - shown in runner debug).
#
# Each component outputs one JSON string, readable in a Panel.
# Copy each delimited block into its own GHPython component.
# =====================================================================


# ---------------------------------------------------------------------
# COMPONENT 1: NODEMaple_ProjectParameters
# (unchanged - see earlier version)
# Inputs: project_number, project_title, client,
#         position_number, position_text (Item access, strings)
# Output: project
# Includes the ASCII transliteration for the Maple pipe protocol.
# ---------------------------------------------------------------------
"""
NODEMaple_ProjectParameters

Project/position metadata -> JSON for the runner input "project".
"""
import json

TRANSLATE = {
    "å": "a", "ø": "o", "æ": "ae", "Å": "A", "Ø": "O", "Æ": "AE",
    "ä": "a", "ö": "o", "ü": "u", "Ä": "A", "Ö": "O", "Ü": "U",
    "é": "e", "è": "e", "ê": "e", "É": "E",
    "ñ": "n", "Ñ": "N", "ç": "c", "Ç": "C",
}

def ascii_safe(s):
    return "".join(TRANSLATE.get(ch, ch) for ch in s)

def _s(v):
    return "" if v is None else ascii_safe(str(v).strip())

project = json.dumps({
    "project_number": _s(project_number),
    "project_title": _s(project_title),
    "client": _s(client),
    "position_number": _s(position_number),
    "position_text": _s(position_text),
})


# ---------------------------------------------------------------------
# COMPONENT 2: NODEMaple_BeamMaterial
# (was BeamStructure - buckling lengths moved to their own component)
# Inputs (Item access):
#   grade         : "GL 30c" (or full library material name)
#   service_class : "1" | "2" | "3"
#   load_duration : "Permanent" ... "Instantaneous"
#   section_name  : "Rectangular / 140x585"
# Output: material
# ---------------------------------------------------------------------
"""
NODEMaple_BeamMaterial

Section and material data block (worksheet page 1):
strength class + service class + load duration compose the library
material name; section name selects the profile.

Value Lists from MaterialDefinitions / TimberClasses /
TimberSections keep the library as single authority.
If grade already contains "/" it is used as the full name.
"""
import json

def _s(v):
    return "" if v is None else str(v).strip()

grade = _s(grade)
service_class = _s(service_class)
load_duration = _s(load_duration)
if "/" in grade or not (grade and service_class and load_duration):
    material_name = grade               # assume full name given
else:
    material_name = "%s / Service class %s / %s" % (
        grade, service_class, load_duration)

material = json.dumps({
    "material_name": material_name,
    "section_name": _s(section_name),
})


# ---------------------------------------------------------------------
# COMPONENT 3: NODEMaple_BeamBuckling
# Inputs (Item access, metres):
#   l_ky  : buckling length, buckling around y-axis (strong axis, I_y)
#   l_kz  : buckling length, buckling around z-axis (weak axis, I_z)
#   l_efy : effective length, lateral torsional buckling,
#           bending around y-axis (strong axis)
#   l_efz : effective length, lateral torsional buckling,
#           bending around z-axis (weak axis)
# Output: buckling
# ---------------------------------------------------------------------
"""
NODEMaple_BeamBuckling

Buckling and lateral torsional buckling lengths (worksheet page 1).
Optional input on the runner: if unconnected, all lengths default
to 0 and the runner debug says so.
"""
import json

def _f(v):
    try:
        return float(v)
    except (TypeError, ValueError):
        return 0.0

buckling = json.dumps({
    "l_ky": _f(l_ky),
    "l_kz": _f(l_kz),
    "l_efy": _f(l_efy),
    "l_efz": _f(l_efz),
})


# ---------------------------------------------------------------------
# COMPONENT 4: NODEMaple_LoadDefinition
# (unchanged - see earlier version)
# Inputs: name, alpha, F_xd, M_yd, M_zd, V_yd, V_zd, M_td
# Output: loadcase (list of JSON strings, one per row)
# ---------------------------------------------------------------------
"""
NODEMaple_LoadDefinition

One component per loadcase (Item access), or several rows via List
access. Design values [kN], [kNm]; alpha [deg].
Connect all outputs to the runner input "loadcases" (flatten it).
"""
import json

def _s(v):
    return "" if v is None else str(v).strip()

def _lst(v):
    if v is None:
        return []
    if hasattr(v, "Branches"):
        out = []
        for br in v.Branches:
            out.extend(x for x in br)
        return out
    if isinstance(v, (list, tuple)):
        return list(v)
    return [v]

names = _lst(name)
n_rows = max(1, len(names)) if names else 1

rows = []
for i in range(n_rows):
    def _get(vs, default=""):
        return _s(vs[i]) if i < len(vs) and vs[i] is not None else default
    def _getn(vs):
        try:
            return float(_get(vs, 0))
        except (TypeError, ValueError):
            return 0.0
    rows.append({
        "name":   _get(names) or "LC%d" % (i + 1),
        "alpha":  _getn(_lst(alpha)),
        "F_xd":   _getn(_lst(F_xd)),
        "M_yd":   _getn(_lst(M_yd)),
        "M_zd":   _getn(_lst(M_zd)),
        "V_yd":   _getn(_lst(V_yd)),
        "V_zd":   _getn(_lst(V_zd)),
        "M_td":   _getn(_lst(M_td)),
    })

loadcase = [json.dumps(r) for r in rows]


# ---------------------------------------------------------------------
# COMPONENT 5: NODEMaple_SupportCheck   (EC5 6.1.5)
# Inputs (Item access):
#   support_type : "a" (continuous support) | "b" (discrete support)
#   a            : [mm]  distance per Figur 6.2
#   l            : [mm]  bearing length per Figur 6.2
#   l1           : [mm]  distance per Figur 6.2
# Output: support_check
# ---------------------------------------------------------------------
"""
NODEMaple_SupportCheck

6.1.5 Continuous and discrete supports (worksheet page 2).
Writes structure["code_615"] = {type_615, a_615, l_615, l1_615}.
Optional input on the runner: if unconnected, the runner uses the
Limtreboka-example defaults (type b, a=0, l=225, l1=7500).
"""
import json

def _s(v):
    return "" if v is None else str(v).strip()

def _f(v):
    try:
        return float(v)
    except (TypeError, ValueError):
        return 0.0

t = _s(support_type) or "b"
support_check = json.dumps({
    "type": t,
    "a": _f(a),
    "l": _f(l),
    "l1": _f(l1),
})


# ---------------------------------------------------------------------
# COMPONENT 6: NODEMaple_AngleCompression   (EC5 6.2.2)
# Inputs (Item access):
#   h_load_area : [mm]  size of load area h_alpha (= h / cos(alpha));
#                 0 -> runner uses the section height
# Output: angle_compression
# ---------------------------------------------------------------------
"""
NODEMaple_AngleCompression

6.2.2 Size of load area (worksheet page 2). The worksheet derives
h_alpha = h / cos(alpha) from the section; do that upstream (or use
the panel's displayed value) and feed the result here. alpha itself
comes from the loadcase. Writes structure["code_622"] = {h_622}.
Optional input: 0 / unconnected -> section height is used.
"""
import json

def _f(v):
    try:
        return float(v)
    except (TypeError, ValueError):
        return 0.0

angle_compression = json.dumps({
    "h": _f(h_load_area),
})


# ---------------------------------------------------------------------
# COMPONENT 7: NODEMaple_TaperedCurved   (EC5 6.4)
# Inputs (Item access):
#   construction_type : "glulam with constant lamination thickness"
#                       | "LVL with constant lamination thickness"
#                       | "glulam with varying lamination thickness"
#                       | "-"  (prismatic - the default)
#   alpha_ap          : [deg] aperture angle of the apex zone
#   tapered_side      : "compression" | "tension"
#                       (tapered side in compression -> "false" in
#                       the library's tapered_N field, and vice versa
#                       - VERIFY against your library's convention)
#   r_in              : [m] inner radius (curved beams)
#   l_curve           : [m] length of curved section
#   t_lam             : [mm] lamination thickness
# Output: tapered_curved
# ---------------------------------------------------------------------
"""
NODEMaple_TaperedCurved

6.4 Members with varying cross-section or curved shape (page 3).
Writes structure["code_64"] = {ConstructionType, alpha_ap, tapered_N,
r_in, l_curve, t_lam}. Optional input: unconnected -> prismatic
defaults (ConstructionType "-", all values 0), matching the current
runner behaviour. Leave all zeros for straight beams.
"""
import json

def _s(v):
    return "" if v is None else str(v).strip().lower()

def _f(v):
    try:
        return float(v)
    except (TypeError, ValueError):
        return 0.0

# library stores tapered_N; worksheet wording is "tapered side in
# compression/tension". Mapping below assumes tapered_N means
# "tapered side in tension" (compression default -> "false").
# If results disagree with the worksheet, swap the mapping here.
tapered_N = "true" if _s(tapered_side) == "tension" else "false"

tapered_curved = json.dumps({
    "construction_type": _s(construction_type) or "-",
    "alpha_ap": _f(alpha_ap),
    "tapered_N": tapered_N,
    "r_in": _f(r_in),
    "l_curve": _f(l_curve),
    "t_lam": _f(t_lam),
})


# ---------------------------------------------------------------------
# COMPONENT 8: NODEMaple_EndNotch   (EC5 6.5.2)
# Inputs (Item access):
#   endnotched : boolean
#   notch_type : "6.11(a)" | "6.11(b)"
#   h_ef       : [mm] effective (remaining) height
#   l_incl     : [mm] inclination length i(h - h_ef)
#   x          : [mm] distance per Figur 6.11(a)
# Output: end_notch
# ---------------------------------------------------------------------
"""
NODEMaple_EndNotch

6.5.2 End-notched beams (worksheet page 4).
Writes structure["code_652"] = {endnotched, endnotchedType, h_ef,
l_incl, x_652}. Optional input: unconnected -> not end-notched,
h_ef = 80, l_incl = 100, x = 0 (current runner defaults).
"""
import json

def _s(v):
    return "" if v is None else str(v).strip()

def _f(v):
    try:
        return float(v)
    except (TypeError, ValueError):
        return 0.0

end_notch = json.dumps({
    "endnotched": "true" if endnotched else "false",
    "notch_type": _s(notch_type) or "6.11(b)",
    "h_ef": _f(h_ef),
    "l_incl": _f(l_incl),
    "x": _f(x),
})
