# Create_NODESteelProfiles_HF_RHS.mm :create hot formed rectangular hollow sections
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

proc()
   local data, metadata, dataTable, i, j, file, ofilename;
   data:=convert(ExcelTools:-Import("Data/Steelprofiles.xlsx","HF RHS (Ezzat)","A4:BF"), Matrix):
   data:=subs("&ndash;" = NULL,data):

   # This is the metadata from the spreadsheet
   # - ingen dots in variablename!

   metadata:=[ 
   [A, "section", 1, "Betegnelse iht. EN 10219-2"]
   ,[B, "steelcode", 1, "Verdier iht. standard"]
   ,[C, "h", (mm), "høyde"]
   ,[D, "b", (mm), "bredde"]
   ,[E, "t", (mm), "tykkelse"]
   ,[F, "r_o", (mm), "ytre radius"]
   ,[G, "r_i", (mm), "indre radius"]

   ,[H, "A", (cm^2), "tverrsnittsareal"]
   ,[I, "A_vz", (cm^2), "virksom skjærareal iht. EC3"]
   ,[J, "A_vy", (cm^2), "skjærareal i y-retning"]

   ,[K, "U_o", (cm), "omkrets utside"]
   ,[L, "U_i", (cm), "omkrets innside"]
   ,[M, "U_m", (cm), "omkrets senterlinje"]
   ,[N, "m_k", (kg/m), "masse"]
   ,[O, "g_k", (kN/m), "vekt"]

   ,[P, "I_y", (cm^4), "treghetsmoment om y-akse"]
   ,[Q, "I_z", (cm^4), "treghetsmoment om z-akse"]
   ,[R, "I_p", (cm^4), "polar treghetsmoment"]
   ,[S, "W_el_y", (cm^3), "elastisk motstandsmoment om y-akse"]
   ,[T, "W_el_z", (cm^3), "elastisk motstandsmoment om z-akse"]
   ,[U, "W_pl_y", (cm^3), "plastisk motstandsmoment om y-akse"]
   ,[V, "W_pl_z", (cm^3), "plastisk motstandsmoment om z-akse"]
   ,[W, "S_y", (cm^3), "statisk moment om y-akse"]
   ,[X, "S_z", (cm^3), "statisk moment om z-akse"]
   ,[Y, "i_y", (cm), "treghetsradius om y-akse"]
   ,[Z, "i_z", (cm), "treghetsradius om z-akse "]
   ,[AA, "i_p", (cm), "polar treghetsradius"]

   ,[AB, "A_m", (cm^2), "Areal innenfor senterlinje"]
   ,[AC, "I_t", (cm^4), "torsjonsmotstandsmoment med utrunding"]
   ,[AD, "omega_0", (cm^2), "warping"]
   ,[AE, "omega_1", (cm^2), "warping"]
   ,[AF, "omega_2", (cm^2), "warping"]
   ,[AG, "omega_3", (cm^2), "warping"]
   ,[AH, "omega_max", (cm^2), "warping"]
   ,[AI, "S_omega_0", (cm^4), "warping"]
   ,[AJ, "S_omega_1", (cm^4), "warping"]
   ,[AK, "S_omega_2", (cm^4), "warping"]
   ,[AL, "S_omega_3", (cm^4), "warping"]
   ,[AM, "I_omega", (cm^6), "warping"]

   ,[AN, "alpha_pl_y", 1, "plastisk formfaktor om y-akse"]
   ,[AO, "alpha_pl_z", 1, "plastisk formfaktor om z-akse"]

   ,[AP, "alpha_1", 1, "d / t"]
   ,[AQ, "alpha_2", 1, "c / t"]

   ,[AR, "cross_section_class_bending_S235", 1, "Tverrsnittsklasse Bøyning S235"]
   ,[AS, "cross_section_class_compression_S235", 1, "Tverrsnittsklasse Trykk S235"]
   ,[AT, "cross_section_class_bending_S355", 1, "Tverrsnittsklasse Bøyning S355"]
   ,[AU, "cross_section_class_compression_S355", 1, "Tverrsnittsklasse Trykk S355"]
   ,[AV, "cross_section_class_bending_S460", 1, "Tverrsnittsklasse Bøyning S460"]
   ,[AW, "cross_section_class_compression_S460", 1, "Tverrsnittsklasse Trykk S460"]

   ,[AX, "N_pl_Rk_S235", (kN), "plastisk bruddlast"]
   ,[AY, "M_el_y_Rk_S235", (kN*m), "elastisk bruddmoment om y-akse"]
   ,[AZ, "M_el_z_Rk_S235", (kN*m), "elastisk bruddmoment om z-akse"]
   ,[BA, "M_pl_y_Rk_S235", (kN*m), "plastisk bruddmoment om y-akse"]
   ,[BB, "M_pl_z_Rk_S235", (kN*m), "plastisk bruddmoment om z-akse"]
   ,[BC, "V_pl_y_Rk_S235", (kN), "plastisk bruddlast i y-retning"]
   ,[BD, "V_pl_z_Rk_S235", (kN), "plastisk bruddlast i z-retning"]

   ,[BE, "buckling_curve_S235-420", 1, "Knekklinje, S235-420"]
   ,[BF, "buckling_curve_S460", 1, "Knekklinje, S460"]
   ]:


   # Create a table data structure and read the material data into it
   # i...number of rows with values
   # j...number of columns with values

   dataTable:=table():

   for i from 1 to numelems(data[..,1]) do
      if data[i,1] <> NULL and data[i,1] <> "" then   # we don't want empty rows at end of worksheet
         dataTable[data[i,1]] := table([
            "steelcode" = data[i,2],
            seq(metadata[j,2] = `if`(data[i,j]<>NULL, data[i,j]*Unit(metadata[j,3]), NULL), j = 3..58)
            ]);
      end if;
   end do:

   # write out to textfile
   ofilename := "Steel/Data_HF_RHS.mm";
   file := FileTools[Text][Open](ofilename, create=true, overwrite=true);

   # %a i sprintf dumps table/matrix into raw, valid Maple-code
   FileTools[Text][WriteString](file, sprintf("metadata := %a:\n", eval(metadata)));
   FileTools[Text][WriteString](file, sprintf("dataTable := %a:\n", eval(dataTable)));
   FileTools[Text][Close](file);

end proc(): # () makes it run immediately at $include