# calculate_F_vR
# calculate_alpha_rope

# 8.2.2
# F_vR is calculated for each fastener and each loadcase with angle alpha, between force and grain direction, called by EC5_812
calculate_F_vR := proc(WhateverYouNeed::table, alpha::table)
	description "Calculate Fv,R according to 8.2.2";

	local f_hk, t_eff, t_steel, d, F_axRk, M_yRk, shearplanes, F_vRk, F_vRd, beta, dummy, F_vRkmin, alpha_rope, gamma_M, k_mod, structure,
	materialdataAll, sectiondataAll, comments, fastenervalues, warnings, connectionInsideLayers, i, F_vRkfin, f, b1outside, connection;

	# local variables
	warnings := WhateverYouNeed["warnings"];
	gamma_M := 1.3; 		# NS-EN 1995, NA.2.4.1
	structure := WhateverYouNeed["calculations"]["structure"];
	materialdataAll := WhateverYouNeed["materialdataAll"];
	sectiondataAll := WhateverYouNeed["sectiondataAll"];
	comments := WhateverYouNeed["results"]["comments"];
	connection := structure["connection"];
	
	fastenervalues := WhateverYouNeed["calculatedvalues"]["fastenervalues"];	
	M_yRk := fastenervalues["M_yRk"];	
	shearplanes := fastenervalues["shearplanes"];
	F_axRk := fastenervalues["F_axRk"];
	
	t_steel := sectiondataAll["steel"]["b"];

	d := structure["fastener"]["fastener_d"];
	b1outside := connection["b1outside"];
	connectionInsideLayers := connection["connectionInsideLayers"];
		
	alpha_rope := calculate_alpha_rope(WhateverYouNeed);

	f_hk := table();
	F_vRkmin := table();		# stores groups of combinable shear failure modes

	# modify t_eff if connectionHalfOutsideLayers	
	t_eff := table();	
	t_eff["1"] := fastenervalues["t_eff"]["1"];		# t_eff 1 inside
	t_eff["2"] := fastenervalues["t_eff"]["2"];		

	if connection["connection1"] = "Timber" and connection["connection2"] = "Timber" then
		# 8.2.2
		f_hk["1"] := calculate_f_hk(WhateverYouNeed, "1", alpha["1"]);
		f_hk["2"] := calculate_f_hk(WhateverYouNeed, "2", alpha["2"]);
		beta := f_hk["2"] / f_hk["1"];			# this will change for each fastener if alpha is different
			
		if connectionInsideLayers = 0 then	# connections with single shearplane
		
			F_vRk["a"] := evalf(f_hk["1"] * t_eff["1"] * d);
		
			F_vRk["b"] := evalf(f_hk["2"] * t_eff["2"] * d);

			dummy := f_hk["1"] * t_eff["1"] * d / (1 + beta) * (sqrt(beta + 2 * beta^2 * (1 + t_eff["2"] / t_eff["1"] + (t_eff["2"] / t_eff["1"])^2) + beta^3 * (t_eff["2"] / t_eff["1"])^2) - beta * (1 + t_eff["2"] / t_eff["1"]));
			F_vRk["c"] := eval(dummy + min(dummy * alpha_rope, F_axRk / 4));

			dummy := 1.05 * f_hk["1"] * t_eff["1"] * d / (2 + beta) * (sqrt(2 * beta * (1 + beta) + 4 * beta * (2 + beta) * M_yRk / (f_hk["1"] * d * t_eff["1"]^2)) - beta);
			F_vRk["d"] := eval(dummy + min(dummy * alpha_rope, F_axRk / 4));

			dummy := 1.05 * f_hk["1"] * t_eff["2"] * d / (1 + 2 * beta) * (sqrt(2 * beta^2 * (1 + beta) + 4 * beta * (1 + 2 * beta) * M_yRk / (f_hk["1"] * d * t_eff["2"]^2)) - beta);
			F_vRk["e"] := eval(dummy + min(dummy * alpha_rope, F_axRk / 4));

			dummy := 1.15 * sqrt(2 * beta / (1 + beta)) * sqrt(2 * M_yRk * f_hk["1"] * d);
			F_vRk["f"] := eval(dummy + min(dummy * alpha_rope, F_axRk / 4));

			# 8.1.3(2)
			# To be able to combine the resistance from individual shear planes in a multiple shear plane connection, the governing failure mode of the fasteners in the respective shear planes should
			# be compatible with each other and should not consist of a combination of failure modes (a), (b), (g) and (h) from Figure 8.2

			F_vRkmin["1ta"] := min(F_vRk["a"], F_vRk["b"]);						# fig. 8.2, 1 shearplane, timber - timber, steel straight
			F_vRkmin["1tb"] := min(F_vRk["c"], F_vRk["d"], F_vRk["e"], F_vRk["f"]);	# fig. 8.2, 1 shearplane, timber - timber, steel bent
			if F_vRkmin["1ta"] < F_vRkmin["1tb"] then
				comments["F_vRkmin"] := "Fv,Rk acc. to 8.2.2 (a-b)"
			else
				comments["F_vRkmin"] := "Fv,Rk acc. to 8.2.2 (c-f)"
			end if;
		
		else # more than 1 shearplane

			F_vRk["g"] := evalf(f_hk["1"] * t_eff["1"] * d);

			F_vRk["h"] := evalf(0.5 * f_hk["2"] * t_eff["2"] * d);

			dummy := 1.05 * f_hk["1"] * t_eff["1"] * d / (2 + beta) * (sqrt(2 * beta * (1 + beta) + 4 * beta * (2 + beta) * M_yRk / (f_hk["1"] * d * t_eff["1"]^2)) - beta);
			F_vRk["j"] := evalf(dummy + min(dummy * alpha_rope, F_axRk / 4));

			dummy := 1.15 * sqrt(2 * beta / (1 + beta)) * sqrt(2 * M_yRk * f_hk["1"] * d);
			F_vRk["k"] := evalf(dummy + min(dummy * alpha_rope, F_axRk / 4));

			F_vRkmin["2ta"] := shearplanes * min(F_vRk["g"], F_vRk["h"]);	# fig. 8.2, 2 shearplane, timber - timber, steel straight
			F_vRkmin["2tb"] := shearplanes * min(F_vRk["j"], F_vRk["k"]);	# fig. 8.2, 2 shearplane, timber - timber, steel bent

			if F_vRkmin["2ta"] < F_vRkmin["2tb"] then
				comments["F_vRkmin"] := "Fv,Rk acc. to 8.2.2 (g-h)"
			else
				comments["F_vRkmin"] := "Fv,Rk acc. to 8.2.2 (j-k)"
			end if;			
			
		end if;

		F_vRkfin := min(entries(F_vRkmin));
		comments["F_vRk_steel"] := evaln(comments["F_vRk_steel"]);
		
	else	# (8.2.3) steel either on inside our outside

		f_hk["1"] := calculate_f_hk(WhateverYouNeed, "1", alpha["1"]);		# only used if timber is outside

		t_eff["1o"] := fastenervalues["t_eff"]["1"];

		if b1outside <> "false" and b1outside < t_eff["1o"] then			# only possible with timber outside / steel inside	
			t_eff["1o"] := b1outside
		end if;	

		# F_vRk
		
		if connection["connection1"] = "Timber" then						# division by zero if run with steel plate outside

			# 1 shearplane, timber outside, steel inside
			
			F_vRk["a"] := evalf(0.4 * f_hk["1"] * t_eff["1o"] * d);

			dummy := 1.15 * sqrt(2 * M_yRk * f_hk["1"] * d);
			F_vRk["b"] := evalf(dummy + min(dummy * alpha_rope, F_axRk / 4));

			F_vRk["c"] := evalf(f_hk["1"] * t_eff["1o"] * d);

			dummy := f_hk["1"] * t_eff["1o"] * d * (sqrt(2 + 4 * M_yRk / (f_hk["1"] * d * t_eff["1o"]^2)) - 1);
			F_vRk["d"] := evalf(dummy + min(dummy * alpha_rope, F_axRk / 4));

			dummy := 2.3 * sqrt(M_yRk * f_hk["1"] * d);
			F_vRk["e"] := evalf(dummy + min(dummy * alpha_rope, F_axRk / 4));

			# 2 shearplanes, timber outside, steel inside

			F_vRk["f"] := evalf(f_hk["1"] * t_eff["1"] * d);

			dummy := evalf(f_hk["1"] * t_eff["1"] * d * (sqrt(2 + 4 * M_yRk / (f_hk["1"] * d * t_eff["1"]^2)) - 1));
			F_vRk["g"] := eval(dummy + min(dummy * alpha_rope, F_axRk / 4));

			dummy := evalf(2.3 * sqrt(M_yRk * f_hk["1"] * d));
			F_vRk["h"] := eval(dummy + min(dummy * alpha_rope, F_axRk / 4));

		end if;

		# 2 shearplanes, steel outside, timber inside
		
		# if connection with >=3 inside layers, t_eff["2"] = 0 (steel inside in connection)
		# need to calculate j - m with t_eff["1"], calculating capacity of part of the connection

		if t_eff["2"] = 0 and connectionInsideLayers >= 3 then
			
			F_vRk["j"] := evalf(0.5 * f_hk["1"] * t_eff["1"] * d);

			dummy := 1.15 * sqrt(2 * M_yRk * f_hk["1"] * d);
			F_vRk["k"] := evalf(dummy + min(dummy * alpha_rope, F_axRk / 4));

			F_vRk["l"] := evalf(0.5 * f_hk["1"] * t_eff["1"] * d);

			dummy := 2.3 * sqrt(M_yRk * f_hk["1"] * d);
			F_vRk["m"] := evalf(dummy + min(dummy * alpha_rope, F_axRk / 4));
			
		else	# real situation with steel outside, timber inside
			
			f_hk["2"] := calculate_f_hk(WhateverYouNeed, "2", alpha["2"]);
			
			F_vRk["j"] := evalf(0.5 * f_hk["2"] * t_eff["2"] * d);

			dummy := 1.15 * sqrt(2 * M_yRk * f_hk["2"] * d);
			F_vRk["k"] := evalf(dummy + min(dummy * alpha_rope, F_axRk / 4));

			F_vRk["l"] := evalf(0.5 * f_hk["2"] * t_eff["2"] * d);

			dummy := 2.3 * sqrt(M_yRk * f_hk["2"] * d);
			F_vRk["m"] := evalf(dummy + min(dummy * alpha_rope, F_axRk / 4));
			
		end if;

		# F_vRkmin, grouping of F_vRk values according to steel plate thickness
		
		# precalculating capacity dependent on steel plate thickness, interpolating values
		if t_steel < d then			# thin or medium thick steel plate
			
			if assigned(F_vRk["a"]) and assigned(F_vRk["b"]) then
				F_vRkmin["1sb"] := min(F_vRk["a"], F_vRk["b"]);		# fig. 8.3, 1 shearplane, thin, bent steel
			else
				F_vRkmin["1sb"] := 0
			end if;

			if assigned(F_vRk["j"]) and assigned(F_vRk["k"]) then
				F_vRkmin["2sa"] := F_vRk["j"];						# fig. 8.3, 2 shearplanes, thin, straight steel
				F_vRkmin["2sb"] := F_vRk["k"];						# fig. 8.3, 2 shearplanes, thin, bent steel
			else
				F_vRkmin["2sa"] := 0;
				F_vRkmin["2sb"] := 0;
			end if;
			comments["F_vRk_steel"] := "thin plate";
			
		end if;

		if t_steel > 0.5 * d then	# medium or thick steel plate

			if assigned(F_vRk["c"]) and assigned(F_vRk["d"]) and assigned(F_vRk["e"]) then
				F_vRkmin["1Sa"] := F_vRk["c"];					# fig. 8.3, 1 shearplane, thick, straight steel
				F_vRkmin["1Sb"] := min(F_vRk["d"], F_vRk["e"]);		# fig. 8.3, 1 shearplane, thick, bent steel
				F_vRkmin["2Sa"] := F_vRk["l"];					# fig. 8.3, 2 shearplanes, thick, straight steel
			else
				F_vRkmin["1Sa"] := 0;
				F_vRkmin["1Sb"] := 0;
				F_vRkmin["2Sa"] := 0;
			end if;

			if assigned(F_vRk["m"]) then
				F_vRkmin["2Sb"] := F_vRk["m"];					# fig. 8.3, 2 shearplanes, thick, bent steel
			else
				F_vRkmin["2Sb"] := 0
			end if;
			comments["F_vRk_steel"] := "thick plate";
		end if;
			
		if t_steel > 0.5 * d and t_steel < d then  # medium thick plate			

			f := (t_steel - 0.5 * d) / (0.5 * d);		# interpolation factor, 0 < f < 1
			
			# min of straight steel
			F_vRkmin["1a"] := F_vRkmin["1Sa"];					# fig. 8.3, 1 shearplane, medium
			F_vRkmin["2a"] := evalf(F_vRkmin["2sa"] + f * (F_vRkmin["2Sa"] - F_vRkmin["2sa"]));	# 2 shearplanes, medium

			# min of bent steel
			F_vRkmin["1b"] := evalf(F_vRkmin["1sb"] + f * (F_vRkmin["1Sb"] - F_vRkmin["1sb"]));
			F_vRkmin["2b"] := evalf(F_vRkmin["2sb"] + f * (F_vRkmin["2Sb"] - F_vRkmin["2sb"]));

			# delete unneccessary values
			for i in {"1sb", "2sa", "2sb", "1Sa", "1Sb", "2Sa", "2Sb"} do
				if assigned(F_vRkmin[i]) then
					F_vRkmin[i] := evaln(F_vRkmin[i])
				end if
			end do;
			
			comments["F_vRk_steel"] := cat("medium plate (f=", round2(f, 2),")");
					
		end if;

		# F_vRkfin, final capacity value

		F_vRkfin := 0;
		
		if connection["connection1"] = "Timber" and connection["connection2"] = "Steel" then
		
			if connectionInsideLayers = 0 then		# just indices starting with "1"

				# alternative: https://www.mapleprimes.com/questions/238203-Table-Entries-With-Indices-That-Have#answer301560
				for i in indices(F_vRkmin, 'nolist') do 
					if substring(i, 1..1) = "1" then
						if F_vRkfin = 0 or F_vRkmin[i] < F_vRkfin then
							F_vRkfin := F_vRkmin[i];
							comments["F_vRkmin"] := cat("Fv,Rk acc. to 8.2.3 (a-e), internal index ", i)
						end if;
					end if;
				end do;
				
			elif connectionInsideLayers = 1 then

				for i in indices(F_vRkmin, 'nolist') do 
					if substring(i, 1..1) = "2" then
						if F_vRkfin = 0 or F_vRkmin[i] < F_vRkfin then
							F_vRkfin := F_vRkmin[i];
							comments["F_vRkmin"] := cat("Fv,Rk acc. to 8.2.3 (f-h), internal index ", i)
						end if;
					end if;
				end do;
			
				F_vRkfin  := F_vRkfin * shearplanes;

			else # connectionInsideLayers >= 3 then
				
				# ... or modes (c), (f) and (j/l) from Figure 8.3 with the other failure modes.
				# only "a" and "b" can be combined with each other.
				local F_vRkmin_;
				F_vRkmin_ := table();

				# store values in new variable
				for i in indices(F_vRkmin, 'nolist') do 
					if searchtext("1", i) > 0 and searchtext("a", i) > 0 then
						F_vRkmin_["1a"]:= F_vRkmin[i]
					elif searchtext("1", i) > 0 and searchtext("b", i) > 0 then
						F_vRkmin_["1b"]:= F_vRkmin[i]
					elif searchtext("2", i) > 0 and searchtext("a", i) > 0 then
						F_vRkmin_["2a"]:= F_vRkmin[i]
					elif searchtext("2", i) > 0 and searchtext("b", i) > 0 then
						F_vRkmin_["2b"]:= F_vRkmin[i]
					else
						Alert(cat("Undefined index in F_vRkmin: ", i), warnings, 2)
					end if;
				end do;

				# check if straight of bent steel has lowest capacity
				F_vRkfin := F_vRkmin_["1a"] * 2 + (shearplanes - 2) * F_vRkmin_["2a"];
				dummy := F_vRkmin_["1b"] * 2 + (shearplanes - 2) * F_vRkmin_["2b"];

				if F_vRkfin < dummy then
					comments["F_vRkmin"] := "Fv,Rk acc. to 8.2.3, straight steel"
				else
					F_vRkfin := dummy;
					comments["F_vRkmin"] := "Fv,Rk acc. to 8.2.3, bent steel"
				end if;		
									
			end if;
			
		elif connection["connection1"] = "Steel" and connection["connection2"] = "Timber" then

			if connectionInsideLayers = 0 then
				
				Alert("Steel - Timber with one shearplane not allowed", warnings, 3)

			elif connectionInsideLayers = 1 then		# 2 shearplanes

				for i in indices(F_vRkmin, 'nolist') do 
					if substring(i, 1..1) = "2" then
						if F_vRkfin = 0 or F_vRkmin[i] < F_vRkfin then
							F_vRkfin := F_vRkmin[i];
							comments["F_vRkmin"] := cat("Fv,Rk acc. to 8.2.3 (j-m), internal index ", i)
						end if;
					end if;
				end do;
			
				F_vRkfin  := F_vRkfin * shearplanes;
				
			elif connectionInsideLayers > 1 then
				
				Alert("Steel - Timber with more than one shearplane not allowed", warnings, 3)
				
			end if;

		else
			
			Alert("Error in calculate_F_vR", warnings, 1);
			
		end if;
	
	end if;			# Timber / Timber , Timber / Steel

	convert~(F_vRk, 'units', 'kN');
	
	# calculate k_mod, using the lowest value of the timber beams
	k_mod := 0;
	
	if connection["connection1"] = "Timber" then		
		k_mod := materialdataAll["1"]["k_mod"]
	end if;

	if connection["connection2"] = "Timber" then
		if k_mod = 0 or k_mod > materialdataAll["2"]["k_mod"] then			
			k_mod := materialdataAll["2"]["k_mod"]		
		end if;
	end if;

	# F_vRd is for one fastener, all shearplanes
	F_vRd := eval(F_vRkfin * k_mod / gamma_M);
	
	if ComponentExists("TextArea_gamma_M") then
		SetProperty("TextArea_gamma_M", value, round2(gamma_M, 2))
	end if;
	
	fastenervalues["alpha_rope"] := alpha_rope;
	fastenervalues["F_vRk"] := F_vRkfin;
	fastenervalues["F_vRd"] := F_vRd;

	return F_vRk, F_vRd;
	
end proc:


calculate_alpha_rope := proc(WhateverYouNeed::table)
	description "calculate alpha rope effect";
	local chosenFastener, alpha_rope;

	chosenFastener := WhateverYouNeed["calculations"]["structure"]["fastener"]["chosenFastener"];
	
	if chosenFastener = "Screw" then
		alpha_rope := 1
	elif chosenFastener = "Bolt" then
		alpha_rope := 0.25
	elif chosenFastener = "Dowel" then
		alpha_rope := 0
	elif chosenFastener = "Nail" then
		alpha_rope := 0.25		# for nails with rectangular section
	else
		alpha_rope := 0
	end if;

	return alpha_rope
end proc: