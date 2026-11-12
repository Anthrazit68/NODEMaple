# Create_NODESteelProfiles_CF_SHS.mm : create cold formed square hollow sections
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
   data:=convert(ExcelTools:-Import("Data/Steelprofiles.xlsx","CF SHS (Ezzat)","A4:BE"), Matrix):
   data:=subs("&ndash;" = NULL,data):

   # This is the metadata from the spreadsheet
   # - no dots in variable names!

   metadata:= [
   [A, "section", 1, "Designation according to EN 10219-2"]
   ,[B, "steelcode", 1, "Values according to standard"]
   ,[C, "h", (mm), "height"]
   ,[D, "t", (mm), "thickness"]
   ,[E, "r_o", (mm), "outer radius"]
   ,[F, "r_i", (mm), "inner radius"]

   ,[G, "A", (cm^2), "cross-sectional area"]
   ,[H, "A_vz", (cm^2), "effective shear area according to EC3"]
   ,[I, "A_vy", (cm^2), "shear area in y-direction"]

   ,[J, "U_o", (cm), "perimeter, outside"]
   ,[K, "U_i", (cm), "perimeter, inside"]
   ,[L, "U_m", (cm), "perimeter, centre line"]
   ,[M, "m_k", (kg/m), "mass"]
   ,[N, "g_k", (kN/m), "weight"]

   ,[O, "I_y", (cm^4), "second moment of area about y-axis"]
   ,[P, "I_z", (cm^4), "second moment of area about z-axis"]
   ,[Q, "I_p", (cm^4), "polar second moment of area"]
   ,[R, "W_el_y", (cm^3), "elastic section modulus about y-axis"]
   ,[S, "W_el_z", (cm^3), "elastic section modulus about z-axis"]
   ,[T, "W_pl_y", (cm^3), "plastic section modulus about y-axis"]
   ,[U, "W_pl_z", (cm^3), "plastic section modulus about z-axis"]
   ,[V, "S_y", (cm^3), "first moment of area about y-axis"]
   ,[W, "S_z", (cm^3), "first moment of area about z-axis"]
   ,[X, "i_y", (cm), "radius of gyration about y-axis"]
   ,[Y, "i_z", (cm), "radius of gyration about z-axis "]
   ,[Z, "i_p", (cm), "polar radius of gyration"]

   ,[AA, "A_m", (cm^2), "area within centre line"]
   ,[AB, "I_t", (cm^4), "torsional constant including corner radii"]
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

   ,[AM, "alpha_pl_y", 1, "plastic shape factor about y-axis"]
   ,[AN, "alpha_pl_z", 1, "plastic shape factor about z-axis"]

   ,[AO, "alpha_1", 1, "d / t"]
   ,[AP, "alpha_2", 1, "c / t"]

   ,[AQ, "cross_section_class_bending_S235", 1, "Cross-section class, bending, S235"]
   ,[AR, "cross_section_class_compression_S235", 1, "Cross-section class, compression, S235"]
   ,[AS, "cross_section_class_bending_S355", 1, "Cross-section class, bending, S355"]
   ,[AT, "cross_section_class_compression_S355", 1, "Cross-section class, compression, S355"]
   ,[AU, "cross_section_class_bending_S460", 1, "Cross-section class, bending, S460"]
   ,[AV, "cross_section_class_compression_S460", 1, "Cross-section class, compression, S460"]

   ,[AW, "N_pl_Rk_S235", (kN), "plastic axial resistance"]
   ,[AX, "M_el_y_Rk_S235", (kN*m), "elastic moment resistance about y-axis"]
   ,[AY, "M_el_z_Rk_S235", (kN*m), "elastic moment resistance about z-axis"]
   ,[AZ, "M_pl_y_Rk_S235", (kN*m), "plastic moment resistance about y-axis"]
   ,[BA, "M_pl_z_Rk_S235", (kN*m), "plastic moment resistance about z-axis"]
   ,[BB, "V_pl_y_Rk_S235", (kN), "plastic shear resistance in y-direction"]
   ,[BC, "V_pl_z_Rk_S235", (kN), "plastic shear resistance in z-direction"]

   ,[BD, "buckling_curve_S235-420", 1, "Buckling curve, S235-420"]
   ,[BE, "buckling_curve_S460", 1, "Buckling curve, S460"]
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
   ofilename := "Steel/Data_CF_SHS.mm";
   file := FileTools[Text][Open](ofilename, create=true, overwrite=true);

   # %a in sprintf dumps table/matrix into raw, valid Maple-code
   FileTools[Text][WriteString](file, sprintf("metadata := %a:\n", eval(metadata)));
   FileTools[Text][WriteString](file, sprintf("dataTable := %a:\n", eval(dataTable)));
   FileTools[Text][Close](file);

end proc(): # () makes it run immediately at $include