# NODEFunctions.mm : general functions or extensions of existing Maple functions
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

#============================================================
# Maple mangler forel�pig funksjoner for runding
# https://www.mapleprimes.com/questions/229309-Round-Function

# rnd2 := proc(x::realcons,n::integer)
rnd2 := proc(x, n::integer)
	if type(x, realcons) then
		return evalf[length(trunc(x))+n](round(x*10^n)/10^n);
	else
		Alert(cat("rnd2: type x not realcons: ", x), table(), 1)
	end if;
end proc;

# alternativ:
# https://www.mapleprimes.com/questions/234862-Rounding-Values-With-Units?sq=234862
# Fmt := (fmt,ee) -> subsindets(ee,`&*`(float,specfunc(Units:-Unit)),
	#        v->parse(MapleTA:-Builtin:-numfmt(fmt,op(1,v)))*op(2,v)):


round2 := proc(super, n::integer)
	description "rounds numbers to n digits";
	# local dummy;
	
	# rnd2
	return evalindets(super, float, x->rnd2(x,n));

	# Fmt
	# dummy := "#.";
	# from 1 to n do
	#	dummy := cat(dummy, "0")
	# end do;
	# return Fmt(dummy, super);
end proc;


# https://www.mapleprimes.com/questions/231694-Check-If-Component-Exists
ComponentExists := proc(EC::{name,string})
	description "Check if Maple component exists";
	try
		# DocumentTools:-GetProperty(EC, ':-visible');
		GetProperty(EC, ':-visible');
		true;
	catch "Attempted to retrieve property of unknown component":
		false;
	end try;
end proc:


# warnings and error messages 	
Alert := proc(msg::string, warnings::table, level::integer)
	description "Error and alert message handling";
	uses Maplets[Examples];
	local opts, dummy, j, warnings_;
	
	# alert level		
	# 0...print TextArea component
	# 1...INFORMATION: minor issue, display popup
	# 2...WARNING: display popup warning, write to textarea
	# 3...WARNING: calculation issue (eta > 1), write to textarea
	# 4...ERROR: error message, write to textarea, 
	# 5...CRITICAL ERROR:, write warning to text
	#-2...WARNING: no display popup

	if level = 1 then
		opts := "Information"
	elif abs(level) = 2 then
		opts := "Warning"
	elif abs(level) = 3 then
		opts := "WARNING"
	elif level = 4 then
		opts := "ERROR"
	elif level = 5 then
		opts := "CRITICAL ERROR"
	end if;

	warnings_ := convert(WhateverYouNeed["warnings"], set);

	if level > 0 and member(cat(opts,": ", msg), warnings_) = false then
		Maplets[Examples]:-Alert(msg, 'title'=opts);		# Alert pop up
	end if;

	if level > 1 or level < 0 then
		# only if warning is new, take it into account		
		if member(cat(opts,": ", msg), warnings_) = false then
			warnings[numelems(warnings) + 1] := cat(opts,": ", msg);
		end if;
	end if;

	if level <> 1 and ComponentExists("TextArea_warnings") then
		# print to Textarea component
		dummy := "";
		for j in indices(warnings, 'nolist') do
			if dummy = "" then
				dummy := warnings[j]
			else
				dummy := cat(dummy, ", ", warnings[j])
			end if;
		end do;

		if SearchText("CRITICAL ERROR", dummy) > 0 then
			SetProperty("TextArea_warnings", 'fontcolor', "Red");
		elif SearchText("ERROR", dummy) > 0 then
			SetProperty("TextArea_warnings", 'fontcolor', "OrangeRed");
		elif SearchText("WARNING", dummy) > 0 then
			SetProperty("TextArea_warnings", 'fontcolor', "Purple");
		elif SearchText("Warning", dummy) > 0 then
			SetProperty("TextArea_warnings", 'fontcolor', "Violet");
		else
			SetProperty("TextArea_warnings", 'fontcolor', "Black");
		end if;

		SetProperty("TextArea_warnings", 'value', dummy);
	end if;
end proc:


PrintAlert := proc(warnings::table)	
	local dummy, j;

	dummy := "";

	if ComponentExists("TextArea_warnings") then
		for j in indices(warnings, 'nolist') do
			if dummy = "" then
				dummy := warnings[j]
			else
				dummy := cat(dummy, ", ", warnings[j])
			end if;
		end do;
	
		SetProperty("TextArea_warnings", 'value', dummy);		
	end if;
end proc:


MASTERALARM := proc(warnings::table)::boolean;
	description "Check if level 5 alarm is triggered in warnings table";
	local i, MASTERALARM;

	MASTERALARM := false;
	for i in entries(warnings, 'nolist') do
		if SearchText("CRITICAL ERROR", i) > 0 then
			MASTERALARM := true
		end if;
	end do;
	return MASTERALARM
end proc:


ResetWarnings := proc(WhateverYouNeed::table)
	description "reset warnings and errors";
	local warnings;

	# https://www.mapleprimes.com/questions/235110-Table-And-Indexed?sq=235110
	warnings := table();
	WhateverYouNeed["warnings"] := warnings;
	Alert("", WhateverYouNeed["warnings"], 0);
end proc:


ResetComponent := proc(var::set)
	description "Delete results in combobox";
	local i;

	for i in var do
	
		if ComponentExists(cat("TextArea_", i)) then
			SetProperty(cat("TextArea_", i), 'value', 0);
		elif ComponentExists(cat("ComboBox_", i)) then
			SetProperty(cat("ComboBox_", i), 'itemlist', [""]);
		elif ComponentExists(cat("CheckBox_", i)) then
			# no action
		else
			Alert(cat("Component not found for ", i), table(), 1)
		end if;
	end do;
end proc:


WriteValueToComponent := proc(compvariable::string, b, check_calculations::set)
	description "Find component we could write our value to";
	uses ListTools;
	local foundvalue, upd_check_calculations, componentvalue, checkvar;

	if member("nocheck", check_calculations) then
		checkvar := false
	else
		checkvar := true
	end if;

	if checkvar and evalb(compvariable in check_calculations) = false then		# variable is not in list of predefined, needed variables for calculation, etc.
		return check_calculations
	end if;

	upd_check_calculations := check_calculations;

	componentvalue := b;		# need to copy that to a local variable, as we need to strip value of units

	if type(componentvalue, 'with_unit') then
		componentvalue := convert(componentvalue, 'unit_free')
	end if;

	if ComponentExists(cat("TextArea_", compvariable)) then
		if componentvalue = "false" or componentvalue = false then
			SetProperty(cat("TextArea_", compvariable), 'enabled', "false");
		else
			SetProperty(cat("TextArea_", compvariable), 'value', componentvalue);
			SyncSliderWithTextArea(compvariable)		# there could be a slider to be adjusted as well
		end if;
		if checkvar then
			upd_check_calculations := upd_check_calculations minus {compvariable};
		end if;

	# ComboBox with predefined values
	elif ComponentExists(cat("ComboBox_", compvariable)) then
		foundvalue := ListTools:-Search(convert(componentvalue, string), DocumentTools:-GetProperty(cat("ComboBox_", compvariable), 'itemList'));		# need to convert to string
		if foundvalue > 0 then
			SetProperty(cat("ComboBox_", compvariable), 'enabled', "true");
			SetProperty(cat("ComboBox_", compvariable), 'selectedindex', foundvalue - 1);
			if checkvar then
				upd_check_calculations := upd_check_calculations minus {compvariable};
			end if;
		else
			if componentvalue = "false" or componentvalue = false then
				SetProperty(cat("ComboBox_", compvariable), 'enabled', "false");
				if checkvar then
					upd_check_calculations := upd_check_calculations minus {compvariable};
				end if;
			else
				Alert(cat("ComboBox_", compvariable, ": no value found ", componentvalue), table(), 1)
			end if;
		end if;

	elif ComponentExists(cat("CheckBox_", compvariable)) then
		SetProperty(cat("CheckBox_", compvariable), 'value', componentvalue);
		if checkvar then
			upd_check_calculations := upd_check_calculations minus {compvariable};
		end if;

	# contrary to other fields, slider values must be numeric, not string!
	elif ComponentExists(cat("Slider_", compvariable)) then
		if type(componentvalue, string) then
			SetProperty(cat("Slider_", compvariable), 'value', parse(componentvalue))
		elif type(componentvalue, numeric) then
			SetProperty(cat("Slider_", compvariable), 'value', componentvalue)
		elif type(componentvalue, with_unit) then
			SetProperty(cat("Slider_", compvariable), 'value', convert(componentvalue, 'unit_free'))
		else
			Alert("Can't set value to slider component", table(), 1)
		end if;
		if checkvar then
			upd_check_calculations := upd_check_calculations minus {compvariable};
		end if;

	elif ComponentExists(compvariable) then			# some variables are defined with componentsettings
		if searchtext("ComboBox", compvariable) = 1 then
			foundvalue := ListTools:-Search(componentvalue, DocumentTools:-GetProperty(compvariable, 'itemList'));
			if foundvalue > 0 then
				SetProperty(compvariable, 'enabled', "true");
				SetProperty(compvariable, 'selectedindex', foundvalue - 1);
				if checkvar then
					upd_check_calculations := upd_check_calculations minus {compvariable};
				end if;
			else
				if componentvalue = "false" or componentvalue = false then
					DocumentTools:-SetProperty(compvariable, 'enabled', "false");
					if checkvar then
						upd_check_calculations := upd_check_calculations minus {compvariable};
					end if;
				else
					Alert(cat(compvariable, ": value not found ", componentvalue), table(), 1)
				end if;
			end if;
		elif searchtext("CheckBox", compvariable) = 1 then
			DocumentTools:-SetProperty(compvariable, 'value', componentvalue);
			if checkvar then
				upd_check_calculations := upd_check_calculations minus {compvariable};
			end if;
		else
			Alert(cat("No component found for ", compvariable), table(), 1)
		end if
	
	else
		if componentvalue <> "" then
			Alert(cat("No component found for ", compvariable), table(), 1)
		end if;
	end if;

	return upd_check_calculations
end proc:


updateResults := proc(data::table)
	description "Update values in MathContainer or TextArea components";
	local i;

	for i in indices(data, 'nolist') do
		
		if ComponentExists(cat("MathContainer_", i)) then
			SetProperty(cat("MathContainer_", i), 'value', round2(data[i], 1))
			
		elif ComponentExists(cat("TextArea_", i)) then
			if type(data[i], float) then	# concrete, epsilon etc.
				SetProperty(cat("TextArea_", i), 'value', MapleTA:-Builtin:-numfmt("0.0000", data[i]))
				
			elif type(data[i], string) then
				SetProperty(cat("TextArea_", i), 'value', data[i])
				
			elif SearchText("*Units:-Unit", convert(data[i], string)) > 0 then		# check if data has units, then remove unit from value
				SetProperty(cat("TextArea_", i), 'value', convert(data[i], 'unit_free'))

			else
				#
				
			end if;
		end if
	end do;
end proc:


ReadComponentsCommon := proc(action::string, WhateverYouNeed::table)
	description "Read values from common components in worksheet";

	local activeloadcase, loadcases, loadvariables, autoloadsave, autocalc, componentvariables, activesettings;
	local material, materials, materialdata, materialdataAll, projectdata, calculations;
	local sections, sectiondataAll;
	local strengthclass, serviceclass, loaddurationclass, calculationtype, exposureclass, durabilityclass;
	local activematerial, activesection, sectionchanged, val, forceSectionUpdate, i, dummy, warnings;
	local steelcode, steelgrade, thicknessclass;

	# define local variables
	calculations := WhateverYouNeed["calculations"];	
	componentvariables := WhateverYouNeed["componentvariables"];
	loadcases := calculations["loadcases"];
	projectdata := WhateverYouNeed["projectdata"];
	material := WhateverYouNeed["material"];
	materialdataAll := WhateverYouNeed["materialdataAll"];
	materials := WhateverYouNeed["materials"];
	# sectiondata := WhateverYouNeed["sectiondata"];
	sections := WhateverYouNeed["sections"];
	sectiondataAll := WhateverYouNeed["sectiondataAll"];

	loadvariables := calculations["loadvariables"];
	activesettings := calculations["activesettings"];	
	autoloadsave := calculations["autoloadsave"];
	autocalc := calculations["autocalc"];
	# structure := WhateverYouNeed["calculations"]["structure"];
	warnings := WhateverYouNeed["warnings"];

	# active***
	if assigned(activesettings["activeloadcase"]) then
		activeloadcase := activesettings["activeloadcase"];
	else
		activeloadcase := ""
	end if;

	if assigned(activesettings["activematerial"]) then
		activematerial := activesettings["activematerial"];
	else
		activematerial := ""
	end if;

	if assigned(activesettings["activesection"]) then
		activesection := activesettings["activesection"];
	else
		activesection := ""
	end if;

	if assigned(WhateverYouNeed["calculations"]["calculationtype"]) then
		calculationtype := WhateverYouNeed["calculations"]["calculationtype"];
	else
		calculationtype := ""
	end if;

	sectionchanged := false;

	# if searchtext("NS-EN 1995-1-1, Section 6", calculationtype) > 0 then
	#	timbertype := WhateverYouNeed["materialdata"]["timbertype"]
	# elif searchtext("NS-EN 1995-1-1, Section 8", calculationtype) > 0 then
		# materialdataAll[i]["timbertype"]
	# end if;

	# "action" can have these values
	# all
	# projectdata
	# materials
	# sections
	# timbertype
	# material
	# section
	# structure
	# autoloadsave
	# autocalc
	# GetLoadcase
	# CalculateLoads_design
	# CalculateLoads_calculate
	# NewLoadcase
	# StoreLoadcase
	# DeleteLoadcase
	# ResetLoadcase

	# project data
	if action = "all" or action = "projectdata" then
		for i in componentvariables["var_projectdata"] do
			if ComponentExists(cat("TextArea_", i)) then
				projectdata[i] := GetProperty(cat("TextArea_", i), value);
			end if;
		end do;
		
		for i in {"positionnumber", "positiontitle"} do
			if ComponentExists(cat("TextArea_", i)) then
				calculations[i] := GetProperty(cat("TextArea_", i), value);
			end if;
		end do
	end if;


	# Readmaterials
	# this one reads strengthclass, serviceclass and loaddurationclass, but just for section 6 calculations where there is a materials
	# Section 8 does not have materialss
	if action = "all" or action = "materials" then
		
		forceSectionUpdate := false;
		
		if ComponentExists("ComboBox_materials") then

			# Go through list of materials and store all values in materials variable
			for val in GetProperty("ComboBox_materials", 'itemlist') do
				if material = "concrete" then
					NODEConcreteEN1992:-GetMaterialdata(val, WhateverYouNeed)
						
				elif material = "steel" then
					NODESteelEN1993:-GetMaterialdata(val, WhateverYouNeed)
					
				elif material = "timber" then
					NODETimberEN1995:-GetMaterialdata(val, WhateverYouNeed)
					
				end if;
				
				if assigned(WhateverYouNeed["materialdata"]["name"]) then
					materials[WhateverYouNeed["materialdata"]["name"]] := eval(WhateverYouNeed["materialdata"]);
				else
					Alert("materialdata name not assigned", warnings, 1);
				end if;
				
			end do;
			
			activematerial := GetProperty("ComboBox_materials", value);
			sectionchanged := MaterialChanged(material, activematerial, WhateverYouNeed, forceSectionUpdate, "");		# partsnumber "" if there is no other timber part
		
		else
			# ComboBox_materials does not exist, check if we need to read something else (8. Mekaniske forbindelser)
		end if;
	end if;

	# sections
	if action = "all" or action = "sections" then
		
		forceSectionUpdate := false;
		
		if ComponentExists("ComboBox_sections") then
		
			for val in GetProperty("ComboBox_sections", 'itemlist') do
				
				if material = "steel" then
					NODESteelEN1993:-GetSectiondata(val, WhateverYouNeed)

				# no sections for concrete at the moment
				elif material = "concrete" then
					# sectiondata := NODEConcreteEN1992:-GetSectiondata(val, warnings)					
					
				elif material = "timber" then
					NODETimberEN1995:-GetSectiondata(val, WhateverYouNeed)
					
				end if;

				if assigned(WhateverYouNeed["sectiondata"]["name"]) then
					sections[WhateverYouNeed["sectiondata"]["name"]] := eval(WhateverYouNeed["sectiondata"]);
				else
					Alert("sectiondata name not assigned", warnings, 1);
				end if;
				
			end do;

			activesection := GetProperty("ComboBox_sections", value);
			SectionChanged(material, activesection, WhateverYouNeed, "");		# partsnumber			

		else
			# ComboBox_materials does not exist, check if we need to read something else (8. Mekaniske forbindelser)
		end if;
	end if;

	# read direct timber material definitions
	if (action = "all" and searchtext("NS-EN 1995-1-1, Section 8", calculationtype) > 0) or substring(action, 1..10) = "timbertype" then

		forceSectionUpdate := true;
		if action = "timbertype" then				# it is a Section 6 calculation
			dummy := {""};						
		elif action = "all" then					# it is a Section 8 calculation
			dummy := {"1", "2"}
		elif substring(action, 1..10) = "timbertype" then
			dummy := {substring(action, -1..-1)}	# get number timber item
		end if;

		for i in dummy do
			if i = "" then
				materialdata := WhateverYouNeed["materialdata"]
			else
				materialdata := WhateverYouNeed["materialdataAll"][i]
			end if;
			# timbertype := materialdata["timbertype"];
			serviceclass := GetProperty("ComboBox_serviceclass", value);
			loaddurationclass := GetProperty("ComboBox_loaddurationclass", value);

			if ComponentExists(cat("ComboBox_timbertype", i)) then
				if GetProperty(cat("ComboBox_timbertype", i), 'enabled') = "true" then
					if materialdata["timbertype"] <> GetProperty(cat("ComboBox_timbertype", i), value) then					

						# set strengthclass
						if GetProperty(cat("ComboBox_timbertype", i), value) = "Solid timber" then					# set properties for strengthclass
							SetProperty(cat("ComboBox_strengthclass", i), 'itemlist', NODETimberMaterial:-Strengthclasses("Solid timber"));
						
						elif GetProperty(cat("ComboBox_timbertype", i), value) = "Glued laminated timber" then
							SetProperty(cat("ComboBox_strengthclass", i), 'itemlist', NODETimberMaterial:-Strengthclasses("Glued laminated timber"));
						
						elif GetProperty(cat("ComboBox_timbertype", i), value) = "CLT" then
							SetProperty(cat("ComboBox_strengthclass", i), 'itemlist', NODETimberMaterial:-Strengthclasses("CLT"));
						
						else
							SetProperty(cat("ComboBox_strengthclass", i), 'itemlist', NODETimberMaterial:-Strengthclasses("all"));
						
						end if;

						SetProperty(cat("ComboBox_strengthclass", i), 'selectedindex', 0);		# pick first value
						activematerial := cat(GetProperty(cat("ComboBox_strengthclass", i), value)," / Service class ", serviceclass," / ", loaddurationclass);
						sectionchanged := MaterialChanged(material, activematerial, WhateverYouNeed, forceSectionUpdate, i);
						
					end if;
					
				else	
					if assigned(materialdataAll[i]) then
						materialdataAll[i] := evaln(materialdataAll[i]);
						sectiondataAll[i] := evaln(sectiondataAll[i])
					end if;	
				end if;
			end if;
		end do;
	end if;

	# material data from specific definitions
	if (action = "all" and not ComponentExists("ComboBox_materials")) or action = "material" then

		if material = "concrete" then
			if ComponentExists("ComboBox_strengthclass") then
				strengthclass := GetProperty("ComboBox_strengthclass", value);
				if NODEConcreteEN1992:-strengthclassExists(strengthclass) = false then
					Alert("Unknown strengthclass", warnings, 5)
				end if;
			else
				Alert("Strengthclass undefined", warnings, 5)
			end if;

			if ComponentExists("ComboBox_exposureclass") then
				exposureclass := GetProperty("ComboBox_exposureclass", value)
			else
				exposureclass := "-"
			end if;
		
			if ComponentExists("ComboBox_durabilityclass") then
				durabilityclass := GetProperty("ComboBox_durabilityclass", value)
			else
				durabilityclass := "-"
			end if;
		
			activematerial := cat(strengthclass," / ", exposureclass," / ", durabilityclass);
			sectionchanged := MaterialChanged(material, activematerial, WhateverYouNeed, forceSectionUpdate, "");
			
		elif material = "steel" then
			
			if ComponentExists("ComboBox_steelcode") and ComponentExists("ComboBox_steelgrade") and ComponentExists("ComboBox_thicknessclass") then
				steelcode := GetProperty("ComboBox_steelcode", value);
				steelgrade := GetProperty("ComboBox_steelgrade", value);
				thicknessclass := GetProperty("ComboBox_thicknessclass", value);
				
				activematerial := cat(steelcode," / ", steelgrade," / ", thicknessclass);
				sectionchanged := MaterialChanged(material, activematerial, WhateverYouNeed, forceSectionUpdate, "");
			end if;

		elif material = "timber" then
			forceSectionUpdate := false;
			if calculationtype = "NS-EN 1995-1-1, Section 8: Fasteners" then
				dummy := {"1", "2"}
			else	
				dummy := {""}
			end if;

			if ComponentExists("ComboBox_serviceclass") and GetProperty("ComboBox_serviceclass", 'enabled') = "true" then
				serviceclass := GetProperty("ComboBox_serviceclass", value)
			else
				serviceclass := "-"
			end if;
		
			if ComponentExists("ComboBox_loaddurationclass") and GetProperty("ComboBox_loaddurationclass", 'enabled') = "true" then
				loaddurationclass := GetProperty("ComboBox_loaddurationclass", value)
			else
				loaddurationclass := "-"
			end if;

			for i in dummy do
				if ComponentExists(cat("ComboBox_strengthclass", i)) and GetProperty(cat("ComboBox_strengthclass", i), 'enabled') = "true" then
					strengthclass := GetProperty(cat("ComboBox_strengthclass", i), value);
					
					if NODETimberEN1995:-strengthclassExists(strengthclass) = false then
						Alert("Unknown strengthclass", warnings, 5)
					end if;
						
					activematerial := cat(strengthclass," / Service class ", serviceclass," / ", loaddurationclass);
					sectionchanged := MaterialChanged(material, activematerial, WhateverYouNeed, forceSectionUpdate, i);
									
				else
					if i <> "" then
						if assigned(materialdataAll[i]) then
							materialdataAll[i] := evaln(materialdataAll[i]);
							sectiondataAll[i] := evaln(sectiondataAll[i])
						end if;
					end if;
				end if;
			end do;

			# steel in timber connection
			if ComponentExists("ComboBox_steelgrade") and GetProperty("ComboBox_steelgrade", 'enabled') = "true" then

				# steelcode := "NS-EN 10025-2";
				steelcode := GetProperty("ComboBox_steelcode", value);
				steelgrade := GetProperty("ComboBox_steelgrade", value);				
				thicknessclass := GetProperty("ComboBox_thicknessclass", value);
				
				activematerial := cat(steelcode," / ", steelgrade," / ", thicknessclass);
				sectionchanged := MaterialChanged("timber", activematerial, WhateverYouNeed, forceSectionUpdate, "steel");								
				
			else
				if assigned(materialdataAll["steel"]) then
					materialdataAll["steel"] := evaln(materialdataAll["steel"]);
					sectiondataAll["steel"] := evaln(sectiondataAll["steel"])
				end if;
			end if;
			
		end if;

		# what if we have mixed materials?
		# multiple materials ? need to fix that one as well
		# if material <> "steel" and ComponentExists("ComboBox_steelgrade") and GetProperty("ComboBox_steelgrade", 'enabled') = "true" then
			
		#	assign('steelgrade', GetProperty("ComboBox_steelgrade", value));
		#	NODESteelEN1993:-GetMaterialdata(cat("NS-EN 10025-2", 40 * Unit('mm'), steelgrade), WhateverYouNeed);
		#	materialdataAll["steel"] := eval(WhateverYouNeed["materialdata"])
		# else 
		#	materialdataAll["steel"] := evaln(materialdataAll["steel"])
		# end if
		
	end if;

	# ReadSystemSection
	# section data
	if (action = "all" and not ComponentExists("ComboBox_sections")) or action = "section" or sectionchanged then
		local sectiontype, section;

		if material = "steel" then
			
			if ComponentExists("ComboBox_sectiontype") and ComponentExists("ComboBox_section") then
				sectiontype := GetProperty("ComboBox_sectiontype", value);
				section := GetProperty("ComboBox_section", value);
				activesection := cat(sectiontype," / ", section);
				SectionChanged(material, activesection, WhateverYouNeed, ""); 	# partsnumber
			end if;		
			
		elif material = "timber" then
		
			if searchtext("NS-EN 1995-1-1, Section 8", calculationtype) > 0 then
				dummy := {"1", "2", "steel"}
			else
				dummy := {""}
			end if;

			for i in dummy do
				if i = "" or assigned(materialdataAll[i]) then			
					activesection := NODETimberEN1995:-GetActiveSectionName(WhateverYouNeed, i);
					SectionChanged(material, activesection, WhateverYouNeed, i);

				else	# remove inactive section data
					
					if assigned(sectiondataAll[i]) then
						sectiondataAll[i] := evaln(sectiondataAll[i])
					end if;
					
				end if;
			end do;
		end if;			
	end if;

	# autosave settings
	if action = "all" or action = "autoloadsave" then
		if ComponentExists("CheckBox_autoloadsave") then
			if GetProperty("CheckBox_autoloadsave",value) = "true" then
				autoloadsave := true;
				if ComponentExists("Button_AddLoad") then
					SetProperty("Button_AddLoad", 'enabled', "false")
				end if;
			else 
				autoloadsave := false;
				if ComponentExists("Button_AddLoad") then
					SetProperty("Button_AddLoad", 'enabled', "true")
				end if;
			end if;
			WhateverYouNeed["calculations"]["autoloadsave"] := autoloadsave;
		end if;
	end if;

	# autocalc settings
	if action = "all" or action = "autocalc" then
		if ComponentExists("CheckBox_autocalc") then
			if GetProperty("CheckBox_autocalc",value) = "true" then
				autocalc := true;
				if ComponentExists("Button_calculate") then
					SetProperty("Button_calculate", 'enabled', "false")
				end if;
			else 
				autocalc := false;
				if ComponentExists("Button_calculate") then
					SetProperty("Button_calculate", 'enabled', "true")
				end if;
			end if;
			WhateverYouNeed["calculations"]["autocalc"] := autocalc;
		else	# sheets that don't have a checkbox implemented should always be calculated automatically
			WhateverYouNeed["calculations"]["autocalc"] := true;
		end if;
	end if;

	if action = "calculateAllLoadcases" or ComponentExists("Button_calculateAllLoadcases") = false then
		WhateverYouNeed["calculateAllLoadcases"] := true
	else
		WhateverYouNeed["calculateAllLoadcases"] := false
	end if;

	if action = "all" or action = "GetLoadcase" or action = "calculateAllLoadcasesCleanup" then
		if ComponentExists("ComboBox_loadcases") and ComponentExists("TextArea_activeloadcase") then
			SetProperty("TextArea_activeloadcase", 'value', GetProperty("ComboBox_loadcases", value));
		end if;
		if ComponentExists("TextArea_activeloadcase") then
			activeloadcase := GetProperty("TextArea_activeloadcase", value);
			WriteLoadsToDocument(activeloadcase, WhateverYouNeed);		# get stored load values and write values to document
		end if;

	elif action = "CalculateLoads" then
		CalculateLoads(activeloadcase, autoloadsave, "", WhateverYouNeed);

	elif action = "CalculateLoads_design" then		# read loads from textareas, and update activeloadcase variable with new value
		CalculateLoads(activeloadcase, autoloadsave, "design", WhateverYouNeed);

	elif action = "CalculateLoads_calculate" then	# read loads from textareas, and update activeloadcase variable with new value
		CalculateLoads(activeloadcase, autoloadsave, "calculate", WhateverYouNeed);
			
	elif action = "NewLoadcase" then
		if GetProperty("TextArea_activeloadcase", value) <> "activeloadcase" then
			activeloadcase := GetProperty("TextArea_activeloadcase", value);
			CalculateLoads(activeloadcase, autoloadsave, "verify", WhateverYouNeed);
		else
			Alert("Reserved: choose different name", warnings, 4)
		end if;
		
	elif action = "StoreLoadcase" then
		CalculateLoads(activeloadcase, true, "verify", WhateverYouNeed);	# leser laster, og skriver verdier til activeloadcases
		
	elif action = "DeleteLoadcase" then
		NODEFunctions:-ModifyLoadcases("ComboBox_loadcases", "Delete", loadvariables, loadcases, activeloadcase);
		SetProperty("ComboBox_loadcases", 'selectedindex', 0);
		SetProperty("TextArea_activeloadcase", 'value', GetProperty("ComboBox_loadcases", value));
		activeloadcase := GetProperty("TextArea_activeloadcase", value);
		WriteLoadsToDocument(activeloadcase, WhateverYouNeed);		# get stored load values and write values to document
		
	elif action = "ResetLoadcase" then
		loadcases := table();
		WhateverYouNeed["calculations"]["loadcases"] := eval(loadcases);	# https://www.mapleprimes.com/questions/235292-Store-Values-Between-Sessions-Including
		activeloadcase := "1";
		if ComponentExists("ComboBox_loadcases") then
			SetProperty("ComboBox_loadcases", 'itemList', [activeloadcase]);
			SetProperty("ComboBox_loadcases", 'selectedindex', 0)
		end if;
		if ComponentExists("TextArea_activeloadcase") then
			SetProperty("TextArea_activeloadcase", 'value', activeloadcase)
		end if;
		for i in loadvariables do
			dummy := cat("TextArea_", i);
			if ComponentExists(dummy) then
				SetProperty(dummy, 'enabled', true);
				SetProperty(dummy, 'value', 0);
			elif ComponentExists(cat("Slider_", i)) then
				dummy := cat("Slider_", i);
				SetProperty(dummy, 'enabled', true);
				SetProperty(dummy, 'value', 0);
			end if;
		end do;
		CalculateLoads(activeloadcase, true, "verify", WhateverYouNeed);
	end if;

	#if calculationtype <> "NS-EN 1995, part 1-1, Section 8: Fasteners" then
	# 	assignVariables(strengthclass);			# assignVariables blir kj�rt uansett senere i prosessen
	#end if;

	# store values back to global variable
	# don't store values in activesettings that should not be saved across sessions
	# NOTE TO SELF: don't ever not make circular references	
	if member("activeloadcase", WhateverYouNeed["componentvariables"]["var_calculations"]) then
		activesettings["activeloadcase"] := activeloadcase
	else
		activesettings["activeloadcase"] := evaln(activesettings["activeloadcase"])
	end if;

	if member("activematerial", WhateverYouNeed["componentvariables"]["var_calculations"]) then
		activesettings["activematerial"] := activematerial
	else
		activesettings["activematerial"] := evaln(activesettings["activematerial"])
	end if;

	if member("activesection", WhateverYouNeed["componentvariables"]["var_calculations"]) then
		activesettings["activesection"] := activesection
	else
		activesettings["activesection"] := evaln(activesettings["activesection"])
	end if;

		
	ReadComponentsSpecific(action, WhateverYouNeed);		# call specific part of ReadSystemSection'

	# check if we need to store settings
	if member(action, {"autocalc", "autoloadsave", "calculateAllLoadcases"}) then
	else		
		Storesettings(WhateverYouNeed);	# write values to storesettings variable
	end if;
end proc:


ModifyComboVariables := proc(combobox::string, action::string, atable::table, newitem::table)
	description "Add, modify, erase item in Combobox and their connected variables and update the table where values are stored";
	local combolist, i;

	if action = "Add" or action = "Modify" then
		if assigned(newitem["name"]) then
			atable[newitem["name"]] := eval(newitem);
		else
			Alert("No tag >name< defined in table", table(), 1)
		end if;
		
	elif action = "Erase" then
		if numelems(atable) > 1 then
			if assigned(atable[newitem["name"]]) then
				atable[newitem["name"]] := evaln(atable[newitem["name"]]);
			end if;
		else
			Alert("Last element can't be deleted", table(), 1);
		end if;

	elif action = "Write" then
		#
		
	end if;

	# create list for combobox
	combolist := [];
	for i from 1 to numelems(atable) do
		combolist := [op(combolist), indices(atable, 'nolist')[i]]
	end do;
	combolist := sort(combolist);
	
	if ComponentExists(combobox) then
		SetProperty(combobox, 'itemList', combolist);

		# set changed value as active
		if action = "Add" or action = "Modify" then
			member(newitem["name"], combolist, 'p');		# find position of new item in combolist
			SetProperty(combobox, 'selectedindex', p-1)		# indexposition starts with 0
		end if;
	end if;
	
end proc:


ModifyLoadcases := proc(combobox::string, action::string, variables::set, loadcases::table, activeloadcase::string)
	description "Add, delete or modify loadcase";
	local i, loadcase, dummy;

	if action = "Add" then
		# saving loads is a bit complicated, as values can be entered either by using characteristik OR dimensioning values
		# this is defined by the active status of the TextArea box
		if activeloadcase <> "" then
			loadcase := table();				
			loadcase["name"] := activeloadcase;
			
			for i in variables do
				if ComponentExists(cat("TextArea_", i)) then
					dummy := cat("TextArea_", i);
					if GetProperty(dummy, 'enabled') = "true" then
						
						# force center coordinates
						if searchtext("loadcenter", i) > 0 then
							if ComponentExists("ComboBox_FastenerPatternUnits") then
								if GetProperty("ComboBox_FastenerPatternUnits", value) = "m" then
									loadcase[i] := parse(GetProperty(dummy, value)) * Unit('m')
								elif GetProperty("ComboBox_FastenerPatternUnits", value) = "cm" then
									loadcase[i] := parse(GetProperty(dummy, value)) * Unit('cm')
								elif GetProperty("ComboBox_FastenerPatternUnits", value) = "mm" then
									loadcase[i] := parse(GetProperty(dummy, value)) * Unit('mm')
								else
									loadcase[i] := parse(GetProperty(dummy, value))
								end if
							else
								loadcase[i] := parse(GetProperty(dummy, value))
							end if;

						# moments
						elif substring(i, 1..1) = "M" then
							loadcase[i] := parse(GetProperty(dummy, value)) * Unit('kN*m')

						# normal or shear forces
						elif substring(i, 1..1) = "F" or substring(i, 1..1) = "V" then
							loadcase[i] := parse(GetProperty(dummy, value)) * Unit('kN')

						else
							loadcase[i] := parse(GetProperty(dummy, value))
							
						end if;
						
					else
						loadcase[i] := "false";
						
					end if;
					
				elif ComponentExists(cat("Slider_", i)) then
					dummy := cat("Slider_", i);
					loadcase[i] := GetProperty(dummy, value) * Unit('degree');
				end if;
			end do;
			loadcases[activeloadcase] := eval(loadcase);
		else
			Alert(cat("Missing loadname ", activeloadcase), table(), 1);
		end if;
		
	elif action = "Delete" then
		if numelems(GetProperty(combobox, 'itemList')) > 1 then
			if assigned(loadcases[activeloadcase]) then
				loadcases[activeloadcase] := evaln(loadcases[activeloadcase])			# evaln: delete member in table
			end if;
		else
			Alert("Last element can't be deleted", table(), 1);
		end if;
	end if;

	# write out to Combobox
	SetComboBoxValues(combobox, loadcases, activeloadcase);

end proc:


SetComboBoxValues := proc(combobox::string, atable::table, avalue::string)
	description "Populate combobox with values from table and set to given active value";
	local dummy, i;

	dummy := [];	# sorted list
	for i from 1 to numelems(atable) do
		dummy := [op(dummy), indices(atable, 'nolist')[i]]
	end do;
	dummy := sort(dummy);

	if numelems(atable) > 0 and ComponentExists(combobox) then
		SetProperty(combobox, 'itemList', dummy);
		for i from 1 to numelems(dummy) do
			if dummy[i] = avalue then
				SetProperty(combobox, 'selectedindex', i-1)
			end if;
		end do;
	end if;
end proc:


# check ?
ProcessLoadcasesFromFile := proc(lctable::table, loadvariables::set)
	description "Get loads from file, returns loadcases (table) and loadname, also writes to Combobox_loadcase / called by NODEXML";
	local loadcases, loadname;
	local i, loadcase_index, loadcase_variable, loadnames, loadcasenames;

	loadcases := table();
	loadnames := table();

	# find loadcase name
	for i in indices(lctable) do		# index consists of 2 parts, so can't use 'nolist' here ["loadcase_1", "F_d"]
		if numelems(i) = 1 then		# shouldn't be possible
			Alert("Just one index for loadcase?", table(), 1);
		elif numelems(i) = 2 then
			loadcase_index := i[1];
			loadcase_variable := i[2];
		end if;
	
		if loadcase_variable = "name" then
			loadnames[loadcase_index] := lctable[loadcase_index, loadcase_variable]
		end if;
	end do;

	# now we can store values
	# need to find loadcase name first
	for i in indices(lctable) do		# index consists of 2 parts, so can't use 'nolist' here ["loadcase_1", "F_d"]
		if numelems(i) = 1 then		# denne burde egentlig ikke finnes
			Alert("Just one index for loadcase?", table(), 1);
		elif numelems(i) = 2 then
			loadcase_index := i[1];
			loadcase_variable := i[2];
		end if;

		if member(loadcase_variable, loadvariables) then
			if lctable[loadcase_index, loadcase_variable] = "false" then
				loadcases[loadnames[loadcase_index]][loadcase_variable] := lctable[loadcase_index, loadcase_variable];
			else
				loadcases[loadnames[loadcase_index]][loadcase_variable] := parse(lctable[loadcase_index, loadcase_variable]);
			end if;
		end if;
	end do;

	# write out to Combobox
	loadcasenames := {};
	for i in indices(loadnames, 'nolist') do
		loadcasenames := loadcasenames union {loadnames[i]}
	end do;

	if numelems(loadcases) > 0 then
		SetProperty("ComboBox_loadcases", 'itemList', loadcasenames);
		SetProperty("ComboBox_loadcases", 'selectedindex', 0);
		loadname := GetProperty("ComboBox_loadcases", value);
	end if;

	return eval(loadcases), loadname;
end proc:


CalculateLoads := proc(loadcase::string, loadsaving::boolean, action::string, WhateverYouNeed::table)
	description "Calculate loads from components";
	local i, val, gamma_G, gamma_Q, loadvariablesShort, load_Gk, load_Qk, load_d, load_d_calculated, loadcase_Gk, loadcase_Qk, loadcase_d, definedCharacteristic, nonloads;
	local loadcases, loadvariables, warnings;

	loadcases := WhateverYouNeed["calculations"]["loadcases"];
	loadvariables := WhateverYouNeed["calculations"]["loadvariables"];
	warnings := WhateverYouNeed["warnings"];

	# NS-EN 1990, tabell NA.A1.2(A)
	gamma_G := 1.35;
	gamma_Q := 1.5;

	if ComponentExists("TextArea_gamma_G") then
		SetProperty("TextArea_gamma_G", 'value', gamma_G)
	end if;
	if ComponentExists("TextArea_gamma_Q") then
		SetProperty("TextArea_gamma_Q", 'value', gamma_Q)
	end if;

	# splitting loads from nonloads, stripping loadnames
	loadvariablesShort := {};	# set
	nonloads := {};
	for val in loadvariables do
		if substring(val, -1..-1) = "k" then
			loadvariablesShort := loadvariablesShort union {substring(val, 1..-3)}
		elif substring(val, -1..-1) = "d" then
			loadvariablesShort := loadvariablesShort union {substring(val, 1..-2)}
		else
			nonloads := nonloads union {val}
		end if
	end do;

	# this one is just for the loads
	for i in loadvariablesShort do

		loadcase_Gk := cat(i, "Gk");
		loadcase_Qk := cat(i, "Qk");
		loadcase_d := cat(i, "d");
	
		if ComponentExists(cat("TextArea_", loadcase_Gk)) and ComponentExists(cat("TextArea_", loadcase_Qk)) and ComponentExists(cat("TextArea_", loadcase_d)) then
		
			if GetProperty(cat("TextArea_", loadcase_Gk), 'enabled') = "true" and GetProperty(cat("TextArea_", loadcase_Qk), 'enabled') = "true" then
				if substring(i, 1..1) = "F" then
					load_Gk := parse(GetProperty(cat("TextArea_", loadcase_Gk), value)) * Unit('kN');
					load_Qk := parse(GetProperty(cat("TextArea_", loadcase_Qk), value)) * Unit('kN');
				elif substring(i, 1..1) = "V" then
					load_Gk := parse(GetProperty(cat("TextArea_", loadcase_Gk), value)) * Unit('kN');
					load_Qk := parse(GetProperty(cat("TextArea_", loadcase_Qk), value)) * Unit('kN');
					if load_Gk < 0 or load_Qk < 0 then
						Alert(cat(loadcase_d, ": value < 0 not allowed"), warnings, 3);
					end if;							
				elif substring(i, 1..1) = "M" then
					load_Gk := parse(GetProperty(cat("TextArea_", loadcase_Gk), value)) * Unit('kN'*'m');
					load_Qk := parse(GetProperty(cat("TextArea_", loadcase_Qk), value)) * Unit('kN'*'m');
				else
					Alert(cat("No definitions found for ", i), warnings, 3);
				end if;
				load_d_calculated := eval(gamma_G * load_Gk + gamma_Q * load_Qk);
				definedCharacteristic := true
			else
				definedCharacteristic := false
			end if;	
		

			# get design values from TextArea
			if substring(i, 1..1) = "F" then
				load_d := parse(GetProperty(cat("TextArea_", loadcase_d), value)) * Unit('kN');
			elif substring(i, 1..1) = "V" then
				load_d := parse(GetProperty(cat("TextArea_", loadcase_d), value)) * Unit('kN');
				if load_d < 0 then
					Alert(cat(loadcase_d, ": value < 0 not allowed"), warnings, 3);
				end if;
			elif substring(i, 1..1) = "M" then
				load_d := parse(GetProperty(cat("TextArea_", loadcase_d), value)) * Unit('kN'*'m');
				if load_d < 0 then
					Alert(cat(loadcase_d, ": value < 0 not allowed"), warnings, 3);
				end if;
			else
				Alert(cat("No definitions found for ", i), warnings, 3);
			end if;
		

			# check consistency between characteristic and dimensioning values
			if definedCharacteristic then
				if load_d_calculated <> load_d then				
					if action = "calculate" then
						SetProperty(cat("TextArea_", loadcase_d), 'value', convert(load_d_calculated, 'unit_free'));
						
					elif action = "verify" then

						# if just load_d has 'value', apparently it comes from Excel file, fix visibility of characteristic TextAreas
						if load_Gk = 0 and load_Qk = 0 and load_d <> 0 then
							SetProperty(cat("TextArea_", loadcase_d), 'value', convert(load_d, 'unit_free'));
							SetProperty(cat("TextArea_", loadcase_Gk), 'enabled', "false");
							SetProperty(cat("TextArea_", loadcase_Qk), 'enabled', "false");

						# if design is 0, and characteristic not, do calculation
						elif (load_Gk <> 0 or load_Qk <> 0) and load_d = 0 then
							SetProperty(cat("TextArea_", loadcase_d), 'value', convert(load_d_calculated, 'unit_free'));
						
						else
							Alert(cat("loadcase: ", loadcase, ", load: ", i, ": gamma_G * ", load_Gk, " + gamma_Q * ", load_Qk, " <> ", load_d), warnings, 3)
						
						end if;
					
					elif action = "design" then					# if design load is defined, and definedCharacteristic is active, this should be checked
						Alert(cat("gamma_G * ", loadcase_Gk, " + gamma_Q * ", loadcase_Qk, " <> ", loadcase_d), warnings, 3);
					end if;
				end if;
			else
				# leave value as it is
			end if;
		
		elif ComponentExists(cat("Slider_", i)) then
			# slider for alpha, etc., ignored
		else
			Alert(cat("TextArea for " , i, " does not exist"), warnings, 3);
		end if;
	
	end do;

	# 6.1.5
	# we cannot switch on and off dialogue boxes dependent on loads anymore, as there are multiple loads with different angles 
	# everything must be active all the time.

	if loadsaving = true and ComponentExists("ComboBox_loadcases") and ComponentExists("Button_AddLoad") then		# save loads to loadcase
		NODEFunctions:-ModifyLoadcases("ComboBox_loadcases", "Add", loadvariables, loadcases, loadcase);
		SetProperty("Button_AddLoad", 'enabled', "false");
		# eta, usedcode, comments := Main(loadcases[loadcase]);		# setter igang beregningen
		# return eta, usedcode, comments
	elif ComponentExists("Button_AddLoad") then	# activate Save button 
		SetProperty("Button_AddLoad", 'enabled', "true");
	end if;
end proc:


CalculateAllLoadcases := proc(WhateverYouNeed::table)
	description "Calculate all loadcases";
	local loadcases, loadcase, j, etamax, loadcaseMax, warningsAll, activeloadcase, warnings;
	local maxFindex, maxF, maxFallLoadcases, maxloadedFastener, loadcaseResults, dummy;

	WhateverYouNeed["calculations"]["calculatingAllLoadcases"]:= true;		# running calculation of all loadcases at the moment
	activeloadcase := WhateverYouNeed["calculations"]["activesettings"]["activeloadcase"];
	loadcases := WhateverYouNeed["calculations"]["loadcases"];
	warnings := WhateverYouNeed["warnings"];

	if numelems(WhateverYouNeed["calculations"]["loadcases"]) < 1 then		# no loads to calculate, might be material or section properties sheet
		return
	end if;

	etamax := table();
	etamax["max"] := 0;
	WhateverYouNeed["results"]["etamax"] := etamax;
	loadcaseMax := indices(loadcases, 'nolist')[1];		# set first index as fallback value

	# for fastener groups;
	maxF := 0;
	maxFindex := 0;
	maxFallLoadcases := 0;
	warningsAll := "";

	maxloadedFastener := table();

	for loadcase in indices(loadcases, 'nolist') do
		
		if loadcase <> "activeloadcase" then
			WriteLoadsToDocument(loadcase, WhateverYouNeed);
			WhateverYouNeed["calculations"]["activesettings"]["activeloadcase"] := loadcase;
		
			# Calling the main calculation routine of the specific program
	#			if WhateverYouNeed["calculations"]["calculationtype"] = "NS-EN 1995-1-1, Section 8: Fasteners" then
	#				NODEFastenerPattern:-CalculateForcesInConnection(WhateverYouNeed)	# just want to calculate forces in the connection, not check the capacity
	#			else
				Main(WhateverYouNeed);
	#			end if;
		
			# calculation with eta values
			if hasindex(WhateverYouNeed["results"], "eta") then
				# store calculation results for Excel export
				loadcaseResults := table();

				# calculate maximum of each code check item as well as the absolute maximum of a loadcase
				if type(WhateverYouNeed["results"]["eta"], table) then
					loadcaseResults["eta"] := WhateverYouNeed["results"]["eta"]["max"];
					loadcaseResults["usedcode"] := WhateverYouNeed["results"]["comments"]["usedcode"];
					loadcaseResults["usedcodeDescription"] := WhateverYouNeed["results"]["comments"]["usedcodeDescription"];

					# looping through indices of calculations
					for dummy in indices(WhateverYouNeed["results"]["eta"], 'nolist') do
						if assigned(etamax[dummy]) then
							if etamax[dummy] < WhateverYouNeed["results"]["eta"][dummy] then
								etamax[dummy] := eval(WhateverYouNeed["results"]["eta"][dummy]);
								if dummy = "max" then
									loadcaseMax := loadcase;
								end if;
							end if
						else
							etamax[dummy] := eval(WhateverYouNeed["results"]["eta"][dummy]);							
						end if;
					end do;
					
				else		# numeric value
					loadcaseResults["eta"] := WhateverYouNeed["results"]["eta"];
					loadcaseResults["usedcode"] := WhateverYouNeed["results"]["comments"]["usedcode"];
					loadcaseResults["usedcodeDescription"] := WhateverYouNeed["results"]["comments"]["usedcodeDescription"];

					if etamax["max"] < loadcaseResults["eta"] then
						etamax["max"] := loadcaseResults["eta"];
						loadcaseMax := loadcase;
						#maxOfLoadcases["loadcase"] := loadcase;
						#maxOfLoadcases["usedcode"] := eval(loadcaseResults["usedcode"]);
						#maxOfLoadcases["comments"] := eval(loadcaseResults["comments"]);
						#WhateverYouNeed["results"]["maxOfLoadcases"] := maxOfLoadcases;
					end if;
				end if;
				
				WhateverYouNeed["results"][loadcase] := eval(loadcaseResults);		
			
				for j in indices(warnings, 'nolist') do
					if warningsAll = "" then
						warningsAll := cat(warnings[j], " (", loadcase, ")")
					else
						warningsAll := cat(warningsAll, ", ", warnings[j], " (", loadcase, ")")
					end if;
				end do;
			end if;	
					
			# calculation with inplane forces (without Faxd)
			if hasindex(WhateverYouNeed["results"], "FastenerGroup") then
				maxFindex := WhateverYouNeed["results"]["FastenerGroup"]["maxFindex"];
				maxF := WhateverYouNeed["results"]["FastenerGroup"]["ForcesInConnection"][maxFindex][3];

				if maxFallLoadcases < maxF or maxFallLoadcases = 0 then
					maxFallLoadcases := maxF;
					loadcaseMax := loadcase;
								
					maxloadedFastener["loadcase"] := loadcase;
					maxloadedFastener["Fx"] := WhateverYouNeed["results"]["FastenerGroup"]["ForcesInConnection"][maxFindex][1];
					maxloadedFastener["Fy"] := WhateverYouNeed["results"]["FastenerGroup"]["ForcesInConnection"][maxFindex][2];
					maxloadedFastener["F"] := maxF;
					maxloadedFastener["alpha"] := WhateverYouNeed["results"]["FastenerGroup"]["ForcesInConnection"][maxFindex][4];
					maxloadedFastener["fastener"] := maxFindex;
					maxloadedFastener["x"] := WhateverYouNeed["results"]["FastenerGroup"]["Fasteners"][maxFindex][1];
					maxloadedFastener["y"] := WhateverYouNeed["results"]["FastenerGroup"]["Fasteners"][maxFindex][2];
				
					WhateverYouNeed["results"]["maxloadedFastener"] := maxloadedFastener;
				end if;
			end if;
		end if;
	end do;

	# printing values to workbook

	if type(WhateverYouNeed["results"]["etamax"], table) then
		for dummy in indices(etamax, 'nolist') do
			if ComponentExists(cat("TextArea_eta", dummy, "_max")) then

				SetProperty(cat("TextArea_eta", dummy, "_max"), 'enabled', "true");
				
				if etamax[dummy] > 1 then 
					SetProperty(cat("TextArea_eta", dummy, "_max"), 'fontcolor', "Red");
				elif etamax[dummy] > 0.9 then
					SetProperty(cat("TextArea_eta", dummy, "_max"), 'fontcolor', "Orange");
				else
					SetProperty(cat("TextArea_eta", dummy, "_max"), 'fontcolor', "Green");				
				end if;
				
				SetProperty(cat("TextArea_eta", dummy, "_max"), 'value', round2(etamax[dummy], 2));								
			end if;
		end do;
		
	else	
		
		if ComponentExists("TextArea_etamax") then

			SetProperty("TextArea_etamax", 'enabled', "true");
			
			if etamax["max"] > 1 then 
				SetProperty("TextArea_etamax", 'fontcolor', "Red");
			elif etamax["max"] > 0.9 then
				SetProperty("TextArea_etamax", 'fontcolor', "Orange");
			else
				SetProperty("TextArea_etamax", 'fontcolor', "Green");
			end if;
			SetProperty("TextArea_etamax", 'enabled', "true");
			SetProperty("TextArea_etamax", 'value', round2(etamax["max"], 2));
		end if;
		
	end if;

	if ComponentExists("TextArea_loadcaseMax") then
		SetProperty("TextArea_loadcaseMax", 'enabled', "true");
		SetProperty("TextArea_loadcaseMax", 'value', loadcaseMax)
	end if;

	if ComponentExists("TextArea_warningsAll") then
		SetProperty("TextArea_warningsAll", 'enabled', "true");
		SetProperty("TextArea_warningsAll", 'value', warningsAll);
	end if;

	if hasindex(WhateverYouNeed["results"], "FastenerGroup") then
		NODEFastenerPattern:-SetComponentsCriticalLoadcase("activate", WhateverYouNeed)
	end if;

	# reset values to active loadcase
	WhateverYouNeed["calculations"]["activesettings"]["activeloadcase"] := activeloadcase;
	# WhateverYouNeed["calculations"]["calculatingAllLoadcases"]:= false;
	# WriteLoadsToDocument(loadcase, WhateverYouNeed);	
	# Main(WhateverYouNeed);

	# SetProperty("TextArea_activeloadcase", 'value', activeloadcase);	
	MainCommon("calculateAllLoadcasesCleanup")
end proc:


disableTextAreaEtaMax := proc(WhateverYouNeed::table)
	description "Disable TextArea for etamax, showing that results are not updated";
	local dummy;

	if type(WhateverYouNeed["results"]["etamax"], table) then
		
		for dummy in indices(WhateverYouNeed["results"]["eta"], 'nolist') do			# need to use eta indices, as etamax probably are not calculated yet
			
			if ComponentExists(cat("TextArea_eta", dummy, "_max")) then
				SetProperty(cat("TextArea_eta", dummy, "_max"), 'enabled', "false");							
			end if;
			
		end do;

	else
		
		if ComponentExists("TextArea_etamax") then
			SetProperty("TextArea_etamax", 'enabled', "false");
		end if;
		
	end if;
end proc: 


WriteLoadsToDocument := proc(loadcase, WhateverYouNeed::table)
	description "Get loadcases and write to document";
	local i, dummy, loadvariables, loadcases;

	loadvariables := WhateverYouNeed["calculations"]["loadvariables"];
	loadcases := WhateverYouNeed["calculations"]["loadcases"];

	SetProperty("TextArea_activeloadcase", 'value', loadcase);

	for i in loadvariables do
		if ComponentExists(cat("TextArea_", i)) then
			dummy := cat("TextArea_", i);	
			if assigned(loadcases[loadcase][i]) then
				if type(loadcases[loadcase][i], boolean) or (type(loadcases[loadcase][i], string) and loadcases[loadcase][i] = "false") then # must be false
					SetProperty(dummy, 'value', "0");
					SetProperty(dummy, 'enabled', false);
				else									# loadcases do also store 'enabled' property now
					SetProperty(dummy, 'enabled', true);
					SetProperty(dummy, 'value', convert(loadcases[loadcase][i], 'unit_free'));						
				end if;
			else 
				SetProperty(dummy, 'value', "0");
				SetProperty(dummy, 'enabled', false);
			end if;
	
		elif ComponentExists(cat("Slider_", i)) then
			SetProperty(cat("Slider_", i), 'value', convert(loadcases[loadcase][i], 'unit_free'));		
		else
			Alert(cat("Error in WriteLoadsToDocument with ", i), WhateverYouNeed["warnings"], 5)
		end if;
	end do;

	# check of values
	CalculateLoads(loadcase, false, "verify", WhateverYouNeed);
end proc:


SetVisibilityTextAreaLoads := proc(loadvar::string)
	description "Set visibility of load text areas";
	local activated;

	if ComponentExists(cat("TextArea_", loadvar, "d")) then
		if length(GetProperty(cat("TextArea_", loadvar, "d"), value)) = 0 then	# reset of design values, needs to be calculated
			SetProperty(cat("TextArea_", loadvar, "Gk"), 'enabled', true);
			SetProperty(cat("TextArea_", loadvar, "Qk"), 'enabled', true);
			activated := true
		else
			# SetProperty(cat("TextArea_", loadvar, "_Gk"), 'value', "0");
			# SetProperty(cat("TextArea_", loadvar, "_Qk"), 'value', "0");

			SetProperty(cat("TextArea_", loadvar, "Gk"), 'enabled', false);
			SetProperty(cat("TextArea_", loadvar, "Qk"), 'enabled', false);
			activated := false
		end if
	end if;	
	return activated
end proc:


ExcelFileInOut := proc(action::string, WhateverYouNeed::table) :: string;
	uses Maplets[Elements];
	description "Excel read and write operations";
	local cellvalue, i, j, f, id, filename, loaddata, varposition, loadname, loadnames, maplet, loadvariables, loadcases, coordinates, sheetname, sheetnames, dummy, selindex;

	# https://www.mapleprimes.com/questions/230384-File-Open-Dialogue-Box
	maplet := Maplet(FileDialog['FD1']('filefilter' = "xlsx", 'filterdescription' = "Excel file", 'onapprove' = Shutdown(['FD1']), 'oncancel' = Shutdown()));
	filename := Maplets['Display'](maplet);
	if type(filename, list) then
		filename := filename[1];
		if searchtext(".xlsx", filename, -5..-1) = 0 and searchtext(".xlsx", filename, -4..-1) = 0 then
			filename := cat(filename , ".xlsx")
		end if;
	else
		return
	end if;

	# template
	if action = "template" or action = "export" then
		if assigned(WhateverYouNeed["calculations"]["loadvariables"]) then
			loadvariables := eval(WhateverYouNeed["calculations"]["loadvariables"]);
			cellvalue := Vector[row](numelems(loadvariables)+4);
			cellvalue(1) := "Loadcase";
			for i from 1 to numelems(loadvariables) do
				cellvalue(i+1) := loadvariables[i]
			end do;
			if action = "export" then
				cellvalue(numelems(loadvariables)+2) := "eta";
				cellvalue(numelems(loadvariables)+3) := "codecheck";
				cellvalue(numelems(loadvariables)+4) := "comments";
			else 
				cellvalue(numelems(loadvariables)+2) := "";
				cellvalue(numelems(loadvariables)+3) := "";
				cellvalue(numelems(loadvariables)+4) := "";
			end if;
			ExcelTools:-Export(cellvalue, filename,	WhateverYouNeed["calculations"]["calculationtype_short"]);
		end if;

		# Fastener Group coordinate export
		if assigned(WhateverYouNeed["results"]["FastenerGroup"]["Fasteners"]) then
			cellvalue := Vector[row](3);
			cellvalue(1) := "(Id)";
			cellvalue(2) := "x";
			cellvalue(3) := "y";
			# cellvalue(2) := eval(WhateverYouNeed["coordinatevariables"])[1];
			# cellvalue(3) := eval(WhateverYouNeed["coordinatevariables"])[2];
			ExcelTools:-Export(cellvalue, filename, "coordinates")
		end if;
	end if;

	if action = "export" then
		if assigned(WhateverYouNeed["calculations"]["loadvariables"]) and assigned(WhateverYouNeed["calculations"]["loadcases"]) then
			loadvariables := eval(WhateverYouNeed["calculations"]["loadvariables"]);
			loadcases := eval(WhateverYouNeed["calculations"]["loadcases"]);
			cellvalue := Vector[row](numelems(loadvariables)+4);
			CalculateAllLoadcases(WhateverYouNeed);

			loadnames := sort([seq(indices(loadcases)[i][1], i = 1 .. numelems(loadcases))]);
	
			for i, loadname in loadnames do
				cellvalue(1) := loadname;
				for j from 1 to numelems(loadvariables) do
					cellvalue(j+1) := convert(loadcases[loadname][loadvariables[j]], 'unit_free')
				end do;
				
				if assigned(WhateverYouNeed["results"][loadname]["eta"]) then
					cellvalue(numelems(loadvariables)+2) := WhateverYouNeed["results"][loadname]["eta"];						
				else
					cellvalue(numelems(loadvariables)+2) := "";						
				end if;
				if assigned(WhateverYouNeed["results"][loadname]["usedcode"]) then
					cellvalue(numelems(loadvariables)+3) := WhateverYouNeed["results"][loadname]["usedcode"];						
				else						
					cellvalue(numelems(loadvariables)+3) := "";						
				end if;
				if assigned(WhateverYouNeed["results"][loadname]["usedcodeDescription"]) then						
					cellvalue(numelems(loadvariables)+4) := WhateverYouNeed["results"][loadname]["usedcodeDescription"];
				else												
					cellvalue(numelems(loadvariables)+4) := "";
				end if;
				
				ExcelTools:-Export(cellvalue, filename, WhateverYouNeed["calculations"]["calculationtype_short"], cat("A",i+1));
			end do;
		end if;

		# Fastener Group
		if assigned(WhateverYouNeed["results"]["FastenerGroup"]["Fasteners"]) then
			# coordinate export
			coordinates := ArrayTools:-Permute(convert(WhateverYouNeed["results"]["FastenerGroup"]["Fasteners"], Matrix), [2, 1]); # extract coordinates, convert to Matrix, switch rows and columns
			coordinates := convert~(coordinates, 'unit_free');
			f :=(i)->i;
			id := Vector(upperbound(coordinates)[1], f);
			ExcelTools:-Export(ArrayTools:-Concatenate(2, id, coordinates), filename, "coordinates", "A2");
		end if;
	end if;

	if action = "import" then

		# import loads
		loaddata := ExcelTools:-Import(filename, WhateverYouNeed["calculations"]["calculationtype_short"]);
		loadvariables := eval(WhateverYouNeed["calculations"]["loadvariables"]);
	
		for i from 1 to upperbound(loaddata)[2] do
			varposition[loaddata[1][i]] := i
		end do;

		if upperbound(loaddata)[1] > 1 then
			MainCommon("ResetLoadcase")
		end if;

		for i from 2 to upperbound(loaddata)[1] do
		
			loadname := convert(loaddata[i][1], string);
			SetProperty("TextArea_activeloadcase", 'value', loadname);
		
			if loadname <> "" then
			
				for j in loadvariables do
					if not type(j, string) then
						Alert(cat("Invalid variable type of ", j, " - type is: ", whattype(j)), WhateverYouNeed["warnings"], 3)
					#else
					#	Alert(cat("Variable type of ", j, " - type is: ", whattype(j)), warnings, 1);
					end if;
				
					cellvalue := eval(loaddata[i][varposition[j]]);

					if ComponentExists(cat("TextArea_", j)) then
						if cellvalue = "false" then
							SetProperty(cat("TextArea_", j), 'enabled', "false")
						else
							SetProperty(cat("TextArea_", j), 'enabled', "true");
							SetProperty(cat("TextArea_", j), 'value', cellvalue)
						end if
					elif ComponentExists(cat("Slider_", j)) then
						if cellvalue = "false" then
							SetProperty(cat("Slider_", j), 'enabled', "false")
						else
							SetProperty(cat("Slider_", j), 'enabled', "true");
							SetProperty(cat("Slider_", j), 'value', cellvalue)
						end if
					end if;					
				end do;
				MainCommon("NewLoadcase")
			end if;
		
		end do;

		# coordinates
		sheetnames := ExcelTools:-WorkbookData(filename)[1];
		
		if member("coordinates", sheetnames) then
			
			dummy := ExcelTools:-Import(filename, "coordinates");
			coordinates := dummy[2..upperbound(dummy)[1], 2..upperbound(dummy)[2]];	# cut away Header and ID, return just coordinates
			dummy := cat(coordinates[1, 1], " ", coordinates[1, 2]);

			if upperbound(coordinates)[1] > 1 then
				for i from 2 to upperbound(coordinates)[1] do
					dummy := cat(dummy, ", ", coordinates[i, 1], " ", coordinates[i, 2])
				end do;

				if ComponentExists("TextArea_coordinates") then
					SetProperty("TextArea_coordinates", 'enabled', "true");
					SetProperty("TextArea_coordinates", 'value', convert(dummy, string));
					if ComponentExists("ComboBox_FastenerPatternType") then
						selindex := ListTools:-Search("coordinates", GetProperty("ComboBox_FastenerPatternType", 'itemList')) - 1;	# index of "coordinates" in Combobox
						SetProperty("ComboBox_FastenerPatternType", 'selectedindex', selindex)
					end if;
				end if;
			end if;
		end if;			
	end if;

	return filename
end proc:


Write_eta := proc(eta::table, comments::table)
	description "Write color coded eta values to document";
	local dummy, i;

	for dummy in indices(eta, 'nolist') do
	
		# active loadcase
		if WhateverYouNeed["calculations"]["calculatingAllLoadcases"] = false then
	
			if ComponentExists(cat("TextArea_eta", dummy, "_active")) then

				HighlightResults({cat("eta", dummy, "_active")}, "highlight");
			
				if eta[dummy] > 1 then 
					SetProperty(cat("TextArea_eta", dummy, "_active"), 'fontcolor', "Red");
				elif eta[dummy] > 0.9 then
					SetProperty(cat("TextArea_eta", dummy, "_active"), 'fontcolor', "IndianRed");
				else
					SetProperty(cat("TextArea_eta", dummy, "_active"), 'fontcolor', "Green");				
				end if;
			
				SetProperty(cat("TextArea_eta", dummy, "_active"), 'value', round2(eta[dummy], 2));

			elif ComponentExists(cat("TextArea_eta", dummy)) then

				HighlightResults({cat("eta", dummy)}, "highlight");
			
				if eta[dummy] > 1 then 
					SetProperty(cat("TextArea_eta", dummy), 'fontcolor', "Red");
				elif eta[dummy] > 0.9 then
					SetProperty(cat("TextArea_eta", dummy), 'fontcolor', "IndianRed");
				else
					SetProperty(cat("TextArea_eta", dummy), 'fontcolor', "Green");				
				end if;
			
				SetProperty(cat("TextArea_eta", dummy), 'value', round2(eta[dummy], 2));
				
			end if;

			if ComponentExists("TextArea_Printactiveloadcase") then
				SetProperty("TextArea_Printactiveloadcase", 'value', WhateverYouNeed["calculations"]["activesettings"]["activeloadcase"]);
			end if;
																
		end if;
	
	end do;

	# print comments, sorted by alphabetical order of index
	dummy := "";
	for i in indices(comments, 'nolist', 'indexorder') do
		if type(comments[i], string) then
			dummy := cat(dummy, " / ", comments[i])
		end if;
	end do;

	if length(dummy) > 4 then
		dummy := substring(dummy, 4..-1);		# eliminate  /  at the start
	end if;
	if ComponentExists("TextArea_comments") and dummy <> "" then
		SetProperty("TextArea_comments", 'value', dummy);
	end if;	
end proc:


Write_eta2 := proc(eta, usedcode::string, comments, loadcase)
	description "Write color coded eta values to document";

	if ComponentExists("TextArea_activeloadcase") then
		SetProperty("TextArea_activeloadcase", 'value', loadcase)
	end if;

	if ComponentExists("TextArea_usedcode") then
		SetProperty("TextArea_usedcode", 'value', usedcode)
	end if;

	if ComponentExists("TextArea_eta") then
		SetProperty("TextArea_eta", 'value', round2(eta,2));
		if eta > 1 then 
			SetProperty("TextArea_eta", 'fontcolor', "Red");
		elif eta > 0.9 then
			SetProperty("TextArea_eta", 'fontcolor', "Orange");
		else
			SetProperty("TextArea_eta", 'fontcolor', "Green");
		end if;
	end if;

	if ComponentExists("TextArea_Printactiveloadcase") then
		SetProperty("TextArea_Printactiveloadcase", 'value', loadcase);
	end if;

	if ComponentExists("TextArea_comments") then
		SetProperty("TextArea_comments", 'value', comments)
	end if;
end proc:


SyncSliderWithTextArea := proc(i::string)
	description "synchronize sliders with text values";
	
	if ComponentExists(cat("Slider_", i)) and ComponentExists(cat("TextArea_", i)) then
		SetProperty(cat("Slider_", i), 'value', parse(GetProperty(cat("TextArea_", i), value)))
	end if;		
end proc:


MaterialChanged := proc(material::string, activematerial::string, WhateverYouNeed::table, forceSectionUpdate, partsnumber::string)
	uses DocumentTools;
	description "Routines after material has changed";
	local sectionchanged, warnings, activesection, activesettings, XMLImport;

	activesettings := WhateverYouNeed["calculations"]["activesettings"];
	warnings := WhateverYouNeed["warnings"];

	if assigned(WhateverYouNeed["calculations"]["XMLImport"]) then
		XMLImport := WhateverYouNeed["calculations"]["XMLImport"]
	else
		XMLImport := false
	end if;

	if ComponentExists(cat("TextArea_activematerial", partsnumber)) then
		SetProperty(cat("TextArea_activematerial", partsnumber), 'value', activematerial);
		# WhateverYouNeed["calculations"]["activesettings"][cat("activematerial", partsnumber)] := activematerial		# this erases other stuff and I don't know why
		activesettings[cat("activematerial", partsnumber)] := activematerial
	end if;

	sectionchanged := false;

	if material = "concrete" then
		NODEConcreteEN1992:-GetMaterialdata(activematerial, WhateverYouNeed);
		NODEConcreteEN1992:-SetComboBoxMaterial(WhateverYouNeed);
		updateResults(WhateverYouNeed["materialdata"]);

	elif material = "steel" then
		NODESteelEN1993:-GetMaterialdata(activematerial, WhateverYouNeed);
		NODESteelEN1993:-SetComboBoxMaterial(WhateverYouNeed);
		updateResults(WhateverYouNeed["materialdata"]);
		
	elif material = "timber" then
		
		if partsnumber <> "steel" then
			NODETimberEN1995:-GetMaterialdata(activematerial, WhateverYouNeed);								# get material properties of active material
		else
			NODESteelEN1993:-GetMaterialdata(activematerial, WhateverYouNeed);
		end if;
		
		if partsnumber <> "" then
			WhateverYouNeed["materialdataAll"][partsnumber] := eval(WhateverYouNeed["materialdata"])
		end if;

		if partsnumber <> "steel" then
			sectionchanged := NODETimberEN1995:-SetComboBoxMaterial(WhateverYouNeed, forceSectionUpdate, partsnumber);		# check if component boxes of material need to be updated
			updateResults(WhateverYouNeed["materialdata"]);
		
			if sectionchanged and XMLImport = false then						# problem when material is changed in XMLImport, as activesection will be overwritten
				activesection := NODETimberEN1995:-GetActiveSectionName(WhateverYouNeed, partsnumber);
				SectionChanged(material, activesection, WhateverYouNeed, partsnumber);				
			end if;
			
		elif XMLImport = false then
			activesection := NODETimberEN1995:-GetActiveSectionName(WhateverYouNeed, partsnumber);
			SectionChanged(material, activesection, WhateverYouNeed, partsnumber);
							
		end if;

	else
		Alert(cat("MaterialChanged: unknown material ", material), warnings, 2)
	
	end if;
	
	return sectionchanged;
end proc:


# this one is to be changed, we need to have it working for both steel and timber sections
SectionChanged := proc(material::string, activesection::string, WhateverYouNeed::table, partsnumber::string)
	description "Change of section properties";
	local warnings, activesettings;

	warnings := WhateverYouNeed["warnings"];
	activesettings := WhateverYouNeed["calculations"]["activesettings"];

	if ComponentExists(cat("TextArea_activesection", partsnumber)) then
		SetProperty(cat("TextArea_activesection", partsnumber), 'value', activesection);
		activesettings[cat("activesection", partsnumber)] := activesection
	end if;
	
	if material = "concrete" then
	#	materialdata := NODEConcreteEN1992:-GetMaterialdata(activematerial, warnings);
	#	NODEConcreteEN1992:-SetComboBoxMaterial(WhateverYouNeed);
	#	updateResults(materialdata);																# update material property component boxes

	elif material = "steel" then
		NODESteelEN1993:-GetSectiondata(activesection, WhateverYouNeed);
		NODESteelEN1993:-SetComboBoxMaterial(WhateverYouNeed);
		updateResults(WhateverYouNeed["sectiondata"]);
		
	elif material = "timber" then
		
		if partsnumber <> "steel" then
			NODETimberEN1995:-GetSectiondata(activesection, WhateverYouNeed);				
		else
			NODESteelEN1993:-GetSectiondata(activesection, WhateverYouNeed);			
		end if;

		# try existing function instead
		SetProperty(cat("TextArea_b", partsnumber), 'value', convert(convert(WhateverYouNeed["sectiondata"]["b"], 'unit_free'), string));
		SetProperty(cat("TextArea_h", partsnumber), 'value', convert(WhateverYouNeed["sectiondata"]["h"], 'unit_free'));

		if assigned(WhateverYouNeed["sectiondata"]["bout"]) then
			if WhateverYouNeed["sectiondata"]["bout"] <> "false" then
				SetProperty(cat("TextArea_bout", partsnumber), 'value', convert(convert(WhateverYouNeed["sectiondata"]["bout"], 'unit_free'), string));
			else
				SetProperty(cat("TextArea_bout", partsnumber), 'enabled', "false")
			end if;
		end if;

		updateResults(WhateverYouNeed["sectiondata"]);
		
		if partsnumber <> "" then
			WhateverYouNeed["sectiondataAll"][partsnumber] := eval(WhateverYouNeed["sectiondata"])
		end if;

	else
		Alert(cat("SectionChanged: unknown material ", material), warnings, 2)
		
	end if;

	# return eval(sectiondata)
end proc:


LibInitCommon := proc(WhateverYouNeed, calculationtype)
	description "Initialize variables and more";
	local componentvariables, warnings, comments, eta, usedcode, usedcodeDescription, etamax, projectdata, calculations, material, autoloadsave,
		autocalc, materials, materialdata, materialdataAll, structure, activesettings, results;
	local section, sections, sectiondata, sectiondataAll, loadvariables, loadcases, calculatedvalues, logs;
	local var_projectdata, var_materials, var_sections, var_calculations, var_loadvariables, var_calculationdata, var_storeitems, var_ComboBox, i;

	# variables used to check if data from XML file are complete and correct
	var_projectdata  := {"projectnumber", "projecttitle", "client"};		# primary input variables for project
	var_materials := {"materials"};
	var_sections := {"sections"};
	var_calculations := {};
	# var_calculationdata := {"positionnumber", "positiontitle", "calculationtype", "calculationtype_short", "activeloadcase"};
	var_calculationdata := {"positionnumber", "positiontitle", "calculationtype", "calculationtype_short"};
	# var_storeitems := {"projectdata", "materials", "sections", "calculations/calculationtype", "calculations/positionnumber",
	#	"calculations/positiontitle", "calculations/activeloadcase", "calculations/loadcases", "calculations/structure", "calculations/activesettings"};
	var_storeitems := {"projectdata", "materials", "sections", "calculations/calculationtype", "calculations/positionnumber",
		"calculations/positiontitle", "calculations/loadcases", "calculations/structure", "calculations/activesettings"};
	var_ComboBox := {"loadcases", "materials", "sections"};

	# calculationdata
	calculations := table();		# table of calculation data for xml export	
	calculations["calculationtype"] := calculationtype;
	
	if ComponentExists("TextArea_calculationtype") then
		SetProperty("TextArea_calculationtype", 'value', calculationtype)
	end if;

	#componentvariables
	componentvariables := table();
	componentvariables["var_projectdata"] := eval(var_projectdata);
	componentvariables["var_materials"] := eval(var_materials);
	componentvariables["var_sections"] := eval(var_sections);
	componentvariables["var_calculations"] := eval(var_calculations);
	componentvariables["var_calculationdata"] := eval(var_calculationdata);
	componentvariables["var_storeitems"] := eval(var_storeitems);
	componentvariables["var_ComboBox"] := eval(var_ComboBox);

	# other local variables
	autoloadsave := true;			# automatic save of load definition changes
	autocalc := true;				# automatic calculation of results
	comments := table();			# comments regarding dimensioning
	eta := table();		
	usedcode := table();
	usedcodeDescription := table();
	etamax := table();
	warnings := table();			# table of warnings and errors
	projectdata := table();
	logs := table();

	# init necessary for xml export of sheets without declarations of those variables
	loadcases := table();
	structure := table();
	activesettings := table();
	results := table();
	material := "";
	materials := table();
	materialdata := table();
	materialdataAll := table();
	# section := table();
	sections := table();
	sectiondata := table();
	sectiondataAll := table();
	calculatedvalues := table();

	# loadvariables, based on existance of Components
	loadvariables := {};
	var_loadvariables := {"alpha", "F_axGk", "F_axQk", "F_xGk", "F_xQk", "F_hGk", "F_hQk", "F_vGk", "F_vQk", "V_zGk", "V_zQk", "V_yGk", "V_yQk", "M_yGk", "M_yQk", "M_zGk", "M_zQk", "M_tGk", "M_tQk",
							"F_axd", "F_xd", "F_hd", "F_vd", "V_yd", "V_zd", "M_yd", "M_zd", "M_td", "loadcenter_x", "loadcenter_y"};
	for i in var_loadvariables do
		if ComponentExists(cat("TextArea_", i)) or ComponentExists(cat("Slider_", i)) then
			loadvariables := loadvariables union {i}
		end if;
	end do;
	
	# clear warnings Textfield
	Alert("", warnings, 0);		# NODEFunction: message, warnings, level

	# add important variables to the one and only important global		
	WhateverYouNeed["projectdata"] := projectdata;
	WhateverYouNeed["sections"] := sections;
	WhateverYouNeed["materials"] := materials;
	WhateverYouNeed["calculations"] := calculations;
	
	calculations["loadcases"] := loadcases;
	calculations["structure"] := structure;	
	calculations["activesettings"] := activesettings;		
	calculations["autoloadsave"] := autoloadsave;
	calculations["autocalc"] := autocalc;
	calculations["loadvariables"] := loadvariables;

	results["eta"] := eta;		
	results["usedcode"] := usedcode;
	results["usedcodeDescription"] := usedcodeDescription;
	results["comments"] := comments;
	results["etamax"] := etamax;
	
	WhateverYouNeed["componentvariables"] := componentvariables;
			
	WhateverYouNeed["material"] := material;
	WhateverYouNeed["materialdata"] := materialdata;
	WhateverYouNeed["materialdataAll"] := materialdataAll;
	# WhateverYouNeed["section"] := section;					# ?
	WhateverYouNeed["sectiondata"] := sectiondata;
	WhateverYouNeed["sectiondataAll"] := sectiondataAll;
	WhateverYouNeed["results"] := results;
	WhateverYouNeed["calculatedvalues"] := calculatedvalues;
	WhateverYouNeed["warnings"] := warnings;
	WhateverYouNeed["logs"] := logs;
	
end proc:


isNumeric := proc(varname::string, WhateverYouNeed::table)::boolean;
	description "Check if variable is numeric or not";
	local answer, dummy;

	answer := false;
	for dummy in WhateverYouNeed["componentvariables"]["var_numeric"] do
		if StringTools:-Search(dummy, varname) > 0 then
			answer := true
		end if;
	end do;

	for dummy in WhateverYouNeed["calculations"]["loadvariables"] do
		if StringTools:-Search(dummy, varname) > 0 then
			answer := true
		end if;
	end do;

	return answer
end proc:


Storesettings := proc(WhateverYouNeed::table)
	description "Storing settings to file";
	local temp, dummy, storeitems, parent, child, newtable;

	storeitems := WhateverYouNeed["componentvariables"]["var_storeitems"];

	temp := table();

	for dummy in storeitems do
		
		if searchtext("/", dummy) > 0 then 		# "calculations/positionnumber"

			parent := StringTools:-Split(dummy, "/")[1];
			child := StringTools:-Split(dummy, "/")[2];

			if assigned(temp[parent]) = false then
				newtable := table();
				temp[parent] := eval(newtable);
			end if;
			
			if assigned(WhateverYouNeed[parent][child]) then
				if type(WhateverYouNeed[parent][child], string) then
					newtable[child] := WhateverYouNeed[parent][child]
				
				elif type(WhateverYouNeed[parent][child], table) then
					newtable[child] := table(WhateverYouNeed[parent][child])
				
				end if;
			end if;
			
		else
			
			if assigned(WhateverYouNeed[dummy]) then
				if type(WhateverYouNeed[dummy], string) then
					temp[dummy] := WhateverYouNeed[dummy]
				
				elif type(WhateverYouNeed[dummy], table) then
					temp[dummy] := table(WhateverYouNeed[dummy])
				
				end if;
			end if;
		end if;
	end do;

	StoresettingsLocal(temp)		# save local using global variable
end proc:


Restoresettings := proc(storedsettings::Matrix, WhateverYouNeed::table)
description "Restoring settings from file";
local temp, dummy, dummy1;

temp := table(storedsettings[1,1]);

for dummy in indices(temp, 'nolist') do		# "calculations", "sections", "projectdata", "materials"
	if type(temp[dummy], table) then			
		if assigned(WhateverYouNeed[dummy]) then
			
			for dummy1 in indices(temp[dummy], 'nolist') do
				if type(temp[dummy][dummy1], table) then
					WhateverYouNeed[dummy][dummy1] := table(eval(temp[dummy][dummy1]))			# still having problems with units due to bug in Maple 2022
					
				elif type(temp[dummy][dummy1], string) then
					WhateverYouNeed[dummy][dummy1] := temp[dummy][dummy1]
					
				end if;
			end do;
			
		else				
			WhateverYouNeed[dummy] := table(eval(temp[dummy]))
			
		end if;
		
	elif type(temp[dummy], string) then			
		WhateverYouNeed[dummy] := temp[dummy]
		
	end if;
	
end do;
		
end proc:


StoredsettingsToComponents := proc(WhateverYouNeed::table)
	description "Write stored values to components in sheet";
	local checkvar, dummy, j, k, storeitems, parent, child;

	storeitems := WhateverYouNeed["componentvariables"]["var_storeitems"];

	for dummy in storeitems do
		
		# checkvar := WhateverYouNeed["componentvariables"][cat("var_", i)];
		checkvar := {"nocheck"};

		# We do either have TextAreas to be filled with values (default), or ComboBoxes where values need to be added (values below are stored in variables, not in Components)
		# ComboBoxes can also have predefined values, where the right value needs to be setattribute
		# name of the special ComboBoxes where we fill values during the run need to be defined (e.g. "loadcases" "FastenerPatterns", materials, sections).

		if searchtext("/", dummy) > 0 then 		# "calculations/positionnumber", "calculations/structure"
			parent := StringTools:-Split(dummy, "/")[1];
			child := StringTools:-Split(dummy, "/")[2];
			
			if assigned(WhateverYouNeed[parent][child]) then
				
				if type(WhateverYouNeed[parent][child], string) then
					checkvar := WriteValueToComponent(child, WhateverYouNeed[parent][child], checkvar)

				elif member(cat("-",child), WhateverYouNeed["componentvariables"]["var_ComboBox"]) then			
					# "-variable" will be ignored

				# tables, where contents need to be stored into ComboBoxes, e.g. loadcases, materials, sections
				# those Comboboxes do not change values in other Comboboxe
				elif member(child, WhateverYouNeed["componentvariables"]["var_ComboBox"]) then		
					ModifyComboVariables(cat("ComboBox_", child), "Write", WhateverYouNeed[parent][child], table());	# write new values to combobox

				elif type(WhateverYouNeed[parent][child], table) then	# ["calculations"]["structure"]

					# didn't manage to do that recursive, so we need to do that manually a couple of levels downwards
					for j in indices(WhateverYouNeed[parent][child], 'nolist') do
					
						if type(WhateverYouNeed[parent][child][j], string) or type(WhateverYouNeed[parent][child][j], numeric) then
							checkvar := WriteValueToComponent(j, WhateverYouNeed[parent][child][j], checkvar)

						elif type(WhateverYouNeed[parent][child][j], boolean) then
							checkvar := WriteValueToComponent(j, WhateverYouNeed[parent][child][j], checkvar)							

						elif type(WhateverYouNeed[parent][child][j], 'with_unit') then
							checkvar := WriteValueToComponent(j, convert(convert(WhateverYouNeed[parent][child][j], 'unit_free'), string), checkvar)

						elif member(cat("-",j), WhateverYouNeed["componentvariables"]["var_ComboBox"]) then
							# "-variable" will be ignored

						# tables, where contents need to be stored into ComboBoxes, e.g. loadcases, materials, sections
						elif member(j, WhateverYouNeed["componentvariables"]["var_ComboBox"]) then		
							if ComponentExists(cat("ComboBox_", j)) then
								ModifyComboVariables(cat("ComboBox_", j), "Write", WhateverYouNeed[parent][child][j], table());	# write new values to combobox
							else
								Alert(cat("StoredsettingsToComponents: ComboBox_", j, " not found"), WhateverYouNeed["warnings"], 1)
							end if;

						elif type(WhateverYouNeed[parent][child][j], table) then	#  ["calculations"]["structure"]["fastener"]

							for k in indices(WhateverYouNeed[parent][child][j], 'nolist') do
						
								if type(WhateverYouNeed[parent][child][j][k], string) or type(WhateverYouNeed[parent][child][j][k], numeric) then
									checkvar := WriteValueToComponent(k, WhateverYouNeed[parent][child][j][k], checkvar)

								elif type(WhateverYouNeed[parent][child][j][k], boolean) then
									checkvar := WriteValueToComponent(k, WhateverYouNeed[parent][child][j][k], checkvar)

								elif type(WhateverYouNeed[parent][child][j][k], 'with_unit') then
									checkvar := WriteValueToComponent(k, convert(convert(WhateverYouNeed[parent][child][j][k], 'unit_free'), string), checkvar)

								elif member(cat("-",k), WhateverYouNeed["componentvariables"]["var_ComboBox"]) then
									# "-variable" will be ignored

								elif member(k, WhateverYouNeed["componentvariables"]["var_ComboBox"]) then		# tables, where contents need to be stored into ComboBoxes, e.g. loadcases, materials, sections
									ModifyComboVariables(cat("ComboBox_", k), "Write", WhateverYouNeed[parent][child][j][k], table());	# write new values to combobox
								
								elif type(WhateverYouNeed[parent][child][j][k], table) then								
									Alert("Missing implementation in StoredsettingsToComponents 1a", WhateverYouNeed["warnings"], 1);

								else							
									Alert(cat("Missing implementation in StoredsettingsToComponents 1b for variable ", k), WhateverYouNeed["warnings"], 1);
									
								end if;
							end do;
							
						else							
							Alert(cat("Missing implementation in StoredsettingsToComponents: ", WhateverYouNeed[parent][child][j], ",  type ", whattype(WhateverYouNeed[parent][child][j])), WhateverYouNeed["warnings"], 1);
							
						end if;
						
					end do;
					
				else
					Alert(cat("Unknown value ", dummy), WhateverYouNeed["warnings"], 1);
					
				end if;

			else
				Alert(cat("Unassigned value ", dummy), WhateverYouNeed["warnings"], 1);

			end if;
			
		else
			if assigned(WhateverYouNeed[dummy]) then
				
				# top level string variables should not exist
				if type(WhateverYouNeed[dummy], string) or type(WhateverYouNeed[dummy], numeric) then
					checkvar := WriteValueToComponent(dummy, WhateverYouNeed[dummy], checkvar)	

				elif type(WhateverYouNeed[dummy], 'with_unit') then
					checkvar := WriteValueToComponent(dummy, convert(convert(WhateverYouNeed[dummy], 'unit_free'), string), checkvar)	

				elif member(cat("-",dummy), WhateverYouNeed["componentvariables"]["var_ComboBox"]) then
					# "-variable" will be ignored

				# tables where we just fill comboboxes
				elif member(dummy, WhateverYouNeed["componentvariables"]["var_ComboBox"]) then		# tables, where contents need to be stored into ComboBoxes, e.g. loadcases, materials, sections
						ModifyComboVariables(cat("ComboBox_", dummy), "Write", WhateverYouNeed[dummy], table());	# write new values to combobox

				elif type(WhateverYouNeed[dummy], table) then
					
					# didn't manage to do that recursive, so we need to do that manually a couple of levels downwards
					for j in indices(WhateverYouNeed[dummy], 'nolist') do
						
						if type(WhateverYouNeed[dummy][j], string) or type(WhateverYouNeed[dummy][j], numeric) then
							checkvar := WriteValueToComponent(j, WhateverYouNeed[dummy][j], checkvar)

						elif type(WhateverYouNeed[dummy][j], 'with_unit') then
							checkvar := WriteValueToComponent(j, convert(convert(WhateverYouNeed[dummy][j], 'unit_free'), string), checkvar)							

						elif member(j, WhateverYouNeed["componentvariables"]["var_ComboBox"]) then		# tables, where contents need to be stored into ComboBoxes, e.g. loadcases, materials, sections
							ModifyComboVariables(cat("ComboBox_", j), "Write", WhateverYouNeed[dummy][j], table());	# write new values to combobox

						elif type(dummy[j], table) then
							
							for k in indices(WhateverYouNeed[dummy][j], 'nolist') do
						
								if type(WhateverYouNeed[dummy][j][k], string) or type(WhateverYouNeed[dummy][j][k], numeric) then
									checkvar := WriteValueToComponent(k, WhateverYouNeed[dummy][j][k], checkvar)

								elif type(WhateverYouNeed[dummy][j][k], 'with_unit') then
									checkvar := WriteValueToComponent(k, convert(convert(WhateverYouNeed[dummy][j][k], 'unit_free'), string), checkvar)

								elif member(k, WhateverYouNeed["componentvariables"]["var_ComboBox"]) then		# tables, where contents need to be stored into ComboBoxes, e.g. loadcases, materials, sections
									ModifyComboVariables(cat("ComboBox_", k), "Write", WhateverYouNeed[dummy][j][k], table());	# write new values to combobox

								elif type(WhateverYouNeed[dummy][j][k], table) then
									
									Alert("Missing implementation in StoredsettingsToComponents 2a", WhateverYouNeed["warnings"], 1);
									
								else
									Alert("Missing implementation in StoredsettingsToComponents 2b", WhateverYouNeed["warnings"], 1);
									
								end if;
								
							end do;
							
						else							
							Alert("Missing implementation in StoredsettingsToComponents 2c", WhateverYouNeed["warnings"], 1);
							
						end if;
						
					end do;

				else 
					Alert(cat("Unknown value ", dummy), WhateverYouNeed["warnings"], 1);
			
				end if;
			else
				Alert(cat("Unassigned value ", dummy), WhateverYouNeed["warnings"], 1);
			end if;
		end if;
	end do;
end proc:


HighlightResults := proc(var, action::string)
	description "Highlite detailed results";
	local dummy, i, fillcolor;

	if action = "highlight" then 
		fillcolor := "Gold"
	elif action = "deactivate" then
		fillcolor := "DarkSlateGray"
	else
		fillcolor := "White"		
	end if;

	if type(var, table) then
		for dummy in indices(var, 'nolist') do
			if type(var[dummy], set) then
				for i in var[dummy] do		
					if ComponentExists(cat("TextArea_", i)) then
						SetProperty(cat("TextArea_", i), 'fillcolor', fillcolor);			
					elif ComponentExists(cat("MathContainer_", i)) then
						SetProperty(cat("MathContainer_", i), 'fillcolor', fillcolor);			
					else
						Alert(cat("Component not found for ", i), table(), 1)				
					end if;		
				end do;	
			else
				Alert(cat("Variable ", var, ",  type ", whattype(var[dummy]), " not defined"), table(), 1)
			end if
		end do
		
	elif type(var, set) then
		
		for i in var do		
			if ComponentExists(cat("TextArea_", i)) then
				SetProperty(cat("TextArea_", i), 'fillcolor', fillcolor);			
			elif ComponentExists(cat("MathContainer_", i)) then
				SetProperty(cat("MathContainer_", i), 'fillcolor', fillcolor);			
			else
				Alert(cat("Component not found for ", i), table(), 1)				
			end if;		
		end do;

	else
		Alert(cat("Variable ", var, ", type ", whattype(var), " not defined"), table(), 1)				
	end if;

end proc:


# https://mapleprimes.com/questions/236468-Annotation-In-Plots
Segment2Arrow := proc(segm)
	uses geometry;
	description "Annotation dimension";
	local a, b, c;

	try
		a := map(coordinates, DefinedAs(segm))[1];
		b := map(coordinates, DefinedAs(segm))[2];
	catch "wrong type of argument":
		Alert(cat("Error, (in geometry:-DefinedAs) wrong type of argument, variable segm: ", whattype(segm), segm), table(), 5)
	end try;
	c := (a + b) / 2;
	return plots:-arrow(c, [a - c, b - c], width = 0.5, head_width = 2, head_length = 4, color = grey)
end proc:


# https://mapleprimes.com/questions/237354-Max-Maxindex-For-Tables#answer298333
maxIndexTable := proc(atable)
	description "returns max value and index of table";		
	local P, j;

	P := [indices](atable, 'pairs');
	j := lhs(P[max[index](rhs~(P))]);

	return atable[j], j

end proc:


# ResetDocument := proc()
#	description "Reset document as far as possible";
		
#	InitCommon();
#	MainCommon("ResetLoadcase")	
# end proc: