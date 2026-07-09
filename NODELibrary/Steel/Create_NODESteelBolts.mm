# Create_NODESteelbolts.mm :create steel bolts database
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
    local rawData, metadata, boltGradesList, fubTable, fubTabTable, ftRdTabTable, asNomTable,
          i, j, outputFile, outputFilename;
    uses ExcelTools, NODEFunctions;

    # Dynamic import: Reads from cell A1 down to the bottom of column M
    rawData := convert(ExcelTools:-Import("Data/TimberFasteners.xlsx", "BoltGrades", "A1:M"), Matrix):
    rawData := subs("&ndash;" = NULL, rawData):

    # Metadata describing columns, units, and descriptions
    metadata := [ 
         [A, "bolt", 1, "Bolt type"]
        ,[B, "As_nom", (mm^2), "nominal section area"]
        ,[C, "Ftensk_4_6", (kN), "tensile strength, 4.6 quality"]
        ,[D, "Ftensk_4_8", (kN), "tensile strength, 4.8 quality"]
        ,[E, "Ftensk_5_6", (kN), "tensile strength, 5.6 quality"]
        ,[F, "Ftensk_5_8", (kN), "tensile strength, 5.8 quality"]
        ,[G, "Ftensk_6_8", (kN), "tensile strength, 6.8 quality"]
        ,[H, "Ftensk_8_8", (kN), "tensile strength, 8.8 quality"]
        ,[I, "Ftensk_10_9", (kN), "tensile strength, 10.9 quality"]
        ,[J, "Ftensk_50", (kN), "tensile strength, A1 / A5 - 50 quality"]
        ,[K, "Ftensk_70", (kN), "tensile strength, A1 / A5 - 70 quality"]
        ,[L, "Ftensk_80", (kN), "tensile strength, A1 / A5 - 80 quality"]
        ,[M, "Ftensk_100", (kN), "tensile strength, A1 / A5 - 100 quality"]
    ]:

    # Extract bolt grade strings from row 1 and sort them using your universal routine
    boltGradesList := sort(convert(rawData[1, 3..13], list), NODEFunctions:-SortStructuralnames);

    fubTable := table():
    fubTabTable := table():
    for j from 3 to 13 do
        fubTable[rawData[1, j]] := rawData[2, j] * Unit('N/mm^2');
        fubTabTable[rawData[1, j]] := rawData[3, j] * Unit('N/mm^2');
    end do:

    ftRdTabTable := table():
    asNomTable := table():
    for i from 4 to numelems(rawData[.., 1]) do
        # Skip potential empty rows at the bottom of the Excel sheet
        if rawData[i, 1] <> NULL and rawData[i, 1] <> "" then
            
            # Map nominal area table
            asNomTable[rawData[i, 1]] := rawData[i, 2] * Unit('mm^2');
            
            # Map design capacities matrix table
            for j from 3 to 13 do
                ftRdTabTable[rawData[i, 1], rawData[1, j]] := rawData[i, j] * Unit('kN');
            end do;
        end if;
    end do:

    # Export all processed datasets into a clean file: Data_NODESteelbolts.mm
    outputFilename := "Steel/Data_NODESteelbolts.mm";
    outputFile := FileTools[Text][Open](outputFilename, create=true, overwrite=true);

    FileTools[Text][WriteString](outputFile, sprintf("boltgrades_ := %a:\n", eval(boltGradesList)));
    FileTools[Text][WriteString](outputFile, sprintf("f_ub_ := %a:\n", eval(fubTable)));
    FileTools[Text][WriteString](outputFile, sprintf("f_ub_tab_ := %a:\n", eval(fubTabTable)));
    FileTools[Text][WriteString](outputFile, sprintf("F_tRd_tab_ := %a:\n", eval(ftRdTabTable)));
    FileTools[Text][WriteString](outputFile, sprintf("As_nom_ := %a:\n", eval(asNomTable)));

    FileTools[Text][Close](outputFile);

end proc(): # Executed immediately upon building