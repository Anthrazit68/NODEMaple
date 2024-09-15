# SetVisibilityComboboxConnection
# validateConnection
# SetComboConnection
# SetComboFasteners
# SetVisibilityWasher
# SetVisibilityTimberCut
# SetComboFastenersAfterXMLImport
# SetComboConnectionAfterXMLImport
# SetComboBoxSharpMetal
# SetComboBoxToothedPlateConnectors

SetVisibilityComboboxConnection := proc(WhateverYouNeed::table)
	description "Set visibility of combobox according to type of connection";
	local structure, i, components;

	structure := WhateverYouNeed["calculations"]["structure"];
	components := table();

	components["steel"] := {"ComboBox_steelgrade", "TextArea_graindirectionsteel", "TextArea_bsteel", "TextArea_hsteel", "TextArea_lengthleftsteel", "TextArea_lengthrightsteel",
			"CheckBox_Cutleftsteel", "CheckBox_Cutrightsteel", "TextArea_activematerialsteel", "TextArea_activesectionsteel",
			"TextArea_a1_minsteel", "TextArea_a2_minsteel", "TextArea_a3_minsteel", "TextArea_a4_minsteel", "TextArea_a1steel", "TextArea_a2steel", "TextArea_a3steel", "TextArea_a4steel",
			"TextArea_etaBoltSteel_active", "MathContainer_N_plRd", "MathContainer_N_uRd", "MathContainer_F_vRd_bolt", "MathContainer_F_bRd_steel"};

	components["timber"] := {"ComboBox_timbertype",
				"ComboBox_b",
				"ComboBox_h",
				"Button_th",
				"TextArea_b",
				"TextArea_h",
				"TextArea_graindirection",
				"ComboBox_strengthclass",
				"CheckBox_Cutleft",
				"CheckBox_Cutright",
				"TextArea_lengthleft",
				"TextArea_lengthright",
				"TextArea_activematerial",
				"TextArea_activesection"};

	components["results"] := {"f_h0k", "f_hk", "t", "t_eff", "h_min", "l_min", "alpha_rho", "R_axk", "R_headk", "eta814", "F_vEd", "F_90Rd", "h_e", "h_e_side", "w", "eta814_NA_DE", "k_r", "a_r", "k_s", 
					"t_ef_814_NA_DE", "F_90Rd_NA_DE", "k_ef", "n_ef0", "k_n_ef0", "k_n_efa", "eta62net", "F_xEd", "Agross_net", "Igross_net"};

	components["mindist"] := {"TextArea_a1_min", "TextArea_a2_min", "TextArea_a3t_min", "TextArea_a3c_min","TextArea_a4t_min", "TextArea_a4c_min","TextArea_a1", "TextArea_a2", "TextArea_a3", "TextArea_a4",
						"TextArea_a1_min_max", "TextArea_a2_min_max", "TextArea_a3t_min_max", "TextArea_a3c_min_max","TextArea_a4t_min_max", "TextArea_a4c_min_max"};

	# steel	
	for i in components["steel"] do
		if structure["connection"]["connection1"] = "Steel" or structure["connection"]["connection2"] = "Steel" then
			SetProperty(i, 'enabled', "true");
		else
			SetProperty(i, 'enabled', "false");
		end if;
	end do;

	SetProperty("TextArea_b1outside", 'enabled', "false");
	
	# Connection type
	# steel on the outside (both sides)
	if structure["connection"]["connection1"] = "Steel" then
		for i in components["timber"] do
			SetProperty(cat(i, "1"), 'enabled', "false");
		end do;
		
		HighlightResults(cat~(components["results"], "1"), "deactivate");
				
		SetProperty("ComboBox_connection2", value, "Timber");
		structure["connection"]["connection2"] := "Timber";

		for i in components["timber"] do
			SetProperty(cat(i, "2"), 'enabled', "true");
		end do;
					
		# SetVisibilityTimberCut();

		# if there is steel on the outside, we allow 1 inside timber layer only
		SetProperty("ComboBox_connectionInsideLayers", value, "1");
		structure["connection"]["connectionInsideLayers"] := 1;		

		# minimumdistance
		for i in components["mindist"] do
			SetProperty(cat(i, "1"), 'enabled', "false");
		end do;

	elif structure["connection"]["connection1"] = "Timber" then	
		
		for i in components["timber"] do
			SetProperty(cat(i, "1"), 'enabled', "true");			
		end do;
		
		HighlightResults(cat~(components["results"], "1"), "activate");	

		if structure["connection"]["connection2"] = "Steel" and structure["connection"]["connectionInsideLayers"] > 1 then
			SetProperty("TextArea_b1outside", 'enabled', "true");
		end if;
		
		# SetVisibilityTimberCut();		
		
		# minimumdistance
		for i in components["mindist"] do
			SetProperty(cat(i, "1"), 'enabled', "true");
		end do;
		
	end if;

	# inside layer	
	for i in components["timber"] do
		if structure["connection"]["connection2"] = "Timber" then
			SetProperty(cat(i, "2"), 'enabled', "true");
		else
			SetProperty(cat(i, "2"), 'enabled', "false");
		end if;
	end do;
	
	if structure["connection"]["connection2"] = "Timber" then
		HighlightResults(cat~(components["results"], "2"), "activate")
	else
		HighlightResults(cat~(components["results"], "2"), "deactivate")
	end if;		

	# minimumdistance
	for i in components["mindist"] do
		if structure["connection"]["connection2"] = "Timber" then
			SetProperty(cat(i, "2"), 'enabled', "true");
		else
			SetProperty(cat(i, "2"), 'enabled', "false");
		end if;			
	end do;			

	SetVisibilityTimberCut();
	
end proc:


validateConnection := proc(WhateverYouNeed::table)
	description "Check various combinations of geometry and fasteners";
	local structure, warnings, fastenervalues;

	structure := WhateverYouNeed["calculations"]["structure"];
	warnings := WhateverYouNeed["warnings"];
	fastenervalues := WhateverYouNeed["calculatedvalues"]["fastenervalues"];

	if structure["connection"]["connection1"] = "Steel" and structure["connection"]["connection2"] = "Steel" then
		Alert("2x steel not allowed", warnings, 5);
		
	elif structure["connection"]["connection1"] = "Steel" and structure["connection"]["connectionInsideLayers"] = 0 then
		Alert("Steel needs to be on the inside in connections with one shear plane", warnings, 5);
		
	elif (structure["fastener"]["chosenFastener"] = "Nail" or structure["fastener"]["chosenFastener"] = "Screw") and structure["connection"]["connection2"] = "Steel" and fastenervalues["shearplanes"] > 1 then
		Alert("Use of nails or screws in connection with inside steelplates not allowed", warnings, 5);
		
	end if;

	if not(structure["connection"]["connection1"] = "Timber" and structure["connection"]["connection2"] = "Steel") then
		if WhateverYouNeed["calculations"]["structure"]["connection"]["b1outside"] <> "false" then
			Alert("Different outer layer only allowed in timber / steel connections", warnings, 5);
		end if;
	end if;
end proc:


SetComboConnection := proc(WhateverYouNeed::table)
	description "Setting Combobox after changing of connection";
	local connection;

	connection := WhateverYouNeed["calculations"]["structure"]["connection"];

	connection["connection1"] := GetProperty("ComboBox_connection1", 'value');
	connection["connection2"] := GetProperty("ComboBox_connection2", 'value');	
	connection["connectionInsideLayers"] := parse(GetProperty("ComboBox_connectionInsideLayers", 'value'));
	connection["connectionInsideTolerance"] := parse(GetProperty("TextArea_connectionInsideTolerance", 'value')) * Unit('mm');
	SetVisibilityComboboxConnection(WhateverYouNeed);		# EC5_8_SetVisibilityCombobox
end proc:


SetComboFasteners := proc(n::integer)
	description "Setting Combobox after change of fasteners";
	# n	
	# 0...changed fastener type
	# 1...changed diameter

	local fastenerProducer, fastenerProduct, dummy, dummy1, d, d_, ls_, dh_, washerProducer, chosenFastener, ind, val, foundvalue, items;

	dummy := n;

	# get fastener type
	chosenFastener := GetProperty("ComboBox_chosenFastener", 'value');
	
	# changed fastener
	# https://www.mapleprimes.com/questions/231924-Which-Set-Sort-Order
	if dummy = 0 then
		# structure := SetVisibilityComboboxConnection(structure);

		# general settings
		SetProperty("ComboBox_nailForm", 'enabled', "false");
		SetProperty("ComboBox_nailSurface", 'enabled', "false");			
		SetProperty("ComboBox_fastener_dh", 'enabled', "true");
		SetProperty("TextArea_fastener_dh", 'enabled', "true");

		SetProperty("CheckBox_calculateAsNail", value, "false");
		SetProperty("CheckBox_calculateAsNail", 'enabled', "false");

		SetProperty("Slider_alphaScrew", value, 90);
		# assign('alphaScrew', GetProperty("Slider_alphaScrew", 'value') * Unit('degree'));
		SetProperty("Slider_alphaScrew", 'enabled', "false");

		SetVisibilityWasher("deactivate");
			
		if chosenFastener = "Nail" then
			SetProperty("ComboBox_nailForm", 'enabled', "true");
			SetProperty("ComboBox_nailSurface", 'enabled', "true");
			SetProperty("CheckBox_calculateAsNail", 'enabled', "true");
			SetProperty("Slider_alphaScrew", 'enabled', "true");
			
		elif chosenFastener = "Screw" then
			SetProperty("CheckBox_calculateAsNail", 'enabled', "true");
			SetProperty("Slider_alphaScrew", 'enabled', "true");
			
		elif chosenFastener = "Bolt" then
			# SetProperty("ComboBox_fastener_dh", 'enabled', "false");
			# SetProperty("TextArea_fastener_dh", 'enabled', "false");
			SetVisibilityWasher("activate")

		elif chosenFastener = "Dowel" then
			SetProperty("ComboBox_fastener_dh", 'enabled', "false");
			SetProperty("TextArea_fastener_dh", 'enabled', "false");
			#
	
		end if;	
		items := convert~(NODETimberFasteners:-fasteners_d[chosenFastener], 'unit_free');
		SetProperty("ComboBox_fastener_d", 'itemList', items);
		SetProperty("ComboBox_fastener_d", 'selectedIndex', 0);
		dummy := 1;
	end if;
	
	if dummy = 1 then
		assign('d_', parse(GetProperty("ComboBox_fastener_d", 'value')));
		SetProperty("TextArea_fastener_d", value, d_);
	else
		assign('d_', parse(GetProperty("TextArea_fastener_d", 'value')));
	end if;
	d := d_ * Unit('mm');	
	
	# changed diameter
	if dummy = 1 or dummy = 11 then
		dummy := 2;
		items := sort(convert(NODETimberFasteners:-fasteners_producers[chosenFastener, convert(d, 'unit_free')], list), lexorder);
		SetProperty("ComboBox_fastenerProducer", 'itemList', items);
		SetProperty("ComboBox_fastenerProducer", 'selectedIndex', 0);
	end if;

	assign('fastenerProducer', GetProperty("ComboBox_fastenerProducer", 'value'));
	# changed fastener producer
	if dummy = 2 then
		items := sort(convert(NODETimberFasteners:-fasteners_products[chosenFastener, convert(d, 'unit_free'), fastenerProducer], list), lexorder);
		SetProperty("ComboBox_fastenerProduct", 'itemList', items);
		SetProperty("ComboBox_fastenerProduct", 'selectedIndex', 0);
		if fastenerProducer = "ISO 4014" then
			SetProperty("ComboBox_boltgrade", 'enabled', "true");			
		else
			SetProperty("ComboBox_boltgrade", 'enabled', "false")
		end if;
		dummy := 3;
	end if;	

	assign('fastenerProduct', GetProperty("ComboBox_fastenerProduct", 'value'));
	# changed product
	if dummy = 3 then
		dummy1 := NODETimberFasteners:-detailinformation[fastenerProducer, fastenerProduct][1];
		if whattype(dummy1) = float then	# no text, probably empty field that has been converted to 0 in the list
			dummy1 := ""
		end if;
		dummy1 := cat(dummy1, ", usable for serviceclass ", round(NODETimberFasteners:-serviceclass[fastenerProducer, fastenerProduct][1]));
		SetProperty("TextArea_detailinformation", value, dummy1);
		items := round~(convert~(NODETimberFasteners:-l[fastenerProducer, fastenerProduct, convert(d, 'unit_free')], 'unit_free'));
		SetProperty("ComboBox_fastener_ls", 'itemList', items);
		SetProperty("ComboBox_fastener_ls", 'selectedIndex', 0);

		dummy := 45;		# changed diameter or product -> ls og dh need to be changed, washer needs to be checked and probably changed
	end if;

	# changed ls
	if dummy = 4 or dummy = 41 or dummy = 45 then
		if dummy = 4 or dummy = 45 then
			ls_ := parse(GetProperty("ComboBox_fastener_ls", 'value'));
			SetProperty("TextArea_fastener_ls", value, ls_);
			items := round~(convert~(NODETimberFasteners:-dh[fastenerProducer, fastenerProduct, convert(d, 'unit_free'), round(ls_)], 'unit_free'));
			SetProperty("ComboBox_fastener_dh", 'itemList', items);
			SetProperty("ComboBox_fastener_dh", 'selectedIndex', 0);						
			
		elif dummy = 41 then # ls chosen manually
			assign('ls_', parse(GetProperty("TextArea_fastener_ls", 'value')));
		end if;	

		dummy := 55;

	end if;
	
	# dh
	if chosenFastener <> "Dowel" and (dummy = 5 or dummy = 51 or dummy = 55) then
		if dummy = 5 or dummy = 55 then
			dh_ := parse(GetProperty("ComboBox_fastener_dh", 'value'));
			SetProperty("TextArea_fastener_dh", value, dh_);
				
		elif dummy = 51 then 	# dh manuelt
			assign('dh_', parse(GetProperty("TextArea_fastener_dh", 'value')));
		end if;
	end if;

	# check if we need washers
	SetProperty("CheckBox_screwWithWasher", 'enabled', "false");
	if chosenFastener = "Bolt" then
		if dummy = 45 then	# change from fastener, diameter or something else
			items := sort(convert(NODETimberFastenersWashers:-producers[convert(d, 'unit_free')], list), lexorder);
			SetProperty("ComboBox_washerProducer", 'itemList', items);
			SetProperty("ComboBox_washerProducer", 'selectedIndex', 0);
			dummy := 6
		end if;

		assign('washerProducer', GetProperty("ComboBox_washerProducer", 'value'));
		# changed washer producer
		if dummy = 6 then	
			items := sort(convert(NODETimberFastenersWashers:-producer_products[convert(d, 'unit_free'), washerProducer], list), lexorder);
			SetProperty("ComboBox_washerProduct", 'itemList', items);
			SetProperty("ComboBox_washerProduct", 'selectedIndex', 0);
			dummy := 61
		end if;

		# changed washer product
		# assign('washerProduct', GetProperty("ComboBox_washerProduct", 'value'));
		
	elif chosenFastener = "Screw" then
		# assign('washerProducer', GetProperty("ComboBox_washerProducer", 'value'));

		if assigned(NODETimberFastenersWashers:-producer_products[convert(d, 'unit_free'), fastenerProducer]) then

			foundvalue := "";
			for val in NODETimberFastenersWashers:-producer_products[convert(d, 'unit_free'), fastenerProducer] do
				
				# type of screw must match text in detailinformation of washer
				if member(fastenerProduct, NODETimberFastenersWashers:-detailinformation[convert(d, 'unit_free'), fastenerProducer, val]) = true then
					foundvalue := val;
				end if;		
				
			end do;
			
			if foundvalue <> "" then
				SetProperty("CheckBox_screwWithWasher", 'enabled', "true");
				
				if GetProperty("CheckBox_screwWithWasher", 'value') = "true" then
					SetVisibilityWasher("activate");

					# find Washer Producer
					for ind, val in GetProperty("ComboBox_washerProducer", 'itemList') do
						if val = fastenerProducer then
							SetProperty("ComboBox_washerProducer", 'selectedIndex', ind-1)
						end if;
					end do;
					
					# find matching Washer Product
					for ind, val in GetProperty("ComboBox_washerProduct", 'itemList') do
						if val = foundvalue then
							SetProperty("ComboBox_washerProduct", 'selectedIndex', ind-1)
						end if;
					end do;
				else
					SetVisibilityWasher("deactivate")
				end if;
			else
				SetProperty("CheckBox_screwWithWasher", 'enabled', "false");
				SetVisibilityWasher("deactivate")
			end if;	
		else
			SetProperty("CheckBox_screwWithWasher", 'enabled', "false")
		end if;
		
	end if;

end proc:


SetVisibilityWasher := proc(SetStatus::string)
	description "Set visibility of input and output fields according to washer status";

	if SetStatus = "activate" then
		SetProperty("ComboBox_washerProducer", 'enabled', "true");
		SetProperty("ComboBox_washerProduct", 'enabled', "true");
		SetProperty("MathContainer_washer_dint", 'visible', "true");
		SetProperty("MathContainer_washer_dext", 'visible', "true");
		SetProperty("MathContainer_washer_s", 'visible', "true");
		SetProperty("MathContainer_washer_N_axk", 'visible', "true");
	elif SetStatus = "deactivate" then
		SetProperty("ComboBox_washerProducer", 'enabled', "false");
		SetProperty("ComboBox_washerProduct", 'enabled', "false");
		SetProperty("MathContainer_washer_dint", 'visible', "false");
		SetProperty("MathContainer_washer_dext", 'visible', "false");
		SetProperty("MathContainer_washer_s", 'visible', "false");
		SetProperty("MathContainer_washer_N_axk", 'visible', "false");
	end if;
end proc:


SetVisibilityTimberCut := proc()
	description "Set visibility of lengthleft TextArea";
	local minimumangle, i, j, a; 		# dummy1, dummy2

	minimumangle := 30 ; 	#degree, https://www.dlubal.com/en/support-and-learning/support/faq/004645	
	a := table;

	# get name of active parts of the connection
	for i in {"1", "2", "steel"} do
		if GetProperty(cat("TextArea_graindirection", i), 'enabled') = "true" then
			
			if assigned(a[1]) = false then
				j := 1
			elif assigned(a[2]) = false then
				j := 2
			end if;
			a[j] := i;
			
		end if;			
	end do;

	# do some checks
	if numelems(a) <> 2 then
		Alert("SetVisibilityTimberCut: number of elements in connection invalid", table(), 2);
	end if;

	for i from 1 to 2 do
		if type(parse(GetProperty(cat("TextArea_graindirection", a[i]), 'value')), numeric) = false then
			SetProperty(cat("TextArea_graindirection", a[i]), 'value', 0);
			Alert(cat("graindirection for ", a[i], " non-numeric, value set to 0"), table(), 2);
		end if;
	end do;

	# set visibility of CheckBox for cuts
	if abs(parse(GetProperty(cat("TextArea_graindirection", a[1]), 'value')) - parse(GetProperty(cat("TextArea_graindirection", a[2]), 'value'))) < minimumangle then
		SetProperty(cat("CheckBox_Cutleft", a[1]), 'enabled', "false");
		SetProperty(cat("CheckBox_Cutright", a[1]), 'enabled', "false");
		SetProperty(cat("CheckBox_Cutleft", a[2]), 'enabled', "false");
		SetProperty(cat("CheckBox_Cutright", a[2]), 'enabled', "false");
	else
		SetProperty(cat("CheckBox_Cutleft", a[1]), 'enabled', "true");
		SetProperty(cat("CheckBox_Cutright", a[1]), 'enabled', "true");
		SetProperty(cat("CheckBox_Cutleft", a[2]), 'enabled', "true");
		SetProperty(cat("CheckBox_Cutright", a[2]), 'enabled', "true");
	end if;
		
	# set visibility of TextArea box for cutlength
	# inactive because we want to allow for beam ends to be parallel to other part in defined distance
#	for dummy1 in {"left", "right"} do
#		for dummy2 in entries(a, 'nolist') do
#			if GetProperty(cat("CheckBox_Cut", dummy1, dummy2), 'enabled') = "true" then
#				if GetProperty(cat("CheckBox_Cut", dummy1, dummy2), 'value') = "true" then
#					SetProperty(cat("TextArea_length", dummy1, dummy2), 'enabled', "false")
#				else
#					SetProperty(cat("TextArea_length", dummy1, dummy2), 'enabled', "true")
#				end if;
#			else
#				if GetProperty(cat("TextArea_graindirection", dummy2), 'enabled') = "true" then
#					SetProperty(cat("TextArea_length", dummy1, dummy2), 'enabled', "true")
#				end if;
#			end if;
#		end do;
#	end do;

end proc:


SetComboBoxSharpMetal := proc(n::integer, WhateverYouNeed::table)
	description "Set ComboBox for Sharp Metal values";
	local SharpMetalActive, SharpMetalWithScrew, SharpMetalProducer, SharpMetalProduct, SharpMetalWidth;
	local dummy, dummy1, maxNumberOfStripes, i, NumberOfStripes, width, structure, sectiondataAll, warnings;

	# local variables
	structure := WhateverYouNeed["calculations"]["structure"];
	warnings := WhateverYouNeed["warnings"];
	sectiondataAll := WhateverYouNeed["sectiondataAll"];
	
	# n
	# 0...switch active / inactive
	# 1...producer
	# 2...product
	# 3...new calculation of number of stripes, get materialdata, e.g. due to changed timber section
	# 4...number of stripes changed

	SharpMetalActive := GetProperty("CheckBox_SharpMetalActive", value);

	dummy := n;
	SharpMetalWithScrew := "true";

	if dummy = -1 then
		SetProperty("CheckBox_SharpMetalActive", value, "false");
		SetProperty("ComboBox_SharpMetalProducer", 'enabled', "false");
		SetProperty("ComboBox_SharpMetalProduct", 'enabled', "false");
		SetProperty("TextArea_SharpMetalInfo", 'enabled', "false");
		SetProperty("ComboBox_SharpMetalStripes", 'enabled', "false");
		return
	end if;

	# check if usable
	if SharpMetalActive = "true" and (structure["connection"]["connection1"] <> "Timber" or structure["connection"]["connection2"] <> "Timber") then
		Alert("SharpMetal can only be used in timber - timber connections", warnings, 3);
		SetProperty("CheckBox_SharpMetalActive", value, "false");
		return
	end if;

	# Sharp Metal on/off setting changed
	if dummy = 0 then		
		if SharpMetalActive = "true" then
			SetComboBoxToothedPlateConnectors(-1, WhateverYouNeed);
			SetProperty("ComboBox_SharpMetalProducer", 'enabled', "true");
			SetProperty("ComboBox_SharpMetalProducer", 'itemList', sort(NODETimberFastenersSharpMetal:-producers[SharpMetalWithScrew]));
			SetProperty("ComboBox_SharpMetalProducer", 'selectedindex', 0);
		else
			SetProperty("ComboBox_SharpMetalProducer", 'enabled', "false");
			SetProperty("ComboBox_SharpMetalProduct", 'enabled', "false");
			SetProperty("TextArea_SharpMetalInfo", 'enabled', "false");
			SetProperty("ComboBox_SharpMetalStripes", 'enabled', "false");
			return
		end if;
		dummy := 1;
	end if;

	# Producer changed
	if dummy = 1 then
		SharpMetalProducer := GetProperty("ComboBox_SharpMetalProducer", value);
		SetProperty("ComboBox_SharpMetalProduct", 'enabled', "true");
		SetProperty("ComboBox_SharpMetalProduct", 'itemList', sort(NODETimberFastenersSharpMetal:-products[SharpMetalWithScrew, SharpMetalProducer]));
		SetProperty("ComboBox_SharpMetalProduct", 'selectedindex', 0);
		dummy := 2;
	end if;

	# Product changed
	if dummy = 2 then
		SharpMetalProduct := GetProperty("ComboBox_SharpMetalProduct", value);
		SetProperty("TextArea_SharpMetalInfo", 'enabled', "true");
		SetProperty("TextArea_SharpMetalInfo", value, NODETimberFastenersSharpMetal:-detailinformation[SharpMetalWithScrew, SharpMetalProducer, SharpMetalProduct][1]);
		dummy := 3;
	end if;

	SharpMetalProducer := GetProperty("ComboBox_SharpMetalProducer", value);
	SharpMetalProduct := GetProperty("ComboBox_SharpMetalProduct", value);
	SharpMetalWidth := NODETimberFastenersSharpMetal:-width[SharpMetalWithScrew, SharpMetalProducer, SharpMetalProduct][1];
	SetProperty("TextArea_SharpMetalWidth", value, round(convert(SharpMetalWidth, 'unit_free')));

	# calculate number of stripes
	if dummy = 3 then
		maxNumberOfStripes := round(evalf(min(sectiondataAll["1"]["h"], sectiondataAll["2"]["h"]) / SharpMetalWidth));
		if maxNumberOfStripes = 0 then
			Alert("Timber section too low for Sharp Metal", warnings, 3);
		else
			SetProperty("ComboBox_SharpMetalStripes", 'enabled', "true");
			dummy1 := {};
			for i from 1 to maxNumberOfStripes do
				dummy1 := dummy1 union {i};
			end do;
			SetProperty("ComboBox_SharpMetalStripes", 'itemList', dummy1);
			SetProperty("ComboBox_SharpMetalStripes", 'selectedindex', 0);				
		end if;
		dummy := 4;
	end if;

	# number of stripes changed
	if dummy = 4 then
		NumberOfStripes := GetProperty("ComboBox_SharpMetalStripes", 'selectedindex') + 1;
		width := NumberOfStripes * SharpMetalWidth;
	end if;
end proc:


SetComboBoxToothedPlateConnectors := proc(n::integer, WhateverYouNeed::table)
	description "Toothed Plate Connectores (Bulldogs)";
	local structure, fastener, fastenervalues, warnings, ToothedPlateActive, dummy, db, d, items, i, componentsEnabled;
# DEBUG();
	# local variables
	structure := WhateverYouNeed["calculations"]["structure"];
	warnings := WhateverYouNeed["warnings"];
	fastener := structure["fastener"];
	fastenervalues := WhateverYouNeed["calculatedvalues"]["fastenervalues"];
	d := structure["fastener"]["fastener_d"];						# bolt diameter

	componentsEnabled := {"ComboBox_ToothedPlatesides",
					"ComboBox_ToothedPlatetype",
					"ComboBox_ToothedPlatedc", 
					"TextArea_ToothedPlatek1", 
					"TextArea_ToothedPlatek2",
					"TextArea_ToothedPlatek3"};
	
	# n
	# 0...switch active / inactive
	# 1...platesides
	# 2...platetype

	dummy := n;	

	# might have Sharp Metal activated, disable ToothedPlateConnectors
	if dummy = -1 then				
		SetProperty("CheckBox_ToothedPlateActive", 'value', "false");
		for i in componentsEnabled do
			SetProperty(i, 'enabled', "false");
		end do;
		SetProperty("MathContainer_F_vRk_810", 'value', 0);
		SetProperty("MathContainer_F_vRd_810", 'value', 0);
		SetProperty("MathContainer_ToothedPlatea3t", 'value', 0);
		return	
	end if;

	# Sharp Metal on/off setting changed
	if dummy = 0 then		
		ToothedPlateActive := GetProperty("CheckBox_ToothedPlateActive", value);
		if ToothedPlateActive = "true" then
			SetComboBoxSharpMetal(-1, WhateverYouNeed);		# can't have SharpMetal and Toothed-Plates together
			for i in componentsEnabled do
				SetProperty(i, 'enabled', "true");
			end do;			
			# SetProperty("ComboBox_ToothedPlatesides", 'selectedindex', 0);			
		else
			for i in componentsEnabled do
				SetProperty(i, 'enabled', "false");
			end do;
			SetProperty("MathContainer_F_vRk_810", 'value', 0);
			SetProperty("MathContainer_F_vRd_810", 'value', 0);
			SetProperty("MathContainer_ToothedPlatea3t", 'value', 0);
			return;
		end if;
		dummy := 1;
	else
		ToothedPlateActive := fastener["ToothedPlateActive"];
	end if;

	# Platesides changed
	if dummy = 1 then
		fastener["ToothedPlatesides"] := GetProperty("ComboBox_ToothedPlatesides", value);		
		items := NODETimberToothedPlateConnectors:-type[fastener["ToothedPlatesides"]];
		SetProperty("ComboBox_ToothedPlatetype", 'itemList', items);
		if numelems(items) = 0 then
			Alert("No valid Toothed Plate Connectors for plate sides", warnings, 1);
			return
		end if;
		SetProperty("ComboBox_ToothedPlatetype", 'selectedindex', 0);
		dummy := 2;
	end if;

	# Platetype changed
	# get list of inner diameters  for connection
	# compare with bolt diameters, and pick the one that fits best
	if dummy = 2 then
		fastener["ToothedPlatetype"] := GetProperty("ComboBox_ToothedPlatetype", value);		
		items := sort(NODETimberToothedPlateConnectors:-db[fastener["ToothedPlatesides"], fastener["ToothedPlatetype"]]);		# sorted list of hole diameters for bolt
		
		db := 0;
		for i in items do
			if i >= d then
				db := i;
				break
			end if;
		end do;
		
		if i = 0 then
			Alert("No valid Toothed Plate Connector found: db too small for bolt diameter", warnings, 3);
			return
		else
			fastenervalues["ToothedPlatedb"] := round(convert(db, 'unit_free'))
		end if;

		items := round~(convert~(NODETimberToothedPlateConnectors:-dc[fastener["ToothedPlatesides"], fastener["ToothedPlatetype"], fastenervalues["ToothedPlatedb"]], 'unit_free'));
		
		SetProperty("ComboBox_ToothedPlatedc", 'itemList', items);
		if numelems(items) <> 0 then
			SetProperty("ComboBox_ToothedPlatedc", 'selectedindex', 0);			
		end if;
		
		dummy := 3;	
	end if;

end proc: