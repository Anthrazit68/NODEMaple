# Create_NODESteelProfiles_H.mm : create HEA, HEB and HEM sections
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
   local data, metadata, dataTable, properties, i, j, file, ofilename;
   data:=convert(ExcelTools:-Import("Data/Steelprofiles.xlsx","H_complete","A4:BE"), Matrix):
   data:=subs("&ndash;" = NULL,data):

   # This is the metadata from the spreadsheet
   # - no dots in variable names!

   metadata:= [
   [A, "section", 1, "Designation according to EN 10365"]
   ,[B, "name_Euronorm_old", 1, "Designation according to Euronorm"]
   ,[C, "steelcode", 1, "Values according to standard"]
   ,[D, "h", (mm), "height"]
   ,[E, "b", (mm), "width"]
   ,[F, "t_w", (mm), "web thickness"]
   ,[G, "t_f", (mm), "flange thickness"]
   ,[H, "r", (mm), "root radius"]
   ,[I, "d", (mm), "straight web depth between fillets"]
   ,[J, "h_w", (mm), "web height between flanges"]

   ,[K, "A", (cm^2), "cross-sectional area"]
   ,[L, "A_vy", (cm^2), "shear area in y-direction"]
   ,[M, "A_steg", (cm^2), "web shear area"]
   ,[N, "A_z", (cm^2), "web area including root radii"]
   ,[O, "A_vz", (cm^2), "effective shear area according to EC3"]
   ,[P, "U", (cm), "perimeter of cross-section"]
   ,[Q, "m_k", (kg/m), "mass"]
   ,[R, "g_k", (kN/m), "weight"]
   ,[S, "alpha_1", 1, "web area / total area"]

   ,[T, "I_y", (cm^4), "second moment of area about y-axis"]
   ,[U, "I_z", (cm^4), "second moment of area about z-axis"]
   ,[V, "I_p", (cm^4), "polar second moment of area"]
   ,[W, "W_el_y", (cm^3), "elastic section modulus about y-axis"]
   ,[X, "W_el_z", (cm^3), "elastic section modulus about z-axis"]
   ,[Y, "W_pl_y", (cm^3), "plastic section modulus about y-axis"]
   ,[Z, "W_pl_z", (cm^3), "plastic section modulus about z-axis"]
   ,[AA, "S_y", (cm^3), "first moment of area about y-axis"]
   ,[AB, "S_z", (cm^3), "first moment of area about z-axis"]
   ,[AC, "i_y", (cm), "radius of gyration about y-axis"]
   ,[AD, "i_z", (cm), "radius of gyration about z-axis "]
   ,[AE, "i_p", (cm), "polar radius of gyration"]

   ,[AF, "I_t_0", (cm^4), "torsional constant without root radii"]
   ,[AG, "I_t", (cm^4), "torsional constant including root radii"]
   ,[AH, "omega_max", (cm^2), "warping"]
   ,[AI, "S_omega_max", (cm^4), "warping"]
   ,[AJ, "I_omega", (cm^6), "warping"]
   ,[AK, "W_omega", (cm^4), "warping"]

   ,[AL, "alpha_pl_y", 1, "plastic shape factor about y-axis"]
   ,[AM, "alpha_pl_z", 1, "plastic shape factor about z-axis"]

   ,[AN, "alpha_2", 1, "d / tw"]
   ,[AO, "alpha_3", 1, "c / tf"]
   ,[AP, "alpha_4", 1, "hw / tw"]

   ,[AQ, "N_pl_Rk_S235", (kN), "plastic axial resistance"]
   ,[AR, "M_el_y_Rk_S235", (kN*m), "elastic moment resistance about y-axis"]
   ,[AS, "M_el_z_Rk_S235", (kN*m), "elastic moment resistance about z-axis"]
   ,[AT, "M_pl_y_Rk_S235", (kN*m), "plastic moment resistance about y-axis"]
   ,[AU, "M_pl_z_Rk_S235", (kN*m), "plastic moment resistance about z-axis"]
   ,[AV, "V_pl_y_Rk_S235", (kN), "plastic shear resistance in y-direction"]
   ,[AW, "V_pl_z_Rk_S235", (kN), "plastic shear resistance in z-direction"]

   ,[AX, "buckling_curve_y_S235-420", 1, "Buckling curve y-y, S235-420"]
   ,[AY, "buckling_curve_z_S235-420", 1, "Buckling curve z-z, S235-420"]
   ,[AZ, "buckling_curve_y_S460", 1, "Buckling curve y-y, S460"]
   ,[BA, "buckling_curve_z_S460", 1, "Buckling curve z-z, S460"]
   ,[BB, "d_L", (mm), "flange hole diameter"]
   ,[BC, "w_1", (mm), "flange hole spacing"]
   ,[BD, "w_2", (mm), "flange hole spacing"]
   ,[BE, "w_3", (mm), "flange hole spacing"]
   ]:

   # Create a table data structure and read the profile data into it
   # i...number of rows with values
   # j...number of columns with values

   dataTable:=table():

   for i from 1 to numelems(data[..,1]) do
      if data[i,1] <> NULL and data[i,1] <> "" then   # we don't want empty rows at end of worksheet

         # Build ONE properties table per row, then register it under
         # both the new (EN 10365) and the old (Euronorm) designation.
         properties := table([
            "section"            = data[i,1],
            "name_Euronorm_old" = data[i,2],
            "steelcode"          = data[i,3],
            seq(
               metadata[j,2] = `if`(
                  data[i,j] <> NULL,
                  `if`(type(data[i,j], string),
                      data[i,j],
                      data[i,j]*Unit(metadata[j,3])),
                  NULL
               ),
               j = 4..numelems(metadata)
            )
         ]);

         dataTable[data[i,1]] := eval(properties);

         # alias under the old Euronorm name (if present)
         if data[i,2] <> NULL and data[i,2] <> "" then
            dataTable[data[i,2]] := eval(properties);
         end if;

      end if;
   end do:

   # write out to textfile
   ofilename := "Steel/Data_H.mm";
   file := FileTools[Text][Open](ofilename, create=true, overwrite=true);

   # %a in sprintf dumps table/matrix into raw, valid Maple-code
   FileTools[Text][WriteString](file, sprintf("metadata := %a:\n", eval(metadata)));
   FileTools[Text][WriteString](file, sprintf("dataTable := %a:\n", eval(dataTable)));
   FileTools[Text][Close](file);

end proc(): # () makes it run immediately at $include