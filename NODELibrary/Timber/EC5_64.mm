# EC5_64.mm : Eurocode 5 chapter 6.4
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


# EC5_643

# 6.4.2 check is already implemented in 6.1.6 (bending check)
EC5_643 := proc(WhateverYouNeed::table)
	description "Beregner utnyttelser i henhold til 6.4.3";
	local timbertype, V_yd, V_zd, M_yd, A, W_y;
	local tau_d_64, sigma_t90d_64, kcr, eta_643, usedcode, comments, f_t90d, f_vd, k_dis, k_p, k_vol, loadcase;

	# get local names for input and other values
	timbertype := WhateverYouNeed["materialdata"]["timbertype"];
	f_t90d := WhateverYouNeed["materialdata"]["f_t90d"];
	f_vd := WhateverYouNeed["materialdata"]["f_vd"];

	loadcase := WhateverYouNeed["calculations"]["activesettings"]["activeloadcase"];
	V_yd := WhateverYouNeed["calculations"]["loadcases"][loadcase]["V_yd"];
	V_zd := WhateverYouNeed["calculations"]["loadcases"][loadcase]["V_zd"];
	M_yd := WhateverYouNeed["calculations"]["loadcases"][loadcase]["M_yd"];

	k_dis := WhateverYouNeed["results"]["k_64"]["k_dis"];
	k_p := WhateverYouNeed["results"]["k_64"]["k_p"];
	k_vol := WhateverYouNeed["results"]["k_64"]["k_vol"];

	A := WhateverYouNeed["sectiondata"]["A"];
	W_y := WhateverYouNeed["sectiondata"]["W_y"];

	# start calculation
	sigma_t90d_64 := convert(k_p * M_yd / W_y, 'units', 'MPa');				# (6.54), conservative, could be reduced by using (6.55)

	# check shear
	# (6.13)
	if timbertype = "Solid timber" then
		kcr := 0.67		# for solid timber
	elif timbertype = "Glued laminated timber" then
		kcr := 0.8		# for glued laminated timber (NA.6.13a)
	else
		kcr := 1
	end if;
	
	# EC5_617();						# check shear
	tau_d_64 := convert(max(evalf(1.5 * V_yd / (kcr * A)), evalf(1.5 * V_zd / (kcr * A))), 'units', 'MPa');	

	eta_643 := evalf(tau_d_64 / f_vd + sigma_t90d_64 / (k_dis * k_vol * f_t90d));	# (6.53)
	
	if sigma_t90d_64 > 0 then
		usedcode := "6.4.3";
		comments := "Double tapered, curved and pitched cambered beams";
	else
		usedcode := "6.1.7";
		comments := "Shear";
	end if;


	# if ComponentExists("TextArea_eta_643") then
	#	HighlightResults({"eta_643"}, "highlight");
	#	SetProperty("TextArea_eta_643", 'value', round2(eta_643, 2));
	# end if;

	if ComponentExists("MathContainer_tau_d_64") then
		HighlightResults({"tau_d_64"}, "highlight");
		SetProperty("MathContainer_tau_d_64", 'value', round2(tau_d_64, 2));
	end if;

	if ComponentExists("MathContainer_sigma_t90d_64") then
		HighlightResults({"sigma_t90d_64"}, "highlight");
		SetProperty("MathContainer_sigma_t90d_64", 'value', round2(sigma_t90d_64, 2));
	end if;

	return eta_643, usedcode, comments
end proc: