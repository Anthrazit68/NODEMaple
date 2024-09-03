# calculateMinimumdistances
# resetcomments
# calculatealpha
# calculate_amin_alpha
# calculate_amin_max
# PrintMinimumdistance

# 8.5.1.1(3) Minimumsavstander

# this one is not really useful at the moment, as we do assume alpha = 0
calculateMinimumdistances := proc(WhateverYouNeed::table)
	local part, structure;

	structure := WhateverYouNeed["calculations"]["structure"];	
	# resetcomments(WhateverYouNeed);

	for part in {"1", "2"} do	
		if structure["connection"][cat("connection", part)] = "Timber" then			
			calculate_amin_alpha(part, WhateverYouNeed);			
			PrintMinimumdistance(part, WhateverYouNeed);
		else
			PrintMinimumdistance("steel", WhateverYouNeed);
		end if;		
	end do;
end proc:


calculate_amin_alpha := proc(part::string, WhateverYouNeed::table)
	local calculatedFastener, chosenFastener, calculateAsNail, a1_min, a2_min, a3_min, a3t_min, a3c_min, a4t_min, a4c_min, predrilled, d, rho_k, axiallyLoaded, 
		j, variables, red_steel, t, h, structure, materialdataAll, sectiondataAll, warnings, comments, distance, alphaBeam, CosMax, SinMax, alpha, ForcesInConnection, i;

	# global variables
	warnings := WhateverYouNeed["warnings"];
	structure := WhateverYouNeed["calculations"]["structure"];
	comments := WhateverYouNeed["calculations"]["comments"];
	sectiondataAll := WhateverYouNeed["sectiondataAll"];
	materialdataAll := WhateverYouNeed["materialdataAll"];
	calculatedFastener := WhateverYouNeed["calculatedvalues"]["fastenervalues"]["calculatedFastener"];
	chosenFastener := structure["fastener"]["chosenFastener"];
	calculateAsNail := structure["fastener"]["calculateAsNail"];
	predrilled := structure["fastener"]["predrilled"];
	axiallyLoaded := WhateverYouNeed["calculatedvalues"]["axiallyLoaded"];
	alphaBeam := evalf(WhateverYouNeed["calculations"]["structure"]["connection"][cat("graindirection", part)]);
	ForcesInConnection := WhateverYouNeed["results"]["FastenerGroup"]["ForcesInConnection"];

	# Find maximum of sinus and cosinus values for angles between force and grain of all fasteners in connection
	CosMax := 0;
	SinMax := 0:
	for i in indices(ForcesInConnection, 'nolist') do
		alpha := ForcesInConnection[i][4] - alphaBeam;	# angle between force in fastener and grain direction
		if abs(cos(alpha)) > CosMax then
			CosMax := abs(cos(alpha))
		end if;
		if abs(sin(alpha)) > SinMax then
			SinMax := abs(sin(alpha))
		end if;		
	end do;
	
	if assigned(WhateverYouNeed["calculatedvalues"]["distance"]) then
		distance := WhateverYouNeed["calculatedvalues"]["distance"]
	else
		distance := table();
		WhateverYouNeed["calculatedvalues"]["distance"] := eval(distance)
	end if;
	
	# local variables
	a1_min := table();
	a2_min := table();
	a3_min := table();
	a3t_min := table();
	a3c_min := table();
	a4t_min := table();
	a4c_min := table();
	
	d := structure["fastener"]["fastener_d"];

	rho_k := table();
	rho_k["1"] := materialdataAll["1"]["rho_k"];
	rho_k["2"] := materialdataAll["2"]["rho_k"];
	
	t := table();
	t["1"] := sectiondataAll["1"]["b"];
	t["2"] := sectiondataAll["2"]["b"];
	
	h := table();
	h["1"] := sectiondataAll["1"]["h"];
	h["2"] := sectiondataAll["2"]["h"];

	if structure["connection"]["connection1"] = "Timber" and structure["connection"]["connection2"] = "Timber" then
		red_steel := 1;
		if assigned(comments["red_steel"]) then
			comments["red_steel"] := evaln(comments["red_steel"])
		end if
		
	elif calculatedFastener = "Nail" or (chosenFastener = "Screw" and calculateAsNail = "true") then
		red_steel := 0.7;		# 8.3.1.4 reduction for a1 and a2 for fasteners between steel and timber
		comments["red_steel"] := "a1, a2 reduced to 70% according to 8.3.1.4";
		
	else # connections with bolts
		red_steel := 1;
		if assigned(comments["red_steel"]) then
			comments["red_steel"] := evaln(comments["red_steel"])
		end if
		
	end if;

	# need to reset some comments here
	if assigned(comments[cat("872_", part)]) then
		comments[cat("872_", part)] := evaln(comments[cat("872_", part)])
	end if;

  	if materialdataAll[part]["timbertype"] = "CLT" then
  	
  		if t[part] < 10 * d or h[part] < 10 * d then
  			Alert("CLT thickness < 10 * d", warnings, 3)
  		end if;

  		# 
  		if t[part] < h[part] then		# fastener on lateral face of CLT element (Rothoblaas page 34, HBS screws)
  		
  			a1_min[part] := 4 * d;
  			a2_min[part] := 2.5 * d;
  			a3t_min[part] := 6 * d;
			a3c_min[part] := 6 * d;
			a4t_min[part] := 6 * d;
			a4c_min[part] := 2.5 * d;
		
  		else							# fastener on narrow face of CLT
  		
  			a1_min[part] := 10 * d;
  			a2_min[part] := 4 * d;
  			a3t_min[part] := 12 * d;
			a3c_min[part] := 7 * d;
			a4t_min[part] := 6 * d;
			a4c_min[part] := 3 * d;
		
  		end if;
  	
  	else		# glulam or general timber
  	
		# a1_min
		if calculatedFastener = "Nail" or (chosenFastener = "Screw" and calculateAsNail = "true") then
			
			if predrilled = "true" then
				a1_min[part] := (4 + abs(CosMax)) * d;
				
			else
				if rho_k[part] <= 420 * Unit('kg/m^3') and d < 5 * Unit('mm') then
					a1_min[part] := (5 + 5 * abs(CosMax)) * d;
				elif rho_k[part] <= 420  * Unit('kg/m^3') and d >= 5 * Unit('mm') then
					a1_min[part] := (5 + 7 * abs(CosMax)) * d;
				else
					a1_min[part] := (7 + 8 * abs(CosMax)) * d;
				end if;
			end if;
		
		elif calculatedFastener = "Bolt" then
			a1_min[part] := (4 + abs(CosMax)) * d;
			
		elif calculatedFastener = "Dowel" then
			a1_min[part] := (3 + 2 * abs(CosMax)) * d;
		
		end if;
	
		# a2_min
		if calculatedFastener = "Nail" or (chosenFastener = "Screw" and calculateAsNail = "true") then
			if predrilled = "true" then
				a2_min[part] := (3 + abs(SinMax)) * d;
		
			else
				if rho_k[part] <= 420 * Unit('kg/m^3') then
					a2_min[part] := 5 * d;
		
				else
					a2_min[part] := 7 * d;
		
				end if;
			end if;
		elif calculatedFastener = "Bolt" then
			a2_min[part] := 4 * d;
		
		elif calculatedFastener = "Dowel" then
			a2_min[part] := 3 * d;
		
		end if;

		# a3t_min
		# burde vist a3t_min uansett, uavhengig av vinkel.

		# 8.3.1.2(5)
		if calculatedFastener = "Nail" or (chosenFastener = "Screw" and calculateAsNail = "true") then
			if predrilled = "true" then
				a3t_min[part] := (7 + 5 * abs(CosMax)) * d;
		
			else
				if rho_k[part] <= 420 * Unit('kg/m^3') then
					a3t_min[part] := (10 + 5 * abs(CosMax)) * d;
		
				else
					a3t_min[part] := (15 + 5 * abs(CosMax)) * d;
		
				end if;
			end if;
			
		elif calculatedFastener = "Bolt" or calculatedFastener = "Dowel" then
			a3t_min[part] := max(7 * d, 80 * Unit('mm'));
		
		end if;

		# reset values when not relevant
#		if not(alpha["max"] >= 270 * Unit('degree') or alpha["min"] <= 90 * Unit('degree')) then
#	 		a3t_min[part] := 0;
#		end if;


		# a3c_min
		if calculatedFastener = "Nail" or (chosenFastener = "Screw" and calculateAsNail = "true") then
			if predrilled = "true" then
				a3c_min[part] := 7 * d;
		
			else
				if rho_k[part] <= 420 * Unit('kg/m^3') then
					a3c_min[part] := 10 * d;
		
				else
					a3c_min[part] := 15 * d;
		
				end if;
			end if;

			# reset values when not relevant
#			if not(alpha["max"] >= 90 * Unit('degree') and alpha["min"] <= 270 * Unit('degree')) then
#				a3c_min[part] := 0
#			end if;
		
		elif calculatedFastener = "Bolt" then
		
#			if alpha["max"] >= 90 * Unit('degree') and alpha["min"] <= 150 * Unit('degree') then
				a3c_min[part] := max((1 + 6 * SinMax) * d, 4 * d)
#			elif alpha["max"] >= 150 * Unit('degree') and alpha["min"] <= 210 * Unit('degree') then
#				a3c_min[part] := 4 * d
#			elif alpha["max"] >= 210 * Unit('degree') and alpha["min"] <= 270 * Unit('degree') then
#				a3c_min[part] := max((1 + 6 * SinMax) * d, 4 * d)
#			else
#				a3c_min[part] := 0
#			end if;
			
		elif calculatedFastener = "Dowel" then
		
#			if alpha["max"] >= 90 * Unit('degree') and alpha["min"] <= 150 * Unit('degree') then
				a3c_min[part] := max(SinMax * d, 3 * d)
#			elif alpha["max"] >= 150 * Unit('degree') and alpha["min"] <= 210 * Unit('degree') then
#				a3c_min[part] := 3 * d
#			elif alpha["max"] >= 210 * Unit('degree') and alpha["min"] <= 270 * Unit('degree') then
#				a3c_min[part] := max(abs(SinMax) * d, 3 * d)
#			else
#				a3c_min[part] := 0
#			end if;
		else
			a3c_min[part] := 0
		end if;

		# setter avstand til venstre kant
		a3_min[part] := max(a3t_min[part], a3c_min[part]);

		# a4t_min
		if calculatedFastener = "Nail" or (chosenFastener = "Screw" and calculateAsNail = "true") then
			if predrilled = "true" then
				if d < 5 * Unit('mm') then
					a4t_min[part] := (3 + 2 * abs(SinMax)) * d;
		
				else
					a4t_min[part] := (3 + 4 * abs(SinMax)) * d;
		
				end if;
			else
				if rho_k[part] <= 420 * Unit('kg/m^3') then
					if d < 5 * Unit('mm') then
						a4t_min[part] := (5 + 2 * abs(SinMax)) * d;
		
					else
						a4t_min[part] := (5 + 5 * abs(SinMax)) * d;
		
					end if;
				else
					# a4t_min[part] := (15 + 5 * abs(SinMax)) * d
				end if;
			end if;
			
		elif calculatedFastener = "Bolt" or calculatedFastener = "Dowel" then
			a4t_min[part] := max((2 + 2 * abs(SinMax)) * d, 3 * d);
		
		end if;

		# vet ikke om det er hensiksmessig � nulle ut minimumskravene, bedre at vi beholder dem
#		if not(alpha["max"] >= 0 and alpha["min"] < 180 * Unit('degree')) then
#			a4t_min[part] := 0
#		end if;


		# a4c_min
		if calculatedFastener = "Nail" or (chosenFastener = "Screw" and calculateAsNail = "true") then
			if predrilled = "true" then
				a4c_min[part] := 3 * d;
		
			else
				if rho_k[part] <= 420 * Unit('kg/m^3') then
					a4c_min[part] := 5 * d;
		
				else
					a4c_min[part] := 7 * d;
		
				end if;
			end if;
			
		elif calculatedFastener = "Bolt" or calculatedFastener = "Dowel" then
			a4c_min[part] := 3 * d;
		
		end if;

		# vet ikke om det er hensiksmessig � nulle ut minimumskravene, bedre at vi beholder dem
#		if not(alpha["max"] >= 180 * Unit('degree') and alpha["min"] <= 360 * Unit('degree')) then
#			a4c_min[part] := 0
#		end if;
  
		# 8.7.2
		if chosenFastener = "Screw" and axiallyLoaded = "true" then
			if evalb(t[part] < 12 * d) then
				# Alert("axiallyLoaded skrue, t < 12*d");		# litt usikker p� om det er et krav eller noe annet som st�r i standarden
				comments[cat("872_", part)] := "8.7.2 axiallyLoaded skrue, t < 12*d ikke oppfylt"
			end if;
		
			a1_min[part] := max(a1_min[part], 7 * d);					
			a2_min[part] := max(a2_min[part], 5 * d);		
			a3c_min[part] := max(a3c_min[part], 10 * d);
			a3t_min[part] := max(a3t_min[part], 10 * d);
			a4c_min[part] := max(a4c_min[part], 4 * d);			
			a4t_min[part] := max(a4t_min[part], 4 * d);
						
		end if;
	end if;

	# check if Toothed Plate connection
	if WhateverYouNeed["calculations"]["structure"]["fastener"]["ToothedPlateActive"] = "true" then
		local dc, ToothedPlatetype;
		ToothedPlatetype := WhateverYouNeed["calculations"]["structure"]["fastener"]["ToothedPlatetype"];		
		dc := WhateverYouNeed["calculations"]["structure"]["fastener"]["ToothedPlatedc"];
		
		if member(ToothedPlatetype, {"C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8", "C9"}) then			
			a1_min[part] := max(a1_min[part], (1.2 + 0.3 * abs(CosMax)) * dc);
			a2_min[part] := max(a2_min[part], 1.2 * dc);
			a3c_min[part] := max(a3c_min[part], (0.9 + 0.6 * abs(SinMax)) * dc);
			a3t_min[part] := max(a3t_min[part], 2.0 * dc);
			a4t_min[part] := max(a4t_min[part], (0.6 + 0.2 * abs(SinMax)) * dc);
			a4c_min[part] := max(a4c_min[part], 0.6 * dc);

		elif member(ToothedPlatetype, {"C10", "C11"}) then
			a1_min[part] := max(a1_min[part], (1.2 + 0.8 * abs(CosMax)) * dc);
			a2_min[part] := max(a2_min[part], 1.2 * dc);
			a3c_min[part] := max(a3c_min[part], (0.9 + 0.6 * abs(SinMax)) * dc);
			a3t_min[part] := max(a3t_min[part], 2.0 * dc);
			a4t_min[part] := max(a4t_min[part], (0.6 + 0.2 * abs(SinMax)) * dc);
			a4c_min[part] := max(a4c_min[part], 0.6 * dc);
		end if;		
	end if;

	# run evalf on everything to get numbers
	# here we do run into a problem, as values are stored in strings, like a4c_min["1"]
	# we now have to change the way variables are stored, resembling the way it is stored in components
	# a4c_min["1"] -> a4c_min1

	variables := {"a1", "a2", "a3t", "a3c", "a4t", "a4c"};
	for j in variables do
		
		if j = "a1" then
			distance[cat("a1_min", part)] := a1_min[part] * red_steel;
					
		elif j = "a2" then
			distance[cat("a2_min", part)] := a2_min[part] * red_steel;
					
		elif j = "a3t" then
			distance[cat("a3t_min", part)] := a3t_min[part];
			
		elif j = "a3c" then
			distance[cat("a3c_min", part)] := a3c_min[part];
						
		elif j = "a4t" then
			distance[cat("a4t_min", part)] := a4t_min[part];
			
		elif j = "a4c" then
			distance[cat("a4c_min", part)] := a4c_min[part];
						
		end if;
	end do;

end proc:


calculate_amin_max := proc(WhateverYouNeed::table)
	description "calculates minimum distances regardless of alpha value";
	local calculatedFastener, chosenFastener, calculateAsNail, predrilled, d, rho_k;
	local a1_min_max, a1_min_min, a2_min_max, a2_min_min, a3_min_max, a3t_min_max, a3c_min_max, a4_min_max, a4t_min_max, a4c_min_max, t, h;
	local red_steel, structure, materialdataAll, sectiondataAll, warnings, comments, part, distance, serviceclass;

	# force::table
DEBUG();
	# global variables
	warnings := WhateverYouNeed["warnings"];
	structure := WhateverYouNeed["calculations"]["structure"];
	comments := WhateverYouNeed["calculations"]["comments"];
	sectiondataAll := WhateverYouNeed["sectiondataAll"];
	materialdataAll := WhateverYouNeed["materialdataAll"];
	calculatedFastener := WhateverYouNeed["calculatedvalues"]["fastenervalues"]["calculatedFastener"];
	chosenFastener := structure["fastener"]["chosenFastener"];
	calculateAsNail := structure["fastener"]["calculateAsNail"];
	predrilled := structure["fastener"]["predrilled"];

	# distance stores both minimumdistance and calculated distance values
	# reset of values is done in ReadComponentsSpecific
	if assigned(WhateverYouNeed["calculatedvalues"]["distance"]) then
		distance := WhateverYouNeed["calculatedvalues"]["distance"]
	else
		distance := table();
		WhateverYouNeed["calculatedvalues"]["distance"] := eval(distance)
	end if;
	
	# local variables
	a1_min_max := table();
	a1_min_min := table();		# used to define which fasteners that should be taken into account for calculation of a2 values in NODEFastenerPattern
	a2_min_max := table();
	a2_min_min := table();		# used to define which fasteners that should be taken into account for calculation of a1 values in NODEFastenerPattern
	a3_min_max := table();
	a3t_min_max := table();
	a3c_min_max := table();
	a4_min_max := table();
	a4t_min_max := table();
	a4c_min_max := table();
	
	d := structure["fastener"]["fastener_d"];

	rho_k := table();
	t := table();	
	h := table();

	for part in {"1", "2"} do
		if assigned(materialdataAll[part]["rho_k"]) then
			rho_k[part] := materialdataAll[part]["rho_k"]
		end if;
		if assigned(materialdataAll[part]["b"]) then
			t[part] := sectiondataAll[part]["b"]
		end if;
		if assigned(materialdataAll[part]["h"]) then
			h[part] := sectiondataAll[part]["h"]
		end if;
	end do;

	for part in {"1", "2"} do

		if structure["connection"][cat("connection", part)] = "Steel" then
			next
		end if;

		if structure["connection"][cat("connection", part)] = "Timber" and structure["connection"][cat("connection", part)] = "Timber" then
			red_steel := 1;
			if assigned(comments["red_steel"]) then
				comments["red_steel"] := evaln(comments["red_steel"])
			end if
		
		elif calculatedFastener = "Nail" or (chosenFastener = "Screw" and calculateAsNail = "true") then
			red_steel := 0.7;		# 8.3.1.4 reduction for a1 and a2 for fasteners between steel and timber
			comments["red_steel"] := "a1, a2 reduced to 70% according to 8.3.1.4";
		
		else # connections with bolts
			red_steel := 1;
			if assigned(comments["red_steel"]) then
				comments["red_steel"] := evaln(comments["red_steel"])
			end if
		
		end if;

		# need to reset some comments here
		if assigned(comments[cat("872_", part)]) then
			comments[cat("872_", part)] := evaln(comments[cat("872_", part)])
		end if;

  		if materialdataAll[part]["timbertype"] = "CLT" then
  	
  			if t[part] < 10 * d or h[part] < 10 * d then
  				Alert("CLT thickness < 10 * d", warnings, 3)
  			end if;

  			if t[part] < h[part] then		# fastener on lateral face of CLT element (Rothoblaas page 34, HBS screws)
  		
  				a1_min_max[part] := 4 * d;
  				a1_min_min[part] := 4 * d;
  				a2_min_max[part] := 2.5 * d;
  				a2_min_min[part] := 2.5 * d;
				a3t_min_max[part] := 6 * d;
				a3c_min_max[part] := 6 * d;			
				a4t_min_max[part] := 6 * d;
				a4c_min_max[part] := 2.5 * d;			
		
  			else							# fastener on narrow face of CLT
  		
  				a1_min_max[part] := 10 * d;
  				a1_min_min[part] := 10 * d;
  				a2_min_max[part] := 4 * d;
  				a2_min_min[part] := 4 * d;
				a3t_min_max[part] := 12 * d;
				a3c_min_max[part] := 7 * d;
				a4t_min_max[part] := 6 * d;
				a4c_min_max[part] := 3 * d;
		
  			end if;
  	
  		else		# glulam or general timber
  	
			# a1_min
			if calculatedFastener = "Nail" or (chosenFastener = "Screw" and calculateAsNail = "true") then
				if predrilled = "true" then
					a1_min_max[part] := (4 + 1) * d;
					a1_min_min[part] := (4 + 0) * d;
				else
					if rho_k[part] <= 420 * Unit('kg/m^3') and d < 5 * Unit('mm') then					
						a1_min_max[part] := (5 + 5) * d;
						a1_min_min[part] := (5 + 0) * d;
					elif rho_k[part] <= 420  * Unit('kg/m^3') and d >= 5 * Unit('mm') then
						a1_min_max[part] := (5 + 7) * d;
						a1_min_min[part] := (5 + 0) * d;
					else
						a1_min_max[part] := (7 + 8) * d;
						a1_min_min[part] := (7 + 0) * d;
					end if;
				end if;

			elif calculatedFastener = "Bolt" then
				a1_min_max[part] := (4 + 1) * d;
				a1_min_min[part] := (4 + 0) * d;
		
			elif calculatedFastener = "Dowel" then
				a1_min_max[part] := (3 + 2) * d;
				a1_min_min[part] := (3 + 0) * d;
		
			end if;
	
			# a2_min
			if calculatedFastener = "Nail" or (chosenFastener = "Screw" and calculateAsNail = "true") then
				if predrilled = "true" then
					a2_min_max[part] := (3 + 1) * d;
					a2_min_min[part] := (3 + 0) * d;
				else
					if rho_k[part] <= 420 * Unit('kg/m^3') then
						a2_min_max[part] := 5 * d;
						a2_min_min[part] := 5 * d;
					else
						a2_min_max[part] := 7 * d;
						a2_min_min[part] := 7 * d;
					end if;
				end if;
		
			elif calculatedFastener = "Bolt" then
				a2_min_max[part] := 4 * d;
				a2_min_min[part] := 4 * d;
		
			elif calculatedFastener = "Dowel" then
				a2_min_max[part] := 3 * d;
				a2_min_min[part] := 3 * d;
		
			end if;

			# a3t_min
			# 8.3.1.2(5)
			if calculatedFastener = "Nail" or (chosenFastener = "Screw" and calculateAsNail = "true") then
				if predrilled = "true" then
					a3t_min_max[part] := 12 * d
				else
					if rho_k[part] <= 420 * Unit('kg/m^3') then
						a3t_min_max[part] := 15 * d
					else
						a3t_min_max[part] := 15 * d
					end if;
				end if;
		
			elif calculatedFastener = "Bolt" or calculatedFastener = "Dowel" then
				a3t_min_max[part] := max(7 * d, 80 * Unit('mm'));
		
			end if;

			# a3c_min
			if calculatedFastener = "Nail" or (chosenFastener = "Screw" and calculateAsNail = "true") then
				if predrilled = "true" then
					a3c_min_max[part] := 7 * d
				else
					if rho_k[part] <= 420 * Unit('kg/m^3') then
						a3c_min_max[part] := 10 * d
					else
						a3c_min_max[part] := 15 * d
					end if;
				end if;

			elif calculatedFastener = "Bolt" then
				a3c_min_max[part] := 7 * d;
			
			elif calculatedFastener = "Dowel" then
				a3c_min_max[part] := 3 * d;

			end if;

			# a4t_min
			if calculatedFastener = "Nail" or (chosenFastener = "Screw" and calculateAsNail = "true") then
				if predrilled = "true" then
					if d < 5 * Unit('mm') then
						a4t_min_max[part] := 5 * d
					else
						a4t_min_max[part] := 7 * d
					end if;
				else
					if rho_k[part] <= 420 * Unit('kg/m^3') then
						if d < 5 * Unit('mm') then
							a4t_min_max[part] := 7 * d
						else
							a4t_min_max[part] := 10 * d
						end if;
					else
						# a4t_min[part] := (15 + 5 * abs(sin(alpha[part]))) * d
					end if;
				end if;
			
			elif calculatedFastener = "Bolt" or calculatedFastener = "Dowel" then
				a4t_min_max[part] := 4 * d

			end if;

			# a4c_min
			if calculatedFastener = "Nail" or (chosenFastener = "Screw" and calculateAsNail = "true") then
				if predrilled = "true" then
					a4c_min_max[part] := 4 * d
				else
					if rho_k[part] <= 420 * Unit('kg/m^3') then
						a4c_min_max[part] := 5 * d
					else
						a4c_min_max[part] := 7 * d
					end if;
				end if;
			
			elif calculatedFastener = "Bolt" or calculatedFastener = "Dowel" then
				a4c_min_max[part] := 3 * d

			end if;
  
			# 8.7.2
			if chosenFastener = "Screw" and WhateverYouNeed["calculatedvalues"]["axiallyLoaded"] = "true" then
				if evalb(t[part] < 12 * d) then
					# Alert("axiallyLoaded skrue, t < 12*d");		# litt usikker p� om det er et krav eller noe annet som st�r i standarden
					comments[cat("872_", part)] := "8.7.2 axiallyloaded screw, t < 12*d not fulfilled"
				end if;
		
				a1_min_max[part] := max(a1_min_max[part], 7 * d);		
				a2_min_max[part] := max(a2_min_max[part], 5 * d);
				a3c_min_max[part] := max(a3c_min_max[part], 10 * d);			
				a3t_min_max[part] := max(a3t_min_max[part], 10 * d);			
				a4c_min_max[part] := max(a4c_min_max[part], 4 * d);			
				a4t_min_max[part] := max(a4t_min_max[part], 4 * d);
			
			end if;
		
		end if;

		# check if Toothed Plate connection
		if WhateverYouNeed["calculations"]["structure"]["fastener"]["ToothedPlateActive"] = "true" then
			local dc, ToothedPlatetype;
			ToothedPlatetype := WhateverYouNeed["calculations"]["structure"]["fastener"]["ToothedPlatetype"];		
			dc := WhateverYouNeed["calculations"]["structure"]["fastener"]["ToothedPlatedc"];
		
			if member(ToothedPlatetype, {"C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8", "C9"}) then			
				a1_min_max[part] := max(a1_min_max[part], (1.2 + 0.3 * 1) * dc);
				a2_min_max[part] := max(a2_min_max[part], 1.2 * dc);
				a3c_min_max[part] := max(a3c_min_max[part], (0.9 + 0.6 * 1) * dc);
				a3t_min_max[part] := max(a3t_min_max[part], 2.0 * dc);
				a4t_min_max[part] := max(a4t_min_max[part], (0.6 + 0.2 * 1) * dc);
				a4c_min_max[part] := max(a4c_min_max[part], 0.6 * dc);

			elif member(ToothedPlatetype, {"C10", "C11"}) then
				a1_min_max[part] := max(a1_min_max[part], (1.2 + 0.8 * 1) * dc);
				a2_min_max[part] := max(a2_min_max[part], 1.2 * dc);
				a3c_min_max[part] := max(a3c_min_max[part], (0.9 + 0.6 * 1) * dc);
				a3t_min_max[part] := max(a3t_min_max[part], 2.0 * dc);
				a4t_min_max[part] := max(a4t_min_max[part], (0.6 + 0.2 * 1) * dc);
				a4c_min_max[part] := max(a4c_min_max[part], 0.6 * dc);
			end if;		
		end if;

		a3_min_max[part] := a3t_min_max[part];
	  	a4_min_max[part] := a4t_min_max[part];

		distance[cat("a1_min_max", part)] := a1_min_max[part] * red_steel;		
		distance[cat("a1_min_min", part)] := a1_min_min[part] * red_steel;		
		distance[cat("a2_min_max", part)] := a2_min_max[part] * red_steel;		
		distance[cat("a2_min_min", part)] := a2_min_min[part] * red_steel;
		distance[cat("a3t_min_max", part)] := a3t_min_max[part];
		distance[cat("a3c_min_max", part)] := a3c_min_max[part];
		distance[cat("a3_min_max", part)] := a3_min_max[part];
		distance[cat("a4t_min_max", part)] := a4t_min_max[part];			
		distance[cat("a4c_min_max", part)] := a4c_min_max[part];	
		distance[cat("a4_min_max", part)] := a4_min_max[part];
		
	end do;

	# check if minimum values for steel need to be checked as well, independent of grain direction
	if structure["connection"]["connection1"] = "Timber" and structure["connection"]["connection2"] = "Timber" then
		return
	else
		if structure["connection"]["connection1"] = "Timber" then
			serviceclass := WhateverYouNeed["materialdataAll"]["1"]["serviceclass"]
		elif structure["connection"]["connection2"] = "Timber" then
			serviceclass := WhateverYouNeed["materialdataAll"]["2"]["serviceclass"]
		end if;

		calculate_amin_steel(serviceclass, WhateverYouNeed);
	end if;

end proc:


PrintMinimumdistance := proc(part, WhateverYouNeed::table)
	description "Write minimumdistance to document";
	local j, variables, warnings, var, varmin, varmin_max, distance;

	warnings := WhateverYouNeed["warnings"];
	distance := WhateverYouNeed["calculatedvalues"]["distance"];

	if part = "steel" then		
		variables := {"a1", "a2", "a3", "a4"};
	else
		variables := {"a1", "a2", "a3t", "a3c", "a4t", "a4c"};
	end if;
	
	for j in variables do
		var := cat(substring(j, 1..2), part);			# a11, a1steel
		varmin := cat(j, "_min", part);				# a1_min, a1steel_min
		if part <> "steel" then
			varmin_max := cat(j, "_min_max", part);	
		end if;

		if ComponentExists(cat("TextArea_", varmin)) and assigned(distance[varmin]) then
			SetProperty(cat("TextArea_", varmin), value, round(convert(distance[varmin], 'unit_free')));
		end if;
		if ComponentExists(cat("TextArea_", varmin_max)) and assigned(distance[varmin_max]) then
			SetProperty(cat("TextArea_", varmin_max), value, round(convert(distance[varmin_max], 'unit_free')));
		end if;

		# check if current distance is bigger that minimumdistance
		if assigned(distance[var]) then
			if j = "a3c" or j = "a4c" then		# does not happen with steel
				if distance[varmin_max] > distance[cat(substring(j, 1..2), "t_min_max", part)] then
					next # next j
				end if;
			end if;
				
			if part <> "steel" and round(distance[var]) >= round(distance[varmin_max]) then
				SetProperty(cat("TextArea_", var), 'fillcolor', "green");

			elif part <> "steel" and round(distance[var]) <= round(distance[varmin_max]) and round(distance[var]) >= round(distance[varmin]) then
				SetProperty(cat("TextArea_", var), 'fillcolor', "DarkOrange");

			elif part = "steel" and round(distance[var]) >= round(distance[varmin]) then
				SetProperty(cat("TextArea_", var), 'fillcolor', "green");
			
			elif round(distance[var]) < round(distance[varmin]) then
				SetProperty(cat("TextArea_", var), 'fillcolor', "red");
				Alert(cat(var, ": distance below required minimumdistance"), warnings, 2);

			else
				SetProperty(cat("TextArea_", var), 'fillcolor', "black");
		
			end if;
		end if;
	end do
	
end proc:


calculate_amin_steel := proc(serviceclass::string, WhateverYouNeed::table)
	local steelcode, warnings, distance, t, d, d0, tolerance;

	warnings := WhateverYouNeed["warnings"];
	steelcode := WhateverYouNeed["materialdataAll"]["steel"]["steelcode"];
	# steelgrade := WhateverYouNeed["materialdataAll"]["steel"]["steelgrade"];	
	d := WhateverYouNeed["calculations"]["structure"]["fastener"]["fastener_d"];
	t := WhateverYouNeed["sectiondataAll"]["steel"]["b"];
	tolerance := max(2 * Unit('mm'), 0.1 * d);	# 10.4.3(1)
	d0 := d + tolerance;

	if assigned(WhateverYouNeed["calculatedvalues"]["distance"]) then
		distance := WhateverYouNeed["calculatedvalues"]["distance"]
	else
		distance := table();
		WhateverYouNeed["calculatedvalues"]["distance"] := eval(distance)
	end if;

	# minimum distances acc. NS-EN 1993-1-8, table 3.3
	distance["a1_minsteel"] := 2.2 * d0;	# p1
	distance["a2_minsteel"] := 2.4 * d0;	# p1
	distance["a3_minsteel"] := 1.2 * d0;	# e1
	distance["a4_minsteel"] := 1.2 * d0;	# e2

	distance["a1_min_maxsteel"] := 2.2 * d0;	# p1
	distance["a2_min_maxsteel"] := 2.4 * d0;	# p1
	distance["a3_min_maxsteel"] := 1.2 * d0;	# e1
	distance["a4_min_maxsteel"] := 1.2 * d0;	# e2

	if steelcode = "NS-EN 10025-5" then
		Alert("Minimum distances for steel code NS-EN 10025-5 not implemented", warnings, 1)
	else
		distance["a1_minsteel"] := min(distance["a1_minsteel"], 14 * t, 200 * Unit('mm'));
		distance["a2_minsteel"] := min(distance["a2_minsteel"], 14 * t, 200 * Unit('mm'));
		
		if serviceclass = "3" then
			distance["a3_minsteel"] := min(distance["a3_minsteel"], 4 * t + 40 * Unit('mm'));
			distance["a4_minsteel"] := min(distance["a4_minsteel"], 4 * t + 40 * Unit('mm'));
		end if;
		
	end if;

end proc: