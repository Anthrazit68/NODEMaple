# NODETimber - EC5_6

# InitSpecific
# ResetSpecific
# MainWrapper
# ReadComponentsSpecific
# Main
# activateComponents_64

InitSpecific := proc()
	description "Specific initialization values";
	global WhateverYouNeed;
	local var_calculations, var_numeric, var_resultdetails;	

	WhateverYouNeed["calculations"]["calculationtype_short"] := "Eurocode 5 part 1-1 ULS";		# for export to Excel
	
	var_calculations := {"positionnumber", "positiontitle", "activeloadcase", "activematerial", "activesection", "timbertype", "b", "h", "strengthclass", "serviceclass", "loaddurationclass", "l_ky", "l_kz", "l_efy", "l_efz"
					"type_615", "a_615", "l_615", "l1_615", "h_622", "ConstructionType", "alpha_ap", "r_in", "l_curve", "t_lam", "tapered_N", "endnotched", "endnotchedType", "h_ef", "l_incl", "x_652"};

	# all variables starting with those values are numeric
	var_numeric := {"l_ky", "l_kz", "l_efy", "l_efz", "a_615", "l_615", "l1_615", "h_622", "alpha_ap", "r_in", "l_curve", "t_lam", "h_ef", "l_inc", "x_652"};

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


ResetSpecific := proc(WhateverYouNeed::table)
	description "Reset specific values for calculation";

	# resetting Combobox for materials and sections
	SetProperty("ComboBox_timbertype", 'selectedindex', 0);		# Solid timber
	MainCommon("timbertype");								# setting C14, 36x98
	SetProperty("ComboBox_serviceclass", 'selectedindex', 0);		# Service class 1
	SetProperty("ComboBox_loaddurationclass", 'selectedindex', 0);	# Load-duration class Permanent
	SetProperty("ComboBox_materials", 'itemlist', [GetProperty("TextArea_activematerial", value)]);
	SetProperty("ComboBox_sections", 'itemlist', [GetProperty("TextArea_activesection", value)]);
	ModifyComboVariables("ComboBox_materials", "Add", WhateverYouNeed["materials"], WhateverYouNeed["materialdata"]);
	ModifyComboVariables("ComboBox_sections", "Add", WhateverYouNeed["sections"], WhateverYouNeed["sectiondata"]);
end proc:


RunAfterRestoresettings := proc(WhateverYouNeed::table)
	activateComponents_64();
end proc:


# wrapper for running main calculation routine
MainWrapper := proc(action::string)
	description "Run main calculation";
	global WhateverYouNeed;
	
	# start calculation if either required by command or autoloadsave true
	if action = "calculation" or WhateverYouNeed["calculations"]["autocalc"] then
		# try to always use this order of parameter when calling procedures
		# TypeOfAction, section, structure, materialdataAll, loadcases[loadcase], sectionpropertiesAll, warnings, comments
		Main(WhateverYouNeed);
	end if;
end proc:


# this one is started by ReadSystemSection
ReadComponentsSpecific := proc(TypeOfAction::string, WhateverYouNeed::table)
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
				assign('a_615', parse(GetProperty("TextArea_a_615", value)) * Unit('mm'));		# String, m� konverteres til tall
			else
				assign('a_615', "false");		# String, m� konverteres til tall
			end if;
			code_615["a_615"] := a_615;	
		end if;

		if ComponentExists("TextArea_l_615") then
			if GetProperty("TextArea_l_615", 'enabled') = "true" then
				assign('l_615', parse(GetProperty("TextArea_l_615", value)) * Unit('mm'));		# String, m� konverteres til tall
			else
				assign('l_615', "false");		# String, m� konverteres til tall
			end if;
			code_615["l_615"] := l_615;
		end if;

		if ComponentExists("TextArea_l1_615") then
			if GetProperty("TextArea_l1_615", 'enabled') = "true" then
				assign('l1_615', parse(GetProperty("TextArea_l1_615", value)) * Unit('mm'));		# String, m� konverteres til tall
			else
				assign('l1_615', "false");		# String, m� konverteres til tall
			end if;
			code_615["l1_615"] := l1_615;
		end if;

		# 6.1.5
		structure["code_615"] := eval(code_615);
	end if;

	# 6.2.2 compression at an angle to the grain
	if TypeOfAction = "all" or TypeOfAction = "section" or TypeOfAction = "sections" or searchtext("Load", TypeOfAction) > 0 or searchtext("622", TypeOfAction) > 0 then
		SetProperty("MathContainer_b", value, sectiondata["b"]);
		alpha_622 := GetProperty("Slider_alpha", value) * Unit('degree');
		SetProperty("MathContainer_alpha", value, alpha_622);
		if cos(alpha_622) <> 0 then
			SetProperty("MathContainer_h_sin_alpha", 'visible', "true");
			SetProperty("MathContainer_h_sin_alpha", value, round2(evalf(sectiondata["h"] / cos(alpha_622)), 0));
			if TypeOfAction = "622->" then
				SetProperty("TextArea_h_622", value, round2(convert(evalf(sectiondata["h"] / cos(alpha_622)), 'unit_free'), 0));
			end if;
		else
			SetProperty("MathContainer_h_sin_alpha", 'visible', "false");
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
			NODETimberEN1995:-calculate_k_64(WhateverYouNeed);
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


# Main calculation routine
Main := proc(WhateverYouNeed::table)
	description "Beregner utnyttelsesgrader for dimensjonering";
	uses NODETimberEN1995;
	local force, activeloadcase, eta, usedcode, comments, structure, warnings, maxindex, usedcodeDescription;
	local alpha, F_xd, M_yd, M_zd, V_yd, V_zd, M_td;

	# declare local variables
	activeloadcase := WhateverYouNeed["calculations"]["activesettings"]["activeloadcase"];
	force := eval(WhateverYouNeed["calculations"]["loadcases"][activeloadcase]);
	structure := WhateverYouNeed["calculations"]["structure"];
	warnings := WhateverYouNeed["warnings"];	

	eta := table();
	usedcode := table();
	usedcodeDescription := table();
	comments := table();	
	
	WhateverYouNeed["results"]["eta"] := eta;			# reset eta
	WhateverYouNeed["results"]["usedcode"] := usedcode;
	WhateverYouNeed["results"]["usedcodeDescription"] := usedcodeDescription;
	WhateverYouNeed["results"]["comments"] := comments;	

	# when running calculation of singular loadcase, global utilization values might not be correct anymore
	SetProperty("TextArea_etamax_max", 'enabled', "false");
	SetProperty("TextArea_loadcaseMax", 'enabled', "false");
	SetProperty("TextArea_warningsAll", 'enabled', "false");

	# deactivate detail results
	HighlightResults(WhateverYouNeed["componentvariables"]["var_resultsdetails"], "deactivate");

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
			eta["612"], usedcode["612"], usedcodeDescription["612"] := EC5_612(WhateverYouNeed)
		end if;
			
		if F_xd <= 0 and M_yd = 0 and M_zd = 0 then	# 6.1.4 compression parallel to the grain
			# eta[1], usedcode[1] := EC5_614(A, f_c0d, force)
			eta["614"], usedcode["614"], usedcodeDescription["614"] := EC5_63(WhateverYouNeed)		# forward to buckling calculation
		end if;
			
		if F_xd >= 0 and (M_yd <> 0 or M_zd <> 0) then	# 6.2.3 combined bending and axial tension
			eta["623"], usedcode["623"], usedcodeDescription["623"] := EC5_623(WhateverYouNeed)
		end if;
		
		if F_xd <= 0 and (M_yd <> 0 or M_zd <> 0) then	# 6.2.4 combined bending and axial compression
			eta["624"], usedcode["624"], usedcodeDescription["624"] := EC5_63(WhateverYouNeed)		# forward to buckling and torsional buckling calculation
		end if;
	end if;
	
	if alpha = 90 * Unit('degrees') then
		if F_xd >= 0 and M_yd = 0 and M_zd = 0 then	# 6.1.3 tension perpendicular to the grain
			eta["613"], usedcode["613"], usedcodeDescription["613"] := EC5_613(WhateverYouNeed)
		end if;
		
		if F_xd <= 0 and M_yd = 0 and M_zd = 0 then	# 6.1.5 compression perpendicular to the grain
			eta["615"], usedcode["615"], usedcodeDescription["615"] := EC5_615(WhateverYouNeed)
		end if;
	end if;

	# 6.2.2 compression stresses at an angle to the grain
	if alpha > 0 and alpha < 90 * Unit('degrees') and F_xd <= 0 and M_yd = 0 and M_zd = 0 then	
		eta["622"], usedcode["622"], usedcodeDescription["622"] := EC5_622(WhateverYouNeed)
	end if;	

	# 2. alpha not relevant
	# 6.1.6 Bending
	if F_xd = 0 and (M_yd <> 0 or M_zd <> 0) then	
		# EC5_616()
		# sender videre til formel som tar med vipping og knekking
		# denne sjekker mot 6.1.6, 6.2.4 og (6.35)
		eta["616"], usedcode["616"], usedcodeDescription["616"] := EC5_63(WhateverYouNeed)
	end if;

	# 6.1.7 shear
	if V_yd <> 0 or V_zd <> 0 then	
		eta["617"], usedcode["617"], usedcodeDescription["617"] := EC5_617(WhateverYouNeed)
	end if;

	# 6.1.8 Torsjon
	if M_td <> 0 and M_yd = 0 and M_zd = 0 and F_xd = 0 then	
		eta["618"], usedcode["618"], usedcodeDescription["618"] := EC5_618(WhateverYouNeed)
	end if;

	# 3. check if there is a special construction
	if member(structure["code_64"]["ConstructionType"], {"Double tapered beam", "Curved beam", "Pitched cambered beam"}) then
		eta["643"], usedcode["643"], usedcodeDescription["643"] := EC5_643(WhateverYouNeed);			# sjekker f�rst iht. 6.4.3, deretter med vanlige formler
	end if;
	
	eta["max"], maxindex := maxIndexTable(eta);
	comments["usedcode"] := eval(usedcode[maxindex]);		# results["usedcode"]
	comments["usedcodeDescription"] := eval(usedcodeDescription[maxindex]);

	# find maximum of all loadcases, print results
	Write_eta(WhateverYouNeed);	
	
end proc:


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