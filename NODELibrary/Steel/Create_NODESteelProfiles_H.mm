# Create_NODESteelProfiles_H.mm :create HEA, HEB and HEM sections
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
   data:=convert(ExcelTools:-Import("Data/Steelprofiles.xlsx","H_complete","A4:BE"), Matrix):
   data:=subs("&ndash;" = NULL,data):

   # This is the metadata from the spreadsheet
   # - ingen dots in variablename!

   metadata:=[ 
   [A, "section", 1, "Betegnelse iht. EN 10365"]
   ,[B, "name_Euronorm_old", 1, "Betegnelse iht. Euronorm"]
   ,[C, "steelcode", 1, "Verdier iht. standard"]
   ,[D, "h", (mm), "høyde"]
   ,[E, "b", (mm), "bredde"]
   ,[F, "t_w", (mm), "stegtykkelse"]
   ,[G, "t_f", (mm), "flenstykkelse"]
   ,[H, "r", (mm), "radius"]
   ,[I, "d", (mm), "rett steghøyde"]
   ,[J, "h_w", (mm), "steghøyde mellom flenser"]

   ,[K, "A", (cm^2), "tverrsnittsareal"]
   ,[L, "A_vy", (cm^2), "skjærareal i y-retning"]
   ,[M, "A_steg", (cm^2), "skjærareal steg"]
   ,[N, "A_z", (cm^2), "stegareal inkludert utrunding"]
   ,[O, "A_vz", (cm^2), "virksom skjærareal iht. EC3"]
   ,[P, "U", (cm), "omkrets tverrsnitt"]
   ,[Q, "m_k", (kg/m), "masse"]
   ,[R, "g_k", (kN/m), "vekt"]
   ,[S, "alpha_1", 1, "stegareal / totalareal"]

   ,[T, "I_y", (cm^4), "treghetsmoment om y-akse"]
   ,[U, "I_z", (cm^4), "treghetsmoment om z-akse"]
   ,[V, "I_p", (cm^4), "polar treghetsmoment"]
   ,[W, "W_el_y", (cm^3), "elastisk motstandsmoment om y-akse"]
   ,[X, "W_el_z", (cm^3), "elastisk motstandsmoment om z-akse"]
   ,[Y, "W_pl_y", (cm^3), "plastisk motstandsmoment om y-akse"]
   ,[Z, "W_pl_z", (cm^3), "plastisk motstandsmoment om z-akse"]
   ,[AA, "S_y", (cm^3), "statisk moment om y-akse"]
   ,[AB,"S_z", (cm^3), "statisk moment om z-akse"]
   ,[AC,"i_y", (cm), "treghetsradius om y-akse"]
   ,[AD,"i_z", (cm), "treghetsradius om z-akse "]
   ,[AE,"i_p", (cm), "polar treghetsradius"]

   ,[AF, "I_t_0", (cm^4), "torsjonsmotstandsmoment uten utrunding"]
   ,[AG, "I_t", (cm^4), "torsjonsmotstandsmoment med utrunding"]
   ,[AH, "omega_max", (cm^2), "warping"]
   ,[AI, "S_omega_max", (cm^4), "warping"]
   ,[AJ, "I_omega", (cm^6), "warping"]
   ,[AK, "W_omega", (cm^4), "warping"]

   ,[AL, "alpha_pl_y", 1, "plastisk formfaktor om y-akse"]
   ,[AM, "alpha_pl_z", 1, "plastisk formfaktor om z-akse"]

   ,[AN, "alpha_2", 1, "d / tw"]
   ,[AO, "alpha_3", 1, "c / tf"]
   ,[AP, "alpha_4", 1, "hw / tw"]

   ,[AQ, "N_pl_Rk_S235", (kN), "plastisk bruddlast"]
   ,[AR, "M_el_y_Rk_S235", (kN*m), "elastisk bruddmoment om y-akse"]
   ,[AS, "M_el_z_Rk_S235", (kN*m), "elastisk bruddmoment om z-akse"]
   ,[AT, "M_pl_y_Rk_S235", (kN*m), "plastisk bruddmoment om y-akse"]
   ,[AU, "M_pl_z_Rk_S235", (kN*m), "plastisk bruddmoment om z-akse"]
   ,[AV, "V_pl_y_Rk_S235", (kN), "plastisk bruddlast i y-retning"]
   ,[AW, "V_pl_z_Rk_S235", (kN), "plastisk bruddlast i z-retning"]

   ,[AX, "buckling_curve_y_S235-420", 1, "Knekklinje y-y, S235-420"]
   ,[AY, "buckling_curve_z_S235-420", 1, "Knekklinje z-z, S235-420"]
   ,[AZ, "buckling_curve_y_S460", 1, "Knekklinje y-y, S460"]
   ,[BA, "buckling_curve_z_S460", 1, "Knekklinje z-z, S460"]
   ,[BB, "d_L", (mm), "Flenshulldiameter"]
   ,[BC, "w_1", (mm), "Avstand flenshull"]
   ,[BD, "w_2", (mm), "Avstand flenshull"]
   ,[BE, "w_3", (mm), "Avstand flenshull"]
   ]:

   # Create a table data structure and read the material data into it
   # i...number of rows with values
   # j...number of columns with values

   dataTable:=table():

   for i from 1 to numelems(data[..,1]) do
      if data[i,1] <> NULL and data[i,1] <> "" then   # we don't want empty rows at end of worksheet

         dataTable[data[i,1]] := table([
            "steelcode" = data[i,3],
            seq(metadata[j,2] = `if`(data[i,j]<>NULL, data[i,j]*Unit(metadata[j,3]), NULL), j = 4..57)
            ]);

         # index for old names
         dataTable[data[i,2]] := table([
            "steelcode" = data[i,3],
            seq(metadata[j,2] = `if`(data[i,j]<>NULL, data[i,j]*Unit(metadata[j,3]), NULL), j = 4..57)
            ]);

      end if;
   end do:

   # write out to textfile
   ofilename := "Steel/Data_H.mm";
   file := FileTools[Text][Open](ofilename, create=true, overwrite=true);

   # %a i sprintf dumps table/matrix into raw, valid Maple-code
   FileTools[Text][WriteString](file, sprintf("metadata := %a:\n", eval(metadata)));
   FileTools[Text][WriteString](file, sprintf("dataTable := %a:\n", eval(dataTable)));
   FileTools[Text][Close](file);

end proc(): # () makes it run immediately at $include