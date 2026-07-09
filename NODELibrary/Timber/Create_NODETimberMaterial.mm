# Create_NODETimberMaterial.mm : create timber material database
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
    local rawData, metadata, dataTable, i, j, outputFile, outputFilename, materialProperties;
    uses ExcelTools, ListTools, NODEFunctions;

    # Read from cell A1 down to the end of data in column R
    rawData := convert(ExcelTools:-Import("Data/Materialdata.xlsx", "timber", "A1:R"), Matrix):
    rawData := subs("&ndash;" = NULL, rawData):

    metadata := [ 
         [A, "strengthclass", 1, "Strength class, e.g. C24, GL30c"]
        ,[B, "f_m,k", (N/mm^2), "Characteristic bending strength"]
        ,[C, "f_t,0,k", (N/mm^2), "Characteristic tension parallel strength"]
        ,[D, "f_t,90,k", (N/mm^2), "Characteristic tension perpendicular strength"]
        ,[E, "f_c,0,k", (N/mm^2), "Characteristic compression parallel strength"]
        ,[F, "f_c,90,k", (N/mm^2), "Characteristic compression perpendicular strength"]
        ,[G, "f_v,k", (N/mm^2), "Characteristic shear strength"]
        ,[H, "f_r,k", (N/mm^2), "Characteristic rolling shear strength"]
        ,[I, "E_m,0,mean", (N/mm^2), "Mean modulus of elasticity parallel"]
        ,[J, "E_m,0,k", (N/mm^2), "5% modulus of elasticity parallel"]
        ,[K, "E_m,90,mean", (N/mm^2), "Mean modulus of elasticity perpendicular"]
        ,[L, "E_90,05", (N/mm^2), "5% modulus of elasticity perpendicular"]
        ,[M, "G_mean", (N/mm^2), "Mean shear modulus"]
        ,[N, "G_0,05", (N/mm^2), "5% modulus of shear"]
        ,[O, "G_r,mean", (N/mm^2), "Mean modulus of rolling rolling shear"]
        ,[P, "G_r,05", (N/mm^2), "5% modulus of rolling shear"]
        ,[Q, "rho_k", (kg/m^3), "Characteristic density"]
        ,[R, "rho_mean", (kg/m^3), "Mean density"]
    ]:

    dataTable := table():

    # Dynamic boundary loop
    for i from 2 to numelems(rawData[..,1]) do
        # Explicitly ensure we only process rows that have a valid string class name
        if rawData[i,1] <> NULL and rawData[i,1] <> "" and type(rawData[i,1], string) then
            
            # CRITICAL FIX: j runs from 2..18 to skip mapping column A as a property
            materialProperties := table([
                seq(metadata[j,2] = `if`(rawData[i,j]<>NULL, rawData[i,j]*Unit(metadata[j,3]), NULL), j = 2..18)
            ]);

            dataTable[rawData[i,1]] := eval(materialProperties);
        end if;
    end do:

    outputFilename := "Timber/Data_TimberMaterial.mm";
    outputFile := FileTools[Text][Open](outputFilename, create=true, overwrite=true);
    FileTools[Text][WriteString](outputFile, sprintf("metadata := %a:\n", eval(metadata)));
    FileTools[Text][WriteString](outputFile, sprintf("dataTable := %a:\n", eval(dataTable)));
    FileTools[Text][Close](outputFile);

end proc():