# NODEConcreteMaterial : definition of concrete material properties
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

NODEConcreteMaterial:= module ()
   export Property, Exposureclasses, Durabilityclasses: 
   option package;  

   local parNames, memberNames, NODEMetadata, NODEData, NODETable:

   NODEMetadata := metadata:
   NODEData := data:
   NODETable := eval(dataTable,1):

   parNames:=convert(metadata[2..,2],list):
   memberNames:=convert(NODEData[2..,1],list):

   Property:=proc(requiredMember::string,requiredPar::string)

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


	Exposureclasses := proc()::list;
		return ["X0", "XC1", "XC2", "XC3", "XC4", "XD1", "XD2", "XD3", "XS1", "XS2", "XS3", "XF1", "XF2", "XF3", "XF4", "XA1", "XA2", "XA3"]
	end proc:


	Durabilityclasses := proc()::list;
		return ["M90", "M60", "M45", "MF45", "M40", "MF40"]
	end proc:
	
end module:
