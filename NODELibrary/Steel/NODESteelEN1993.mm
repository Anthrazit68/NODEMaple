# NODESteelEN1993.mm : EN 1993 (steel) general procedures
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

	
GetMaterialdata := proc(material::string, WhateverYouNeed::table)		
	uses NODESteelMaterial, DocumentTools;
	description "Get materialvalues for predefined material";
	local steelcode, steelgrade, thicknessclass;
	local firstpos, secondpos, materialdata;
	local f_yk, f_uk, E, G, nu, alpha_t, gamma_M0, gamma_M1, gamma_M2;
	local f_yd, f_ud, warnings;

	warnings := WhateverYouNeed["warnings"];

	# NS-EN 10025-2 / S 355 / 0 - 40 mm
	firstpos := searchtext(" / ", material);					# posisjon for f�rste begrensning
	secondpos := searchtext(" / ", material, firstpos + 1 .. -1) + firstpos;	# https://www.mapleprimes.com/questions/230804-Searchtext-Result-Position?sq=230804

	steelcode := substring(material, 1..firstpos-1);
	steelgrade := substring(material, firstpos+3..secondpos-1);
	thicknessclass := substring(material, secondpos+3..-1);

	# characteristic material parameters
	if thicknessclass = "0 - 40 mm" then
		# f_yk := NODESteelMaterial:-Property(steelgrade, "f_y_0_40");
		# f_uk := NODESteelMaterial:-Property(steelgrade, "f_u_0_40");
		f_yk := eval(NODESteelMaterial:-Property1({steelgrade, steelcode}, "f_y_0_40"));
		f_uk := eval(NODESteelMaterial:-Property1({steelgrade, steelcode}, "f_u_0_40"));
		
	elif thicknessclass = "40 - 80 mm" then
		# f_yk := NODESteelMaterial:-Property(steelgrade, "f_y_40_80");
		# f_uk := NODESteelMaterial:-Property(steelgrade, "f_u_40_80");
		f_yk := eval(NODESteelMaterial:-Property1({steelgrade, steelcode}, "f_y_40_80"));
		f_uk := eval(NODESteelMaterial:-Property1({steelgrade, steelcode}, "f_u_40_80"));
	else 
		Alert("Invalid steel thickness", warnings, 5);
		f_yk := 0;
		f_uk := 0;
	end if;
	
	E := eval(NODESteelMaterial:-Property1({steelgrade, steelcode}, "E"));
	G := eval(NODESteelMaterial:-Property1({steelgrade, steelcode}, "G"));
	nu := eval(NODESteelMaterial:-Property1({steelgrade, steelcode}, "nu"));
	alpha_t := eval(NODESteelMaterial:-Property1({steelgrade, steelcode}, "alpha_t"));

	gamma_M0 := 1.05;
	gamma_M1 := 1.05;
	gamma_M2 := 1.25;

	# dimensjonerende materialverdier
	f_yd := f_yk / gamma_M0;
	f_ud := f_uk / gamma_M0;

	# lagre materialdata
	materialdata := table();
	materialdata["material"] := "steel";
	materialdata["name"] := material;
	materialdata["steelcode"] := steelcode;
	materialdata["steelgrade"] := steelgrade;
	materialdata["thicknessclass"] := thicknessclass;
	
	materialdata["gamma_M0"] := gamma_M0;
	materialdata["gamma_M1"] := gamma_M1;
	materialdata["gamma_M2"] := gamma_M2;

	materialdata["f_yk"] := f_yk;
	materialdata["f_uk"] := f_uk;
	materialdata["E"] := E;
	materialdata["G"] := G;
	materialdata["nu"] := nu;
	materialdata["alpha_t"] := alpha_t;
	
	materialdata["f_yd"] := f_yd;
	materialdata["f_ud"] := f_ud;

	WhateverYouNeed["materialdata"] := materialdata;
			
	# return eval(materialdata);

end proc:


GetSectiondata := proc(profilename::string, WhateverYouNeed::table)
	uses NODESteelProfiles_CF_SHS, NODESteelProfiles_CF_RHS, NODESteelProfiles_HF_SHS, NODESteelProfiles_HF_RHS, NODESteelProfiles_I, NODESteelProfiles_H, DocumentTools;
	description "Get steel profile data";
	local sectioncode, sectiontype, section, sectiondata;
	local data, metadata, sectionproperties, i, warnings;

	warnings := WhateverYouNeed["warnings"];

	# CF SHS / SHS 350 x 16
	sectiontype := substring(profilename, 1 .. searchtext(" / ", profilename)-1);
	section := substring(profilename, searchtext(" / ", profilename)+3 .. -1);

	if sectiontype = "Rectangular" then 
		SectiondataRectangular(profilename, WhateverYouNeed)
	else

		sectioncode := cat("NODESteelProfiles_",sectiontype,":-Property");	# NODESteelProfiles_CF SHS:-Property
		sectioncode := StringTools:-RegSubs(" " = "_", sectioncode);		# change "CF RHS" to "CF_RHS"

		sectionproperties := ["h", "b", "t_w", "t_f", "h_w", "d", "t", "r", "r_o", "r_i", "A", "A_m", "A_vy", "A_steg", "A_z", "A_vz", "U", "U_o", "U_i", "U_m", "m_k", "g_k", 
		"alpha_1", "alpha_2", "alpha_3", "alpha_4", "d_L", "w_1", "w_2", "w_3", 
		"I_y", "I_z", "I_p", "S_y", "S_z", "W_el_y", "W_el_z", "W_pl_y", "W_pl_z", "i_y", "i_z", "i_p", "alpha_pl_y", "alpha_pl_z", "I_t_0", "I_t", "omega_max", "omega_0", "omega_1", "omega_2", "omega_3", "I_omega", "W_omega",
		"S_omega_0", "S_omega_1", "S_omega_2", "S_omega_3", "S_omega_max",
		"cross_section_class_bending_S235", "cross_section_class_compression_S235", "cross_section_class_bending_S355", "cross_section_class_compression_S355", "cross_section_class_bending_S460", "cross_section_class_compression_S460",
		"N_pl_Rk_S235", "V_pl_y_Rk_S235", "V_pl_z_Rk_S235", "M_el_y_Rk_S235", "M_el_z_Rk_S235", "M_pl_y_Rk_S235", "M_pl_z_Rk_S235",
		"buckling_curve_y_S235-420", "buckling_curve_z_S235-420", "buckling_curve_y_S460", "buckling_curve_z_S460"];

		# store section data
		sectiondata := table();
		sectiondata["sectiontype"] := sectiontype;	# I, H, CF_SHS
		sectiondata["section"] := section;		# "HE 100 A"
		sectiondata["name"] := cat(sectiontype," / ", section);

		data := sprintf("%s(%a,%a)", sectioncode, section, "standard");		# legger til standard informasjon
		sectiondata["standard"] := eval(parse(data));

		metadata := sprintf("%s(%a)", sectioncode, "metadata");	# https://www.mapleprimes.com/questions/231067-Can-I-Have-An-Apostroph-In-Cat-
		metadata := eval(parse(metadata));

		# go through section properties
		for i in sectionproperties do

			# check if data is defined for the profile
			if member(i, metadata) then
				data := sprintf("%s(%a,%a)", sectioncode, section, i);		# get section property
				sectiondata[i] := eval(parse(data));
			
			else
				if searchtext("SHS", sectioncode) > 0 then
					if i = "b" then					# kopierer h verdi til b for quadratiske profiler
						data := sprintf("%s(%a,%a)", sectioncode, section, "h");		# henter tverrsnittsdata
						sectiondata[i] := eval(parse(data));
						# Ezzat profildata har definert verdier b�de for z og y, dvs. det er ikke n�dvendig � kopiere data over lenger
						# elif Search("z", i) > 0 then								# kopier y verdier til z verdier for quadratiske profiler
						#	k := StringTools:-RegSubs("z" = "y", i);			
						#	data := sprintf("%s(%a,%a)", sectioncode, section, k);		# henter tverrsnittsdata
						#	SetProperty(j, 'value', eval(parse(data)));
						#	sectiondata[i] := eval(parse(data));
					else													# nuller ut andre verdier
						sectiondata[i] := 0;
					end if
				else														# nuller ut verdier for alt annet
					sectiondata[i] := 0;
				end if;
			
			end if;

			# sjekker om det er RHS eller SHS profil, der knekkurve ikke er definert for y og z aksen adskilt, men samlet - m� splittes i y og z
			if i = "buckling_curve_y_S235-420" or i = "buckling_curve_z_S235-420" then				# det er et textfelt for knekkurve
				if member("buckling_curve_S235-420", metadata) then		# det er RHS eller SHS profil
					data := sprintf("%s(%a,%a)", sectioncode, section, "buckling_curve_S235-420");		# henter tverrsnittsdata
					sectiondata[i] := eval(parse(data));
				else	
					sectiondata[i] := 0;
				end if;
			end if;
		
			if i = "buckling_curve_y_S460" or i = "buckling_curve_z_S460" then				# det er et textfelt for knekkurve
				if member("buckling_curve_S460", metadata) then		# det er RHS eller SHS profil
					data := sprintf("%s(%a,%a)", sectioncode, section, "buckling_curve_S460");		# henter tverrsnittsdata
					sectiondata[i] := eval(parse(data));
				else
					sectiondata[i] := 0
				end if;
			end if;
		end do;

		WhateverYouNeed["sectionproperties"] := sectionproperties;
		WhateverYouNeed["sectiondata"] := sectiondata;
	
		# return eval(sectiondata);
	end if;
end proc:


SectiondataRectangular := proc(profilename::string, WhateverYouNeed::table)
	description "Get section data, just rectangular sections for the moment";
	local b, h, A, W_y, W_z, I_y, I_z, I_t, i_y, i_z;
	local sectiontype, section, sectionproperties, sectiondata, b_, h_, i, j;

# 	warnings := WhateverYouNeed["warnings"];

	sectionproperties := ["h", "b", "A", "I_y", "I_z", "I_t", "W_y", "W_z", "i_y", "i_z"];

	sectiontype := substring(profilename, 1 .. searchtext(" / ", profilename)-1);
	section := substring(profilename, searchtext(" / ", profilename)+3 .. -1);	
	b_ := parse(substring(section, 1 .. searchtext("x", section)-1));
	h_ := parse(substring(section, searchtext("x", section)+1 .. -1));

	b := b_*Unit('mm');
	h := h_*Unit('mm');

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

	WhateverYouNeed["sectionproperties"] := sectionproperties;
	WhateverYouNeed["sectiondata"] := sectiondata;

	# return eval(sectiondata);
end proc:


SetComboBox := proc(WhateverYouNeed::table)
	uses DocumentTools;
	description "Set combobox according to chosen material or section";
	local ind, val, foundit, warnings;
	local steelcode, steelgrade, thicknessclass, sectiontype, section;

	# define local variables
	warnings := WhateverYouNeed["warnings"];
			
	if assigned(WhateverYouNeed["materialdata"]["steelcode"]) then	# data is materialdata
		steelcode := eval(WhateverYouNeed["materialdata"]["steelcode"]);
		steelgrade := eval(WhateverYouNeed["materialdata"]["steelgrade"]);
		thicknessclass := eval(WhateverYouNeed["materialdata"]["thicknessclass"]);

		# steelcode
		if ComponentExists("ComboBox_steelcode") then
			if steelcode <> GetProperty("ComboBox_steelcode", value) then
				foundit := false;
				if steelcode = "" then
					SetProperty("ComboBox_steelcode", 'selectedindex', 0);
					steelcode := GetProperty("ComboBox_steelcode", 'value')
				else
					for ind, val in GetProperty("ComboBox_steelcode", 'itemlist') do
						if val = steelcode then
							foundit := true;
							SetProperty("ComboBox_steelcode", 'selectedindex', ind-1);
						end if;
					end do;
					if not foundit then
						Alert(cat("Invalid steelcode ", steelcode), warnings, 5);
					end if;
				end if;
			SetProperty("ComboBox_steelgrade", 'itemlist', NODESteelMaterial:-steelgrades[steelcode]);
			end if;
		end if;

		# steelgrade
		if ComponentExists("ComboBox_steelgrade") then
			if steelgrade <> GetProperty("ComboBox_steelgrade", value) then
				foundit := false;
				for ind, val in GetProperty("ComboBox_steelgrade", itemlist) do
					if val = steelgrade then
						foundit := true;
						SetProperty("ComboBox_steelgrade", selectedindex, ind-1)
					end if;
				end do;
				if not foundit then
					Alert(cat("Invalid steelgrade ", steelgrade), warnings, 5);
				end if;
			end if;
		end if;

		# thicknessclass
		if ComponentExists("ComboBox_thicknessclass") then
			if thicknessclass <> GetProperty("ComboBox_thicknessclass", value) then
				foundit := false;
				for ind, val in GetProperty("ComboBox_thicknessclass", itemlist) do
					if val = thicknessclass then
						foundit := true;
						SetProperty("ComboBox_thicknessclass", selectedindex, ind-1)
					end if;
				end do;
				if not foundit then
					Alert(cat("Invalid thicknessclass ", thicknessclass), warnings, 5);
				end if;
			end if;
		end if;
	end if;

	if assigned(WhateverYouNeed["sectiondata"]["sectiontype"]) then	# data is sectiondata
		sectiontype := eval(WhateverYouNeed["sectiondata"]["sectiontype"]);
		section := eval(WhateverYouNeed["sectiondata"]["section"]);
		
		# sectiontype
		if ComponentExists("ComboBox_sectiontype") then
			if sectiontype <> GetProperty("ComboBox_sectiontype", value) then
				foundit := false;
				if sectiontype = "" then
					SetProperty("ComboBox_sectiontype", selectedindex, 0);
					sectiontype := GetProperty("ComboBox_sectiontype", value)
				else
					for ind, val in GetProperty("ComboBox_sectiontype", itemlist) do
						if val = sectiontype then
							foundit := true;
							SetProperty("ComboBox_sectiontype", selectedindex, ind-1);
						end if;
					end do;
					if not foundit then
						Alert(cat("Invalid sectiontype ", sectiontype), warnings, 5);
					end if;
				end if;
				SetComboBoxSection(sectiontype);
			end if;
		end if;

		# section
		if ComponentExists("ComboBox_section") then
			if section <> GetProperty("ComboBox_section", value) then
				foundit := false;
				for ind, val in GetProperty("ComboBox_section", itemlist) do
					if val = section then
						foundit := true;
						SetProperty("ComboBox_section", selectedindex, ind-1)
					end if;
				end do;
				if not foundit then
					Alert(cat("Invalid section ", section), warnings, 5);
				end if;
			end if;
		end if;
	end if;
	
end proc:


SetComboBoxSection := proc(sectiontype::string)
	uses DocumentTools;
	description "Set sections Combobox according to section types";
	local sectioncode, sections;

	sectioncode := cat("NODESteelProfiles_",sectiontype,":-Property");	# NODESteelProfiles_H:-Property
	sectioncode := StringTools:-RegSubs(" " = "_", sectioncode);		# endre "CF RHS" til "CF_RHS"

	sections := sprintf("%s(%a)", sectioncode, "allmembers");	# https://www.mapleprimes.com/questions/231067-Can-I-Have-An-Apostroph-In-Cat-
	sections := eval(parse(sections));

	SetProperty("ComboBox_section", itemlist, sections);
	SetProperty("ComboBox_section", selectedIndex, 0);
end proc: