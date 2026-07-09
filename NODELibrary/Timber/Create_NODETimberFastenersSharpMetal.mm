# Create_NODETimberFastenersSharpMetal.mm : process Rothoblaas Sharp Metal connectors
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
          fm_withscrew, prod, bet, descr, fm_serviceclass, fm_width,
          fm_fv0k, fm_fv90k, fm_fvEGk, fm_kser0k, fm_kser90k, fm_kserEGk;
    uses ExcelTools, ListTools, NODEFunctions;

    # 1. Import raw matrix from Excel (Columns A to L, starting from row 2 to skip headers)
    rawData := convert(ExcelTools:-Import("Data/TimberFasteners.xlsx", "Rothoblaas Sharp Metal", "A2:L"), Matrix):
    rawData := subs("&ndash;" = NULL, rawData):

    # 2. Metadata describing columns, units, and engineering properties
    metadata := [ 
         [A, "prod", 1, "Producer"]
        ,[B, "bet", 1, "Designation / Product name"]
        ,[C, "descr", 1, "Detailed description"]
        ,[D, "fm_serviceclass", 1, "Service class limitation"]
        ,[E, "fm_width", (mm), "Width of sharp metal plate"]
        ,[F, "fm_withscrew", 1, "Connection reinforced with screw"]
        ,[G, "f_v_0_k", (N/mm^2), "Shear strength parallel to grain"]
        ,[H, "f_v_90_k", (N/mm^2), "Shear strength normal to grain"]
        ,[I, "f_v_EG_k", (N/mm^2), "Shear strength at end-grain edge"]
        ,[J, "k_ser_0_k", (N/mm^3), "Slip modulus / Deformation factor parallel"]
        ,[K, "k_ser_90_k", (N/mm^3), "Slip modulus / Deformation factor normal"]
        ,[L, "k_ser_EG_k", (N/mm^3), "Slip modulus / Deformation factor edge"]
    ]:

    # 3. Initialize lookup tables and index matching sets
    fm_withscrew := {};
    prod := table();
    bet := table();
    descr := table();
    fm_serviceclass := table();
    fm_width := table();
    fm_fv0k := table();
    fm_fv90k := table();
    fm_fvEGk := table();
    fm_kser0k := table();
    fm_kser90k := table();
    fm_kserEGk := table();

    # 4. Map rows and collect engineering parameters via direct structural indexing
    for i from 1 to numelems(rawData[..,1]) do
        # Prevent executing blank spacing entries at the bottom of the worksheet
        if rawData[i,1] <> NULL and rawData[i,1] <> "" then
            
            # Identify core validation variables
            fm_withscrew := fm_withscrew union {rawData[i,6]};

            # Hierarchy 1: Connection Type (with/without screw) -> Producer
            if not assigned(prod[rawData[i,6]]) then prod[rawData[i,6]] := {}; end if;
            prod[rawData[i,6]] := prod[rawData[i,6]] union {rawData[i,1]};

            # Hierarchy 2: Connection Type -> Producer -> Designation
            if not assigned(bet[rawData[i,6], rawData[i,1]]) then bet[rawData[i,6], rawData[i,1]] := {}; end if;
            bet[rawData[i,6], rawData[i,1]] := bet[rawData[i,6], rawData[i,1]] union {rawData[i,2]};

            # Properties Matrix indexed uniformly by: [WithScrew, Producer, Designation]
            rowKey := rawData[i,6], rawData[i,1], rawData[i,2];

            if not assigned(descr[rowKey]) then descr[rowKey] := {}; end if;
            descr[rowKey] := descr[rowKey] union {rawData[i,3]};

            if not assigned(fm_serviceclass[rowKey]) then fm_serviceclass[rowKey] := {}; end if;
            fm_serviceclass[rowKey] := fm_serviceclass[rowKey] union {rawData[i,4]};

            if not assigned(fm_width[rowKey]) then fm_width[rowKey] := {}; end if;
            fm_width[rowKey] := fm_width[rowKey] union {rawData[i,5] * Unit('mm')};

            if not assigned(fm_fv0k[rowKey]) then fm_fv0k[rowKey] := {}; end if;
            fm_fv0k[rowKey] := fm_fv0k[rowKey] union {rawData[i,7] * Unit('N/mm^2')};

            if not assigned(fm_fv90k[rowKey]) then fm_fv90k[rowKey] := {}; end if;
            fm_fv90k[rowKey] := fm_fv90k[rowKey] union {rawData[i,8] * Unit('N/mm^2')};

            if not assigned(fm_fvEGk[rowKey]) then fm_fvEGk[rowKey] := {}; end if;
            fm_fvEGk[rowKey] := fm_fvEGk[rowKey] union {rawData[i,9] * Unit('N/mm^2')};

            if not assigned(fm_kser0k[rowKey]) then fm_kser0k[rowKey] := {}; end if;
            fm_kser0k[rowKey] := fm_kser0k[rowKey] union {rawData[i,10] * Unit('N/mm^3')};

            if not assigned(fm_kser90k[rowKey]) then fm_kser90k[rowKey] := {}; end if;
            fm_kser90k[rowKey] := fm_kser90k[rowKey] union {rawData[i,11] * Unit('N/mm^3')};

            if not assigned(fm_kserEGk[rowKey]) then fm_kserEGk[rowKey] := {}; end if;
            fm_kserEGk[rowKey] := fm_kserEGk[rowKey] union {rawData[i,12] * Unit('N/mm^3')};

        end if;
    end do:

    # 5. Serialization and safe file compilation
    outputFilename := "Timber/Data_NODETimberFastenersSharpMetal.mm";
    outputFile := FileTools[Text][Open](outputFilename, create=true, overwrite=true);

    FileTools[Text][WriteString](outputFile, sprintf("metadata := %a:\n", eval(metadata)));
    FileTools[Text][WriteString](outputFile, sprintf("fm_withscrew := %a:\n", eval(fm_withscrew)));
    FileTools[Text][WriteString](outputFile, sprintf("prod := %a:\n", eval(prod)));
    FileTools[Text][WriteString](outputFile, sprintf("bet := %a:\n", eval(bet)));
    FileTools[Text][WriteString](outputFile, sprintf("descr := %a:\n", eval(descr)));
    FileTools[Text][WriteString](outputFile, sprintf("fm_serviceclass := %a:\n", eval(fm_serviceclass)));
    FileTools[Text][WriteString](outputFile, sprintf("fm_width := %a:\n", eval(fm_width)));
    FileTools[Text][WriteString](outputFile, sprintf("fm_fv0k := %a:\n", eval(fm_fv0k)));
    FileTools[Text][WriteString](outputFile, sprintf("fm_fv90k := %a:\n", eval(fm_fv90k)));
    FileTools[Text][WriteString](outputFile, sprintf("fm_fvEGk := %a:\n", eval(fm_fvEGk)));
    FileTools[Text][WriteString](outputFile, sprintf("fm_kser0k := %a:\n", eval(fm_kser0k)));
    FileTools[Text][WriteString](outputFile, sprintf("fm_kser90k := %a:\n", eval(fm_kser90k)));
    FileTools[Text][WriteString](outputFile, sprintf("fm_kserEGk := %a:\n", eval(fm_kserEGk)));

    FileTools[Text][Close](outputFile);

end proc():