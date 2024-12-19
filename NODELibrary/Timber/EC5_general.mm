# EC5_general.mm : Eurocode 5 general procedures
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

SetComboBox := proc(WhateverYouNeed::table, forceSectionUpdate::boolean, partsnumber::string)::boolean;
	description "Set material combobox according to chosen material (complete) or timber type";
	local ind, val, foundit, sectionchanged;
		local materialdata, timbertype, strengthclass, serviceclass, loaddurationclass, warnings;

		# define local variables
		if partsnumber = "" then
			materialdata := WhateverYouNeed["materialdata"];
			
		elif partsnumber = "1" or partsnumber = "2" then		
			materialdata := WhateverYouNeed["materialdataAll"][partsnumber];
		end if;
		
		timbertype := materialdata["timbertype"];
		strengthclass := materialdata["strengthclass"];
		serviceclass := materialdata["serviceclass"];
		loaddurationclass := materialdata["loaddurationclass"];		
		warnings := WhateverYouNeed["warnings"];

		sectionchanged := false;

		# check if active timbertype is different from setting in combobox
		if (timbertype <> GetProperty(cat("ComboBox_timbertype", partsnumber), value)) or forceSectionUpdate then	# need to change
			foundit := false;
			for ind, val in GetProperty(cat("ComboBox_timbertype", partsnumber), 'itemList') do
				if timbertype = val then
					foundit := true;
					SetProperty(cat("ComboBox_timbertype", partsnumber), 'selectedIndex', ind-1)					# ind starter med 1, Comboboxindexer med 0
				end if;
			end do;
		
			if not foundit then
				Alert("Invalid timbertype", warnings, 5);
			else
				materialdata["timbertype"] := GetProperty(cat("ComboBox_timbertype", partsnumber), value);		# setting new value for timbertype
				
				# setting strengthclass
				if timbertype = "Solid timber" then					# set properties for strengthclass
					SetProperty(cat("ComboBox_strengthclass", partsnumber), 'itemList', NODETimberMaterial:-Strengthclasses("Solid timber"));
					
				elif timbertype = "Glued laminated timber" then
					SetProperty(cat("ComboBox_strengthclass", partsnumber), 'itemList', NODETimberMaterial:-Strengthclasses("Glued laminated timber"));
					
				elif timbertype = "CLT" then
					SetProperty(cat("ComboBox_strengthclass", partsnumber), 'itemList', NODETimberMaterial:-Strengthclasses("CLT"));
					
				else
					SetProperty(cat("ComboBox_strengthclass", partsnumber), 'itemList', NODETimberMaterial:-Strengthclasses("all"));
					
				end if;

				SetProperty(cat("ComboBox_strengthclass", partsnumber), 'selectedIndex', 0);		# pick first value
				
				sectionchanged := true;

				SetProperty(cat("ComboBox_b", partsnumber), 'itemList', NODETimberSections:-b[timbertype]);
				SetProperty(cat("ComboBox_b", partsnumber), 'selectedIndex', 0);
				Changed_bh(WhateverYouNeed, cat("b", partsnumber));
			end if;
		
		end if;

		# strengthclass
		if strengthclass <> GetProperty(cat("ComboBox_strengthclass", partsnumber), value) then
			foundit := false;
			if strengthclass = "" then		# undefined because we have a new timber type, set to first item in listdir
				SetProperty(cat("ComboBox_strengthclass", partsnumber), 'selectedIndex', 0);
				strengthclass := GetProperty(cat("ComboBox_strengthclass", partsnumber), value)
			else
				for ind, val in GetProperty(cat("ComboBox_strengthclass", partsnumber), 'itemList') do
					if val = strengthclass then
						foundit := true;
						SetProperty(cat("ComboBox_strengthclass", partsnumber), 'selectedIndex', ind-1);
					end if;
				end do;
				if not foundit then
					Alert("Invalid strengthclass", warnings, 5);
				end if;
			end if;
		end if;
	
		# serviceclass
		if "serviceclass" <> GetProperty("ComboBox_serviceclass", value) then
			foundit := false;
			for ind, val in GetProperty("ComboBox_serviceclass", 'itemList') do
				if val = serviceclass then
					foundit := true;
					SetProperty("ComboBox_serviceclass", 'selectedIndex', ind-1)
				end if;
			end do;
			if not foundit then
				Alert("Invalid serviceclass", warnings, 5);
			end if;
		end if;

		# loaddurationclass
		if "loaddurationclass" <> GetProperty("ComboBox_loaddurationclass", value) then
			foundit := false;
			for ind, val in GetProperty("ComboBox_loaddurationclass", 'itemList') do
				if val = loaddurationclass then
					foundit := true;
					SetProperty("ComboBox_loaddurationclass", 'selectedIndex', ind-1)
				end if;
			end do;
			if not foundit then
				Alert("Invalid loaddurationclass", warnings, 5);
			end if;
		end if;

		return sectionchanged
	end proc:


Changed_bh := proc(WhateverYouNeed::table, varname::string)
	description "Set Component for b and h for timber sections";
	local dim, partsnumber, b_, h_, warnings;
	
	warnings := WhateverYouNeed["warnings"];

	if StringTools:-Length(varname) = 1 then
		dim := varname;
		partsnumber := "";
	elif StringTools:-Length(varname) = 2 then
		dim := substring(varname, 1..1);
		partsnumber := substring(varname, 2..2);
	else
		Alert(cat("Changed_bh: undefined component ", varname), warnings, 3);
	end if;

	if dim = "b" then
		if NODEFunctions:-ComponentExists(cat("ComboBox_b", partsnumber)) then
			b_ := parse(GetProperty(cat("ComboBox_b", partsnumber), value));	# Combobox value is string, convert to number
			SetProperty(cat("TextArea_b", partsnumber), 'value', b_);
			if NODEFunctions:-ComponentExists(cat("TextArea_bout", partsnumber)) and GetProperty(cat("TextArea_bout", partsnumber), 'enabled') = "true" then
				SetProperty(cat("TextArea_bout", partsnumber), 'value', b_);
			end if;

			if partsnumber = "" then
				SetProperty(cat("ComboBox_h", partsnumber), 'itemList', NODETimberSections:-h[WhateverYouNeed["materialdata"]["timbertype"], b_]);
			else
				SetProperty(cat("ComboBox_h", partsnumber), 'itemList', NODETimberSections:-h[WhateverYouNeed["materialdataAll"][partsnumber]["timbertype"], b_]);
			end if;
			SetProperty(cat("ComboBox_h", partsnumber), 'selectedIndex', 0);
			h_ := parse(GetProperty(cat("ComboBox_h", partsnumber), value));
			SetProperty(cat("TextArea_h", partsnumber), 'value', h_);
		end if;
		
	elif dim = "h" then
		if NODEFunctions:-ComponentExists(cat("ComboBox_h", partsnumber)) then
			h_ := parse(GetProperty(cat("ComboBox_h", partsnumber), value));
			SetProperty(cat("TextArea_h", partsnumber), 'value', h_);
		end if;
		
	end if;

end proc:


# 3.2 / 3.3
# kh factor is going to be applied to formulas using f_mk / f_md and f_t0k / f_t0d
# need to calculate kh for each direction in case of bending
kh := proc(side::string, WhateverYouNeed::table)
	description "Calculation of kh factor according to 3.2 / 3.3";
	local kh, timbertype, h, warnings;

	timbertype := WhateverYouNeed["materialdata"]["timbertype"];
	warnings := WhateverYouNeed["warnings"];
	
	if side = "h" then
		h := WhateverYouNeed["sectiondata"]["h"];
	elif side = "b" then
		h := WhateverYouNeed["sectiondata"]["b"];
	elif side = "f_t0d" then
		if WhateverYouNeed["sectiondata"]["h"] > WhateverYouNeed["sectiondata"]["b"] then
			h := WhateverYouNeed["sectiondata"]["h"]
		else
			h := WhateverYouNeed["sectiondata"]["b"]
		end if
	else
		Alert("Invalid side for calculation of kh", warnings, 4);
	end if;
	
	if timbertype = "Glued laminated timber" then
		kh := max(min((600 * Unit('mm') / h)^0.1, 1.1), 1.0);	# en m� ha variable mellom ' ' n�r en bruker assign, ellers s� kommer det en feilmelding fordi variablen er definert med verdi allerede
		
	elif timbertype = "Solid timber" then
		kh := max(min((150*Unit('mm') / h)^0.2, 1.3), 1.0);
	else
		kh := 1.0
	end if;
	# `k__h` := k_h;	# 2D notasjon

	if side = "h" and NODEFunctions:-ComponentExists("TextArea_k_h") then
		HighlightResults({"k_h"}, "highlight");
		SetProperty("TextArea_k_h", 'value', round2(kh, 2))
		
	elif side = "b" and NODEFunctions:-ComponentExists("TextArea_k_hb") then
		HighlightResults({"k_hb"}, "highlight");
		SetProperty("TextArea_k_hb", 'value', round2(kh, 2))
	end if;
	
	return kh
end proc:


kmod := proc(loaddurationclass::string, serviceclass::string)
	description "Beregning av kmod faktor";
	local k_mod; # , `k__mod`;

	# loaddurationclass := WhateverYouNeed["materialdata"]["loaddurationclass"];
	# serviceclass := WhateverYouNeed["materialdata"]["serviceclass"];
	
	if loaddurationclass = "Permanent" then
		if serviceclass = "1" or serviceclass = "2" then 
			k_mod := 0.60
		else 
			k_mod := 0.50
		end if;
	elif loaddurationclass = "Long-term" then
		if serviceclass = "1" or serviceclass = "2" then 
			k_mod := 0.70
		else 
			k_mod := 0.55
		end if;
	elif loaddurationclass = "Medium-term" then
		if serviceclass = "1" or serviceclass = "2" then 
			k_mod := 0.80
		else 
			k_mod := 0.65
		end if;
	elif loaddurationclass = "Short-term" then
		if serviceclass = "1" or serviceclass = "2" then 
			k_mod := 0.90
		else 
			k_mod := 0.70
		end if;
	# fungerer ikke, fordi det er bug i editor, kan ikke sjekke norske s�rtegn
	# https://www.mapleprimes.com/posts/214334-SubString-With-Special-Characters?sp=214334
	elif loaddurationclass = "Instantaneous" then		
		if serviceclass = "1" or serviceclass = "2" then 
			k_mod := 1.10
		else 
			k_mod := 0.90
		end if;
	else
		k_mod := 0
	end if;
	# `k__mod` := k_mod;					# 2D notasjon
	# kmod_komplett(loaddurationclass);	# m� sende videre loaddurationclass etter endring av code
	return k_mod;
end proc:


GetMaterialdata := proc(activematerial::string, WhateverYouNeed::table)		# "GL 30c / serviceclass 3 / Langtidslast"
	uses NODETimberMaterial;
	description "Get materialvalues for predefined material";
	local timbertype, strengthclass, serviceclass, loaddurationclass;
	local firstpos, secondpos, materialdata;
	local f_mk, f_t0k, f_t90k, f_c0k, f_c90k, f_vk, f_rk, E_m0mean, E_m0k, E_m90mean, E_9005, G_mean, G_005, G_rmean, G_r05, rho_k, rho_mean, gamma_M;
	local f_md, f_t0d, f_t90d, f_c0d, f_c90d, f_vd, f_rd;
	local k_mod;
	
	firstpos := searchtext(" / Service class ", activematerial);					# posisjon for f�rste begrensning
	secondpos := searchtext(" / ", activematerial, firstpos + 1 .. -1) + firstpos;	# https://www.mapleprimes.com/questions/230804-Searchtext-Result-Position?sq=230804

	# Find which timber material we have, and see if we need to change combobox values
	if searchtext("CLT", activematerial, 1..3) > 0 then
		timbertype := "CLT"
	elif searchtext("L", activematerial, 1..2) > 0 then
		timbertype := "Glued laminated timber"	
	elif searchtext("C", activematerial, 1..2) > 0 then
		timbertype := "Solid timber"
	else
		Alert("Unknown timber type", WhateverYouNeed["warnings"], 5);
	end if;

	strengthclass := substring(activematerial, 1..firstpos-1);
	serviceclass := substring(activematerial, secondpos-1);
	loaddurationclass := substring(activematerial, secondpos + 3 .. -1);
	
	# karakteristiske materialverdier
	f_mk := eval(Property(strengthclass, "f_m,k"));						# f_mk needs to be modified by kh
	f_t0k := eval(Property(strengthclass, "f_t,0,k"));					# f_t0k needs to be modified by kh
	f_t90k := eval(Property(strengthclass, "f_t,90,k"));
	f_c0k := eval(Property(strengthclass, "f_c,0,k"));
     f_c90k := eval(Property(strengthclass, "f_c,90,k"));
	f_vk := eval(Property(strengthclass, "f_v,k"));
	f_rk := eval(Property(strengthclass, "f_r,k"));
	E_m0mean := eval(Property(strengthclass, "E_m,0,mean"));
	E_m0k := eval(Property(strengthclass, "E_m,0,k"));
	E_m90mean := eval(Property(strengthclass, "E_m,90,mean"));
	E_9005 := eval(Property(strengthclass, "E_90,05"));
	G_mean := eval(Property(strengthclass, "G_mean"));
	G_005 := eval(Property(strengthclass, "G_0,05"));
	G_rmean := eval(Property(strengthclass, "G_r,mean"));
	G_r05 := eval(Property(strengthclass, "G_r,05"));
	rho_k := eval(Property(strengthclass, "rho_k"));
	rho_mean := eval(Property(strengthclass, "rho_mean"));

	# lagre materialdata
	materialdata := table();
	materialdata["material"] := "timber";
	materialdata["name"] := activematerial;
	materialdata["timbertype"] := timbertype;
	materialdata["strengthclass"] := strengthclass;
	materialdata["serviceclass"] := serviceclass;
	materialdata["loaddurationclass"] := loaddurationclass;

	gamma_M := NODETimberEN1995:-gamma_M(timbertype);
	materialdata["gamma_M"] := gamma_M;

	materialdata["f_mk"] := f_mk;
	materialdata["f_t0k"] := f_t0k;
	materialdata["f_t90k"] := f_t90k;
	materialdata["f_c0k"] := f_c0k;
	materialdata["f_c90k"] := f_c90k;
	materialdata["f_vk"] := f_vk;
	materialdata["f_rk"] := f_rk;
	materialdata["E_m0mean"] := E_m0mean;
	materialdata["E_m0k"] := E_m0k;
	materialdata["E_m90mean"] := E_m90mean;
	materialdata["E_9005"] := E_9005;
	materialdata["G_mean"] := G_mean;
	materialdata["G_005"] := G_005;
	materialdata["G_rmean"] := G_rmean;
	materialdata["G_r05"] := G_r05;
	materialdata["rho_k"] := rho_k;
	materialdata["rho_mean"] := rho_mean;

	# dimensjonerende materialverdier
	
	# k_mod
	k_mod := kmod(loaddurationclass, serviceclass);
	f_md := f_mk * k_mod / gamma_M;								# f_md needs to be modified by kh
	f_t0d := f_t0k * k_mod / gamma_M;								# f_t0d needs to be modified by kh
	f_t90d := f_t90k * k_mod / gamma_M;
	f_c0d := f_c0k * k_mod / gamma_M;
	f_c90d := f_c90k * k_mod / gamma_M;
	f_vd := f_vk * k_mod / gamma_M;
	f_rd := f_rk * k_mod / gamma_M;

	materialdata["f_md"] := f_md;
	materialdata["f_t0d"] := f_t0d;
	materialdata["f_t90d"] := f_t90d;
	materialdata["f_c0d"] := f_c0d;
	materialdata["f_c90d"] := f_c90d;
	materialdata["f_vd"] := f_vd;
	materialdata["f_rd"] := f_rd;

	materialdata["k_mod"] := k_mod;

	WhateverYouNeed["materialdata"] := materialdata;
	
	# return materialdata;
end proc:


GetActiveSectionName := proc(WhateverYouNeed::table, partsnumber::string) ::string;		# partsnumber: "", 1, 2, steel
	description "Create activesection reading TextArea";
	local b_, bout_, h_, sectiontype;

	if NODEFunctions:-ComponentExists(cat("TextArea_b", partsnumber)) and GetProperty(cat("TextArea_b", partsnumber), 'enabled') = "true"
		and NODEFunctions:-ComponentExists(cat("TextArea_h", partsnumber)) and GetProperty(cat("TextArea_h", partsnumber), 'enabled') = "true" then
			
		# sectiontype := WhateverYouNeed["materialdata"]["timbertype"];
		sectiontype := "Rectangular";
					
		b_ := parse(GetProperty(cat("TextArea_b", partsnumber), value));	# Combobox value is string, convert to number
		h_ := parse(GetProperty(cat("TextArea_h", partsnumber), value));

		if NODEFunctions:-ComponentExists(cat("TextArea_bout", partsnumber)) and GetProperty(cat("TextArea_bout", partsnumber), 'enabled') = "true" then
			bout_ := parse(GetProperty(cat("TextArea_bout", partsnumber), value));
			if b_ <> bout_ then
				return cat(sectiontype, " / ", b_, "(", bout_, ")x", h_);
			else
				return cat(sectiontype, " / ", b_, "x", h_);
			end if;
		else
			return cat(sectiontype, " / ", b_, "x", h_);
		end if;
			
		
	else
		return "";
		# Alert(cat("GetActiveSectionName: TextArea_b", partsnumber, " / ", cat("TextArea_h", partsnumber), " not found"), WhateverYouNeed["warnings"], 3)
	end if
end proc:


GetSectiondata := proc(profilename::string, WhateverYouNeed::table)
	description "Get section data, just rectangular sections for the moment";
	local b, bout, h, A, W_y, W_z, I_y, I_z, I_t, i_y, i_z;
	local sectiontype, section, sectionproperties, sectiondata, b_, bout_, h_, i, j;

# 	warnings := WhateverYouNeed["warnings"];
	# Rectangular / bxh				usual name for rectangular sections
	# Rectanbular / b(bout)xh	name for sections with different b in ouside layer, section values calculated for main section

	sectionproperties := ["h", "b", "A", "I_y", "I_z", "I_t", "W_y", "W_z", "i_y", "i_z"];

	sectiontype := substring(profilename, 1 .. searchtext(" / ", profilename)-1);
	section := substring(profilename, searchtext(" / ", profilename)+3 .. -1);	

	if searchtext(section, "(") = 0 then
		b_ := parse(substring(section, 1 .. searchtext("x", section)-1));	# 71x85
		h_ := parse(substring(section, searchtext("x", section)+1 .. -1));
	else
		b_ := parse(substring(section, 1 .. searchtext("(", section)-1));	# 71(40)x85
		bout_ := parse(substring(section, searchtext("(", section)+1 .. searchtext(")", section)-1));	# 71(40)x85
		h_ := parse(substring(section, searchtext(")", section)+1 .. -1));
		bout := bout_ * Unit('mm');
	end if;
	
	b := b_ * Unit('mm');
	h := h_ * Unit('mm');

	# check 6.3.3 will not work
	# if b > h then
	# 	Alert("b > h not possible, switching of weak and strong axis not allowed", WhateverYouNeed["warnings"], 4)			
	# end if;

	A := b*h;
	I_y := evalf(b * h^3 / 12);
	I_z := evalf(h * b^3 / 12);
	W_y := evalf(b * h^2 / 6);
	W_z := evalf(h * b^2 / 6);
	i_y := sqrt(I_y/A);
	i_z := sqrt(I_z/A);
	
	i := max(b, h);
	j := min(b, h);
	I_t := evalf(1/3 * i * j^3 * (1 - 0.63 * j / i));		# Limtreboka side 171	

	sectiondata := table();
	sectiondata["name"] := cat(sectiontype, " / ", b_, "x", h_);
	sectiondata["sectiontype"] := sectiontype;
	sectiondata["b"] := b;
	sectiondata["h"] := h;
	sectiondata["A"] := A;
	sectiondata["I_y"] := I_y;
	sectiondata["I_z"] := I_z;
	sectiondata["W_y"] := W_y;
	sectiondata["W_z"] := W_z;
	sectiondata["i_y"] := i_y;
	sectiondata["i_z"] := i_z;
	sectiondata["I_t"] := I_t;

	if assigned(bout) then 
		sectiondata["bout"] := bout
	end if;

	WhateverYouNeed["sectionproperties"] := sectionproperties;
	WhateverYouNeed["sectiondata"] := sectiondata;
	
	# return eval(sectiondata);
end proc:


# https://www.mapleprimes.com/questions/231694-Check-If-Component-Exists
strengthclassExists:=proc(FK::{name,string})
	uses NODETimberMaterial;
	description "Sjekk om strengthclass finnes";
	try
		Property(FK, "f_m,k");
		true;
	catch:
		false;
	end try;
end proc: