# Create_NODESteelProfiles_HF_RHS.mm : create hot formed rectangular hollow sections
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
   # - no dots in variable names!

   metadata:= [
   [A, "section", 1, "Designation according to EN 10219-2"]
   ,[B, "steelcode", 1, "Values according to standard"]
   ,[C, "h", (mm), "height"]
   ,[D, "b", (mm), "width"]
   ,[E, "t", (mm), "thickness"]
   ,[F, "r_o", (mm), "outer radius"]
   ,[G, "r_i", (mm), "inner radius"]

   ,[H, "A", (cm^2), "cross-sectional area"]
   ,[I, "A_vz", (cm^2), "effective shear area according to EC3"]
   ,[J, "A_vy", (cm^2), "shear area in y-direction"]

   ,[K, "U_o", (cm), "perimeter, outside"]
   ,[L, "U_i", (cm), "perimeter, inside"]
   ,[M, "U_m", (cm), "perimeter, centre line"]
   ,[N, "m_k", (kg/m), "mass"]
   ,[O, "g_k", (kN/m), "weight"]

   ,[P, "I_y", (cm^4), "second moment of area about y-axis"]
   ,[Q, "I_z", (cm^4), "second moment of area about z-axis"]
   ,[R, "I_p", (cm^4), "polar second moment of area"]
   ,[S, "W_el_y", (cm^3), "elastic section modulus about y-axis"]
   ,[T, "W_el_z", (cm^3), "elastic section modulus about z-axis"]
   ,[U, "W_pl_y", (cm^3), "plastic section modulus about y-axis"]
   ,[V, "W_pl_z", (cm^3), "plastic section modulus about z-axis"]
   ,[W, "S_y", (cm^3), "first moment of area about y-axis"]
   ,[X, "S_z", (cm^3), "first moment of area about z-axis"]
   ,[Y, "i_y", (cm), "radius of gyration about y-axis"]
   ,[Z, "i_z", (cm), "radius of gyration about z-axis "]
   ,[AA, "i_p", (cm), "polar radius of gyration"]

   ,[AB, "A_m", (cm^2), "area within centre line"]
   ,[AC, "I_t", (cm^4), "torsional constant including corner radii"]
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

   ,[AN, "alpha_pl_y", 1, "plastic shape factor about y-axis"]
   ,[AO, "alpha_pl_z", 1, "plastic shape factor about z-axis"]

   ,[AP, "alpha_1", 1, "d / t"]
   ,[AQ, "alpha_2", 1, "c / t"]

   ,[AR, "cross_section_class_bending_S235", 1, "Cross-section class, bending, S235"]
   ,[AS, "cross_section_class_compression_S235", 1, "Cross-section class, compression, S235"]
   ,[AT, "cross_section_class_bending_S355", 1, "Cross-section class, bending, S355"]
   ,[AU, "cross_section_class_compression_S355", 1, "Cross-section class, compression, S355"]
   ,[AV, "cross_section_class_bending_S460", 1, "Cross-section class, bending, S460"]
   ,[AW, "cross_section_class_compression_S460", 1, "Cross-section class, compression, S460"]

   ,[AX, "N_pl_Rk_S235", (kN), "plastic axial resistance"]
   ,[AY, "M_el_y_Rk_S235", (kN*m), "elastic moment resistance about y-axis"]
   ,[AZ, "M_el_z_Rk_S235", (kN*m), "elastic moment resistance about z-axis"]
   ,[BA, "M_pl_y_Rk_S235", (kN*m), "plastic moment resistance about y-axis"]
   ,[BB, "M_pl_z_Rk_S235", (kN*m), "plastic moment resistance about z-axis"]
   ,[BC, "V_pl_y_Rk_S235", (kN), "plastic shear resistance in y-direction"]
   ,[BD, "V_pl_z_Rk_S235", (kN), "plastic shear resistance in z-direction"]

   ,[BE, "buckling_curve_S235-420", 1, "Buckling curve, S235-420"]
   ,[BF, "buckling_curve_S460", 1, "Buckling curve, S460"]
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
   ofilename := "Steel/Data_HF_RHS.mm";
   file := FileTools[Text][Open](ofilename, create=true, overwrite=true);

   # %a in sprintf dumps table/matrix into raw, valid Maple-code
   FileTools[Text][WriteString](file, sprintf("metadata := %a:\n", eval(metadata)));
   FileTools[Text][WriteString](file, sprintf("dataTable := %a:\n", eval(dataTable)));
   FileTools[Text][Close](file);

end proc(): # () makes it run immediately at $include