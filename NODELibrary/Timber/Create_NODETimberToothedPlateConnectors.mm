# Create_NODETimberToothedPlateConnectors.mm : process toothed plate connector database
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
          sides_set, type_set, dc_set, producer_, information_, serviceclass_,
          d1_, h1_, hc_, t_, d2_, la1_, la2_, t1_, t2_, a1_, a2_, a3t_, a3c_, a4t_, a4c_, Rvk_;
    uses ExcelTools, ListTools, NODEFunctions;

    # 1. Import raw data matrix from Excel (Columns A to W, row 3 down to the end of data layout)
    rawData := convert(ExcelTools:-Import("Data/TimberFasteners.xlsx", "ToothedPlateConnectors", "A3:W"), Matrix):
    rawData := subs("&ndash;" = NULL, rawData):

    # 2. Metadata definitions describing parameters and engineering units
    metadata := [ 
         [A, "prod", 1, "Producer"]
        ,[B, "type", 1, "Connector type classification"]
        ,[C, "sides", 1, "Connector interface configuration (1 or 2-sided)"]
        ,[D, "information", 1, "Detailed structural specifications"]
        ,[E, "serviceclass", 1, "Maximum service class eligibility"]
        ,[F, "dc", (mm), "External connector diameter (dc)"]
        ,[G, "d1", (mm), "Internal bolt hole diameter (d1)"] # Fixed column key indexing label duplication
        ,[H, "h1", (mm), "Tooth depth height (h1)"]
        ,[I, "hc", (mm), "Flange height depth (hc)"]
        ,[J, "t", (mm), "Plate core base thickness (t)"]
        ,[K, "d2", (mm), "Alternative internal hole diameter (d2)"]
        ,[L, "la1", (mm), "Inherent spacing component parallel (a1)"]
        ,[M, "la2", (mm), "Inherent spacing component normal (a2)"]
        ,[N, "t1", (mm), "Minimum timber thickness element 1 (t1)"]
        ,[O, "t2", (mm), "Minimum timber thickness element 2 (t2)"]
        ,[P, "a1", (mm), "Minimum spacing limit parallel to grain (a1)"]
        ,[Q, "a2", (mm), "Minimum spacing limit normal to grain (a2)"]
        ,[R, "a3t", (mm), "Minimum loaded end distance boundary (a3,t)"]
        ,[S, "a3c", (mm), "Minimum unloaded end distance boundary (a3,c)"]
        ,[T, "a4t", (mm), "Minimum loaded edge distance boundary (a4,t)"]
        ,[U, "a4c", (mm), "Minimum unloaded edge distance boundary (a4,c)"]
        ,[V, "Rvk", (kN), "Characteristic shear capacity check value (R_v_k)"]
    ]:

    # 3. Initialize lookup tracking tables and unique component arrays
    sides_set := {};
    type_set := table();
    dc_set := table();
    producer_ := table();
    information_ := table();
    serviceclass_ := table();
    d1_ := table();
    h1_ := table();
    hc_ := table();
    t_ := table();
    d2_ := table();
    la1_ := table();
    la2_ := table();
    t1_ := table();
    t2_ := table();
    a1_ := table();
    a2_ := table();
    a3t_ := table();
    a3c_ := table();
    a4t_ := table();
    a4c_ := table();
    Rvk_ := table();

    # 4. Map cross-reference tracking objects using a single matrix loop pass
    for i from 1 to numelems(rawData[..,1]) do
        # Guard mapping engine against blank cell lines at the base of the file
        if rawData[i,1] <> NULL and rawData[i,1] <> "" then
            
            # Stringify integer keys to clear float decimal points (e.g. converting 1.0 to "1")
            local activeSides, activeType, activeDc;
            activeSides := convert(round(rawData[i,3]), string);
            activeType  := rawData[i,2];
            activeDc    := round(rawData[i,6]);

            # Assemble parent selection listings
            sides_set := sides_set union {activeSides};

            # Hierarchy Level 1: Interface Type (Sides) -> Product Types
            if not assigned(type_set[activeSides]) then 
                type_set[activeSides] := {}; 
            end if;
            type_set[activeSides] := type_set[activeSides] union {activeType};

            # Hierarchy Level 2: [Interface Type, Product Type] -> Diameter Set
            if not assigned(dc_set[activeSides, activeType]) then 
                dc_set[activeSides, activeType] := {}; 
            end if;
            dc_set[activeSides, activeType] := dc_set[activeSides, activeType] union {rawData[i,6] * Unit('mm')};

            # Uniform Compound Reference Multi-Key Index Array: [Sides, Type, Diameter]
            rowKey := activeSides, activeType, activeDc;

            if not assigned(producer_[rowKey]) then producer_[rowKey] := {}; end if;
            producer_[rowKey] := producer_[rowKey] union {rawData[i,1]};

            if not assigned(information_[rowKey]) then information_[rowKey] := {}; end if;
            information_[rowKey] := information_[rowKey] union {rawData[i,4]};

            if not assigned(serviceclass_[rowKey]) then serviceclass_[rowKey] := {}; end if;
            serviceclass_[rowKey] := serviceclass_[rowKey] union {rawData[i,5]};

            if not assigned(d1_[rowKey]) then d1_[rowKey] := {}; end if;
            d1_[rowKey] := d1_[rowKey] union {rawData[i,7] * Unit('mm')};

            if not assigned(h1_[rowKey]) then h1_[rowKey] := {}; end if;
            h1_[rowKey] := h1_[rowKey] union {rawData[i,8] * Unit('mm')};

            if not assigned(hc_[rowKey]) then hc_[rowKey] := {}; end if;
            hc_[rowKey] := hc_[rowKey] union {rawData[i,9] * Unit('mm')};

            if not assigned(t_[rowKey]) then t_[rowKey] := {}; end if;
            t_[rowKey] := t_[rowKey] union {rawData[i,10] * Unit('mm')};

            if not assigned(d2_[rowKey]) then d2_[rowKey] := {}; end if;
            d2_[rowKey] := d2_[rowKey] union {rawData[i,11] * Unit('mm')};

            if not assigned(la1_[rowKey]) then la1_[rowKey] := {}; end if;
            la1_[rowKey] := la1_[rowKey] union {rawData[i,12] * Unit('mm')};

            if not assigned(la2_[rowKey]) then la2_[rowKey] := {}; end if;
            la2_[rowKey] := la2_[rowKey] union {rawData[i,13] * Unit('mm')};

            if not assigned(t1_[rowKey]) then t1_[rowKey] := {}; end if;
            t1_[rowKey] := t1_[rowKey] union {rawData[i,14] * Unit('mm')};

            if not assigned(t2_[rowKey]) then t2_[rowKey] := {}; end if;
            t2_[rowKey] := t2_[rowKey] union {rawData[i,15] * Unit('mm')};

            if not assigned(a1_[rowKey]) then a1_[rowKey] := {}; end if;
            a1_[rowKey] := a1_[rowKey] union {rawData[i,16] * Unit('mm')};

            if not assigned(a2_[rowKey]) then a2_[rowKey] := {}; end if;
            a2_[rowKey] := a2_[rowKey] union {rawData[i,17] * Unit('mm')};

            if not assigned(a3t_[rowKey]) then a3t_[rowKey] := {}; end if;
            a3t_[rowKey] := a3t_[rowKey] union {rawData[i,18] * Unit('mm')};

            if not assigned(a3c_[rowKey]) then a3c_[rowKey] := {}; end if;
            a3c_[rowKey] := a3c_[rowKey] union {rawData[i,19] * Unit('mm')};

            if not assigned(a4t_[rowKey]) then a4t_[rowKey] := {}; end if;
            a4t_[rowKey] := a4t_[rowKey] union {rawData[i,20] * Unit('mm')};

            if not assigned(a4c_[rowKey]) then a4c_[rowKey] := {}; end if;
            a4c_[rowKey] := a4c_[rowKey] union {rawData[i,21] * Unit('mm')};

            if not assigned(Rvk_[rowKey]) then Rvk_[rowKey] := {}; end if;
            Rvk_[rowKey] := Rvk_[rowKey] union {rawData[i,22] * Unit('kN')};

        end if;
    end do:

    # 5. Serialize processing layout maps directly into high-performance plain code lines (%a)
    outputFilename := "Timber/Data_NODETimberToothedPlateConnectors.mm";
    outputFile := FileTools[Text][Open](outputFilename, create=true, overwrite=true);

    FileTools[Text][WriteString](outputFile, sprintf("metadata := %a:\n", eval(metadata)));
    FileTools[Text][WriteString](outputFile, sprintf("sides_ := %a:\n", eval(sides_set)));
    FileTools[Text][WriteString](outputFile, sprintf("type_ := %a:\n", eval(type_set)));
    FileTools[Text][WriteString](outputFile, sprintf("dc_ := %a:\n", eval(dc_set)));
    FileTools[Text][WriteString](outputFile, sprintf("producer_ := %a:\n", eval(producer_)));
    FileTools[Text][WriteString](outputFile, sprintf("information_ := %a:\n", eval(information_)));
    FileTools[Text][WriteString](outputFile, sprintf("serviceclass_ := %a:\n", eval(serviceclass_)));
    FileTools[Text][WriteString](outputFile, sprintf("d1_ := %a:\n", eval(d1_)));
    FileTools[Text][WriteString](outputFile, sprintf("h1_ := %a:\n", eval(h1_)));
    FileTools[Text][WriteString](outputFile, sprintf("hc_ := %a:\n", eval(hc_)));
    FileTools[Text][WriteString](outputFile, sprintf("t_ := %a:\n", eval(t_)));
    FileTools[Text][WriteString](outputFile, sprintf("d2_ := %a:\n", eval(d2_)));
    FileTools[Text][WriteString](outputFile, sprintf("la1_ := %a:\n", eval(la1_)));
    FileTools[Text][WriteString](outputFile, sprintf("la2_ := %a:\n", eval(la2_)));
    FileTools[Text][WriteString](outputFile, sprintf("t1_ := %a:\n", eval(t1_)));
    FileTools[Text][WriteString](outputFile, sprintf("t2_ := %a:\n", eval(t2_)));
    FileTools[Text][WriteString](outputFile, sprintf("a1_ := %a:\n", eval(a1_)));
    FileTools[Text][WriteString](outputFile, sprintf("a2_ := %a:\n", eval(a2_)));
    FileTools[Text][WriteString](outputFile, sprintf("a3t_ := %a:\n", eval(a3t_)));
    FileTools[Text][WriteString](outputFile, sprintf("a3c_ := %a:\n", eval(a3c_)));
    FileTools[Text][WriteString](outputFile, sprintf("a4t_ := %a:\n", eval(a4t_)));
    FileTools[Text][WriteString](outputFile, sprintf("a4c_ := %a:\n", eval(a4c_)));
    FileTools[Text][WriteString](outputFile, sprintf("Rvk_ := %a:\n", eval(Rvk_)));

    FileTools[Text][Close](outputFile);

end proc():