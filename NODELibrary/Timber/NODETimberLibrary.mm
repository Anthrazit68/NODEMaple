# NODETimberLibary.mm : Routines for NODETimber
# Copyright (C) 2025  Andreas Zieritz

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

# 2025-10-20: adding version numbering
# version := "1.0.0";

CheckLoadExcentricity := proc(WhateverYouNeed::table)
	description "Check if load excentricity is compatible with opening width";
	local opening_a, activeloadcase, loadcenter_x, tolerance, warnings;

	tolerance := 1 * Unit('mm');
	opening_a := WhateverYouNeed["calculations"]["structure"]["opening"]["opening_a"];
	activeloadcase := WhateverYouNeed["calculations"]["activesettings"]["activeloadcase"];
	loadcenter_x := WhateverYouNeed["calculations"]["loadcases"][activeloadcase]["loadcenter_x"];
	warnings := WhateverYouNeed["warnings"];
	
	if type(loadcenter_x, 'with_unit') = false or evalf(abs(loadcenter_x) - opening_a / 2) > tolerance  then
	
		Alert(cat("loadcase ", activeloadcase, ": load excentricity wrong, calculating new value"), warnings, 1);
		SetLoadExcentricity(WhateverYouNeed, false);
	end if;

end proc:


ReadComponentsSpecific_connection := proc(WhateverYouNeed::table, connection::table)
	description "Subroutine for ReadeComponentsSpecific, EC5_8, connection";
	local dummy, dummy1, activesettings;

	activesettings := WhateverYouNeed["calculations"]["activesettings"];

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
	
	for dummy in WhateverYouNeed["componentvariables"]["var_connection_graindirection"] do
		if GetProperty(cat("TextArea_", dummy), 'enabled') = "true" then
			connection[dummy] := parse(GetProperty(cat("TextArea_", dummy), 'value')) * Unit('degree')
		else
			connection[dummy] := "false"
		end if;
	end do;

	for dummy in WhateverYouNeed["componentvariables"]["var_connection_cut"] do
#			if GetProperty(cat("CheckBox_", dummy), 'enabled') = "true" then
#				connection[dummy] := GetProperty(cat("CheckBox_", dummy), 'value')
		if GetProperty(cat("ComboBox_", dummy), 'enabled') = "true" then
			connection[dummy] := GetProperty(cat("ComboBox_", dummy), 'value')
		end if;
	end do;

	for dummy in WhateverYouNeed["componentvariables"]["var_connection_angle"] do
		if GetProperty(cat("TextArea_", dummy), 'enabled') = "true" then
			connection[dummy] := parse(GetProperty(cat("TextArea_", dummy), 'value')) * Unit('degree')
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

end proc:


ReadComponentsSpecific_fastener := proc(fastener::table, fastenervalues::table)
	description "Subroutine for ReadeComponentsSpecific, EC5_8, fasteners";
	local d_, ls_;
	# no unit check possible, as we do not have access to WhateverYouNeed, assumed ok (checked everywhere else)
	d_ := convert(fastener["fastener_d"], 'unit_free');		# [mm]
	ls_ := convert(fastener["fastener_ls"], 'unit_free');	# [mm]

	if ComponentExists("TextArea_numberOfFasteners") then
		fastener["numberOfFasteners"] := parse(GetProperty("TextArea_numberOfFasteners", 'value'))
	end if;

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

	fastenervalues["M_yRk"] := eval(NODETimberFasteners:-M_yRk[fastener["fastenerProducer"], fastener["fastenerProduct"], d_][1]);
	fastenervalues["f_axk"] := eval(NODETimberFasteners:-f_axk[fastener["fastenerProducer"], fastener["fastenerProduct"], d_][1]);
	fastenervalues["f_headk"] := eval(NODETimberFasteners:-f_headk[fastener["fastenerProducer"], fastener["fastenerProduct"], d_][1]);
	fastenervalues["f_tensk"] := eval(NODETimberFasteners:-f_tensk[fastener["fastenerProducer"], fastener["fastenerProduct"], d_][1]);
	fastenervalues["l1"] := eval(NODETimberFasteners:-l1[fastener["fastenerProducer"], fastener["fastenerProduct"], d_, ls_][1]);
	fastenervalues["l2"] := eval(NODETimberFasteners:-l2[fastener["fastenerProducer"], fastener["fastenerProduct"], d_, ls_][1]);
	fastenervalues["f_uk"] := eval(NODETimberFasteners:-f_uk[fastener["fastenerProducer"], fastener["fastenerProduct"], d_, ls_][1]);
	fastenervalues["b_max"] := eval(NODETimberFasteners:-b_max[fastener["fastenerProducer"], fastener["fastenerProduct"], d_, ls_][1]);

	if GetProperty("ComboBox_washerProducer", 'enabled') = "true" then

		fastener["washerProducer"] := GetProperty("ComboBox_washerProducer", 'value');
		fastener["washerProduct"] := GetProperty("ComboBox_washerProduct", 'value');
		
		fastenervalues["washerInfo"] := NODETimberFastenersWashers:-detailinformation[d_, fastener["washerProducer"], fastener["washerProduct"]][1];
		fastenervalues["washer_dint"] := eval(NODETimberFastenersWashers:-dint[d_, fastener["washerProducer"], fastener["washerProduct"]][1]);
		fastenervalues["washer_dext"] := eval(NODETimberFastenersWashers:-dext[d_, fastener["washerProducer"], fastener["washerProduct"]][1]);
		fastenervalues["washer_s"] := eval(NODETimberFastenersWashers:-s[d_, fastener["washerProducer"], fastener["washerProduct"]][1]);
		fastenervalues["washer_A_ef"] := eval(NODETimberFastenersWashers:-A_ef(d_, fastener["washerProducer"], fastener["washerProduct"]));
		fastenervalues["washer_N_axk"] := eval(NODETimberFastenersWashers:-N_axk(d_, fastener["washerProducer"], fastener["washerProduct"]));

		WriteValueToComponent("washerInfo", fastenervalues["washerInfo"], {"nocheck"});
		WriteValueToComponent("washer_dint", round2(fastenervalues["washer_dint"],1), {"nocheck"});
		WriteValueToComponent("washer_dext", round2(fastenervalues["washer_dext"],1), {"nocheck"});
		WriteValueToComponent("washer_s", round2(fastenervalues["washer_s"],1), {"nocheck"});
		WriteValueToComponent("washer_N_axk", round2(fastenervalues["washer_N_axk"],1), {"nocheck"});		
	
	else
		fastener["washerProducer"] := "false";
		fastener["washerProduct"] := "false";
	end if;

	if GetProperty("CheckBox_screwWithWasher", 'enabled') = "true" then
		fastener["screwWithWasher"] := GetProperty("CheckBox_screwWithWasher", 'value')
	else
		fastener["screwWithWasher"] := "false"
	end if;

	if ComponentExists("ComboBox_ShearConnector") then
		
		fastener["ShearConnector"] := GetProperty("ComboBox_ShearConnector", 'value');

		# SharpMetal		
		if fastener["ShearConnector"] = "Sharp Metal" then
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

		# Split ring
		if fastener["ShearConnector"] = "Split ring" then
			fastener["SplitRingtype"] := GetProperty("ComboBox_SplitRingtype", value);
			fastener["SplitRingdc"] := parse(GetProperty("ComboBox_SplitRingdc", 'value')) * Unit('mm');
			fastenervalues["SplitRingt"] := NODETimberSplitRing:-t[fastener["SplitRingtype"], round(convert(fastener["SplitRingdc"], 'unit_free'))][1];		# inner circle;
			
			WriteValueToComponent("SplitRingt", round(convert(fastenervalues["SplitRingt"], 'unit_free')), {"nocheck"});		
			fastenervalues["SplitRinghc"] := NODETimberSplitRing:-hc[fastener["SplitRingtype"], round(convert(fastener["SplitRingdc"], 'unit_free'))][1];		# inner circle;
			WriteValueToComponent("SplitRinghc", round(convert(fastenervalues["SplitRinghc"], 'unit_free')), {"nocheck"});					
		else
			fastener["SplitRingtype"] := "false";
			fastener["SplitRingdc"] := "false"
		end if;

		# ToothedPlate
		if fastener["ShearConnector"] = "Toothed-plate" then
			fastener["ToothedPlatesides"] := GetProperty("ComboBox_ToothedPlatesides", value);
			fastener["ToothedPlatetype"] := GetProperty("ComboBox_ToothedPlatetype", value);
			fastener["ToothedPlatedc"] := parse(GetProperty("ComboBox_ToothedPlatedc", 'value')) * Unit('mm');
			fastenervalues["ToothedPlated1"] := NODETimberToothedPlateConnectors:-d1[fastener["ToothedPlatesides"], fastener["ToothedPlatetype"], round(convert(fastener["ToothedPlatedc"], 'unit_free'))][1];		# inner circle;
			SetProperty("TextArea_ToothedPlatedb", 'value',round(convert(fastenervalues["ToothedPlated1"], 'unit_free')));
			fastenervalues["ToothedPlatehc"] := NODETimberToothedPlateConnectors:-hc[fastener["ToothedPlatesides"], fastener["ToothedPlatetype"], round(convert(fastener["ToothedPlatedc"], 'unit_free'))][1];		# height of teeth;
			SetProperty("TextArea_ToothedPlatehc", 'value',round(convert(fastenervalues["ToothedPlatehc"], 'unit_free')));
		else
			fastener["ToothedPlatesides"] := "false";
			fastener["ToothedPlatetype"] := "false";
			fastener["ToothedPlatedc"] := "false";			
		end if;
		
	end if;

	if ComponentExists("CheckBox_staggered1") and ComponentExists("CheckBox_staggered2") then
		fastener["staggered1"] := GetProperty("CheckBox_staggered1", 'value');
		fastener["staggered2"] := GetProperty("CheckBox_staggered2", 'value');
	end if;
	
	fastener["predrilled"] := GetProperty("CheckBox_predrilled", 'value');
	if fastener["predrilled"] = "true" then
		SetProperty("CheckBox_ignoreReqPredrilled", 'value',"false");
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
	SetProperty("MathContainer_M_yRk", 'value',round2(fastenervalues["M_yRk"], 2));		# might need to calculated M_yRk
	SetProperty("MathContainer_f_axk", 'fillcolor', "white");						# might have been changed by calculate_f_axk
	SetProperty("MathContainer_f_axk", 'value',round2(fastenervalues["f_axk"], 2));		# see calculate_f_axk
	SetProperty("MathContainer_f_headk", 'fillcolor', "white");
	SetProperty("MathContainer_f_headk", 'value',round2(fastenervalues["f_headk"], 2));
	SetProperty("MathContainer_f_tensk", 'value',round2(fastenervalues["f_tensk"], 2));

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
		end if;
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

	for i in WhateverYouNeed["componentvariables"]["var_connection_angle"] do
		WriteValueToComponent(i, WhateverYouNeed["calculations"]["structure"]["connection"][i], {"nocheck"});	
	end do;

	for i in WhateverYouNeed["componentvariables"]["var_connection_length"] do
		WriteValueToComponent(i, WhateverYouNeed["calculations"]["structure"]["connection"][i], {"nocheck"});
	end do;

	SetVisibilityComboboxConnection(WhateverYouNeed);	
	
	# SetComboConnection(WhateverYouNeed);	
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
		# SetProperty("Slider_alphaScrew", 'enabled', "false");

		SetVisibilityWasher("deactivate");
			
		if chosenFastener = "Nail" then
			SetProperty("ComboBox_nailForm", 'enabled', "true");
			SetProperty("ComboBox_nailSurface", 'enabled', "true");
			SetProperty("CheckBox_calculateAsNail", 'enabled', "true");
			# SetProperty("Slider_alphaScrew", 'enabled', "true");
			
		elif chosenFastener = "Screw" then
			SetProperty("CheckBox_calculateAsNail", 'enabled', "true");
			# SetProperty("Slider_alphaScrew", 'enabled', "true");
			
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
		d_ := parse(GetProperty("ComboBox_fastener_d", 'value'));
		SetProperty("TextArea_fastener_d", value, d_);
	else
		d_ := parse(GetProperty("TextArea_fastener_d", 'value'));
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
			dh_ := parse(GetProperty("TextArea_fastener_dh", 'value'));
		end if;
	end if;

	# check if we need washers
	SetProperty("CheckBox_screwWithWasher", 'enabled', "false");
	if chosenFastener = "Bolt" then
		if dummy = 55 then	# change from fastener, diameter or something else
			items := sort(convert(NODETimberFastenersWashers:-producers[convert(d, 'unit_free')], list), lexorder);
			SetProperty("ComboBox_washerProducer", 'itemList', items);
			SetProperty("ComboBox_washerProducer", 'selectedIndex', 0);
			dummy := 6
		end if;

		washerProducer := GetProperty("ComboBox_washerProducer", 'value');
		# changed washer producer
		if dummy = 6 then	
			items := sort(convert(NODETimberFastenersWashers:-producer_products[convert(d, 'unit_free'), washerProducer], list), lexorder);
			SetProperty("ComboBox_washerProduct", 'itemList', items);
			SetProperty("ComboBox_washerProduct", 'selectedIndex', 0);
			dummy := 61
		end if;

		# changed washer product
		# washerProduct := GetProperty("ComboBox_washerProduct", 'value');		no need for that one, as it will be read by ReadComponentsSpecific
		
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


SetComboFastenersAfterXMLImport := proc(WhateverYouNeed::table)
	description "Setting Combobox after XML readin";

	local sectionpropertiesAll, fastener, fastenervalues, fastenerProducer, fastenerProduct, dummy, dummy1, d, d_, ls, ls_, dh, dh_, screwWithWasher, washerProducer, washerProduct, chosenFastener, pos, warnings,
		items, i, j, nailForm, nailSurface;

	warnings := WhateverYouNeed["warnings"];
	fastener := WhateverYouNeed["calculations"]["structure"]["fastener"];
	fastenervalues := WhateverYouNeed["calculatedvalues"]["fastenervalues"];
	chosenFastener := fastener["chosenFastener"];	
	sectionpropertiesAll := WhateverYouNeed["sectionpropertiesAll"];

	# 0.) numberOfFasteners
	if ComponentExists("TextArea_numberOfFasteners") then
		SetProperty("TextArea_numberOfFasteners", 'value', fastener["numberOfFasteners"])
	end if;

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

	SetProperty("CheckBox_calculateAsNail", 'value',"false");
	SetProperty("CheckBox_calculateAsNail", 'enabled', "false");

	SetProperty("Slider_alphaScrew", 'value',90);
	# assign('alphaScrew', GetProperty("Slider_alphaScrew", 'value') * Unit('degree'));
	# SetProperty("Slider_alphaScrew", 'enabled', "false");

	SetVisibilityWasher("deactivate");
			
	if chosenFastener = "Nail" then
		SetProperty("ComboBox_nailForm", 'enabled', "true");
		SetProperty("ComboBox_nailSurface", 'enabled', "true");
		SetProperty("CheckBox_calculateAsNail", 'enabled', "true");
#		SetProperty("Slider_alphaScrew", 'enabled', "true");
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
#		SetProperty("Slider_alphaScrew", 'enabled', "true");
			
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
	d_ := ConvertUnitfree("fastener_d", d, WhateverYouNeed);
	
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
	dummy1 := cat(dummy1, ", serviceclass ", round(NODETimberFasteners:-serviceclass[fastenerProducer, fastenerProduct][1]));
	SetProperty("TextArea_detailinformation", 'value',dummy1);
	
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

	# 8.) Shear Connector
	local ShearConnector, ShearComponents, activate;
	
	ShearConnector := fastener["ShearConnector"];
	dummy := GetProperty("ComboBox_ShearConnector", 'itemlist');
	if member(ShearConnector, dummy, 'pos') then
		SetProperty("ComboBox_ShearConnector", 'selectedindex', pos-1)
	else
		Alert(cat("ComboBox_ShearConnector: entry ", ShearConnector, " not found"), warnings, 3);
	end if;
	
	ShearComponents := table();
	ShearComponents["-"] := {};
	ShearComponents["Sharp Metal"] := {"ComboBox_SharpMetalProducer", "ComboBox_SharpMetalProduct", 
								"TextArea_SharpMetalInfo", "ComboBox_SharpMetalStripes", "TextArea_SharpMetalLength"};
								
	ShearComponents["Split ring"] := {"ComboBox_SplitRingtype", "ComboBox_SplitRingdc", "TextArea_SplitRingt", "TextArea_SplitRinghc"};
	
	ShearComponents["Toothed-plate"] := {"ComboBox_ToothedPlatesides", "ComboBox_ToothedPlatetype", "ComboBox_ToothedPlatedc", 
								"TextArea_ToothedPlatek1", "TextArea_ToothedPlatek2", "TextArea_ToothedPlatek3",
								"MathContainer_F_vRk_89_810", "MathContainer_F_vRd_89_810", "MathContainer_ToothedPlatea3t"};
								
	for i in {"Sharp Metal", "Split ring", "Toothed-plate"} do
		
		if i = ShearConnector then
			activate := "true"
		else
			activate := "false"
		end if;
		
		for j in ShearComponents[i] do
			if searchtext("MathContainer", j) = 0 then
				SetProperty(j, 'enabled', activate)
			elif activate = "false" then
				SetProperty(j, 'value', 0)
			end if
		end do;		
	end do;

	# 9.) SharpMetal
	local SharpMetalWithScrew, SharpMetalProducer, SharpMetalProduct, SharpMetalStripes, SharpMetalWidth, SharpMetalLength, maxNumberOfStripes;
	SharpMetalWithScrew := "true";
	SharpMetalProducer := fastener["SharpMetalProducer"];
	SharpMetalProduct := fastener["SharpMetalProduct"];
	SharpMetalStripes := fastener["SharpMetalStripes"];
	SharpMetalLength := fastener["SharpMetalLength"];
	
	if ShearConnector = "Sharp metal" then
		SetProperty("ComboBox_SharpMetalProducer", 'itemList', sort(NODETimberFastenersSharpMetal:-producers["true"]));		
		dummy := GetProperty("ComboBox_SharpMetalProducer", 'itemlist');
		if member(SharpMetalProducer, dummy, 'pos') then
			SetProperty("ComboBox_SharpMetalProducer", 'selectedindex', pos-1)
		else
			Alert(cat("ComboBox_SharpMetalProducer: entry ", SharpMetalProducer, " not found"), warnings, 3);
		end if;

		SetProperty("ComboBox_SharpMetalProduct", 'itemList', sort(NODETimberFastenersSharpMetal:-products[SharpMetalWithScrew, SharpMetalProducer]));		
		dummy := GetProperty("ComboBox_SharpMetalProduct", 'itemlist');
		if member(SharpMetalProduct, dummy, 'pos') then
			SetProperty("ComboBox_SharpMetalProduct", 'selectedindex', pos-1);
			SetProperty("TextArea_SharpMetalInfo", 'value',NODETimberFastenersSharpMetal:-detailinformation[SharpMetalWithScrew, SharpMetalProducer, SharpMetalProduct][1]);
		else
			Alert(cat("ComboBox_SharpMetalProduct: entry ", SharpMetalProduct, " not found"), warnings, 3);
		end if;

		SharpMetalWidth := NODETimberFastenersSharpMetal:-width[SharpMetalWithScrew, SharpMetalProducer, SharpMetalProduct][1];
		SetProperty("TextArea_SharpMetalWidth", 'value',round~(convert~(SharpMetalWidth, 'unit_free')));
		SetProperty("TextArea_SharpMetalLength", 'value',round~(convert~(SharpMetalLength, 'unit_free')));
		
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

	# 10. Split ring
	local SplitRingtype, SplitRingdc, dc, t;
	SplitRingtype := fastener["SplitRingtype"];
	SplitRingdc := fastener["SplitRingdc"];

	if ShearConnector = "Split ring" then

		dummy := sort(NODETimberSplitRing:-type);
		SetProperty("ComboBox_SplitRingtype", 'itemList', dummy);
		# dummy := GetProperty("ComboBox_SplitRingtype", 'itemlist');
		if member(SplitRingtype, dummy, 'pos') then
			SetProperty("ComboBox_SplitRingtype", 'selectedindex', pos-1)
		else
			Alert(cat("ComboBox_SplitRingtype: entry ", SplitRingtype, " not found"), warnings, 3);
		end if;

		items := sort(NODETimberSplitRing:-dc[SplitRingtype]);		# sorted list of external diameter
		for dc in items do
			t := NODETimberSplitRing:-t[fastener["SplitRingtype"], round(convert(dc, 'unit_free'))][1];		# thickness
			if dc - 2 * t <= d then				
				items := items minus {dc}		# center hole diameter too small, remove item from list
			end if;			
		end do;

		dummy := round~(convert~(items, 'unit_free'));
		SetProperty("ComboBox_SplitRingdc", 'itemList', dummy);
		# dummy := GetProperty("ComboBox_SplitRingdc", 'itemlist');
		dummy1 := round(convert(SplitRingdc, 'unit_free'));
		if member(dummy1, dummy, 'pos') then
			SetProperty("ComboBox_SplitRingdc", 'selectedindex', pos-1)
		else
			Alert(cat("ComboBox_SplitRingdc: entry ", dummy1, " not found"), warnings, 3);
		end if;		
	end if;
	
	# 11.) Bulldog				see also SetComboBoxToothedPlateConnectors	
	local ToothedPlatesides, ToothedPlatetype, ToothedPlatedc, componentsEnabled, db;
	ToothedPlatesides := fastener["ToothedPlatesides"];
	ToothedPlatetype := fastener["ToothedPlatetype"];
	ToothedPlatedc := fastener["ToothedPlatedc"];	

	if fastener["ShearConnector"] = "Toothed-plate" then
		
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

		items := sort(round~(convert~(NODETimberToothedPlateConnectors:-dc[ToothedPlatesides, ToothedPlatetype], 'unit_free')));		# sorted list of hole diameters for bolt
		
		SetProperty("ComboBox_ToothedPlatedc", 'itemList', items);
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


SetVisibilityComboboxConnection := proc(WhateverYouNeed::table)
	description "Set visibility of combobox according to type of connection";
	local structure, i, components;

	structure := WhateverYouNeed["calculations"]["structure"];
	components := table();

	components["steel"] := {"ComboBox_steelgrade", "TextArea_graindirectionsteel", "TextArea_section_bsteel", "TextArea_section_hsteel", "TextArea_lengthleftsteel", "TextArea_lengthrightsteel",
			"TextArea_angleleftsteel", "TextArea_anglerightsteel", "ComboBox_cutleftsteel", "ComboBox_cutrightsteel", "TextArea_activematerialsteel", "TextArea_activesectionsteel",
			"TextArea_a1_minsteel", "TextArea_a2_minsteel", "TextArea_a3_minsteel", "TextArea_a4_minsteel", "TextArea_a1steel", "TextArea_a2steel", "TextArea_a3steel", "TextArea_a4steel",
			"TextArea_etaBoltSteel_active", "MathContainer_N_plRd", "MathContainer_N_uRd", "MathContainer_F_vRd_bolt", "MathContainer_F_bRd_steel"};

	components["timber"] := {"ComboBox_timbertype",
				"ComboBox_section_b",
				"ComboBox_section_h",
				"Button_th",
				"TextArea_section_b",
				"TextArea_section_h",
				"TextArea_graindirection",
				"ComboBox_strengthclass",
				"ComboBox_cutleft",
				"ComboBox_cutright",
				"TextArea_angleleft",
				"TextArea_angleright",
				"TextArea_lengthleft",
				"TextArea_lengthright",
				"TextArea_activematerial",
				"TextArea_activesection"};

	components["results"] := {"f_h0k", "f_hk", "t", "t_eff", "h_min", "l_min", "k_rho", "R_axk", "R_headk", "eta814", "F_vEd", "F_90Rd", "h_e", "h_e_side", "w", "eta814_NA_DE", "k_r", "a_r", "k_s", 
					"t_ef_814_NA_DE", "F_90Rd_NA_DE", "k_ef", "n_ef0", "k_n_ef0", "k_n_efa", "eta62net", "F_xEd", "Anet_gross", "Inet_gross"};

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
		
	# Connection type
	# steel on the outside (both sides)
	if structure["connection"]["connection1"] = "Steel" then
		for i in components["timber"] do
			SetProperty(cat(i, "1"), 'enabled', "false");
		end do;
		SetProperty("TextArea_section_bout1", 'enabled', "false");
		
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

		if structure["connection"]["connectionInsideLayers"] > 1 then
			SetProperty("TextArea_section_bout1", 'enabled', "true");
		else
			SetProperty("TextArea_section_bout1", 'enabled', "false");
		end if;

		HighlightResults(cat~(components["results"], "1"), "activate");	
		
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


SetVisibilityShearConnector := proc(WhateverYouNeed::table)
	description "Set visibility of Shear Connectors";
	local fastener, ShearConnector, ShearComponents, i, j, activate;

	fastener := WhateverYouNeed["calculations"]["structure"]["fastener"];
	ShearConnector := GetProperty("ComboBox_ShearConnector", 'value');

	if fastener["ShearConnector"] = ShearConnector then
		return		# no change, nothing to do here
	end if;

	ShearComponents := table();
	ShearComponents["-"] := {};
	ShearComponents["Sharp Metal"] := {"ComboBox_SharpMetalProducer", "ComboBox_SharpMetalProduct", 
								"TextArea_SharpMetalInfo", "ComboBox_SharpMetalStripes", "TextArea_SharpMetalLength"};
	ShearComponents["Split ring"] := {"ComboBox_SplitRingtype", "ComboBox_SplitRingdc", "TextArea_SplitRingt", "TextArea_SplitRinghc"};
	ShearComponents["Toothed-plate"] := {"ComboBox_ToothedPlatesides", "ComboBox_ToothedPlatetype", "ComboBox_ToothedPlatedc", 
								"TextArea_ToothedPlatek1", "TextArea_ToothedPlatek2", "TextArea_ToothedPlatek3",
								"MathContainer_F_vRk_89_810", "MathContainer_F_vRd_89_810", "MathContainer_ToothedPlatea3t"};

	# deactivate everything first
	for i in {"Sharp Metal", "Split ring", "Toothed-plate"} do
		
		if i = ShearConnector then
			activate := "true"
		else
			activate := "false"
		end if;
		
		for j in ShearComponents[i] do
			if searchtext("MathContainer", j) = 0 then
				SetProperty(j, 'enabled', activate)
			elif activate = "false" then
				SetProperty(j, 'value', 0)
			end if
		end do;
		
	end do;

	if ShearConnector = "Sharp metal" then
		SetComboBoxSharpMetal(1, WhateverYouNeed)
	elif ShearConnector = "Split ring" then
		SetComboBoxSplitRing(0, WhateverYouNeed)
	elif ShearConnector = "Toothed-plate" then
		SetComboBoxToothedPlateConnectors(1, WhateverYouNeed)
	end if;
end proc:


SetVisibilityTimberCut := proc()
	description "Set visibility of lengthleft TextArea";
	local minimumangle, i, j, a; 		# dummy1, dummy2

	minimumangle := 15 ; 	#degree, https://www.dlubal.com/en/support-and-learning/support/faq/004645	
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
	# CheckBox for cuts has been replaced by ComboBox with choice for either angle or cut to profile	
#	if abs(parse(GetProperty(cat("TextArea_graindirection", a[1]), 'value')) - parse(GetProperty(cat("TextArea_graindirection", a[2]), 'value'))) < minimumangle then
#		SetProperty(cat("CheckBox_cutleft", a[1]), 'enabled', "false");
#		SetProperty(cat("CheckBox_cutright", a[1]), 'enabled', "false");
#		SetProperty(cat("CheckBox_cutleft", a[2]), 'enabled', "false");
#		SetProperty(cat("CheckBox_cutright", a[2]), 'enabled', "false");
#	else
#		SetProperty(cat("CheckBox_cutleft", a[1]), 'enabled', "true");
#		SetProperty(cat("CheckBox_cutright", a[1]), 'enabled', "true");
#		SetProperty(cat("CheckBox_cutleft", a[2]), 'enabled', "true");
#		SetProperty(cat("CheckBox_cutright", a[2]), 'enabled', "true");
#	end if;
		
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
	local SharpMetalWithScrew, SharpMetalProducer, SharpMetalProduct, SharpMetalWidth;
	local fastener, dummy, dummy1, maxNumberOfStripes, i, NumberOfStripes, width, structure, sectiondataAll, warnings;

	# local variables
	structure := WhateverYouNeed["calculations"]["structure"];
	warnings := WhateverYouNeed["warnings"];
	sectiondataAll := WhateverYouNeed["sectiondataAll"];
	fastener := WhateverYouNeed["calculations"]["structure"]["fastener"];
	
	# n
	# 1...producer
	# 2...product
	# 3...new calculation of number of stripes, get materialdata, e.g. due to changed timber section
	# 4...number of stripes changed

	dummy := n;
	SharpMetalWithScrew := "true";

	# check if usable
	if fastener["ShearConnector"] = "Sharp Metal" and (structure["connection"]["connection1"] <> "Timber" or structure["connection"]["connection2"] <> "Timber") then
		Alert("SharpMetal can only be used in timber - timber connections", warnings, 3);
		return
	end if;

	# at the moment no need to redefine list of producers, just ROTHOBLAAS available

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


SetComboBoxSplitRing := proc(n::integer, WhateverYouNeed::table)
	description "Split ring connectors";
	local structure, fastener, warnings, dummy, d, t, items, dc;

	# local variables
	structure := WhateverYouNeed["calculations"]["structure"];
	warnings := WhateverYouNeed["warnings"];
	fastener := structure["fastener"];
	d := structure["fastener"]["fastener_d"];						# bolt diameter

	# n
	# 0...activated
	# 1...platetype

	dummy := n;	

	if dummy = 0 then
		items := sort(NODETimberSplitRing:-type);
		SetProperty("ComboBox_SplitRingtype", 'itemList', items);
		if numelems(items) <> 0 then
			SetProperty("ComboBox_SplitRingtype", 'selectedindex', 0);
		end if;
		dummy := 1
	end if;

	# Platetype changed
	# get list of inner diameters  for connection
	if dummy = 1 then
		fastener["SplitRingtype"] := GetProperty("ComboBox_SplitRingtype", value);
		items := sort(NODETimberSplitRing:-dc[fastener["SplitRingtype"]]);		# sorted list of external diameter
				
		for dc in items do
			t := NODETimberSplitRing:-t[fastener["SplitRingtype"], round(convert(dc, 'unit_free'))][1];		# thickness
			if dc - 2 * t <= d then				
				items := items minus {dc}		# center hole diameter too small, remove item from list
			end if;			
		end do;
		
		if numelems(items) = 0 then
			Alert("No valid Split ring connector found: dc too small for bolt diameter", warnings, 3);
			return
		end if;
		
		SetProperty("ComboBox_SplitRingdc", 'itemList', round~(convert~(items, 'unit_free')));
		if numelems(items) <> 0 then
			SetProperty("ComboBox_SplitRingdc", 'selectedindex', 0);
		end if;
		
	end if;

end proc:


SetComboBoxToothedPlateConnectors := proc(n::integer, WhateverYouNeed::table)
	description "Toothed Plate Connectores (Bulldogs)";
	local structure, fastener, warnings, dummy, d, d1, items, i;

	# local variables
	structure := WhateverYouNeed["calculations"]["structure"];
	warnings := WhateverYouNeed["warnings"];
	fastener := structure["fastener"];
	d := structure["fastener"]["fastener_d"];						# bolt diameter

	# n
	# 1...platesides
	# 2...platetype

	dummy := n;
	# no need to redefine number of possible sides (1, 2)

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
	if dummy = 2 then
		fastener["ToothedPlatetype"] := GetProperty("ComboBox_ToothedPlatetype", value);		
		items := sort(NODETimberToothedPlateConnectors:-dc[fastener["ToothedPlatesides"], fastener["ToothedPlatetype"]]);		# sorted list of external diameter
				
		for i in items do
			d1 := NODETimberToothedPlateConnectors:-d1[fastener["ToothedPlatesides"], fastener["ToothedPlatetype"], round(convert(i, 'unit_free'))][1];		# get center hole diameter
			if d1 <= d then				
				items := items minus {i}		# center hole diameter too small, remove item from list
			end if;			
		end do;
		
		if numelems(items) = 0 then
			Alert("No valid Toothed Plate Connector found: d1 too small for bolt diameter", warnings, 3);
			return
		end if;
		
		SetProperty("ComboBox_ToothedPlatedc", 'itemList', convert~(items, 'unit_free'));
		if numelems(items) <> 0 then
			SetProperty("ComboBox_ToothedPlatedc", 'selectedindex', 0);			
		end if;
		
		dummy := 3;	
	end if;

end proc:


SetVisibilityCutProfile := proc(part::string, side::string, action::string)::boolean;
	
	description "Sets angle value for parts";
	local dummy1, dummy2, value;
	
	dummy1 := cat("ComboBox_cut", side, part);
	dummy2 := cat("TextArea_angle", side, part);

	if action = "cut" then		# ComboBox cut type changed
		value := GetProperty(dummy1, 'value');

		if value = "cut angle" then
			SetProperty(dummy2, 'enabled', "true");	
		
		elif value = "cut rect." then
			SetProperty(dummy2, 'enabled', "true");
			SetProperty(dummy2, 'value', "90");		

		elif value = "cut profile" then
			SetProperty(dummy2, 'enabled', "false");			
		end if;
		
	elif action = "angle" then
		value := GetProperty(dummy2, 'value');

		if type(parse(value), numeric) = false then
	
			Alert(cat("Angle definition part ",part, " side ", side, " not numeric"), table(), 3);
			SetProperty(dummy1, 'selectedindex', 1);	# should be cut rect.
			SetProperty(dummy2, 'enabled', "true");
			SetProperty(dummy2, 'value', "90");		
			return false
			
		else

			if value = "90" then
				SetProperty(dummy1, 'selectedindex', 1)	# should be cut rect.
			else
				SetProperty(dummy1, 'selectedindex', 0)	# should be cut angle
			end if;
		end if;
		
	end if;

	return true
end proc:


SetVisibilityOpening := proc(openingtype::string)
	description "Setting visibility dependent on opening type";

	if openingtype = "circular" then
		SetProperty("TextArea_opening_hd", 'value', GetProperty("TextArea_opening_a", 'value'));
		SetProperty("TextArea_opening_hd", 'enabled', "false");
		SetProperty("TextArea_opening_r", 'enabled', "false")
		
	elif openingtype = "rectangular" then
		SetProperty("TextArea_opening_hd", 'enabled', "true");
		SetProperty("TextArea_opening_r", 'enabled', "true")
		
	end if;

	SetLoadExcentricity(WhateverYouNeed, false)		# will just fix current load case, not other existing load cases
	
end proc:


SetLoadExcentricity := proc(WhateverYouNeed::table, createnewloadcase::boolean)
	description "Setting load excentricity based on load position, called when generating new load case or when CheckLoadExcentricity triggers error";
	local side, dummy, warnings, activeloadcase;

	dummy := evalf(WhateverYouNeed["calculations"]["structure"]["opening"]["opening_a"] / 2);
	warnings := WhateverYouNeed["warnings"];
	activeloadcase := WhateverYouNeed["calculations"]["activesettings"]["activeloadcase"];

	if createnewloadcase then
		if searchtext("left", GetProperty("TextArea_activeloadcase", 'value')) > 0 then
			side := "left";
			dummy := -dummy
		elif searchtext("right", GetProperty("TextArea_activeloadcase", 'value')) > 0  then
			side := "right"
		else
			side := "";
			Alert("Error: loadcase name must include side \"left\" or \"right\" for calculation of excentricity", warnings, 4);
			return;
		end if;
	else
		if searchtext("left", activeloadcase) > 0 then
			side := "left";
			dummy := -dummy
		elif searchtext("right", activeloadcase) > 0  then
			side := "right"
		else
			side := "";
			Alert("Error: loadcase name must include side \"left\" or \"right\" for calculation of excentricity", warnings, 4);
			return;
		end if;
	end if;

	WriteValueToComponent("loadcenter_x", round(dummy), {"nocheck"});
	if createnewloadcase then		
		MainCommon("NewLoadcase");
	else
		WhateverYouNeed["calculations"]["loadcases"][activeloadcase]["loadcenter_x"] := dummy
	end if;
	
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

#	if not(structure["connection"]["connection1"] = "Timber" and structure["connection"]["connection2"] = "Steel") then
#		if WhateverYouNeed["calculations"]["structure"]["connection"]["bout1"] <> "false" then
#			Alert("Different outer layer only allowed in timber / steel connections", warnings, 5);
#		end if;
#	end if;
end proc: