# calculate_83
# calculate_t
# calculate_F_axR
# checkPredrilled
# calculate_f_h0k
# calculate_n_ef
# calculate_k_ef
# calculate_f_axk
# calculate_f_headk
# calculate_R_axk_n_head

# Kapittel 8.3 Spikerforbindelser

# 8.3.1.1(1)
calculate_t := proc(WhateverYouNeed::table)
	description "Calculate t and t_pen / effective part thickness and penetration depth";
	local shearplanes, t_total, t, t_eff, t_ef_814_NA_DE, t_pen, n_tip, n_head, ls, d, chosenFastener, connection, alphaScrew;
	local checkPassed, structure, sectiondataAll, warnings, comments, fastenervalues, timberlayers, i, nailSurface;

	# define local variables
	structure := WhateverYouNeed["calculations"]["structure"];
	sectiondataAll := WhateverYouNeed["sectiondataAll"];
	warnings := WhateverYouNeed["warnings"];
	comments := WhateverYouNeed["results"]["comments"];
	fastenervalues := WhateverYouNeed["calculatedvalues"]["fastenervalues"];

	# structure / fastener
	chosenFastener := structure["fastener"]["chosenFastener"];
	ls := structure["fastener"]["fastener_ls"];					# length of fastener
	alphaScrew := structure["fastener"]["alphaScrew"];	# inclination of fastener
	d := structure["fastener"]["fastener_d"];					# diameter
	nailSurface := structure["fastener"]["nailSurface"];
	
	# structure / connection
	connection := structure["connection"];
	shearplanes := fastenervalues["shearplanes"];		# number of shearplanes due to geometry (theoretical, independent of fasteners)
	t_total := WhateverYouNeed["calculatedvalues"]["t_total"];		# total thickness of connection
	timberlayers := WhateverYouNeed["calculatedvalues"]["layers"];
	
	# materialdata
	t := table();

	if assigned(sectiondataAll["1"]["b"]) then
		t["1"] := sectiondataAll["1"]["b"];
	else
		t["1"] := 0
	end if;

	if assigned(sectiondataAll["2"]["b"]) then
		t["2"] := sectiondataAll["2"]["b"];
	else
		t["2"] := 0
	end if;

	if assigned(sectiondataAll["steel"]["b"]) then
		t["steel"] := sectiondataAll["steel"]["b"];
	else
		t["steel"] := 0
	end if;

	t_eff := table();
	t_ef_814_NA_DE := table();
	
	# reset specific settings for overlap and doublesided
	fastenervalues["overlap"] := evaln(fastenervalues["overlap"]);
	fastenervalues["doublesided"] := evaln(fastenervalues["doublesided"]);
	fastenervalues["SingleShearplane"] := evaln(fastenervalues["SingleShearplane"]);

	comments["overlap"] := evaln(comments["overlap"]);
	comments["doublesided"] := evaln(comments["doublesided"]);
	comments["SingleShearplane"] := evaln(comments["SingleShearplane"]);
	
	# t_eff["1"], t_eff["2"]
	if chosenFastener = "Bolt" or chosenFastener = "Dowel" then

		if ls < t_total then		# needs to go through the whole section
			Alert("Fastener too short", warnings, 5);
			return
		else
			ls := t_total			# probably need to limit length to section depth
		end if;

		if connection["connection1"] = "Timber" and connection["connection2"] = "Timber" then	# figure 8.2
			t_eff["1"] := t["1"];
			t_eff["2"] := t["2"]
			
		elif connection["connection1"] = "Timber" and connection["connection2"] = "Steel" then	# figure 8.3 a - h
			t_eff["1"] := t["1"];
			t_eff["2"] := 0
			
		elif connection["connection1"] = "Steel" and connection["connection2"] = "Timber" then	# figure 8.3 j - m
			if chosenFastener = "Bolt" then
				t_eff["1"] := 0;
				t_eff["2"] := t["2"]
			elif chosenFastener = "Dowel" then
				Alert("Outside steelplates cannot be used together with dowels", warnings, 5);
				return
			end if
			
		end if;

		# t_ef for 8.1.4 NA DE, limtreboka p. 251
		# tpen not possible to use as bolts and dowels need to go through all parts
		
		for i in {"1", "2"} do
			
			if timberlayers[i] > 0 then
				
				if shearplanes = 1 then	# single sided connection
					t_ef_814_NA_DE[i] := min(t[i] * timberlayers[i], 6 * d)
				else
					t_ef_814_NA_DE[i] := min(t[i] * timberlayers[i], 12 * d)
				end if;
				
			end if;
			
		end do;

		n_tip := 0; 		# part number for which t_pen is defined
		n_head := 0;
		t_pen := 0;
	
	elif chosenFastener = "Nail" or chosenFastener = "Screw" then

		# extending formula for inclined screws
		if alphaScrew <> 90  * Unit('degree') then
			comments["alphaScrew"] := cat("screw inclined ", convert(alphaScrew, 'unit_free'), " degrees")
		elif assigned(comments["alphaScrew"]) then 
			comments["alphaScrew"] := evaln(comments["alphaScrew"])
		end if;

		if evalf(ls * sin(alphaScrew)) > t_total then		# nail sticks out of section
			Alert("Nail / screw too long", warnings, 5);
			return
		end if;

		if shearplanes = 1 then			# just 2 parts
			
			# for timber - timber connections with one shearplane, fastener tip is always considered to be in part 2
			if connection["connection1"] = "Timber" and connection["connection2"] = "Timber" then		# figure 8.2 a - f

				t_eff["1"] := min(t["1"], ls * sin(alphaScrew));						
				t_eff["2"] := evalf(min(t["2"], ls * sin(alphaScrew) - t["1"]));				# figure 8.4(a)
				t_pen := t_eff["2"];
				n_tip := "2";				# number of part with the tip
				n_head := "1";

				if (chosenFastener = "Nail" and nailSurface = "smooth" and t_pen < 8 * d) or t_pen < 6 * d then		# 8.3.1.2				
					Alert(cat("calculate_t: ", chosenFastener, " too short"), warnings, 5);
					return
				else
					fastenervalues["doublesided"] := false;
				end if;

			# for timber - steel connections with one shearplane, fastener tip is always considered to go into part 1 (different from above)
			elif connection["connection1"] = "Timber" and connection["connection2"] = "Steel" then		# Figur 8.3 a - e

				t_eff["1"] := evalf(min(t["1"], ls * sin(alphaScrew) - t["steel"]));	
				t_eff["2"] := 0;
				t_pen := t_eff["1"];
				n_tip := "1";
				n_head := 0;

				if (chosenFastener = "Nail" and nailSurface = "smooth" and t_pen < 8 * d) or t_pen < 6 * d then		# 8.3.1.2				
					Alert(cat("calculate_t: ", chosenFastener, " too short"), warnings, 5);
					return
				else
					fastenervalues["doublesided"] := false;
				end if;

			else

				Alert("calculate_t: undefined material combination with 1 shearplane", warnings, 5);
				return

			end if;
						
		elif shearplanes = 2 then		# 3 parts, 2 outer, 1 inner
	
			# check if connection should be doublesided
			if connection["connection1"] = "Timber" and connection["connection2"] = "Timber" then	# figure 8.2 g - k

				# check if nail is in part 1, 2 or 3

				if ls * sin(alphaScrew) <= t["1"] then		# fastener in part 1, too short

					Alert(cat("calculate_t: ", chosenFastener, " tip in part 1, too short"), warnings, 5);
					return

				elif ls * sin(alphaScrew) > t["1"] and ls * sin(alphaScrew) <= t["1"] + t["2"] then	# fastener in part 2
					
					t_eff["1"] := t["1"];
					t_eff["2"] := evalf(ls * sin(alphaScrew) - t["1"]);
					t_pen := t_eff["2"] / sin(alphaScrew);
					n_tip := "2";
					n_head := "1";

					if t["2"] - t_pen < 4 * d then	# 8.3.1.1(7)
						Alert("8.3.1.1(7): Warning: t-t2 < 4d, overlap not allowed", warnings, 3);
						fastenervalues["overlap"] := false;
					else
						fastenervalues["overlap"] := true;
					end if;

					if (chosenFastener = "Nail" and nailSurface = "smooth" and t_pen < 8 * d) or t_pen < 6 * d then		# 8.3.1.2				
						Alert(cat("calculate_t: ", chosenFastener, " tip in part 2, anchorage length too short"), warnings, 5);
						return
					else
						fastenervalues["doublesided"] := true;
						fastenervalues["SingleShearplane"] := true;
						comments["SingleShearplane"] := cat(chosenFastener, " tip in part 2 -> doublesided, single shearplane");
					end if;					

				else	# fastener in part 3

					t_eff["1"] := evalf(min(t["1"], ls * sin(alphaScrew) - t["2"] - t["1"]));	# 8.4(b)
					t_eff["2"] := t["2"];
					t_pen := t_eff["1"] / sin(alphaScrew);
					n_tip := "1";
					n_head := "1";

					# might be too short for proper 2 shearplane connection
					if (chosenFastener = "Nail" and nailSurface = "smooth" and t_pen < 8 * d) or t_pen < 6 * d then		# 8.3.1.2

						fastenervalues["doublesided"] := true;
						fastenervalues["SingleShearplane"] := true;
						fastenervalues["overlap"] := false;						
						comments["SingleShearplane"] := cat(chosenFastener, " anchorage length too short in part 3, single shearplane");
						t_eff["1"] := t["1"];
						t_eff["2"] := t["2"];
						t_pen := t["2"];
						n_tip := "2";
						n_head := "1";						

					else

						fastenervalues["doublesided"] := false;
						fastenervalues["SingleShearplane"] := false;
						fastenervalues["overlap"] := false;

					end if;

				end if;

			elif connection["connection1"] = "Steel" then	# steel - timber - steel / nail screw must always be doublesided

				t_eff["1"] := 0;
				t_eff["2"] := evalf(min(t["2"], ls * sin(alphaScrew) - t["steel"]));					
				t_pen := t_eff["2"] / sin(alphaScrew);
				n_tip := "2";
				n_head := 0;
				fastenervalues["doublesided"] := true;
				fastenervalues["SingleShearplane"] := true;

				if t["2"] - t_pen < 4 * d then	# 8.3.1.1(7)
					Alert("8.3.1.1(7): Warning: t-t2 < 4d, overlap not allowed", warnings, 3);
					fastenervalues["overlap"] := false;
				else
					comments["SingleShearplane"] := cat(chosenFastener, " overlap in part 2, single shearplane");
					fastenervalues["overlap"] := true;
				end if;

				if ls * sin(alphaScrew) > t["2"] + t["steel"] then

					Alert(cat(chosenFastener, " too long", warnings, 5));
					return

				elif (chosenFastener = "Nail" and nailSurface = "smooth" and t_pen < 8 * d) or t_pen < 6 * d then		# 8.3.1.2				

					Alert(cat("calculate_t: ", chosenFastener, " in part 2, anchorage length too short"), warnings, 5);
					return

				end if;					

			elif connection["connection2"] = "Steel" then	# Rothoblaas Alumini / Alumega

				t_eff["1"] := evalf(min(t["1"], ls * sin(alphaScrew) - t["1"] - t["steel"]));
				t_eff["2"] := 0;
				t_pen := t_eff["1"] / sin(alphaScrew);
				n_tip := "1";
				n_head := "1";

				fastenervalues["doublesided"] := false;
				fastenervalues["SingleShearplane"] := false;
				fastenervalues["overlap"] := false;
								
				if (chosenFastener = "Nail" and nailSurface = "smooth" and t_pen < 8 * d) or t_pen < 6 * d then		# 8.3.1.2

					Alert(cat("calculate_t: ", chosenFastener, " anchorage length too short"), warnings, 5);
					return

				end if;				

			end if;			
			
		else	# more than 2 shearplanes
					
			Alert("Connection with > 2 shearplanes can not be dimensioned with nails / screws", warnings, 5);			
			return
			
		end if;
		
		# t_ef for 8.1.4 NA DE
		for i in {"1", "2"} do
			
			if timberlayers[i] > 0 then
				
				if shearplanes = 1 then	# single sided connection
						
					if connection["connection1"] = "Timber" and connection["connection2"] = "Timber" then
						t_ef_814_NA_DE[i] := min(t[i] * timberlayers[i], t_pen, 12 * d)
					else
						t_ef_814_NA_DE[i] := min(t[i] * timberlayers[i], t_pen, 15 * d)	# steel - timber connection, nail (and screw)						
					end if;
				
				else					# symmectric connections
				
					if connection["connection1"] = "Timber" and connection["connection2"] = "Timber" then
						t_ef_814_NA_DE[i] := min(t[i] * timberlayers[i], 2 * t_pen, 24 * d)						
					else
						t_ef_814_NA_DE[i] := min(t[i] * timberlayers[i], 2 * t_pen, 30 * d)	# steel - timber connection, nail (and screw)						
					end if;
								
				end if;
								
			end if;
			
		end do;					

		t_pen := evalf(t_pen);

		# check if thread length is shorter than penetration depth (just screws)
		if structure["fastener"]["chosenFastener"] = "Screw" then
			if fastenervalues["l1"] < t_pen then
				t_pen := fastenervalues["l1"];
				comments["threadlength"] := "t,pen limited by thread length";	
			elif assigned(comments["threadlength"]) then
				comments["threadlength"] := evaln(comments["threadlength"])	
			end if
		elif assigned(comments["threadlength"]) then
			comments["threadlength"] := evaln(comments["threadlength"])	
		end if;		

	else

		Alert("calculate_t: unknown fastener type", warnings, 3);

	end if;

	for i in {"overlap", "doublesided"} do		# "SingleShearplane" is defined directly
		if assigned(fastenervalues[i]) then
			if fastenervalues[i] = true then
				comments[i] := i;
			else
				comments[i] := cat("no ", i);	# write text that says 
			end if;
		end if;
	end do;
	
	SetProperty("MathContainer_t1", value, round(t["1"]));
	SetProperty("MathContainer_t2", value, round(t["2"]));
	SetProperty("MathContainer_t_eff1", value, round(t_eff["1"]));
	SetProperty("MathContainer_t_eff2", value, round(t_eff["2"]));
	SetProperty("MathContainer_t_pen", value, round(t_pen));
	SetProperty("TextArea_shearplanes", value, fastenervalues["shearplanes"]);

	fastenervalues["t_eff"] := eval(t_eff);
	fastenervalues["t_ef_814_NA_DE"] := t_ef_814_NA_DE;
	fastenervalues["t_pen"] := t_pen;
	fastenervalues["n_tip"] := n_tip;
	fastenervalues["n_head"] := n_head;

end proc:


# 8.3.2
calculate_F_axR := proc(WhateverYouNeed::table)
	description "calculate F_axR for nails";

	local calculatedFastener, chosenFastener, t, t_pen, n_tip, rho_k, connection, nailSurface, d, dh, f_axk, f_headk, f_tensk, washer_N_axk, screwWithWasher, alphaScrew, calculateAsNail;
	local F_axRk, F_axRd, F_axRd_fastener, alpha_rho, R_axk, R_headk, k_d, n_head, R_axk_n_head, gamma_M, k_mod;
	local structure, materialdataAll, sectiondataAll, warnings, comments, fastenervalues, numberOfFasteners, k_ef;

	# define local variables
	gamma_M := 1.3; 		# NS-EN 1995, NA.2.4.1
	structure := WhateverYouNeed["calculations"]["structure"];
	materialdataAll := WhateverYouNeed["materialdataAll"];	
	sectiondataAll := WhateverYouNeed["sectiondataAll"];
	warnings := WhateverYouNeed["warnings"];
	comments := WhateverYouNeed["results"]["comments"];
	fastenervalues := WhateverYouNeed["calculatedvalues"]["fastenervalues"];
	numberOfFasteners := numelems(WhateverYouNeed["results"]["FastenerGroup"]["Fasteners"]);

	alpha_rho := table();
	R_axk := 0;
	R_axk_n_head := 0;
	R_headk := 0;

	# stored values
	connection := structure["connection"];
	n_tip := fastenervalues["n_tip"];
	n_head := fastenervalues["n_head"];
	t_pen := fastenervalues["t_pen"];

	# structure / fastener
	chosenFastener := structure["fastener"]["chosenFastener"];
	calculatedFastener := fastenervalues["calculatedFastener"];
	calculateAsNail := structure["fastener"]["calculateAsNail"];
	nailSurface := structure["fastener"]["nailSurface"];
	d := structure["fastener"]["fastener_d"];
	dh := structure["fastener"]["fastener_dh"];
	screwWithWasher := structure["fastener"]["screwWithWasher"];
	f_axk := fastenervalues["f_axk"];
	f_headk := fastenervalues["f_headk"];
	f_tensk := fastenervalues["f_tensk"];
	washer_N_axk := fastenervalues["washer_N_axk"];
	alphaScrew := structure["fastener"]["alphaScrew"];
	
	rho_k := table();
	rho_k["1"] := materialdataAll["1"]["rho_k"];
	rho_k["2"] := materialdataAll["2"]["rho_k"];

	t := table();
	t["1"] := sectiondataAll["1"]["b"];
	t["2"] := sectiondataAll["2"]["b"];
	
	# modification factor for f_axk, which is defined for timber with 350 kg/m3
	# for screws: (8.39) uses rho_k ^ 0.8, (8.40b) uses the same formula
	# for nails:  (8.26) uses rho_k ^ 2
	if chosenFastener = "Nail" then
		alpha_rho[n_tip] := evalf((rho_k[n_tip] / (350.0 * Unit(('kg')/'m'^3))) ^ 2); 	
		alpha_rho[n_head] := evalf((rho_k[n_head] / (350.0 * Unit(('kg')/'m'^3))) ^ 2); 
		
	elif chosenFastener = "Screw" then
		alpha_rho[n_tip] := evalf((rho_k[n_tip] / (350.0 * Unit(('kg')/'m'^3))) ^ 0.8); 	
		alpha_rho[n_head] := evalf((rho_k[n_head] / (350.0 * Unit(('kg')/'m'^3))) ^ 0.8); 
	else
		alpha_rho[n_tip] := 1;
		alpha_rho[n_head] := 1
	end if;
	
	if n_tip <> 0 then
		SetProperty(cat("TextArea_alpha_rho", n_tip), value, round2(alpha_rho[n_tip], 2));
	else
		SetProperty("TextArea_alpha_rho1", value, 1);
	end if;
	
	if n_head <> 0 then
		SetProperty(cat("TextArea_alpha_rho", n_head), value, round2(alpha_rho[n_head], 2));
	else
		SetProperty("TextArea_alpha_rho2", value, 1);
	end if;

	# checking agains calculated fastener, might be nail, bolt or dowel (not screw)
	if calculatedFastener = "Nail" or (chosenFastener = "Screw" and calculateAsNail = "true") then

		# f_axk, R_axk
		if f_axk = 0 then
			calculate_f_axk(WhateverYouNeed);
			f_axk := fastenervalues["f_axk"]
		end if;		
		R_axk := f_axk * d * t_pen * alpha_rho[n_tip];		# (8.23), part with the tip of the nail

		# f_headk
		if f_headk = 0 then
			calculate_f_headk(WhateverYouNeed);
			f_headk := fastenervalues["f_headk"]
		end if;
		if connection[n_head] = "Timber" then
			if screwWithWasher = "true" then		# for some 6mm screws there could be washer (just Rothoblaas HBS for the moment)
				R_headk := washer_N_axk * alpha_rho[n_head];
			else
				R_headk := f_headk * dh^2 * alpha_rho[n_head];
			end if;
		else
			R_headk := f_tensk
		end if;	

		# R_axk_n_head
		if connection[n_head] = "Timber" then			
			calculate_R_axk_n_head(n_head, WhateverYouNeed) * alpha_rho[n_head];
			R_axk_n_head := structure["calculatedvalues"]["R_axk_n_head"];
		else
			R_axk_n_head := 0
		end if;
		
		# t_pen
		# 8.3.2 (7)
		if calculatedFastener = "Nail" and nailSurface = "smooth" then
			if t_pen < 8 * d then
				R_axk := 0			
			elif t_pen < 12 * d then
				R_axk := R_axk * (t_pen / (4 * d) - 2)
			end if;
		else
			if t_pen < 6 * d then
				R_axk := 0
			elif t_pen < 8 * d then
				R_axk := R_axk * (t_pen / (2 * d) - 3)			
			end if;			
		end if;	

		# F_axkRk
		if connection[n_head] = "Timber" then
			if chosenFastener = "Nail" and nailSurface = "smooth" then
				F_axRk := eval(min(R_axk, f_axk * d * t[n_head] / sin(alphaScrew) * alpha_rho[n_head] + R_headk));	# 8.24
				
			elif nailSurface = "non smooth" or chosenFastener = "Screw" then			
				F_axRk := eval(min(R_axk, R_headk + R_axk_n_head));	# 8.23 with modification for screws with thread in complete length
				
			end if;
	
		else	# steel plate on outside
			F_axRk := R_axk			
			
		end if;			

		F_axRk := eval(min(F_axRk, f_tensk));	# check for steel failure

		k_ef := 1;		# reduction factor for connection

	elif calculatedFastener = "Dowel" then
		F_axRk := 0;
		k_ef := 1;		# reduction factor for connection

	elif calculatedFastener = "Bolt" then
		R_axk := 0;
		k_ef := 1;		# reduction factor for connection
		
		if chosenFastener = "Bolt" then		# with washer
			R_headk := washer_N_axk * alpha_rho[n_head];
			F_axRk := eval(min(f_tensk, R_headk))

		# screws >= 6mm and <= 12mm calculted acc. 8.7.2
		# choose to calculate screws >6mm acc. 8.7.2, though screws with d = 6mm should be calculated as nails (see 8.7.1(5))
		else 

			k_d := min(d / ( 8 * Unit('mm')), 1);														# (8.40)
			
			if f_axk = 0 then
				calculate_f_axk(WhateverYouNeed);
				f_axk := fastenervalues["f_axk"]
			end if;		
			R_axk := f_axk * d * t_pen * k_d / (1.2 * cos(alphaScrew)^2 + sin(alphaScrew)^2) * alpha_rho[n_tip];	# (8.38)
			
			if connection[n_head] = "Timber" then
				R_axk_n_head := calculate_R_axk_n_head(n_head) * alpha_rho[n_head];
				
				if screwWithWasher = true then		# 6mm screws could be with washers (just Rothoblaas HBS for the moment)
					R_headk := washer_N_axk * alpha_rho[n_head];
				else
					R_headk := f_headk * dh^2 * alpha_rho[n_head];
				end if;
				
			else # screw against steel
				R_headk := f_tensk;
				
			end if;
			
			F_axRk := eval(min(R_axk, R_axk_n_head + R_headk, f_tensk));

			k_ef := 0.9;	# reduction factor for connection
			
		end if;
		
	end if;
	
	R_headk := convert(R_headk, 'units', 'kN');
	R_axk := convert(R_axk, 'units', 'kN');
	F_axRk := convert(F_axRk, 'units', 'kN');


	SetProperty("MathContainer_R_axk1", value, 0);
	SetProperty("MathContainer_R_axk2", value, 0);
	SetProperty("MathContainer_R_headk1", value, 0);
	SetProperty("MathContainer_R_headk2", value, 0);
	if n_tip = "1" or n_tip = "2" then
		SetProperty(cat("MathContainer_R_axk", n_tip), value, round2(R_axk, 1))
	end if;
	if n_head = "1" or n_head = "2" then
		SetProperty(cat("MathContainer_R_axk", n_head), value, round2(R_axk_n_head, 1))
	end if;
	
	if n_head = "1" or n_head = "2" then
		SetProperty(cat("MathContainer_R_headk", n_head), value, round2(R_headk, 1))
	end if;
	
	SetProperty("MathContainer_F_axRk", value, round2(F_axRk, 1));

	# calculate F_axRd	
	k_mod := 0;

	if structure["connection"]["connection1"] = "Timber" then		
		k_mod := materialdataAll["1"]["k_mod"]
	end if;

	if structure["connection"]["connection2"] = "Timber" then
		if k_mod = 0 or k_mod > materialdataAll["2"]["k_mod"] then			
			k_mod := materialdataAll["2"]["k_mod"]		
		end if;
	end if;
	
	# F_axRd is for single shearplane, one fastener
	F_axRd := eval(F_axRk * k_mod / gamma_M);
	SetProperty("MathContainer_F_axRd", value, round2(F_axRd, 1));

	F_axRd_fastener := F_axRd * (numberOfFasteners ^ k_ef / numberOfFasteners);
	SetProperty("MathContainer_F_axRd_fastener", value, round2(F_axRd_fastener, 1));

	if ComponentExists("TextArea_gamma_M") then
		SetProperty("TextArea_gamma_M", value, round2(gamma_M, 2))
	end if;
	
	fastenervalues["R_headk"] := R_headk;
	fastenervalues["R_axk"] := R_axk;
	fastenervalues["F_axRk"] := F_axRk;
	fastenervalues["F_axRd"] := F_axRd;
	fastenervalues["F_axRd_fastener"] := F_axRd_fastener;

end proc:


# 8.3.1.1(2)
checkPredrilled := proc(WhateverYouNeed::table)
	description "Check if predrilled is required";
	local rho_k, d, predrilled, check_predrilled, chosenFastener, t, connection, ignoreReqPredrilled;
	local structure, materialdataAll, sectiondataAll, warnings, comments;

	# define local variables
	structure := WhateverYouNeed["calculations"]["structure"];
	materialdataAll := WhateverYouNeed["materialdataAll"];	
	sectiondataAll := WhateverYouNeed["sectiondataAll"];
	warnings := WhateverYouNeed["warnings"];
	comments := WhateverYouNeed["results"]["comments"];

	check_predrilled := false;
	
	chosenFastener := structure["fastener"]["chosenFastener"];
	connection := structure["connection"];
	d := structure["fastener"]["fastener_d"];
	predrilled := structure["fastener"]["predrilled"];
	ignoreReqPredrilled := structure["fastener"]["ignoreReqPredrilled"];
	
	t := table();
	t["1"] := sectiondataAll["1"]["b"];
	t["2"] := sectiondataAll["2"]["b"];

	rho_k := table();
	rho_k["1"] := materialdataAll["1"]["rho_k"];
	rho_k["2"] := materialdataAll["2"]["rho_k"];

	if chosenFastener = "Nail" then		# (8.18)
		if connection["connection1"] = "Timber" and connection["connection2"] = "Timber" then
			if evalb(min(t["1"], t["2"]) < max(7 * d, (13 * d - 30 * Unit('mm')) * rho_k["1"] / (400 * Unit('kg/m^3')))) then
				check_predrilled := true
			end if;
		elif connection["connection1"] = "Timber" and connection["connection2"] = "Steel" then
			if evalb(t["1"] < max(7 * d, (13 * d - 30 * Unit('mm')) * rho_k["1"] / (400 * Unit('kg/m^3')))) then
				check_predrilled := true
			end if;
		elif connection["connection1"] = "Steel" and connection["connection2"] = "Timber" then
			if evalb(t["2"] < max(7 * d, (13 * d - 30 * Unit('mm')) * rho_k["2"] / (400 * Unit('kg/m^3')))) then
				check_predrilled := true
			end if;
		end if;
	elif chosenFastener = "Screw" then		# (10.4.5)
		if d > 6 * Unit('mm') then
			check_predrilled := true
		end if;
	else
		check_predrilled := true		# dowels and bolts need to be predrilled anyway
	end if;

	if predrilled = "true" then
		comments["predrilled"] := "predrilled";
	elif assigned(comments["predrilled"]) then
		comments["predrilled"] := evaln(comments["predrilled"])		# remove entry
	end if;

	if ignoreReqPredrilled = "true" then
		comments["ignoreReqPredrilled"] := "required predrill ignored"
	elif assigned(comments["ignoreReqPredrilled"]) then
		comments["ignoreReqPredrilled"] := evaln(comments["ignoreReqPredrilled"])
	end if;

	if check_predrilled = true and predrilled = "false" and ignoreReqPredrilled = "false" then
		Alert("predrill required", warnings, 3)
	end if;	
	
end proc:


GetFastenervalues := proc(WhateverYouNeed::table)
	description "check if fastenervalues are predefined or need to be calculated";
	local comments, structure, fastener, fastenervalues, calculatedFastener, nailSurface, nailForm, f_uk, d, M_yRk, boltgrade, f_tensk, warnings;

	comments := WhateverYouNeed["results"]["comments"];
	structure := WhateverYouNeed["calculations"]["structure"];
	fastener := structure["fastener"];
	fastenervalues := WhateverYouNeed["calculatedvalues"]["fastenervalues"];
	warnings := WhateverYouNeed["warnings"];
	
	# M_yRk					
	if fastenervalues["M_yRk"] = 0 then
		# 8.3.1.1(4)
		# Case - 00078221 | Re: Error, (in Units:-getUnitStruct) invalid subscript selector
		# If you assign the unit function call to a global variable and then examine its attributes, it works as expected. 
		# However, if you use a local variable in a procedure, or access the attributes before assigning to a variable as in the command above, it returns NULL. 
	
		# Men jeg fant ut at problemet forsvinner, hvis en legger en extra eval( ) rundt funksjonen, f�r en lagrer det til en lokal variabel

		calculatedFastener := WhateverYouNeed["calculatedvalues"]["fastenervalues"]["calculatedFastener"];
		nailSurface := structure["fastener"]["nailSurface"];
		nailForm := structure["fastener"]["nailForm"];		
		d := structure["fastener"]["fastener_d"];

		if assigned(fastener["boltgrade"]) then			# boltgrade is just assigned if chosen bolttype opens up for this, otherwise undefined
			boltgrade := fastener["boltgrade"];		# "4.6", "8.8"
			f_uk := NODEBolts:-f_ub[boltgrade];
			fastenervalues["f_uk"] := f_uk
		else
			f_uk := fastenervalues["f_uk"];
#		else
#			f_uk := 0;
#			Alert("GetFastenervalues: fastener f_uk not defined", warnings, 3)
		end if;
	
		if calculatedFastener = "Nail" and nailSurface = "smooth" and evalb(f_uk > 600 * Unit('N'/'mm^2')) then
		
			if nailForm = "round" then
				M_yRk := (0.3 * convert(f_uk, 'unit_free') * convert(d, 'unit_free')^2.6)/1000 * Unit('N'*'m')			# 8.14
			else
				M_yRk := (0.45 * convert(f_uk, 'unit_free') * convert(d, 'unit_free')^2.6)/1000 * Unit('N'*'m')		# 8.14
			end if;
		
		elif calculatedFastener = "Bolt" or calculatedFastener = "Dowel" then
		
			M_yRk := (0.3 * convert(f_uk, 'unit_free') * convert(d, 'unit_free')^2.6)/1000 * Unit('N'*'m')				# 8.30
		
		end if;

		fastenervalues["M_yRk"] := M_yRk;
		comments["M_yRk"] := "M_yRk calculated";
		SetProperty("MathContainer_M_yRk", value, round2(fastenervalues["M_yRk"], 2));	
			
	elif assigned(comments["M_yRk"]) then
			
		comments["M_yRk"] := evaln(comments["M_yRk"])
			
	end if;
		
	# f_tensk	
	if fastenervalues["f_tensk"] = 0 then

		if assigned(fastener["boltgrade"]) then			# boltgrade is just assigned if chosen bolttype opens up for this, otherwise undefined
			f_tensk := NODEBolts:-F_tRk(cat("M", round(convert(d, 'unit_free'))), fastener["boltgrade"]);		# "M12", "5.6"
		else			
			f_tensk := 0;			
		end if;

		fastenervalues["f_tensk"] := f_tensk;
		comments["f_tensk"] := "f_tensk calculated";
		SetProperty("MathContainer_f_tensk", value, round2(fastenervalues["f_tensk"], 2));

	elif assigned(comments["f_tensk"]) then

		comments["f_tensk"] := evaln(comments["f_tensk"])
		
	end if;	

end proc:


# 8.3.1.1(5)
calculate_f_h0k := proc(WhateverYouNeed::table, part::string)
	local f_h0k, calculatedFastener, d, predrilled, chosenFastener, calculateAsNail, structure, rho_k, material;

	structure := WhateverYouNeed["calculations"]["structure"];

	calculatedFastener := WhateverYouNeed["calculatedvalues"]["fastenervalues"]["calculatedFastener"];
	chosenFastener := structure["fastener"]["chosenFastener"];
	calculateAsNail := structure["fastener"]["calculateAsNail"];
	predrilled := structure["fastener"]["predrilled"];
	d := structure["fastener"]["fastener_d"];
	rho_k := WhateverYouNeed["materialdataAll"][part]["rho_k"];
	material := WhateverYouNeed["materialdataAll"][part]["material"];
	
	if material = "timber" then
		if calculatedFastener = "Nail" or (chosenFastener = "Screw" and calculateAsNail = "true") then
			if predrilled = "true" then
				f_h0k := (0.082 * (1 - 0.01 * convert(d, 'unit_free')) * convert(rho_k, 'unit_free')) * Unit('N'/'mm^2');
			else
				f_h0k := (0.082 * convert(rho_k, 'unit_free') * convert(d, 'unit_free')^(-0.3)) * Unit('N'/'mm^2')
			end if;
			
		elif calculatedFastener = "Bolt" or calculatedFastener = "Dowel" then
			
			f_h0k := (0.082 * (1 - 0.01 * convert(d, 'unit_free')) * convert(rho_k, 'unit_free')) * Unit('N'/'mm^2');
			
		end if;

	else
		f_h0k := 0

	end if;
	
	return f_h0k
end proc:


# 8.3.1.1(8)
# calculating k_n_ef as a reduction factor for capacity due to number of fasteners in a row
calculate_n_ef := proc(WhateverYouNeed::table)
	description "calculate reduction factor of capacity of one single fastener";
	local staggered, calculatedFastener, a1, d, chosenFastener, calculateAsNail, part, structure, distance, k_ef, n_ef0, n1, k_n_ef0, comments;

	structure := WhateverYouNeed["calculations"]["structure"];	
	chosenFastener := structure["fastener"]["chosenFastener"];	
	calculateAsNail := structure["fastener"]["calculateAsNail"];
	calculatedFastener := WhateverYouNeed["calculatedvalues"]["fastenervalues"]["calculatedFastener"];
	distance := WhateverYouNeed["calculatedvalues"]["distance"];
	d := structure["fastener"]["fastener_d"];
	comments := WhateverYouNeed["results"]["comments"];

	for part in {"1", "2"} do

		staggered := structure["fastener"][cat("staggered", part)];

		if structure["connection"][cat("connection", part)] = "Timber" then

			if assigned(WhateverYouNeed["calculatedvalues"]["distance"]["a1_nFastenersInRow"][part]) then
				n1 := WhateverYouNeed["calculatedvalues"]["distance"]["a1_nFastenersInRow"][part]
			else
				n1 := 1
			end if;
			
			if calculatedFastener = "Nail" or (chosenFastener = "Screw" and calculateAsNail = "true") then
				if staggered = "false" then		# staggered parallel to grain direction with distance d
					comments[cat("staggered", part)] := evaln(comments[cat("staggered", part)]);
					k_ef := calculate_k_ef(part, WhateverYouNeed);
					n_ef0 := n1^k_ef;			# (8.17)
				else
					comments[cat("staggered", part)] := cat("row parallel to grain ", part, " staggered");
					k_ef := 1;
					n_ef0 := n1
				end if;
	
			elif calculatedFastener = "Bolt" or calculatedFastener = "Dowel" then
				if assigned(distance[cat("a1", part)]) then
					a1 := eval(distance[cat("a1", part)]);
					k_ef := 1;
					n_ef0 := min(n1, n1^0.9 * root((a1 / (13 * d)), 4) );		# (8.34), capacity in grain direction
				else
					k_ef := 0;
					n_ef0 := 1
				end if;
	
			end if;

			k_n_ef0 := n_ef0 / n1;

			WhateverYouNeed["calculatedvalues"][cat("k_ef", part)] := k_ef;
			WhateverYouNeed["calculatedvalues"][cat("n_ef0", part)] := n_ef0;
			WhateverYouNeed["calculatedvalues"][cat("k_n_ef0", part)] := k_n_ef0;	# reduction factor for n_ef

			if ComponentExists(cat("TextArea_k_ef", part)) then
				SetProperty(cat("TextArea_k_ef", part), value, round2(k_ef, 2))
			end if;
			if ComponentExists(cat("TextArea_n_ef0", part)) then
				SetProperty(cat("TextArea_n_ef0", part), value, round2(n_ef0, 2))
			end if;
			if ComponentExists(cat("TextArea_k_n_ef0", part)) then
				SetProperty(cat("TextArea_k_n_ef0", part), value, round2(k_n_ef0, 2))
			end if;

#			if part = 1 or assigned(WhateverYouNeed["calculatedvalues"]["k_n_ef"]) = false then
#				WhateverYouNeed["calculatedvalues"]["k_n_ef0"] := k_n_ef0
				
#			elif k_n_ef0 < WhateverYouNeed["calculatedvalues"]["k_n_ef0"] then
#				WhateverYouNeed["calculatedvalues"]["k_n_ef0"] := k_n_ef0
			
#			end if;
			
		end if;
	end do;
	
end proc:


# 8.3.1.1(8)
calculate_k_ef := proc(part::string, WhateverYouNeed::table)
	description "calculate reduction factor k_ef for nails";
	local k_ef, d, predrilled, distance, a1, structure;

	structure := WhateverYouNeed["calculations"]["structure"];
	d := structure["fastener"]["fastener_d"];
	predrilled := structure["fastener"]["predrilled"];
	distance := WhateverYouNeed["calculatedvalues"]["distance"];

	if assigned(distance[cat("a1", part)]) then
		a1 := eval(distance[cat("a1", part)]);
	
		if a1 >= 14*d then
			k_ef := 1
		elif a1 >= 10*d then
			k_ef := 0.85 + (a1 - 10*d) * (1 - 0.85) / (4 * d)
		elif a1 >= 7*d then
			k_ef := 0.7 + (a1 - 7*d) * (0.85 - 0.7) / (3 * d)
		elif a1 >= 4*d and predrilled = "true" then
			k_ef := 0.5 + (a1 - 4*d) * (0.7 - 0.5) / (3 * d)
		else
			k_ef := 0
		end if;
		
	else
		k_ef := 0
	end if;
	
	return k_ef
end proc:


calculate_f_axk := proc(WhateverYouNeed::table)
	description "calculate f_axk according to formula in EC 5";
	local f_axk, chosenFastener, d, t_pen, nailSurface, calculatedvalue, structure, fastenervalues;

	# local variables
	structure := WhateverYouNeed["calculations"]["structure"];
	fastenervalues := WhateverYouNeed["calculatedvalues"]["fastenervalues"];
	calculatedvalue := false;
	# comments := table(comments);
	chosenFastener := structure["fastener"]["chosenFastener"];
	nailSurface := structure["fastener"]["nailSurface"];
	d := structure["fastener"]["fastener_d"];
	t_pen := fastenervalues["t_pen"];
	# f_axk := WhateverYouNeed["calculatedvalues"]["fastenervalues"]["f_axk"];

	if chosenFastener = "Nail" and nailSurface = "smooth" and evalb(t_pen > 12 * d) then
		f_axk := 20*10^(-6) * 350 ^ 2 * Unit('N/mm^2');															# (8.25)
		calculatedvalue := true
	elif chosenFastener = "Screw" then
		f_axk := 0.52 * convert(d, 'unit_free') ^ (-0.5) * convert(t_pen, 'unit_free') ^ (-0.1) * 350 ^ 0.8 * Unit('N/mm^2');		# (8.39)
		calculatedvalue := true
	end if;

	if calculatedvalue then
		SetProperty("MathContainer_f_axk", 'fillcolor', "coral");
		WhateverYouNeed["calculatedvalues"]["fastenervalues"]["f_axk"] := eval(f_axk);
		SetProperty("MathContainer_f_axk", value, round2(f_axk, 2))
	else
		SetProperty("MathContainer_f_axk", 'fillcolor', "white")
	end if;
	
end proc:


calculate_f_headk := proc(WhateverYouNeed::table)
	description "Calculate f_head,k according to EC5";
	local f_headk, chosenFastener, d, t_pen, nailSurface, calculatedvalue, structure, fastenervalues;

	structure := WhateverYouNeed["calculations"]["structure"];
	fastenervalues := WhateverYouNeed["calculatedvalues"]["fastenervalues"];
	calculatedvalue := false;
	chosenFastener := structure["fastener"]["chosenFastener"];
	nailSurface := structure["fastener"]["nailSurface"];
	d := structure["fastener"]["fastener_d"];
	t_pen := fastenervalues["t_pen"];
	
	if chosenFastener = "Nail" and nailSurface = "smooth" and evalb(t_pen > 12 * d) then
		f_headk := 70*10^(-6) * 350 ^ 2 * Unit('N/mm^2');															# (8.26)
		calculatedvalue := true;
	end if;

	if calculatedvalue then
		SetProperty("MathContainer_f_headk", 'fillcolor', "orange");
		fastenervalues["f_headk"] := eval(f_headk);
		SetProperty("MathContainer_f_headk", value, round2(f_headk, 2));
	else
		SetProperty("MathContainer_f_headk", 'fillcolor', "white");
	end if;
	
end proc:


# 8.3.2 for part with the head
calculate_R_axk_n_head := proc(part, WhateverYouNeed)
	description "Calculates Rax,k for the part of the screw with the head";
	local chosenFastener, d, ls, t, f_axk, alphaScrew, fastenervalues, structure, sectiondataAll, comments;
	local R_axk_n_head, lg, lg1, lg2, tol;

	# local variables
	structure := WhateverYouNeed["calculations"]["structure"];
	sectiondataAll := WhateverYouNeed["sectiondataAll"];
	comments := WhateverYouNeed["results"]["comments"];
	fastenervalues := WhateverYouNeed["calculatedvalues"]["fastenervalues"];
	chosenFastener := structure["fastener"]["chosenFastener"];	
	ls := structure["fastener"]["fastener_ls"];
	d := structure["fastener"]["fastener_d"];
	f_axk := fastenervalues["f_axk"];
	alphaScrew := structure["fastener"]["alphaScrew"];	# inclination of fastener

	t := table();
	t["1"] := sectiondataAll["1"]["b"];
	t["2"] := sectiondataAll["2"]["b"];

	R_axk_n_head := 0;
	tol := 10 * Unit('mm');     	# tolerance
	lg := 0;					# anchorage length of fastener in part with fastener head
	
	# This is for the part with the head
	# For nails calculations are not prepared for at this part is calculated with anchorage length, but it is done for screws
	if chosenFastener = "Screw" then
		lg1 := fastenervalues["l1"];	# thread length from tip
		lg2 := fastenervalues["l2"];	# for screws with split thread
		
		if lg2 > 0 then	# screw with splitted thread
			comments["doublethreaded"] := "double-threaded screw";
			lg := evalf(min(t[part] / sin(alphaScrew), lg2 - tol));
		elif assigned(comments["doublethreaded"]) then
			comments["doublethreaded"] := evaln(comments["doublethreaded"]);
			lg := evalf(t[part] / sin(alphaScrew) - ls + lg1 - tol);
		end if;
		
		if lg <= 6 * d then
			R_axk_n_head := 0;
		else
			R_axk_n_head := f_axk * d * lg;
			if lg < 8 * d then
				R_axk_n_head := R_axk_n_head * (lg / (2 * d) - 3);
			end if;
		end if;

	end if;

	structure["calculatedvalues"]["R_axk_n_head"] := convert(R_axk_n_head, 'units', 'kN');
end proc:


EC5_832 := proc(WhateverYouNeed::table)
	description "8.3.2/8.7.2 Axially loaded nails/screw";
	local eta_active, usedcode, comments, F_axd, activeloadcase, F_axRd_fastener, numberOfFasteners;

	activeloadcase := WhateverYouNeed["calculations"]["activesettings"]["activeloadcase"];
	F_axd := WhateverYouNeed["calculations"]["loadcases"][activeloadcase]["F_axd"];

	F_axRd_fastener :=  WhateverYouNeed["calculatedvalues"]["fastenervalues"]["F_axRd_fastener"];	# capacity for one screw
	numberOfFasteners := numelems(WhateverYouNeed["results"]["FastenerGroup"]["Fasteners"]);

	if WhateverYouNeed["calculatedvalues"]["axiallyLoaded"] = true then
		if numberOfFasteners * F_axRd_fastener <> 0 then
			eta_active := F_axd / (numberOfFasteners * F_axRd_fastener);
		else
			eta_active := 99
		end if
	else
		eta_active := 0
	end if;

	# need to check maximum of loadcases as well sometime
	
	usedcode := "8.3.2 / 8.7.2";
	comments := "Axially loaded nails/screw";
	return eta_active, usedcode, comments;

end proc:


EC5_833 := proc(WhateverYouNeed::table)
	description "8.3.3 Combined laterally and axially loaded nails";
	local chosenFastener, nailSurface, structure, eta, usedcode, warnings, comments, eta_active;

	structure := WhateverYouNeed["calculations"]["structure"];
	chosenFastener := structure["fastener"]["chosenFastener"];
	nailSurface := structure["fastener"]["nailSurface"];
	
	eta := WhateverYouNeed["results"]["eta"];	
	warnings := WhateverYouNeed["warnings"];

	if chosenFastener = "Nail" and nailSurface = "smooth" then
		eta_active := eta["832"] + eta["812"];		# (8.27)
		usedcode := "8.3.3";
		comments := "Combined laterally and axially loaded nails"

	elif chosenFastener = "Nail" or chosenFastener = "Screw" then		# non smooth surface, screws 8.7.3
		if eta["832"] > 0 and eta["812"] > 0 then					# we don't square utilization if it is not a combined load situation
			eta_active := eta["832"]^2 + eta["812"]^2;		# (8.28)
			usedcode := "8.3.3";
			comments := "Combined laterally and axially loaded nails"
		else
			eta_active := 0;		# (8.27)
		end if;

	
	elif WhateverYouNeed["results"]["832"] = 0 then
		# bolts or dowels with no axial load
		eta_active := 0

	elif chosenFastener = "Bolt" then		# 8.5 does not give any clue about how to combine shear and tension in bolts, therefore no combination necessary is assumed
		eta_active := 0		
		
	else
		Alert("8.3.3 No valid fastener for combined laterally and axially loads", warnings, 5);
		
	end if;	

	return eta_active, usedcode, comments;
end proc: