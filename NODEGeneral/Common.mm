# NODETimber - Common

# startupcheck
# Reset
# InitCommon
# MainCommon
# ExcelInOut
# StoresettingsLocal
# RestoresettingsLocal

startupcheck := proc()::boolean;
	global startup;
	# https://www.mapleprimes.com/questions/229343-Startup-Code-Reexecuted-When-Pressing
	description "check if code is run during startup or -execute entire code-";	
	if startup = false then
		# Startup complete, we are running from Execute entire code
	else
		startup := true;	# Code run from Startup Code
	end if;
end proc:


Reset := proc()
	description "Reset of Document";
	global storesettings, WhateverYouNeed;
	storesettings := Matrix(1,1);
	InitCommon();
	ReadComponentsCommon("ResetLoadcase", WhateverYouNeed);		# Storesettings
	ResetSpecific(WhateverYouNeed);
	MainCommon("all");			# also runs Storesettings
end proc:


# 1.) Initialize variables
InitCommon := proc()
	description "Initialize variables and more";
	global WhateverYouNeed, calculationtype;
	
	WhateverYouNeed := table();		# all necessary variables are stored here
	LibInitCommon(WhateverYouNeed, calculationtype);		# initialization done in NODElibrary
	InitSpecific();
	
	# init necessary for xml export of sheets without declarations of those variables
	WhateverYouNeed["material"] := "timber";
		
end proc:


# 2.) Main routine
MainCommon := proc(action::string)
	description "Main routine to be started after all input";
	global WhateverYouNeed;

	ResetWarnings(WhateverYouNeed);
	ReadComponentsCommon(action, WhateverYouNeed);		# also runs Storesettings

	WhateverYouNeed["calculations"]["calculatingAllLoadcases"]:= false;		# not running calculation of all loadcases at the moment

	if MASTERALARM(WhateverYouNeed["warnings"]) = true then
		return
	end if;
	
	if action = "calculation" or action = "calculateAllLoadcasesCleanup" or WhateverYouNeed["calculations"]["autocalc"] then
		Main(WhateverYouNeed);			
	end if;

	if MASTERALARM(WhateverYouNeed["warnings"]) = false and WhateverYouNeed["calculateAllLoadcases"] and (action = "calculation" or WhateverYouNeed["calculations"]["autocalc"]) and action <> "calculateAllLoadcasesCleanup" then
	 	CalculateAllLoadcases(WhateverYouNeed)
	 	
	elif action = "calculateAllLoadcasesCleanup" then
		# nope
	else
		disableTextAreaEtaMax(WhateverYouNeed)
	end if
	
end proc:


ExcelInOut := proc(action::string)
	description "Call Excel read and write operations";
	global WhateverYouNeed, filename;
	local loadcase, loadcases, activeloadcase, cellvalue, node, ForcesInConnection;

#	activeloadcase := WhateverYouNeed["calculations"]["activeloadcase"];
#	loadcases := WhateverYouNeed["calculations"]["loadcases"];
	# pointList := WhateverYouNeed["results"]["FastenerGroup"]["Fasteners"];
	
	filename := ExcelFileInOut(action, WhateverYouNeed);

	# Headers
# 	cellvalue := Array(1..numelems(pointList) + 1, 1..5);
#	cellvalue[1,1] := "(Id)";
#	cellvalue[1,2] := "Fx [kN]";
#	cellvalue[1,3] := "Fy [kN]";
#	cellvalue[1,4] := "F [kN]";
#	cellvalue[1,5] := "alpha [deg]";

#	for loadcase in indices(loadcases, 'nolist', 'indexorder') do
#		WriteLoadsToDocument(loadcase, WhateverYouNeed);
#		WhateverYouNeed["calculations"]["activeloadcase"] := loadcase;
		
		# Calling the main calculation routine of the specific program
#		Main(WhateverYouNeed);
			
#		ExcelTools:-Export(cellvalue, filename, loadcase);
#	end do;
	
#	SetProperty("TextArea_activeloadcase", value, activeloadcase);
#	MainCommon("calculateAllLoadcasesCleanup");
end proc:


StoresettingsLocal := proc(saveitems::table)
	description "Saves settings to local document";
	global storesettings;

	storesettings[1,1] := eval(saveitems);
end proc:


RestoresettingsLocal := proc()
	description "Restore settings from stored value to document";
	global storesettings, WhateverYouNeed;

	Restoresettings(storesettings, WhateverYouNeed);		# restore values from "storedsettings" matrix to WhateverYouNeed
	StoredsettingsToComponents(WhateverYouNeed);
	RunAfterRestoresettings(WhateverYouNeed);	# local procedures to define secondary necessary settings
end proc:

# -- code not considered important below

notation2D := proc()
	description "Definere originale (lesbare) variabler i 2D notasjon";
	global `f__m,k`, `f__t,0,k`, `f__t,90,k`, `f__c,0,k`, `f__c,90,k`, `f__v,k`, `f__r,k`, `E__m,0,mean`, `E__m,0,k`, `E__m,90,mean`, `E__90,05`, `G__mean`, `G__0,05`, `G__r,mean`, `G__r,05`, `rho__k`, `rho__mean`, `gamma__M`;
	global `f__m,d`, `f__t,0,d`, `f__t,90,d`, `f__c,0,d`, `f__c,90,d`, `f__v,d`, `f__r,d`, `k__mod`;
	global f_mk, f_t0k, f_t90k, f_c0k, f_c90k, f_vk, f_rk, E_m0mean, E_m0k, E_m90mean, E_9005, G_mean, G_005, G_rmean, G_r05, rho_k, rho_mean, gamma_M, f_md, f_t0d, f_t90d, f_c0d, f_c90d, f_vd, f_rd, k_mod;

	`f__m,k` := f_mk;
	`f__t,0,k` := f_t0k;
	`f__t,90,k` := f_t90k;
	`f__c,0,k` := f_c0k;
	`f__c,90,k` := f_c90k;
	`f__v,k` := f_vk;
	`f__r,k` := f_rk;
	`E__m,0,mean` := E_m0mean;
	`E__m,0,k` := E_m0k;
	`E__m,90,mean` := E_m90mean;
	`E__90,05` := E_9005;
	`G__mean` := G_mean;
	`G__0,05` := G_005;
	`G__r,mean` := G_rmean;
	`G__r,05` := G_r05;
	`rho__k` := rho_k;
	`rho__mean` := rho_mean;
	`gamma__M` := gamma_M;

	`f__m,d` := f_md;
	`f__t,0,d` := f_t0d;
	`f__t,90,d` := f_t90d;
	`f__c,0,d` := f_c0d;
	`f__c,90,d` := f_c90d;
	`f__v,d` := f_vd;
	`f__r,d` := f_rd;

	`k__mod` := k_mod;					# 2D notasjon
	
end proc:


# NODETimber - GeneralCombobox

# GeneralCombobox
# her er det lagret code som behandler interaksjoner med Comboboxer som brukes i "Materialegenskaper Tre"
# kan ogs� brukes for comboboxer i andre worksheets med samme navn / funksjonalitet

# Denne procedure blir ikke brukt, man kan aktiviseres hvis en �nsker � resette variabler for hver gang
# SetDefaultValues := proc()
#	description "Reset Combobox til default verdier";
#	global startup, serviceclass, loaddurationclass, trematerialer;

#	if startup then
#		# Fyller Comboboxer med verdier
#		SetProperty("ComboBox_tretype", itemlist, trematerialer);
#		SetProperty("ComboBox_tretype", selectedIndex, 1);				# solidtimber
#		SetComboTimbermaterial("Solid timber");	

#		# serviceclass 1
#		SetProperty("ComboBox_serviceclass", selectedIndex, 0);
#		assign('serviceclass', GetProperty("ComboBox_serviceclass", value));

#		# loaddurationclass Permanent last
#		SetProperty("ComboBox_loaddurationclass", selectedIndex, 0);
#		assign('loaddurationclass', GetProperty("ComboBox_serviceclass", value));

#		kmod();
#		dimensjonerendeVerdier();

#		updateResultsMaterial();
#		startup := false;	# Ferdig med startup code, setter checkvariable
#	end if;
#end proc: