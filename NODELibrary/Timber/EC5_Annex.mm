# EC5_Annex.mm : Eurocode 5 Annex procedures
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

AnnexA := proc(WhateverYouNeed::table)
	description "Block Shear check acc. Annex A";
	local BlockShear, A_net_t, A_net_v, lvl, lvr, L_net_v, L_net_t, fastenervalues, structure, t_eff, bout1, connection, d, t_ef, M_yRk, f_hk, F_hd, F_vd, alphaForce,
	 activeloadcase, dummy, dummy1, t_steel, sectiondataAll, shearplanes, timberlayers, t_1, i, usedcode, comments, warnings, F_bsRk, F_bsRd, f_t0k, f_vk, k_mod,
	 gamma_M, alphaBeam, alpha, F_gd, eta, k_t;

	structure := WhateverYouNeed["calculations"]["structure"];
	connection := structure["connection"];
	fastenervalues := WhateverYouNeed["calculatedvalues"]["fastenervalues"];	
	bout1 := connection["bout1"];
	sectiondataAll := WhateverYouNeed["sectiondataAll"];
	d := structure["fastener"]["fastener_d"];	
	M_yRk := fastenervalues["M_yRk"];
	t_steel := sectiondataAll["steel"]["b"];
	shearplanes := fastenervalues["shearplanes"];
	timberlayers := WhateverYouNeed["calculatedvalues"]["layers"];
	warnings := WhateverYouNeed["warnings"];
	gamma_M := NODETimberEN1995:-gamma_M("Connections"); 		# NS-EN 1995, NA.2.4.1

	lvl := WhateverYouNeed["calculatedvalues"]["distance"]["dist"]["a_lvl"];
	lvr := WhateverYouNeed["calculatedvalues"]["distance"]["dist"]["a_lvr"];
	BlockShear := WhateverYouNeed["calculatedvalues"]["BlockShear"];
	
	usedcode := "Annex A";
	comments := "Block shear and plug shear failure at multiple dowel-type steel-to-timber connections";

	# return if not relevant, for timber - timber connections		
	if connection["connection1"] = "Timber" and connection["connection2"] = "Timber" then
		return 0, usedcode, comments	
	end if;	

	# L_net
	L_net_v := evalf((lvl + lvr) * Unit('mm')) ;										# parallel with grain
	L_net_t := WhateverYouNeed["calculatedvalues"]["distance"]["dist"]["a_lt"] * Unit('mm');	# perp. to grain direction

	# t_eff, effective thickness of fastener
	t_eff := table();	
	t_eff["1"] := fastenervalues["t_eff"]["1"];
	t_eff["2"] := fastenervalues["t_eff"]["2"];

	# f_hk, needs to be f_h0k, as block failure checks capacity of connection for force in grain direction
	f_hk := table();
	if connection["connection1"] = "Timber" and connection["connection2"] = "Steel" then			# Timber - Steel
		f_hk := WhateverYouNeed["calculatedvalues"]["f_h0k"]["1"];
		f_t0k := WhateverYouNeed["materialdataAll"]["1"]["f_t0k"];
		f_vk := WhateverYouNeed["materialdataAll"]["1"]["f_vk"];
		k_mod := WhateverYouNeed["materialdataAll"]["1"]["k_mod"];
		alphaBeam := evalf(WhateverYouNeed["calculations"]["structure"]["connection"]["graindirection1"]);
		k_t := evalf(0.9 + 1.4 * sqrt(WhateverYouNeed["materialdataAll"]["1"]["G_mean"] / WhateverYouNeed["materialdataAll"]["1"]["E_m0mean"]));
	
	elif connection["connection1"] = "Steel" and connection["connection2"] = "Timber" then		# Steel - Timber
		f_hk := WhateverYouNeed["calculatedvalues"]["f_h0k"]["2"];
		f_t0k := WhateverYouNeed["materialdataAll"]["2"]["f_t0k"];
		f_vk := WhateverYouNeed["materialdataAll"]["2"]["f_vk"];
		k_mod := WhateverYouNeed["materialdataAll"]["2"]["k_mod"];
		alphaBeam := evalf(WhateverYouNeed["calculations"]["structure"]["connection"]["graindirection2"]);
		k_t := evalf(0.9 + 1.4 * sqrt(WhateverYouNeed["materialdataAll"]["2"]["G_mean"] / WhateverYouNeed["materialdataAll"]["2"]["E_m0mean"]));
		
	else
		Alert("Undefined connection for AnnexA", warnings, 3)		
	end if;

	# t_ef, according to Annex A
	t_ef := table();
	A_net_t := table();
	A_net_v := table();
	
	if connection["connection1"] = "Steel" and connection["connection2"] = "Timber" then

		# all except 2 shearplanes impossible
		# only modes j - m posssible

		if shearplanes = 2 then			
			A_net_t["total"] := L_net_t * t_eff["2"];		# (A.2)
			A_net_v["total"] := L_net_v * t_eff["2"];		# (A.3), modes j - m

		else
			A_net_t["total"] := 0;
			A_net_v["total"] := 0;
			Alert("Number of shearplanes > 2 for connection not defined", warnings, 3);
			
		end if;		
				
	elif connection["connection1"] = "Timber" and connection["connection2"] = "Steel" then

		# common values, independent of layer thickness
		t_ef["b"] := 1.4 * sqrt(M_yRk / (f_hk * d));			# (b) thin steel plate, (A.6)
		t_ef["e"] := 2 * sqrt(M_yRk / (f_hk * d));				# (e)(h) thick steel plate, (A.7), fixed wrong formula (t1 must be removed from equation)

		# check if reduced outside layers
		t_eff["1o"] := fastenervalues["t_eff"]["1"];
		if bout1 <> "false" and bout1 < t_eff["1o"] then
			t_eff["1o"] := bout1
		end if;	

		# 1 shear plane
		t_ef["a"] := 0.4 * t_eff["1o"];														# (a) thin steel plate, (A.6)
		t_ef["d"] := t_eff["1o"] * (sqrt(2 + 4 * M_yRk / (f_hk * d * t_eff["1o"]^2)) - 1);	# (d) thick steel plate, (A.7)		

		# 2 shear planes
		t_ef["g"] := fastenervalues["t_eff"]["1"] * (sqrt(2 + 4 * M_yRk / (f_hk * d * fastenervalues["t_eff"]["1"]^2)) - 1);		# (g) thick steel plate, (A.7)
		t_ef["h"] := t_ef["e"];		# thick steel plate

		# precalculating t_ef, 1 shear plane, dependent on steel plate thickness, interpolating values
		if t_steel <= 0.5 * d then	# thin steel plate
				
			t_ef["a-e"] := min(t_ef["a"], t_ef["b"]);			

		elif t_steel >= d then	# thick steel plate

			t_ef["a-e"] := min(t_ef["d"], t_ef["e"]);			
			
		else # between thin and thick steel plate, interpolating

			dummy := min(t_ef["a"], t_ef["b"]);
			dummy1 := min(t_ef["d"], t_ef["e"]);
					
			t_ef["a-e"] := evalf(dummy + (t_steel - 0.5 * d) / (0.5 * d) * (dummy1 - dummy));						
					
		end if;

		# A_net
		if shearplanes = 1 then					# timber - steel, mode a - e

			t_1 := t_eff["1o"];
			A_net_t["total"] := L_net_t * t_1;			# (A.2)
			A_net_v["total"] := min(L_net_v * t_1,			# (A.3), mode c
							L_net_v / 2 * (L_net_t + 2 * t_ef["a-e"]));	# mode a, b, d, e
						
		elif shearplanes = 2 then				# timber - steel, mode f - h

			t_1 := t_eff["1o"];
			A_net_t["total"] := L_net_t * t_1;			# (A.2)
			A_net_v["total"] := min(L_net_v * t_1,			# (A.3), mode f
						L_net_v / 2 * (L_net_t + 2 * min(t_ef["g"], t_ef["h"])));	# mode g, h

		else # connectionInsideLayers >= 3 then

			# side members, failure modes a - e			
			t_1 := t_eff["1o"];
			A_net_t["side"] := L_net_t * t_1;			# (A.2)
			A_net_v["side"] := min(L_net_v * t_1,			# (A.3), mode c
						L_net_v / 2 * (L_net_t + 2 * t_ef["a-e"]));	# mode a, b, d, e

			# middle members, failure modes j - m
			t_1 := fastenervalues["t_eff"]["1"];
			A_net_t["middle"] := L_net_t * t_1;		# (A.2)
			A_net_v["middle"] := L_net_v * t_1;		# mode j/l, k, m

			# sum
			A_net_t["total"] := 2 * A_net_t["side"] + (timberlayers["1"] - 2) * A_net_t["middle"];
			A_net_v["total"] := 2 * A_net_v["side"] + (timberlayers["1"] - 2) * A_net_v["middle"];
				
		end if;
				
	end if;

	for i in {"a", "b", "d", "e", "g", "h"} do
#		dummy := cat("MathContainer_t_ef", i);
		WriteValueToComponent(cat("t_ef", i), round(t_ef[i]), {"nocheck"});
#		if ComponentExists(dummy) then 
#			SetProperty(dummy, 'value', round(t_ef[i]))
#		else
#			SetProperty(dummy, 'value', 0)
#		end if;
	end do;

	F_bsRk := max(k_t * A_net_t["total"] * f_t0k, 0.7 * A_net_v["total"] * f_vk);			# (A.1), NA (A2)
	# F_bsRk := max(1.5 * A_net_t["total"] * f_t0k, 0.7 * A_net_v["total"] * f_vk);			# (A.1)
	F_bsRk := convert(F_bsRk, 'units', 'kN');
	F_bsRd := F_bsRk * k_mod / gamma_M;

	# get force in grain direction
	activeloadcase := WhateverYouNeed["calculations"]["activesettings"]["activeloadcase"];
	F_hd := WhateverYouNeed["calculations"]["loadcases"][activeloadcase]["F_hd"];
	F_vd := WhateverYouNeed["calculations"]["loadcases"][activeloadcase]["F_vd"];

	if F_hd = 0 and F_vd = 0 then		# special case where either everything is zero, or we just have moments on the connection
		alphaForce := 0;
	else
		alphaForce := arctan(convert(F_vd, 'unit_free'), convert(F_hd, 'unit_free')) * Unit('radians');
	end if;

	alpha := alphaForce - alphaBeam;

	F_gd := sqrt(F_vd ^ 2 + F_hd ^ 2) * cos(alpha);		# force in grain direction

	# calculate eta
	eta := F_gd / F_bsRd;
	
	# https://mapleprimes.com/questions/237950-Parse-Statement-In-Proc?sp=237950
	# for i in {"L_net_v", "L_net_t"} do
	#	if ComponentExists(cat("MathContainer_", i)) then
	#		dummy := round(parse(i, 'statement'));
	#		SetProperty(cat("MathContainer_", i), 'value', dummy)
	#	end if;
	# end do;

	# workaround
	WriteValueToComponent("AnnexA_t_1", round(t_1), {"nocheck"});
	WriteValueToComponent("AnnexA_t_ef", round(t_ef["a-e"]), {"nocheck"});
	WriteValueToComponent("L_net_v", round(L_net_v), {"nocheck"});
	WriteValueToComponent("L_net_t", round(L_net_t), {"nocheck"});
	WriteValueToComponent("A_net_v", round(A_net_v["total"]), {"nocheck"});
	WriteValueToComponent("A_net_t", round(A_net_t["total"]), {"nocheck"});
	WriteValueToComponent("F_bsRk", round(F_bsRk), {"nocheck"});
	WriteValueToComponent("F_bsRd", round(F_bsRd), {"nocheck"});
	
#	if ComponentExists("MathContainer_AnnexA_t_1") then
#		SetProperty("MathContainer_AnnexA_t_1", 'value', round(t_1))
#	end if;
#	if ComponentExists("MathContainer_AnnexA_t_ef") then
#		SetProperty("MathContainer_AnnexA_t_ef", 'value', round(t_ef["a-e"]))
#	end if;
#	if ComponentExists("MathContainer_L_net_v") then
#		SetProperty("MathContainer_L_net_v", 'value', round(L_net_v))
#	end if;
#	if ComponentExists("MathContainer_L_net_t") then
#		SetProperty("MathContainer_L_net_t", 'value', round(L_net_t))
#	end if;
#	if ComponentExists("MathContainer_A_net_v") then
#		SetProperty("MathContainer_A_net_v", 'value', round(A_net_v["total"]))
#	end if;
#	if ComponentExists("MathContainer_A_net_t") then
#		SetProperty("MathContainer_A_net_t", 'value', round(A_net_t["total"]))
#	end if;
#	if ComponentExists("MathContainer_F_bsRk") then
#		SetProperty("MathContainer_F_bsRk", 'value', round(F_bsRk))
#	end if;
#	if ComponentExists("MathContainer_F_bsRd") then
#		SetProperty("MathContainer_F_bsRd", 'value', round(F_bsRd))
#	end if;

	BlockShear["L_net_v"] := L_net_v;
	BlockShear["L_net_t"] := L_net_t;
	BlockShear["A_net_v"] := A_net_v;
	BlockShear["A_net_t"] := A_net_t;
	BlockShear["F_bsRk"] := F_bsRk;
	BlockShear["F_bsRd"] := F_bsRd;

	return eta, usedcode, comments
	
end proc:


checkServiceclass := proc(WhateverYouNeed::table)
	description "check fastener serviceclass against connection serviceclass";
	local timber, serviceclass, warnings;

	warnings := WhateverYouNeed["warnings"];
	
	if WhateverYouNeed["calculations"]["calculationtype"] = "NS-EN 1995-1-1, Section 8: Fasteners" then

		if WhateverYouNeed["calculations"]["structure"]["connection"]["connection1"] = "Timber" then
			timber := "1"
		elif WhateverYouNeed["calculations"]["structure"]["connection"]["connection2"] = "Timber" then
			timber := "2"
		end if;

		serviceclass := WhateverYouNeed["materialdataAll"][timber]["serviceclass"];

	elif WhateverYouNeed["calculations"]["calculationtype"] = "Timber beam with opening" then

		serviceclass := WhateverYouNeed["materialdata"]["serviceclass"];

	end if;

	if parse(serviceclass) > WhateverYouNeed["calculatedvalues"]["fastenervalues"]["serviceclass"] then
		Alert("Fastener Service Class lower than required", warnings, 2)
	end if;
		
end proc:


checkOpeningGeometry := proc(WhateverYouNeed::table)
	description "check opening geometry in beams with opening";
	local opening, b, h, warnings, openingtype, a, hd, e, lv, lA, lz, r, openingValid, h_r, h_ro, h_ru, dummy, usedcode, comments, openingResult,
		l_t90, k_t90, K_corner, l_ad, reinforcmentType;

	warnings := WhateverYouNeed["warnings"];
	usedcode := "DIN NA";
	comments :=  WhateverYouNeed["results"]["comments"];
	openingResult := WhateverYouNeed["results"]["opening"];		# calculated values

	# get predefined geometric input values
	opening :=  WhateverYouNeed["calculations"]["structure"]["opening"];		# defined in TeamBeamWithOpening:-ReadComponentsSpecific
	b := WhateverYouNeed["sectiondataAll"]["1"]["b"];
	h := WhateverYouNeed["sectiondataAll"]["1"]["h"];
	openingtype := opening["openingtype"];
	a := opening["opening_a"];
	hd := opening["opening_hd"];
	e := opening["opening_e"];
	lv := opening["opening_lv"];
	lA := opening["opening_lA"];
	lz := opening["opening_lz"];
	r := opening["opening_r"];
	
	# hd is defined for both rectangular and circular openings
	l_ad := table();
	h_ro := h / 2 - hd / 2 - e;		
	h_ru := h / 2 - hd / 2 + e;

	if openingtype = "rectangular" then
		l_ad["left"] := h_ru;
		l_ad["right"] := h_ro;
		h_r := min(h_ru, h_ro);					# limtreboka, p 90, (5-9)
		l_t90 := 0.5*(hd + h);					# limtreboka, p 90, (5-11)
		K_corner := evalf(1.84 * (1+a/h)/(1-hd/h) * (hd/h)^0.2);	# (5-14)

	elif openingtype = "circular" then
		l_ad["left"] := h_ru + 0.15 * hd;
		l_ad["right"] := h_ro + 0.15 * hd;
		h_r := min(h_ru + 0.15 * hd, h_ro + 0.15 * hd);			# (5-10)
		l_t90 := 0.35*hd + 0.5*h;								# (5-12)
		K_corner := 1							# assumed value, needs to be verified
	end if;

	k_t90 := evalf(min(1, (450 * Unit('mm') / h)^0.5));			# (5-13)
	openingResult["h_r"] := evalf(h_r);
	openingResult["l_t90"] := evalf(l_t90);
	openingResult["k_t90"] := k_t90;
	openingResult["K_corner"] := K_corner;
	openingResult["l_ad"] := l_ad;
	WhateverYouNeed["sectiondataAll"]["1"]["l_ad"] := l_ad;		# for calculation of F_axR

	# check if opening outside beam
	if  h_ro <= 0 then
		Alert("Opening outside top beam", warnings, 5);
	elif h_ru <= 0 then
		Alert("Opening outside bottom beam", warnings, 5);	
	end if;

	if openingtype = "rectangular" then
		if r < 0 then
			opening["opening_r"] := 0;
			if ComponentExists("TextArea_opening_r") then
				Alert("radius = 0", warnings, 1);
				SetProperty("TextArea_opening_r", 'value', 0)
			end if;
		elif r > a / 2 or r > hd / 2 then
			opening["opening_r"] := min(a/2, hd/2);
			if ComponentExists("TextArea_opening_r") then
				Alert(cat("r set to ", convert(r, 'unit_free')), warnings, 1);
				SetProperty("TextArea_opening_r", 'value', convert(r, 'unit_free'))
			end if;
		end if;
	end if;

	# check if size and placement of opening fulfills criteria for beams without reinforcement acc. DIN EN 1995-1-1/NA (limtreboka p. 88)
	openingValid := true;

	if lv < h then
		dummy := "lv < h";
		openingValid := false;

	elif lz <> 0 and (lz < 1.0*h or lz < 300 * Unit('mm')) then
		dummy := "lz < 1.0*h or < 300mm";
		openingValid := false;

	elif lA < 0.5*h then
		dummy := "lA < 0.5*h";
		openingValid := false;

	elif h_ro < 0.25*h or h_ru < 0.25*h then
		dummy := "h_r(o,u) < 0.25*h";
		openingValid := false;

	elif a > 1.0*h or a > 2.5 * hd then
		dummy := "a > h or a > 2.5*hd";
		openingValid := false;
	
	elif hd > 0.4*h then			# 0.3*h for inner reinforcement, 0.4*h for outer reinforcement
		dummy := "hd > 0.4*h (outer reinforcement)";
		openingValid := false;

	elif openingtype = "rectangular" and r < 15 * Unit('mm') then
		dummy := "r < 15mm ";
		openingValid := false;

	end if;

	openingResult["openingValid"] := openingValid;

	if openingValid = false then
		Alert(cat("Opening invalid: ", dummy), warnings, 5);
		return
	end if;

	# check if reinforcment necessary, or type of reinforcement
	reinforcmentType := "none";

	if lz <> 0 and lz < 1.5*h then
		reinforcmentType := "both"

	elif h_ro < 0.35*h or h_ru < 0.35*h then
		reinforcmentType := "both"

	elif a > 0.4*h then
		reinforcmentType := "both"
	
	elif hd > 0.15*h then
		reinforcmentType := "both";
		if hd > 0.3*h then
			reinforcmentType := "outside";
		end if

	elif WhateverYouNeed["materialdata"]["serviceclass"] = "3" then	# Limtreboka, p. 88, bottom page
		reinforcmentType := "both";

	end if;

	openingResult["reinforcmentType"] := reinforcmentType;

	# check if hole is minor
	openingResult["minorOpening"] := false;

	if openingtype = "circular" then

		if hd <= 50 * Unit('mm') and hd <= 0.15 * h and e <= 0.15 * h then		# no strict rules for e in code, assumed same as for hd
			openingResult["minorOpening"] := true;			
		end if;

	elif openingtype = "circular" then

		if evalf(sqrt(a^2 + hd^2)) <= 50 * Unit('mm') and hd <= 0.15 * h and e <= 0.15 * h then		# no strict rules for e in code, assumed same as for hd
			openingResult["minorOpening"] := true;			
		end if;

	end if;
	
	# write results
	WriteValueToComponent("h_r", round(h_r), {"nocheck"});
	WriteValueToComponent("l_t90", round(l_t90), {"nocheck"});
	WriteValueToComponent("k_t90", round2(k_t90, 2), {"nocheck"});
	WriteValueToComponent("K_corner", round2(K_corner, 2), {"nocheck"});

end proc:


calculate_BeamWithOpening := proc(WhateverYouNeed::table)
	description "Timber beam with opening";
	local opening, hd, openingResult, b, h, h_r, sigma_t90d, f_vd, f_t90d, eta, usedcode, comments, loadcase, F_vd, M_yd, F_t90d, l_t90, A, k_t90, K_corner, tau_cornerd,
		F_t90Vd, F_t90Md, l_ad, loadside, fastenervalues, a2, a4, maxnumberOfScrews;

	# define local variables
	opening :=  WhateverYouNeed["calculations"]["structure"]["opening"];
	hd := opening["opening_hd"];
	b := WhateverYouNeed["sectiondataAll"]["1"]["b"];
	h := WhateverYouNeed["sectiondataAll"]["1"]["h"];	
	openingResult := WhateverYouNeed["results"]["opening"];
	h_r := openingResult["h_r"];
	l_t90 := openingResult["l_t90"];
	k_t90 := openingResult["k_t90"];
	K_corner := openingResult["K_corner"];
	
	f_t90d := WhateverYouNeed["materialdata"]["f_t90d"];
	f_vd := WhateverYouNeed["materialdata"]["f_vd"];
	loadcase := WhateverYouNeed["calculations"]["activesettings"]["activeloadcase"];
	F_vd := WhateverYouNeed["calculations"]["loadcases"][loadcase]["F_vd"];
	M_yd := WhateverYouNeed["calculations"]["loadcases"][loadcase]["M_yd"];
	loadside := WhateverYouNeed["calculations"]["loadcases"][loadcase]["loadside"];
	l_ad := max(entries(openingResult["l_ad"]));		# longest distance from beam edge to crack for longest screw length
	fastenervalues := WhateverYouNeed["calculatedvalues"]["fastenervalues"];	

	eta := table();
	comments := table();
	
	# check maximum number of screws in section
	a2 := WhateverYouNeed["calculatedvalues"]["distance"]["a2_min_max1"];
	a4 := WhateverYouNeed["calculatedvalues"]["distance"]["a4c_min_max1"];
	maxnumberOfScrews := (b - 2*a4) / a2;

	if maxnumberOfScrews < 0 then
		Alert("Beam to small, no reinforcement possible", warnings, 3);
	else
		maxnumberOfScrews := round(maxnumberOfScrews) + 1;
		openingResult["maxnumberOfScrews"] := maxnumberOfScrews
	end if;

	# reduction factor mentioned in limtreboka for circular openings is neither used in example 18, nor in Holzbau Taschenbuch Example A.4.2
	# if opening["openingtype"] = "circular" then
	# 	hd_ := 0.7 * hd
	# elif opening["openingtype"] = "rectangular" then
	# 	hd_ := hd
	# end if;

	F_t90Vd := convert(evalf(F_vd * hd / (4*h) * (3 - hd^2 / h^2)), 'units', 'kN');
	F_t90Md := convert(evalf(0.008 * M_yd / h_r), 'units', 'kN');
	F_t90d := convert(evalf(F_t90Vd + F_t90Md), 'units', 'kN');				# (5-8)

	A := evalf(0.5 * l_t90 * b);
	sigma_t90d := convert(F_t90d / A, 'units', 'N'/'mm^2');					# (5-7)

	# check tension perp. to grain
	eta["Ft90"] := evalf(sigma_t90d / (k_t90 * f_t90d));
	usedcode := "Beam with opening";
	# comments["Ft90"] := "F,t90";

	# check shear at opening ?
	tau_cornerd := convert(evalf(K_corner * 3 * F_vd / (2 * b * h)), 'units', 'N'/'mm^2');	# (5-14)
	eta["tau_corner"] := evalf(tau_cornerd / f_vd);
	# comments["tau_corner"] := "tau_corner";

	
	# comments
	comments["reinforcmentType"] := cat("reinforcement: ", openingResult["reinforcmentType"], ",");
	
	if openingResult["minorOpening"] = true then
		comments["minorOpening"] := cat("minor opening, ", dummy)
	end if;

	eta["Ft90r"] := evalf(F_t90d / fastenervalues["F_axRd_fastener"]);

	openingResult["F_t90Vd"] := F_t90Vd;
	openingResult["F_t90Md"] := F_t90Md;
	openingResult["F_t90d"] := F_t90d;
	openingResult["sigma_t90d"] := sigma_t90d;
	openingResult["tau_cornerd"] := tau_cornerd;

	WriteValueToComponent("F_t90Vd", round2(F_t90Vd, 2), {"nocheck"});
	WriteValueToComponent("F_t90Md", round2(F_t90Md, 2), {"nocheck"});
	WriteValueToComponent("F_t90d", round2(F_t90d, 2), {"nocheck"});
	WriteValueToComponent("sigma_t90d", round2(sigma_t90d, 2), {"nocheck"});
	WriteValueToComponent("tau_cornerd", round2(tau_cornerd, 2), {"nocheck"});
	WriteValueToComponent("l_ad", round(l_ad), {"nocheck"});

	Write_eta(eta, comments);

	return eta, usedcode, comments

end proc: