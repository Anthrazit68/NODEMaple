# Create_NODESteelProfiles_I.mm : create I-shaped profiles
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
   # - no dots in variable names!

   metadata:= [
   [A, "section", 1, "Designation according to EN 10365"]
   ,[B, "steelcode", 1, "Values according to standard"]
   ,[C, "h", (mm), "height"]
   ,[D, "b", (mm), "width"]
   ,[E, "t_w", (mm), "web thickness"]
   ,[F, "t_f", (mm), "flange thickness"]
   ,[G, "r", (mm), "root radius"]
   ,[H, "d", (mm), "straight web depth between fillets"]
   ,[I, "h_w", (mm), "web height between flanges"]

   ,[J, "A", (cm^2), "cross-sectional area"]
   ,[K, "A_vy", (cm^2), "shear area in y-direction"]
   ,[L, "A_steg", (cm^2), "web shear area"]
   ,[M, "A_z", (cm^2), "web area including root radii"]
   ,[N, "A_vz", (cm^2), "effective shear area according to EC3"]
   ,[O, "U", (cm), "perimeter of cross-section"]
   ,[P, "m_k", (kg/m), "mass"]
   ,[Q, "g_k", (kN/m), "weight"]
   ,[R, "alpha_1", 1, "web area / total area"]

   ,[S, "I_y", (cm^4), "second moment of area about y-axis"]
   ,[T, "I_z", (cm^4), "second moment of area about z-axis"]
   ,[U, "I_p", (cm^4), "polar second moment of area"]
   ,[V, "W_el_y", (cm^3), "elastic section modulus about y-axis"]
   ,[W, "W_el_z", (cm^3), "elastic section modulus about z-axis"]
   ,[X, "W_pl_y", (cm^3), "plastic section modulus about y-axis"]
   ,[Y, "W_pl_z", (cm^3), "plastic section modulus about z-axis"]
   ,[Z, "S_y", (cm^3), "first moment of area about y-axis"]
   ,[AA, "S_z", (cm^3), "first moment of area about z-axis"]
   ,[AB, "i_y", (cm), "radius of gyration about y-axis"]
   ,[AC, "i_z", (cm), "radius of gyration about z-axis "]
   ,[AD, "i_p", (cm), "polar radius of gyration"]

   ,[AE, "I_t_0", (cm^4), "torsional constant without root radii"]
   ,[AF, "I_t", (cm^4), "torsional constant including root radii"]
   ,[AG, "omega_max", (cm^2), "warping"]
   ,[AH, "S_omega_max", (cm^4), "warping"]
   ,[AI, "I_omega", (cm^6), "warping"]
   ,[AJ, "W_omega", (cm^4), "warping"]

   ,[AK, "alpha_pl_y", 1, "plastic shape factor about y-axis"]
   ,[AL, "alpha_pl_z", 1, "plastic shape factor about z-axis"]

   ,[AM, "alpha_2", 1, "d / tw"]
   ,[AN, "alpha_3", 1, "c / tf"]
   ,[AO, "alpha_4", 1, "hw / tw"]

   ,[AP, "N_pl_Rk_S235", (kN), "plastic axial resistance"]
   ,[AQ, "M_el_y_Rk_S235", (kN*m), "elastic moment resistance about y-axis"]
   ,[AR, "M_el_z_Rk_S235", (kN*m), "elastic moment resistance about z-axis"]
   ,[AS, "M_pl_y_Rk_S235", (kN*m), "plastic moment resistance about y-axis"]
   ,[AT, "M_pl_z_Rk_S235", (kN*m), "plastic moment resistance about z-axis"]
   ,[AU, "V_pl_y_Rk_S235", (kN), "plastic shear resistance in y-direction"]
   ,[AV, "V_pl_z_Rk_S235", (kN), "plastic shear resistance in z-direction"]

   ,[AW, "buckling_curve_y_S235-420", 1, "Buckling curve y-y, S235-420"]
   ,[AX, "buckling_curve_z_S235-420", 1, "Buckling curve z-z, S235-420"]
   ,[AY, "buckling_curve_y_S460", 1, "Buckling curve y-y, S460"]
   ,[AZ, "buckling_curve_z_S460", 1, "Buckling curve z-z, S460"]
   ,[BA, "d_L", (mm), "flange hole diameter"]
   ,[BB, "w_1", (mm), "flange hole spacing"]
   ]:

   # Create a table data structure and read the profile data into it
   # i...number of rows with values
   # j...number of columns with values

   dataTable:=table():

   for i from 1 to numelems(data[..,1]) do
      if data[i,1] <> NULL and data[i,1] <> "" then   # we don't want empty rows at end of worksheet
         dataTable[data[i,1]] := table([
            "section"   = data[i,1],
            "steelcode" = data[i,2],
            seq(
               metadata[j,2] = `if`(
                  data[i,j] <> NULL,
                  `if`(type(data[i,j], string),
                      data[i,j],
                      data[i,j]*Unit(metadata[j,3])),
                  NULL
               ),
               j = 3..numelems(metadata)
            )
         ]);
      end if;
   end do:

   # write out to textfile
   ofilename := "Steel/Data_I.mm";
   file := FileTools[Text][Open](ofilename, create=true, overwrite=true);

   # %a in sprintf dumps table/matrix into raw, valid Maple-code
   FileTools[Text][WriteString](file, sprintf("metadata := %a:\n", eval(metadata)));
   FileTools[Text][WriteString](file, sprintf("dataTable := %a:\n", eval(dataTable)));
   FileTools[Text][Close](file);

end proc(): # () makes it run immediately at $include