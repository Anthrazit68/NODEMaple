AnnexA := proc(WhateverYouNeed::table)
	description "Block Shear check acc. Annex A";
	local BlockShear, A_net_t, A_net_v, lvl, lvr, L_net_v, L_net_t, fastenervalues, structure, t_eff, b1outside, connection, d, t_ef, M_yRk, f_hk, F_hd, F_vd, alphaForce, activeloadcase,
		dummy, dummy1, t_steel, sectiondataAll, shearplanes, timberlayers, t_1, i, usedcode, comments, warnings, F_bsRk, F_bsRd, f_t0k, f_vk, k_mod, gamma_M, alphaBeam, alpha, F_gd, eta;

	structure := WhateverYouNeed["calculations"]["structure"];
	connection := structure["connection"];
	fastenervalues := WhateverYouNeed["calculatedvalues"]["fastenervalues"];	
	b1outside := connection["b1outside"];
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
	
	elif connection["connection1"] = "Steel" and connection["connection2"] = "Timber" then		# Steel - Timber
		f_hk := WhateverYouNeed["calculatedvalues"]["f_h0k"]["2"];
		f_t0k := WhateverYouNeed["materialdataAll"]["2"]["f_t0k"];
		f_vk := WhateverYouNeed["materialdataAll"]["2"]["f_vk"];
		k_mod := WhateverYouNeed["materialdataAll"]["2"]["k_mod"];
		alphaBeam := evalf(WhateverYouNeed["calculations"]["structure"]["connection"]["graindirection2"]);
		
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
		t_ef["b"] := 1.4 * sqrt(M_yRk / (f_hk * d));									# thin steel plate, (A.6)
		t_ef["e"] := 2 * sqrt(M_yRk / (f_hk * d));									# thick steel plate, (A.7)	

		# check if reduced outside layers
		t_eff["1o"] := fastenervalues["t_eff"]["1"];
		if b1outside <> "false" and b1outside < t_eff["1o"] then
			t_eff["1o"] := b1outside
		end if;	

		# 1 shear plane
		t_ef["a"] := 0.4 * t_eff["1o"];											# thin steel plate, (A.6)		
		t_ef["d"] := t_eff["1o"] * (sqrt(2 + M_yRk / (f_hk * d * t_eff["1o"]^2)) - 1);		# thick steel plate, (A.7)		

		# 2 shear planes
		t_ef["g"] := fastenervalues["t_eff"]["1"] * (sqrt(2 + M_yRk / (f_hk * d * fastenervalues["t_eff"]["1"]^2)) - 1);		# thick steel plate, (A.7)		
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

	F_bsRk := max(1.5 * A_net_t["total"] * f_t0k, 0.7 * A_net_v["total"] * f_vk);
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
	
	if WhateverYouNeed["calculations"]["structure"]["connection"]["connection1"] = "Timber" then
		timber := "1"
	elif WhateverYouNeed["calculations"]["structure"]["connection"]["connection2"] = "Timber" then
		timber := "2"
	end if;

	serviceclass := WhateverYouNeed["materialdataAll"][timber]["serviceclass"];

	if parse(serviceclass) > WhateverYouNeed["calculatedvalues"]["fastenervalues"]["serviceclass"] then
		Alert("Fastener Service Class lower than required", warnings, 2)
	end if;
		
end proc:
