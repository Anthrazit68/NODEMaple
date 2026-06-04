# NODEConcreteEN1992.mm
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

NODEConcreteEN1992 := module()
    description "Dimensioning of concrete structures according to EN1992-1-1";
    option package;
    uses Units[Simple], NODEFunctions;
	
    export rebarDiameters, strengthclassExists, GetMaterialdata, checkCompliance, SetComboBoxMaterial;

    rebarDiameters := proc()::list;
        description "List of valid reinforcement diameters";
        return [8, 10, 12, 16, 20, 25, 32] *~ Unit('mm');
    end proc:

    strengthclassExists := proc(FK::{name,string})
        uses NODEConcreteMaterial;
        description "Check if strengthclass exists";
        try
            Property(FK, "f_ck");
            return true;
        catch:
            return false;
        end try;
    end proc:

    GetMaterialdata := proc(material::string, WhateverYouNeed::table)
        uses NODEConcreteMaterial, DocumentTools, StringTools;
        description "Get materialvalues for predefined material using Eurocode 2 formulas";
        
        local strengthclass, strengthclass_CEN, exposureclass, durabilityclass, parts;
        local materialdata, f_ck, f_ckcube, f_cm, f_ctm, f_ctk005, f_ctk095, E_cm;
        local epsilon_c1, epsilon_cu1, epsilon_c2, epsilon_cu2, n, epsilon_c3, epsilon_cu3;
        local gamma_C, alpha_cc, alpha_ct, f_cd, f_ctd, E_s, f_yk, gamma_s, f_yd, warnings;

        warnings := WhateverYouNeed["warnings"];
		
        # Secure splitting using RegSplit to safely handle names like "C20/25"
        # e.g., "B35 / XC3 / M60" splits into exactly 3 clean trimmed parts
        parts := map(StringTools:-Trim, StringTools:-RegSplit(" +/ +", material));
        
        if numelems(parts) < 3 then
            error("Invalid concrete material string format. Expected 'Strength / Exposure / Durability'. Received: %1", material);
        end if;

        strengthclass   := parts[1];
        exposureclass   := parts[2];
        durabilityclass := parts[3];
        
        strengthclass_CEN := Property(strengthclass, "strengthclass_CEN");

        # 1. Fetch the raw characteristic values from the data file
        f_ck     := eval(Property(strengthclass, "f_ck"));
        f_ckcube := eval(Property(strengthclass, "f_ck,cube"));

        # 2. Compute mean compressive strength (f_cm)
        f_cm := f_ck + 8 * Unit('MPa');
        
        # 3. Compute mean tensile strength (f_ctm) depending on strength class
        if f_ck / Unit('MPa') > 50 then
            f_ctm := evalf(2.12 * ln(1 + (f_cm / Unit('MPa') / 10))) * Unit('MPa');
        else
            # For normal strength concrete, try to fetch f_ctm from table first, fallback to formula if NULL
            try
                f_ctm := eval(Property(strengthclass, "f_ctm"));
                if f_ctm = NULL then raise; end if;
            catch:
                f_ctm := evalf(0.30 * (f_ck / Unit('MPa'))^(2/3)) * Unit('MPa');
            end try;
        end if;
        
        # 4. Compute characteristic tensile strengths
        f_ctk005 := 0.7 * f_ctm;
        f_ctk095 := 1.3 * f_ctm;
        
        # 5. Compute Modulus of Elasticity (E_cm)
        E_cm := (22 * (f_cm / Unit('MPa') / 10)^0.3) * Unit('GPa');
        
        # 6. Compute non-linear strain parameters according to EN 1992-1-1 Table 3.1
        epsilon_c1 := min(0.7 * ((f_cm / Unit('MPa'))^0.31) / 1000, 2.8 / 1000);
        
        if f_ck / Unit('MPa') <= 50 then
            epsilon_cu1 := 3.5 / 1000;
            epsilon_c2  := 2.0 / 1000;
            epsilon_cu2 := 3.5 / 1000;
            n           := 2.0;
            epsilon_c3  := 1.75 / 1000;
            epsilon_cu3 := 3.5 / 1000;
        else
            epsilon_cu1 := (2.8 + 27 * ((98 - f_cm / Unit('MPa')) / 100)^4) / 1000;
            epsilon_c2  := (2.0 + 0.0085 * (f_ck / Unit('MPa') - 50)^0.53) / 1000;
            epsilon_cu2 := (2.6 + 35 * ((90 - f_ck / Unit('MPa')) / 100)^4) / 1000;
            n           := 1.4 + 23.4 * ((90 - f_ck / Unit('MPa')) / 100)^4;
            epsilon_c3  := (1.75 + 0.55 * (f_ck / Unit('MPa') - 50) / 40) / 1000;
            epsilon_cu3 := (2.6 + 35 * ((90 - f_ck / Unit('MPa')) / 100)^4) / 1000;
        end if;
        
        gamma_C  := 1.5;
        alpha_cc := 0.85;
        alpha_ct := 0.85;

        # Design values for concrete
        f_cd  := alpha_cc * f_ck / gamma_C;
        f_ctd := alpha_ct * f_ctk005 / gamma_C;

        # Populate materialdata table
        materialdata := table();
        materialdata["material"]          := "concrete";
        materialdata["name"]              := material;
        materialdata["strengthclass_NS"]  := strengthclass;
        materialdata["strengthclass_CEN"] := strengthclass_CEN;
        materialdata["exposureclass"]     := exposureclass;
        materialdata["durabilityclass"]   := durabilityclass;
        materialdata["gamma_C"]           := gamma_C;
        materialdata["f_ck"]              := f_ck;
        materialdata["f_ckcube"]          := f_ckcube;
        materialdata["f_cm"]              := f_cm;
        materialdata["f_ctm"]             := f_ctm;
        materialdata["f_ctk005"]          := f_ctk005;
        materialdata["f_ctk095"]          := f_ctk095;
        materialdata["E_cm"]              := E_cm;
        materialdata["epsilon_c1"]        := epsilon_c1;
        materialdata["epsilon_cu1"]       := epsilon_cu1;
        materialdata["epsilon_c2"]        := epsilon_c2;
        materialdata["epsilon_cu2"]       := epsilon_cu2;
        materialdata["n"]                 := n;
        materialdata["epsilon_c3"]        := epsilon_c3;
        materialdata["epsilon_cu3"]       := epsilon_cu3;
        materialdata["alpha_cc"]          := alpha_cc;
        materialdata["alpha_ct"]          := alpha_ct;
        materialdata["f_cd"]              := f_cd;
        materialdata["f_ctd"]             := f_ctd;

        # Reinforcement steel parameters (B500NC)
        E_s     := 200000 * Unit('MPa');
        f_yk    := 500 * Unit('MPa');
        gamma_s := 1.15;
        f_yd    := f_yk / gamma_s;
		
        materialdata["name_steel"] := "B500NC";
        materialdata["E_s"]        := E_s;
        materialdata["f_yk"]       := f_yk;
        materialdata["gamma_s"]    := gamma_s;
        materialdata["f_yd"]       := f_yd;

        checkCompliance(materialdata, warnings);
        WhateverYouNeed["materialdata"] := materialdata;

    end proc:

    checkCompliance := proc(materialdata::table, warnings::table)
        description "Check compliance between strength class, exposure class and durability class";
        uses NODEFunctions;

        if materialdata["exposureclass"] = "X0" then
            if not evalb(materialdata["durabilityclass"] in ["M90", "M60", "M45", "MF45", "M40", "MF40", "-"]) then
                Alert(cat("Exposure class ", materialdata["exposureclass"], " not in compliance with durability class ", materialdata["durabilityclass"]), warnings, 3)
            end if
        elif evalb(materialdata["exposureclass"] in ["XC1", "XC2", "XC3", "XC4", "XF1"]) then
            if not evalb(materialdata["durabilityclass"] in ["M60", "M45", "MF45", "M40", "MF40", "-"]) then
                Alert(cat("Exposure class ", materialdata["exposureclass"], " not in compliance with durability class ", materialdata["durabilityclass"]), warnings, 3)
            end if
        elif evalb(materialdata["exposureclass"] in ["XA1", "XA2", "XA4", "XD1", "XS1"]) then
            if not evalb(materialdata["durabilityclass"] in ["M45", "MF45", "M40", "MF40", "-"]) then
                Alert(cat("Exposure class ", materialdata["exposureclass"], " not in compliance with durability class ", materialdata["durabilityclass"]), warnings, 3)
            end if
        elif evalb(materialdata["exposureclass"] in ["XF2", "XF3", "XF4"]) then
            if not evalb(materialdata["durabilityclass"] in ["MF45", "MF40", "-"]) then
                Alert(cat("Exposure class ", materialdata["exposureclass"], " not in compliance with durability class ", materialdata["durabilityclass"]), warnings, 3)
            end if
        elif evalb(materialdata["exposureclass"] in ["XD2", "XD3", "XS2", "XS3", "XA3"]) then
            if not evalb(materialdata["durabilityclass"] in ["MF45", "MF40", "-"]) then
                Alert(cat("Exposure class ", materialdata["exposureclass"], " not in compliance with durability class ", materialdata["durabilityclass"]), warnings, 3)
            end if
        end if;

        if materialdata["durabilityclass"] = "M90" then
            if materialdata["f_ck"] < 20*Unit('N/mm^2') then
                Alert("Check NA.E.1N failed, strength class minimum B20 (C20/25) for durability class M90", warnings, 3)
            end if
        elif materialdata["durabilityclass"] = "M60" then
            if materialdata["f_ck"] < 25*Unit('N/mm^2') then
                Alert("Check NA.E.1N failed, strength class minimum B25 (C25/30) for durability class M60", warnings, 3)
            end if
        elif evalb(materialdata["durabilityclass"] in ["M45", "MF45"]) then
            if materialdata["f_ck"] < 35*Unit('N/mm^2') then
                Alert("Check NA.E.1N failed, strength class minimum B35 (C35/45) for durability class M(F)45", warnings, 3)
            end if
        elif evalb(materialdata["durabilityclass"] in ["M40", "MF40"]) then
            if materialdata["f_ck"] < 40*Unit('N/mm^2') then
                Alert("Check NA.E.1N failed, strength class minimum B40 (C40/50) for durability class M(F)40", warnings, 3)
            end if
        end if;		
    end proc:

    SetComboBoxMaterial := proc(WhateverYouNeed::table)
        uses DocumentTools, NODEFunctions;
        description "Set material combobox according to chosen material";
        local ind, val, foundit, warnings, materialdata;
        local strengthclass, exposureclass, durabilityclass;

        warnings        := WhateverYouNeed["warnings"];
        materialdata    := WhateverYouNeed["materialdata"];
        strengthclass   := eval(materialdata["strengthclass_NS"]);
        exposureclass   := eval(materialdata["exposureclass"]);
        durabilityclass := eval(materialdata["durabilityclass"]);	

        if ComponentExists("ComboBox_strengthclass") then
            if strengthclass <> GetProperty("ComboBox_strengthclass", value) then
                foundit := false;
                if strengthclass = "" then
                    SetProperty("ComboBox_strengthclass", 'selectedindex', 0);
                    strengthclass := GetProperty("ComboBox_strengthclass", value);
                else
                    for ind, val in GetProperty("ComboBox_strengthclass", 'itemList') do
                        if val = strengthclass then
                            foundit := true;
                            SetProperty("ComboBox_strengthclass", 'selectedindex', ind-1);
                        end if;
					end do;
                    if not foundit then
                        Alert("Invalid strengthclass", warnings, 5);
                    end if;
                end if;
            end if;
        end if;

        if ComponentExists("ComboBox_exposureclass") then
            if exposureclass <> GetProperty("ComboBox_exposureclass", value) then
                foundit := false;
                for ind, val in GetProperty("ComboBox_exposureclass", itemList) do
                    if val = exposureclass then
                        foundit := true;
                        SetProperty("ComboBox_exposureclass", selectedindex, ind-1);
                    end if;
                end do;
                if not foundit then
                    Alert("Invalid exposureclass", warnings, 5);
                end if;
            end if;
        end if;

        if ComponentExists("ComboBox_durabilityclass") then
            if durabilityclass <> GetProperty("ComboBox_durabilityclass", value) then
                foundit := false;
                for ind, val in GetProperty("ComboBox_durabilityclass", itemList) do
                    if val = durabilityclass then
                        foundit := true;
                        SetProperty("ComboBox_durabilityclass", selectedindex, ind-1);
                    end if;
                end do;
                if not foundit then
                    Alert("Invalid durabilityclass", warnings, 5);
                end if;
            end if;
        end if;
		
    end proc:

end module: