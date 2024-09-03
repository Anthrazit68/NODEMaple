# 6.2.2 trykkspenninger i vinkel p� fiberretning
EC5_622 := proc(WhateverYouNeed::table)
	description "6.2.2 trykkspenninger i vinkel p� fiberretning";
	local sigma_cad, f_cad, eta_622, usedcode, comments, F_xd, alpha, f_c0d, f_c90d, k_c90, A_622, loadcase, timbertype, h_622;

	f_c0d := WhateverYouNeed["materialdata"]["f_c0d"];
	f_c90d := WhateverYouNeed["materialdata"]["f_c90d"];
	timbertype := WhateverYouNeed["materialdata"]["timbertype"];

	loadcase := WhateverYouNeed["calculations"]["activesettings"]["activeloadcase"];
	alpha := WhateverYouNeed["calculations"]["loadcases"][loadcase]["alpha"];	# https://www.mapleprimes.com/questions/234028-Maple-2022--New-Bug-In-UnitsSimple?reply=reply
	F_xd := WhateverYouNeed["calculations"]["loadcases"][loadcase]["F_xd"];
	
	A_622 := WhateverYouNeed["results"]["A_622"];
	h_622 := WhateverYouNeed["calculations"]["structure"]["code_622"]["h_622"];

	# need to calculate k_c90 specific for this case
	k_c90 := 1;
	if timbertype = "Solid timber" then
		k_c90 := 1.5
	elif timbertype = "Glued laminated timber" then
		if h_622 <= 400 * Unit('mm') then
			k_c90 := 1.75	
		end if;
	end if;

	sigma_cad := convert(abs(evalf(F_xd / A_622)), 'units', 'N'/'mm^2');
	f_cad := convert(evalf(f_c0d / (f_c0d / (k_c90 * f_c90d) * (sin(alpha))^2 + (cos(alpha))^2)), 'units', 'N'/'mm^2');
	eta_622 := evalf(sigma_cad / f_cad);
	usedcode := "6.2.2";
	comments := "Compression stresses at an angle to the grain";

	# print stuff
	HighlightResults(WhateverYouNeed["componentvariables"]["var_resultsdetails"]["6.2.2"], "highlight");
	if ComponentExists("TextArea_k_c90") then
		SetProperty("TextArea_k_c90", value, round2(k_c90, 2))
	end if;
	if ComponentExists("MathContainer_A_622") then
		SetProperty("MathContainer_A_622", value, round2(A_622, 2))
	end if;
	
	if ComponentExists("MathContainer_sigma_cad") then
		SetProperty("MathContainer_sigma_cad", value, round2(sigma_cad, 2))
	end if;
	
	if ComponentExists("MathContainer_f_cad") then
		SetProperty("MathContainer_f_cad", value, round2(f_cad, 2))
	end if;
	
	# if ComponentExists("TextArea_eta_622") then
	# 	SetProperty("TextArea_eta_622", value, round2(eta_622, 2))
	# end if;
	
	return eta_622, usedcode, comments
end proc:


# 6.2.3 kombinert b�yning og aksialt strekk
EC5_623 := proc(WhateverYouNeed::table)
	description "6.2.3 kombinert b�yning og aksialt strekk";
	local sigma_t0d, sigma_myd, sigma_mzd, km, eta, usedcode, comments, F_xd, M_yd, M_zd, b, h, f_t0d, f_md, loadcase;

	# local variables
	b := WhateverYouNeed["sectiondata"]["b"];
	h := WhateverYouNeed["sectiondata"]["h"];

	f_t0d := WhateverYouNeed["materialdata"]["f_t0d"] * kh("f_t0d", WhateverYouNeed);
	f_md := WhateverYouNeed["materialdata"]["f_md"];

	loadcase := WhateverYouNeed["calculations"]["activesettings"]["activeloadcase"];
	F_xd := WhateverYouNeed["calculations"]["loadcases"][loadcase]["F_xd"];
	M_yd := WhateverYouNeed["calculations"]["loadcases"][loadcase]["M_yd"];
	M_zd := WhateverYouNeed["calculations"]["loadcases"][loadcase]["M_zd"];

	sigma_t0d := convert(F_xd / (b*h), 'units', 'N'/'mm^2');

	km := 0.7; 	# for konstruksjonstre, limtre og parallelfiner / rektangul�re tverrsnitt
	sigma_myd := convert(M_yd / (b * h^2 / 6), 'units', 'N'/'mm^2');
	sigma_mzd := convert(M_zd / (b^2 * h / 6), 'units', 'N'/'mm^2');
	
	eta := max(sigma_t0d / f_t0d + sigma_myd / (f_md * kh("h", WhateverYouNeed)) + km * sigma_mzd / (f_md * kh("b", WhateverYouNeed)),
	           sigma_t0d / f_t0d + km * sigma_myd / (f_md * kh("h", WhateverYouNeed)) + sigma_mzd / (f_md * kh("b", WhateverYouNeed)));

	# usedcode := "6.2.3 kombinert b&oslash;yning og aksialt strekk";
	usedcode := "6.2.3";
	comments := "Combined bending and axial tension";

	return eta, usedcode, comments
end proc:


# 6.2.4/6.3.2 kombinert b�yning og aksialt trykk
EC5_624 := proc(WhateverYouNeed::table, k_cy, k_cz)
	description "6.2.4/6.3.2 kombinert b�yning og aksialt trykk";
	local A, W_y, W_z, F_xd, M_yd, M_zd, sigma_c0d, sigma_myd, sigma_mzd, km, eta, usedcode, comments, f_c0d, f_md, loadcase;

	# define local variables
	eta := WhateverYouNeed["results"]["eta"];
	f_c0d := WhateverYouNeed["materialdata"]["f_c0d"];
	f_md := WhateverYouNeed["materialdata"]["f_md"];

	loadcase := WhateverYouNeed["calculations"]["activesettings"]["activeloadcase"];
	F_xd := WhateverYouNeed["calculations"]["loadcases"][loadcase]["F_xd"];
	M_yd := WhateverYouNeed["calculations"]["loadcases"][loadcase]["M_yd"];
	M_zd := WhateverYouNeed["calculations"]["loadcases"][loadcase]["M_zd"];

	A := WhateverYouNeed["sectiondata"]["A"];
	W_y := WhateverYouNeed["sectiondata"]["W_y"];
	W_z := WhateverYouNeed["sectiondata"]["W_z"];
	
	# start calculation
	sigma_c0d := convert(-F_xd / A, 'units', 'N'/'mm^2');

	km := 0.7; 	# for konstruksjonstre, limtre og parallelfiner / rektangul�re tverrsnitt
	sigma_myd := convert(M_yd / W_y, 'units', 'N'/'mm^2');
	sigma_mzd := convert(M_zd / W_z, 'units', 'N'/'mm^2');

	eta["619"] := max((sigma_c0d / f_c0d)^2 + sigma_myd / (f_md * kh("h", WhateverYouNeed)) + km * sigma_mzd / (f_md * kh("b", WhateverYouNeed)),
	               (sigma_c0d / f_c0d)^2 + km * sigma_myd / (f_md * kh("h", WhateverYouNeed)) + sigma_mzd / (f_md * kh("h", WhateverYouNeed)));	# formel 6.19, 6.20
	               
	eta["623"] := max(sigma_c0d / (k_cy * f_c0d) + sigma_myd / (f_md * kh("h", WhateverYouNeed)) + km * sigma_mzd / (f_md * kh("b", WhateverYouNeed)),
	               sigma_c0d / (k_cz * f_c0d) + km * sigma_myd / (f_md * kh("h", WhateverYouNeed)) + sigma_mzd / (f_md * kh("b", WhateverYouNeed)));	# formel 6.23, 6.24

	# if ComponentExists("TextArea_eta_619") and ComponentExists("TextArea_eta_623") then
	#	HighlightResults({"eta_619", "eta_623"}, "highlight");
	#	SetProperty("TextArea_eta_619", value, round2(eta_619, 2));		# (6.19/.20)
	#	SetProperty("TextArea_eta_623", value, round2(eta_623, 2));		# (6.23/.24)
	# end if;

	if k_cy = 1 and k_cz = 1 then
		if M_yd = 0 and M_zd = 0 then
			usedcode := "6.1.4";
			comments := "Compression parallel to the grain";
		else
			# usedcode := "6.2.4 kombinert b&oslash;yning og aksialt trykk";
			usedcode := "6.2.4";
			comments := "Combined bending and axial compression";
		end if;
	else
		# usedcode := "6.3.2 S&oslash;yler utsatt for trykk eller en kombinasjon av trykk og b&oslash;yning";
		usedcode := "6.3.2";
		comments := "Columns subjected to either compression or combined compression and bending";
	end if;
	return max(eta["619"], eta["623"]), usedcode, comments
end proc: