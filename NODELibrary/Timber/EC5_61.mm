# EC5_612
# EC5_613
# EC5_614
# EC5_615
# calculate_k_c90
# EC5_615_EN
# EC5_615_NTI
# EC5_616
# EC5_617
# EC5_618

# 6.1.2 Tension parallel to the grain
EC5_612 := proc(WhateverYouNeed::table)
	description "6.1.2 Tension parallel to the grain";
	local A, sigma_t0d, eta, usedcode, comments, F_xd, f_t0d, loadcase;

	# define local variables
	f_t0d := WhateverYouNeed["materialdata"]["f_t0d"] * kh("f_t0d", WhateverYouNeed);
	loadcase := WhateverYouNeed["calculations"]["activesettings"]["activeloadcase"];
	F_xd := WhateverYouNeed["calculations"]["loadcases"][loadcase]["F_xd"];
	A := WhateverYouNeed["sectiondata"]["A"];
	
	sigma_t0d := convert(F_xd / A, 'units', 'N'/'mm^2');
	eta := evalf(sigma_t0d / f_t0d);
	usedcode := "6.1.2";
	comments := "Tension parallel to the grain";
	
	return eta, usedcode, comments
end proc:


# 6.1.3 Tension perpendicular to the grain
EC5_613 := proc(WhateverYouNeed::table)
	description "6.1.3 Tension perpendicular to the grain";
	local sigma_t90d, V0, eta, usedcode, comments, F_xd, b, h, l_615, f_t90d, loadcase;

	b := WhateverYouNeed["sectiondata"]["b"];
	h := WhateverYouNeed["sectiondata"]["h"];
	l_615 := WhateverYouNeed["calculations"]["structure"]["code_615"]["l_615"];
	f_t90d := WhateverYouNeed["materialdata"]["f_t90d"];
	loadcase := WhateverYouNeed["calculations"]["activesettings"]["activeloadcase"];
	F_xd := WhateverYouNeed["calculations"]["loadcases"][loadcase]["F_xd"];

	# Utvider sjekk med formel fra "Bautabellen"
	V0 := 0.01 * Unit('m^3');

	if l_615 <= 0 then
		Alert("6.1.3: Error: l_615 <= 0", WhateverYouNeed["warnings"], 3);
		return 9999, "6.1.3", "Error: l_615 <= 0"
	end if;	
	
	sigma_t90d := convert(evalf(F_xd / (b * l_615)), 'units', 'N'/'mm^2');
	eta := evalf(sigma_t90d / (f_t90d * (V0 / (b * h * l_615))^0.2));

	# usedcode := "6.1.3 Strekk vinkelrett p&aring; fiberretningen";
	usedcode := "6.1.3";
	comments := "Tension perpendicular to the grain";
	return eta, usedcode, comments
end proc:


# 6.1.4 Compression parallel to the grain
# Denne blir ikke brukt lenger, bruker 6.3.2 istedenfor, som sender saken videre til 6.2.4
EC5_614 := proc(WhateverYouNeed::table)
	description "6.1.4 Compression parallel to the grain";
	local A, sigma_c0d, eta, usedcode, comments, F_xd, f_c0d, loadcase;
	
	# define local variables
	f_c0d := WhateverYouNeed["materialdata"]["f_c0d"];
	loadcase := WhateverYouNeed["calculations"]["activesettings"]["activeloadcase"];
	F_xd := WhateverYouNeed["calculations"]["loadcases"][loadcase]["F_xd"];
	A := WhateverYouNeed["sectiondata"]["A"];
	
	sigma_c0d := convert(-F_xd / A, 'units', 'N'/'mm^2');
	eta := sigma_c0d / f_c0d;

	usedcode := "6.1.4";
	comments := "Compression parallel to the grain";
	return eta, usedcode, comments
end proc:


# 6.1.5 Compression perpendicular to the grain
EC5_615 := proc(WhateverYouNeed::table)
	description "6.1.5 Compression perpendicular to the grain";
	local eta_615_EN, eta_615_NTI, eta, usedcode, comments;

	eta_615_EN := EC5_615_EN(WhateverYouNeed);
	
	if eta_615_EN = -1 then			# geometry incomplete, return with error
		Alert("6.1.5: input geometry invalid", WhateverYouNeed["warnings"], 5);
		return eta_615_EN, "6.1.5", "input geometry invalid"
	end if;
	
	eta_615_NTI := EC5_615_NTI(WhateverYouNeed);

	if eta_615_EN <= eta_615_NTI then
		eta := eta_615_EN;
		usedcode := "6.1.5";
		comments := "Compression perpendicular to the grain, EN";
	else
		eta := eta_615_NTI;
		usedcode := "NA.6.1.5";
		comments := "Compression perpendicular to the grain, NTI";
	end if;
	
	return eta, usedcode, comments
end proc:


calculate_k_c90 := proc(WhateverYouNeed::table)
	local h, k_c90, type_615, l_615, l1_615, timbertype;

	# define local variables
	h := WhateverYouNeed["sectiondata"]["h"];
	
	type_615 := WhateverYouNeed["calculations"]["structure"]["code_615"]["type_615"];
	l_615 := WhateverYouNeed["calculations"]["structure"]["code_615"]["l_615"];
	l1_615 := WhateverYouNeed["calculations"]["structure"]["code_615"]["l1_615"];

	timbertype := WhateverYouNeed["materialdata"]["timbertype"];

	if l_615 <= 0 or l1_615 <= 0 then
		Alert("6.1.5: Error: l_615 eller l1_615 <= 0", WhateverYouNeed["warnings"], 5);
		return -1
	end if;
	
	k_c90 := 1;
	
	if type_615 = "a" and l1_615 >= 2*h then
		if timbertype = "Solid timber" then
			k_c90 := 1.25;
		elif timbertype = "Glued laminated timber" then
			k_c90 := 1.5;
		end if;
		
	elif type_615 = "b" and l1_615 >= 2*h then
		if timbertype = "Solid timber" then
			k_c90 := 1.5;
		elif timbertype = "Glued laminated timber" then
			if l_615 <= 400 * Unit('mm') then
				k_c90 := 1.75;
			end if;
		end if;
	end if;
	
	return k_c90
end proc:


EC5_615_EN := proc(WhateverYouNeed::table)
	description "Beregning iht. Eurocode, punkt 6.1.5";
	local b, sigma_c90d, l_ef_615, A_net, A_ef, F_c90d, f_c90d_mod, eta_EN, a, l, l1, k_c90, f_c90d, loadcase;

	# define local variables
	b := WhateverYouNeed["sectiondata"]["b"];
	
	a := WhateverYouNeed["calculations"]["structure"]["code_615"]["a_615"];
	l := WhateverYouNeed["calculations"]["structure"]["code_615"]["l_615"];
	l1 := WhateverYouNeed["calculations"]["structure"]["code_615"]["l1_615"];
	
	f_c90d := WhateverYouNeed["materialdata"]["f_c90d"];
	loadcase := WhateverYouNeed["calculations"]["activesettings"]["activeloadcase"];
	F_c90d := -WhateverYouNeed["calculations"]["loadcases"][loadcase]["F_xd"];		# vi snur fortegn for beregningen iht. standard
	
	# begin calculation
	if WhateverYouNeed["calculations"]["structure"]["code_615"]["type_615"] = "false" then
		Alert("6.1.5: Error - support undefined", WhateverYouNeed["warnings"], 5);
		return -1
	elif a = "false" or l = "false" or l1 = "false" then
		Alert("6.1.5: Error - a, l or l1 undefined", WhateverYouNeed["warnings"], 5);
		return -1
	end if;
	
	if l <= 0 then
		Alert("6.1.5: Error: l <= 0", WhateverYouNeed["warnings"], 5);
		return -1
	end if;	

	l_ef_615 := l + min(2 * 30 * Unit('mm'), a + 30 * Unit('mm'), l + 30 * Unit('mm'), l1/2 + 30 * Unit('mm'));
	A_net := l * b;
	A_ef := l_ef_615 * b;

	sigma_c90d := convert(F_c90d / A_ef, 'units', 'N'/'mm^2');

	k_c90 := calculate_k_c90(WhateverYouNeed);		# beregner k_c90
	f_c90d_mod := convert(k_c90 * f_c90d, 'units', 'N'/'mm^2');
	
	eta_EN := sigma_c90d / f_c90d_mod;

	if ComponentExists("TextArea_k_c90") and ComponentExists("MathContainer_Anet") and ComponentExists("MathContainer_Aef")
	and ComponentExists("MathContainer_f_c90d_mod") and ComponentExists("MathContainer_sigma_c90d") and ComponentExists("TextArea_eta615_EN") then
		HighlightResults(WhateverYouNeed["componentvariables"]["var_resultsdetails"]["6.1.5"], "highlight");
		SetProperty("TextArea_k_c90", value, k_c90);
		SetProperty("MathContainer_Anet", value, round2(evalf(convert(A_net, 'units', 'mm^2')), 1));
		SetProperty("MathContainer_Aef", value, round2(evalf(convert(A_ef, 'units', 'mm^2')), 1));
		SetProperty("MathContainer_f_c90d_mod", value, round2(evalf(f_c90d_mod), 1));
		SetProperty("MathContainer_sigma_c90d", value, round2(evalf(sigma_c90d), 1));
		SetProperty("TextArea_eta615_EN", value, round2(eta_EN,2));
		if eta_EN > 1 then 
			SetProperty("TextArea_eta615_EN", 'fontcolor', "Red");
		elif eta_EN > 0.9 then
			SetProperty("TextArea_eta615_EN", 'fontcolor', "Orange");
		else
			SetProperty("TextArea_eta615_EN", 'fontcolor', "Green");
		end if;
	end if;
	
	return eta_EN
end proc:


EC5_615_NTI := proc(WhateverYouNeed::table)
	description "Beregning iht NT rapport 86";
	local b, h, A_net, f_c90k_mod, f_c90d_mod, k_c90_mod, sigma_c90d, eta_NTI, a, l, l1, strengthclass, F_c90d, type_opplegg, loadcase, gamma_M, k_mod;

	# define local variables
	b := WhateverYouNeed["sectiondata"]["b"];
	h := WhateverYouNeed["sectiondata"]["h"];

	type_opplegg := WhateverYouNeed["calculations"]["structure"]["code_615"]["type_615"];
	a := WhateverYouNeed["calculations"]["structure"]["code_615"]["a_615"];
	l := WhateverYouNeed["calculations"]["structure"]["code_615"]["l_615"];
	l1 := WhateverYouNeed["calculations"]["structure"]["code_615"]["l1_615"];
	
	strengthclass := WhateverYouNeed["materialdata"]["strengthclass"];
	gamma_M := WhateverYouNeed["materialdata"]["gamma_M"];
	
	loadcase := WhateverYouNeed["calculations"]["activesettings"]["activeloadcase"];
	F_c90d := -WhateverYouNeed["calculations"]["loadcases"][loadcase]["F_xd"];		# vi snur fortegn for beregningen iht. standard

	k_mod := kmod(WhateverYouNeed["materialdata"]["loaddurationclass"], WhateverYouNeed["materialdata"]["serviceclass"]);

	# calculations
	A_net := l * b;

	sigma_c90d := convert(F_c90d / A_net, 'units', 'N'/'mm^2');
	
	if strengthclass = "C14" or strengthclass = "C16" then
		f_c90k_mod := 4.3 * Unit('N' / 'mm^2')
	elif strengthclass = "C18" or strengthclass = "C20" or strengthclass = "C22" then
		f_c90k_mod := 4.8 * Unit('N' / 'mm^2')
	elif strengthclass = "C24" or strengthclass = "C27" then
		f_c90k_mod := 5.3 * Unit('N' / 'mm^2')
	elif strengthclass = "C30" or strengthclass = "C35" or strengthclass = "C40" or strengthclass = "C45" or strengthclass = "C50" then
		f_c90k_mod := 5.7 * Unit('N' / 'mm^2')
	elif strengthclass = "GL 28c" then
		f_c90k_mod := 5.3 * Unit('N' / 'mm^2')
	elif strengthclass = "CE L40c" then
		f_c90k_mod := 5.7 * Unit('N' / 'mm^2')		
	elif strengthclass = "GL 30c" then
		f_c90k_mod := 5.5 * Unit('N' / 'mm^2')		
	elif strengthclass = "GL 32c" then
		f_c90k_mod := 5.7 * Unit('N' / 'mm^2')		
	elif strengthclass = "GL 28h" then
		f_c90k_mod := 5.3 * Unit('N' / 'mm^2')		
	elif strengthclass = "GL 30h" then
		f_c90k_mod := 5.5 * Unit('N' / 'mm^2')		
	elif strengthclass = "GL 32h" then
		f_c90k_mod := 5.7 * Unit('N' / 'mm^2')	
	else
		f_c90k_mod := 0
	end if;

	if l1 < 150 * Unit('mm') or l >= 150 * Unit('mm') then
		k_c90_mod := 1
	else
		if a >= 100 * Unit('mm') then		# kan ogs� v�re 0
			if l < 15 * Unit('mm') then
				k_c90_mod := 1.8
			else
				k_c90_mod := 1 + (150 * Unit('mm') - l) / (170 * Unit('mm'))
			end if
		else
			if l < 15 * Unit('mm') then
				k_c90_mod := 1 + a / (125 * Unit('mm'))
			else
				k_c90_mod := 1 + a * (150 * Unit('mm') - l) / (17000 * Unit('mm^2'))
			end if
		end if;
	end if;

	# f_c90d_mod := convert(k_c90_mod * f_c90d * f_c90k_mod / f_c90k, 'units', 'N'/'mm^2');
	f_c90d_mod := k_c90_mod * f_c90k_mod * k_mod / gamma_M;

	if type_opplegg = "b" and a < h then
		f_c90d_mod := f_c90d_mod / 2
	end if;

	if f_c90d_mod > 0 then
		eta_NTI := sigma_c90d / f_c90d_mod
	else 
		eta_NTI := 9999
	end if;

	if ComponentExists("MathContainer_NTI_f_c90d_mod") and ComponentExists("MathContainer_NTI_sigma_c90d") and ComponentExists("TextArea_eta615_NTI") then
		HighlightResults(WhateverYouNeed["componentvariables"]["var_resultsdetails"]["6.1.5"], "highlight");
		SetProperty("MathContainer_NTI_f_c90d_mod", value, round2(evalf(f_c90d_mod), 1));
		SetProperty("MathContainer_NTI_sigma_c90d", value, round2(evalf(sigma_c90d), 1));
		SetProperty("TextArea_eta615_NTI", value, round2(eta_NTI,2));
		if eta_NTI > 1 then 
			SetProperty("TextArea_eta615_NTI", 'fontcolor', "Red");
		elif eta_NTI > 0.9 then
			SetProperty("TextArea_eta615_NTI", 'fontcolor', "Orange");
		else
			SetProperty("TextArea_eta615_NTI", 'fontcolor', "Green");
		end if;
	end if;

	return eta_NTI
end proc:


# 6.1.6 Bending
# code including torsional buckling
# code including tapered beams
EC5_616 := proc(WhateverYouNeed::table, k_crity, k_critz)
	description "6.1.6 Bending";
	local k_m_alpha, k_r, k_l;		# factors for special constructions 6.4 (tapered and curved beams)
	local W_y, W_z;
	local sigma_myd, sigma_mzd, km, eta, usedcode, comments, M_yd, M_zd, f_md, f_myd, f_mzd, loadcase;

	# define local variables
	f_md := WhateverYouNeed["materialdata"]["f_md"];

	W_y := WhateverYouNeed["sectiondata"]["W_y"];
	W_z := WhateverYouNeed["sectiondata"]["W_z"];
	
	loadcase := WhateverYouNeed["calculations"]["activesettings"]["activeloadcase"];
	M_yd := WhateverYouNeed["calculations"]["loadcases"][loadcase]["M_yd"];
	M_zd := WhateverYouNeed["calculations"]["loadcases"][loadcase]["M_zd"];

	k_m_alpha := WhateverYouNeed["results"]["k_64"]["k_m_alpha"];		# 6.4.2 single tapered beam
	k_r := WhateverYouNeed["results"]["k_64"]["k_r"];					# 6.4.3 curved beam, pitched cambered beam
	k_l := WhateverYouNeed["results"]["k_64"]["k_l"];					# 6.4.3 double tapered beam

	# start calculation
	km := 0.7; 	# for konstruksjonstre, glulam og parallelfiner / rektangul�re tverrsnitt
	sigma_myd := convert(evalf(k_l * M_yd / W_y), 'units', 'N'/'mm^2');		# (6.42)
	sigma_mzd := convert(evalf(M_zd / W_z), 'units', 'N'/'mm^2');

	f_myd := k_m_alpha * k_r * k_crity * f_md * kh("h", WhateverYouNeed);
	f_mzd := k_critz * f_md * kh("b", WhateverYouNeed);
	
	eta := max(sigma_myd / f_myd + km * sigma_mzd / f_mzd, km * sigma_myd / f_myd + sigma_mzd / f_mzd);		# (6.11), (6.12)

	if k_crity = 1 and k_critz = 1 and k_m_alpha = 1 and k_r = 1 then 
		usedcode := "6.1.6";
		comments := "Bending";
		
	elif k_crity = 1 and k_critz = 1 and k_m_alpha <> 1 and k_r = 1 then
		usedcode := "6.4.2";
		comments := "Bending for single tapered beams";
		
	elif (k_crity <> 1 or k_critz <> 1) and k_m_alpha = 1 and k_r = 1 then 
		usedcode := "6.3.3";
		comments := "(6.33) Beams subjected to either bending or combined bending and compression";

	elif k_r = 1 and k_l = 1 then
		usedcode := "6.3.3 / 6.4.2";
		comments := "Single tapered beams subjected to either bending or combined bending and compression";

	else
		usedcode := "6.3.3 / 6.4.3";
		comments := "Curved or double tapered beams subjected to either bending or combined bending and compression";

	end if;

	if ComponentExists("TextArea_k_crity") then
		HighlightResults({"k_crity"}, "highlight");
		SetProperty("TextArea_k_crity", value, round2(k_crity, 2))
	end if;

	if ComponentExists("TextArea_k_critz") then
		HighlightResults({"k_critz"}, "highlight");
		SetProperty("TextArea_k_critz", value, round2(k_critz, 2))
	end if;
	
	return eta, usedcode, comments
end proc:


# 6.1.7 Shear / 6.5.2 Beams with a notch at the support
EC5_617 := proc(WhateverYouNeed::table)
	description "6.1.7 Shear";
	local kcr, tau_yd, tau_zd, h_ef, l_incl, endnotched, endnotchedType, k_v, k_v1, k_v2, i_652, alpha_652, kn, x_652, eta, usedcode, comments, V_yd, V_zd, b, h, timbertype, f_vd, A, loadcase;

	# define local variables
	b := WhateverYouNeed["sectiondata"]["b"];
	h := WhateverYouNeed["sectiondata"]["h"];
	A := WhateverYouNeed["sectiondata"]["A"];
		
	endnotched := WhateverYouNeed["calculations"]["structure"]["code_652"]["endnotched"];
	endnotchedType := WhateverYouNeed["calculations"]["structure"]["code_652"]["endnotchedType"];
	h_ef := WhateverYouNeed["calculations"]["structure"]["code_652"]["h_ef"];
	l_incl := WhateverYouNeed["calculations"]["structure"]["code_652"]["l_incl"];
	x_652 := WhateverYouNeed["calculations"]["structure"]["code_652"]["x_652"];

	timbertype := WhateverYouNeed["materialdata"]["timbertype"];
	f_vd := WhateverYouNeed["materialdata"]["f_vd"];

	loadcase := WhateverYouNeed["calculations"]["activesettings"]["activeloadcase"];
	V_yd := WhateverYouNeed["calculations"]["loadcases"][loadcase]["V_yd"];
	V_zd := WhateverYouNeed["calculations"]["loadcases"][loadcase]["V_zd"];

	# start calculation
	if timbertype = "Solid timber" then
		kcr := 0.67;		# for konstruksjonstre
		kn := 5			# (6.63)
	elif timbertype = "Glued laminated timber" then
		kcr := 0.8;		# glulam
		kn := 6.5			# (6.63)
	else
		kcr := 1;
		kn := 4.5			# (LVL, 6.63)
	end if;

	k_v := 1;		# setter default verdi i tilfelle det bare er skj�rkontroll

	# kontroll av innsnitt ved opplegg iht. 6.5.2
	if endnotched = "true" then	# beregner som bjelker med innsnitt ved opplegget
		
		if h_ef > 0 and l_incl >= 0 then
			if h_ef > h then
				Alert("6.5.2 check not passed: h_ef < h", WhateverYouNeed["warnings"], 3)
			else 
				if endnotchedType = "6.11(a)" then
					i_652 := evalf(l_incl / (h - h_ef));
					alpha_652 := evalf(h_ef / h);
					k_v1 := evalf(kn * (1 + 1.1 * i_652^1.5 / sqrt(convert(h, 'unit_free'))));
					k_v2 := evalf(sqrt(convert(h, 'unit_free')) * (sqrt(alpha_652 * (1 - alpha_652)) + 0.8 * x_652 / h * sqrt(1 / alpha_652 - alpha_652^2)));
					k_v := min(1, evalf(k_v1 / k_v2));
				else
					k_v := 1
				end if;				
			end if;			
		else
			Alert("6.5.2 check not passed: h_ef > 0, l_incl >= 0", WhateverYouNeed["warnings"], 3);
		end if;
		tau_yd := evalf(1.5 * V_yd / (kcr * b * h_ef));		# kcr not according to EC5, but calculations in Limtreboka, seems logic to me to reduce section, as no difference to 6.1.7
		tau_zd := evalf(1.5 * V_zd / (kcr * b * h_ef));
		
		# Eurocode gives no information about how to dimension sections with shear in 2 directions
		# eta := max(evalf(tau_yd / (k_v * f_vd)), evalf(tau_zd / (k_v * f_vd)));		# maximum of the 2 directions
		# eta := evalf(tau_yd / (k_v * f_vd) + tau_zd / (k_v * f_vd));				# add utilization of both directions linear
		eta := evalf(sqrt((tau_yd / (k_v * f_vd))^2 + (tau_zd / (k_v * f_vd))^2));		# add utilization of both directions vectortype (see also Limtreboka)
		

		usedcode := "6.5.2";
		comments := "Beams with a notch at the support";
	else		
		# general shear check
		tau_yd := evalf(1.5 * V_yd / (kcr * A));
		tau_zd := evalf(1.5 * V_zd / (kcr * A));
		
		# eta := max(evalf(tau_yd / f_vd), evalf(tau_zd / f_vd));	# maximum of the 2 directions
		# eta := evalf(tau_yd / f_vd + tau_zd / f_vd);			# add utilization of both directions linear
		eta := evalf(sqrt((tau_yd / f_vd)^2 + (tau_zd / f_vd)^2));	# add utilization of both directions vectortype (see also Limtreboka)

		usedcode := "6.1.7";
		comments := "Shear";
	end if;

	
	if ComponentExists("TextArea_kcr") and ComponentExists("TextArea_kn") and ComponentExists("TextArea_kv") then 
		HighlightResults(WhateverYouNeed["componentvariables"]["var_resultsdetails"]["6.1.7"], "highlight");
		SetProperty("TextArea_kcr", value, round2(kcr, 2));
		SetProperty("TextArea_kn", value, round2(kn, 2));
		SetProperty("TextArea_kv", value, round2(k_v, 2));
	end if;
	
	return eta, usedcode, comments
end proc:


# 6.1.8 Torsjon
EC5_618 := proc(WhateverYouNeed::table)
	description "6.1.8 Torsion";
	local tau_tord, k_shape, eta, usedcode, comments, M_td, b, h, f_vd, I_t, loadcase;

	# define local variables
	b := WhateverYouNeed["sectiondata"]["b"];
	h := WhateverYouNeed["sectiondata"]["h"];
	I_t := WhateverYouNeed["sectiondata"]["I_t"];

	f_vd := WhateverYouNeed["materialdata"]["f_vd"];
	
	loadcase := WhateverYouNeed["calculations"]["activesettings"]["activeloadcase"];
	M_td := WhateverYouNeed["calculations"]["loadcases"][loadcase]["M_td"];

	# start calculation
	# a_ := max(b, h);
	# b_ := min(b, h);
	# It := 1/3 * a_ * b_^3 * (1 - 0.63 * b_ / a_); 		# denne ble allerede beregnet tidligere
	tau_tord := convert(M_td * min(b, h) / I_t, 'units', 'N'/'mm^2');
	
	k_shape := min(1 + 0.15 * max(h, b) / min(h, b), 2);	# for rektangul�re tverrsnitt

	eta := tau_tord / (k_shape * f_vd);

	usedcode := "6.1.8";
	comments := "Torsion";

	if ComponentExists("MathContainer_tau_tord") and ComponentExists("TextArea_k_shape") and ComponentExists("MathContainer_ksh_fvd") then
		HighlightResults(WhateverYouNeed["componentvariables"]["var_resultsdetails"]["6.1.8"], "highlight");
		SetProperty("MathContainer_tau_tord", value, round2(evalf(tau_tord), 1));
		SetProperty("TextArea_k_shape", value, round2(evalf(k_shape), 1));
		SetProperty("MathContainer_ksh_fvd", value, round2(evalf(k_shape * f_vd), 1));
	end if;
	
	return eta, usedcode, comments
end proc: