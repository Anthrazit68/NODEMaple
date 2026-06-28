# NODETimberMaterial.mm : timber material properties module
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

NODETimberMaterial := module()
    description "Data API and property lookups for timber strength classes according to EN 1995-1-1";
    option package;

    # Public API procedures exposed to the worksheet GUI and calculation templates
    export Property, Strengthclasses;

    # Encapsulated module-level local tables - zero global contamination
    local metadata, dataTable, parNames, memberNamesRaw;

# $include MUST sit at the absolute start of the file line (column 1) to build correctly
$include "Timber/Data_TimberMaterial.mm"

    # Initialize raw data structures from the included database files at load-time
    parNames       := convert(metadata[2.., 2], list);
    memberNamesRaw := [indices(dataTable, 'nolist')];

    Property := proc(requiredMember::string, requiredPar::string)
        local parPos, memberNames;
        uses ListTools;

        # Sort the members dynamically at runtime to satisfy compiler verification
        memberNames := sort(memberNamesRaw, (a,b) -> NODEFunctions:-SortStructuralnames(a,b));

        if _npassed = 2 then   
            if member(requiredMember, memberNames) and member(requiredPar, parNames) then
                return dataTable[requiredMember][requiredPar];
            else
                if not member(requiredMember, memberNames) and not member(requiredPar, parNames) then
                    error "Member and parameter not found";
                elif not member(requiredMember, memberNames) then
                    error "Member not found";
                elif not member(requiredPar, parNames) then
                    error "Parameter not found";
                end if;
            end if;

        elif _npassed = 3 and _passed[3] = "metadata" then
            parPos := ListTools:-Search(requiredPar, parNames);
            if parPos > 0 then
                return metadata[parPos+1, numelems(metadata[parPos+1])];
            else
                error "Parameter not found in metadata";
            end if;
            
        elif _npassed = 1 and _passed[1] = "allmembers" then
            return memberNames;

        elif _npassed = 1 and _passed[1] = "metadata" then
            return parNames;    
        end if;
    end proc:

    Strengthclasses := proc(timbertype::string)
        description "Return sorted structural timber strength classes filtered by category";
        local val, glulam, solidtimber, CLT, memberNames;

        # Sort the members dynamically at runtime
        memberNames := sort(memberNamesRaw, (a,b) -> NODEFunctions:-SortStructuralnames(a,b));

        glulam      := [];
        solidtimber := [];
        CLT         := [];
    
        for val in memberNames do
            if StringTools:-Search("CLT", val) > 0 then
                CLT := [op(CLT), val];
            elif StringTools:-Search("GL", val) > 0 or StringTools:-Search("L", val) > 0 then
                glulam := [op(glulam), val];
            elif StringTools:-Search("C", val) > 0 then
                solidtimber := [op(solidtimber), val];
            end if;
        end do;

        if timbertype = "Solid timber" then
            return solidtimber;
        elif timbertype = "Glued laminated timber" then
            return glulam;
        elif timbertype = "CLT" then
            return CLT;
        elif timbertype = "all" then
            return memberNames;
        else
            return [];
        end if;
    end proc:
    
end module: