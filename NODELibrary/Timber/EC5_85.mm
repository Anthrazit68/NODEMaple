# EC5_85.mm : Eurocode 5 chapter 8.5
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


# Kapittel 8.5 Bolteforbindelser

# calculate_f_hk
# calculate_f_hak

# characteristic embedment strength values 8.5.1.1(2)
# DEPRECATED
# calculate_f_hk := proc(WhateverYouNeed::table)
#	description "Characteristic embedment strength values";
#	local f_h0k, f_hk, part, dummy, structure, fastenervalues;

#	structure := WhateverYouNeed["calculations"]["structure"];
#	fastenervalues := WhateverYouNeed["calculatedvalues"]["fastenervalues"];

#	f_h0k := table();
#	f_hk := table();
	
#	for part in {"1", "2"} do

#		if structure["connection"][cat("connection", part)] = "Timber" then
#			f_h0k[part] := calculate_f_h0k(part, WhateverYouNeed);			# 8.3.1.1(5)
#			f_hk[part] := calculate_f_hak(WhateverYouNeed, part, f_h0k[part])			# 8.5.1.1(2)
#		else
#			f_h0k[part] := 0;
#			f_hk[part] := 0;
#		end if;
		
#		dummy := cat("MathContainer_f_h0k", part);
#		if ComponentExists(dummy) then
#			SetProperty(dummy, 'value', round2(f_h0k[part], 1))
#		end if;

#		dummy := cat("MathContainer_f_hk", part);
#		if ComponentExists(dummy) then
#			SetProperty(dummy, 'value', round2(f_hk[part], 1))
#		end if;
	
#	end do;
	
#	fastenervalues["f_h0k"] := eval(f_h0k);
#	fastenervalues["f_hk"] := eval(f_hk);
# end proc:

# calculate_f_h0k - see 8.3.1.1(5)


# 8.5.1.1(2)
# calculates f_h0k and f_hak values
calculate_f_hk := proc(WhateverYouNeed::table, part::string, alpha)
	local fastenervalues, f_hk, k90, calculatedFastener, d, f_h0k, f_h0k_table, f_hk_table, dummy;

	fastenervalues := WhateverYouNeed["calculatedvalues"]["fastenervalues"];
	calculatedFastener := WhateverYouNeed["calculatedvalues"]["fastenervalues"]["calculatedFastener"];
	f_h0k := WhateverYouNeed["calculatedvalues"]["f_h0k"][part];

	if assigned(fastenervalues["f_hk"]) = false then
		f_hk_table := table();
		fastenervalues["f_hk"] := eval(f_hk_table);
	end if;
	
	if calculatedFastener = "Nail" then
		
		dummy := cat("MathContainer_f_hk", part);
		if ComponentExists(dummy) then
			SetProperty(dummy, 'value', round2(f_h0k, 1))
		end if;

		f_hk := f_h0k;
	else

		# 8.5.1.1 (8.33)
		d := WhateverYouNeed["calculations"]["structure"]["fastener"]["fastener_d"];
		k90 := 1.35 + 0.015 * convert(d, 'unit_free');		# for softwoods
		# k90 := 1.30 + 0.015 * convert(d, 'unit_free');		# for LVL
		# k90 := 0.9 + 0.015 * convert(d, 'unit_free');		# for hardwoods
		
		f_hk := evalf(f_h0k / (k90 * sin(alpha)^2 + cos(alpha)^2));
			
	end if;

	fastenervalues["f_hk"][part] := f_hk;
	return f_hk;

end proc:


# DEPRECATED
# 8.5.1.1(2)
# calculate_f_hak_minmax := proc(WhateverYouNeed::table, part::string, f_h0k)
#	local f_hak, k90, calculatedFastener, d, structure, alphaMinMax, alphaBeam, alpha_h, dummy;

#	structure := WhateverYouNeed["calculations"]["structure"];
#	calculatedFastener := WhateverYouNeed["calculatedvalues"]["fastenervalues"]["calculatedFastener"];
#	alphaMinMax := WhateverYouNeed["results"]["FastenerGroup"]["alphaMinMax"]; 	# max and min angle of forces in fastener points (global directions)
#	alphaBeam := evalf(WhateverYouNeed["calculations"]["structure"]["connection"][cat("graindirection", part)]);

#	alpha_h := table();
#	f_hak := table();

#	# 8.5.1.1 (8.33)
#	d := structure["fastener"]["fastener_d"];
#	k90 := 1.35 + 0.015 * convert(d, 'unit_free');		# for softwoods
	# k90 := 1.30 + 0.015 * convert(d, 'unit_free');		# for LVL
	# k90 := 0.9 + 0.015 * convert(d, 'unit_free');		# for hardwoods

#	if calculatedFastener = "Nail" then
#		return f_h0k;		
		
#	else
#		for dummy in {"min", "max"} do

#			alpha_h[dummy] := alphaMinMax[dummy] - alphaBeam;
#			f_hak[dummy] := evalf(f_h0k / (k90 * (sin(alpha_h[dummy]))^2 + (cos(alpha_h[dummy]))^2));
			
#		end do;	
#	end if;

#	if f_hak["min"] <= f_hak["max"] then
#		if ComponentExists(cat("MathContainer_alpha_h", part)) then
#			SetProperty(cat("MathContainer_alpha_h", part), 'value', round(alpha_h["min"]));
#		end if;
#		return f_hak["min"]
#	else
#		if ComponentExists(cat("MathContainer_alpha_h", part)) then
#			SetProperty(cat("MathContainer_alpha_h", part), 'value', round(alpha_h["max"]));
#		end if;
#		return f_hak["max"]
#	end if;
# end proc: