# NODESteelEN1993.mm : EN 1993 (steel) general procedures
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

NODESteelProfiles_I:= module()
	
	description "lagrer verdier for IPE profiler";
	export Property: 
	option package;  

	global metadata, data, dataTable;
	local parNames, memberNames, NODEMetadata, NODEData, NODETable;

   NODEMetadata := metadata:
   NODEData := data:
   NODETable := eval(dataTable,1):

   parNames:=convert(metadata[1..,2],list):
   memberNames := convert(NODEData[1..,1],list):	# betegnelser iht. EN 10365 - "IPE 300"

   Property:=proc(requiredMember::string,requiredPar::string)			# "IPE", "G"

      local parPos, memberPos:

      if _npassed = 2 then        
         if requiredMember in memberNames and requiredPar in parNames then
           NODETable[requiredMember][requiredPar]:
         else
            if not requiredMember in memberNames and not requiredPar in parNames then
               error("Member and parameter not found"):
            elif not requiredMember in memberNames then
               error("Member not found"):
            elif not requiredPar in parNames then
               error("Parameter not found"):
            end if:
         end if:

      elif _npassed = 3 and _passed[3] = "metadata" then
         parPos:=ListTools:-Search(requiredPar, parNames):
         return NODEMetadata[parPos+1,5]:

      elif _npassed = 1 and _passed[1] = "allmembers" then
         return memberNames:

      elif _npassed = 1 and _passed[1] = "metadata" then
         return parNames:

      end if:

   end proc:
end module: