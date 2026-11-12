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

    # Dispatch: 
    #   Property(grade, par)                          -> legacy grade-only lookup
    #   Property(grade, code, par)                    -> NEW unambiguous pair lookup
    #   Property(code, "allmembers")                  -> NEW grades of one code
    #   Property("allcodes")                          -> NEW list of codes
    Property := proc(requiredMember::string, requiredPar::string)
        uses ListTools;
        local key;

        if _npassed = 3 and _passed[3] <> "metadata" then
            # NEW: pair lookup, e.g. Property("S 275 H", "NS-EN 10210-1", "f_y_0_40")
            if _passed[3] = "steeltype" then
                return _passed[1];
            elif _passed[3] = "steelcode" then
                return _passed[2];
            end if;
            key := {_passed[1], _passed[2]};
            if assigned(dataTable1[key]) then
                if assigned(dataTable1[key][_passed[3]]) then
                    return dataTable1[key][_passed[3]];
                else
                    error("Parameter not found: %1", _passed[3]);
                end if;
            else
                error("Material set not found: %1", key);
            end if;

        elif _npassed = 1 and _passed[1] = "allcodes" then
            # NEW: list of standards
            return standarder;

        elif _npassed = 2 and _passed[2] = "allmembers" and
             assigned(steeltypeTocode[_passed[1]]) then
            # NEW: grades of one code, e.g. Property("NS-EN 10210-1", "allmembers")
            return steeltypeTocode[_passed[1]];

        elif _npassed = 2 then
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