# Create_NODETimberFasteners.mm : create timber fastener database
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
    local rawData, metadata, i, j, outputFile, outputFilename, rowKey,
          fm_set, fm_d, prod, bet, fm_producers, producers_connectionstypes,
          fm_descr, fm_serviceclass, prod_con_dia, fm_l, fm_MyRk, fm_faxk, 
          fm_fheadk, fm_ftensk, fm_dh, fm_l1, fm_l2, fm_fuk, fm_Bmax;
    uses ExcelTools, ListTools, NODEFunctions;

    # 1. Import raw data from Excel (Columns A to P, starting from row 2 to skip headers)
    rawData := convert(ExcelTools:-Import("Data/TimberFasteners.xlsx", "TimberFasteners", "A2:P"), Matrix):
    rawData := subs("&ndash;" = NULL, rawData):

    # 2. Metadata describing columns, units, and descriptions
    metadata := [ 
         [A, "fm", 1, "Fastener type (Nail, bolt, screw, or dowel)"]
        ,[B, "prod", 1, "Producer"]
        ,[C, "bet", 1, "Designation / Product name"]
        ,[D, "descr", 1, "Detailed information / Description"]
        ,[E, "serviceclass", 1, "Highest service class"]
        ,[F, "d", (mm), "Diameter"]
        ,[G, "l", (mm), "Length"]
        ,[H, "dh", (mm), "Head diameter"]
        ,[I, "M_y_Rk", (N*m), "Yield moment (My,Rk)"]
        ,[J, "f_ax_k", (N/mm^2), "Withdrawal parameter (fax,k)"]
        ,[K, "f_head_k", (N/mm^2), "Head pull-through parameter (fhead,k)"]
        ,[L, "f_tens_k", (kN), "Tensile capacity (ftens,k)"]
        ,[M, "l1", (mm), "Threaded length from tip"]
        ,[N, "l3", (mm), "Threaded length from head"] # Map column N matching 'l3' in Excel sheet
        ,[O, "f_uk", (N/mm^2), "Ultimate tensile strength of wire (f,uk)"]
        ,[P, "B_max", (mm), "Maximum thickness (B max)"]
    ]:

    # 3. Initialize database tables and sets
    fm_set := {};
    fm_d := table();
    prod := table();
    bet := table();
    fm_producers := {};
    producers_connectionstypes := table();
    fm_descr := table();
    fm_serviceclass := table();
    prod_con_dia := table();
    fm_l := table();
    fm_MyRk := table();
    fm_faxk := table();
    fm_fheadk := table();
    fm_ftensk := table();
    fm_dh := table();
    fm_l1 := table();
    fm_l2 := table(); # Kept variable name for backwards compatibility
    fm_fuk := table();
    fm_Bmax := table();

    # 4. Process the data matrix and build relation mappings
    for i from 1 to numelems(rawData[..,1]) do
        # Skip potential empty rows at the bottom of the Excel sheet
        if rawData[i,1] <> NULL and rawData[i,1] <> "" then
            
            # Populate unique sets for fasteners and producers
            fm_set := fm_set union {rawData[i,1]};
            fm_producers := fm_producers union {rawData[i,2]};

            # Indexing Hierarchy 1: Fastener Type -> Diameter -> Producer -> Designation
            if not assigned(fm_d[rawData[i,1]]) then fm_d[rawData[i,1]] := {}; end if;
            fm_d[rawData[i,1]] := fm_d[rawData[i,1]] union {rawData[i,6] * Unit('mm')};

            if not assigned(prod[rawData[i,1], rawData[i,6]]) then prod[rawData[i,1], rawData[i,6]] := {}; end if;
            prod[rawData[i,1], rawData[i,6]] := prod[rawData[i,1], rawData[i,6]] union {rawData[i,2]};

            if not assigned(bet[rawData[i,1], rawData[i,6], rawData[i,2]]) then bet[rawData[i,1], rawData[i,6], rawData[i,2]] := {}; end if;
            bet[rawData[i,1], rawData[i,6], rawData[i,2]] := bet[rawData[i,1], rawData[i,6], rawData[i,2]] union {rawData[i,3]};

            # Indexing Hierarchy 2: Producer -> Designation
            if not assigned(producers_connectionstypes[rawData[i,2]]) then producers_connectionstypes[rawData[i,2]] := {}; end if;
            producers_connectionstypes[rawData[i,2]] := producers_connectionstypes[rawData[i,2]] union {rawData[i,3]};

            # Map text descriptions and classifications per Producer/Designation
            if not assigned(fm_descr[rawData[i,2], rawData[i,3]]) then fm_descr[rawData[i,2], rawData[i,3]] := {}; end if;
            fm_descr[rawData[i,2], rawData[i,3]] := fm_descr[rawData[i,2], rawData[i,3]] union {rawData[i,4]};

            if not assigned(fm_serviceclass[rawData[i,2], rawData[i,3]]) then fm_serviceclass[rawData[i,2], rawData[i,3]] := {}; end if;
            fm_serviceclass[rawData[i,2], rawData[i,3]] := fm_serviceclass[rawData[i,2], rawData[i,3]] union {rawData[i,5]};

            if not assigned(prod_con_dia[rawData[i,2], rawData[i,3]]) then prod_con_dia[rawData[i,2], rawData[i,3]] := {}; end if;
            prod_con_dia[rawData[i,2], rawData[i,3]] := prod_con_dia[rawData[i,2], rawData[i,3]] union {rawData[i,6] * Unit('mm')};

            # Map mechanical properties tables indexed by (Producer, Designation, Diameter)
            if not assigned(fm_l[rawData[i,2], rawData[i,3], rawData[i,6]]) then fm_l[rawData[i,2], rawData[i,3], rawData[i,6]] := {}; end if;
            fm_l[rawData[i,2], rawData[i,3], rawData[i,6]] := fm_l[rawData[i,2], rawData[i,3], rawData[i,6]] union {rawData[i,7] * Unit('mm')};

            if not assigned(fm_MyRk[rawData[i,2], rawData[i,3], rawData[i,6]]) then fm_MyRk[rawData[i,2], rawData[i,3], rawData[i,6]] := {}; end if;
            fm_MyRk[rawData[i,2], rawData[i,3], rawData[i,6]] := fm_MyRk[rawData[i,2], rawData[i,3], rawData[i,6]] union {rawData[i,9] * Unit('N*m')};

            if not assigned(fm_faxk[rawData[i,2], rawData[i,3], rawData[i,6]]) then fm_faxk[rawData[i,2], rawData[i,3], rawData[i,6]] := {}; end if;
            fm_faxk[rawData[i,2], rawData[i,3], rawData[i,6]] := fm_faxk[rawData[i,2], rawData[i,3], rawData[i,6]] union {rawData[i,10] * Unit('N/mm^2')};

            if not assigned(fm_fheadk[rawData[i,2], rawData[i,3], rawData[i,6]]) then fm_fheadk[rawData[i,2], rawData[i,3], rawData[i,6]] := {}; end if;
            fm_fheadk[rawData[i,2], rawData[i,3], rawData[i,6]] := fm_fheadk[rawData[i,2], rawData[i,3], rawData[i,6]] union {rawData[i,11] * Unit('N/mm^2')};

            if not assigned(fm_ftensk[rawData[i,2], rawData[i,3], rawData[i,6]]) then fm_ftensk[rawData[i,2], rawData[i,3], rawData[i,6]] := {}; end if;
            fm_ftensk[rawData[i,2], rawData[i,3], rawData[i,6]] := fm_ftensk[rawData[i,2], rawData[i,3], rawData[i,6]] union {rawData[i,12] * Unit('kN')};

            # Map length-dependent dimension tables indexed by (Producer, Designation, Diameter, Length)
            rowKey := rawData[i,2], rawData[i,3], rawData[i,6], round(rawData[i,7]);

            if not assigned(fm_dh[rowKey]) then fm_dh[rowKey] := {}; end if;
            fm_dh[rowKey] := fm_dh[rowKey] union {rawData[i,8] * Unit('mm')};

            if not assigned(fm_l1[rowKey]) then fm_l1[rowKey] := {}; end if;
            fm_l1[rowKey] := fm_l1[rowKey] union {`if`(rawData[i,13]<>NULL, rawData[i,13]*Unit('mm'), 0*Unit('mm'))};

            if not assigned(fm_l2[rowKey]) then fm_l2[rowKey] := {}; end if;
            fm_l2[rowKey] := fm_l2[rowKey] union {`if`(rawData[i,14]<>NULL, rawData[i,14]*Unit('mm'), 0*Unit('mm'))};

            if not assigned(fm_fuk[rowKey]) then fm_fuk[rowKey] := {}; end if;
            fm_fuk[rowKey] := fm_fuk[rowKey] union {`if`(rawData[i,15]<>NULL, rawData[i,15]*Unit('N/mm^2'), 0*Unit('N/mm^2'))};

            if not assigned(fm_Bmax[rowKey]) then fm_Bmax[rowKey] := {}; end if;
            fm_Bmax[rowKey] := fm_Bmax[rowKey] union {`if`(rawData[i,16]<>NULL, rawData[i,16]*Unit('mm'), 0*Unit('mm'))};

        end if;
    end do:

    # 5. Export processed datasets into a clean file using raw Maple format (%a)
    outputFilename := "Timber/Data_NODETimberFasteners.mm";
    outputFile := FileTools[Text][Open](outputFilename, create=true, overwrite=true);

    FileTools[Text][WriteString](outputFile, sprintf("metadata := %a:\n", eval(metadata)));
    FileTools[Text][WriteString](outputFile, sprintf("fm := %a:\n", eval(fm_set)));
    FileTools[Text][WriteString](outputFile, sprintf("fm_d := %a:\n", eval(fm_d)));
    FileTools[Text][WriteString](outputFile, sprintf("prod := %a:\n", eval(prod)));
    FileTools[Text][WriteString](outputFile, sprintf("bet := %a:\n", eval(bet)));
    FileTools[Text][WriteString](outputFile, sprintf("fm_producers := %a:\n", eval(fm_producers)));
    FileTools[Text][WriteString](outputFile, sprintf("producers_connectionstypes := %a:\n", eval(producers_connectionstypes)));
    FileTools[Text][WriteString](outputFile, sprintf("fm_descr := %a:\n", eval(fm_descr)));
    FileTools[Text][WriteString](outputFile, sprintf("fm_serviceclass := %a:\n", eval(fm_serviceclass)));
    FileTools[Text][WriteString](outputFile, sprintf("prod_con_dia := %a:\n", eval(prod_con_dia)));
    FileTools[Text][WriteString](outputFile, sprintf("fm_l := %a:\n", eval(fm_l)));
    FileTools[Text][WriteString](outputFile, sprintf("fm_MyRk := %a:\n", eval(fm_MyRk)));
    FileTools[Text][WriteString](outputFile, sprintf("fm_faxk := %a:\n", eval(fm_faxk)));
    FileTools[Text][WriteString](outputFile, sprintf("fm_fheadk := %a:\n", eval(fm_fheadk)));
    FileTools[Text][WriteString](outputFile, sprintf("fm_ftensk := %a:\n", eval(fm_ftensk)));
    FileTools[Text][WriteString](outputFile, sprintf("fm_dh := %a:\n", eval(fm_dh)));
    FileTools[Text][WriteString](outputFile, sprintf("fm_l1 := %a:\n", eval(fm_l1)));
    FileTools[Text][WriteString](outputFile, sprintf("fm_l2 := %a:\n", eval(fm_l2)));
    FileTools[Text][WriteString](outputFile, sprintf("fm_fuk := %a:\n", eval(fm_fuk)));
    FileTools[Text][WriteString](outputFile, sprintf("fm_Bmax := %a:\n", eval(fm_Bmax)));

    FileTools[Text][Close](outputFile);

end proc():