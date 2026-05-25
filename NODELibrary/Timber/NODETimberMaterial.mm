# NODETimberMaterial : timber material properties
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

NODETimberMaterial:= module ()
	export Property, Strengthclasses;
	option package;  

	global metadata, data, dataTable;
	local parNames, memberNames, NODEMetadata, NODEData, NODETable, parPos;

	NODEMetadata := metadata;
	NODEData := data;
	NODETable := eval(dataTable,1);

	parNames:=convert(metadata[2..,2],list);
	memberNames:=convert(NODEData[2..,1],list);

	Property := proc(requiredMember::string,requiredPar::string)

     	# local parPos, memberPos:

		if _npassed = 2 then   
			if requiredMember in memberNames and requiredPar in parNames then
          		NODETable[requiredMember][requiredPar];
         		else
          		if not requiredMember in memberNames and not requiredPar in parNames then
               		error("Member and parameter not found");
            		elif not requiredMember in memberNames then
               		error("Member not found");
            		elif not requiredPar in parNames then
               		error("Parameter not found");
           		end if;
         		end if;

		elif _npassed = 3 and _passed[3] = "metadata" then
			parPos:=ListTools:-Search(requiredPar, parNames):
         			return NODEMetadata[parPos+1,5];
         		
		elif _npassed = 1 and _passed[1] = "allmembers" then
			return memberNames:

		elif _npassed = 1 and _passed[1] = "metadata" then
         		return parNames:	
         
		end if;

	end proc:


	Strengthclasses := proc(timbertype::string)::table;
		description "return sorted timberclasses";
		local val, tmp, timber, glulam, solidtimber, CLT;

		tmp := [indices](NODETable, indexorder);
		timber := convert(tmp[() .. (), 1], list);

		glulam := [];
		solidtimber := [];
		CLT := [];
	
		for val in timber do
			if searchtext("CLT", val) > 0 then
				CLT := [op(CLT), val]
				
     		elif searchtext("L", val) > 0 then
				glulam := [op(glulam), val];
				
			elif searchtext("C", val) > 0 then
				solidtimber := [op(solidtimber), val];
				
    			end if;
		end do;

		if timbertype = "Solid timber" then
			return eval(solidtimber)
			
		elif timbertype = "Glued laminated timber" then
			return eval(glulam)

		elif timbertype = "CLT" then
			return eval(CLT)

		elif timbertype = "all" then
			return eval(timber)

		else
			return eval(table())
			
		end if;
	end proc:
	
end module: