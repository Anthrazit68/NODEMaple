# Create_NODETimberSections.mm : process timber section cross-sections
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
    local rawData, metadata, i, outputFile, outputFilename, timberTypeKey, widthKey,
          tretype_set, profil_b, profil_h;
    uses ExcelTools, ListTools, NODEFunctions;

    # 1. Import data matrix from Excel (Columns A to C, row 2 down to the end of the data layout)
    rawData := convert(ExcelTools:-Import("Data/TimberDimensions.xlsx", "Timber", "A2:C"), Matrix):
    rawData := subs("&ndash;" = NULL, rawData):

    # 2. Metadata definitions describing properties and default target units
    metadata := [ 
         [A, "Typ", 1, "Timber profile type (Solid timber, Glued laminated timber, or CLT)"]
        ,[B, "b", (mm), "Cross-section width"]
        ,[C, "h", (mm), "Cross-section height"]
    ]:

    # 3. Initialize lookup sets and configuration index tables
    tretype_set := {};
    profil_b := table();
    profil_h := table();

    # 4. Parse the raw tracking data in a single pass to map profile layouts
    for i from 1 to numelems(rawData[..,1]) do
        # Protect logic from failing on unexpected whitespace rows at the bottom of the worksheet
        if rawData[i,1] <> NULL and rawData[i,1] <> "" then
            
            # Extract names and round out data-entry float decimal points (e.g., converting 90.0 to 90)
            timberTypeKey := rawData[i,1];
            widthKey      := round(rawData[i,2]);

            # Store the unique structural category types
            tretype_set := tretype_set union {timberTypeKey};

            # Hierarchy Level 1: Timber Category Type -> Width Set
            if not assigned(profil_b[timberTypeKey]) then 
                profil_b[timberTypeKey] := {}; 
            end if;
            profil_b[timberTypeKey] := profil_b[timberTypeKey] union {widthKey * Unit('mm')};

            # Hierarchy Level 2: [Timber Category Type, Width (unit-free for lookup matching)] -> Height Set
            if not assigned(profil_h[timberTypeKey, widthKey]) then 
                profil_h[timberTypeKey, widthKey] := {}; 
            end if;
            profil_h[timberTypeKey, widthKey] := profil_h[timberTypeKey, widthKey] union {round(rawData[i,3]) * Unit('mm')};

        end if;
    end do:

    # 5. Output file generation, compiling cleanly structured text code expressions (%a)
    outputFilename := "Timber/Data_NODETimberSections.mm";
    outputFile := FileTools[Text][Open](outputFilename, create=true, overwrite=true);

    FileTools[Text][WriteString](outputFile, sprintf("metadata := %a:\n", eval(metadata)));
    FileTools[Text][WriteString](outputFile, sprintf("tretype := %a:\n", eval(tretype_set)));
    FileTools[Text][WriteString](outputFile, sprintf("profil_b := %a:\n", eval(profil_b)));
    FileTools[Text][WriteString](outputFile, sprintf("profil_h := %a:\n", eval(profil_h)));

    FileTools[Text][Close](outputFile);

end proc(): # Compiled immediately when called via $include paths