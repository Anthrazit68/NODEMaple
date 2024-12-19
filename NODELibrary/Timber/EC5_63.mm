# EC5_63.mm : Eurocode 5 chapter 6.3
# Copyright (C) 2024  Andreas Zieritz

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


# EC5_63
# calculate_k_64

# 6.3.2 columns subjected to either compression or combined compression and bending
# 6.3.3 beams subjected to either bending or combined bending and compression

EC5_63 := proc(WhateverYouNeed::table)
	description "Checking columns and beams subjected to bending and compression";
	local E_m0k, f_c0k, f_c0d, f_md, f_mk, G_005;
	local b, h, timbertype, l_ky, l_kz, l_efy, l_efz, F_xd, M_yd, M_zd;
	local ky, kz, k_cy, k_cz, beta_c, lambda_y, lambda_z, lambda_rely, lambda_relz;
	local sigma_mcrity, sigma_mcritz, lambda_relmy, lambda_relmz, k_crity, k_critz, sigma_myd, sigma_mzd, sigma_c0d;
	local eta, usedcode, usedcodeDescription, max_index, max_eta;
	local i_y, i_z, W_y, W_z, A, I_z, I_y, I_t, loadcase;

	eta := WhateverYouNeed["results"]["eta"];
	usedcode := WhateverYouNeed["results"]["usedcode"];
	usedcodeDescription := WhateverYouNeed["results"]["usedcodeDescription"];			
	max_index := 0;

	# define local variables
	l_ky := WhateverYouNeed["calculations"]["structure"]["buckling"]["l_ky"];
	l_kz := WhateverYouNeed["calculations"]["structure"]["buckling"]["l_kz"];
	l_efy := WhateverYouNeed["calculations"]["structure"]["buckling"]["l_efy"];
	l_efz := WhateverYouNeed["calculations"]["structure"]["buckling"]["l_efz"];

	timbertype := WhateverYouNeed["materialdata"]["timbertype"];
	E_m0k := WhateverYouNeed["materialdata"]["E_m0k"];
	f_c0k := WhateverYouNeed["materialdata"]["f_c0k"];
	f_c0d := WhateverYouNeed["materialdata"]["f_c0d"];
	f_md := WhateverYouNeed["materialdata"]["f_md"];
	f_mk := WhateverYouNeed["materialdata"]["f_mk"];
	G_005 := WhateverYouNeed["materialdata"]["G_005"];

	loadcase := WhateverYouNeed["calculations"]["activesettings"]["activeloadcase"];
	F_xd := WhateverYouNeed["calculations"]["loadcases"][loadcase]["F_xd"];
	M_yd := WhateverYouNeed["calculations"]["loadcases"][loadcase]["M_yd"];
	M_zd := WhateverYouNeed["calculations"]["loadcases"][loadcase]["M_zd"];

	b := WhateverYouNeed["sectiondata"]["b"];
	h := WhateverYouNeed["sectiondata"]["h"];
	i_y := WhateverYouNeed["sectiondata"]["i_y"];
	i_z := WhateverYouNeed["sectiondata"]["i_z"];
	W_y := WhateverYouNeed["sectiondata"]["W_y"];
	W_z := WhateverYouNeed["sectiondata"]["W_z"];
	I_z := WhateverYouNeed["sectiondata"]["I_z"];
	I_y := WhateverYouNeed["sectiondata"]["I_y"];
	I_t := WhateverYouNeed["sectiondata"]["I_t"];
	A := WhateverYouNeed["sectiondata"]["A"];

	# start  calculation
	# 6.3.2(1) buckling
	lambda_y := l_ky / i_y;
	lambda_z := l_kz / i_z;
	lambda_rely := evalf(lambda_y / Pi * sqrt(f_c0k/E_m0k));		# (6.21)
	lambda_relz := evalf(lambda_z / Pi * sqrt(f_c0k/E_m0k));		# (6.22)

	if ComponentExists("TextArea_lambda_rely") and ComponentExists("TextArea_lambda_relz") then
		HighlightResults({"lambda_rely", "lambda_relz"}, "highlight");
		SetProperty("TextArea_lambda_rely", 'value', round2(lambda_rely,2));
		SetProperty("TextArea_lambda_relz", 'value', round2(lambda_relz,2))
	end if;

	if lambda_rely < 0.3 and lambda_relz < 0.3 then 	
		# no buckling check necessary		6.3.2 (2)
		k_cy := 1;
		k_cz := 1;
	else
		if timbertype = "Solid timber" then
			beta_c := 0.2
		elif timbertype = "Glued laminated timber" then
			beta_c := 0.1
		else
			beta_c := 0
		end if;

		# check buckling in both axis
		ky := 0.5 * (1 + beta_c*(lambda_rely - 0.3) + lambda_rely^2);		# (6.27)
		kz := 0.5 * (1 + beta_c*(lambda_relz - 0.3) + lambda_relz^2);		# (6.28)
		k_cy := 1 / (ky + sqrt(ky^2 - lambda_rely^2));					# (6.25)
		k_cz := 1 / (kz + sqrt(kz^2 - lambda_relz^2));					# (6.26)		
	end if;
	if ComponentExists("TextArea_k_cy") and ComponentExists("TextArea_k_cz") then
		HighlightResults({"k_cy", "k_cz"}, "highlight");
		SetProperty("TextArea_k_cy", 'value', round2(k_cy,2));
		SetProperty("TextArea_k_cz", 'value', round2(k_cz,2))
	end if;

	# 6.2.4
	eta["624"], usedcode["624"], usedcodeDescription["624"] := EC5_624(WhateverYouNeed, k_cy, k_cz);		# beregner kapasitet med utvidet formel fra 6.2.4
	# if ComponentExists("TextArea_eta_624") then
	#	HighlightResults({"eta_624"}, "highlight");
	#	SetProperty("TextArea_eta_624", 'value', round2(eta["624"], 2))
	# end if;

	# 6.3.3
	# Beams subjected to either bending or combined bending and compression
	# sigma_mcrity := Pi * sqrt(E_m0k * I_z * G_005 * I_t) / (l_efy * W_y);		# 6.31
	# sigma_mcritz := Pi * sqrt(E_m0k * I_y * G_005 * I_t) / (l_efz * W_z);		# 6.31

	# alternative formula for softwood with solid rectangular cross-section
	sigma_mcrity := 0.78 * b^2 / (h * l_efy) * E_m0k;		# (6.32)
	sigma_mcritz := 0.78 * h^2 / (b * l_efz) * E_m0k;		# (6.32)

	# sigma_mcrity := 0.78 * b^2 / (h * l_efy) * E_m0k;					# 6.32
	# sigma_mcritz := 0.78 * h^2 / (b * l_efz) * E_m0k;					# 6.32, extended for moment around z-axis
	
	lambda_relmy := evalf(sqrt(f_mk / sigma_mcrity));						# 6.30
	lambda_relmz := evalf(sqrt(f_mk / sigma_mcritz));						# 6.30, extended for moment around z-axis

	# (6.34)
	if lambda_relmy <= 0.75 then
		# ingen fare for vipping
		k_crity := 1
	elif lambda_relmy <= 1.4 then
		k_crity := 1.56 - 0.75 * lambda_relmy;
	else 
		k_crity := 1 / lambda_relmy^2
	end if;

	if lambda_relmz <= 0.75 then
		# ingen fare for vipping
		k_critz := 1
	elif lambda_relmz <= 1.4 then
		k_critz := 1.56 - 0.75 * lambda_relmz;
	else 
		k_critz := 1 / lambda_relmz^2
	end if;

	if ComponentExists("TextArea_lambda_relmy") then
		HighlightResults({"lambda_relmy"}, "highlight");
		SetProperty("TextArea_lambda_relmy", 'value', round2(lambda_relmy,2))
	end if;
	if ComponentExists("TextArea_lambda_relmz") then
		HighlightResults({"lambda_relmz"}, "highlight");
		SetProperty("TextArea_lambda_relmz", 'value', round2(lambda_relmz,2))
	end if;

	# 6.1.6
	# calculating capacity with extended formula for bending chapter 6.1.6 (6.11 + 6.12)
	eta["616"], usedcode["616"], usedcodeDescription["616"] := EC5_616(WhateverYouNeed, k_crity, k_critz);		
	# if ComponentExists("TextArea_eta_616") then
	#	HighlightResults({"eta_616"}, "highlight");
	#	SetProperty("TextArea_eta_616", 'value', round2(eta["616"],2))
	# end if;

	sigma_c0d := convert(-F_xd / A, 'units', 'N'/'mm^2');
	sigma_myd := convert(M_yd / W_y, 'units', 'N'/'mm^2');
	sigma_mzd := convert(M_zd / W_z, 'units', 'N'/'mm^2');
	
	eta["633"] := (sigma_myd / (k_crity * f_md * kh("h", WhateverYouNeed)))^2 + (sigma_mzd / (k_critz * f_md * kh("b", WhateverYouNeed)))^2 + sigma_c0d / (k_cz * f_c0d);		# (6.35), modified
	usedcode["633"] := "6.3.3";
	usedcodeDescription["633"] := "Beams subjected to either bending or combined bending and compression";
	
	# if ComponentExists("TextArea_eta_633") then
	#	HighlightResults({"eta_633"}, "highlight");
	#	SetProperty("TextArea_eta_633", 'value', round2(eta["633"],2))
	# end if;

	max_index := indices(eta, 'nolist')[max[index](convert(eta, list))];		# have to convert table to list, get the index position, and get the index name of the index
	# max_index := indices(eta, 'nolist')[maxindex(convert(eta, list))];		# have to convert table to list, get the index position, and get the index name of the index
	
	# return eta[max_index], cat("6.3 / ", usedcode[max_index]), comments[max_index]
	max_eta, max_index := maxIndexTable(table(["624" = eta["624"], "616" = eta["616"], "633" = eta["633"]]));
	return max_eta, cat("6.3 / ", eval(usedcode[max_index])), eval(usedcodeDescription[max_index])
	
end proc:


calculate_k_64 := proc(WhateverYouNeed::table)
	description "Beregner diverse k-verdier for konstruksjoner i kapittel 6.4";
	local k1, k2, k3, k4, k5, k6, k7, r, V;
	local A, h, b;
	local timbertype, f_md, f_c90d, f_t90d, f_vd;
	local ConstructionType, r_in, t_lam, l_curve, alpha_ap;
	local k_dis, k_l, k_m_alpha, k_p, k_r, k_vol, tapered_N;
	local k_64;

	# define local variables
	b := WhateverYouNeed["sectiondata"]["b"];
	h := WhateverYouNeed["sectiondata"]["h"];
	A := WhateverYouNeed["sectiondata"]["A"];

	timbertype := WhateverYouNeed["materialdata"]["timbertype"];
	f_md := WhateverYouNeed["materialdata"]["f_md"] * kh("h", WhateverYouNeed);
	f_c90d := WhateverYouNeed["materialdata"]["f_c90d"];
	f_t90d := WhateverYouNeed["materialdata"]["f_t90d"];
	f_vd := WhateverYouNeed["materialdata"]["f_vd"];

	ConstructionType := WhateverYouNeed["calculations"]["structure"]["code_64"]["ConstructionType"];
	alpha_ap := WhateverYouNeed["calculations"]["structure"]["code_64"]["alpha_ap"];
	r_in := WhateverYouNeed["calculations"]["structure"]["code_64"]["r_in"];
	t_lam := WhateverYouNeed["calculations"]["structure"]["code_64"]["t_lam"];
	l_curve := WhateverYouNeed["calculations"]["structure"]["code_64"]["l_curve"];
	tapered_N := WhateverYouNeed["calculations"]["structure"]["code_64"]["tapered_N"];

	# start calculations
	# k_m_alpha
	# if ConstructionType = "Single tapered beam" or ConstructionType = "Double tapered beam" or ConstructionType = "Pitched cambered beam" then		# Single tapered beam
	if ConstructionType = "Single tapered beam" then		# Single tapered beam
		if tapered_N = "tension" then
			k_m_alpha := evalf(1 / sqrt(1 + (f_md / (0.75 * f_vd) * tan(alpha_ap))^2 + (f_md / f_t90d * tan(alpha_ap)^2)^2));		# (6.40)
		elif tapered_N = "compression" then
			k_m_alpha := evalf(1 / sqrt(1 + (f_md / (1.5 * f_vd) * tan(alpha_ap))^2 + (f_md / f_c90d * tan(alpha_ap)^2)^2));		# (6.39)
		else
			k_m_alpha := 1
		end if;
	else
		k_m_alpha := 1
	end if;

	# k_p, k_r, k_l
	if ConstructionType = "-" or ConstructionType = "Single tapered beam" then
		k_p := 1;
		k_r := 1;
		k_l := 1;
		
	# 6.4.3 Double tapered beam, Curved beam og Pitched cambered beam
	else		
		if timbertype <> "Glued laminated timber" then
			Alert("6.4.3(1): This clause applies only to glued laminated timber and LVL.", WhateverYouNeed["warnings"], 2)
		end if;

		# k_l
		k1 := 1 + 1.4 * tan(alpha_ap) + 5.4 * (tan(alpha_ap))^2;			# (6.44)
		k2 := 0.35 - 8 * tan(alpha_ap);								# (6.45)
		k3 := 0.6 + 8.3 * tan(alpha_ap) - 7.8 * (tan(alpha_ap))^2;			# (6.46)
		k4 := 6 * (tan(alpha_ap))^2;									# (6.47)

		if ConstructionType = "Double tapered beam" then	# Double tapered beam
			k_l := evalf(k1);										# (6.43)
		else
			r := r_in + 0.5 * h;									# (6.48)	
			k_l := evalf(k1 + k2 * (h / r) + k3 * (h / r)^2 + k4 * (h / r)^3);	# (6.43)
		end if;

		# k_p
		k5 := 0.2 * tan(alpha_ap);									# (6.57)
		k6 := 0.25 - 1.5 * tan(alpha_ap) + 2.6 * (tan(alpha_ap))^2;			# (6.58)
		k7 := 2.1 * tan(alpha_ap) - 4 * (tan(alpha_ap))^2;				# (6.59)
		if ConstructionType = "Double tapered beam" then	# Double tapered beam
			k_p := evalf(k5);										# (6.56)
		else
			k_p := evalf(k5 + k6 * (h / r) + k7 * (h / r)^2);				# (6.56)
		end if;
		

		# k_r
		if timbertype = "Solid timber" or ConstructionType = "Double tapered beam" or ConstructionType = "-" then	# Double tapered beam	(6.49)
			k_r := 1
		elif evalf(r_in / t_lam) >= 240 then							# Curved beam og Pitched cambered beam
			k_r := 1
		else
			k_r := evalf(0.76 + 0.001 * r_in/t_lam)
		end if;		
	end if;

	# k_vol (6.51)
	if timbertype = "Solid timber" or ConstructionType = "Single tapered beam" or ConstructionType = "-" then
		k_vol := 1;
		V := 0
	else
		if ConstructionType = "Double tapered beam" then 
			V := convert(evalf(b * (h^2 - h^2 * tan(alpha_ap))), 'units', 'm^3');
		elif ConstructionType = "Curved beam" then 
			V := convert(evalf(l_curve * A), 'units', 'm^3');		# A = b * h
		elif ConstructionType = "Pitched cambered beam" then 
	 		V := convert(evalf((h + (h - l_curve/2 * tan(alpha_ap))) / 2 * b * l_curve), 'units', 'm^3'); 		
		end if;
		k_vol := convert((0.01 * Unit('m^3') / V), 'unit_free')^0.2;
	end if;
	
	# k_dis
	if ConstructionType = "Double tapered beam" or ConstructionType = "Curved beam" then
		k_dis := 1.4
	elif ConstructionType = "Pitched cambered beam" then
		k_dis := 1.7
	else 
		k_dis := 1
	end if;

	k_64 := table();
	k_64["k_dis"] := k_dis;
	k_64["k_l"] := k_l;
	k_64["k_m_alpha"] := k_m_alpha;
	k_64["k_p"] := k_p;
	k_64["k_r"] := k_r;
	k_64["k_vol"] := k_vol;
	k_64["V"] := V;

	if ComponentExists("TextArea_k_dis") and ComponentExists("TextArea_k_m_alpha") and ComponentExists("TextArea_k_l") and ComponentExists("TextArea_k_p") and ComponentExists("TextArea_k_r")
		and ComponentExists("TextArea_k_vol") and ComponentExists("TextArea_V") then 
			
		HighlightResults(WhateverYouNeed["componentvariables"]["var_resultsdetails"]["6.4"], "highlight");		# should always be active

		SetProperty("TextArea_k_dis", 'value', round2(k_64["k_dis"], 2));
		SetProperty("TextArea_k_m_alpha", 'value', round2(k_64["k_m_alpha"], 2));
		SetProperty("TextArea_k_l", 'value', round2(k_64["k_l"], 2));
		SetProperty("TextArea_k_p", 'value', round2(k_64["k_p"], 2));
		SetProperty("TextArea_k_r", 'value', round2(k_64["k_r"], 2));
		SetProperty("TextArea_k_vol", 'value', round2(k_64["k_vol"], 2));
		SetProperty("TextArea_V", 'value', round2(convert(k_64["V"], 'unit_free'), 2));
	end if;

	WhateverYouNeed["results"]["k_64"] := eval(k_64);
	# return eval(k_64)
end proc: