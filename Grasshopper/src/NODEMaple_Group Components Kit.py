# =====================================================================
# NODEMaple group components - three separate GHPython components.
# Copy each delimited block into its own GHPython component and name
# it as indicated. Each outputs a JSON "group object".
# =====================================================================


# ---------------------------------------------------------------------
# COMPONENT 1: NODEMaple_ProjectParameters
# Inputs  (all Item access, strings):
#   project_number, project_title, client
#   position_number, position_text
# Output:
#   project : JSON string
# ---------------------------------------------------------------------
"""
NODEMaple_ProjectParameters

Collects project and position metadata into one JSON group object
for NODEMaple_BeamDesign (input "project").

All inputs Item access; unconnected inputs become empty strings.
"""
import json

# ASCII-safe transliteration for the Maple pipe protocol
TRANSLATE = {
    "å": "a", "ø": "o", "æ": "ae", "Å": "A", "Ø": "O", "Æ": "AE",
    "ä": "a", "ö": "o", "ü": "u", "Ä": "A", "Ö": "O", "Ü": "U",
    "é": "e", "è": "e", "ê": "e", "É": "E",
    "ñ": "n", "Ñ": "N", "ç": "c", "Ç": "C",
}

def ascii_safe(s):
    return "".join(TRANSLATE.get(ch, ch) for ch in s)

def _s(v):
    return "" if v is None else str(v).strip()

project = json.dumps({
    "project_number": _s(project_number),
    "project_title": _s(project_title),
    "client": _s(client),
    "position_number": _s(position_number),
    "position_text": _s(position_text),
})


# ---------------------------------------------------------------------
# COMPONENT 2: NODEMaple_BeamStructure
# Inputs (Item access):
#   grade         : "GL 30c"   (or full name with slashes)
#   service_class : "1" | "2" | "3"
#   load_duration : "Permanent" | "Long-term" | ... | "Instantaneous"
#   section_name  : "Rectangular / 140x585"
#   l_ky, l_kz, l_efy, l_efz : buckling / effective lengths [m]
# Output:
#   structure : JSON string
# ---------------------------------------------------------------------
"""
NODEMaple_BeamStructure

Describes the beam: material (grade + service class + load duration
composing the library material name), section, and buckling
lengths. Output feeds NODEMaple_BeamDesign input "structure".

Value Lists for grade / service_class / load_duration / section_name
should come from the MaterialDefinitions / TimberClasses /
TimberSections components - the library stays the single authority.
"""
import json

# ASCII-safe transliteration for the Maple pipe protocol
TRANSLATE = {
    "å": "a", "ø": "o", "æ": "ae", "Å": "A", "Ø": "O", "Æ": "AE",
    "ä": "a", "ö": "o", "ü": "u", "Ä": "A", "Ö": "O", "Ü": "U",
    "é": "e", "è": "e", "ê": "e", "É": "E",
    "ñ": "n", "Ñ": "N", "ç": "c", "Ç": "C",
}

def ascii_safe(s):
    return "".join(TRANSLATE.get(ch, ch) for ch in s)

def _s(v):
    return "" if v is None else str(v).strip()

def _f(v):
    try:
        return float(v)
    except (TypeError, ValueError):
        return 0.0

grade = _s(grade)
service_class = _s(service_class)
load_duration = _s(load_duration)
if "/" in grade or not (grade and service_class and load_duration):
    material_name = grade               # assume full name given
else:
    material_name = "%s / Service class %s / %s" % (
        grade, service_class, load_duration)

structure = json.dumps({
    "material_name": material_name,
    "section_name": _s(section_name),
    "l_ky":  _f(l_ky),
    "l_kz":  _f(l_kz),
    "l_efy": _f(l_efy),
    "l_efz": _f(l_efz),
})


# ---------------------------------------------------------------------
# COMPONENT 3: NODEMaple_LoadDefinition
# Inputs (Item access; give lists via List access to emit several
#         loadcases from one component):
#   name   : loadcase name
#   alpha  : [deg]   0 = parallel to grain, 90 = perpendicular
#   F_xd   : [kN]    tension +, compression -
#   M_yd   : [kNm]
#   M_zd   : [kNm]
#   V_yd   : [kN]
#   V_zd   : [kN]
#   M_td   : [kNm]
# Output:
#   loadcase : list of JSON strings (one per row)
# ---------------------------------------------------------------------
"""
NODEMaple_LoadDefinition

Builds loadcase definitions as JSON objects. Connect the output to
NODEMaple_BeamDesign input "loadcases" (Item access on the main
component merges all wires/rows into one list of JSON strings).
Several LoadDefinition components may feed the same input.

Row order per component: the inputs are zipped; with Item access a
single row is produced. Numbers default to 0 when unconnected.
"""
import json

# ASCII-safe transliteration for the Maple pipe protocol
TRANSLATE = {
    "å": "a", "ø": "o", "æ": "ae", "Å": "A", "Ø": "O", "Æ": "AE",
    "ä": "a", "ö": "o", "ü": "u", "Ä": "A", "Ö": "O", "Ü": "U",
    "é": "e", "è": "e", "ê": "e", "É": "E",
    "ñ": "n", "Ñ": "N", "ç": "c", "Ç": "C",
}

def ascii_safe(s):
    return "".join(TRANSLATE.get(ch, ch) for ch in s)

def _s(v):
    return "" if v is None else str(v).strip()

def _lst(v):
    # scalar -> single-element list; list/tree -> list of items
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
