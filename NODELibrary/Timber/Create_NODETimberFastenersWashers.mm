# Create_NODETimberFastenersWashers.mm : process washers database
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
    local rawData, metadata, i, outputFile, outputFilename, rowKey,
          fm_dbolt, prod, bet, descr, fm_dint, fm_dext, fm_s;
    uses ExcelTools, ListTools, NODEFunctions;

    # 1. Import raw data from Excel (Columns A to G, dynamic row depth)
    rawData := convert(ExcelTools:-Import("Data/TimberFasteners.xlsx", "Washers", "A2:G"), Matrix):
    rawData := subs("&ndash;" = NULL, rawData):

    # 2. Metadata describing columns, units, and engineering dimensions
    metadata := [ 
         [A, "prod", 1, "Producer"]
        ,[B, "bet", 1, "Type / Designation"]
        ,[C, "descr", 1, "Usage / Application description"]
        ,[D, "fm_dbolt", (mm), "Nominal bolt diameter"]
        ,[E, "fm_dint", (mm), "Internal washer diameter"]
        ,[F, "fm_dext", (mm), "External washer diameter"]
        ,[G, "fm_s", (mm), "Washer thickness"]
    ]:

    # 3. Initialize database lookup tables and sets
    fm_dbolt := {};
    prod := table();
    bet := table();
    descr := table();
    fm_dint := table();
    fm_dext := table();
    fm_s := table();

    # 4. Map matrix and populate relational indices via single scan pass
    for i from 1 to numelems(rawData[..,1]) do
        # Avoid processing potential trailing empty spreadsheet spaces
        if rawData[i,1] <> NULL and rawData[i,1] <> "" then
            
            # Save nominal bolt diameters as a unique set using standard units
            fm_dbolt := fm_dbolt union {rawData[i,4] * Unit('mm')};

            # Hierarchy 1: Bolt Diameter (kept unit-free for strict index key matching) -> Producer
            if not assigned(prod[rawData[i,4]]) then prod[rawData[i,4]] := {}; end if;
            prod[rawData[i,4]] := prod[rawData[i,4]] union {rawData[i,1]};

            # Hierarchy 2: Bolt Diameter -> Producer -> Type (Designation)
            if not assigned(bet[rawData[i,4], rawData[i,1]]) then bet[rawData[i,4], rawData[i,1]] := {}; end if;
            bet[rawData[i,4], rawData[i,1]] := bet[rawData[i,4], rawData[i,1]] union {rawData[i,2]};

            # Complete dimension tracking matrix indexed by: [BoltDiameter, Producer, Type]
            rowKey := rawData[i,4], rawData[i,1], rawData[i,2];

            if not assigned(descr[rowKey]) then descr[rowKey] := {}; end if;
            descr[rowKey] := descr[rowKey] union {rawData[i,3]};

            # FIXED: Corrected reference from 'fm_dint' typo back to 'descr' table allocation
            if not assigned(fm_dint[rowKey]) then fm_dint[rowKey] := {}; end if;
            fm_dint[rowKey] := fm_dint[rowKey] union {rawData[i,5] * Unit('mm')};

            if not assigned(fm_dext[rowKey]) then fm_dext[rowKey] := {}; end if;
            fm_dext[rowKey] := fm_dext[rowKey] union {rawData[i,6] * Unit('mm')};

            if not assigned(fm_s[rowKey]) then fm_s[rowKey] := {}; end if;
            fm_s[rowKey] := fm_s[rowKey] union {rawData[i,7] * Unit('mm')};

        end if;
    end do:

    # 5. Serialization output writing clean Maple code expressions (%a)
    outputFilename := "Timber/Data_NODETimberFastenersWashers.mm";
    outputFile := FileTools[Text][Open](outputFilename, create=true, overwrite=true);

    FileTools[Text][WriteString](outputFile, sprintf("metadata := %a:\n", eval(metadata)));
    FileTools[Text][WriteString](outputFile, sprintf("fm_dbolt := %a:\n", eval(fm_dbolt)));
    FileTools[Text][WriteString](outputFile, sprintf("prod := %a:\n", eval(prod)));
    FileTools[Text][WriteString](outputFile, sprintf("bet := %a:\n", eval(bet)));
    FileTools[Text][WriteString](outputFile, sprintf("descr := %a:\n", eval(descr)));
    FileTools[Text][WriteString](outputFile, sprintf("fm_dint := %a:\n", eval(fm_dint)));
    FileTools[Text][WriteString](outputFile, sprintf("fm_dext := %a:\n", eval(fm_dext)));
    FileTools[Text][WriteString](outputFile, sprintf("fm_s := %a:\n", eval(fm_s)));

    FileTools[Text][Close](outputFile);

end proc():