# NODETimber - EC5_8

# InitSpecific
# ResetSpecific
# RunAfterRestoresettings
# MainWrapper
# ReadComponentsSpecific
# Main
# SetComboFastenersAfterXMLImport
# SetComboConnectionAfterXMLImport

InitSpecific := proc()
	description "Declare some global variables before use";
	global WhateverYouNeed;
	local var_calculations, var_calculations_FastenerPatterns, var_calculations_fasteners, FastenerPatterns, var_numeric, var_loadvariables, var_connection_cut, var_connection_length, var_connection_graindirection;
	
	WhateverYouNeed["calculations"]["calculationtype_short"] := "EC5 part 1-1 Connections";		# for export to Excel
	
	# libFastenerPattern start
	var_calculations_FastenerPatterns := {"positionnumber", "activeloadcase", "activematerial1", "activematerial2", "activesection1", "activesection2", "positiontitle", "FastenerPatternUnits", "FastenerPatternCoordinates",
					"FastenerPatternType1", "center_x1", "center_y1", "grid_x1", "grid_y1", "grid_alpha_11", "grid_alpha_21", "radial_diameter1", "radial_items1", "radial_alpha1",
					"FastenerPatternType2", "center_x2", "center_y2", "grid_x2", "grid_y2", "grid_alpha_12", "grid_alpha_22", "radial_diameter2", "radial_items2", "radial_alpha2",
					"FastenerPatternType3", "center_x3", "center_y3", "grid_x3", "grid_y3", "grid_alpha_13", "grid_alpha_23", "radial_diameter3", "radial_items3", "radial_alpha3",
					"coordinates", "reactionforces"};

	var_loadvariables := {"f_814"};

	var_calculations_fasteners := {"connection1", "connection2", "connectionInsideLayers", "connectionInsideTolerance", "serviceclass", "loaddurationclass", "timbertype1", "strengthclass1", "b1", "b1outside", "h1", "graindirection1",
					"timbertype2", "strengthclass2", "b2", "h2", "graindirection2", "graindirectionsteel", "steeltype", "bsteel", "hsteel", "lengthleftsteel", "lengthrightsteel",
					"chosenFastener", "calculateAsNail", "nailForm", "nailSurface", "fastener_d", "fastenerProducer", "fastenerProduct", "fastener_ls", "fastener_dh",
					"washerProducer", "washerProduct", "screwWithWasher", "staggered_0", "staggered_90",
					"doublesided", "predrilled", "ignoreReqPredrilled", "alphaScrew", "a11", "a12", "a21", "a22", "a31", "a32", "a41", "a42", "lengthleft1", "lengthright1", "lengthleft2", "lengthright2",
					"SharpMetalActive", "SharpMetalProducer", "SharpMetalProduct", "SharpMetalStripes", "SharpMetalLength",
					"ToothedPlateActive", "ToothedPlatesides", "ToothedPlatetype", "ToothedPlatedc"};

	var_calculations := var_calculations_FastenerPatterns union var_calculations_fasteners;

	# all variables starting with those values are numeric, grid is NOT (2*70)
	var_numeric := {"center_", "radial_", "loadcenter_", "fastener_d", "fastener_ls", "lengthleft", "lengthright", "graindirection", "connectionInsideTolerance", "connectionInsideLayers", "b1outside",
				"SharpMetalLength", "ToothedPlatedc"};

	var_connection_cut := {"Cutleft1", "Cutleft2", "Cutright1", "Cutright2", "Cutleftsteel", "Cutrightsteel"};
	var_connection_length := {"lengthleft1", "lengthright1", "lengthleft2", "lengthright2", "lengthleftsteel", "lengthrightsteel"};

	WhateverYouNeed["componentvariables"]["var_calculations"] := WhateverYouNeed["componentvariables"]["var_calculations"] union var_calculations;
	WhateverYouNeed["componentvariables"]["var_numeric"] := eval(var_numeric);
	# WhateverYouNeed["componentvariables"]["var_calculationdata"] := eval(WhateverYouNeed["componentvariables"]["var_calculationdata"] union {"activeFastenerPattern", "activematerial1", "activematerial2", "activematerialsteel", 
	#				"activesection1", "activesection2", "activesectionsteel"});
	#WhateverYouNeed["componentvariables"]["var_storeitems"] := eval(WhateverYouNeed["componentvariables"]["var_storeitems"] union {"calculations/activeFastenerPattern", "calculations/activematerial1", "calculations/activematerial2",
	#				"calculations/activematerialsteel", "calculations/activesection1", "calculations/activesection2", "calculations/activesectionsteel"});
	WhateverYouNeed["componentvariables"]["var_ComboBox"] := eval(WhateverYouNeed["componentvariables"]["var_ComboBox"] union {"FastenerPatterns", "connection", "fastener"});		# Comboboxes where there are stored a list of settings

	WhateverYouNeed["calculations"]["loadvariables"] := WhateverYouNeed["calculations"]["loadvariables"] union var_loadvariables;

	WhateverYouNeed["componentvariables"]["var_connection_cut"] := var_connection_cut;
	WhateverYouNeed["componentvariables"]["var_connection_length"] := var_connection_length;
	WhateverYouNeed["componentvariables"]["var_connection_graindirection"] := {"graindirection1", "graindirection2", "graindirectionsteel"};

	# need to setup variable for storing values, but only if missing
	if assigned(WhateverYouNeed["calculations"]["structure"]["FastenerPatterns"]) = false then
		FastenerPatterns := table();
		WhateverYouNeed["calculations"]["structure"]["FastenerPatterns"] := eval(FastenerPatterns)
	end if;	
end proc:


ResetSpecific := proc(WhateverYouNeed::table)
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


RunAfterRestoresettings := proc(WhateverYouNeed::table)
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
			NODETimberEN1995:-SetComboBox(WhateverYouNeed, false, partsnumber);			
		end if;

		if assigned(WhateverYouNeed["calculations"]["activesettings"][cat("activesection", partsnumber)]) then
			activesection := WhateverYouNeed["calculations"]["activesettings"][cat("activesection", partsnumber)];
			NODETimberEN1995:-GetSectiondata(activesection, WhateverYouNeed);			
			sectiondataAll[partsnumber] := eval(WhateverYouNeed["sectiondata"]);
			
			dummy := GetProperty(cat("ComboBox_b", partsnumber), 'itemlist');
			dummy1 := convert(convert(sectiondataAll[partsnumber]["b"], 'unit_free'), string);
			if member(dummy1, dummy, 'pos') then
				SetProperty(cat("ComboBox_b", partsnumber), 'selectedindex', pos-1);
				NODETimberEN1995:-Changed_bh(WhateverYouNeed, cat("b", partsnumber));
			end if;
			SetProperty(cat("TextArea_b", partsnumber), 'value', dummy1);

			dummy := GetProperty(cat("ComboBox_h", partsnumber), 'itemlist');
			dummy1 := convert(convert(sectiondataAll[partsnumber]["h"], 'unit_free'), string);
			if member(dummy1, dummy, 'pos') then
				SetProperty(cat("ComboBox_h", partsnumber), 'selectedindex', pos-1);				
			end if;
			SetProperty(cat("TextArea_h", partsnumber), 'value', dummy1);
			
			# NODETimberEN1995:-SetComboBox(WhateverYouNeed, false, partsnumber);			
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
		SetProperty("TextArea_bsteel", 'value', convert(WhateverYouNeed["sectiondataAll"]["steel"]["b"], 'unit_free'));
		SetProperty("TextArea_hsteel", 'value', convert(WhateverYouNeed["sectiondataAll"]["steel"]["h"], 'unit_free'));
		
	end if;

end proc:


runAfterXMLImportLocal := proc(WhateverYouNeed::table, i::string)
	description "Procedure run after import of XML file, called in NODEXML:-runAfterXMLImport";
	local warnings;

	warnings := WhateverYouNeed["warnings"];

	if i = "fastener" then
		SetComboFastenersAfterXMLImport(WhateverYouNeed);		# EC5_8_SetVisibilityCombobox
	elif i = "connection" then
		SetComboConnectionAfterXMLImport(WhateverYouNeed)		# EC5_8_SetVisibilityCombobox
	else
		Alert(cat("runAfterXMLUImportLocal: unhandled command ", i), warnings, 2);
	end if;
end proc:



# wrapper for running main calculation routine
MainWrapper := proc(action::string)
	description "Run main calculation";
	global WhateverYouNeed;

	# start calculation if either required by command or autoloadsave true
	if action = "calculation" or WhateverYouNeed["calculations"]["autocalc"] then
		Main(WhateverYouNeed);
	end if;
end proc:


# this one is started by ReadSystemSection
ReadComponentsSpecific := proc(TypeOfAction::string, WhateverYouNeed::table)	
	description "Read specific structure and section data";
	local structure, connection, fastener, fastenervalues, dummy, dummy1, distance, comments, activesettings, calculations, warnings;

	calculations := WhateverYouNeed["calculations"];	
	structure := calculations["structure"];
	warnings := WhateverYouNeed["warnings"];
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
		fastener["chosenFastener"] := GetProperty("ComboBox_chosenFastener", 'value');
		fastener["calculateAsNail"] := GetProperty("CheckBox_calculateAsNail", 'value');
		
		if GetProperty("ComboBox_nailForm", 'enabled') = "true" then
			fastener["nailForm"] := GetProperty("ComboBox_nailForm", 'value');
			fastener["nailSurface"] := GetProperty("ComboBox_nailSurface", 'value');
		else
			fastener["nailForm"] := "false";
			fastener["nailSurface"] := "false";
		end if;

		fastener["fastenerProducer"] := GetProperty("ComboBox_fastenerProducer", 'value');
		fastener["fastenerProduct"] := GetProperty("ComboBox_fastenerProduct", 'value');	
		fastenervalues["detailinformation"] := NODETimberFasteners:-detailinformation[fastener["fastenerProducer"], fastener["fastenerProduct"]][1];
		fastenervalues["serviceclass"] := NODETimberFasteners:-serviceclass[fastener["fastenerProducer"], fastener["fastenerProduct"]][1];
		fastener["fastener_d"] := parse(GetProperty("TextArea_fastener_d", 'value')) * Unit('mm');
		fastener["fastener_ls"] := parse(GetProperty("TextArea_fastener_ls", 'value')) * Unit('mm');
		fastener["fastener_dh"] := parse(GetProperty("TextArea_fastener_dh", 'value')) * Unit('mm');
		if GetProperty("ComboBox_boltgrade", enabled) = "true" then
			fastener["boltgrade"] := GetProperty("ComboBox_boltgrade", 'value');
		else
			fastener["boltgrade"] := evaln(fastener["boltgrade"])
		end if;

		fastenervalues["M_yRk"] := eval(NODETimberFasteners:-M_yRk[fastener["fastenerProducer"], fastener["fastenerProduct"], convert(fastener["fastener_d"], 'unit_free')][1]);
		fastenervalues["f_axk"] := eval(NODETimberFasteners:-f_axk[fastener["fastenerProducer"], fastener["fastenerProduct"], convert(fastener["fastener_d"], 'unit_free')][1]);
		fastenervalues["f_headk"] := eval(NODETimberFasteners:-f_headk[fastener["fastenerProducer"], fastener["fastenerProduct"], convert(fastener["fastener_d"], 'unit_free')][1]);
		fastenervalues["f_tensk"] := eval(NODETimberFasteners:-f_tensk[fastener["fastenerProducer"], fastener["fastenerProduct"], convert(fastener["fastener_d"], 'unit_free')][1]);
		fastenervalues["l1"] := eval(NODETimberFasteners:-l1[fastener["fastenerProducer"], fastener["fastenerProduct"], convert(fastener["fastener_d"], 'unit_free'), convert(fastener["fastener_ls"], 'unit_free')][1]);
		fastenervalues["l2"] := eval(NODETimberFasteners:-l2[fastener["fastenerProducer"], fastener["fastenerProduct"], convert(fastener["fastener_d"], 'unit_free'), convert(fastener["fastener_ls"], 'unit_free')][1]);
		fastenervalues["f_uk"] := eval(NODETimberFasteners:-f_uk[fastener["fastenerProducer"], fastener["fastenerProduct"], convert(fastener["fastener_d"], 'unit_free'), convert(fastener["fastener_ls"], 'unit_free')][1]);
		
		if GetProperty("ComboBox_washerProducer", 'enabled') = "true" then
			fastener["washerProducer"] := GetProperty("ComboBox_washerProducer", 'value');
			fastener["washerProduct"] := GetProperty("ComboBox_washerProduct", 'value');
			
			fastenervalues["washerInfo"] := NODETimberFastenersWashers:-detailinformation[convert(fastener["fastener_d"], 'unit_free'), fastener["washerProducer"], fastener["washerProduct"]][1];
			fastenervalues["washer_dint"] := eval(NODETimberFastenersWashers:-dint[convert(fastener["fastener_d"], 'unit_free'), fastener["washerProducer"], fastener["washerProduct"]][1]);
			fastenervalues["washer_dext"] := eval(NODETimberFastenersWashers:-dext[convert(fastener["fastener_d"], 'unit_free'), fastener["washerProducer"], fastener["washerProduct"]][1]);
			fastenervalues["washer_s"] := eval(NODETimberFastenersWashers:-s[convert(fastener["fastener_d"], 'unit_free'), fastener["washerProducer"], fastener["washerProduct"]][1]);
			fastenervalues["washer_A_ef"] := eval(NODETimberFastenersWashers:-A_ef(convert(fastener["fastener_d"], 'unit_free'), fastener["washerProducer"], fastener["washerProduct"]));
			fastenervalues["washer_N_axk"] := eval(NODETimberFastenersWashers:-N_axk(convert(fastener["fastener_d"], 'unit_free'), fastener["washerProducer"], fastener["washerProduct"]));

			SetProperty("TextArea_washerInfo", value, fastenervalues["washerInfo"]);
			SetProperty("MathContainer_washer_dint", value, round2(fastenervalues["washer_dint"],1));
			SetProperty("MathContainer_washer_dext", value, round2(fastenervalues["washer_dext"],1));
			SetProperty("MathContainer_washer_s", value, round2(fastenervalues["washer_s"],1));
			SetProperty("MathContainer_washer_N_axk", value, round2(fastenervalues["washer_N_axk"],1));
	
		else
			fastener["washerProducer"] := "false";
			fastener["washerProduct"] := "false";
		end if;

		if GetProperty("CheckBox_screwWithWasher", 'enabled') = "true" then
			fastener["screwWithWasher"] := GetProperty("CheckBox_screwWithWasher", 'value')
		else
			fastener["screwWithWasher"] := "false"
		end if;

		# SharpMetal
		fastener["SharpMetalActive"] := GetProperty("CheckBox_SharpMetalActive", 'value');

		if fastener["SharpMetalActive"] = "true" then
			fastener["SharpMetalProducer"] := GetProperty("ComboBox_SharpMetalProducer", 'value');
			fastener["SharpMetalProduct"] := GetProperty("ComboBox_SharpMetalProduct", 'value');
			fastener["SharpMetalStripes"] := GetProperty("ComboBox_SharpMetalStripes", 'value');
			fastener["SharpMetalLength"] := parse(GetProperty("TextArea_SharpMetalLength", 'value')) * Unit('mm');
			#
			fastenervalues["SharpMetal_f_v0k"] := eval(NODETimberFastenersSharpMetal:-f_v0k["true", fastener["SharpMetalProducer"], fastener["SharpMetalProduct"]][1]);
			fastenervalues["SharpMetal_f_v90k"] := eval(NODETimberFastenersSharpMetal:-f_v90k["true", fastener["SharpMetalProducer"], fastener["SharpMetalProduct"]][1]);
			fastenervalues["SharpMetal_f_vEGk"] := eval(NODETimberFastenersSharpMetal:-f_vEGk["true", fastener["SharpMetalProducer"], fastener["SharpMetalProduct"]][1]);

			fastenervalues["SharpMetal_k_ser0k"] := eval(NODETimberFastenersSharpMetal:-k_ser0k["true", fastener["SharpMetalProducer"], fastener["SharpMetalProduct"]][1]);
			fastenervalues["SharpMetal_k_ser90k"] := eval(NODETimberFastenersSharpMetal:-k_ser90k["true", fastener["SharpMetalProducer"], fastener["SharpMetalProduct"]][1]);
			fastenervalues["SharpMetal_k_serEGk"] := eval(NODETimberFastenersSharpMetal:-k_serEGk["true", fastener["SharpMetalProducer"], fastener["SharpMetalProduct"]][1]);
			
		else
			fastener["SharpMetalProducer"] := "false";
			fastener["SharpMetalProduct"] := "false";
			fastener["SharpMetalStripes"] := "false";
			fastener["SharpMetalLength"] := "0"
		end if;

		# ToothedPlate
		fastener["ToothedPlateActive"] := GetProperty("CheckBox_ToothedPlateActive", 'value');

		if fastener["ToothedPlateActive"] = "true" then
			fastener["ToothedPlatesides"] := GetProperty("ComboBox_ToothedPlatesides", value);
			fastener["ToothedPlatetype"] := GetProperty("ComboBox_ToothedPlatetype", value);
			fastener["ToothedPlatedc"] := parse(GetProperty("ComboBox_ToothedPlatedc", 'value')) * Unit('mm');

			# need to define db value
			local itemlist, db, i;
			itemlist := sort(NODETimberToothedPlateConnectors:-db[fastener["ToothedPlatesides"], fastener["ToothedPlatetype"]]);		# list of hole diameters for bolt				
			db := 0;			
			for i in itemlist do
				if i >= structure["fastener"]["fastener_d"] then
					db := i;
					break
				end if;
			end do;
		
			if i = 0 then
				Alert("No valid Toothed Plate Connector found: db too small for bolt diameter", warnings, 3);
				return
			else
				fastenervalues["ToothedPlatedb"] := round(convert(db, 'unit_free'));
				SetProperty("TextArea_ToothedPlatedb", value, fastenervalues["ToothedPlatedb"])
			end if;
			
		else
			fastener["ToothedPlatesides"] := "false";
			fastener["ToothedPlatetype"] := "false";
			fastener["ToothedPlatedc"] := "false";			
		end if;		

		fastener["staggered_0"] := GetProperty("CheckBox_staggered_0", 'value');
		fastener["staggered_90"] := GetProperty("CheckBox_staggered_90", 'value');
		fastener["doublesided"] := GetProperty("CheckBox_doublesided", 'value');
		fastener["predrilled"] := GetProperty("CheckBox_predrilled", 'value');
		if fastener["predrilled"] = "true" then
			SetProperty("CheckBox_ignoreReqPredrilled", value, "false");
			SetProperty("CheckBox_ignoreReqPredrilled", 'enabled', "false")
		else
			SetProperty("CheckBox_ignoreReqPredrilled", 'enabled', "true")
		end if;
		fastener["ignoreReqPredrilled"] := GetProperty("CheckBox_ignoreReqPredrilled", 'value');

		if GetProperty("Slider_alphaScrew", 'enabled') = "true" then
			fastener["alphaScrew"] := GetProperty("Slider_alphaScrew", 'value') * Unit('degree')
		else
			fastener["alphaScrew"] := "false"
		end if;

		# writeout properties
		SetProperty("MathContainer_M_yRk", value, round2(fastenervalues["M_yRk"], 2));		# might need to calculated M_yRk
		SetProperty("MathContainer_f_axk", 'fillcolor', "white");						# might have been changed by calculate_f_axk
		SetProperty("MathContainer_f_axk", value, round2(fastenervalues["f_axk"], 2));		# see calculate_f_axk
		SetProperty("MathContainer_f_headk", 'fillcolor', "white");
		SetProperty("MathContainer_f_headk", value, round2(fastenervalues["f_headk"], 2));
		SetProperty("MathContainer_f_tensk", value, round2(fastenervalues["f_tensk"], 2));
	end if;

	if TypeOfAction = "all" or TypeOfAction = "layout" or TypeOfAction = "connection" then
		SetVisibilityTimberCut();

		for dummy in {"activematerial", "activesection"} do
			for dummy1 in {"", "1", "2", "steel"} do
				if ComponentExists(cat("TextArea_", dummy, dummy1)) and GetProperty(cat("TextArea_", dummy, dummy1), 'enabled') = "true" then
					activesettings[cat(dummy, dummy1)] := GetProperty(cat("TextArea_", dummy, dummy1), value)
				else
					if assigned(activesettings[cat(dummy, dummy1)]) then
						activesettings[cat(dummy, dummy1)] := evaln(activesettings[cat(dummy, dummy1)])
					end if;
				end if;
			end do;
		end do;
		
		# WhateverYouNeed["calculations"]["activesettings"]["activesection"] := GetProperty("TextArea_activesection", value);
		# fibre angles of timber parts, zero angle 3 o'clock counterclockwise

		# for dummy in {"timbertype1", "timbertype2", "strengthclass1", "strengthclass2", "steelcode", "steelgrade", "thicknessclass"} do
		#	if GetProperty(cat("ComboBox_", dummy), 'enabled') = "true" then
		#		connection[dummy] := GetProperty(cat("ComboBox_", dummy), 'value')
		#	else
		#		connection[dummy] := "false"
		#	end if;
		# end do;		

		if GetProperty("TextArea_b1outside", 'enabled') = "true" then
			connection["b1outside"] := parse(GetProperty("TextArea_b1outside", 'value')) * Unit('mm')
		else
			connection["b1outside"] := "false"
		end if;
		
		for dummy in WhateverYouNeed["componentvariables"]["var_connection_graindirection"] do
			if GetProperty(cat("TextArea_", dummy), 'enabled') = "true" then
				connection[dummy] := parse(GetProperty(cat("TextArea_", dummy), 'value')) * Unit('degree')
			else
				connection[dummy] := "false"
			end if;
		end do;

		for dummy in WhateverYouNeed["componentvariables"]["var_connection_cut"] do
			if GetProperty(cat("CheckBox_", dummy), 'enabled') = "true" then
				connection[dummy] := GetProperty(cat("CheckBox_", dummy), 'value')
			else
				connection[dummy] := "false"
			end if;
		end do;
		
		for dummy in WhateverYouNeed["componentvariables"]["var_connection_length"] do
			if GetProperty(cat("TextArea_", dummy), 'enabled') = "true" then
				connection[dummy] := parse(GetProperty(cat("TextArea_", dummy), 'value')) * Unit('mm')
			else
				connection[dummy] := "false"
			end if;
		end do;		
		
	end if;

	activesettings["calculate_814_NA_DE"] := GetProperty("CheckBox_calculate_814_NA_DE", 'value');

	# calculatedvalues
	
end proc:


# in case of calculateAllLoadcases this routine is run partly, but at the end a full calculation with the active loadcase is run in addition
Main := proc(WhateverYouNeed::table)
	description "Main calculation procedure, calculates values for each force";
	local calculations, activesettings, structure, comments, chosenFastener, fastener, calculatedFastener, d, warnings, fastenervalues, eta, usedcode, checkPassed, force, maxindex, usedcodeDescription;

	# declare local variables
	calculations := WhateverYouNeed["calculations"];	
	structure := calculations["structure"];
	comments := calculations["comments"];
	activesettings := calculations["activesettings"];		
	warnings := WhateverYouNeed["warnings"];
	fastener := structure["fastener"];
	fastenervalues := WhateverYouNeed["calculatedvalues"]["fastenervalues"];
	force := WhateverYouNeed["calculations"]["loadcases"][activesettings["activeloadcase"]];

	eta := table();
	WhateverYouNeed["results"]["eta"] := eta;
	usedcode := WhateverYouNeed["results"]["usedcode"];
	comments := WhateverYouNeed["results"]["comments"];
	usedcodeDescription := table();
	 
	# local variables for metal fasteners
	chosenFastener := fastener["chosenFastener"];
	d := fastener["fastener_d"];

	# are we running in a readin mode from XMLImport, prohibit change of section in MaterialChanged
	calculations["XMLImport"] := false;

	checkServiceclass(WhateverYouNeed);	# Annex

	# geometry dependent routines will not be run when calculating all loadcases
	# calculating number of shearplanes, thickness, number of timber layers in connection	
	if WhateverYouNeed["calculations"]["calculatingAllLoadcases"] = false then

		calculateShearplanes(WhateverYouNeed);		# EC5_81	
		validateConnection(WhateverYouNeed);		# EC5_8_SetVisibilityCombobox
		calculate_t_total(WhateverYouNeed);			# EC5_81
		calculate_t(WhateverYouNeed);				# EC5_83, 8.3.1.1(1), calculate t_eff, t_pen, n_tip
	

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

		# check how we should design fastener
		if (chosenFastener = "Nail" and d <= 8 * Unit('mm')) or (chosenFastener = "Screw" and d <= 6 * Unit('mm')) or fastener["calculateAsNail"] = "true" then
			calculatedFastener := "Nail"
		elif chosenFastener = "Bolt" or (chosenFastener = "Nail" and d > 8 * Unit('mm')) or (chosenFastener = "Screw" and d > 6 * Unit('mm')) then
			calculatedFastener := "Bolt"
		elif chosenFastener = "Dowel" and d > 6 * Unit('mm') and d < 30 * Unit('mm') then
			calculatedFastener := "Dowel"
		elif chosenFastener = "Screw" then		# that should be impossible
			calculatedFastener := "Screw";
			warnings := Alert("calculated fastener: Screw - should be impossible", warnings, 5);
		else								# that should be impossible either
			calculatedFastener := "Unknown";
			warnings := Alert("unknown calculated fastener", warnings, 5);
		end if;

		fastenervalues["calculatedFastener"] := calculatedFastener;
		comments["calculation"] := cat(chosenFastener, ", calculated as ", calculatedFastener);

		GetFastenervalues(WhateverYouNeed);		# EC5_83: check if fastenervalues are predefined or need to be calculated, M_yRk, f_tensk

		if MASTERALARM(warnings) = true then
			HighlightResults({"eta812_active", "eta832_active", "eta814_active", "eta833_active", "etamax_active"}, "deactivate");
			return
		end if;

		calculate_amin_max(WhateverYouNeed);		# calculate force independent minimum distance values
		
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

	if MASTERALARM(warnings) = true then
		HighlightResults({"eta812_active", "eta832_active", "eta814_active", "eta833_active", "etamax_active"}, "deactivate");
		return
	end if;

	# calculate alpha dependent values
	# as per now not implemented properly, as it is almost impossible to use proper alpha values (e.g. moment in connections, each bolt has different alpha 'value')
	if WhateverYouNeed["calculations"]["calculatingAllLoadcases"] = false then

		calculateMinimumdistances(WhateverYouNeed);		# EC5_8_minimumdistance, as per now not calculated with correct alpha angle, but alpha = 0
		# calculate_f_hk(WhateverYouNeed);				# EC5_85, characteristic embedment strength values	
		calculate_n_ef(WhateverYouNeed);				# calculate reduction factor for fasteners in a row

		if MASTERALARM(warnings) = true then
			HighlightResults({"eta812_active", "eta832_active", "eta814_active", "eta833_active", "etamax_active"}, "deactivate");
			return
		end if;
		
	end if;

	# force in axial direction of fastener
	if WhateverYouNeed["calculations"]["calculatingAllLoadcases"] = false then
		
		calculate_F_axR(WhateverYouNeed);		# EC5_83, need to calculate value also if there is no axiallyLoaded condition (calculate_F_vR)
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

		checkPredrilled(WhateverYouNeed);			# EC5_83
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
		
	# 8.3.3
	# global chosenFastener, nailSurface, eta, eta_v, eta_ax, eta_814, F_axEd, F_vEd, F_axRd_total, F_vRd_total;
	# local variabl1es, j, dummy, dummy1;

	eta["max"] := 0;

	eta["812"], usedcode["812"], usedcodeDescription["812"] := EC5_812(WhateverYouNeed);			# 8.1.2 Multiple fastener connections
	
	eta["814"], usedcode["814"], usedcodeDescription["814"] := EC5_814(WhateverYouNeed);			# 8.1.4 Connection forces at an angle to the grain

	eta["832"], usedcode["832"], usedcodeDescription["832"] := EC5_832(WhateverYouNeed);			# 8.3.2/8.7.2 Axially loaded nails/screw

	eta["62net"], usedcode["62net"], usedcodeDescription["62net"] := EC5_62net(WhateverYouNeed);	# EC5_81, check of beam net tension area

	if WhateverYouNeed["calculatedvalues"]["axiallyLoaded"] then
		eta["833"], usedcode["833"], usedcodeDescription["833"] := EC5_833(WhateverYouNeed)		# "8.3.3 Combined laterally and axially loaded nails	
	else
		eta["833"] := 0
	end if;

	eta["AnnexA"], usedcode["AnnexA"], usedcodeDescription["AnnexA"] := AnnexA(WhateverYouNeed);

	eta["BoltSteel"], usedcode["BoltSteel"], usedcodeDescription["BoltSteel"] := BoltandSteelCapacity(WhateverYouNeed);

	eta["max"], maxindex := maxIndexTable(eta);
	comments["usedcode"] := eval(usedcode[maxindex]);
	comments["usedcodeDescription"] := eval(usedcodeDescription[maxindex]);

	# find maximum of all loadcases, print results
	Write_eta(WhateverYouNeed);
	PrintAlert(warnings);
end proc:


SetComboFastenersAfterXMLImport := proc(WhateverYouNeed::table)
	description "Setting Combobox after XML readin";

	local sectionpropertiesAll, fastener, fastenervalues, fastenerProducer, fastenerProduct, dummy, dummy1, d, d_, ls, ls_, dh, dh_, screwWithWasher, washerProducer, washerProduct, chosenFastener, pos, warnings,
		SharpMetalWithScrew, SharpMetalActive, SharpMetalProducer, SharpMetalProduct, SharpMetalStripes, SharpMetalWidth, maxNumberOfStripes, i, nailForm, nailSurface;

	warnings := WhateverYouNeed["warnings"];
	fastener := WhateverYouNeed["calculations"]["structure"]["fastener"];
	fastenervalues := WhateverYouNeed["calculatedvalues"]["fastenervalues"];
	chosenFastener := fastener["chosenFastener"];	
	sectionpropertiesAll := WhateverYouNeed["sectionpropertiesAll"];

	# 1.) chosenFastener	
	dummy := GetProperty("ComboBox_chosenFastener", 'itemlist');

	if member(chosenFastener, dummy, 'pos') then
		SetProperty("ComboBox_chosenFastener", 'selectedindex', pos-1)
	else
		Alert(cat("SetComboFastenersAfterXMLImport: chosenFastener not found: ", chosenFastener), warnings, 3)
	end if;
	
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
		nailForm := fastener["nailForm"];
		nailSurface := fastener["nailSurface"];

		dummy := GetProperty("ComboBox_nailForm", 'itemlist');
		if member(nailForm, dummy, 'pos') then
			SetProperty("ComboBox_nailForm", 'selectedindex', pos-1)		
		end if;

		dummy := GetProperty("ComboBox_nailSurface", 'itemlist');
		if member(nailSurface, dummy, 'pos') then
			SetProperty("ComboBox_nailSurface", 'selectedindex', pos-1)		
		end if;
			
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
		
	# 2.) d	
	SetProperty("ComboBox_fastener_d", 'itemList', convert~(NODETimberFasteners:-fasteners_d[chosenFastener], 'unit_free'));
	
	d := fastener["fastener_d"];
	d_ := convert(d, 'unit_free');
	
	dummy := GetProperty("ComboBox_fastener_d", 'itemlist');

	if member(convert(d_, string), dummy, 'pos') then
		SetProperty("ComboBox_fastener_d", 'selectedindex', pos-1)	
	end if;
	SetProperty("TextArea_fastener_d", 'value', d_);
	
	# 3.) Fastener producer
	SetProperty("ComboBox_fastenerProducer", 'itemList', sort(convert(NODETimberFasteners:-fasteners_producers[chosenFastener, d_], list), lexorder));

	fastenerProducer := fastener["fastenerProducer"];

	dummy := GetProperty("ComboBox_fastenerProducer", 'itemlist');

	if member(fastenerProducer, dummy, 'pos') then
		SetProperty("ComboBox_fastenerProducer", 'selectedindex', pos-1)
	else
		Alert(cat("SetComboFastenersAfterXMLImport: fastenerProducer not found: ", fastenerProducer), warnings, 2)
	end if;

	# 4.) fastenerProduct
	SetProperty("ComboBox_fastenerProduct", 'itemList', sort(convert(NODETimberFasteners:-fasteners_products[chosenFastener, convert(d, 'unit_free'), fastenerProducer], list), lexorder));

	fastenerProduct := fastener["fastenerProduct"];

	dummy := GetProperty("ComboBox_fastenerProduct", 'itemlist');

	if member(fastenerProduct, dummy, 'pos') then
		SetProperty("ComboBox_fastenerProduct", 'selectedindex', pos-1)
	else
		Alert(cat("SetComboFastenersAfterXMLImport: fastenerProduct not found: ", fastenerProduct), warnings, 2)
	end if;
	
	dummy1 := NODETimberFasteners:-detailinformation[fastenerProducer, fastenerProduct][1];
	if whattype(dummy1) = float then	# no text, probably empty field that has been converted to 0 in the list
		dummy1 := ""
	end if;
	dummy1 := cat(dummy1, ", usable for serviceclass ", round(NODETimberFasteners:-serviceclass[fastenerProducer, fastenerProduct][1]));
	SetProperty("TextArea_detailinformation", value, dummy1);
	
	# 5.) ls
	SetProperty("ComboBox_fastener_ls", 'itemList', round~(convert~(NODETimberFasteners:-l[fastenerProducer, fastenerProduct, convert(d, 'unit_free')], 'unit_free')));

	ls := fastener["fastener_ls"];
	ls_ := round(convert(ls, 'unit_free'));

	dummy := GetProperty("ComboBox_fastener_ls", 'itemlist');

	if member(convert(ls_, string), dummy, 'pos') then
		SetProperty("ComboBox_fastener_ls", 'selectedindex', pos-1)
	else
		Alert(cat("SetComboFastenersAfterXMLImport: fastener_ls not found: ", ls), warnings, 2)
	end if;
	SetProperty("TextArea_fastener_ls", 'value', ls_);
	
	# 6.) dh
	if GetProperty("ComboBox_fastener_dh", 'enabled') = "true" then		# not working for dowels
		SetProperty("ComboBox_fastener_dh", 'itemList', round~(convert~(NODETimberFasteners:-dh[fastenerProducer, fastenerProduct, convert(d, 'unit_free'), ls_], 'unit_free')));

		dh := fastener["fastener_dh"];
		dh_ := round(convert(dh, 'unit_free'));

		dummy := GetProperty("ComboBox_fastener_dh", 'itemlist');

		if member(convert(dh_, string), dummy, 'pos') then
			SetProperty("ComboBox_fastener_dh", 'selectedindex', pos-1)
		else
			Alert(cat("SetComboFastenersAfterXMLImport: fastener_dh not found: ", dh), warnings, 2)
		end if;
		SetProperty("TextArea_fastener_dh", 'value', dh_);
	end if;

	# 7.) washer

	screwWithWasher := fastener["screwWithWasher"];	
	washerProducer := fastener["washerProducer"];
	washerProduct := fastener["washerProduct"];
	
	if screwWithWasher = "false" then
		if washerProducer = "false" then
			SetProperty("CheckBox_screwWithWasher", 'enabled', "false");
		else
			SetProperty("CheckBox_screwWithWasher", 'enabled', "true");
			SetProperty("CheckBox_screwWithWasher", 'value', "false");
		end if;
	else
	end if;
	
	if washerProducer = "false" then
		SetProperty("ComboBox_washerProducer", 'enabled', "false");
	else
		SetProperty("ComboBox_washerProducer", 'enabled', "true");
		SetProperty("ComboBox_washerProducer", 'itemList', sort(convert(NODETimberFastenersWashers:-producers[convert(d, 'unit_free')], list), lexorder));
		dummy := GetProperty("ComboBox_washerProducer", 'itemlist');
		if member(washerProducer, dummy, 'pos') then
			SetProperty("ComboBox_washerProducer", 'selectedindex', pos-1)
		end if;
	end if;
	
	if washerProduct = "false" then
		SetProperty("ComboBox_washerProduct", 'enabled', "false");
	else
		SetProperty("ComboBox_washerProduct", 'enabled', "true");
		SetProperty("ComboBox_washerProduct", 'itemList', sort(convert(NODETimberFastenersWashers:-producer_products[convert(d, 'unit_free'), washerProducer], list), lexorder));
		dummy := GetProperty("ComboBox_washerProduct", 'itemlist');
		if member(washerProduct, dummy, 'pos') then
			SetProperty("ComboBox_washerProduct", 'selectedindex', pos-1)
		end if;
	end if;

	# 7.) SharpMetal
	SharpMetalWithScrew := "true";
	SharpMetalActive := fastener["SharpMetalActive"];
	SharpMetalProducer := fastener["SharpMetalProducer"];
	SharpMetalProduct := fastener["SharpMetalProduct"];
	SharpMetalStripes := fastener["SharpMetalStripes"];
	
	SetProperty("CheckBox_SharpMetalActive", 'value', SharpMetalActive);

	if SharpMetalActive = "false" then
		SetComboBoxToothedPlateConnectors(-1, WhateverYouNeed);			# can't have Bulldog and SharpMetal together
		SetProperty("ComboBox_SharpMetalProducer", 'enabled', "false");
		SetProperty("ComboBox_SharpMetalProduct", 'enabled', "false");
		SetProperty("TextArea_SharpMetalInfo", 'enabled', "false");
		SetProperty("ComboBox_SharpMetalStripes", 'enabled', "false");
	else

		if SharpMetalProducer = "false" then
			SetProperty("ComboBox_SharpMetalProducer", 'enabled', "false");
		else
			SetProperty("ComboBox_SharpMetalProducer", 'enabled', SharpMetalWithScrew);
			SetProperty("ComboBox_SharpMetalProducer", 'itemList', sort(NODETimberFastenersSharpMetal:-producers["true"]));		
			dummy := GetProperty("ComboBox_SharpMetalProducer", 'itemlist');
			if member(SharpMetalProducer, dummy, 'pos') then
				SetProperty("ComboBox_SharpMetalProducer", 'selectedindex', pos-1)
			end if;
		end if;

		if SharpMetalProduct = "false" then
			SetProperty("ComboBox_SharpMetalProduct", 'enabled', "false");
			SetProperty("TextArea_SharpMetalInfo", 'enabled', "false");
		else
			SetProperty("ComboBox_SharpMetalProduct", 'enabled', "true");
			SetProperty("TextArea_SharpMetalInfo", 'enabled', "true");
			SetProperty("ComboBox_SharpMetalProduct", 'itemList', sort(NODETimberFastenersSharpMetal:-products[SharpMetalWithScrew, SharpMetalProducer]));		
			dummy := GetProperty("ComboBox_SharpMetalProduct", 'itemlist');
			if member(SharpMetalProduct, dummy, 'pos') then
				SetProperty("ComboBox_SharpMetalProduct", 'selectedindex', pos-1);
				SetProperty("TextArea_SharpMetalInfo", value, NODETimberFastenersSharpMetal:-detailinformation[SharpMetalWithScrew, SharpMetalProducer, SharpMetalProduct][1]);
			end if;
		end if;

		if SharpMetalStripes = "false" then
			SetProperty("ComboBox_SharpMetalStripes", 'enabled', "false");
		else
			SetProperty("ComboBox_SharpMetalStripes", 'enabled', SharpMetalWithScrew);
			SharpMetalWidth := NODETimberFastenersSharpMetal:-width[SharpMetalWithScrew, SharpMetalProducer, SharpMetalProduct][1];
			maxNumberOfStripes := round(evalf(min(sectionpropertiesAll[1]["h"], sectionpropertiesAll[2]["h"]) / SharpMetalWidth));

			if maxNumberOfStripes = 0 then
				Alert("Timber section too low for Sharp Metal", warnings, 3);
			else
				dummy1 := {};
				for i from 1 to maxNumberOfStripes do
					dummy1 := dummy1 union {i};
				end do;
				SetProperty("ComboBox_SharpMetalStripes", 'itemList', dummy1);			
			end if;
					
			dummy := GetProperty("ComboBox_SharpMetalStripes", 'itemlist');
			if member(SharpMetalStripes, dummy, 'pos') then
				SetProperty("ComboBox_SharpMetalStripes", 'selectedindex', pos-1)
			else
				Alert("SharpMetalStripes: illegal number of stripes", warnings, 3)
			end if;
		end if;
		
	end if;

	# 8.) Bulldog				see also SetComboBoxToothedPlateConnectors	
	local ToothedPlateActive, ToothedPlatesides, ToothedPlatetype, ToothedPlatedc, componentsEnabled, db, items;
	ToothedPlateActive := fastener["ToothedPlateActive"];
	ToothedPlatesides := fastener["ToothedPlatesides"];
	ToothedPlatetype := fastener["ToothedPlatetype"];
	ToothedPlatedc := fastener["ToothedPlatedc"];	

	componentsEnabled := {"ComboBox_ToothedPlatesides",
					"ComboBox_ToothedPlatetype",
					"ComboBox_ToothedPlatedc", 
					"TextArea_ToothedPlatek1", 
					"TextArea_ToothedPlatek2",
					"TextArea_ToothedPlatek3"};

	SetProperty("CheckBox_ToothedPlateActive", 'value', ToothedPlateActive);

	if ToothedPlateActive = "false" then
		
		for i in componentsEnabled do
			SetProperty(i, 'enabled', "false");
		end do;
		SetProperty("MathContainer_F_vRk_810", 'value', 0);
		SetProperty("MathContainer_F_vRd_810", 'value', 0);
		SetProperty("MathContainer_ToothedPlatea3t", 'value', 0);
		
	else
		
		SetComboBoxSharpMetal(-1, WhateverYouNeed);		# can't have SharpMetal and Toothed-Plates together
		for i in componentsEnabled do
			SetProperty(i, 'enabled', "true");
		end do;

		# ToothedPlatesides
		dummy := GetProperty("ComboBox_ToothedPlatesides", 'itemlist');
		if member(ToothedPlatesides, dummy, 'pos') then
			SetProperty("ComboBox_ToothedPlatesides", 'selectedindex', pos-1)
		else
			Alert(cat("ComboBox_ToothedPlatesides: entry ", ToothedPlatesides, " not found"), warnings, 3);
		end if;

		# Toothedplatetype
		items := NODETimberToothedPlateConnectors:-type[ToothedPlatesides];
		SetProperty("ComboBox_ToothedPlatetype", 'itemList', sort(items));	
		if member(ToothedPlatetype, items, 'pos') then
			SetProperty("ComboBox_ToothedPlatetype", 'selectedindex', pos-1)
		else
			Alert(cat("ComboBox_ToothedPlatetype: entry ", ToothedPlatetype, " not found"), warnings, 3);
		end if;

		# Toothedplatedc
		# get list of inner diameters  for connection
		# compare with bolt diameters, and pick the one that fits best

		items := sort(NODETimberToothedPlateConnectors:-db[ToothedPlatesides, ToothedPlatetype]);		# sorted list of hole diameters for bolt
		
		db := 0;
		for i in items do
			if i >= d then
				db := i;
				break
			end if;
		end do;
		
		if i = 0 then
			Alert("No valid Toothed Plate Connector found: db too small for bolt diameter", warnings, 3);			
		else
			fastenervalues["ToothedPlatedb"] := round(convert(db, 'unit_free'))
		end if;

		SetProperty("TextArea_ToothedPlatedb", value, fastenervalues["ToothedPlatedb"]);

		items := round~(convert~(NODETimberToothedPlateConnectors:-dc[ToothedPlatesides, ToothedPlatetype, fastenervalues["ToothedPlatedb"]], 'unit_free'));
		SetProperty("ComboBox_ToothedPlatedc", 'itemList', sort(items));
		if member(round(convert(ToothedPlatedc, 'unit_free')), items, 'pos') then
			SetProperty("ComboBox_ToothedPlatedc", 'selectedindex', pos-1)
		else
			Alert(cat("ComboBox_ToothedPlatedc: entry ", ToothedPlatedc, " not found"), warnings, 3);
		end if;
		
	end if;

	# 9.) other values		
	if assigned(fastener["boltgrade"]) then
		SetProperty("ComboBox_boltgrade", 'enabled', "true");
		dummy := GetProperty("ComboBox_boltgrade", 'itemlist');
		if member(fastener["boltgrade"], dummy, 'pos') then
			SetProperty("ComboBox_boltgrade", 'selectedindex', pos-1)
		else
			Alert("Boltgrade not found", warnings, 3)
		end if;
	else 
		SetProperty("ComboBox_boltgrade", 'enabled', "false")
	end if;
	
end proc:


SetComboConnectionAfterXMLImport := proc(WhateverYouNeed::table)
	description "Setting Combobox after XML readin";
	local warnings, connection, i, dummy, pos, material, activematerial, forceSectionUpdate, activesection;

	warnings := WhateverYouNeed["warnings"];
	connection := WhateverYouNeed["calculations"]["structure"]["connection"];
	material := "timber";
	forceSectionUpdate := false;
	WhateverYouNeed["calculations"]["XMLImport"] := true;		# MaterialChanged must not call SectionChanged as we overwrite activesettings

	for i in {"connection1", "connection2", "connectionInsideLayers"} do
		dummy := GetProperty(cat("ComboBox_", i), 'itemlist');
		if member(convert(connection[i], string), dummy, 'pos') then			# connectionInsideLayers is numeric, must be converted to string
			SetProperty(cat("ComboBox_", i), 'selectedindex', pos-1)
		else
			Alert(cat("SetComboConnectionAfterXMLImport: ", cat("ComboBox_", i), ": entry ", connection[i], " not found"), warnings, 3)
		end if;
	end do;

	SetProperty("TextArea_connectionInsideTolerance", 'value', convert(connection["connectionInsideTolerance"], 'unit_free'));

	# setting dialogue boxes for material and section
	for i in {"1", "2", "steel"} do
		if assigned(WhateverYouNeed["calculations"]["activesettings"][cat("activematerial", i)]) then
			activematerial := WhateverYouNeed["calculations"]["activesettings"][cat("activematerial", i)];
			MaterialChanged(material, activematerial, WhateverYouNeed, forceSectionUpdate, i);
		end;
		if assigned(WhateverYouNeed["calculations"]["activesettings"][cat("activesection", i)]) then
			activesection := WhateverYouNeed["calculations"]["activesettings"][cat("activesection", i)];
			SectionChanged(material, activesection, WhateverYouNeed, i)
		end if;
	end do;

	for i in WhateverYouNeed["componentvariables"]["var_connection_graindirection"] do
		WriteValueToComponent(i, WhateverYouNeed["calculations"]["structure"]["connection"][i], {"nocheck"});	
	end do;

	for i in WhateverYouNeed["componentvariables"]["var_connection_cut"] do
		WriteValueToComponent(i, WhateverYouNeed["calculations"]["structure"]["connection"][i], {"nocheck"});	
	end do;

	for i in WhateverYouNeed["componentvariables"]["var_connection_length"] do
		WriteValueToComponent(i, WhateverYouNeed["calculations"]["structure"]["connection"][i], {"nocheck"});
	end do;

	SetVisibilityComboboxConnection(WhateverYouNeed);	
	
	# SetComboConnection(WhateverYouNeed);	
end proc: