# Create_NODEConcreteMaterial.mm
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

# Create_NODEConcreteMaterial.mm

proc()
    local rawData, metadata, dataTable, i, j, outputFile, outputFilename, currentClass, concreteProperties;
    uses ExcelTools;

    # Dynamic import: Only reads columns A to D (the first 4 columns)
    rawData := convert(ExcelTools:-Import("Data/Materialdata.xlsx", "concrete", "A1:D"), Matrix):
    rawData := subs("&ndash;" = NULL, rawData):

    # Metadata describing columns, units, and descriptions for the first 4 columns
    metadata := [
         [A, "strengthclass_NS", 1, "Strength class NS, e.g. B35, LB30"]
        ,[B, "strengthclass_CEN", 1, "Strength class CEN, e.g. C20/25, LC25/28"]
        ,[C, "f_ck", (MPa), "characteristic cylinder compressive strength after 28 days"]
        ,[D, "f_ck,cube", (MPa), "characteristic cube compressive strength after 28 days"]
    ]:

    dataTable := table():

    # Populate the table starting from row 2
    for i from 2 to numelems(rawData[.., 1]) do
        currentClass := rawData[i, 1];

        # Strict type-check: ensures we skip ghost rows, NULL values, or numeric zeros (like 0.)
        if currentClass <> NULL and currentClass <> "" and type(currentClass, string) then
            
            # Map parameters. We use j = 3..4 to apply units to f_ck and f_ck,cube
            concreteProperties := table([
                "strengthclass_CEN" = rawData[i, 2],
                seq(metadata[j, 2] = `if`(rawData[i, j]<>NULL and rawData[i, j]<>-"" and rawData[i, j]<>" -", 
                                         rawData[i, j]*Unit(metadata[j, 3]), NULL), j = 3..4)
            ]);

            # Store inside the datatable with proper evaluation
            dataTable[currentClass] := eval(concreteProperties);
        end if;
    end do:

    # Export everything safely to Data_ConcreteMaterial.mm
    outputFilename := "Concrete/Data_ConcreteMaterial.mm";
    outputFile := FileTools[Text][Open](outputFilename, create=true, overwrite=true);

    FileTools[Text][WriteString](outputFile, sprintf("metadata := %a:\n", eval(metadata)));
    FileTools[Text][WriteString](outputFile, sprintf("dataTable := %a:\n", eval(dataTable)));

    FileTools[Text][Close](outputFile);

end proc(): # Executed immediately upon building