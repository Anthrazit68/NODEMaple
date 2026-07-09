# NODEConcreteMaterial.mm
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

NODEConcreteMaterial := module()
    description "Material properties for concrete according to Eurocode 2";
    option package;  
    export Property, Exposureclasses, Durabilityclasses; 

    # Fully encapsulated on module level - zero global variables!
    local metadata, dataTable, parNames, memberNames;

# $include MUST be at the absolute start of the line (column 1) to build properly
$include "Concrete/Data_ConcreteMaterial.mm"

    parNames := convert(metadata[2.., 2], list):
    
    # Extracts all concrete grades and sorts them perfectly (e.g., B20, B30, B35...)
    memberNames := sort([indices(dataTable, 'nolist')], NODEFunctions:-SortStructuralnames);

    Property := proc(requiredMember::string, requiredPar::string)
        uses ListTools;

        if _npassed = 2 then
            if assigned(dataTable[requiredMember]) then
                if assigned(dataTable[requiredMember][requiredPar]) then
                    return dataTable[requiredMember][requiredPar];
                else
                    error("Parameter not found: %1", requiredPar);
                end if;
            else
                error("Concrete strength class not found: %1", requiredMember);
            end if;

        elif _npassed = 3 and _passed[3] = "metadata" then
            local parPos := ListTools:-Search(requiredPar, parNames);
            if parPos > 0 then
                return metadata[parPos, 4]; # Column 4 contains description string
            else
                error("Parameter not found in metadata");
            end if;

        elif _npassed = 1 and _passed[1] = "allmembers" then
            return memberNames;

        elif _npassed = 1 and _passed[1] = "metadata" then
            return parNames;       
        end if;
    end proc:

    Exposureclasses := proc()::list;
        return ["X0", "XC1", "XC2", "XC3", "XC4", "XD1", "XD2", "XD3", "XS1", "XS2", "XS3", "XF1", "XF2", "XF3", "XF4", "XA1", "XA2", "XA3"];
    end proc:

    Durabilityclasses := proc()::list;
        return ["M90", "M60", "M45", "MF45", "M40", "MF40"];
    end proc:
    
end module: