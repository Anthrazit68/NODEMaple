# NODESteelProfiles_CF_SHS.mm: cold formed square hollow sections
# Copyright (C) 2024  Andreas Zieritz

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

NODESteelProfiles_CF_SHS:= module()
	uses NODEFunctions;
	description "CF SHS profiles";
    option package;
	export Property: 
	
   local metadata, dataTable, parNames, memberNames, parPos;
	
$include "Steel/Data_CF_SHS.mm"

   parNames:=convert(metadata[1..,2], list):
   memberNames := sort([indices(dataTable, 'nolist')], SortStructuralnames);

   Property := proc(requiredMember::string, requiredPar::string)
    uses ListTools;

    if _npassed = 2 then         
        
        # Sjekk direkte om profilen og parameteren faktisk eksisterer
        if assigned(dataTable[requiredMember]) then
            if assigned(dataTable[requiredMember][requiredPar]) then
                return dataTable[requiredMember][requiredPar];
            else
                error("Parameter not found: %1", requiredPar);
            end if;
        else
            error("Member not found: %1", requiredMember);
        end if;

    elif _npassed = 3 and _passed[3] = "metadata" then
        local parPos := ListTools:-Search(requiredPar, parNames);
        if parPos > 0 then
            return metadata[parPos, 4]; 
        else
            error("Parameter not found in metadata");
        end if;

    elif _npassed = 1 and _passed[1] = "allmembers" then
        return memberNames;

    elif _npassed = 1 and _passed[1] = "metadata" then
        return parNames;      
    end if;

   end proc:

end module: