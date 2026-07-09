# NODETimberGUI.mm : initialization and graphical routines for Maple timber worksheets
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

# NODETimber - EC5_6 : Eurocode 5, chapter 6 main routines
# Copyright (C) 2024  Andreas Zieritz

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# InitSpecific
# ResetSpecific
# MainWrapper
# ReadComponentsSpecific
# Main
# activateComponents_64

NODETimberGUI := module()

    description "Module for workbook initialization and GUI handlers":
    option package;
    
    global WhateverYouNeed; 
    export runAfterXMLImportLocal, activateComponents_64, InitSpecific_EC5_6, Main_EC5_6, ReadComponentsSpecific_EC5_6, ResetSpecific_EC5_6, RunAfterRestoresettings_EC5_6,
            InitSpecific_EC5_8, Main_EC5_8, ReadComponentsSpecific_EC5_8, ResetSpecific_EC5_8, RunAfterRestoresettings_EC5_8,
            InitSpecific_Opening, Main_Opening, ReadComponentsSpecific_Opening, ResetSpecific_Opening, RunAfterRestoresettings_Opening;
    uses DocumentTools, NODEFunctions, NODETimberEN1995, NODEDocumentCommon;

    runAfterXMLImportLocal := proc(i::string)
        description "Procedure run after import of XML file, called in NODEXML:-runAfterXMLImport";
        local warnings, dummy;

        warnings := WhateverYouNeed["warnings"];

        if substring(i, 1) = "-" then		# now is the time to go through all values
            dummy := substring(i, 2..)
        else
            dummy := i
        end if;

        if dummy = "fastener" then
            SetComboFastenersAfterXMLImport(WhateverYouNeed);		# EC5_8_SetVisibilityCombobox
            
        elif dummy = "connection" then
            SetComboConnectionAfterXMLImport(WhateverYouNeed)		# EC5_8_SetVisibilityCombobox
                    
        else
            Alert(cat("runAfterXMLImportLocal: unhandled command ", dummy), warnings, 2);
        end if;
    end proc:

    # EC5_6

    # this one is initiated by ComboBox_ConstructionType
    activateComponents_64 := proc()
        description "Activate / deactivate components for section 6.4";

        if GetProperty("ComboBox_ConstructionType", 'selectedindex') = 0  then 			# -
            SetProperty("TextArea_alpha_ap", 'enabled', "false");
            SetProperty("ComboBox_tapered_N", 'enabled', "false");
            SetProperty("TextArea_r_in", 'enabled', "false");
            SetProperty("TextArea_l_curve", 'enabled', "false");
            SetProperty("TextArea_t_lam", 'enabled', "false");

        elif GetProperty("ComboBox_ConstructionType", 'selectedindex') = 1 then			# Single tapered beam
            SetProperty("TextArea_alpha_ap", 'enabled', "true");
            SetProperty("ComboBox_tapered_N", 'enabled', "true");
            SetProperty("TextArea_r_in", 'enabled', "false");
            SetProperty("TextArea_l_curve", 'enabled', "false");
            SetProperty("TextArea_t_lam", 'enabled', "false");

        elif GetProperty("ComboBox_ConstructionType", 'selectedindex') = 2 then			# Double tapered beam
            SetProperty("TextArea_alpha_ap", 'enabled', "true");
            SetProperty("ComboBox_tapered_N", 'enabled', "false");
            SetProperty("TextArea_r_in", 'enabled', "false");
            SetProperty("TextArea_l_curve", 'enabled', "false");
            SetProperty("TextArea_t_lam", 'enabled', "false");

        elif GetProperty("ComboBox_ConstructionType", 'selectedindex') = 3 then			# Curved beam
            SetProperty("TextArea_alpha_ap", 'enabled', "false");
            SetProperty("ComboBox_tapered_N", 'enabled', "false");
            SetProperty("TextArea_r_in", 'enabled', "true");
            SetProperty("TextArea_l_curve", 'enabled', "true");
            SetProperty("TextArea_t_lam", 'enabled', "true");

        elif GetProperty("ComboBox_ConstructionType", 'selectedindex') = 4 then			# Pitched cambered beam
            SetProperty("TextArea_alpha_ap", 'enabled', "true");
            SetProperty("ComboBox_tapered_N", 'enabled', "false");
            SetProperty("TextArea_r_in", 'enabled', "true");
            SetProperty("TextArea_l_curve", 'enabled', "true");
            SetProperty("TextArea_t_lam", 'enabled', "true");

        end if;
    end proc:


    InitSpecific_EC5_6 := proc()
        description "Specific initialization values";        
        local var_calculations, var_numeric, var_resultdetails, var_units;

        WhateverYouNeed["calculations"]["calculationtype_short"] := "Eurocode 5 part 1-1 ULS";		# for export to Excel        

        var_calculations := {"timbertype", "b", "h", "strengthclass", "serviceclass", "loaddurationclass", "l_ky", "l_kz", "l_efy", "l_efz",
                        "type_615", "a_615", "l_615", "l1_615", "h_622", "ConstructionType", "alpha_ap", "r_in", "l_curve", "t_lam", "tapered_N", "endnotched", "endnotchedType", "h_ef", "l_incl", "x_652"};

        # all variables starting with those values are numeric
        var_numeric := {"l_ky", "l_kz", "l_efy", "l_efz", "a_615", "l_615", "l1_615", "h_622", "alpha_ap", "r_in", "l_curve", "t_lam", "h_ef", "l_incl", "x_652"};

        var_units := WhateverYouNeed["componentvariables"]["var_units"];
        var_units["m"] := var_units["m"] union {"l_ky", "l_kz", "l_efy", "l_efz", "r_in", "l_curve"};
        var_units["mm"] := var_units["mm"] union {"a_615", "l_615", "l1_615", "h_622", "t_lam", "h_ef", "l_incl", "x_652"};		# b, h are not defined directly, but through section name [mm]
        var_units["arcdeg"] := var_units["arcdeg"] union {"alpha_ap"};

        # variables which are used for printing detailed results
        var_resultdetails := table();
        var_resultdetails["3.2"] := {"k_h", "k_hb"};
        var_resultdetails["6.1.2"] := {"eta612"};
        var_resultdetails["6.1.3"] := {"eta613"};
        var_resultdetails["6.1.4"] := {"eta614"};	
        var_resultdetails["6.1.5"] := {"k_c90", "f_c90d_mod", "NTI_f_c90d_mod", "Anet", "sigma_c90d", "NTI_sigma_c90d", "Aef", "eta615_EN", "eta615_NTI", "eta615"};
        var_resultdetails["6.1.7"] := {"kcr", "kn", "kv", "eta617"};
        var_resultdetails["6.1.8"] := {"tau_tord", "k_shape", "ksh_fvd", "eta618"};
        var_resultdetails["6.2.2"] := {"k_c90", "sigma_cad", "A_622", "f_cad", "eta622"};
        var_resultdetails["6.3"] := {"lambda_rely", "lambda_relz", "eta619", "eta623", "eta624", "k_crity", "k_critz", "eta616", "lambda_relmy", "lambda_relmz", "eta633", "k_cy", "k_cz"};
        # var_resultdetails["6.4"] := {"k_m_alpha", "k_p", "k_l", "k_dis", "k_r", "k_vol", "V"};
        var_resultdetails["6.4"] := {"eta643", "sigma_t90d_64", "tau_d_64" };

        WhateverYouNeed["componentvariables"]["var_calculations"] := WhateverYouNeed["componentvariables"]["var_calculations"] union var_calculations;
        WhateverYouNeed["componentvariables"]["var_numeric"] := eval(var_numeric);
        # WhateverYouNeed["componentvariables"]["var_calculationdata"] := eval(WhateverYouNeed["componentvariables"]["var_calculationdata"] union {"activematerial", "activesection"});
        # WhateverYouNeed["componentvariables"]["var_storeitems"] := eval(WhateverYouNeed["componentvariables"]["var_storeitems"] union {"calculations/activematerial", "calculations/activesection"});
        WhateverYouNeed["componentvariables"]["var_resultsdetails"] := eval(var_resultdetails);

    end proc:


    # Main calculation routine
    Main_EC5_6 := proc(action::string)
        description "Main calculation routine for EC5_6 calculations";        
        local force, activeloadcase, eta, usedcode, comments, structure, warnings, maxindex, usedcodeDescription;
        local alpha, F_xd, M_yd, M_zd, V_yd, V_zd, M_td;

        # declare local variables
        activeloadcase := WhateverYouNeed["calculations"]["activesettings"]["activeloadcase"];
        force := eval(WhateverYouNeed["calculations"]["loadcases"][activeloadcase]);
        structure := WhateverYouNeed["calculations"]["structure"];
        warnings := WhateverYouNeed["warnings"];

        # reset eta, usedcode, usedCodeDescription, comments
        eta := table();
        usedcode := table();
        usedcodeDescription := table();
        comments := table();
        
        WhateverYouNeed["results"]["eta"] := eta;
        WhateverYouNeed["results"]["usedcode"] := usedcode;
        WhateverYouNeed["results"]["usedcodeDescription"] := usedcodeDescription;
        WhateverYouNeed["results"]["comments"] := comments;

        if action = "CalculateAllLoadcases" or action = "calculateAllLoadcasesCleanup" then		# don't reset calculated values

            # updateComponents := false
            
        elif action = "calculation" or WhateverYouNeed["calculations"]["autocalc"] then
            
            # when running calculation of singular loadcase, global utilization values might not be correct anymore
            SetProperty("TextArea_etamax_max", 'enabled', "false");
            SetProperty("TextArea_loadcaseMax", 'enabled', "false");
            SetProperty("TextArea_warningsAll", 'enabled', "false");			
        
        else

            Alert(cat("Main: action ", action, " undefined"), warnings, 3);
            
        end if;

        # deactivate detail results
        if assigned(WhateverYouNeed["calculations"]["suppress_gui"]) then
            if WhateverYouNeed["calculations"]["suppress_gui"] = false then 
                HighlightResults(WhateverYouNeed["componentvariables"]["var_resultsdetails"], "deactivate");
            end if;
        else
            Alert("Undefined variable suppress_gui", warnings, 1);
            DEBUG();
        end if;

        # get force from loadcases[loadcase]
        alpha := evalf(force["alpha"]);
        F_xd := eval(force["F_xd"]);
        M_yd := eval(force["M_yd"]);
        M_zd := eval(force["M_zd"]);
        V_yd := eval(force["V_yd"]);
        V_zd := eval(force["V_zd"]);
        M_td := eval(force["M_td"]);

        eta["max"] := 0;

        # 1. calculation with defined alpha
        if alpha = 0 then
            if F_xd >= 0 and M_yd = 0 and M_zd = 0 then	# 6.1.2 tension parallel to the grain
                local eta612, usedcode612, usedcodeDescription612;                
                eta["612"], usedcode["612"], usedcodeDescription["612"] := EC5_612()
            end if;
                
            if F_xd <= 0 and M_yd = 0 and M_zd = 0 then	# 6.1.4 compression parallel to the grain
                # eta[1], usedcode[1] := EC5_614(A, f_c0d, force)
                eta["614"], usedcode["614"], usedcodeDescription["614"] := EC5_63()		# forward to buckling calculation
            end if;
                
            if F_xd >= 0 and (M_yd <> 0 or M_zd <> 0) then	# 6.2.3 combined bending and axial tension
                eta["623"], usedcode["623"], usedcodeDescription["623"] := EC5_623()
            end if;
            
            if F_xd <= 0 and (M_yd <> 0 or M_zd <> 0) then	# 6.2.4 combined bending and axial compression
                eta["624"], usedcode["624"], usedcodeDescription["624"] := EC5_63()		# forward to buckling and torsional buckling calculation
            end if;
        end if;
        
        if alpha = 90 * Unit('degrees') then
            if F_xd >= 0 and M_yd = 0 and M_zd = 0 then	# 6.1.3 tension perpendicular to the grain
                eta["613"], usedcode["613"], usedcodeDescription["613"] := EC5_613()
            end if;
            
            if F_xd <= 0 and M_yd = 0 and M_zd = 0 then	# 6.1.5 compression perpendicular to the grain
                eta["615"], usedcode["615"], usedcodeDescription["615"] := EC5_615()
            end if;
        end if;

        # 6.2.2 compression stresses at an angle to the grain
        if alpha > 0 and alpha < 90 * Unit('degrees') and F_xd <= 0 and M_yd = 0 and M_zd = 0 then	
            eta["622"], usedcode["622"], usedcodeDescription["622"] := EC5_622()
        end if;	

        # 2. alpha not relevant
        # 6.1.6 Bending
        if F_xd = 0 and (M_yd <> 0 or M_zd <> 0) then	            
            # forward to formula that also checks lateral and lateral torsional buckling
            # checking 6.1.6, 6.2.4 og (6.35)
            eta["616"], usedcode["616"], usedcodeDescription["616"] := EC5_63()
        end if;

        # 6.1.7 shear
        if V_yd <> 0 or V_zd <> 0 then	
            eta["617"], usedcode["617"], usedcodeDescription["617"] := EC5_617()
        end if;

        # 6.1.8 Torsjon
        if M_td <> 0 and M_yd = 0 and M_zd = 0 and F_xd = 0 then	
            eta["618"], usedcode["618"], usedcodeDescription["618"] := EC5_618()
        end if;

        # 3. check if there is a special construction
        if member(structure["code_64"]["ConstructionType"], {"Double tapered beam", "Curved beam", "Pitched cambered beam"}) then
            eta["643"], usedcode["643"], usedcodeDescription["643"] := EC5_643();	# check first 6.4.3, afterwards the usual formulas
        end if;
        
        eta["max"], maxindex := maxIndexTable(eta);
        comments["usedcode"] := eval(usedcode[maxindex]);		# results["usedcode"]
        comments["usedcodeDescription"] := eval(usedcodeDescription[maxindex]);

        # find maximum of all loadcases, print results
        if WhateverYouNeed["calculations"]["suppress_gui"] = false then
            Write_eta(eta, comments);
            PrintAlert(warnings);
        end if;
        
    end proc:


    # this one is started by ReadSystemSection
    ReadComponentsSpecific_EC5_6 := proc(TypeOfAction::string)
        description "Read specific structure and section data";
        local materialdata, structure, sectiondata, warnings;
        local buckling, l_ky, l_kz, l_efy, l_efz;		# read variables
        local code_615, type_615, a_615, l_615, l1_615;
        local ConstructionType, alpha_ap, tapered_N, r_in, t_lam, l_curve, code_64;
        local code_652, code_622, alpha_622;

        materialdata := WhateverYouNeed["materialdata"];
        sectiondata := WhateverYouNeed["sectiondata"];
        structure := WhateverYouNeed["calculations"]["structure"];
        warnings := WhateverYouNeed["warnings"];
        
        # TypeOfAction
        # "all"
        # "section"
        # "stability"
        # "61"
        # "64"

        # if TypeOfAction = "all" then
        #	WhateverYouNeed["calculations"]["activesettings"]["activematerial"] := GetProperty("TextArea_activematerial", value);
        #	WhateverYouNeed["calculations"]["activesettings"]["activesection"] := GetProperty("TextArea_activesection", value);
        # end if;

        if TypeOfAction = "all" or TypeOfAction = "stability" then
            # buckling lengths

            # http://beta.maplesoft.com/topic/21766/	
            # Maple drops units when value becomes zero
            # Maple drops value when value is one
            if assigned(structure["buckling"]) = false then			
                buckling := table();
                WhateverYouNeed["calculations"]["structure"]["buckling"] := eval(buckling)
            else
                buckling := WhateverYouNeed["calculations"]["structure"]["buckling"]
            end if;

            # don't use slider values here, but textarea - value might be out of boundary for slider
            if ComponentExists("TextArea_l_ky") then
                assign('l_ky', parse(GetProperty("TextArea_l_ky", value)) * Unit('m'));
                buckling["l_ky"] := l_ky;
            end if;

            if ComponentExists("TextArea_l_kz") then
                assign('l_kz', parse(GetProperty("TextArea_l_kz", value)) * Unit('m'));
                buckling["l_kz"] := l_kz;
            end if;

            if ComponentExists("TextArea_l_efy") then
                assign('l_efy', parse(GetProperty("TextArea_l_efy", value)) * Unit('m'));
                buckling["l_efy"] := l_efy;
                if l_efy = 0 then
                    Alert("invalid with l_efy = 0", warnings, 5);
                end if;
            end if;		

            if ComponentExists("TextArea_l_efz") then
                assign('l_efz', parse(GetProperty("TextArea_l_efz", value)) * Unit('m'));
                buckling["l_efz"] := l_efz;
                if l_efz = 0 then
                    Alert("invalid with l_efz = 0", warnings, 5);
                end if;
            end if;		
        end if;
        
        # Read values for 6.1.2/6.1.5
        # Dialogue boxes are activated in GetLoad, and are dependent on alpha value
        if TypeOfAction = "all" or TypeOfAction = "61" then		
            code_615 := table();
            if ComponentExists("ComboBox_type_615") then
                if GetProperty("ComboBox_type_615", 'enabled') = "true" then
                    assign('type_615', GetProperty("ComboBox_type_615", value));
                else
                    assign('type_615', "false");
                end if;
                code_615["type_615"] := type_615;
            end if;

            if ComponentExists("TextArea_a_615") then
                if GetProperty("TextArea_a_615", 'enabled') = "true" then
                    assign('a_615', parse(GetProperty("TextArea_a_615", value)) * Unit('mm'));		# String, needs to be converted to number
                else
                    assign('a_615', "false");		# String, needs to be converted to number
                end if;
                code_615["a_615"] := a_615;	
            end if;

            if ComponentExists("TextArea_l_615") then
                if GetProperty("TextArea_l_615", 'enabled') = "true" then
                    assign('l_615', parse(GetProperty("TextArea_l_615", value)) * Unit('mm'));		# String, needs to be converted to number
                else
                    assign('l_615', "false");		# String, needs to be converted to number
                end if;
                code_615["l_615"] := l_615;
            end if;

            if ComponentExists("TextArea_l1_615") then
                if GetProperty("TextArea_l1_615", 'enabled') = "true" then
                    assign('l1_615', parse(GetProperty("TextArea_l1_615", value)) * Unit('mm'));		# String, needs to be converted to number
                else
                    assign('l1_615', "false");		# String, needs to be converted to number
                end if;
                code_615["l1_615"] := l1_615;
            end if;

            # 6.1.5
            structure["code_615"] := eval(code_615);
        end if;

        # 6.2.2 compression at an angle to the grain
        if TypeOfAction = "all" or TypeOfAction = "section" or TypeOfAction = "sections" or searchtext("Load", TypeOfAction) > 0 or searchtext("622", TypeOfAction) > 0 then
            SetProperty("MathContainer_b", value, sectiondata["b"]);		# 6.2.2, show b
            alpha_622 := GetProperty("Slider_alpha", value) * Unit('degree');
            SetProperty("MathContainer_alpha", value, alpha_622);
            if alpha_622 <= 70 * Unit('degree') then		# delimiter
                SetProperty("MathContainer_h_sin_alpha", 'visible', "true");
                SetProperty("Button_622", 'enabled', "true");
                SetProperty("MathContainer_h_sin_alpha", value, round2(evalf(sectiondata["h"] / cos(alpha_622)), 0));
                if TypeOfAction = "622->" then
                    SetProperty("TextArea_h_622", value, round2(convert(evalf(sectiondata["h"] / cos(alpha_622)), 'unit_free'), 0));
                end if;
            else
                SetProperty("MathContainer_h_sin_alpha", 'visible', "false");
                SetProperty("Button_622", 'enabled', "false");
            end if;
            code_622 := table();
            code_622["h_622"] := parse(GetProperty("TextArea_h_622", value)) * Unit('mm');
            WhateverYouNeed["results"]["A_622"] := eval(WhateverYouNeed["sectiondata"]["b"] * code_622["h_622"]);
            
            structure["code_622"] := eval(code_622);
        end if;

        # 6.4 members with varying cross-section or curved shape
        if TypeOfAction = "all" or TypeOfAction = "section" or TypeOfAction = "sections" or TypeOfAction = "64" then
            assign('ConstructionType', GetProperty("ComboBox_ConstructionType", value));
            
            # if ConstructionType = "Single tapered beam" or ConstructionType = "Saltaksbjelker" then
            if ConstructionType = "Single tapered beam" then
                assign('tapered_N', GetProperty("ComboBox_tapered_N", value));
            else 
                assign('tapered_N', "false");
            end if;
            
            if ConstructionType = "Curved beam" or ConstructionType = "-" then
                assign('alpha_ap', 0 * Unit('degree'));
            else	
                assign('alpha_ap', parse(GetProperty("TextArea_alpha_ap", value)) * Unit('degree'));
            end if;

            if ConstructionType = "Curved beam" or ConstructionType = "Pitched cambered beam" then
                assign('r_in', parse(GetProperty("TextArea_r_in", value)) * Unit('m'));
                if r_in > 0 then
                # ok
                else
                    Alert("Inner radius must be > 0", warnings, 4)
                end if;
                assign('l_curve', parse(GetProperty("TextArea_l_curve", value)) * Unit('m'));
                if l_curve > 0 then
                    # ok
                else
                    Alert("Curve length must be > 0, but lower than 2/3 of length", warnings, 2)
                end if;
                assign('t_lam', parse(GetProperty("TextArea_t_lam", value)) * Unit('mm'));
                if t_lam > 6 * Unit('mm') and t_lam < 45 * Unit('mm') then
                    # ok
                else
                    Alert("Lamination thickness must be 6mm < l < 45 mm", warnings, 2)
                end if;
            else
                r_in := 0;
                l_curve := 0;
                t_lam := 0
            end if;

            code_64 := table();
            code_64["ConstructionType"] := ConstructionType;
            code_64["alpha_ap"] := alpha_ap;
            code_64["tapered_N"] := tapered_N;
            code_64["r_in"] := r_in;
            code_64["l_curve"] := l_curve;
            code_64["t_lam"] := t_lam;

            structure["code_64"] := eval(code_64);

            if materialdata["material"] = "timber" then
                NODETimberEN1995:-calculate_k_64();
            end if;
        end if;

        # 6.5.2
        if TypeOfAction = "all" or TypeOfAction = "652" then
            code_652 := table();
            code_652["endnotched"] := GetProperty("CheckBox_endnotched", value);
            code_652["endnotchedType"] := GetProperty("ComboBox_endnotchedType", value);
            code_652["h_ef"] := parse(GetProperty("TextArea_h_ef", value)) * Unit('mm');
            code_652["l_incl"] := parse(GetProperty("TextArea_l_incl", value)) * Unit('mm');
            code_652["x_652"] := parse(GetProperty("TextArea_x_652", value)) * Unit('mm');

            structure["code_652"] := eval(code_652);
        end if;

    end proc:
    

    ResetSpecific_EC5_6 := proc()
        description "Reset specific values for calculation";
        local sectionchanged;

        sectionchanged := ReadComponentsCommon_TimberGUI(WhateverYouNeed, {""}, "Reset");

        SetProperty("ComboBox_materials", 'itemlist', [GetProperty("TextArea_activematerial", value)]);
        SetProperty("ComboBox_sections", 'itemlist', [GetProperty("TextArea_activesection", value)]);

        ModifyComboVariables("ComboBox_materials", "Add", WhateverYouNeed["materials"], WhateverYouNeed["materialdata"]);
        ModifyComboVariables("ComboBox_sections", "Add", WhateverYouNeed["sections"], WhateverYouNeed["sectiondata"]);

    end proc:


    RunAfterRestoresettings_EC5_6 := proc()
        SetComboBoxSection(WhateverYouNeed, "");	# Set Combobox Section if possible	
        activateComponents_64();					# need to activate / deactivate fields according to structural system
    end proc:


    # EC5_8
    InitSpecific_EC5_8 := proc()
        description "Specific initialization values";        
        local var_numeric, var_loadvariables, var_connection_cut, var_connection_angle, var_connection_length, var_units, var_calculations_FastenerPatterns, FastenerPatterns, var_calculations_fasteners;
        
        WhateverYouNeed["calculations"]["calculationtype_short"] := "EC5 part 1-1 Connections";		# for export to Excel

        # libFastenerPattern start
        var_calculations_FastenerPatterns := {"activeFastenerPattern", "activematerial1", "activematerial2", "activesection1", "activesection2",
                        "FastenerPatternUnits", "reactionforces",
                        "FastenerPatternType1", "center_x1", "center_y1", "grid_x1", "grid_y1", "grid_alpha_11", "grid_alpha_21", "radial_diameter1", "radial_items1", "radial_alpha1",
                        "FastenerPatternType2", "center_x2", "center_y2", "grid_x2", "grid_y2", "grid_alpha_12", "grid_alpha_22", "radial_diameter2", "radial_items2", "radial_alpha2",
                        "FastenerPatternType3", "center_x3", "center_y3", "grid_x3", "grid_y3", "grid_alpha_13", "grid_alpha_23", "radial_diameter3", "radial_items3", "radial_alpha3",
                        "FastenerPatternCoordinates", "coordinates"};

        var_calculations_fasteners := {"connection1", "connection2", "connectionInsideLayers", "connectionInsideTolerance", "serviceclass", "loaddurationclass", "timbertype1", "strengthclass1", "b1", "bout1", "h1", "graindirection1",
                        "timbertype2", "strengthclass2", "b2", "h2", "graindirection2", "graindirectionsteel", "steeltype", "bsteel", "hsteel", "lengthleftsteel", "lengthrightsteel",
                        "chosenFastener", "calculateAsNail", "nailForm", "nailSurface", "fastener_d", "fastenerProducer", "fastenerProduct", "fastener_ls", "fastener_dh",
                        "washerProducer", "washerProduct", "screwWithWasher", "staggered1", "staggered2",
                        "predrilled", "ignoreReqPredrilled", "alphaScrew", "a11", "a12", "a21", "a22", "a31", "a32", "a41", "a42", "lengthleft1", "lengthright1", "lengthleft2", "lengthright2",
                        "ShearConnector", "SharpMetalProducer", "SharpMetalProduct", "SharpMetalStripes", "SharpMetalLength", "SplitRingtype", "SplitRingdc", 
                        "ToothedPlatesides", "ToothedPlatetype", "ToothedPlatedc"};

        # all variables starting with those values are numeric, grid is NOT (2*70)
        var_numeric := {"graindirection", "alphaScrew", "center_", "radial_", "loadcenter_", "fastener_d", "fastener_ls", "fastener_dh", 
                "connectionInsideTolerance", "connectionInsideLayers", "bout1", "SharpMetalStripes", "SharpMetalLength", "SplitRingdc", "ToothedPlatedc"};

        # define default units for unit checks
        var_units := WhateverYouNeed["componentvariables"]["var_units"];	
        var_units["mm"] := var_units["mm"] union {"bout", "fastener_d", "fastener_ls", "fastener_dh", "connectionInsideTolerance", "SharpMetalLength", "SplitRingdc", "ToothedPlate", "length"};
        var_units["arcdeg"] := var_units["arcdeg"] union {"graindirection", "alphaScrew", "radial_", "angle"};

        var_connection_cut := {"cutleft1", "cutleft2", "cutright1", "cutright2", "cutleftsteel", "cutrightsteel"};
        var_connection_angle := {"angleleft1", "angleright1", "angleleft2", "angleright2", "angleleftsteel", "anglerightsteel"};
        var_connection_length := {"lengthleft1", "lengthright1", "lengthleft2", "lengthright2", "lengthleftsteel", "lengthrightsteel"};

        WhateverYouNeed["componentvariables"]["var_calculations"] := WhateverYouNeed["componentvariables"]["var_calculations"] union var_calculations_FastenerPatterns union var_calculations_fasteners;
        WhateverYouNeed["componentvariables"]["var_numeric"] := WhateverYouNeed["componentvariables"]["var_numeric"] union var_numeric union var_connection_angle union var_connection_length;
        
        # WhateverYouNeed["componentvariables"]["var_calculationdata"] := eval(WhateverYouNeed["componentvariables"]["var_calculationdata"] union {"activeFastenerPattern", "activematerial1", "activematerial2", "activematerialsteel", 
        #				"activesection1", "activesection2", "activesectionsteel"});
        
        WhateverYouNeed["componentvariables"]["var_storeitems"] := eval(WhateverYouNeed["componentvariables"]["var_storeitems"] union {});

        # Comboboxes where there are stored a list of settings
        # variables with - in front of the name are not going to be read by standard procedure, but deprecated to runAfterXMLImportLocal
        WhateverYouNeed["componentvariables"]["var_ComboBox"] := WhateverYouNeed["componentvariables"]["var_ComboBox"] union {"FastenerPatterns", "-connection", "-fastener"};

        var_loadvariables := {"f_814"};
        WhateverYouNeed["calculations"]["loadvariables"] := WhateverYouNeed["calculations"]["loadvariables"] union var_loadvariables;

        WhateverYouNeed["componentvariables"]["var_connection_cut"] := var_connection_cut;
        WhateverYouNeed["componentvariables"]["var_connection_length"] := var_connection_length;
        WhateverYouNeed["componentvariables"]["var_connection_angle"] := var_connection_angle;
        WhateverYouNeed["componentvariables"]["var_connection_graindirection"] := {"graindirection1", "graindirection2", "graindirectionsteel"};

        # need to setup variable for storing values, but only if missing
        if assigned(WhateverYouNeed["calculations"]["structure"]["FastenerPatterns"]) = false then
            FastenerPatterns := table();
            WhateverYouNeed["calculations"]["structure"]["FastenerPatterns"] := eval(FastenerPatterns)
        end if;	
    end proc:


    Main_EC5_8 := proc(action::string)        
        description "Main calculation routine for EC5_8 calculations";
        local calculations, activesettings, structure, comments, chosenFastener, fastener, calculatedFastener, d, warnings, fastenervalues, eta, usedcode, checkPassed,
                force, maxindex, usedcodeDescription;

        # declare local variables
        calculations := WhateverYouNeed["calculations"];	
        structure := calculations["structure"];	
        activesettings := calculations["activesettings"];		
        warnings := WhateverYouNeed["warnings"];
        fastener := structure["fastener"];
        fastenervalues := WhateverYouNeed["calculatedvalues"]["fastenervalues"];
        force := WhateverYouNeed["calculations"]["loadcases"][activesettings["activeloadcase"]];

        # reset eta, usedcode, usedCodeDescription, comments
        eta := table();
        usedcode := table();
        usedcodeDescription := table();
        comments := table();

        # updateComponents := true;		# update results to Maple components
        
        WhateverYouNeed["results"]["eta"] := eta;
        WhateverYouNeed["results"]["usedcode"] := usedcode;
        WhateverYouNeed["results"]["usedcodeDescription"] := usedcodeDescription;
        WhateverYouNeed["results"]["comments"] := comments;
        
        # local variables for metal fasteners
        chosenFastener := fastener["chosenFastener"];
        d := fastener["fastener_d"];

        if action = "CalculateAllLoadcases" or action = "calculateAllLoadcasesCleanup" then		# don't reset calculated values

            # updateComponents := false
            
        elif action = "calculation" or WhateverYouNeed["calculations"]["autocalc"] then
            
            # when running calculation of singular loadcase, global utilization values might not be correct anymore
            SetProperty("TextArea_etamax_max", 'enabled', "false");
            SetProperty("TextArea_loadcaseMax", 'enabled', "false");
            SetProperty("TextArea_warningsAll", 'enabled', "false");			
        
        else

            Alert(cat("Main: action ", action, " undefined"), warnings, 3);
            
        end if;
        

        # are we running in a readin mode from XMLImport, prohibit change of section in MaterialChanged
        calculations["XMLImport"] := false;

        checkServiceclass(WhateverYouNeed);	# Annex

        # geometry dependent routines will not be run when calculating all loadcases
        # calculating number of shearplanes, thickness, number of timber layers in connection	
        if WhateverYouNeed["calculations"]["calculatingAllLoadcases"] = false then

            calculateShearplanes();					# EC5_81	
            validateConnection(WhateverYouNeed);					# EC5_8_SetVisibilityCombobox
            calculate_t_total();					# EC5_81
            calculate_t();							# EC5_83, 8.3.1.1(1), calculate t_eff, t_pen, n_tip

            if MASTERALARM(warnings) = true then
                HighlightResults({"eta812_active", "eta832_active", "eta814_active", "eta833_active", "etamax_active"}, "deactivate");
                return
            end if;

            # calculate metal fastener values
            # check if user overrides calculated settings
            if fastener["calculateAsNail"] = "true" then
                comments["calculateAsNail"] := "calculate as nail";
            elif assigned(comments["calculateAsNail"]) then
                comments["calculateAsNail"] := evaln(comments["calculateAsNail"])		# remove entry
            end if;

            GetCalculatedFastener();
            comments["calculation"] := cat(chosenFastener, ", calculated as ", fastenervalues["calculatedFastener"]);

            GetFastenervalues();		# EC5_83: check if fastenervalues are predefined or need to be calculated, M_yRk, f_tensk

            if MASTERALARM(warnings) = true then
                HighlightResults({"eta812_active", "eta832_active", "eta814_active", "eta833_active", "etamax_active"}, "deactivate");
                return
            end if;

            calculate_amin_max();		# calculate force independent minimum distance values
            
        end if;

    # check if calculateMinimumdistance should be run first, because min. a1 and a2 distance could be used when finding number of fasteners in row and column

        NODEFastenerPattern:-CalculateForcesInConnection(WhateverYouNeed);		# reads fastener definition and calculates points and forces
        
        if WhateverYouNeed["calculations"]["calculatingAllLoadcases"] = false then
            
            NODEFastenerPattern:-PlotResults(WhateverYouNeed)
            
        end if;
            
        if MASTERALARM(warnings) = true then
            HighlightResults({"eta812_active", "eta832_active", "eta814_active", "eta833_active", "etamax_active"}, "deactivate");
            return
        end if;

        # calculate alpha dependent values
        # as per now not implemented properly, as it is almost impossible to use proper alpha values (e.g. moment in connections, each bolt has different alpha 'value')
        if WhateverYouNeed["calculations"]["calculatingAllLoadcases"] = false then

            calculateMinimumdistances();		# EC5_8_minimumdistance, as per now not calculated with correct alpha angle, but alpha = 0
            # calculate_f_hk(WhateverYouNeed);				# EC5_85, characteristic embedment strength values	
            calculate_n_ef();				# calculate reduction factor for fasteners in a row

            if MASTERALARM(warnings) = true then
                HighlightResults({"eta812_active", "eta832_active", "eta814_active", "eta833_active", "etamax_active"}, "deactivate");
                return
            end if;
            
        end if;

        # force in axial direction of fastener
        if WhateverYouNeed["calculations"]["calculatingAllLoadcases"] = false then
            
            calculate_F_axR();		# EC5_83, need to calculate value also if there is no axiallyLoaded condition (calculate_F_vR)
            if force["F_axd"] > 0 then
                WhateverYouNeed["calculatedvalues"]["axiallyLoaded"] := true;
                comments["axiallyLoaded"] := "axially loaded";
                
            else								# assigned(comments["axiallyLoaded"]) then
                WhateverYouNeed["calculatedvalues"]["axiallyLoaded"] := false;
                if assigned(comments["axiallyLoaded"]) then
                    comments["axiallyLoaded"] := evaln(comments["axiallyLoaded"])
                end if;
                
            end if;		
        
            if MASTERALARM(warnings) = true then
                HighlightResults({"eta812_active", "eta832_active", "eta814_active", "eta833_active", "etamax_active"}, "deactivate");
                return
            end if;
        end if;

        # check predrill requirement 8.3.1.1(2)
        if WhateverYouNeed["calculations"]["calculatingAllLoadcases"] = false then

            checkPredrilled();			# EC5_83
            checkPassed := checkAnchorageLength(false, WhateverYouNeed);			# EC5_83, CheckSingleShearPlane - check if just one shearplane should be used, even if fastener openes for two

            if MASTERALARM(warnings) = true then
                HighlightResults({"eta812_active", "eta832_active", "eta814_active", "eta833_active", "etamax_active"}, "deactivate");
                return
            end if;
            
        end if;

    #	if WhateverYouNeed["calculations"]["calculatingAllLoadcases"] = false then

            # this needs to be calculated for every fastener, if different angles in connection
            # calculate_F_vR(WhateverYouNeed);		# EC5_82
            # calculate_F_90R(WhateverYouNeed);		# EC5_81, splitting capacity, moved into EC5_814

    #		if MASTERALARM(warnings) = true then
    #			HighlightResults({"eta812_active", "eta832_active", "eta814_active", "eta833_active", "etamax_active"}, "deactivate");
    #			return
    #		end if;
            
    #	end if;

        NODETimberEN1995:-calculate_f_h0k();		# 8.3.1.1(5)
            
        # 8.3.3
        # global chosenFastener, nailSurface, eta, eta_v, eta_ax, eta_814, F_axEd, F_vEd, F_axRd_total, F_vRd_total;
        # local variabl1es, j, dummy, dummy1;

        eta["max"] := 0;

        eta["812"], usedcode["812"], usedcodeDescription["812"] := EC5_812();			# 8.1.2 Multiple fastener connections
        
        eta["814"], usedcode["814"], usedcodeDescription["814"] := EC5_814();			# 8.1.4 Connection forces at an angle to the grain

        eta["832"], usedcode["832"], usedcodeDescription["832"] := EC5_832();			# 8.3.2/8.7.2 Axially loaded nails/screw

        eta["62net"], usedcode["62net"], usedcodeDescription["62net"] := EC5_62net();	# EC5_81, check of beam net tension area

        if WhateverYouNeed["calculatedvalues"]["axiallyLoaded"] then
            eta["833"], usedcode["833"], usedcodeDescription["833"] := EC5_833()		# 8.3.3 Combined laterally and axially loaded nails	
        else
            eta["833"] := 0
        end if;

        eta["AnnexA"], usedcode["AnnexA"], usedcodeDescription["AnnexA"] := AnnexA();	# Annex A: Block Shear check

        eta["BoltSteel"], usedcode["BoltSteel"], usedcodeDescription["BoltSteel"] := BoltandSteelCapacity();

        eta["max"], maxindex := maxIndexTable(eta);
        comments["usedcode"] := eval(usedcode[maxindex]);
        comments["usedcodeDescription"] := eval(usedcodeDescription[maxindex]);

        # find maximum of all loadcases, print results
        if WhateverYouNeed["calculations"]["suppress_gui"] = false then
            Write_eta(eta, comments);
            PrintAlert(warnings);
        end if;

    end proc:


    ReadComponentsSpecific_EC5_8 := proc(TypeOfAction::string)	
        description "Read specific structure and section data";
        local structure, connection, fastener, fastenervalues, dummy, dummy1, distance, activesettings, calculations, warnings;

        calculations := WhateverYouNeed["calculations"];	
        structure := calculations["structure"];
        warnings := WhateverYouNeed["warnings"];	
        activesettings := calculations["activesettings"];	

        # define some more variables
        # connection
        if assigned(structure["connection"]) = false then
            connection := table();
            structure["connection"] := eval(connection)
        else
            connection := structure["connection"]
        end if;

        # fastener
        if assigned(structure["fastener"]) = false then
            fastener := table();			# input of fastener information, will be stored into structure variable and exported to xml file
            structure["fastener"] := eval(fastener)
        else
            fastener := structure["fastener"]
        end if;

        # fastenervalues
        if assigned(WhateverYouNeed["calculatedvalues"]["fastenervalues"]) = false then
            fastenervalues := table();		# calculated or table values of fasteners, will not be stored in xml file
            WhateverYouNeed["calculatedvalues"]["fastenervalues"] := fastenervalues;
        else
            fastenervalues := WhateverYouNeed["calculatedvalues"]["fastenervalues"]
        end if;

        # when layout changes we must reset calculated values
        distance := table();
        WhateverYouNeed["calculatedvalues"]["distance"] := eval(distance);
        NODEFastenerPattern:-ModifyFastenerPattern("AddFastenerPattern", WhateverYouNeed);
        
        # TypeOfAction
        # ============
        # all
        # connection
        # fastener
        # layout
        # distance

        # structure subvalues
        # ===================
        # connection
        # fastener
        # layout
        # distance
        # calculatedvalues

        if TypeOfAction = "all" or TypeOfAction = "connection" then	
            SetComboConnection(WhateverYouNeed)					# EC5_8_SetVisibilityCombobox
        end if;

        if TypeOfAction = "all" or TypeOfAction = "fastener" then
            ReadComponentsSpecific_fastener(fastener, fastenervalues)		# NODETimberLibary
        end if;

        if TypeOfAction = "all" or TypeOfAction = "layout" or TypeOfAction = "connection" then		
            SetVisibilityTimberCut();
            ReadComponentsSpecific_connection(WhateverYouNeed, connection);	# NODETimberLibary
        end if;

        # sections with special section name 71(40)x140 require additional care
        # outer profile thickness is stored both in section name and connection definition
        # invoked by MainCommon("section"), but to be certain also checked when called by "connection"
        if TypeOfAction = "all" or TypeOfAction = "section" or TypeOfAction = "connection" then
            if GetProperty("TextArea_section_bout1", 'enabled') = "true" then
                connection["bout1"] := parse(GetProperty("TextArea_section_bout1", 'value')) * Unit('mm')
            else
                connection["bout1"] := "false"
            end if;
        end if;

        activesettings["calculate_814_NA_DE"] := GetProperty("CheckBox_calculate_814_NA_DE", 'value');

        # calculatedvalues
        
    end proc:


    ResetSpecific_EC5_8 := proc()
        description "Reset specific values for calculation";
        
        # reset Fasternpatterns, one bolt in origo
        SetProperty("ComboBox_FastenerPatternType1", 'selectedindex', 1);
        SetProperty("TextArea_center_x1", 'value', "0");
        SetProperty("TextArea_center_y1", 'value', "0");
        SetProperty("TextArea_grid_x1", 'value', "0");
        SetProperty("TextArea_grid_y1", 'value', "0");
        SetProperty("TextArea_grid_alpha_11", 'value', "0");
        SetProperty("TextArea_grid_alpha_21", 'value', "0");
        SetProperty("ComboBox_FastenerPatternType2", 'selectedindex', 0);
        SetProperty("ComboBox_FastenerPatternType3", 'selectedindex', 0);
        # SetProperty("CheckBox_FastenerPatternCoordinates", 'enabled', "false");
        NODEFastenerPattern:-SetVisibilityFastenerPattern();
        SetProperty("ComboBox_FastenerPatterns", 'itemlist', ["1"]);
        SetProperty("TextArea_activeFastenerPattern", 'value', "1");
        NODEFastenerPattern:-ModifyFastenerPattern("AddFastenerPattern", WhateverYouNeed)
    end proc:


    RunAfterRestoresettings_EC5_8 := proc()
        description "Procedures defining settings after restore from storesettings";
        local partsnumber, activematerial, activesection, materialdataAll, sectiondataAll, dummy, dummy1, pos;

        materialdataAll := WhateverYouNeed["materialdataAll"];
        sectiondataAll := WhateverYouNeed["sectiondataAll"];

        # set Combobox values dependent on stored definitions
        for partsnumber in {"1", "2"} do		

            if assigned(WhateverYouNeed["calculations"]["activesettings"][cat("activematerial", partsnumber)]) then
                activematerial := WhateverYouNeed["calculations"]["activesettings"][cat("activematerial", partsnumber)];
                NODETimberEN1995:-GetMaterialdata(activematerial, WhateverYouNeed);
                materialdataAll[partsnumber] := eval(WhateverYouNeed["materialdata"]);
                NODETimberEN1995:-SetComboBoxMaterial(WhateverYouNeed, false, partsnumber);			
            end if;

            if assigned(WhateverYouNeed["calculations"]["activesettings"][cat("activesection", partsnumber)]) then
                activesection := WhateverYouNeed["calculations"]["activesettings"][cat("activesection", partsnumber)];
                NODETimberEN1995:-GetSectiondata(activesection, WhateverYouNeed);			
                sectiondataAll[partsnumber] := eval(WhateverYouNeed["sectiondata"]);
                SetComboBoxSection(WhateverYouNeed, partsnumber);	# Set Combobox Section if possible		
            end if;
            
        end do;

        # steel
        if assigned(WhateverYouNeed["calculations"]["activesettings"]["activematerialsteel"]) then
            
            activematerial := WhateverYouNeed["calculations"]["activesettings"]["activematerialsteel"];
            NODESteelEN1993:-GetMaterialdata(activematerial, WhateverYouNeed);		
            materialdataAll["steel"] := eval(WhateverYouNeed["materialdata"]);

            dummy := GetProperty("ComboBox_steelgrade", 'itemlist');
            dummy1 := WhateverYouNeed["materialdataAll"]["steel"]["steelgrade"];
            if member(dummy1, dummy, 'pos') then
                SetProperty("ComboBox_steelgrade", 'selectedindex', pos-1);			
            end if;		
            
            activesection := WhateverYouNeed["calculations"]["activesettings"]["activesectionsteel"];
            NODESteelEN1993:-GetSectiondata(activesection, WhateverYouNeed);
            sectiondataAll["steel"] := eval(WhateverYouNeed["sectiondata"]);
            SetProperty("TextArea_section_bsteel", 'value', convert(WhateverYouNeed["sectiondataAll"]["steel"]["b"], 'unit_free'));
            SetProperty("TextArea_section_hsteel", 'value', convert(WhateverYouNeed["sectiondataAll"]["steel"]["h"], 'unit_free'));
            
        end if;

    end proc:

    
    # Timber Beam with Opening
    InitSpecific_Opening := proc()
        description "Declare some global variables before use";
        global WhateverYouNeed;
        local var_calculations, var_numeric, var_loadvariables, var_units, var_connection_cut, var_connection_angle, var_connection_length;
            # var_connection_cut, var_connection_angle, ;	
        
        WhateverYouNeed["calculations"]["calculationtype_short"] := "Timber beam with opening";		# for export to Excel
            
        var_calculations := {"positionnumber", "positiontitle", "activeloadcase", "activematerial", "activesection", "timbertype", "b", "h", "strengthclass", "serviceclass", "loaddurationclass", "reactionforces",
                        "numberOfFasteners", "chosenFastener", "calculateAsNail", "nailForm", "nailSurface", "fastener_d", "fastenerProducer", "fastenerProduct", "fastener_ls", "fastener_dh",
                        "predrilled", "ignoreReqPredrilled", "alphaScrew", "a11", "a12", "a21", "a22", "a31", "a32", "a41", "a42", "graindirection1", "lengthleft1", "lengthright1",
                        "openingtype", "opening_a", "opening_hd", "opening_e", "opening_lv", "opening_lA", "opening_lz", "opening_r", "reinforcement", "screwposition"};

        var_loadvariables := {};
        
        # all variables starting with those values are numeric, grid is NOT (2*70)
        var_numeric := {"alphaScrew", "center_", "radial_", "loadcenter_", "fastener_d", "fastener_ls", "opening_", "numberOfFasteners"};

        # define default units for unit checks
        var_units := WhateverYouNeed["componentvariables"]["var_units"];	
        var_units["mm"] := var_units["mm"] union {"fastener_d", "fastener_ls", "opening_", "h_r", "length", "a2_min_max", "a3c_min_max", "a4c_min_max", "a21", "a31", "a41"};
        var_units["arcdeg"] := var_units["arcdeg"] union {"alphaScrew", "radial_", "angle"};
        
        # var_numeric := {"alphaScrew", "center_", "radial_", "loadcenter_", "fastener_d", "fastener_ls", "angleleft1", "angleright1", "lengthleft1", "lengthright1", "graindirection1", "opening_"};

        var_connection_cut := {"cutleft1", "cutright1"};
        var_connection_angle := {"angleleft1", "angleright1"};
        var_connection_length := {"lengthleft1", "lengthright1"};

        WhateverYouNeed["componentvariables"]["var_calculations"] := WhateverYouNeed["componentvariables"]["var_calculations"] union var_calculations;
        WhateverYouNeed["componentvariables"]["var_numeric"] := eval(var_numeric) union var_connection_angle union var_connection_length;
        
        WhateverYouNeed["componentvariables"]["var_storeitems"] := eval(WhateverYouNeed["componentvariables"]["var_storeitems"] union {});

        WhateverYouNeed["calculations"]["loadvariables"] := WhateverYouNeed["calculations"]["loadvariables"] union var_loadvariables;

    end proc:


    ResetSpecific_Opening := proc()
        description "Reset specific values for calculation";
        local autocalc_;

        autocalc_ := GetProperty("CheckBox_autocalc", 'value');
        SetProperty("CheckBox_autocalc", 'value', "false");
        WhateverYouNeed["calculations"]["autocalc"] := false;

        # resetting Combobox for materials and sections
        SetProperty("ComboBox_timbertype", 'selectedindex', 0);			# Solid timber
        NODEDocumentCommon:-MainCommon("timbertype");										# setting C14, 36x98
        SetProperty("ComboBox_serviceclass", 'selectedindex', 0);		# Service class 1
        SetProperty("ComboBox_loaddurationclass", 'selectedindex', 0);	# Load-duration class Permanent
        SetProperty("ComboBox_materials", 'itemlist', [GetProperty("TextArea_activematerial", value)]);
        SetProperty("ComboBox_sections", 'itemlist', [GetProperty("TextArea_activesection", value)]);
        ModifyComboVariables("ComboBox_materials", "Add", WhateverYouNeed["materials"], WhateverYouNeed["materialdata"]);
        ModifyComboVariables("ComboBox_sections", "Add", WhateverYouNeed["sections"], WhateverYouNeed["sectiondata"]);

        # openings
        SetProperty("ComboBox_openingtype", 'value', "1");
        SetVisibilityOpening(GetProperty("ComboBox_openingtype", 'value'));
        SetProperty("TextArea_opening_a", 'value', "100");
        SetProperty("TextArea_opening_hd", 'value', "100");
        SetProperty("TextArea_opening_e", 'value', "0");
        SetProperty("TextArea_opening_lv", 'value', "0");
        SetProperty("TextArea_opening_lA", 'value', "0");
        SetProperty("TextArea_opening_lz", 'value', "0");
        SetProperty("TextArea_opening_r", 'value', "0");

        SetProperty("CheckBox_autocalc", 'value', autocalc_);
    end proc:


    RunAfterRestoresettings_Opening := proc()
        description "Procedures defining settings after restore from storesettings";
        local partsnumber, activematerial, activesection, materialdataAll, sectiondataAll;

        materialdataAll := WhateverYouNeed["materialdataAll"];
        sectiondataAll := WhateverYouNeed["sectiondataAll"];

        # set Combobox values dependent on stored definitions
        for partsnumber in {"1", "2"} do		
            
            if assigned(WhateverYouNeed["calculations"]["activesettings"][cat("activematerial", partsnumber)]) then
                activematerial := WhateverYouNeed["calculations"]["activesettings"][cat("activematerial", partsnumber)];
                NODETimberEN1995:-GetMaterialdata(activematerial, WhateverYouNeed);
                materialdataAll[partsnumber] := eval(WhateverYouNeed["materialdata"]);
                NODETimberEN1995:-SetComboBoxMaterial(WhateverYouNeed, false, partsnumber);			
            end if;

            if assigned(WhateverYouNeed["calculations"]["activesettings"][cat("activesection", partsnumber)]) then
                activesection := WhateverYouNeed["calculations"]["activesettings"][cat("activesection", partsnumber)];
                NODETimberEN1995:-GetSectiondata(activesection, WhateverYouNeed);			
                sectiondataAll[partsnumber] := eval(WhateverYouNeed["sectiondata"]);

                SetComboBoxSection(WhateverYouNeed, partsnumber);	# Set Combobox Section if possible	
            end if;
            
        end do;
        
        SetVisibilityOpening(GetProperty("ComboBox_openingtype", 'value'));  # sets load excentricity as well		

    end proc:

    # this one is started by ReadSystemSection
    ReadComponentsSpecific_Opening := proc(TypeOfAction::string)	
        description "Read specific structure and section data";
        local connection, structure, warnings;
        local fastener, fastenervalues, comments, activesettings, calculations, opening;

        calculations := WhateverYouNeed["calculations"];	
        # materialdata := WhateverYouNeed["materialdata"];
        # sectiondata := WhateverYouNeed["sectiondata"];

        warnings := WhateverYouNeed["warnings"];
        structure := calculations["structure"];
        comments := calculations["comments"];
        activesettings := calculations["activesettings"];

        # define some more variables
        # connection
        if assigned(structure["connection"]) = false then
            connection := table();
            structure["connection"] := eval(connection)
        else
            connection := structure["connection"]
        end if;

        # fastener
        if assigned(structure["fastener"]) = false then
            fastener := table();			# input of fastener information, will be stored into structure variable and exported to xml file
            structure["fastener"] := eval(fastener)
        else
            fastener := structure["fastener"]
        end if;

        # fastenervalues
        if assigned(WhateverYouNeed["calculatedvalues"]["fastenervalues"]) = false then
            fastenervalues := table();		# calculated or table values of fasteners, will not be stored in xml file
            WhateverYouNeed["calculatedvalues"]["fastenervalues"] := fastenervalues;
        else
            fastenervalues := WhateverYouNeed["calculatedvalues"]["fastenervalues"]
        end if;

        # opening
        if assigned(structure["opening"]) = false then
            opening := table();			# input of fastener information, will be stored into structure variable and exported to xml file
            structure["opening"] := eval(opening)
        else
            opening := structure["opening"]
        end if;

        # when layout changes we must reset calculated values
        # distance := table();
        # WhateverYouNeed["calculatedvalues"]["distance"] := eval(distance);	
        
        # TypeOfAction
        # ============
        # all
        # fastener
        # layout
        # distance

        # structure subvalues
        # ===================
        # fastener
        # layout
        # distance
        # calculatedvalues

        if TypeOfAction = "all" or TypeOfAction = "fastener" then
            ReadComponentsSpecific_fastener(fastener, fastenervalues)	# common
        end if;

        if TypeOfAction = "all" or TypeOfAction = "layout" then
                
        end if;

        if TypeOfAction = "all" or TypeOfAction = "opening" then
            
            opening["openingtype"] := GetProperty("ComboBox_openingtype", 'value');
            opening["opening_a"] := parse(GetProperty("TextArea_opening_a", 'value')) * Unit('mm');
            opening["reinforcement"] := GetProperty("ComboBox_reinforcement", 'value');
            opening["screwposition"] := GetProperty("ComboBox_screwposition", 'value');

            if GetProperty("TextArea_opening_hd", 'enabled') = "true" then
                opening["opening_hd"] := parse(GetProperty("TextArea_opening_hd", 'value')) * Unit('mm')
            else
                opening["opening_hd"] := opening["opening_a"]		# circular hole, defined by a value
            end if;

            opening["opening_e"] := parse(GetProperty("TextArea_opening_e", 'value')) * Unit('mm');
            opening["opening_lv"] := parse(GetProperty("TextArea_opening_lv", 'value')) * Unit('mm');
            opening["opening_lA"] := parse(GetProperty("TextArea_opening_lA", 'value')) * Unit('mm');
            opening["opening_lz"] := parse(GetProperty("TextArea_opening_lz", 'value')) * Unit('mm');
            opening["opening_r"] := parse(GetProperty("TextArea_opening_r", 'value')) * Unit('mm');
            
        end if;

    end proc:


    # in case of calculateAllLoadcases this routine is run partly, but at the end a full calculation with the active loadcase is run in addition
    Main_Opening := proc()
        description "Main calculation procedure, calculates values for each force";
        local calculations, activesettings, structure, comments, chosenFastener, fastener, calculatedFastener, warnings, fastenervalues, eta, usedcode, checkPassed, maxindex, usedcodeDescription, openingResult;

        # declare local variables
        calculations := WhateverYouNeed["calculations"];	
        structure := calculations["structure"];	
        activesettings := calculations["activesettings"];		
        warnings := WhateverYouNeed["warnings"];
        fastener := structure["fastener"];
        fastenervalues := WhateverYouNeed["calculatedvalues"]["fastenervalues"];
        # force := WhateverYouNeed["calculations"]["loadcases"][activesettings["activeloadcase"]];
        
        openingResult := table();
        WhateverYouNeed["results"]["opening"] := openingResult;

        # reset eta, usedcode, usedCodeDescription, comments
        eta := table();
        usedcode := table();
        usedcodeDescription := table();
        comments := table();
        
        WhateverYouNeed["results"]["eta"] := eta;
        WhateverYouNeed["results"]["usedcode"] := usedcode;
        WhateverYouNeed["results"]["usedcodeDescription"] := usedcodeDescription;
        WhateverYouNeed["results"]["comments"] := comments;
        
        # local variables for metal fasteners
        chosenFastener := fastener["chosenFastener"];
        # d := fastener["fastener_d"];

        # are we running in a readin mode from XMLImport, prohibit change of section in MaterialChanged
        calculations["XMLImport"] := false;

        # checkServiceclass(WhateverYouNeed);	# Annex

        # setting necessary variables
        WhateverYouNeed["materialdataAll"]["1"] := WhateverYouNeed["materialdata"];		# value by pointer (mutable)
        WhateverYouNeed["sectiondataAll"]["1"] := WhateverYouNeed["sectiondata"];			# value by pointer
        
        # duplicate settings for calculation of F_axR
        WhateverYouNeed["materialdataAll"]["2"] := WhateverYouNeed["materialdata"];		# value by pointer (mutable), no change in material properties
        WhateverYouNeed["sectiondataAll"]["2"] := WhateverYouNeed["sectiondata"];			# value by pointer

        # settings fixed geometry values
        structure["connection"]["graindirection1"] := 0;
        structure["connection"]["cutleft1"] := "cut rect.";
        structure["connection"]["cutright1"] := "cut rect.";
        structure["connection"]["angleleft1"] := 90 * Unit('degree');
        structure["connection"]["angleright1"] := 90 * Unit('degree');
        structure["connection"]["connection1"] := "Timber";
        structure["connection"]["connection2"] := "Timber";
        
        structure["connection"]["lengthleft1"] := max(500 * Unit('mm'), WhateverYouNeed["calculations"]["structure"]["opening"]["opening_a"] / 2 + 200 * Unit('mm'));
        structure["connection"]["lengthright1"] := structure["connection"]["lengthleft1"];	

        # geometry dependent routines will not be run when calculating all loadcases
        # calculating number of shearplanes, thickness, number of timber layers in connection	

        checkOpeningGeometry(WhateverYouNeed);		# needed for calculatingAllLoadcases as well
        if MASTERALARM(warnings) = true then
            return
        end if;
        
        if WhateverYouNeed["calculations"]["calculatingAllLoadcases"] = false then

            calculate_t(WhateverYouNeed);							# EC5_83, 8.3.1.1(1), calculate t_eff, t_pen, n_tip
            if MASTERALARM(warnings) = true then
                return
            end if;

            if WhateverYouNeed["calculations"]["structure"]["opening"]["reinforcement"] = "interior" then
                # calculate metal fastener values
                # check if user overrides calculated settings
                if fastener["calculateAsNail"] = "true" then
                    comments["calculateAsNail"] := "calculate as nail";
                elif assigned(comments["calculateAsNail"]) then
                    comments["calculateAsNail"] := evaln(comments["calculateAsNail"])		# remove entry
                end if;

                GetCalculatedFastener(WhateverYouNeed);	
                comments["calculation"] := cat(chosenFastener, ", calculated as ", fastenervalues["calculatedFastener"]);

                GetFastenervalues(WhateverYouNeed);		# EC5_83: check if fastenervalues are predefined or need to be calculated, M_yRk, f_tensk
                calculate_F_axR(WhateverYouNeed);			# EC5_83, need to calculate value also if there is no axiallyLoaded condition (calculate_F_vR)

                if MASTERALARM(warnings) = true then
    #				HighlightResults({"eta812_active", "eta832_active", "eta814_active", "eta833_active", "etamax_active"}, "deactivate");
                    return
                end if;
            end if;		
        end if;

        # check if load excentricity is correct

        CheckLoadExcentricity(WhateverYouNeed);
        if WhateverYouNeed["calculations"]["structure"]["opening"]["reinforcement"] = "interior" then
            calculate_amin_max(WhateverYouNeed);		# calculate force independent minimum distance values
            PrintMinimumdistance("1", WhateverYouNeed);
        end if;
        
        calculate_BeamWithOpening(WhateverYouNeed);

        if WhateverYouNeed["calculations"]["suppress_gui"] = false then
            NODEFastenerPattern:-PlotResults(WhateverYouNeed)
        end if;

        eta["max"], maxindex := maxIndexTable(eta);
    #	comments["usedcode"] := eval(usedcode[maxindex]);
    #	comments["usedcodeDescription"] := eval(usedcodeDescription[maxindex]);

        # find maximum of all loadcases, print results
        if WhateverYouNeed["calculations"]["suppress_gui"] = false then
            Write_eta(eta, comments);
            PrintAlert(warnings);
        end if;
    end proc:

end module: