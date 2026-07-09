# Create_NODETimberSplitRing.mm : process timber split ring connectors
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
          type_set, dc_set, producer_, information_, serviceclass_, 
          hc_, t_, r_, a1_, a2_, a3t_, a3c_, a4t_, a4c_;
    uses ExcelTools, ListTools, NODEFunctions;

    # 1. Import raw data matrix from Excel (Columns A to N, matching the template row array range)
    rawData := convert(ExcelTools:-Import("Data/TimberFasteners.xlsx", "Simpson SplitRing", "A3:N"), Matrix):
    rawData := subs("&ndash;" = NULL, rawData):

    # 2. Metadata configurations describing parameters and unit objects
    metadata := [ 
         [A, "prod", 1, "Producer"]
        ,[B, "type", 1, "Connector type classification"]
        ,[C, "information", 1, "Detailed type specifications"]
        ,[D, "serviceclass", 1, "Maximum service class eligibility"]
        ,[E, "dc", (mm), "Connector diameter"]
        ,[F, "hc", (mm), "Connector height"]
        ,[G, "t", (mm), "Connector thickness"]
        ,[H, "r", (mm), "Groove dimension radius"]
        ,[I, "a1", (mm), "Minimum spacing parallel to grain (a1)"]
        ,[J, "a2", (mm), "Minimum spacing perpendicular to grain (a2)"]
        ,[K, "a3t", (mm), "Minimum loaded end distance (a3,t)"]
        ,[L, "a3c", (mm), "Minimum unloaded end distance (a3,c)"]
        ,[M, "a4t", (mm), "Minimum loaded edge distance (a4,t)"]
        ,[N, "a4c", (mm), "Minimum unloaded edge distance (a4,c)"]
    ]:

    # 3. Initialize lookup tracking tables and unique component arrays
    type_set := {};
    dc_set := table();
    producer_ := table();
    information_ := table();
    serviceclass_ := table();
    hc_ := table();
    t_ := table();
    r_ := table();
    a1_ := table();
    a2_ := table();
    a3t_ := table();
    a3c_ := table();
    a4t_ := table();
    a4c_ := table();

    # 4. Map cross-reference arrays via a single structural data sweep
    for i from 1 to numelems(rawData[..,1]) do
        # Ignore empty worksheet slots safely
        if rawData[i,1] <> NULL and rawData[i,1] <> "" then
            
            # Save parent lookup indices
            type_set := type_set union {rawData[i,2]};

            # Hierarchy 1: Connector Type -> Unique Diameters List
            if not assigned(dc_set[rawData[i,2]]) then 
                dc_set[rawData[i,2]] := {}; 
            end if;
            dc_set[rawData[i,2]] := dc_set[rawData[i,2]] union {rawData[i,5] * Unit('mm')};

            # Uniform Index Matrix Key: [Type Name, Rounded Diameter Value]
            rowKey := rawData[i,2], round(rawData[i,5]);

            if not assigned(producer_[rowKey]) then producer_[rowKey] := {}; end if;
            producer_[rowKey] := producer_[rowKey] union {rawData[i,1]};

            if not assigned(information_[rowKey]) then information_[rowKey] := {}; end if;
            information_[rowKey] := information_[rowKey] union {rawData[i,3]};

            # FIXED: Fixed the mismatched index array check mapping error from rowData[i,4] to rowKey
            if not assigned(serviceclass_[rowKey]) then serviceclass_[rowKey] := {}; end if;
            serviceclass_[rowKey] := serviceclass_[rowKey] union {rawData[i,4]};

            if not assigned(hc_[rowKey]) then hc_[rowKey] := {}; end if;
            hc_[rowKey] := hc_[rowKey] union {rawData[i,6] * Unit('mm')};

            if not assigned(t_[rowKey]) then t_[rowKey] := {}; end if;
            t_[rowKey] := t_[rowKey] union {rawData[i,7] * Unit('mm')};

            if not assigned(r_[rowKey]) then r_[rowKey] := {}; end if;
            r_[rowKey] := r_[rowKey] union {rawData[i,8] * Unit('mm')};

            if not assigned(a1_[rowKey]) then a1_[rowKey] := {}; end if;
            a1_[rowKey] := a1_[rowKey] union {rawData[i,9] * Unit('mm')};

            if not assigned(a2_[rowKey]) then a2_[rowKey] := {}; end if;
            a2_[rowKey] := a2_[rowKey] union {rawData[i,10] * Unit('mm')};

            if not assigned(a3t_[rowKey]) then a3t_[rowKey] := {}; end if;
            a3t_[rowKey] := a3t_[rowKey] union {rawData[i,11] * Unit('mm')};

            if not assigned(a3c_[rowKey]) then a3c_[rowKey] := {}; end if;
            a3c_[rowKey] := a3c_[rowKey] union {rawData[i,12] * Unit('mm')};

            if not assigned(a4t_[rowKey]) then a4t_[rowKey] := {}; end if;
            a4t_[rowKey] := a4t_[rowKey] union {rawData[i,13] * Unit('mm')};

            if not assigned(a4c_[rowKey]) then a4c_[rowKey] := {}; end if;
            a4c_[rowKey] := a4c_[rowKey] union {rawData[i,14] * Unit('mm')};

        end if;
    end do:

    # 5. Compile final formatted file dump out using standard plaintext serialization (%a)
    outputFilename := "Timber/Data_NODETimberSplitRing.mm";
    outputFile := FileTools[Text][Open](outputFilename, create=true, overwrite=true);

    FileTools[Text][WriteString](outputFile, sprintf("metadata := %a:\n", eval(metadata)));
    FileTools[Text][WriteString](outputFile, sprintf("type_ := %a:\n", eval(type_set)));
    FileTools[Text][WriteString](outputFile, sprintf("dc_ := %a:\n", eval(dc_set)));
    FileTools[Text][WriteString](outputFile, sprintf("producer_ := %a:\n", eval(producer_)));
    FileTools[Text][WriteString](outputFile, sprintf("information_ := %a:\n", eval(information_)));
    FileTools[Text][WriteString](outputFile, sprintf("serviceclass_ := %a:\n", eval(serviceclass_)));
    FileTools[Text][WriteString](outputFile, sprintf("hc_ := %a:\n", eval(hc_)));
    FileTools[Text][WriteString](outputFile, sprintf("t_ := %a:\n", eval(t_)));
    FileTools[Text][WriteString](outputFile, sprintf("r_ := %a:\n", eval(r_)));
    FileTools[Text][WriteString](outputFile, sprintf("a1_ := %a:\n", eval(a1_)));
    FileTools[Text][WriteString](outputFile, sprintf("a2_ := %a:\n", eval(a2_)));
    FileTools[Text][WriteString](outputFile, sprintf("a3t_ := %a:\n", eval(a3t_)));
    FileTools[Text][WriteString](outputFile, sprintf("a3c_ := %a:\n", eval(a3c_)));
    FileTools[Text][WriteString](outputFile, sprintf("a4t_ := %a:\n", eval(a4t_)));
    FileTools[Text][WriteString](outputFile, sprintf("a4c_ := %a:\n", eval(a4c_)));

    FileTools[Text][Close](outputFile);

end proc():