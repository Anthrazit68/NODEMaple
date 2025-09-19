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
		dummy := cat("MathContainer_t_ef", i);
		if ComponentExists(dummy) then 
			SetProperty(dummy, 'value', round(t_ef[i]))
		else
			SetProperty(dummy, 'value', 0)
		end if;
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
	if ComponentExists("MathContainer_AnnexA_t_1") then
		SetProperty("MathContainer_AnnexA_t_1", 'value', round(t_1))
	end if;
	if ComponentExists("MathContainer_AnnexA_t_ef") then
		SetProperty("MathContainer_AnnexA_t_ef", 'value', round(t_ef["a-e"]))
	end if;
	if ComponentExists("MathContainer_L_net_v") then
		SetProperty("MathContainer_L_net_v", 'value', round(L_net_v))
	end if;
	if ComponentExists("MathContainer_L_net_t") then
		SetProperty("MathContainer_L_net_t", 'value', round(L_net_t))
	end if;
	if ComponentExists("MathContainer_A_net_v") then
		SetProperty("MathContainer_A_net_v", 'value', round(A_net_v["total"]))
	end if;
	if ComponentExists("MathContainer_A_net_t") then
		SetProperty("MathContainer_A_net_t", 'value', round(A_net_t["total"]))
	end if;
	if ComponentExists("MathContainer_F_bsRk") then
		SetProperty("MathContainer_F_bsRk", 'value', round(F_bsRk))
	end if;
	if ComponentExists("MathContainer_F_bsRd") then
		SetProperty("MathContainer_F_bsRd", 'value', round(F_bsRd))
	end if;

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
	local opening, h, warnings, openingtype, a, hd, e, lv, lA, lz, r, withoutReinforcement, h_ro, h_ru, dummy, usedcode, comments, openingResult;

	warnings := WhateverYouNeed["warnings"];
	usedcode := "DIN NA";
	comments :=  WhateverYouNeed["results"]["comments"];
	openingResult := WhateverYouNeed["results"]["opening"];

	# definition of variables
	opening :=  WhateverYouNeed["calculations"]["structure"]["opening"];
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
	h_ro := h / 2 - hd / 2 - e;		
	h_ru := h / 2 - hd / 2 + e;

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
	withoutReinforcement := true;

	if lv < h then
		dummy := "lv < h";
		withoutReinforcement := false;

	elif lz <> 0 and lz < 1.5*h and lz > 300 * Unit('mm') then
		dummy := "lz < 1.5*h (300mm)";
		withoutReinforcement := false;

	elif lA < 0.5*h then
		dummy := "lA < 0.5*h";
		withoutReinforcement := false;

	elif h_ro < 0.35*h or h_ru < 0.35*h then
		dummy := "h_rou < 0.35*h";
		withoutReinforcement := false;

	elif a > 0.4*h then
		dummy := "a > 0.4*h";
		withoutReinforcement := false;
	
	elif hd > 0.15*h then
		dummy := "hd > 0.15*h";
		withoutReinforcement := false;

	elif openingtype = "rectangular" and r < 15 * Unit('mm') then
		dummy := "r < 15mm ";
		withoutReinforcement := false;

	elif WhateverYouNeed["materialdata"]["serviceclass"] = "3" then
		dummy := "serviceclass 3 ";
		withoutReinforcement := false;

	end if;

	# check if hole is minor
	openingResult["minorOpening"] := false;

	if openingtype = "circular" then

		if hd <= 50 * Unit('mm') and hd <= 0.15 * h and e <= 0.15 * h then		# no strict rules for e in code, assumed same as for hd
			openingResult["minorOpening"] := true;
			comments["minorOpening"] := "minor opening"
		end if;

	elif openingtype = "circular" then

		if evalf(sqrt(a^2 + hd^2)) <= 50 * Unit('mm') and hd <= 0.15 * h and e <= 0.15 * h then		# no strict rules for e in code, assumed same as for hd
			openingResult["minorOpening"] := true;
			comments["minorOpening"] := "minor opening"
		end if;

	end if;

	openingResult["withoutReinforcement"] := withoutReinforcement;
	if withoutReinforcement = false then
		comments["checkOpeningGeometry"] := cat("Beam opening: reinforcement necessary, ", dummy)		
	end if;

end proc: