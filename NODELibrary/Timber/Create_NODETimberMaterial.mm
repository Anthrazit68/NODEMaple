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

    # 1. Dynamic import: Reads from cell A1 down to the bottom of column R
    rawData := convert(ExcelTools:-Import("Data/Materialdata.xlsx", "timber", "A1:R"), Matrix):
    rawData := subs("&ndash;" = NULL, rawData):

    # 2. Metadata describing columns, units, and engineering variables
    # Note: Variable names use safe underscores instead of dots/commas
    metadata := [ 
         [A, "strengthclass", 1, "Strength class, e.g. C24, GL30c"]
        ,[B, "f_m_k", (N/mm^2), "Characteristic bending strength"]
        ,[C, "f_t_0_k", (N/mm^2), "Characteristic tension parallel strength"]
        ,[D, "f_t_90_k", (N/mm^2), "Characteristic tension perpendicular strength"]
        ,[E, "f_c_0_k", (N/mm^2), "Characteristic compression parallel strength"]
        ,[F, "f_c_90_k", (N/mm^2), "Characteristic compression perpendicular strength"]
        ,[G, "f_v_k", (N/mm^2), "Characteristic shear strength"]
        ,[H, "f_r_k", (N/mm^2), "Characteristic rolling shear strength"]
        ,[I, "E_m_0_mean", (N/mm^2), "Mean modulus of elasticity parallel"]
        ,[J, "E_m_0_k", (N/mm^2), "5% modulus of elasticity parallel"]
        ,[K, "E_m_90_mean", (N/mm^2), "Mean modulus of elasticity perpendicular"]
        ,[L, "E_90_05", (N/mm^2), "5% modulus of elasticity perpendicular"]
        ,[M, "G_mean", (N/mm^2), "Mean shear modulus"]
        ,[N, "G_0_05", (N/mm^2), "5% modulus of shear"]
        ,[O, "G_r_mean", (N/mm^2), "Mean modulus of rolling shear"]
        ,[P, "G_r_05", (N/mm^2), "5% modulus of rolling shear"]
        ,[Q, "rho_k", (kg/m^3), "Characteristic density"]
        ,[R, "rho_mean", (kg/m^3), "Mean density"]
    ]:

    # 3. Process data matrix rows and map material strengths
    dataTable := table():

    for i from 2 to numelems(rawData[..,1]) do
        # Prevent executing trailing empty worksheet padding
        if rawData[i,1] <> NULL and rawData[i,1] <> "" then
            
            # Map material properties. We loop j = 2..18 to skip the text column A (strengthclass)
            materialProperties := table([
                seq(metadata[j,2] = `if`(rawData[i,j]<>NULL, rawData[i,j]*Unit(metadata[j,3]), NULL), j = 2..18)
            ]);

            # Store the structured data table inside the master dataTable indexed by its strengthclass name
            dataTable[rawData[i,1]] := eval(materialProperties);
        end if;
    end do:

    # 4. Serialize all processed data components into a clean source file: Data_TimberMaterial.mm
    outputFilename := "Timber/Data_TimberMaterial.mm";
    outputFile := FileTools[Text][Open](outputFilename, create=true, overwrite=true);

    FileTools[Text][WriteString](outputFile, sprintf("metadata := %a:\n", eval(metadata)));
    FileTools[Text][WriteString](outputFile, sprintf("dataTable := %a:\n", eval(dataTable)));

    FileTools[Text][Close](outputFile);

end proc(): # Executed instantly upon build evaluation ($include)