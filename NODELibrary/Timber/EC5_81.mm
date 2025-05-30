# EC5_81.mm : Eurocode 5 chapter 8.1
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


# calculateShearplanes
# calculate_F_90R
# calculate_t_total
# EC5_812
# EC5_814
# EC5_814_NA_DE
# EC5_62net

calculateShearplanes := proc(WhateverYouNeed::table)
	description "Calculate number of shearplanes in connection";
	local structure, fastenervalues;

	structure := WhateverYouNeed["calculations"]["structure"];
	fastenervalues := WhateverYouNeed["calculatedvalues"]["fastenervalues"];
	
	fastenervalues["shearplanes"] := structure["connection"]["connectionInsideLayers"] + 1;

	# https://www.mapleprimes.com/questions/231829-Count-Number-Of-Elements-In-SearchAll#answer277964
	# snitt := numelems([SearchAll("-", connectiontype)]);
end proc:


calculate_t_total := proc(WhateverYouNeed::table)
	description "Calculate total thickness";
	local dummy, t, t_steel, t_total, numberOfLayers, eqnumberOfLayers, structure, sectiondataAll, plural, layer1, layer1out, layer2, layerSteel, tolerance,
		shearplanes, layerTolerance, connection, part;

	sectiondataAll := WhateverYouNeed["sectiondataAll"];
	structure := WhateverYouNeed["calculations"]["structure"];
	connection := structure["connection"];
	
	t := table();
	t["1"] := sectiondataAll["1"]["b"];
	t["2"] := sectiondataAll["2"]["b"];
	if connection["bout1"] <> "false" then
		t["1out"] := connection["bout1"];
	else
		t["1out"] := 0
	end if;
	t_steel := sectiondataAll["steel"]["b"];
	tolerance := connection["connectionInsideTolerance"];
	shearplanes := WhateverYouNeed["calculatedvalues"]["fastenervalues"]["shearplanes"];
	numberOfLayers := table();
	eqnumberOfLayers := table();
	
	layer1 := cat(convert(t["1"], 'unit_free'),"mm timber");	
	layer1out := cat(convert(t["1out"], 'unit_free'),"mm timber");
	cat(round(convert(t["1"], 'unit_free') / 2),"mm timber");
	layer2 := cat(convert(t["2"], 'unit_free'),"mm timber");
	layerSteel := cat(convert(t_steel, 'unit_free'),"mm steel");
	if tolerance > 0 then
		layerTolerance := cat(" + ", shearplanes, "*", convert(tolerance, 'unit_free'), "mm tolerance")
	else
		layerTolerance := ""
	end if;	
	
	if connection["connection1"] = "Timber" then		
					
		if connection["connectionInsideLayers"] = 0 then			
						
			if connection["connection2"] = "Timber" then	
				t_total := t["1"] + t["2"] + shearplanes * tolerance;
				numberOfLayers["1"] := 1;
				numberOfLayers["2"] := 1;
				numberOfLayers["steel"] := 0;
				dummy := cat(layer1, " + ", layer2, layerTolerance)
				
			elif connection["connection2"] = "Steel" then
				t_total := t["1"] + t_steel + shearplanes * tolerance;
				numberOfLayers["1"] := 1;
				numberOfLayers["2"] := 0;
				numberOfLayers["steel"] := 1;
				dummy := cat(layer1, " + ", layerSteel, layerTolerance)
				
			end if;
			
		else		#connection with more than one shearplane
			
			numberOfLayers["1"] := 2 + trunc(connection["connectionInsideLayers"] / 2);		# number of numberOfLayers in part 1
			
			if connection["connection2"] = "Timber" then	
				
				numberOfLayers["2"] := trunc(connection["connectionInsideLayers"] / 2) + 1;		# number of numberOfLayers in part 2
				numberOfLayers["steel"] := 0;

				# t_total
				if connection["bout1"] = "false" then
					t_total := numberOfLayers["1"] * t["1"] + numberOfLayers["2"] * t["2"] + shearplanes * tolerance;
				else
					t_total := 2 * t["1out"] + (numberOfLayers["1"] - 2) * t["1"] + numberOfLayers["2"] * t["2"] + shearplanes * tolerance;
				end if;

				# text
				if connection["connectionInsideLayers"] = 1 then					
					dummy := cat(layer1, " + ", layer2, " + ", layer1, layerTolerance)
				else
					if connection["bout1"] = "false" then
						dummy := cat(numberOfLayers["1"], "*", layer1, " + ", numberOfLayers["2"], "*", layer2, layerTolerance)
					else
						dummy := cat("2*", layer1out, " + ", numberOfLayers["1"]-2, "*", layer1, " + ", numberOfLayers["2"], "*", layer2, layerTolerance)						
					end if;
				end if;

			else	# steel inside
				
				numberOfLayers["2"] := 0;
				numberOfLayers["steel"] := trunc(connection["connectionInsideLayers"] / 2) + 1;		# number of steellayers in part 2

				# t_total
				if connection["bout1"] = "false" then					
					t_total := numberOfLayers["1"] * t["1"] + numberOfLayers["steel"] * t_steel + shearplanes * tolerance;
				else
					t_total := 2 * t["1out"] + (numberOfLayers["1"] - 2) * t["1"] + numberOfLayers["steel"] * t_steel + shearplanes * tolerance;
				end if;				

				# text
				if connection["connectionInsideLayers"] = 1 then					
					dummy := cat(layer1, " + ", layerSteel, " + ", layer1, layerTolerance)
				else
					if connection["bout1"] = "false" then
						dummy := cat(numberOfLayers["1"], "*", layer1, " + ", numberOfLayers["steel"], "*", layerSteel, layerTolerance)
					else
						dummy := cat("2*", layer1out, " + ", numberOfLayers["1"]-2, "*", layer1, " + ", numberOfLayers["steel"], "*", layerSteel, layerTolerance)						
					end if;
				end if;
			
			end if;
			
		end if;
		
	else		# steel outside, not more than 1 timber layer inside allowed
		numberOfLayers["1"] := 0;
		numberOfLayers["2"] := trunc(connection["connectionInsideLayers"] / 2) + 1;
		numberOfLayers["steel"] := 2 + trunc(connection["connectionInsideLayers"] / 2);		# number of numberOfLayers in part 1		
				
		t_total := t_steel * numberOfLayers["steel"] + t["2"] * numberOfLayers["2"] + shearplanes * tolerance;
		dummy := cat(layerSteel, " + ", layer2, " + ", layerSteel, layerTolerance)
		
	end if;

	if WhateverYouNeed["calculatedvalues"]["fastenervalues"]["shearplanes"] = 1 then
		plural := ""
	else
		plural := "s"
	end if;
	dummy := cat(WhateverYouNeed["calculatedvalues"]["fastenervalues"]["shearplanes"], " shearplane", plural, ": ",SubstituteAll(dummy, "1x", ""), " = ",convert(t_total, 'unit_free'), "mm");		# trenger ikke 1x
	SetProperty("TextArea_ConnectionBuildup", 'value', convert(dummy, string));

	for part in {"1", "2", "steel"} do
		if part = "1" then
			if connection["bout1"] = "false" then
				eqnumberOfLayers[part] := numberOfLayers[part]
			else
				eqnumberOfLayers[part] := (numberOfLayers[part] - 2) + 2 * (connection["bout1"] / sectiondataAll[part]["b"])	# virtual number of layers
			end if;
		else
			eqnumberOfLayers[part] := numberOfLayers[part]
		end if;
	end do;

	WhateverYouNeed["calculatedvalues"]["t_total"] := t_total;								# total thickness of connection without tolerance
	WhateverYouNeed["calculatedvalues"]["layers"] := eval(numberOfLayers);					# number of timber layers in connection
	WhateverYouNeed["calculatedvalues"]["eqnumberOfLayers"] := eval(eqnumberOfLayers);		# number of timber layers in connection
	
end proc:


calculate_F_90R := proc(WhateverYouNeed::table)
	description "Calculate splitting capacity according to 8.1.4";

	local warnings, F_90Rk, F_90Rd, part, dummy, t, t_, h, h_, h_e, gamma_M, k_mod, eqnumberOfLayers, w_, structure, materialdataAll,
		sectiondataAll, fastenervalues, h_e_side, k_r, n, i, h_i, activebeamside, distance, k_r_divisor, h_1, h_1_side, h_e_index, k_s,
		F_90Rd_NA_DE, a_r, t_ef_814_NA_DE;

	# local variables	
	structure := WhateverYouNeed["calculations"]["structure"];
	materialdataAll := WhateverYouNeed["materialdataAll"];
	sectiondataAll := WhateverYouNeed["sectiondataAll"];
	warnings := WhateverYouNeed["warnings"];
	fastenervalues := WhateverYouNeed["calculatedvalues"]["fastenervalues"];
	distance := WhateverYouNeed["calculatedvalues"]["distance"];
	t_ef_814_NA_DE := fastenervalues["t_ef_814_NA_DE"];		# 8.3.1.1(1), calculate_t

	F_90Rk := table();
	F_90Rd := table();	
	F_90Rd_NA_DE := table();
	k_r := table();		# NA DE, limtreboka page 250
	k_s := table();
	h_e := table();
	a_r := table();
	
	# 8.5
	if structure["connection"]["connection1"] = "Timber" and structure["connection"]["connection2"] = "Timber" then
		w_ := 1
	else
		h := sectiondataAll["steel"]["h"];
		w_ := max((convert(h, 'unit_free') / 100)^0.35, 1)
	end if;

	eqnumberOfLayers := WhateverYouNeed["calculatedvalues"]["eqnumberOfLayers"];

	# profile might not be active in connection, but is still defined (e.g. connection type 1 timber, but not used).
	# calculations might be wrong, should not be done with inactive types
	dummy := {"1", "2"};
	for part in dummy do
		if structure["connection"][cat("connection", part)] <> "Timber" then
			next
		end if;
		# calculate characteristic splitting capacity
		t := sectiondataAll[part]["b"];
		h := sectiondataAll[part]["h"];
		t_ := convert(t, 'unit_free');
		h_ := convert(h, 'unit_free');

		# beamside at which force points to is opposite of he distance side
		if NODEFastenerPattern:-BeamsideForceDirection(part, WhateverYouNeed) = "L" then
			h_e_side := "L";
			
		elif NODEFastenerPattern:-BeamsideForceDirection(part, WhateverYouNeed) = "R" then
			h_e_side := "R";
			
		# don't really know what to do if force is in graindirection
		elif NODEFastenerPattern:-BeamsideForceDirection(part, WhateverYouNeed) = "S" then
			h_e_side := "S";
			# Alert("F_90R: force in graindirection", warnings, 1);
			
		elif NODEFastenerPattern:-BeamsideForceDirection(part, WhateverYouNeed) = "E" then
			h_e_side := "E";
			# Alert("F_90R: force in graindirection", warnings, 1);
			
		end if;

		# standard EC, or norwegian NA
		if h_e_side = "L" or h_e_side = "R" then		
			activebeamside := h_e_side			
		else	# h_e_side is "S" or "E"			
			if distance["h_e"][cat(part, "L")] < distance["h_e"][cat(part, "R")] then
				activebeamside := "L"
			else 	
				activebeamside := "R"
			end if;			
		end if;

		if activebeamside = "L" then
			h_1_side := "R"
		elif activebeamside = "R" then
			h_1_side := "L"
		end if;

		h_e[part] := distance["h_e"][cat(part, activebeamside)];
		h_e_index := distance["h_e_index"][cat(part, activebeamside)];	# row index of h_e row
		h_1 := h_ - h_e[part];
		
		if structure["connection"][cat("connection", part)] = "Timber" then
			F_90Rk[part] := convert(evalf(14 * t_ * w_ * sqrt(h_e[part] / (1 - h_e[part] / h_))) * Unit('N'), 'units', 'kN') * eqnumberOfLayers[part];
		else
			F_90Rk[part] := 0
		end if;

		gamma_M := materialdataAll[part]["gamma_M"];
		k_mod := materialdataAll[part]["k_mod"];		
		
		F_90Rd[part] := eval(F_90Rk[part] * k_mod / gamma_M);

		# german NA, see limtreboka p. 250
		local fasteners, pointlist, j, f_t90d;
		# k_r
		n := numelems(distance["FastenersInRow"][part]);
		k_r_divisor := 0;
		for i from 1 to n do
			h_i := WhateverYouNeed["calculatedvalues"]["distance"]["FastenersInRowDistance"][part][cat(i, h_1_side)];
			k_r_divisor := k_r_divisor + (h_1 / h_i)^2
		end do;
		k_r[part] := eval(n / k_r_divisor);

		# k_s			distance between outermost fasteners of fastener with distance h_e		
		fasteners := WhateverYouNeed["results"]["FastenerGroup"]["Fasteners"];		
		f_t90d := WhateverYouNeed["materialdataAll"][part]["f_t90d"];
		pointlist := WhateverYouNeed["calculatedvalues"]["distance"]["FastenersInRow"][part][h_e_index];		# {1, 4, 7}
		a_r[part] := 0;
		if numelems(pointlist) = 1 then
			# 
		else
			for i from 1 to numelems(pointlist) do				
				for j from i to numelems(pointlist) do				
					if Student:-Precalculus:-Distance(fasteners[pointlist[i]], fasteners[pointlist[j]]) > a_r[part] then
						a_r[part] := Student:-Precalculus:-Distance(fasteners[pointlist[i]], fasteners[pointlist[j]]);
					end if;
				end do;
			end do;
		end if;

		k_s[part] := max(1, 0.7 + 1.4 * a_r[part] / h);
		
		if a_r[part] > h/2 and WhateverYouNeed["calculations"]["activesettings"]["calculate_814_NA_DE"] = "true" then 
			Alert(cat("8.1.4 NA DE: Beam ", part, ": a_r > h / 2"), warnings, -3);		# limtreboka p. 250, comment a_r
		end if;

		if h_e[part] / h_ < 0.2  and WhateverYouNeed["calculations"]["activesettings"]["calculate_814_NA_DE"] = "true" then
			if member(materialdataAll[part]["loaddurationclass"], {"Short-term", "Instantaneous"}) = false then
				Alert("8.1.4 NA DE: h_e / h < 0,2 - only loaddurationclass Short-term or Instantaneous allowed", warnings, -3)
			end if;
		end if;

		# calculating t_ef acc. limtreboka p. 251	
		
		F_90Rd_NA_DE[part] := k_s[part] * k_r[part] * (6.5 + 18 * h_e[part]^2 / h_^2) * (convert(t_ef_814_NA_DE[part], 'unit_free') * h_)^0.8 * f_t90d * 1 * Unit('mm^2');

		# printing
		if ComponentExists(cat("MathContainer_F_90Rd", part)) then
			SetProperty(cat("MathContainer_F_90Rd", part), 'value', round2(F_90Rd[part], 1));
		end if;

		if ComponentExists(cat("MathContainer_h_e", part)) then
			SetProperty(cat("MathContainer_h_e", part), 'value', round2(h_e[part] * Unit('mm'), 1));
		end if;

		if ComponentExists(cat("TextArea_h_e_side", part)) then
			SetProperty(cat("TextArea_h_e_side", part), 'value', h_e_side);
		end if;

		if ComponentExists(cat("TextArea_w", part)) then
			SetProperty(cat("TextArea_w", part), 'value', round2(w_, 2));
		end if;

		if ComponentExists(cat("TextArea_k_r", part)) then
			SetProperty(cat("TextArea_k_r", part), 'value', round2(k_r[part], 2));
		end if;

		if ComponentExists(cat("MathContainer_a_r", part)) then
			SetProperty(cat("MathContainer_a_r", part), 'value', round(a_r[part]));
		end if;

		if ComponentExists(cat("TextArea_k_s", part)) then
			SetProperty(cat("TextArea_k_s", part), 'value', round2(k_s[part], 2));
		end if;

		if ComponentExists(cat("MathContainer_t_ef_814_NA_DE", part)) then
			SetProperty(cat("MathContainer_t_ef_814_NA_DE", part), 'value', round2(t_ef_814_NA_DE[part], 2));
		end if;
		
		if ComponentExists(cat("MathContainer_F_90Rd_NA_DE", part)) then
			SetProperty(cat("MathContainer_F_90Rd_NA_DE", part), 'value', round2(convert(F_90Rd_NA_DE[part], 'units', 'kN'), 1));
		end if;
	end do;

	# if ComponentExists("TextArea_gamma_M") then
	#	SetProperty("TextArea_gamma_M", 'value', round2(gamma_M, 2))
	# end if;

	fastenervalues["F_90Rk"] := eval(F_90Rk);
	fastenervalues["F_90Rd"] := eval(F_90Rd);
	fastenervalues["F_90Rd_NA_DE"] := eval(F_90Rd_NA_DE);

	return h_e, a_r
	
end proc:


# need a complete rewrite of this check
# 1. loop through parts
# 2. calculate capacity in grain direction
# 2. loop through each fastener
# 3. get force in grain direction
# 4. calculate capacity of fastener


# checking capacity of forces in grain direction
EC5_812 := proc(WhateverYouNeed::table)
	description "8.1.2 Multiple fastener connections";
	local usedcode, comments, ForcesInConnection, part, alphaForce, alphaBeam, alpha, warnings, structure, k_n_ef0, F_vefRd, fastener, eta_n_ef, eta, etamax, 
		F_vEd, ind, val, dummy, fastenervalues, i, k_n_efa, firstrun_FvR, firstrun_ShearConnector, ShearConnector;

	warnings := WhateverYouNeed["warnings"];
	structure := WhateverYouNeed["calculations"]["structure"];	
	ForcesInConnection := WhateverYouNeed["results"]["FastenerGroup"]["ForcesInConnection"];
	fastenervalues := WhateverYouNeed["calculatedvalues"]["fastenervalues"];
	ShearConnector := structure["fastener"]["ShearConnector"];

	alpha := table();			# angle between force and grain direction
	eta_n_ef := table();		# reduction factor for fasteners in grain direction, dependent on force to grain
	F_vefRd := table();
	k_n_efa := table();

	# 8.8	No fastener calculated, capacity alpha dependent
	# 8.9 	Split ring and plate connector: capacity of fastener not taken into account, capacity alpha dependent
	# 8.10 	Toothed plate connector: capacity of shear connector and fastener added, capacity not dependent on alpha

	# precalculation of reduction factor for fasteners in grain direction
	for fastener from 1 to numelems(ForcesInConnection) do		# loop over fasteners

		F_vEd := ForcesInConnection[fastener][3];		# force in fastener
		alphaForce := ForcesInConnection[fastener][4];	# angle of force in fastener		

		# calculate alpha angles between force and grain, reduction factors
		for part in {"1", "2"} do
			
			if structure["connection"][cat("connection", part)] = "Timber" then
			
				alphaBeam := evalf(structure["connection"][cat("graindirection", part)]);
				alpha[part] := abs(alphaForce - alphaBeam);			# angle between force and grain direction in fastener

				# need to check that alpha[part] is between 0 - 90 deg.
				if alpha[part] > 180*Unit('arcdeg') then
					alpha[part] := alpha[part] - 180*Unit('arcdeg')

				elif alpha[part] > 90*Unit('arcdeg') then
					alpha[part] := 180*Unit('arcdeg') - alpha[part]

				end if;

				# reduction factor for fasteners in grain direction, dependent on force to grain
				eta_n_ef[part] := (90*Unit('arcdeg') - alpha[part]) / (90*Unit('arcdeg'));	# factor interpolation of angle		
				if eta_n_ef[part] > 1 or eta_n_ef[part] < 0 then			# this should not be possible
					Alert("EC5_812: impossible eta_n_ef: 0 > eta_n_ef > 1", warnings, 5)
				end if;
				
				k_n_ef0 := WhateverYouNeed["calculatedvalues"][cat("k_n_ef0", part)];	# reduction factor capacity in grain direction
				k_n_efa[part] := ((eta_n_ef[part] * k_n_ef0) + (1 - eta_n_ef[part]) * 1);				
				
			end if;
			
		end do;

		# calculation of capacity
		# optimization: F_vR for nails needs just to be calculated once (not alpha dependent), while
		# need to calculate F_vR for each fastener and each beam, because f_hk is defined for angle between force and grain direction
		# Capacity of some shear connectors is added with fasteners, some not

		firstrun_FvR := true;					# just relevant for nails, as they don't need to be calculated multiple times
		firstrun_ShearConnector := true;		# Toothed plate connectors

		for part in {"1", "2"} do

			if structure["connection"][cat("connection", part)] = "Timber" then

				# fasteners
				# check if we need to calculate F_vR or if we can get it from storage
				if (fastenervalues["calculatedFastener"] = "Nail" or structure["fastener"]["calculateAsNail"] = "true") and firstrun_FvR = false then
					# no need to calculate F_vR again

				else
					calculate_F_vR(WhateverYouNeed, alpha);		# EC5_82, capacity of fasteners
					firstrun_FvR := false
				end if;

				# ShearConnectors
				# check if we need to calculate F_vR_89_810 or if we can get it from storage
				if ShearConnector = "Toothed-plate" and firstrun_ShearConnector = false then
					# use stored values

				elif ShearConnector = "Toothed-plate" and firstrun_ShearConnector = true then
					calculate_F_vR_89_810(WhateverYouNeed, alpha[part]);
					firstrun_ShearConnector := false

				# 8.9 	Split ring and plate connector: capacity of fastener not taken into account, capacity alpha dependent
				elif ShearConnector = "Split ring" then					
					calculate_F_vR_89_810(WhateverYouNeed, alpha[part]);
					fastenervalues["F_vRk"] := 0;
					fastenervalues["F_vRd"] := 0;

				else
					fastenervalues["F_vRk_89_810"] := 0;
					fastenervalues["F_vRd_89_810"] := 0
				end if;

				# (8.1), we do not reduce the capacity of bulldogs for connections in a row, NTNU example does not do that (take full effect of connection)
				# (8.1) refers to 8.3.1.1(8) - nails, and 8.5.1.1(4) - bolts
				F_vefRd[part] := fastenervalues["F_vRd"] * k_n_efa[part] + fastenervalues["F_vRd_89_810"];		

				if F_vefRd[part] = 0 then
					eta := 9999
				else
					eta := F_vEd / F_vefRd[part];				
				end if;

				# found new maximum, set values
				if assigned(etamax) = false or eta > etamax then

					etamax := eta;

					# reset					
					for ind in {"a", "b", "c", "d", "e", "f", "g", "h", "j", "k", "l", "m"} do
						dummy := cat("MathContainer_F_vRk", ind);
						SetProperty(dummy, 'value', 0);
					end do;

					# write out values
					# https://www.mapleprimes.com/questions/232543-Tables-And-Indexing?sq=232543
					# https://www.mapleprimes.com/questions/234098-Loop-Over-Table
					for ind in indices(fastenervalues["F_vRk_ind"], 'nolist') do
						dummy := cat("MathContainer_F_vRk", ind);
						SetProperty(dummy, 'value', round2(convert(fastenervalues["F_vRk_ind"][ind], 'units', 'kN'), 1));
					end do;

					SetProperty("MathContainer_alpha_rope", 'value', fastenervalues["alpha_rope"]);
					SetProperty("MathContainer_F_vRk", 'value', round2(convert(fastenervalues["F_vRk"] + fastenervalues["F_vRk_89_810"], 'units', 'kN'), 1));		# including shearplanes
					SetProperty("MathContainer_F_vRd", 'value', round2(convert(fastenervalues["F_vRd"] + fastenervalues["F_vRd_89_810"], 'units', 'kN'), 1));
					SetProperty("MathContainer_F_vefRd", 'value', round2(convert(F_vefRd[part], 'units', 'kN'), 1));
					SetProperty("TextArea_FvRk_critNode", 'value', fastener);

					for i in {"1", "2"} do
						
						if assigned(k_n_efa[i]) then
							SetProperty(cat("TextArea_k_n_efa", i), 'value', round2(k_n_efa[i], 2));
						end if;

						dummy := cat("MathContainer_f_h0k", i);
						if ComponentExists(dummy) then
							SetProperty(dummy, 'value', round2(WhateverYouNeed["calculatedvalues"]["f_h0k"][i], 1))
						end if;	

						dummy := cat("MathContainer_f_hk", i);
						if ComponentExists(dummy) then
							SetProperty(dummy, 'value', round2(fastenervalues["f_hk"][i], 1))
						end if;	
						
					end do;

				end if;
				
			end if;
			
		end do;		

	end do;	

	if ComponentExists("TextArea_eta812_active") then
		if etamax > 1 then 
			SetProperty("TextArea_eta812_active", 'fontcolor', "Red");
		elif etamax > 0.9 then
			SetProperty("TextArea_eta812_active", 'fontcolor', "Orange");
		else
			SetProperty("TextArea_eta812_active", 'fontcolor', "Green");
		end if;
		SetProperty("TextArea_eta812_active", 'value', round2(etamax, 2));
	end if;


	usedcode := "8.1.2";
	comments := "Multiple fastener connections";
	
	return etamax, usedcode, comments;
	
end proc:
	

	#############################

#	for part in {"1", "2"} do		# loop over parts		

#		eta[part] := 0;
		
#		if structure["connection"][cat("connection", part)] = "Timber" then
			
#			alphaBeam := evalf(structure["connection"][cat("graindirection", part)]);
#			ForcesInConnection := WhateverYouNeed["results"]["FastenerGroup"]["ForcesInConnection"];
#			k_n_ef := WhateverYouNeed["calculatedvalues"][cat("k_n_ef0", part)];		# reduction factor capacity in grain direction

#			for fastener from 1 to numelems(ForcesInConnection) do		# loop over fasteners

#				F_vEd := ForcesInConnection[fastener][3];		# force in fastener
#				alphaForce := ForcesInConnection[fastener][4];	# angle of force in fastener		
#				alpha := abs(alphaForce - alphaBeam);			# angle between force and grain direction in fastener
#				if alpha > 90*Unit('arcdeg') then
#					alpha := 180*Unit('arcdeg') - alpha
#				end if;

#				eta_n_ef := (90*Unit('arcdeg') - alpha) / (90*Unit('arcdeg'));	# factor interpolation of angle
#				if eta_n_ef > 1 or eta_n_ef < 0 then			# this should not be possible
#					Alert("EC5_812: eta_n_ef > 1", 3, warnings)
#				end if;

#				F_vefRd := F_vRd(WhateverYouNeed, part, alpha) * ((eta_n_ef * k_n_ef) + (1 - eta_n_ef) * 1);		# (8.1)

#				etaFastener := F_vEd / F_vefRd;

#				if etaFastener > eta[part] then
					
#					eta[part] := etaFastener; 
					
#					if ComponentExists(cat("MathContainer_FvefRd", part)) then
#						SetProperty(cat("MathContainer_FvefRd", part), 'value', round2(F_vefRd, 1))
#					end if;
					
#				end if;

#			end do;	
			
#		end if;		
		
#	end do;



EC5_814 := proc(WhateverYouNeed::table)
	description "8.1.4 Connection forces at an angle to the grain";
	local F_90Rd, alpha, alphaForce, alphaBeam, F_hd, F_vd, F_Ed, F_vEd, activeloadcase, warnings,	part, eta, comments, usedcode, structure,
		f_814, eta_814_NA_DE, usedcode_NA_DE, comments_NA_DE, h_e, a_r, i, calculate_814_NA_DE;

	warnings := WhateverYouNeed["warnings"];
	structure := WhateverYouNeed["calculations"]["structure"];	
	activeloadcase := WhateverYouNeed["calculations"]["activesettings"]["activeloadcase"];
	F_hd := WhateverYouNeed["calculations"]["loadcases"][activeloadcase]["F_hd"];
	F_vd := WhateverYouNeed["calculations"]["loadcases"][activeloadcase]["F_vd"];
	f_814 := WhateverYouNeed["calculations"]["loadcases"][activeloadcase]["f_814"];		# reduction factor for force normal to grain (force to be split on two sides)

	h_e, a_r := calculate_F_90R(WhateverYouNeed);		# EC5_81, splitting capacity
	
	if f_814 < 0.5 or f_814 > 1 then
		Alert("wrong loadfactor f_8.1.4: 0,5 < f_8.1.4 < 1,0", warnings, 3);
	end if;
		
	eta := table();
	
	if F_hd = 0 and F_vd = 0 then		# special case where either everything is zero, or we just have moments on the connection
		alphaForce := 0;
	else
		alphaForce := arctan(convert(F_vd, 'unit_free'), convert(F_hd, 'unit_free')) * Unit('radians');
	end if;
	
	F_90Rd := WhateverYouNeed["calculatedvalues"]["fastenervalues"]["F_90Rd"];
	F_Ed := sqrt(F_vd ^ 2 + F_hd ^ 2) * f_814;
	
	for part in {"1", "2"} do
		
		if structure["connection"][cat("connection", part)] = "Timber" then
			
			alphaBeam := evalf(WhateverYouNeed["calculations"]["structure"]["connection"][cat("graindirection", part)]);
			alpha := alphaForce - alphaBeam;

			F_vEd := evalf(F_Ed * sin(alpha));	# force normal to graindirection
			eta[cat("814", part)] := abs(evalf(F_vEd  / F_90Rd[part]));

			if ComponentExists(cat("MathContainer_F_vEd", part)) then
				SetProperty(cat("MathContainer_F_vEd", part), 'value', round2(F_vEd, 1))
			end if;

			# if ComponentExists(cat("TextArea_eta814", part)) then
			#	SetProperty(cat("TextArea_eta814", part), 'value', round2(eta[part], 2))
			# end if;
			
		end if;		
		
	end do;

	# check according to german EC5_814_NA_DE
	calculate_814_NA_DE := WhateverYouNeed["calculations"]["activesettings"]["calculate_814_NA_DE"];
	if calculate_814_NA_DE = "true" then
		
		eta_814_NA_DE, usedcode_NA_DE, comments_NA_DE := EC5_814_NA_DE(WhateverYouNeed, h_e, a_r);
		
	else
		
		for part in {"1", "2"} do
			if ComponentExists(cat("TextArea_eta814_NA_DE", part)) then
				SetProperty(cat("TextArea_eta814_NA_DE", part), 'enabled', false);				
			end if;
		end do; 

		eta_814_NA_DE[0] := 0;
		
	end if;
	# cleanup of unneccessary error messages if check is not relevant
	if max(entries(eta_814_NA_DE)) = 0 then
		for i in indices(warnings, 'nolist') do
			if searchtext("8.1.4 NA DE:", warnings[i]) > 0 then
				warnings[i] := evaln(warnings[i])	# remove entry	
			end if;
		end do;
	end if;

	usedcode := "8.1.4";
	comments := "Connection forces at an angle to the grain";

	Write_eta(eta, table());

	if calculate_814_NA_DE = "true" then
		if max(entries(eta)) <=  max(entries(eta_814_NA_DE)) then		# take the least of the 2 maximum values (similar to 6.1.5)
			return max(entries(eta)), usedcode, comments
		else
			return max(entries(eta_814_NA_DE)), usedcode_NA_DE, comments_NA_DE
		end if;
	else
		return max(entries(eta)), usedcode, comments
	end if;
end proc:


EC5_814_NA_DE := proc(WhateverYouNeed::table, h_e::table, a_r::table)
	description "8.1.4 Connection forces at an angle to the grain, NA DE (german annex), limtreboka p. 249";
	local warnings, structure, activeloadcase, F_hd, F_vd, F_Ed, F_vEd, F_90Rd_NA_DE, f_814, part, alphaForce, alphaBeam, alpha, 
		sectiondataAll, h, eta, comments, usedcode;

	sectiondataAll := WhateverYouNeed["sectiondataAll"];
	warnings := WhateverYouNeed["warnings"];
	structure := WhateverYouNeed["calculations"]["structure"];	
	activeloadcase := WhateverYouNeed["calculations"]["activesettings"]["activeloadcase"];
	F_hd := WhateverYouNeed["calculations"]["loadcases"][activeloadcase]["F_hd"];
	F_vd := WhateverYouNeed["calculations"]["loadcases"][activeloadcase]["F_vd"];
	F_90Rd_NA_DE := WhateverYouNeed["calculatedvalues"]["fastenervalues"]["F_90Rd_NA_DE"];
	f_814 := WhateverYouNeed["calculations"]["loadcases"][activeloadcase]["f_814"];		# reduction factor for force normal to grain (force to be split on two sides)

	eta := table();
	
	if F_hd = 0 and F_vd = 0 then		# special case where either everything is zero, or we just have moments on the connection
		alphaForce := 0;
	else
		alphaForce := arctan(convert(F_vd, 'unit_free'), convert(F_hd, 'unit_free')) * Unit('radians');
	end if;

	F_Ed := sqrt(F_vd ^ 2 + F_hd ^ 2) * f_814;

	for part in {"1", "2"} do
		
		if structure["connection"][cat("connection", part)] = "Timber" then

			if assigned(h_e[part]) = false then				
				next
			end if;

			h := convert(sectiondataAll[part]["h"], 'unit_free');		

			alphaBeam := evalf(WhateverYouNeed["calculations"]["structure"]["connection"][cat("graindirection", part)]);
			alpha := alphaForce - alphaBeam;
			
			F_vEd := evalf(F_Ed * sin(alpha));	# force normal to graindirection
			F_90Rd_NA_DE := WhateverYouNeed["calculatedvalues"]["fastenervalues"]["F_90Rd_NA_DE"][part];
			
			if h_e[part] / h > 0.7 then		# not necessary to check

				eta[cat("814_NA_DE", part)] := 0;

			else
			
				if convert(a_r[part], 'unit_free')  / h > 1 and F_vEd > 0.5 * F_90Rd_NA_DE then
					Alert("8.1.4 NA DE: a_r / h > 1,0 and F_vEd > 0.5 * F_90Rd: connection too weak", warnings, 3)
				end if;		
			
				eta[cat("814_NA_DE", part)] := abs(evalf(F_vEd / F_90Rd_NA_DE));

			end if;

			if ComponentExists(cat("TextArea_eta814_NA_DE", part)) then
				SetProperty(cat("TextArea_eta814_NA_DE", part), 'enabled', true);
				# SetProperty(cat("TextArea_eta814_NA_DE", part), 'value', round2(eta[part], 2))
			end if;
		end if;		
		
	end do;

	usedcode := "8.1.4 NA DE";
	comments := "Connection forces at an angle to the grain, NA DE";

	Write_eta(eta, table());

	return eta, usedcode, comments;
end proc:


# section considered to be in tension
# effect from kh not taken into account
EC5_62net := proc(WhateverYouNeed::table)
	description "Check net area of section, simplified";
	local structure, sectiondataAll, d, bout1, Anet, part, eqnumberOfLayers, numberOfBolts, alphaBeam, activeloadcase, F_hd, F_vd, F_Ed, F_xEd, alphaForce,
		alpha, eta, f_t0d, usedcode, comments, fastener, intPointL, intPointR, fastenerPointlist, b, h, distance, yi, ind, I_d, I_d_part, Inet, FastenerGroup,
		eta_F, eta_M, M_yd1, f_c0d, kh, sigma_t0d, sigma_c0d, sigma_md, f_md, connection, tolerance, i,
		A_steel, f_yd, f_ud, N_plRd, N_uRd, M_cRd, dc, he, A_shearconnector, A_fastener, fastenervalues, shearplanes;

	structure := WhateverYouNeed["calculations"]["structure"];
	fastener := structure["fastener"];
	sectiondataAll := WhateverYouNeed["sectiondataAll"];
	d := fastener["fastener_d"];
	activeloadcase := WhateverYouNeed["calculations"]["activesettings"]["activeloadcase"];
	F_hd := WhateverYouNeed["calculations"]["loadcases"][activeloadcase]["F_hd"];
	F_vd := WhateverYouNeed["calculations"]["loadcases"][activeloadcase]["F_vd"];
	fastenerPointlist := WhateverYouNeed["calculatedvalues"]["graphicsElements"]["fastenerPointlist"];
	FastenerGroup := WhateverYouNeed["results"]["FastenerGroup"];
	distance := WhateverYouNeed["calculatedvalues"]["distance"];
	connection := structure["connection"];
	tolerance := 1 * Unit('mm');
	fastenervalues := WhateverYouNeed["calculatedvalues"]["fastenervalues"];
	shearplanes := fastenervalues["shearplanes"];
	
	bout1 := connection["bout1"];	

	if F_hd = 0 and F_vd = 0 then		# special case where either everything is zero, or we just have moments on the connection
		alphaForce := 0;
	else
		alphaForce := evalf(arctan(convert(F_vd, 'unit_free'), convert(F_hd, 'unit_free')) * Unit('radians'));
	end if;

	F_Ed := sqrt(F_vd ^ 2 + F_hd ^ 2);

	Anet := table();
	eta := table();
	eqnumberOfLayers := WhateverYouNeed["calculatedvalues"]["eqnumberOfLayers"];

	# Anet
	for part in {"1", "2"} do
		
		if structure["connection"][cat("connection", part)] = "Timber" then

			# 1. calculate or get section area, check if there is different thickness on outer parts
			# 2. deduct split ring / shear plate area
			# 3. deduct bolt size

			numberOfBolts := WhateverYouNeed["calculatedvalues"]["distance"]["a2_nFastenersInColumn"][part];

			# total area of ShearConnector area
			if fastener["ShearConnector"] = "Split ring" then
				dc := fastener["SplitRingdc"];
				he := fastenervalues["SplitRinghc"] / 2;
				A_shearconnector := dc * he * shearplanes * numberOfBolts
			else
				he := 0;
				A_shearconnector := 0
			end if;

			# Fastener
			A_fastener := eqnumberOfLayers[part] * (d + tolerance) * (sectiondataAll[part]["b"] - he) * numberOfBolts;
			
			# net section area
			Anet[part] := eqnumberOfLayers[part] * sectiondataAll[part]["A"] - A_shearconnector - A_fastener;

			if ComponentExists(cat("TextArea_Anet_gross", part)) then
				SetProperty(cat("TextArea_Anet_gross", part), 'value', round2(Anet[part] / (eqnumberOfLayers[part] * sectiondataAll[part]["A"]), 2))
			end if;
			
		elif structure["connection"][cat("connection", part)] = "Steel" then			

			A_steel := WhateverYouNeed["sectiondataAll"]["steel"]["A"];
			f_yd := WhateverYouNeed["materialdataAll"]["steel"]["f_yk"] / WhateverYouNeed["materialdataAll"]["steel"]["gamma_M0"];
			f_ud := WhateverYouNeed["materialdataAll"]["steel"]["f_uk"] / WhateverYouNeed["materialdataAll"]["steel"]["gamma_M2"];
			numberOfBolts := WhateverYouNeed["calculatedvalues"]["distance"]["a2_nFastenersInColumn"]["steel"];
			
			N_plRd := convert(eqnumberOfLayers["steel"] * A_steel * f_yd, 'units', 'kN');			# NS-EN 1993-1-1, (6.6)

			Anet["steel"] := eqnumberOfLayers["steel"] * (sectiondataAll["steel"]["A"] - numberOfBolts * (d + tolerance) * sectiondataAll["steel"]["b"]);

			N_uRd := convert(0.9 * Anet["steel"] * f_ud, 'units', 'kN');						# NS-EN 1993-1-1, (6.7)			

			WhateverYouNeed["calculatedvalues"]["N_plRd"] := N_plRd;
			WhateverYouNeed["calculatedvalues"]["N_uRd"] := N_uRd;

			if ComponentExists("MathContainer_N_plRd") then
				SetProperty("MathContainer_N_plRd", 'value', round2(N_plRd, 1))
			end if;

			if ComponentExists("MathContainer_N_uRd") then
				SetProperty("MathContainer_N_uRd", 'value', round2(N_uRd, 1))
			end if;
			
		end if;
		
	end do;

	# Inet
	
	# calculate largest I of bolt sections, to be subtracted from I gross
	I_d_part := table();
	
	for ind in indices(WhateverYouNeed["calculatedvalues"]["distance"]["a2_FastenersInColumn"], 'nolist') do		# "13"={3,4}, beam, index, {fasteners}

		if searchtext("steel", ind) > 0 then		# we also have steel fasteners in that list now, don't need them
			part := "steel"
		else
			part := substring(ind, 1);
		end if;
		
		b := sectiondataAll[part]["b"];
		h := sectiondataAll[part]["h"];		
		I_d := 0;

		for fastener in WhateverYouNeed["calculatedvalues"]["distance"]["a2_FastenersInColumn"][ind] do
			
			intPointL := cat("a_", convert(fastenerPointlist[fastener], string), "BLL", part);	# a_F1BLL1
			intPointR := cat("a_", convert(fastenerPointlist[fastener], string), "BLR", part);

			yi := h/2 - min(distance[intPointL], distance[intPointR]) * Unit('mm');		# distance from centerline of beam to fastener

			I_d := evalf(I_d + (b * d^3 / 12) + (yi^2 * b * d));
				
		end do;

		if assigned(I_d_part[part]) = false or I_d_part[part] < I_d then
			I_d_part[part] := I_d
		end if;
		
	end do;

	# calculate Inet
	Inet := table();
	for part in {"1", "2"} do
		
		if structure["connection"][cat("connection", part)] = "Timber" then

			Inet[part] := eqnumberOfLayers[part] * (sectiondataAll[part]["I_y"] - I_d_part[part]);

			if ComponentExists(cat("TextArea_Inet_gross", part)) then
				SetProperty(cat("TextArea_Inet_gross", part), 'value', round2(Inet[part] / (eqnumberOfLayers[part] * sectiondataAll[part]["I_y"]), 2))
			end if;

		else
			
			Inet["steel"] := eqnumberOfLayers["steel"] * (sectiondataAll["steel"]["I_y"] - I_d_part["steel"]);
			
		end if
		
	end do;

	WhateverYouNeed["calculatedvalues"]["Anet"] := Anet;
	WhateverYouNeed["calculatedvalues"]["Inet"] := Inet;

	# eta
	for i in {"1", "2"} do
		
		if structure["connection"][cat("connection", i)] = "Timber" then
			part := i
		else
			part := "steel"
		end if;
			
		WhateverYouNeed["materialdata"] := WhateverYouNeed["materialdataAll"][part];
		WhateverYouNeed["sectiondata"] := WhateverYouNeed["sectiondataAll"][part];			
			
		alphaBeam := evalf(WhateverYouNeed["calculations"]["structure"]["connection"][cat("graindirection", part)]);
		alpha := alphaForce - alphaBeam;

		F_xEd := evalf(F_Ed * cos(alpha));							# force in graindirection
		M_yd1 := FastenerGroup["ForcesInCenterofFastener"][3];
		h := sectiondataAll[part]["h"];
			
		if ComponentExists(cat("MathContainer_F_xEd", part)) then
			SetProperty(cat("MathContainer_F_xEd", part), 'value', round2(F_xEd, 1))
		end if;

		if structure["connection"][cat("connection", part)] = "Timber" then

			if GetProperty(cat("ComboBox_Anet_pargrain", part), value) = "f t,0,d" then
				f_t0d := WhateverYouNeed["materialdataAll"][part]["f_t0d"];					# section considered to be in tension
				sigma_t0d := F_xEd / Anet[part];				
				
				# in connections with multiple slotted-in steel plates and dowels, need to calculate kh with full section
				if part = "1" and structure["connection"]["connection2"] = "Steel" then
					WhateverYouNeed["sectiondata"] := table(WhateverYouNeed["sectiondataAll"][part]);		# eval(table) does not break the link, need to create a new table
					WhateverYouNeed["sectiondata"]["b"] := WhateverYouNeed["calculatedvalues"]["t_total"];	# new value for b
					kh := NODETimberEN1995:-kh("f_t0d", WhateverYouNeed);
					WhateverYouNeed["sectiondata"] := WhateverYouNeed["sectiondataAll"][part];				# reset to original state
				else
					kh := NODETimberEN1995:-kh("f_t0d", WhateverYouNeed);
				end if;								
				
				eta_F:= abs(evalf(sigma_t0d / (f_t0d * kh)));		# 6.2.3
				
			else	# f_c0d, timber in compression
				
				f_c0d := WhateverYouNeed["materialdataAll"][part]["f_c0d"];		# section considered to be in compression
				sigma_c0d := F_xEd / Anet[part];
				eta_F:= abs(evalf(sigma_c0d / f_c0d)^2)
				
			end if;

			sigma_md := abs(M_yd1 / (Inet[part] / (h/2)));
			f_md := WhateverYouNeed["materialdataAll"][part]["f_md"];
			kh := NODETimberEN1995:-kh("h", WhateverYouNeed);
			eta_M := sigma_md / (f_md * kh);	
			
		else	# steel plate

			eta_F := abs(F_xEd / min(N_plRd, N_uRd));

			M_cRd := f_yd * Inet[part] / (h/2);
			eta_M := abs(M_yd1 / M_cRd)
			
		end if;

		eta[cat("62net", part)] := eta_F + eta_M;
			
	end do;
	
	usedcode := "6.2net";
	comments := "EC 6.2, check net section";

	Write_eta(eta, table());		# eta, comments

	return max(entries(eta)), usedcode, comments;
	
end proc:


# this one should be moved into the steel library
BoltandSteelCapacity := proc(WhateverYouNeed::table)
	description "Bolt Shear capacity acc. NS-EN 1993-1-8:2005+NA:2009, table 3.4";
	local fastenervalues, structure, F_vRd, F_bRd, alpha_v, f_ub, A, gamma_M2, d, eqnumberOfLayers, t, f_u, alpha_b, tolerance, d0, p1, p2, e1, e2, alpha_d, k1, calculatedvalues, usedcode, comments,
		maxFindex, ForcesInConnection, F_vEd, eta;

	calculatedvalues := WhateverYouNeed["calculatedvalues"];
	eqnumberOfLayers := WhateverYouNeed["calculatedvalues"]["eqnumberOfLayers"];
	usedcode := "EC3 3.6.1";
	comments := "EC3, steel bolt shear and bearing resistance";

	if assigned(eqnumberOfLayers["steel"]) = false or eqnumberOfLayers["steel"] = 0 then
		WhateverYouNeed["calculatedvalues"]["F_vRd_bolt"] := evaln(WhateverYouNeed["calculatedvalues"]["F_vRd_bolt"]);
		WhateverYouNeed["calculatedvalues"]["F_bRd_steel"] := evaln(WhateverYouNeed["calculatedvalues"]["F_bRd_steel"]);
		return 0, usedcode, comments;
	end if; 
	
	structure := WhateverYouNeed["calculations"]["structure"];	
	fastenervalues := calculatedvalues["fastenervalues"];	
	d := structure["fastener"]["fastener_d"];
	gamma_M2 := 1.25; 		# NS-EN 1993-1-8:2005+NA:2009

	maxFindex := WhateverYouNeed["results"]["FastenerGroup"]["maxFindex"];
	ForcesInConnection := WhateverYouNeed["results"]["FastenerGroup"]["ForcesInConnection"];
	F_vEd := ForcesInConnection[maxFindex][3];

	eta := table();
		
	# shear resistance single shear plane, NS-EN 1993-1-8:2005+NA:2009, table 3.4
	A := evalf(d^2 * Pi / 4);
	alpha_v := 0.6;		# assume bolt quality 4.6, 5.6, 8.8 or shear plane in unthreaded part of screw or bolt
	if type(fastenervalues["f_uk"], 'with_unit') and fastenervalues["f_uk"] > 0 then
		f_ub := fastenervalues["f_uk"];
	else
		f_ub := 0
	end if;

	if structure["connection"]["connection1"] = "Timber" then
		if eqnumberOfLayers["steel"] = 1 then
			F_vRd := evalf(eqnumberOfLayers["steel"] * alpha_v * f_ub * A / gamma_M2)	# timber - steel connection
		else
			F_vRd := evalf(2 * eqnumberOfLayers["steel"] * alpha_v * f_ub * A / gamma_M2)	# e.g. 3 inner layers of steel -> 3 * 2 shear planes
		end if;
		
	elif structure["connection"]["connection1"] = "Steel" then
		if eqnumberOfLayers["steel"] <= 2 then
			F_vRd := evalf(eqnumberOfLayers["steel"] * alpha_v * f_ub * A / gamma_M2)	# timber - steel connection
		else
			F_vRd := 0;		# should not be possible
		end if;
	else
		F_vRd := 0;			# should not be possible
	end if;
	F_vRd := convert(F_vRd, 'units', 'kN');	
	
	if F_vRd <> 0 then
		eta["F_vRd"]:= F_vEd / F_vRd;
	else
		eta["F_vRd"]:= 0			# f_ub missing
	end if;

	# bearing resistance of steel part
	tolerance := max(2 * Unit('mm'), 0.1 * d);	# 10.4.3(1)
	d0 := d + tolerance;	
	p1 := calculatedvalues["distance"]["a1_minsteel"];
	p2 := calculatedvalues["distance"]["a2_minsteel"];
	e1 := calculatedvalues["distance"]["a3_minsteel"];
	e2 := calculatedvalues["distance"]["a4_minsteel"];
	t := WhateverYouNeed["sectiondataAll"]["steel"]["b"];
	f_u := WhateverYouNeed["materialdataAll"]["steel"]["f_uk"];
	
	alpha_d := min(e1 / (3 * d0), p1 / (3 * d0) - 1 / 4);		# in force direction, both end and inner screws

	k1 := min(2.8 * e2 / d0 - 1.7, 1.4 * p2 / d0 -1.7, 2.5);	# normal to force direction, both screws along edge and inner screws
	
	alpha_b := min(alpha_d, f_ub / f_u, 1.0);		# table 3.4
	
	F_bRd := convert(evalf(eqnumberOfLayers["steel"] * k1 * alpha_b * f_u * d * t / gamma_M2), 'units', 'kN');

	if F_bRd > 0 then
		eta["F_bRd"]:= F_vEd / F_bRd;
	else
		eta["F_bRd"]:= 0		# f_ub probably undefined
	end if;

	WhateverYouNeed["calculatedvalues"]["F_vRd_bolt"] := F_vRd;
	WhateverYouNeed["calculatedvalues"]["F_bRd_steel"] := F_bRd;

	if ComponentExists("MathContainer_F_vRd_bolt") then
		SetProperty("MathContainer_F_vRd_bolt", 'value', round(F_vRd))
	end if;
	if ComponentExists("MathContainer_F_bRd_steel") then
		SetProperty("MathContainer_F_bRd_steel", 'value', round(F_bRd))
	end if;

	return max(entries(eta)), usedcode, comments;

end proc: