# Create_NODESteelProfiles_HF_SHS.mm :create hot formed square hollow sections
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
   data:=convert(ExcelTools:-Import("Data/Steelprofiles.xlsx","HF SHS (Ezzat)","A4:BE"), Matrix):
   data:=subs("&ndash;" = NULL,data):

   # This is the metadata from the spreadsheet
   # - ingen dots in variablename!

metadata:=[ 
 [A, "section", 1, "Betegnelse iht. EN 10219-2"]
,[B, "steelcode", 1, "Verdier iht. standard"]
,[C, "h", (mm), "høyde"]
,[D, "t", (mm), "tykkelse"]
,[E, "r_o", (mm), "ytre radius"]
,[F, "r_i", (mm), "indre radius"]

,[G, "A", (cm^2), "tverrsnittsareal"]
,[H, "A_vz", (cm^2), "virksom skjærareal iht. EC3"]
,[I, "A_vy", (cm^2), "skjærareal i y-retning"]

,[J, "U_o", (cm), "omkrets utside"]
,[K, "U_i", (cm), "omkrets innside"]
,[L, "U_m", (cm), "omkrets senterlinje"]
,[M, "m_k", (kg/m), "masse"]
,[N, "g_k", (kN/m), "vekt"]

,[O, "I_y", (cm^4), "treghetsmoment om y-akse"]
,[P, "I_z", (cm^4), "treghetsmoment om z-akse"]
,[Q, "I_p", (cm^4), "polar treghetsmoment"]
,[R, "W_el_y", (cm^3), "elastisk motstandsmoment om y-akse"]
,[S, "W_el_z", (cm^3), "elastisk motstandsmoment om z-akse"]
,[T, "W_pl_y", (cm^3), "plastisk motstandsmoment om y-akse"]
,[U, "W_pl_z", (cm^3), "plastisk motstandsmoment om z-akse"]
,[V, "S_y", (cm^3), "statisk moment om y-akse"]
,[W, "S_z", (cm^3), "statisk moment om z-akse"]
,[X, "i_y", (cm), "treghetsradius om y-akse"]
,[Y, "i_z", (cm), "treghetsradius om z-akse "]
,[Z, "i_p", (cm), "polar treghetsradius"]

,[AA, "A_m", (cm^2), "Areal innenfor senterlinje"]
,[AB, "I_t", (cm^4), "torsjonsmotstandsmoment med utrunding"]
,[AC, "omega_0", (cm^2), "warping"]
,[AD, "omega_1", (cm^2), "warping"]
,[AE, "omega_2", (cm^2), "warping"]
,[AF, "omega_3", (cm^2), "warping"]
,[AG, "omega_max", (cm^2), "warping"]
,[AH, "S_omega_0", (cm^4), "warping"]
,[AI, "S_omega_1", (cm^4), "warping"]
,[AJ, "S_omega_2", (cm^4), "warping"]
,[AK, "S_omega_3", (cm^4), "warping"]
,[AL, "I_omega", (cm^6), "warping"]

,[AM, "alpha_pl_y", 1, "plastisk formfaktor om y-akse"]
,[AN, "alpha_pl_z", 1, "plastisk formfaktor om z-akse"]

,[AO, "alpha_1", 1, "d / t"]
,[AP, "alpha_2", 1, "c / t"]

,[AQ, "cross_section_class_bending_S235", 1, "Tverrsnittsklasse Bøyning S235"]
,[AR, "cross_section_class_compression_S235", 1, "Tverrsnittsklasse Trykk S235"]
,[AS, "cross_section_class_bending_S355", 1, "Tverrsnittsklasse Bøyning S355"]
,[AT, "cross_section_class_compression_S355", 1, "Tverrsnittsklasse Trykk S355"]
,[AU, "cross_section_class_bending_S460", 1, "Tverrsnittsklasse Bøyning S460"]
,[AV, "cross_section_class_compression_S460", 1, "Tverrsnittsklasse Trykk S460"]

,[AW, "N_pl_Rk_S235", (kN), "plastisk bruddlast"]
,[AX, "M_el_y_Rk_S235", (kN*m), "elastisk bruddmoment om y-akse"]
,[AY, "M_el_z_Rk_S235", (kN*m), "elastisk bruddmoment om z-akse"]
,[AZ, "M_pl_y_Rk_S235", (kN*m), "plastisk bruddmoment om y-akse"]
,[BA, "M_pl_z_Rk_S235", (kN*m), "plastisk bruddmoment om z-akse"]
,[BB, "V_pl_y_Rk_S235", (kN), "plastisk bruddlast i y-retning"]
,[BC, "V_pl_z_Rk_S235", (kN), "plastisk bruddlast i z-retning"]

,[BD, "buckling_curve_S235-420", 1, "Knekklinje, S235-420"]
,[BE, "buckling_curve_S460", 1, "Knekklinje, S460"]
]:

   # Create a table data structure and read the material data into it
   # i...number of rows with values
   # j...number of columns with values

   dataTable:=table():

   for i from 1 to numelems(data[..,1]) do
      if data[i,1] <> NULL and data[i,1] <> "" then   # we don't want empty rows at end of worksheet
         dataTable[data[i,1]] := table([
            "steelcode" = data[i,2],
            seq(metadata[j,2] = `if`(data[i,j]<>NULL, data[i,j]*Unit(metadata[j,3]), NULL), j = 3..57)
            ]);
      end if;
   end do:

   # write out to textfile
   ofilename := "Steel/Data_HF_SHS.mm";
   file := FileTools[Text][Open](ofilename, create=true, overwrite=true);

   # %a i sprintf dumps table/matrix into raw, valid Maple-code
   FileTools[Text][WriteString](file, sprintf("metadata := %a:\n", eval(metadata)));
   FileTools[Text][WriteString](file, sprintf("dataTable := %a:\n", eval(dataTable)));
   FileTools[Text][Close](file);

end proc(): # () makes it run immediately at $include