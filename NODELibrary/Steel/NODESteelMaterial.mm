# NODESteelMaterial.mm: steel material data
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

# NODESteelMaterial.mm
NODESteelMaterial := module()
    description "Material properties for steel according to EN 10025";
    uses NODEFunctions;
    option package;  
    export Property, Property1, steelcodes, steelgrades; 
    
    # Fully encapsulated on module level - zero global variables!
    local metadata, dataTable, dataTable1, standarder, steeltypeTocode, parNames, memberNames;

    # Include the pre-generated dataset compiled by the generator
$include "Steel/Data_SteelMaterial.mm"

    # Export lists directly to the GUI / ComboBox components
    steelcodes := standarder; 			
    steelgrades := eval(steeltypeTocode);	

    parNames := convert(metadata[2..,2], list):
    
    # memberNames extracts ALL unique steel grades across all tables and sorts them cleanly
    memberNames := sort([indices(dataTable, 'nolist')], SortStructuralnames);

    # Standard lookup using only the steel grade string (e.g., Property("S 235 W", "E"))
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
                error("Material/Steelgrade not found: %1", requiredMember);
            end if;

        elif _npassed = 3 and _passed[3] = "metadata" then
            local parPos := ListTools:-Search(requiredPar, parNames);
            if parPos > 0 then
                return metadata[parPos+1, 5];
            else
                error("Parameter not found in metadata");
            end if;

        elif _npassed = 1 and _passed[1] = "allmembers" then
            return memberNames;

        elif _npassed = 1 and _passed[1] = "metadata" then
            return parNames;
        end if;
    end proc:

    # Bulletproof lookup using a set to handle identical names in different codes
    # e.g., Property1({"S 355", "NS-EN 10025-2"}, "f_y_0_40")
    Property1 := proc(requiredMember::set, requiredPar::string)
        
        if assigned(dataTable1[requiredMember]) then
            if assigned(dataTable1[requiredMember][requiredPar]) then
                return dataTable1[requiredMember][requiredPar];
            else
                error("Parameter not found for this material set: %1", requiredPar);
            end if;
        else
            error("Material set not found: %1", requiredMember);
        end if;

    end proc:

end module: