# NODESteelProfiles.mm: Super module for querying steel profile families and sections
# Copyright (C) 2026  Andreas Zieritz

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

NODESteelProfiles := module()
    description "Super module for steel profile families and cross section lookups";
    uses NODEFunctions;
    option package;

    export Property, profiletypes;

    local metadata, profileTable, parNames, memberNames, profileModules;

    # Metadata describing profile category attributes
    metadata := [
        [A, "type", 1, "Profile family code (e.g. CF_RHS, H, I)"],
        [B, "name", 1, "Full profile family designation"],
        [C, "standard", 1, "Applicable manufacturing/execution standard"],
        [D, "shape", 1, "Geometric cross section family"]
    ]:

    # Profile dictionary definitions
    profileTable := table([
        "CF_RHS" = table([
            "name" = "Cold Formed Rectangular Hollow Sections",
            "standard" = "EN 10219-2",
            "shape" = "RHS"
        ]),
        "CF_SHS" = table([
            "name" = "Cold Formed Square Hollow Sections",
            "standard" = "EN 10219-2",
            "shape" = "SHS"
        ]),
        "H" = table([
            "name" = "Wide Flange H-Sections (HEB, HEA, HEM)",
            "standard" = "EN 10034",
            "shape" = "H"
        ]),
        "HF_RHS" = table([
            "name" = "Hot Finished Rectangular Hollow Sections",
            "standard" = "EN 10210-2",
            "shape" = "RHS"
        ]),
        "HF_SHS" = table([
            "name" = "Hot Finished Square Hollow Sections",
            "standard" = "EN 10210-2",
            "shape" = "SHS"
        ]),
        "I" = table([
            "name" = "I-Sections (IPE, IPN)",
            "standard" = "EN 10024 / EN 10034",
            "shape" = "I"
        ])
    ]):

    # Mapping to actual profile sub-modules
    profileModules := table([
        "CF_RHS" = eval(NODESteelProfiles_CF_RHS),
        "CF_SHS" = eval(NODESteelProfiles_CF_SHS),
        "H"      = eval(NODESteelProfiles_H),
        "HF_RHS" = eval(NODESteelProfiles_HF_RHS),
        "HF_SHS" = eval(NODESteelProfiles_HF_SHS),
        "I"      = eval(NODESteelProfiles_I)
    ]):

    parNames := convert(metadata[1.., 2], list):
    memberNames := sort([indices(profileTable, 'nolist')]):
    profiletypes := memberNames;

    # Property dispatcher
    # Signature patterns supported:
    #   Property("allmembers")                  -> ["CF_RHS", "CF_SHS", "H", "HF_RHS", "HF_SHS", "I"]
    #   Property("metadata")                    -> ["type", "name", "standard", "shape"]
    #   Property(profileType, "allmembers")     -> delegates to sub-module Property("allmembers")
    #   Property(profileType, "metadata")       -> delegates to sub-module Property("metadata")
    #   Property(profileType, par)              -> lookup metadata parameter for that family
    #   Property(profileType, section, par)     -> delegates property query to sub-module
    #   Property(profileType, section, par, "metadata") -> delegates metadata lookup for section parameter
    Property := proc(requiredMember::string, requiredPar::string)
        uses ListTools;
        local subMod, parPos;

        # 1. Zero/Single parameter keywords on super-module level
        if _npassed = 1 then
            if _passed[1] = "allmembers" then
                return memberNames;
            elif _passed[1] = "metadata" then
                return parNames;
            else
                error("Unknown single query parameter: %1", _passed[1]);
            end if;

        # 2. Two-parameter queries: Delegation or Family property lookup
        elif _npassed = 2 then
            # Querying member list of a specific profile group (e.g. Property("CF_RHS", "allmembers"))
            if _passed[2] = "allmembers" then
                if assigned(profileModules[_passed[1]]) then
                    subMod := profileModules[_passed[1]];
                    return subMod:-Property("allmembers");
                else
                    error("Unknown profile type: %1", _passed[1]);
                end if;

            # Querying metadata parameter list of a specific profile group
            elif _passed[2] = "metadata" then
                if assigned(profileModules[_passed[1]]) then
                    subMod := profileModules[_passed[1]];
                    return subMod:-Property("metadata");
                else
                    error("Unknown profile type: %1", _passed[1]);
                end if;

            # Parameter query on the profile type itself (e.g. Property("CF_RHS", "standard"))
            elif assigned(profileTable[requiredMember]) then
                if assigned(profileTable[requiredMember][requiredPar]) then
                    return profileTable[requiredMember][requiredPar];
                else
                    error("Parameter not found for profile family: %1", requiredPar);
                end if;
            else
                error("Profile family not found: %1", requiredMember);
            end if;

        # 3. Three-parameter queries: Delegation to sub-module (e.g. Property("CF_RHS", "RHS 100x50x4", "A"))
        elif _npassed = 3 then
            if assigned(profileModules[_passed[1]]) then
                subMod := profileModules[_passed[1]];
                return subMod:-Property(_passed[2], _passed[3]);
            else
                error("Unknown profile type: %1", _passed[1]);
            end if;

        # 4. Four-parameter queries: Delegation to sub-module with "metadata"
        elif _npassed = 4 and _passed[4] = "metadata" then
            if assigned(profileModules[_passed[1]]) then
                subMod := profileModules[_passed[1]];
                return subMod:-Property(_passed[2], _passed[3], "metadata");
            else
                error("Unknown profile type: %1", _passed[1]);
            end if;
        end if;

    end proc:

end module: