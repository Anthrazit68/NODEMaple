# Create_NODESteelMaterial.mm :create steel material database
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
    local rawData, metadata, dataTable, dataTable1, standardsList, steelTypeToCode, i, j, 
          outputFile, outputFilename, currentStd, currentGrade, materialProperties;
    uses ExcelTools, ListTools, NODEFunctions;

    # Dynamic import: Reads from cell A2 down to the bottom of column J
    rawData := convert(ExcelTools:-Import("Data/Materialdata.xlsx", "steel", "A2:J"), Matrix):
    rawData := subs("&ndash;" = NULL, rawData):

    # Metadata describing columns, units, and descriptions
    metadata := [ 
         [A, "steeltype", 1, "Steel grade, e.g. S 235 H"]
        ,[B, "steelcode", 1, "Standard, e.g. NS-EN 10210-1"]
        ,[C, "f_y_0_40", (MPa), "yield strength, t=0-40mm"]
        ,[D, "f_u_0_40", (MPa), "tensile strength, t=0-40mm"]
        ,[E, "f_y_40_80", (MPa), "yield strength, t=40-80mm"]
        ,[F, "f_u_40_80", (MPa), "tensile strength, t=40-80mm"]
        ,[G, "E", (MPa), "modulus of elasticity"]
        ,[H, "nu", 1, "Poisson's ratio"]
        ,[I, "G", (MPa), "shear modulus"]
        ,[J, "alpha_t", (1/K), "coefficient of thermal expansion"]
    ]:

    # 1. Gather all unique standards from column 2 (e.g., "NS-EN 10025-2")
    standardsList := [];
    for i from 1 to numelems(rawData[..,2]) do
        currentStd := rawData[i,2];
        if currentStd <> NULL and currentStd <> "" and ListTools:-Search(currentStd, standardsList) = 0 then
            standardsList := [op(standardsList), currentStd];
        end if;
    end do:
    # Sort the standards list alphabetically
    standardsList := sort(standardsList);

    # 2. Initialize the relation table (mapping each standard to an empty list of steel grades)
    steelTypeToCode := table():
    for currentStd in standardsList do
        steelTypeToCode[currentStd] := [];
    end do:

    # 3. Create and populate the storage tables
    dataTable := table():
    dataTable1 := table():

    for i from 1 to numelems(rawData[..,1]) do
        currentGrade := rawData[i,1];
        currentStd := rawData[i,2];

        # Skip empty rows from the Excel sheet
        if currentGrade <> NULL and currentGrade <> "" then
            
            # Map material properties. We use j = 3..10 to skip text columns 1 and 2
            materialProperties := table([
                seq(metadata[j,2] = `if`(rawData[i,j]<>NULL, rawData[i,j]*Unit(metadata[j,3]), NULL), j = 3..10)
            ]);

            # CRITICAL FIX: Use eval(materialProperties) to store the actual data, 
            # not just the variable name string!
            dataTable[currentGrade] := eval(materialProperties);
            dataTable1[eval({currentGrade, currentStd})] := eval(materialProperties);

            # Append the steel grade to the list for this standard (if not already present)
            if ListTools:-Search(currentGrade, steelTypeToCode[currentStd]) = 0 then
                steelTypeToCode[currentStd] := [op(steelTypeToCode[currentStd]), currentGrade];
            end if;
        end if;
    end do:

    # 4. Sort the steel grades inside each standard using NODEFunctions
    for currentStd in standardsList do
        steelTypeToCode[currentStd] := sort(steelTypeToCode[currentStd], NODEFunctions:-SortStructuralnames);
    end do:

    # 5. Export all components into a single clean file: Data_SteelMaterial.mm
    outputFilename := "Steel/Data_SteelMaterial.mm";
    outputFile := FileTools[Text][Open](outputFilename, create=true, overwrite=true);

    FileTools[Text][WriteString](outputFile, sprintf("metadata := %a:\n", eval(metadata)));
    FileTools[Text][WriteString](outputFile, sprintf("dataTable := %a:\n", eval(dataTable)));
    FileTools[Text][WriteString](outputFile, sprintf("dataTable1 := %a:\n", eval(dataTable1)));
    FileTools[Text][WriteString](outputFile, sprintf("standarder := %a:\n", eval(standardsList)));
    FileTools[Text][WriteString](outputFile, sprintf("steeltypeTocode := %a:\n", eval(steelTypeToCode)));

    FileTools[Text][Close](outputFile);

end proc(): # Executed immediately upon building