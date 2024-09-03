calculate_F_vR_810 := proc(WhateverYouNeed::table)
	description "Toothed Plate Connectors";
	local structure, warnings, fastener, platesides, ToothedPlatetype, db, dc, hc, F_vRk, F_vRd, k1, k2, k3, t, a3t, rho_k, rho_k_, k_mod, gamma_M, fastenervalues, comments, d, shearplanes, F_vRkfin;

	warnings := WhateverYouNeed["warnings"];
	comments := WhateverYouNeed["results"]["comments"];

	if WhateverYouNeed["calculations"]["structure"]["fastener"]["ToothedPlateActive"] = "false" then
		comments["810"] := evaln(comments["810"]);
		return 0, 0			# F_vRk, F_vRd
	end if;

	fastenervalues := WhateverYouNeed["calculatedvalues"]["fastenervalues"];
	
	#if assigned(fastenervalues["F_vRk_810"]) then			# return values if previously calculated
	#	return fastenervalues["F_vRk_810"], fastenervalues["F_vRd_810"]
	#end if;	

	fastener := WhateverYouNeed["calculations"]["structure"]["fastener"];
	db := fastenervalues["ToothedPlatedb"];	
	d := WhateverYouNeed["calculations"]["structure"]["fastener"]["fastener_d"];
	shearplanes := fastenervalues["shearplanes"];

	gamma_M := 1.3; 		# NS-EN 1995, NA.2.4.1
	structure := WhateverYouNeed["calculations"]["structure"];
	warnings := WhateverYouNeed["warnings"];
	platesides := fastener["ToothedPlatesides"];
	ToothedPlatetype := fastener["ToothedPlatetype"];		
	dc := fastener["ToothedPlatedc"];
	hc := NODETimberToothedPlateConnectors:-hc[platesides, ToothedPlatetype, db][1];		# height of teeth
	

	# calculate some values need for calculation
	t := table();
	rho_k := table();
	k_mod := table();
	
	if structure["connection"]["connection1"] = "Timber" then
		t["1"] := WhateverYouNeed["sectiondataAll"]["1"]["b"];
		if structure["connection"]["b1outside"] <> "false" then
			t["1outside"] := structure["connection"]["b1outside"];		
		end if;
		rho_k["1"] := WhateverYouNeed["materialdataAll"]["1"]["rho_k"];
		k_mod["1"] := WhateverYouNeed["materialdataAll"]["1"]["k_mod"]
	end if;

	if structure["connection"]["connection2"] = "Timber" then
		t["2"] := WhateverYouNeed["sectiondataAll"]["2"]["b"];
		rho_k["2"] := WhateverYouNeed["materialdataAll"]["2"]["rho_k"];
		k_mod["2"] := WhateverYouNeed["materialdataAll"]["2"]["k_mod"]
	end if;
	

	# check if type of Toothed Plate Connector is possible
	if structure["connection"]["connection1"] = "Steel" or structure["connection"]["connection2"] = "Steel" then
		if platesides = "2" then
			Alert("2-sided toothed plate connector can't be used with steel", warnings, 3);
			return
		end if;
	end if;

	# check minimum thickness of timber parts 8.9(2)	
	if assigned(t["1"]) and t["1"] < 2.25 * hc then
		Alert("Toothed Plate Connector: 8.9(2) t1(outer) < 2.25 * he", warnings, 3);
			
	elif assigned(t["1outside"]) and t["1outside"] < 2.25 * hc then
		Alert("Toothed Plate Connector: 8.9(2) t1(outer) < 2.25 * he", warnings, 3);
			
	elif WhateverYouNeed["calculatedvalues"]["layers"]["1"] > 2 and t["1"] < 3.75 * hc then
		Alert("Toothed Plate Connector: 8.9(2) t1(inner) < 3.75 * he", warnings, 3);
			
	elif assigned(t["2"]) and t["2"] < 3.75 * hc then
		Alert("Toothed Plate Connector: 8.9(2) t2 < 3.75 * he", warnings, 3);
			
	end if;			

	# k1 (8.73)
	k1 := 1.0;
	
	if assigned(t["1"]) then 
		k1 := min(k1, t["1"] / (3 * hc))
	end if;
	
	if assigned(t["1outside"]) then 
		k1 := min(k1, t["1outside"] / (3 * hc))
	end if;
	
	if assigned(t["2"]) then
		k1 := min(k1, t["2"] / (5 * hc))
	end if;

	# k2 (8.74)
	k2 := 1.0;

	if member(ToothedPlatetype, {"C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8", "C9"}) then
		
		a3t := max(1.1 * dc, 7 * d, 80 * Unit('mm'));	# (8.75)
		k2 := min(k2, a3t / (1.5 * dc))				# (8.74)
		
	elif member(ToothedPlatetype, {"C10", "C11"}) then

		a3t := max(1.5 * dc, 7 * d, 80 * Unit('mm'));	# (8.77)		
		k2 := min(k2, a3t / (2.0 * dc))				# (8.76)
		
	end if;

	# k3 (8.78)
	rho_k_ := convert(min(entries(rho_k, 'nolist')), 'unit_free');
	k3 := min(1.5, rho_k_ / 350);						# (8.78)

	# Fv_Rk
	if member(ToothedPlatetype, {"C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8", "C9"}) then

		F_vRk := 18 * k1 * k2 * k3 * convert(dc, 'unit_free')^1.5 * Unit('N')
		
	elif member(ToothedPlatetype, {"C10", "C11"}) then

		F_vRk := 25 * k1 * k2 * k3 * convert(dc, 'unit_free')^1.5 * Unit('N')

	end if; 

	F_vRk := convert(F_vRk, 'units', 'kN');
	F_vRkfin := F_vRk * shearplanes;
	F_vRd := eval(F_vRkfin * min(entries(k_mod, 'nolist')) / gamma_M);

	fastenervalues["F_vRk_810"] := F_vRkfin;
	fastenervalues["F_vRd_810"] := F_vRd;
	comments["810"] := "Toothed Plate Connectors";

	# print
	if ComponentExists("TextArea_ToothedPlatehc") then
		SetProperty("TextArea_ToothedPlatehc", value, round(convert(hc, unit_free)))
	end if;
	
	if ComponentExists("MathContainer_F_vRk_810") then
		SetProperty("MathContainer_F_vRk_810", value, round2(F_vRk, 1))
	end if;

	if ComponentExists("MathContainer_F_vRd_810") then
		SetProperty("MathContainer_F_vRd_810", value, round2(F_vRd, 1))
	end if;
	
	if ComponentExists("TextArea_ToothedPlatek1") then
		SetProperty("TextArea_ToothedPlatek1", value, round2(k1, 2))
	end if;

	if ComponentExists("TextArea_ToothedPlatek2") then
		SetProperty("TextArea_ToothedPlatek2", value, round2(k2, 2))
	end if;

	if ComponentExists("TextArea_ToothedPlatek3") then
		SetProperty("TextArea_ToothedPlatek3", value, round2(k3, 2))
	end if;

	if ComponentExists("MathContainer_ToothedPlatea3t") then
		SetProperty("MathContainer_ToothedPlatea3t", value, round(a3t))
	end if;

	return F_vRkfin, F_vRd		# both values including shearplanes
	
end proc: