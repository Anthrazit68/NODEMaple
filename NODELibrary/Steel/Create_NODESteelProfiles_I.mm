# Create_NODESteelProfiles_I.mm :create I-shaped profiles
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
   data:=convert(ExcelTools:-Import("Data/Steelprofiles.xlsx","I_complete","A4:BB"), Matrix):
   data:=subs("&ndash;" = NULL,data):

   # This is the metadata from the spreadsheet
   # - ingen dots in variablename!

metadata:=[ 
 [A, "section", 1, "Betegnelse iht. EN 10365"]
,[B, "steelcode", 1, "Verdier iht. standard"]
,[C, "h", (mm), "høyde"]
,[D, "b", (mm), "bredde"]
,[E, "t_w", (mm), "stegtykkelse"]
,[F, "t_f", (mm), "flenstykkelse"]
,[G, "r", (mm), "radius"]
,[H, "d", (mm), "rett steghøyde"]
,[I, "h_w", (mm), "steghøyde mellom flenser"]

,[J, "A", (cm^2), "tverrsnittsareal"]
,[K, "A_vy", (cm^2), "skjærareal i y-retning"]
,[L, "A_steg", (cm^2), "skjærareal steg"]
,[M, "A_z", (cm^2), "stegareal inkludert utrunding"]
,[N, "A_vz", (cm^2), "virksom skjærareal iht. EC3"]
,[O, "U", (cm), "omkrets tverrsnitt"]
,[P, "m_k", (kg/m), "masse"]
,[Q, "g_k", (kN/m), "vekt"]
,[R, "alpha_1", 1, "stegareal / totalareal"]

,[S, "I_y", (cm^4), "treghetsmoment om y-akse"]
,[T, "I_z", (cm^4), "treghetsmoment om z-akse"]
,[U, "I_p", (cm^4), "polar treghetsmoment"]
,[V, "W_el_y", (cm^3), "elastisk motstandsmoment om y-akse"]
,[W, "W_el_z", (cm^3), "elastisk motstandsmoment om z-akse"]
,[X, "W_pl_y", (cm^3), "plastisk motstandsmoment om y-akse"]
,[Y, "W_pl_z", (cm^3), "plastisk motstandsmoment om z-akse"]
,[Z, "S_y", (cm^3), "statisk moment om y-akse"]
,[AA,"S_z", (cm^3), "statisk moment om z-akse"]
,[AB,"i_y", (cm), "treghetsradius om y-akse"]
,[AC,"i_z", (cm), "treghetsradius om z-akse "]
,[AD,"i_p", (cm), "polar treghetsradius"]

,[AE, "I_t_0", (cm^4), "torsjonsmotstandsmoment uten utrunding"]
,[AF, "I_t", (cm^4), "torsjonsmotstandsmoment med utrunding"]
,[AG, "omega_max", (cm^2), "warping"]
,[AH, "S_omega_max", (cm^4), "warping"]
,[AI, "I_omega", (cm^6), "warping"]
,[AJ, "W_omega", (cm^4), "warping"]

,[AK, "alpha_pl_y", 1, "plastisk formfaktor om y-akse"]
,[AL, "alpha_pl_z", 1, "plastisk formfaktor om z-akse"]

,[AM, "alpha_2", 1, "d / tw"]
,[AN, "alpha_3", 1, "c / tf"]
,[AO, "alpha_4", 1, "hw / tw"]

,[AP, "N_pl_Rk_S235", (kN), "plastisk bruddlast"]
,[AQ, "M_el_y_Rk_S235", (kN*m), "elastisk bruddmoment om y-akse"]
,[AR, "M_el_z_Rk_S235", (kN*m), "elastisk bruddmoment om z-akse"]
,[AS, "M_pl_y_Rk_S235", (kN*m), "plastisk bruddmoment om y-akse"]
,[AT, "M_pl_z_Rk_S235", (kN*m), "plastisk bruddmoment om z-akse"]
,[AU, "V_pl_y_Rk_S235", (kN), "plastisk bruddlast i y-retning"]
,[AV, "V_pl_z_Rk_S235", (kN), "plastisk bruddlast i z-retning"]

,[AW, "buckling_curve_y_S235-420", 1, "Knekklinje y-y, S235-420"]
,[AX, "buckling_curve_z_S235-420", 1, "Knekklinje z-z, S235-420"]
,[AY, "buckling_curve_y_S460", 1, "Knekklinje y-y, S460"]
,[AZ, "buckling_curve_z_S460", 1, "Knekklinje z-z, S460"]
,[BA, "d_L", (mm), "Flenshulldiameter"]
,[BB, "w_1", (mm), "Avstand flenshull"]
]:

   # Create a table data structure and read the material data into it
   # i...number of rows with values
   # j...number of columns with values

   dataTable:=table():

   for i from 1 to numelems(data[..,1]) do
      if data[i,1] <> NULL and data[i,1] <> "" then   # we don't want empty rows at end of worksheet
         dataTable[data[i,1]] := table([
            "steelcode" = data[i,2],
            seq(metadata[j,2] = `if`(data[i,j]<>NULL, data[i,j]*Unit(metadata[j,3]), NULL), j = 3..54)
            ]);
      end if;
   end do:

   # write out to textfile
   ofilename := "Steel/Data_I.mm";
   file := FileTools[Text][Open](ofilename, create=true, overwrite=true);

   # %a i sprintf dumps table/matrix into raw, valid Maple-code
   FileTools[Text][WriteString](file, sprintf("metadata := %a:\n", eval(metadata)));
   FileTools[Text][WriteString](file, sprintf("dataTable := %a:\n", eval(dataTable)));
   FileTools[Text][Close](file);

end proc(): # () makes it run immediately at $include