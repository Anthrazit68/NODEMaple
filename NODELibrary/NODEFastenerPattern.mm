# NODEFastenerPattern.mm : calculation of geometry and forces in fasteners
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

# https://mechanicalc.com/calculators/bolt-pattern-force-distribution/

CalculateForcesInConnection := proc(WhateverYouNeed::table)
	description "Calculation of inplane forces";
	local calculations, activesettings, ForcesInConnection, maxFindex, FastenerGroup, pointList, loadVector, load, centerOfFasteners, centerOfForce,
		 loadcase, force, warnings, layout, activeFastenerPattern;

	calculations := WhateverYouNeed["calculations"];	
	activesettings := calculations["activesettings"];	
	warnings := WhateverYouNeed["warnings"];
	loadcase := activesettings["activeloadcase"];
	activeFastenerPattern := activesettings["activeFastenerPattern"];
	force := eval(calculations["loadcases"][loadcase]);

	FastenerGroup := table();

	EnableComponentsmaxF("deactivate");

	# calculate forces on fasteners, get index of fastener with largest force

	# fastener pattern, calculation of fastener coordinates
	
	layout, pointList := GetPointlist(WhateverYouNeed);	# returns list of points
	if MASTERALARM(WhateverYouNeed["warnings"]) = true then
		return
	end if;
	
	if numelems(eval(pointList)) = 0 then
		Alert("Error: Pointlist has no elements", warnings, 5);
		return
	end if;
	centerOfFasteners := PointlistGetCenter(pointList);			# calculate coordinates of center of bolt group, Vector[column]
	centerOfForce := Vector(2, [eval(force["loadcenter_x"]), eval(force["loadcenter_y"])]);

	FastenerGroup["Fasteners"] := pointList;
	FastenerGroup["CenterOfFasteners"] := centerOfFasteners;
	FastenerGroup["CenterOfForce"] := centerOfForce;

	# forces on connection
	# loadVector := Vector(3, [force["F_hd"], force["F_vd"], force["M_yd"]]);	# Vector[column]
	loadVector := Vector(3, [eval(force["F_hd"]), eval(force["F_vd"]), eval(force["M_yd"])]);	# need to eval due to bug when using values from storesettings

	if WhateverYouNeed["calculations"]["structure"]["FastenerPatterns"][activeFastenerPattern]["reactionforces"] = "true" then			# calculate reaction forces instead of action forces
		loadVector := loadVector *~ (-1)
	end if;
	
	load := EccentricMoment(loadVector, centerOfFasteners, centerOfForce);			# calculate load in center of bolt group, Vector[column]
	
	if ComponentExists("TextArea_M_yd1") and WhateverYouNeed["calculations"]["calculatingAllLoadcases"] = false then
		SetProperty("TextArea_M_yd1", 'value', round2(convert(load[3], 'unit_free'), 2))
	end if;
	
	ForcesInConnection := ForcesInPoint(load, pointList, centerOfFasteners, warnings);	# list of forces in every fastener node / Fh, Fv, Fres, alpha
	maxFindex := maxFIndexFastener(ForcesInConnection);

	FastenerGroup["ForcesInConnection"] := ForcesInConnection;
	FastenerGroup["maxFindex"] := maxFindex;		
	FastenerGroup["ForcesInCenterofFastener"] := load;
			
	WhateverYouNeed["results"]["FastenerGroup"] := FastenerGroup;
		
	# write out calculated values
	if ComponentExists("MathContainer_Fx") and ComponentExists("MathContainer_Fy") and ComponentExists("MathContainer_F")
		and ComponentExists("MathContainer_alpha") and ComponentExists("TextArea_x") and ComponentExists("TextArea_y")
		and ComponentExists("TextArea_activeloadcase") and ComponentExists("TextArea_criticalnodeCurrentloadcase")
		and WhateverYouNeed["calculations"]["calculatingAllLoadcases"] = false then
			
		SetProperty("MathContainer_Fx", 'value', round2(ForcesInConnection[maxFindex][1], 2));
		SetProperty("MathContainer_Fy", 'value', round2(ForcesInConnection[maxFindex][2], 2));
		SetProperty("MathContainer_F", 'value', round2(ForcesInConnection[maxFindex][3], 2));
		SetProperty("MathContainer_alpha", 'value', round2(ForcesInConnection[maxFindex][4], 2));
		SetProperty("TextArea_x", 'value', round2(FastenerGroup["Fasteners"][maxFindex][1], 2));
		SetProperty("TextArea_y", 'value', round2(FastenerGroup["Fasteners"][maxFindex][2], 2));
		SetProperty("TextArea_currentloadcase", 'value', GetProperty("TextArea_activeloadcase", value));
		SetProperty("TextArea_criticalnodeCurrentloadcase", 'value', maxFindex);
	end if;

	# SetComponentsCriticalLoadcase("deactivate", WhateverYouNeed); # 

	WhateverYouNeed["results"]["FastenerGroup"] := FastenerGroup;
end proc:


ModifyFastenerPattern := proc(action::string, WhateverYouNeed::table)
	description "Add, delete or modify loadcase";
	local calculations, activesettings, i, layout, activeFastenerPattern, layoutnames, pointList, structure, warnings, compvariable, check_calculations, FastenerPatterns;

	calculations := WhateverYouNeed["calculations"];	
	activesettings := calculations["activesettings"];	
	structure := WhateverYouNeed["calculations"]["structure"];
	warnings := WhateverYouNeed["warnings"];
	
	activeFastenerPattern := GetProperty("TextArea_activeFastenerPattern", value);
	FastenerPatterns := structure["FastenerPatterns"];		
	check_calculations := WhateverYouNeed["componentvariables"]["var_calculations"];	# set

	if action = "AddFastenerPattern" then
		if activeFastenerPattern <> "" then
			layout, pointList := GetPointlist(WhateverYouNeed);	# returns list of points
			layout["name"] := activeFastenerPattern;
			FastenerPatterns[activeFastenerPattern] := eval(layout);
		else
			Alert(cat("Missing fastener pattern layout name ", activeFastenerPattern), warnings, 1);
			return
		end if;
		
	elif action = "SelectFastenerPattern" or action = "DeleteFastenerPattern" then
		if action = "DeleteFastenerPattern" then
			if numelems(GetProperty("ComboBox_FastenerPatterns", 'itemList')) > 1 then
				FastenerPatterns[GetProperty("ComboBox_FastenerPatterns", value)] := evaln(FastenerPatterns[GetProperty("ComboBox_FastenerPatterns", value)]);			# evaln: delete member in table
				SetProperty("ComboBox_FastenerPatterns", 'selectedindex', 0)
			else
				Alert("Last element can't be deleted", warnings, 1);
			end if;	
		end if;
		activeFastenerPattern := GetProperty("ComboBox_FastenerPatterns", value);
		SetProperty("TextArea_activeFastenerPattern", 'value', activeFastenerPattern);
		for compvariable in indices(eval(FastenerPatterns[activeFastenerPattern]), 'nolist') do
			check_calculations := WriteValueToComponent(compvariable, eval(FastenerPatterns[activeFastenerPattern][compvariable]), check_calculations)
		end do;
		NODEFastenerPattern:-SetVisibilityFastenerPattern();			# might be needed after XMLImport
	end if;

	# write out to Combobox
	layoutnames := {};
	for i from 1 to numelems(FastenerPatterns) do
		layoutnames := layoutnames union {indices(FastenerPatterns, 'nolist')[i]}
	end do;

	if numelems(FastenerPatterns) > 0 then
		SetProperty("ComboBox_FastenerPatterns", 'itemList', layoutnames);
		for i from 1 to numelems(layoutnames) do
			if layoutnames[i] = activeFastenerPattern then
				SetProperty("ComboBox_FastenerPatterns", 'selectedindex', i-1)
			end if;
		end do;
	end if;

	activesettings["activeFastenerPattern"] := activeFastenerPattern;
end proc:


PlotResults := proc(WhateverYouNeed::table)
	uses plots, plottools;
	description "Plot results of calculation";
	local structure, i, displayForceVectors, fastener, fasteners, fastenervalues, fastenerPointlist, results, scalefactor, r, len, alpha, geometryList, graphicsElements, warnings,
		sectiondataAll, h, beamBoundarylines, annotations_a, annotations, x, y, lengthleft, lengthright, angleleft, angleright, beams, clr, beamPoints, minimumangle,
		plotitems, beamnumber, displayBlockShear, cutleft, cutright, part, deltaangle;

	warnings := WhateverYouNeed["warnings"];
	structure := WhateverYouNeed["calculations"]["structure"];
	graphicsElements := table();
	WhateverYouNeed["calculatedvalues"]["graphicsElements"] := graphicsElements;		# stores beamBoundarylines, etc.
	minimumangle := 15 * Unit('degree');
	geometryList := [];	# list of geometry elements to be plotted
	# displayPoints := [];
	fastenerPointlist := [];

	if assigned(WhateverYouNeed["calculations"]["structure"]["fastener"]["fastener_d"]) then
		r := round(convert(WhateverYouNeed["calculations"]["structure"]["fastener"]["fastener_d"], 'unit_free') / 2)		# need to convert to posint, diameter to radius
	else
		r := 20
	end if;

	# dummylength := 100;		# if length is not provided we need to use a temporary distance

	# one can either use the geometry or the plot package

	if MASTERALARM(warnings) = false then

		results := WhateverYouNeed["results"]["FastenerGroup"]["ForcesInConnection"];			
		fastener := WhateverYouNeed["calculations"]["structure"]["fastener"];
		fasteners := WhateverYouNeed["results"]["FastenerGroup"]["Fasteners"];
		fastenervalues := WhateverYouNeed["calculatedvalues"]["fastenervalues"];
		sectiondataAll := WhateverYouNeed["sectiondataAll"];

		scalefactor := GetProperty("Slider_scalefactor", value);

		# pointplot works with units, textplot doesn't
		# https://www.mapleprimes.com/questions/234265-Textplot-With-Units?sq=234265

		# points
		
		# CenterOfFasteners
		# CenterOfForce			
		# https://mapleprimes.com/questions/236156-Convert-In-Nested-Lists?reply=reply
		geometry:-point(CenterOfFasteners, convert~(convert(WhateverYouNeed["results"]["FastenerGroup"]["CenterOfFasteners"], list), 'unit_free'));
		geometry:-point(CenterOfForce, convert~(convert(WhateverYouNeed["results"]["FastenerGroup"]["CenterOfForce"], list), 'unit_free'));
		geometryList := [op(geometryList), CenterOfFasteners('symbol' = 'cross', 'color' = "SteelBlue", 'symbolsize' = 30)];
		geometryList := [op(geometryList), CenterOfForce('symbol' = 'diagonalcross', 'color' = "Red", 'symbolsize' = 30)];
					
		# displayPoints := [pointplot(convert~(WhateverYouNeed["results"]["FastenerGroup"]["CenterOfFasteners"], 'unit_free'), symbol = 'cross', 'color' = "SteelBlue", 'symbolsize' = 30), 
		#	pointplot(convert~(WhateverYouNeed["results"]["FastenerGroup"]["CenterOfForce"], 'unit_free'), symbol = 'diagonalcross', 'color' = "Red", 'symbolsize' = 30, 'scaling' = constrained)];

		# Fasteners
		for i from 1 to numelems(fasteners) do
			geometry:-point(parse(cat("F", i)), convert~(convert(fasteners[i], list), 'unit_free'));
			fastenerPointlist := [op(fastenerPointlist), parse(cat("F", i))];
			if assigned(WhateverYouNeed["calculations"]["structure"]["fastener"]["fastener_d"]) = false then										
				geometryList := [op(geometryList), parse(cat("F", i))('symbol' = 'solidcircle', 'color' = "SteelBlue", 'symbolsize' = r)];
			else										
				geometry:-circle(parse(cat("fastener", i)), [parse(cat("F", i)), r], 'centername' = parse(cat("F", i)));
				geometryList := [op(geometryList), parse(cat("fastener", i))('color' = "Black", 'filled' = true)];
			end if;

			# Shear Connectors
			if fastener["ShearConnector"] = "Toothed-plate" then
				# outer circle
				geometry:-circle(parse(cat("fastener", i,"_bulldogo")), [parse(cat("F", i)), convert(fastener["ToothedPlatedc"] / 2, 'unit_free')]);
				geometryList := [op(geometryList), parse(cat("fastener", i,"_bulldogo"))('color' = "Niagara DarkOrchid", 'linestyle' = "dash")];
				# inner circle				
				geometry:-circle(parse(cat("fastener", i,"_bulldogi")), [parse(cat("F", i)), convert(fastenervalues["ToothedPlated1"] / 2, 'unit_free')]);
				geometryList := [op(geometryList), parse(cat("fastener", i,"_bulldogi"))('color' = "Niagara DarkOrchid", 'linestyle' = "dash")];

			elif fastener["ShearConnector"] = "Split ring" then
				# outer circle
				geometry:-circle(parse(cat("fastener", i,"_bulldogo")), [parse(cat("F", i)), convert(fastener["SplitRingdc"] / 2, 'unit_free')]);
				geometryList := [op(geometryList), parse(cat("fastener", i,"_bulldogo"))('color' = "Niagara DarkOrchid", 'linestyle' = "dash")];
			end if;
			
		end do;
		graphicsElements["fastenerPointlist"] := fastenerPointlist;
		
		#if assigned(WhateverYouNeed["calculations"]["structure"]["fastener"]["fastener_d"]) = false then
			# displayPoints := [op(displayPoints), pointplot((convert~)~(fasteners, 'unit_free'), symbol = 'solidcircle', 'color' = "SteelBlue", 'symbolsize' = r)]
			
		#else
		#	for i from 1 to numelems(fasteners) do
		#		fastener := disk(convert~([fasteners[i][1], fasteners[i][2]], 'unit_free'), r, 'color' = "SteelBlue");
		#		displayPoints := [op(displayPoints), fastener]
		#	end do
			# displayPoints := [op(displayPoints), disk((convert~)~(fasteners, 'unit_free'), r, 'color' = "SteelBlue")]
		# end if;

		# forces
		# https://www.mapleprimes.com/questions/232971-Copy-Values-Of-Mutable-Content
		
		displayForceVectors := table();
		for i from 1 to nops(results) do
			displayForceVectors[i] := arrow(convert~([fasteners[i][1], fasteners[i][2]], 'unit_free'), [convert(results[i][1], 'unit_free') * scalefactor, convert(results[i][2], 'unit_free') * scalefactor], 'color'='blue');	# if results includes joint coordinates
		end do;
		displayForceVectors := convert(displayForceVectors, list);

		# text
		annotations := [textplot([seq([convert(fasteners[i][1], 'unit_free'), convert(fasteners[i][2], 'unit_free'), convert(i, string)], i = 1 .. nops(fasteners))], 'align'={'below', 'right'}),
			textplot([convert(WhateverYouNeed["results"]["FastenerGroup"]["CenterOfFasteners"][1], 'unit_free'), convert(WhateverYouNeed["results"]["FastenerGroup"]["CenterOfFasteners"][2], 'unit_free'), "Fasteners"],'align'={'below', 'right'}), 
			textplot([convert(WhateverYouNeed["results"]["FastenerGroup"]["CenterOfForce"][1], 'unit_free'), convert(WhateverYouNeed["results"]["FastenerGroup"]["CenterOfForce"][2], 'unit_free'), "Force"], 'align'={'below', 'right'})];

		# geometry of beams
		# Beams
		len := 100;		# length of beam
		geometry:-point(O, [0, 0]);	# origo, letter "O"
		beamBoundarylines := [];			
		beams := table();
		beamPoints := [];
		alpha := table();
		beamnumber := table();
		# centerlines := table();

		# find item number of 2 beams
		if assigned(structure["connection"]) then
			
			for part from 1 to 2 do
				
				if assigned(structure["connection"][cat("connection", part)]) then
					if structure["connection"][cat("connection", part)] = "Timber" then
						beamnumber[part] := convert(part, string)
					elif structure["connection"][cat("connection", part)] = "Steel" then
						beamnumber[part] := "steel"
					end if
				end if;

				i := beamnumber[part];		# "1", "2", "steel"

				if assigned(WhateverYouNeed["calculations"]["structure"]["connection"][cat("graindirection", i)]) and WhateverYouNeed["calculations"]["structure"]["connection"][cat("graindirection", i)] <> "false" then
		
					alpha[i] := evalf(WhateverYouNeed["calculations"]["structure"]["connection"][cat("graindirection", i)]);
		
					# 1.) create center points and line
					# 1a) BPC...Beam Point Center (point)
					geometry:-point(parse(cat("BPC", i)), [len * cos(alpha[i]), len * sin(alpha[i])]);			
					beamPoints := [op(beamPoints), parse(cat("BPC", i))];
					# BC...Beam Center (line)
					geometry:-line(parse(cat("BC", i)),  [O, parse(cat("BPC", i))]);			# centerline, from origo, letter "O" to beam endpoint B1, or B2

					# 1b) centerlines[i] := line(A, B, color = red, linestyle = dash)
					geometryList := [op(geometryList), parse(cat("BC", i))('color' = "Red", 'linestyle' = 'dashdot')];
		
					h := convert(sectiondataAll[i]["h"], 'unit_free');
				
					# 2.) create left and right beam sides
					# 2a.)BOL...Beam Origo Left, BOR...Beam Origo Right
					geometry:-point(parse(cat("BOL", i)), [geometry:-coordinates(O)[1] - h / 2 * sin(alpha[i]), geometry:-coordinates(O)[2] + h / 2 * cos(alpha[i])]);		# point on left side of beam grid line
					geometry:-point(parse(cat("BOR", i)), [geometry:-coordinates(O)[1] + h / 2 * sin(alpha[i]), geometry:-coordinates(O)[1] - h / 2 * cos(alpha[i])]);		# point on right side of beam grid line
					beamPoints := [op(beamPoints), parse(cat("BOL", i)), parse(cat("BOR", i))];

					# 2b.) BLL...beam line left, BLR...beam line right
					geometry:-ParallelLine(parse(cat("BLL", i)), parse(cat("BOL", i)), parse(cat("BC", i)));
					geometry:-ParallelLine(parse(cat("BLR", i)), parse(cat("BOR", i)), parse(cat("BC", i)));

					# 3.) create Beam Start and End Center points
					lengthleft := convert(WhateverYouNeed["calculations"]["structure"]["connection"][cat("lengthleft", i)], 'unit_free');				# could be "false"
					lengthright := convert(WhateverYouNeed["calculations"]["structure"]["connection"][cat("lengthright", i)], 'unit_free');

					angleleft := evalf(WhateverYouNeed["calculations"]["structure"]["connection"][cat("angleleft", i)]);				# could be "false"
					angleright := evalf(WhateverYouNeed["calculations"]["structure"]["connection"][cat("angleright", i)]);
					
					cutleft := WhateverYouNeed["calculations"]["structure"]["connection"][cat("Cutleft", i)];
					cutright := WhateverYouNeed["calculations"]["structure"]["connection"][cat("Cutright", i)];					

					# BSC...Beam Start Center, BEC...Beam End Center (points), calculated with lengths
					# length... = "false" should not be possible anymore, as we allow for parallel lines to other beam with values
					x := geometry:-coordinates(O)[1] - lengthleft * cos(alpha[i]);
					y := geometry:-coordinates(O)[2] - lengthleft * sin(alpha[i]);
					geometry:-point(parse(cat("BSC", i)), [x, y]);

					x := geometry:-coordinates(O)[1] + lengthright * cos(alpha[i]);
					y := geometry:-coordinates(O)[2] + lengthright * sin(alpha[i]);
					geometry:-point(parse(cat("BEC", i)), [x, y]);
		
					# 4.) create start and end line of beam
					# 4a.) start (left) side beam
					if angleleft <> "false" then
						if angleleft < minimumangle or angleleft > 180 * Unit('degree') - minimumangle then
							Alert("Angle left outside range", warnings, 2);
							angleleft := 90 * Unit('degree');
							WhateverYouNeed["calculations"]["structure"]["connection"][cat("angleleft", i)] := angleleft;
							SetProperty(cat("TextArea_angleleft", i), 'value', round2(convert(angleleft, 'unit_free'), 2))
						end if;
						deltaangle := alpha[i] + angleleft;
					else
						deltaangle := alpha[i] + 90 * Unit('degree');	# temporary solution, should be cut to other beam
					end if;

					# coordinate for direction
					x := geometry:-coordinates(parse(cat("BSC", i)))[1] + len * cos(deltaangle);
					y := geometry:-coordinates(parse(cat("BSC", i)))[2] + len * sin(deltaangle);
					geometry:-point(parse(cat("BSC_", i)), [x, y]);

					# BLS...beam line start
					geometry:-line(parse(cat("BLS", i)), [parse(cat("BSC", i)), parse(cat("BSC_", i))]);

					# 4b.) end (right) side beam
					if angleright <> "false" then
						if angleright < minimumangle or angleright > 180 * Unit('degree') - minimumangle then
							Alert("Angle right outside range", warnings, 2);
							angleright := 90 * Unit('degree');
							WhateverYouNeed["calculations"]["structure"]["connection"][cat("angleright", i)] := angleright;
							SetProperty(cat("TextArea_angleright", i), 'value', round2(convert(angleright, 'unit_free'), 2))
						end if;
						deltaangle := alpha[i] + angleright;
					else
						deltaangle := alpha[i] + 90 * Unit('degree');	# temporary solution, should be cut to other beam
					end if;

					# coordinate for direction
					x := geometry:-coordinates(parse(cat("BEC", i)))[1] + len * cos(deltaangle);
					y := geometry:-coordinates(parse(cat("BEC", i)))[2] + len * sin(deltaangle);
					geometry:-point(parse(cat("BEC_", i)), [x, y]);

					# BLE...beam line end
					geometry:-line(parse(cat("BLE", i)), [parse(cat("BEC", i)), parse(cat("BEC_", i))]);

					# 5.) corner points of beams as intersection
					# BSL...Beam Start Left, BSR...Beam Start Right
					# BEL...Beam End Left, BER...Beam End Right
					geometry:-intersection(parse(cat("BSL", i)), parse(cat("BLL", i)), parse(cat("BLS", i)));
					geometry:-intersection(parse(cat("BEL", i)), parse(cat("BLL", i)), parse(cat("BLE", i)));
					geometry:-intersection(parse(cat("BSR", i)), parse(cat("BLR", i)), parse(cat("BLS", i)));
					geometry:-intersection(parse(cat("BER", i)), parse(cat("BLR", i)), parse(cat("BLE", i)));
					
				end if;
			end do;

			# need to redefine line and segment positions if lines if they are cut
			# probably enough to just move point positions
			for part from 1 to 2 do

				i := beamnumber[part];		# "1", "2", "steel"

				lengthleft := convert(WhateverYouNeed["calculations"]["structure"]["connection"][cat("lengthleft", i)], 'unit_free');				# could be "false"
				lengthright := convert(WhateverYouNeed["calculations"]["structure"]["connection"][cat("lengthright", i)], 'unit_free');

				angleleft := evalf(WhateverYouNeed["calculations"]["structure"]["connection"][cat("angleleft", i)]);				# could be "false"
				angleright := evalf(WhateverYouNeed["calculations"]["structure"]["connection"][cat("angleright", i)]);
				
				cutleft := WhateverYouNeed["calculations"]["structure"]["connection"][cat("Cutleft", i)];
				cutright := WhateverYouNeed["calculations"]["structure"]["connection"][cat("Cutright", i)];
				
				if cutleft = "cut profile" then		# angleleft = false
					
					if abs(alpha[beamnumber[2]] - alpha[beamnumber[1]]) >= minimumangle and abs(alpha[beamnumber[2]] - alpha[beamnumber[1]]) <= 90 * Unit('degree') then							
						
						if part = 1 then
							
							if alpha[beamnumber[2]] - alpha[beamnumber[1]] > 0 and alpha[beamnumber[2]] - alpha[beamnumber[1]] < 180 then
								geometry:-intersection(parse(cat("BSL", i)), parse(cat("BLL", beamnumber[1])), parse(cat("BLL", beamnumber[2])));
								geometry:-intersection(parse(cat("BSR", i)), parse(cat("BLR", beamnumber[1])), parse(cat("BLL", beamnumber[2])));															
							else
								geometry:-intersection(parse(cat("BSL", i)), parse(cat("BLL", beamnumber[1])), parse(cat("BLR", beamnumber[2])));
								geometry:-intersection(parse(cat("BSR", i)), parse(cat("BLR", beamnumber[1])), parse(cat("BLR", beamnumber[2])));							
							end if;															
							
						elif part = 2 then
							
							if alpha[beamnumber[2]] - alpha[beamnumber[1]] > 0 and alpha[beamnumber[2]] - alpha[beamnumber[1]] < 180 then
								geometry:-intersection(parse(cat("BSL", i)), parse(cat("BLR", beamnumber[1])), parse(cat("BLL", beamnumber[2])));
								geometry:-intersection(parse(cat("BSR", i)), parse(cat("BLR", beamnumber[1])), parse(cat("BLR", beamnumber[2])));
							else
								geometry:-intersection(parse(cat("BSL", i)), parse(cat("BLL", beamnumber[1])), parse(cat("BLL", beamnumber[2])));
								geometry:-intersection(parse(cat("BSR", i)), parse(cat("BLL", beamnumber[1])), parse(cat("BLR", beamnumber[2])));
							end if;

						end if;

						x := geometry:-coordinates(parse(cat("BSL", i)))[1] - lengthleft * cos(alpha[i]);
						y := geometry:-coordinates(parse(cat("BSL", i)))[2] - lengthleft * sin(alpha[i]);
						geometry:-point(parse(cat("BSL", i)), [x, y]);

						x := geometry:-coordinates(parse(cat("BSR", i)))[1] - lengthleft * cos(alpha[i]);
						y := geometry:-coordinates(parse(cat("BSR", i)))[2] - lengthleft * sin(alpha[i]);
						geometry:-point(parse(cat("BSR", i)), [x, y]);
						
					else
						
						Alert("Alpha angle between beams outside range", warnings, 2);
						
					end if;
					
				end if;
				
				if cutright = "cut profile" then
					
					if abs(alpha[beamnumber[2]] - alpha[beamnumber[1]]) >= minimumangle and abs(alpha[beamnumber[2]] - alpha[beamnumber[1]]) <= 90 * Unit('degree') then
					
						if part = 1 then
							if alpha[beamnumber[2]] - alpha[beamnumber[1]] > 0 and alpha[beamnumber[2]] - alpha[beamnumber[1]] < 180 then
								geometry:-intersection(parse(cat("BEL", i)), parse(cat("BLL", beamnumber[1])), parse(cat("BLR", beamnumber[2])));
								geometry:-intersection(parse(cat("BER", i)), parse(cat("BLR", beamnumber[1])), parse(cat("BLR", beamnumber[2])));							
							else
								geometry:-intersection(parse(cat("BEL", i)), parse(cat("BLL", beamnumber[1])), parse(cat("BLL", beamnumber[2])));
								geometry:-intersection(parse(cat("BER", i)), parse(cat("BLR", beamnumber[1])), parse(cat("BLL", beamnumber[2])));							
							end if;
							
						elif part = 2 then

							if alpha[beamnumber[2]] - alpha[beamnumber[1]] > 0 and alpha[beamnumber[2]] - alpha[beamnumber[1]] < 180 then
								geometry:-intersection(parse(cat("BEL", i)), parse(cat("BLL", beamnumber[1])), parse(cat("BLL", beamnumber[2])));
								geometry:-intersection(parse(cat("BER", i)), parse(cat("BLL", beamnumber[1])), parse(cat("BLR", beamnumber[2])));							
							else
								geometry:-intersection(parse(cat("BEL", i)), parse(cat("BLR", beamnumber[1])), parse(cat("BLL", beamnumber[2])));
								geometry:-intersection(parse(cat("BER", i)), parse(cat("BLR", beamnumber[1])), parse(cat("BLR", beamnumber[2])));							
							end if;

						end if;

						x := geometry:-coordinates(parse(cat("BEL", i)))[1] + lengthright * cos(alpha[i]);
						y := geometry:-coordinates(parse(cat("BEL", i)))[2] + lengthright * sin(alpha[i]);
						geometry:-point(parse(cat("BEL", i)), [x, y]);

						x := geometry:-coordinates(parse(cat("BER", i)))[1] + lengthright * cos(alpha[i]);
						y := geometry:-coordinates(parse(cat("BER", i)))[2] + lengthright * sin(alpha[i]);
						geometry:-point(parse(cat("BER", i)), [x, y]);
						
					else
						Alert("Alpha angle between beams outside range", warnings, 2);
					end if;
				end if;
		
				# 2. part, start- and endlines
				geometry:-line(parse(cat("BLS", i)), [parse(cat("BSL", i)), parse(cat("BSR", i))]);
				geometry:-line(parse(cat("BLE", i)), [parse(cat("BEL", i)), parse(cat("BER", i))]);	

				# BLL...beam line left, BLR...beam line right, BLS...beam line start, BLE...beam line end
				beamBoundarylines := [op(beamBoundarylines), parse(cat("BLL", i)), parse(cat("BLR", i)), parse(cat("BLS", i)), parse(cat("BLE", i))];

				# add beam points to list													
				beamPoints := [op(beamPoints), parse(cat("BSC", i)), parse(cat("BEC", i))];
				beamPoints := [op(beamPoints), parse(cat("BSL", i)), parse(cat("BEL", i)), parse(cat("BSR", i)), parse(cat("BER", i))];

			end do;

			graphicsElements["beamBoundarylines"] := beamBoundarylines;
			graphicsElements["beamPoints"] := beamPoints;
			
			# plot polygons
			for i in {"1", "2", "steel"} do
				if assigned(WhateverYouNeed["calculations"]["structure"]["connection"][cat("graindirection", i)]) and WhateverYouNeed["calculations"]["structure"]["connection"][cat("graindirection", i)] <> "false" then
					# polygonplot
					if i = "1" then
						clr := "Orange" 
					elif i = "2"then
						clr := "Olive"
					elif i = "steel" then
						clr := "Turquoise"
					end if;
					beams[i] := polygonplot(Matrix([geometry:-coordinates(parse(cat("BSL", i))), 
							geometry:-coordinates(parse(cat("BEL", i))),
							geometry:-coordinates(parse(cat("BER", i))),
							geometry:-coordinates(parse(cat("BSR", i)))], 'datatype' = float), 'transparency' = 0.3, 'color' = clr);
												
					# segments
					# BL...beam left, BR...beam right, BS...beam start, BE...beam end
					geometry:-segment(parse(cat("BL", i)), parse(cat("BSL", i)), parse(cat("BEL", i)));
					geometry:-segment(parse(cat("BR", i)), parse(cat("BSR", i)), parse(cat("BER", i)));
					geometry:-segment(parse(cat("BS", i)), parse(cat("BSL", i)), parse(cat("BSR", i)));
					geometry:-segment(parse(cat("BE", i)), parse(cat("BEL", i)), parse(cat("BER", i)));										

					geometryList := [op(geometryList), 
							parse(cat("BL", i))('color' = "Black", 'linestyle' = 'solid'),
							parse(cat("BR", i))('color' = "Black", 'linestyle' = 'solid'),
							parse(cat("BS", i))('color' = "Red", 'linestyle' = 'solid'),		# left, port side
							parse(cat("BE", i))('color' = "Green", 'linestyle' = 'solid')];		# right, starboard side
				end if;
			end do;

			if CheckPointInPolygon(WhateverYouNeed) then		# check if fasteners er inside of parts

				annotations_a := calculate_a(WhateverYouNeed);			# calculate a-values according to EC5
				if MASTERALARM(warnings) = true then
					return
				end if;

				displayBlockShear := BlockShearPath(WhateverYouNeed);	# calculate BlockShear
				# geometryList := [op(geometryList), op(segmentlist)];

				beams := convert(beams, list);

				plotitems := [op(beams)];

				if GetProperty("CheckBox_GraphicsShowAnnotations", value) = "true" then
					if numelems(annotations) > 0 then
						plotitems := [op(plotitems), op(annotations)]
					end if;
				end if;
			
				if GetProperty("CheckBox_GraphicsShowDistances", value) = "true" then
					if numelems(annotations_a) > 0 then
						plotitems := [op(plotitems), op(annotations_a)]
					end if;
				end if;
			
				if GetProperty("CheckBox_GraphicsShowForces", value) = "true" then
					if numelems(displayForceVectors) > 0 then
						plotitems := [op(plotitems), op(displayForceVectors)]
					end if
				end if;
				
				if GetProperty("CheckBox_GraphicsShowBlockShear", value) = "true" then
					if numelems(displayBlockShear) > 0 then
						plotitems := [op(plotitems), geometry:-draw(displayBlockShear)]
					end if;
				end if;			

			end if;

			SetProperty("Plot_result", 'value', display(geometry:-draw(geometryList), plotitems));		# combine geometry and plots elements
			
		else	# if assigned(WhateverYouNeed["calculations"]["structure"]["connection"]) = false

			SetProperty("Plot_result", 'value', display(displayForceVectors, annotations));		# combine geometry and plots elements
			
		end if;
		
	else	# MASTERALARM(WhateverYouNeed["warnings"]) = true
	
	end if;
end proc:


maxFIndexFastener := proc(results::list)
	description "returns index of fastener with Fmax";

	return max[index](convert(convert(results, Matrix)[3], list))	# https://www.mapleprimes.com/questions/233500-UnitsSimplemaxindex-#comment289958
	# return maxindex(convert(convert(results, Matrix)[3], list))
end proc:


# reads fastener definitions and calculates coordinates of points
GetPointlist := proc(WhateverYouNeed::table)
	description "Calculate coordinates of points";
	local calculations, activesettings, PointList, center, grid, alpha, dia, number, i, dummy, layout, warnings;

	calculations := WhateverYouNeed["calculations"];	
	activesettings := calculations["activesettings"];	
	warnings := WhateverYouNeed["warnings"];

	PointList := [];		# list of points
	layout := table();

	layout["FastenerPatternUnits"] := GetProperty("ComboBox_FastenerPatternUnits", value);
	layout["reactionforces"] := GetProperty("CheckBox_reactionforces", value);
	activesettings["activeFastenerPattern"] := GetProperty("ComboBox_FastenerPatterns", value);

	# read FastenerPatterns
	for i from 1 to GetNumberOfFastenerDefinitions() do

		layout[cat("FastenerPatternType", i)] := GetProperty(cat("ComboBox_FastenerPatternType", i), value);

		# we do allow for mixed definitions now, so need to reset things after each run
		center := [];
		grid := [];
		alpha := [];
		dia := [];
		number := [];

		if GetProperty(cat("ComboBox_FastenerPatternType", i), 'enabled') = "true" then		# should always be true now
						
			if layout[cat("FastenerPatternType", i)] = "grid" then

				dummy := [parse(GetProperty(cat("TextArea_center_x", i), value)), parse(GetProperty(cat("TextArea_center_y", i), value))];
				layout[cat("center_x",i)] := GetProperty(cat("TextArea_center_x", i), value);
				layout[cat("center_y",i)] := GetProperty(cat("TextArea_center_y", i), value);
				center := [op(center), dummy];

				dummy := [GetProperty(cat("TextArea_grid_x", i), value), GetProperty(cat("TextArea_grid_y", i), value)];
				layout[cat("grid_x",i)] := GetProperty(cat("TextArea_grid_x", i), value);
				layout[cat("grid_y",i)] := GetProperty(cat("TextArea_grid_y", i), value);
				grid := [op(grid), dummy];

				dummy := [parse(GetProperty(cat("TextArea_grid_alpha_1", i), value)), parse(GetProperty(cat("TextArea_grid_alpha_2", i), value))];
				layout[cat("grid_alpha_1",i)] := GetProperty(cat("TextArea_grid_alpha_1", i), value);
				layout[cat("grid_alpha_2",i)] := GetProperty(cat("TextArea_grid_alpha_2", i), value);
				alpha := [op(alpha), dummy];

				PointList := [op(PointList), op(PointlistByGrid(center, grid, alpha, warnings))]	# merge 2 lists?
			
			elif layout[cat("FastenerPatternType", i)] = "radial" then

				dummy := [parse(GetProperty(cat("TextArea_center_x", i), value)), parse(GetProperty(cat("TextArea_center_y", i), value))];
				layout[cat("center_x",i)] := GetProperty(cat("TextArea_center_x", i), value);
				layout[cat("center_y",i)] := GetProperty(cat("TextArea_center_y", i), value);
				center := [op(center), dummy];
			
				dummy := parse(GetProperty(cat("TextArea_radial_diameter", i), value));
				layout[cat("radial_diameter",i)] := GetProperty(cat("TextArea_radial_diameter", i), value);
				dia := [op(dia), dummy];

				dummy := parse(GetProperty(cat("TextArea_radial_items", i), value));
				layout[cat("radial_items",i)] := GetProperty(cat("TextArea_radial_items", i), value);
				number := [op(number), dummy];

				dummy := parse(GetProperty(cat("TextArea_radial_alpha", i), value));
				layout[cat("radial_alpha",i)] := GetProperty(cat("TextArea_radial_alpha", i), value);
				alpha := [op(alpha), dummy];

				PointList := [op(PointList), op(PointlistByCircle(center, dia, number, alpha, warnings))]

			# elif layout[cat("FastenerPatternType", i)] = "-" then
			
			end if;
		else
			layout[cat("FastenerPatternType", i)] := "false"
		end if;

		if MASTERALARM(WhateverYouNeed["warnings"]) = true then
			return layout, PointList
		end if;
	end do;

	# coordinates input
	layout["FastenerPatternCoordinates"] := GetProperty("CheckBox_FastenerPatternCoordinates", value);

	if layout["FastenerPatternCoordinates"] = "true" then			
		layout["coordinates"] := GetProperty("TextArea_coordinates", value);
		PointList := [op(PointList), op(PointlistByText(GetProperty("TextArea_coordinates", value), warnings))]			
	end if;

	# post production
	PointList := PointlistRemoveDuplicates(PointList);

	# WhateverYouNeed["calculations"]["structure"]["layout"] := eval(layout);

	if layout["FastenerPatternUnits"] = "m" then
		PointList := PointList *~ Unit('m')
	elif layout["FastenerPatternUnits"] = "cm" then
		PointList := PointList *~ Unit('cm')
	elif layout["FastenerPatternUnits"] = "mm" then
		PointList := PointList *~ Unit('mm')
	end if;

	return layout, PointList
end proc:


SetVisibilityFastenerPattern := proc()
	description "Set visibility of fastener layout";
	local i, j, allcomponents, components, val, FastenerPatternType;

	# We do allow a mix of radial, grid and coordinate input now

	components := table();

	allcomponents := {"grid", "radial", "common"};
	components["grid"] := ["TextArea_grid_x", "TextArea_grid_y", "TextArea_grid_alpha_1", "TextArea_grid_alpha_2"];
	components["radial"] := ["TextArea_radial_diameter", "TextArea_radial_items", "TextArea_radial_alpha"];
	components["common"] := ["TextArea_center_x", "TextArea_center_y"];

	# deenable everything first
	for i from 1 to GetNumberOfFastenerDefinitions() do
		for j in allcomponents do
			for val in components[j] do
				SetProperty(cat(val, i), 'enabled', "false");
			end do;
		end do;
	end do;
	
	for i from 1 to GetNumberOfFastenerDefinitions() do
		SetProperty(cat("ComboBox_FastenerPatternType", i), 'enabled', "true");
		FastenerPatternType := GetProperty(cat("ComboBox_FastenerPatternType", i), value);
		if FastenerPatternType <> "-" then
			for val in components["common"] do
				SetProperty(cat(val, i), 'enabled', "true");
			end do;
			for val in components[FastenerPatternType] do
				SetProperty(cat(val, i), 'enabled', "true");
			end do;
		end if;				
	end do;			

	if GetProperty("CheckBox_FastenerPatternCoordinates", value) = "true" then
		SetProperty("TextArea_coordinates", 'enabled', "true");			
	else
		SetProperty("TextArea_coordinates", 'enabled', "false");
	end if;		

end proc:


GetNumberOfFastenerDefinitions := proc() :: integer;
	description "Number of fastener groups defined in sheet";
	local i, dummy, maxnumber;

	maxnumber := 0;
	for i from 1 to 10 do
		dummy := cat("ComboBox_FastenerPatternType", i);
		if ComponentExists(dummy) then
			maxnumber := i
		else
			return maxnumber
		end if;
	end do;
	return maxnumber
end proc:


PointlistByGrid := proc(center, grid, alpha, warnings)::list;		# list of parameters
	description "Constructs grid of points in x and y direction inclined angle alpha";
	uses StringTools;

	local aPointList, nx, ny, dx, dy, i, j, maxX, maxY, x, y, deltaX, deltaY, valX, valY, ind, valCenter, dummy, counter, xtable, ytable, xsum, ysum;

	aPointList := [];		# list of points

	if (numelems(center) <> numelems(grid)) or (numelems(grid) <> numelems(alpha)) then
		Alert("Unequal number of center and grid definitions", warnings, 5);
		return aPointList;
	end if;

	for ind, valCenter in center do 						# loop over groups of connections
	
		valX := grid[ind][1];		# 3*30 or 30			# string
		valY := grid[ind][2];

		valX := StringTools:-Split(valX, " ");		# list
		valX := remove(type, valX, "");			# remove whitespace
		
		valY := StringTools:-Split(valY, " ");		# list
		valY := remove(type, valY, "");			# remove whitespace

		xtable := table();
		xtable[0] := 0;			
		counter := 1;

		for dummy in valX do
			if SearchText("*", dummy) > 0 then		# 3*30
				nx := parse(StringTools:-Split(dummy, "*")[1]);	# number of gaps
				dx := parse(StringTools:-Split(dummy, "*")[2]);	# gap distance
				for i from 1 to nx do
					xtable[counter] := dx;
					counter := counter + 1
				end do;
			else								# 30
				dx := parse(convert(dummy, string));
				if dx = 0 then
					nx := 0;
				else
					nx := 1;
					xtable[counter] := dx;
					counter := counter + 1
				end if;
			end if;
		end do;

		ytable := table();
		ytable[0] := 0;
		counter := 1;
		for dummy in valY do
			if SearchText("*", dummy) > 0 then
				ny := parse(StringTools:-Split(dummy, "*")[1]);
				dy := parse(StringTools:-Split(dummy, "*")[2]);
				for i from 1 to ny do
					ytable[counter] := dy;
					counter := counter + 1
				end do;
			else
				dy := parse(convert(dummy, string));
				if dy = 0 then
					ny := 0;
				else
					ny := 1;
					ytable[counter] := dy;
					counter := counter + 1
				end if;
			end if;
		end do;

		maxX := 0;
		for i in entries(xtable, 'nolist') do
			maxX := maxX + i
		end do;

		maxY := 0;
		for i in entries(ytable, 'nolist') do
			maxY := maxY + i
		end do;

		xsum := 0;
		for i in entries(xtable, 'nolist') do
			xsum := xsum + i;
			ysum := 0;
			for j in entries(ytable, 'nolist') do
				ysum := ysum + j;
				deltaX := evalf(-maxY/2 + ysum) * tan(alpha[ind][1] * Unit('degree'));		# alpha1 moves positions sideways in x direction
				x := evalf(valCenter[1] - maxX/2 + xsum - deltaX);
		
				deltaY := evalf(-maxX/2 + xsum) * tan(alpha[ind][2] * Unit('degree'));		# alpha2 moves positions up and down i y direction
				y := evalf(valCenter[2] - maxY/2 + ysum + deltaY);
		
				aPointList := [op(aPointList), Vector[column](2,[x,y])];		# append a new element to a list
			end do;
		end do;

	end do;

	return aPointList
end proc:


PointlistByCircle := proc(center, dia, number, alpha, warnings)::list;
	description "Construct a circle of points rotated by angle alpha in a distance of diameter";
	local aPointList, j, x, y, AngleOfSector, ind, valCenter;

	aPointList := [];		# list of points

	if (numelems(center) <> numelems(dia)) or (numelems(dia) <> numelems(number)) or (numelems(number) <> numelems(alpha)) then
		Alert("Invalid: unequal number of groups in circle definition", warnings, 5);
		return aPointList
	end if;

	for ind, valCenter in center do 						# loop over groups of connections
		
		if dia[ind] <= 0 then		# no diameter, only one bolt in center of circle ?
			Alert("Invalid diameter, must be bigger than 0", warnings, 5);
			return aPointList
		
		elif number[ind] < 1 then		# must have more than 1 item in circle
			Alert("Invalid: must have more than 1 item in circle", warnings, 5);
			return aPointList
		
		end if;

		AngleOfSector := evalf(360 * Unit('degree') / number[ind]);

		for j from 0 to number[ind] - 1 do		# go along the circle
			x := evalf(valCenter[1] - dia[ind] * sin(j * AngleOfSector + alpha[ind] * Unit('degree')));
			y := evalf(valCenter[2] + dia[ind] * cos(j * AngleOfSector + alpha[ind] * Unit('degree')));

			aPointList := [op(aPointList), Vector[column](2,[x,y])];		# append a new element to a list
		end do;
	
	end do;
	
	return aPointList
end proc:


PointlistByText := proc(textinput::string, warnings::table)::list;
	uses StringTools;
	description "Get points by coordinate entries, separated by comma";
	local aPointList, points, i, dummy;

	aPointList := [];		# list of points

	points := Split(textinput, ",");

	for i from 1 to numelems(points) do
		dummy := Split(points[i]);
		dummy := remove(type, dummy, "");			# remove white spaces
		if numelems(dummy) <> 2 then
			Alert("Unable to read coordinate list", warnings, 4);
			return aPointList
		end if;
		aPointList := [op(aPointList), Vector[column](2,[parse(dummy[1]), parse(dummy[2])])];
	end do;

	return aPointList
end proc:


PointlistRemoveDuplicates := proc(aPointList::list)::list;
	description "Remove duplicates in point list";
	local newPointList;

	# Remove duplicates, but that needs to be done by converting vectors to lists and back again.
	# https://www.mapleprimes.com/questions/232959-Convert-List-With-Vectors-To-Set
	# 1. convert elements (Vectors) to list
	# 2. convert list to set (eliminating duplicates)
	# 3. convert set to list
	# 4. convert elements (lists) to Vectors
	newPointList := convert~(convert(convert(convert~(aPointList, list), set), list), Vector);
	
	return newPointList
end proc:


PointlistRotate := proc(PointList, phi)
	description "Rotate Pointlist angle alpha";
	local rotMatrix, i;

	# https://de.wikipedia.org/wiki/Koordinatentransformation
	rotMatrix := Matrix([[cos(phi), -sin(phi)], [sin(phi), cos(phi)]]);

	return evalf([seq(rotMatrix.PointList[i], i=1..nops(PointList))]);		
end proc:


PointlistGetCenter := proc(pointlist)
	description "Calculate center of point list";
	local center, i;

	center := Vector(2);
	for i from 1 to nops(pointlist) do
		center[1] := center[1] + pointlist[i][1];
		center[2] := center[2] + pointlist[i][2];
	end do;

	center := center /~ nops(pointlist);

	return center;
end proc:


EccentricMoment := proc(loadVector, centerOfFasteners, centerOfForce)
	description "Calculate eccentric moment for existing forces, moment and eccentricity";
	local loadVector_centerBoltgroup;

	loadVector_centerBoltgroup := Vector[column](3, loadVector);
	loadVector_centerBoltgroup[3] := evalf(eval(loadVector[3]) + loadVector[1] * (centerOfFasteners[2] - centerOfForce[2]) - loadVector[2] * (centerOfFasteners[1] - centerOfForce[1]));
	loadVector_centerBoltgroup[3] := convert(loadVector_centerBoltgroup[3], 'units', 'kN*m');

	return loadVector_centerBoltgroup;
end proc:


ForcesInPoint := proc(forces::Vector, PointList, centerOfFasteners, warnings::table)::list;		# Fx (N), Fy (V), My
	description "Calculates the forces of each point in a bolt array";

	local x, y, r, r2, i, n, results_M, results, ResultVector, Fx, Fy, F_M;		
	
	# https://www.mapleprimes.com/questions/232971-Copy-Values-Of-Mutable-Content

	# calculate force due to moment around bolt center
	r2 := 0;
	for i from 1 to nops(PointList) do		# calculate r^2
		x := (PointList[i][1] - centerOfFasteners[1]);
		y := (PointList[i][2] - centerOfFasteners[2]);
		r2 := r2 + x^2 + y^2	
	end do;

	results_M := Array();
	for i from 1 to nops(PointList) do

		ResultVector := Vector(2);
		x := (PointList[i][1] - centerOfFasteners[1]);	# x distance between fastener point and center of Fasteners
		y := (PointList[i][2] - centerOfFasteners[2]);
		r := sqrt(x^2 + y^2);
		
		if r2 > 0 then
			F_M := evalf(forces[3] / r2 * r);			
		# this should just happen when there is just one bolt
		elif forces[3] = 0 then
			F_M := 0;		
		else 
			Alert("Connection with one fastener and moment impossible", warnings, 4);
		end if;
		
		# if convert(r, 'unit_free') <> 0 then		# https://www.mapleprimes.com/posts/216010-Comparing-Units	
		if r <> 0 then
			ResultVector[1] := convert(evalf(-F_M * y / r), 'units', 'kN');		# Fx
			ResultVector[2] := convert(evalf(F_M * x / r), 'units', 'kN');		# Fy
		else
			ResultVector[1] := 0;
			ResultVector[2] := 0;
		end if;
		results_M(i) := ResultVector;
	end do;

	results_M := convert(results_M, list);

	n := numelems(PointList);
	results := Array();					# list of all points

	for i from 1 to nops(PointList) do
	
		ResultVector := Vector(4);
		Fx := evalf(forces[1] / n);			# Fh
		Fy := evalf(forces[2] / n);			# Fv
	
		ResultVector[1] := evalf(Fx + results_M[i][1]);
		ResultVector[2] := evalf(Fy + results_M[i][2]);
		ResultVector[3] := evalf(sqrt(ResultVector[1]^2 + ResultVector[2]^2));		# F
		if ResultVector[1] = 0 and ResultVector[2] = 0 then
			ResultVector[4] := 0
		else
			ResultVector[4] := convert(arctan(ResultVector[2], ResultVector[1]) * Unit('radian'), 'units', 'degree')		# alpha
		end if;

		results(i) := ResultVector;
	end do;

	results := convert(results, list);

	return results
end proc:


calculate_a := proc(WhateverYouNeed::table)			# calculate a-values according to EC5
	description "Calculate a-values for timber constructions";
	local i, j, fastenerPointlist, beamBoundarylines, beamBoundaryline, k, dist, dummy, dummy1, beamside, beamindex, warnings, distance, intPointL, intPointR, intPointS, intPointE, a1min, a2min,
		segmentlist, segments, segm1, segm2, segm3, segm4, a1distance, a2distance, annotation1, annotation2, annotation3, annotation4, annotations, alpha, parline,
		a1_FastenersInRow, a1_row, a1_nFastenersInRow, a2_FastenersInColumn, a2_column, a2_nFastenersInColumn, distanceOfInterest;

	warnings := WhateverYouNeed["warnings"];
	beamBoundarylines := WhateverYouNeed["calculatedvalues"]["graphicsElements"]["beamBoundarylines"];
	fastenerPointlist := WhateverYouNeed["calculatedvalues"]["graphicsElements"]["fastenerPointlist"];

	dist := table();		
	segments := table();
	segmentlist := [];
	annotations := {};
	a1_FastenersInRow := table();		# indexed table of a1_row elements
	a1_nFastenersInRow := table();	# number of fasteners in row
	a2_FastenersInColumn := table();	# indexed table of a2_column elements
	a2_nFastenersInColumn := table();	# number of fasteners in column

	# distance stores both minimumdistance and calculated distance values
	# reset of values is done in ReadComponentsSpecific
	distance := WhateverYouNeed["calculatedvalues"]["distance"];
	
	# store calculated distance and segment
	distance["dist"] := dist;
	distance["segments"] := segments;
	
	# a1_row := {};	
	# all fasteners in a specific row

	# calculate distances between fastener and intersection point
	for i from 1 to numelems(fastenerPointlist) do				# F1, F2,...
		
		for beamBoundaryline from 1 to numelems(beamBoundarylines) do	# BLL1: boundary line beam 1, Left (Right, Start, End)

			# find beam index ("1", "2", "steel") and side (Left, Right, Start, End)
			if searchtext("steel", beamBoundarylines[beamBoundaryline]) = 0 then
				beamindex := substring(convert(beamBoundarylines[beamBoundaryline], string), -1..-1);
				beamside := substring(convert(beamBoundarylines[beamBoundaryline], string), -2..-2);
			else
				beamindex := "steel";
				beamside := substring(convert(beamBoundarylines[beamBoundaryline], string), -6..-6);
			end if;

			# a_F1BLL1, a_F1BLLsteel
			dummy := cat("a_", convert(fastenerPointlist[i], string), convert(beamBoundarylines[beamBoundaryline], string));	
			
			if beamside = "L" or beamside = "R" then
				# projection point from fastener on left or right boundary line (normal to grain direction)
				geometry:-projection(parse(dummy), fastenerPointlist[i], beamBoundarylines[beamBoundaryline]);	
				
			elif beamside = "S" or beamside = "E" then
				# intersection point of line through fastener point with start or end of beam
				geometry:-ParallelLine(parline, fastenerPointlist[i], parse(cat("BLL", beamindex)));
				geometry:-intersection(parse(dummy), parline, beamBoundarylines[beamBoundaryline])

			else
				Alert(cat("Unknown beamside ",beamside) , warnings, 1);						
			end if;

			# distance between fastener and projection / intersection point
			dist[dummy] := evalf(geometry:-distance(fastenerPointlist[i], parse(dummy)));	
			segments[dummy] := [fastenerPointlist[i], parse(dummy)]				# storing points
		end do;
		
	end do;

	# calculate a4
	for beamBoundaryline from 1 to numelems(beamBoundarylines) do		# we do have left and right sides
		
		# if searchtext("steel", beamBoundarylines[beamBoundaryline]) > 0 then
		# 	break			# no a values for steel
		# end if;
		if searchtext("steel", beamBoundarylines[beamBoundaryline]) = 0 then
			beamindex := substring(convert(beamBoundarylines[beamBoundaryline], string), -1..-1);
			beamside := substring(convert(beamBoundarylines[beamBoundaryline], string), -2..-2);
		else
			beamindex := "steel";
			beamside := substring(convert(beamBoundarylines[beamBoundaryline], string), -6..-6);
		end if;
		
		alpha := convert(evalf(convert(WhateverYouNeed["calculations"]["structure"]["connection"][cat("graindirection", beamindex)], 'radians')), 'unit_free');

		# a4: checking left and right sides
		if beamside = "L" then			
		
			for i from 1 to numelems(fastenerPointlist) do				# F1, F2,...	

				intPointL := cat("a_", convert(fastenerPointlist[i], string), "BLL", beamindex);	# a_F1BLL1
				intPointR := cat("a_", convert(fastenerPointlist[i], string), "BLR", beamindex);				

#				We do not check inside / outside beam anymore, as this is done in CheckPointInPolygon

#				if round(dist[intPointL] + dist[intPointR]) > round(evalf(geometry:-distance(parse(intPointL), parse(intPointR)))) then
#					Alert(cat("Fastener Point ",convert(fastenerPointlist[i], string), " outside of beam ", beamindex) , warnings, 5);
#					distance[cat("a4", beamindex)] := 0;
#					return;
					
#				else
					# need to store a4 values for each fastener point for calculation of splitting capacity

				distance[intPointL] := evalf(dist[intPointL]);
				distance[intPointR] := evalf(dist[intPointR]);

				# check if new a4 value
				if assigned(distance[cat("a4", beamindex)]) = false or convert(distance[cat("a4", beamindex)], 'unit_free') > min(evalf(dist[intPointL]), evalf(dist[intPointR])) then						
					distance[cat("a4", beamindex)] := min(evalf(dist[intPointL]), evalf(dist[intPointR])) * Unit('mm');
					if evalf(dist[intPointL]) < evalf(dist[intPointR]) then
						segm4 := geometry:-segment(parse(cat("a4", beamindex)), op(segments[intPointL]));
						
					else
						segm4 := geometry:-segment(parse(cat("a4", beamindex)), op(segments[intPointR]));
					end if;
					dummy1 := cat("a4", beamindex, "=", convert(round(convert(distance[cat("a4", beamindex)], 'unit_free')), string), "mm");
					annotation4 := plots:-textplot([op(geometry:-coordinates(geometry:-midpoint(parse(cat("a4", beamindex, "M")), segm4))) , dummy1],
							'align' = {'above', 'right'}, 'color' = "Blue", 'rotation' = alpha);
				end if;	
#				end if;					
			end do;
			
			if distance[cat("a4", beamindex)] <> 0 then
				# segmentlist := [op(segmentlist), segm4('color' = "DarkGrey")];
				try
					geometry:-DefinedAs(segm4)
				catch "wrong type of argument":
					Alert("wrong type of argument, variable segm4: ", warnings, 5);
					DEBUG();
				end try;
				annotations := annotations union {annotation4, Segment2Arrow(segm4)}
			end if;

		# a3: checking start and end sides
		elif beamside = "S" then		

			for i from 1 to numelems(fastenerPointlist) do				# F1, F2,...	
			
				intPointS := cat("a_", convert(fastenerPointlist[i], string), "BLS", beamindex);	# a_F1BLS1
				intPointE := cat("a_", convert(fastenerPointlist[i], string), "BLE", beamindex);				
			
#				We do not check inside / outside beam anymore, as this is done in CheckPointInPolygon			
#				if round(dist[intPointS] + dist[intPointE]) > round(evalf(geometry:-distance(parse(intPointS), parse(intPointE)))) then
#					Alert(cat("Fastener Point ",convert(fastenerPointlist[i], string), " outside of beam ", beamindex) , warnings, 5);	
#					distance[cat("a3", beamindex)] := 0;
#					return;
#				else

				if assigned(distance[cat("a3", beamindex)]) = false or convert(distance[cat("a3", beamindex)], 'unit_free') > min(evalf(dist[intPointS]), evalf(dist[intPointE])) then						
					distance[cat("a3", beamindex)] := min(evalf(dist[intPointS]), evalf(dist[intPointE])) * Unit('mm');
					if evalf(dist[intPointS]) < evalf(dist[intPointE]) then
						segm3 := geometry:-segment(parse(cat("a3", beamindex)), op(segments[intPointS]));
						distance[cat("a3", beamindex, "side")] := "S"		# need to store which side has shortest distance for calculation of block shear
						
					else
						segm3 := geometry:-segment(parse(cat("a3", beamindex)), op(segments[intPointE]));
						distance[cat("a3", beamindex, "side")] := "E"		# need to store which side has shortest distance for calculation of block shear
					end if;
					dummy1 := cat("a3", beamindex, "=", convert(round(convert(distance[cat("a3", beamindex)], 'unit_free')), string), "mm");
					annotation3 := plots:-textplot([op(geometry:-coordinates(geometry:-midpoint(parse(cat("a3", beamindex, "M")), segm3))) , dummy1],
							'align' = {'above', 'right'}, 'color' = "Blue", 'rotation' = alpha);
				end if;	

#				end if;					

			end do;
			
			if distance[cat("a3", beamindex)] <> 0 then
				# segmentlist := [op(segmentlist), segm3('color' = "DarkGrey")];
				annotations := annotations union {annotation3, Segment2Arrow(segm3)}
			end if;
							
		end if;
		
	end do;		

	# a1
	# - create lines parallel to grain direction through each fastener point (line_F1B1)
	# - create projection point from checked point to parallel line (a1_211, -> a1_F2F1B1)
	# - if length from F2 to projection point is lower than a2min / 2, check
	# - find minimum distance between points F1 and projection point
	# - find number of fasteners in a row

	# a2
	# create line normal to grain direction
	# 

	distance["a1_numberOfFasteners"] := 0;
	distance["a2_numberOfFasteners"] := 0;

	for beamBoundaryline from 1 to numelems(beamBoundarylines) do
		
#			if searchtext("steel", beamBoundarylines[beamBoundaryline]) > 0 then
#				next			# no a values for steel
#			end if;	

		if searchtext("steel", beamBoundarylines[beamBoundaryline]) = 0 then
			beamindex := substring(convert(beamBoundarylines[beamBoundaryline], string), -1..-1);
			beamside := substring(convert(beamBoundarylines[beamBoundaryline], string), -2..-2);
		else
			beamindex := "steel";
			beamside := substring(convert(beamBoundarylines[beamBoundaryline], string), -6..-6);
		end if;
		
		alpha := convert(evalf(convert(WhateverYouNeed["calculations"]["structure"]["connection"][cat("graindirection", beamindex)], 'radians')), 'unit_free');			
		
		if beamside = "L" then			# run each beam just once				

			for i from 1 to numelems(fastenerPointlist) do
					
				dummy := cat("line_", convert(fastenerPointlist[i], string), "B", beamindex);	# line_F1B1, parallel to grain direction
				geometry:-ParallelLine(parse(dummy), fastenerPointlist[i], beamBoundarylines[beamBoundaryline]);	# line through fastener point, parallel with grain direction of beam
				a1_row := {i};
				a2_column := {i};

				for k from i+1 to numelems(fastenerPointlist) do		# check distance between fastener points i and k
					
					geometry:-projection(parse(cat("a1_", beamBoundaryline, i, k)), fastenerPointlist[k], parse(dummy));		# a1_BLL112, projection point on line through fastenerPoint k
					a1distance := geometry:-distance(fastenerPointlist[i], parse(cat("a1_", beamBoundaryline, i, k)));			# check distance for points to be considered on same a2 column
					a2distance := geometry:-distance(fastenerPointlist[k], parse(cat("a1_", beamBoundaryline, i, k)));			# check distance for points to be considered on same a1 row						
						
					if assigned(distance[cat("a1_min_max", beamindex)]) then
						# a1min := convert(distance[cat("a1_min_max", beamindex)], 'unit_free');		# minimum a1
						a1min := convert(distance[cat("a1_min_min", beamindex)], 'unit_free');		# minimum a1
					else
						a1min := 0
					end if;

					if assigned(distance[cat("a2_min_max", beamindex)]) then
						# a2min := convert(distance[cat("a2_min_max", beamindex)], 'unit_free');		# minimum a2
						a2min := convert(distance[cat("a2_min_min", beamindex)], 'unit_free');		# minimum a2
					else
						a2min := 0
					end if;

					# get a1 value
					# if a2distance <= a2min / 2 then		# calculate distance in grain direction between fastenerpoints, 5.2(4)

					if beamindex = "steel" then
						distanceOfInterest := convert(distance["a2_minsteel"], 'unit_free')			# 2,4 * d0
					else
						distanceOfInterest := convert(distance[cat("a2_min_max", beamindex)] / 2, 'unit_free')	# calculate distance in grain direction between fastenerpoints, 5.2(4), using max value
					end if;
					
					if a2distance <= distanceOfInterest then	
						a1_row := a1_row union {k};
							
						if assigned(distance[cat("a1", beamindex)]) = false or convert(distance[cat("a1", beamindex)], 'unit_free') > a1distance then		# new value for a1 found
							
							distance[cat("a1", beamindex, "_fastener")] := {};		# stores fastener points that are within minimum distance
								
							distance[cat("a1", beamindex)] := a1distance * Unit('mm');
							distance[cat("a1", beamindex, "_fastener")] := {i, k};
							segm1 := geometry:-segment(parse(cat("a1", beamindex)), fastenerPointlist[i], parse(cat("a1_", beamBoundaryline, i, k)));
							dummy1 := cat("a1", beamindex, "=", convert(round(convert(distance[cat("a1", beamindex)], 'unit_free')), string), "mm");
							annotation1 := plots:-textplot([op(geometry:-coordinates(geometry:-midpoint(parse(cat("a1", beamindex, "M")), segm1))) , dummy1],
									'align' = {'above', 'right'}, 'color' = "Blue", 'rotation' = alpha);

						# add point to list of points which have minimum distance to another point
						elif convert(distance[cat("a1", beamindex)], 'unit_free') = a1distance then
							distance[cat("a1", beamindex, "_fastener")] := distance[cat("a1", beamindex, "_fastener")] union {i, k};
								
						end if;
							
					end if;

					# get a2 value
					# if a1distance <= a1min / 2 then # 5.2(4)
					if beamindex = "steel" then
						distanceOfInterest := convert(distance["a1_minsteel"], 'unit_free')			# 2,4 * d0
					else
						distanceOfInterest := convert(distance[cat("a1_min_max", beamindex)] / 2, 'unit_free')	# calculate distance in grain direction between fastenerpoints, 5.2(4), using max value
					end if;
					
					if a1distance <= distanceOfInterest then
							
						a2_column := a2_column union {k};
						
						if assigned(distance[cat("a2", beamindex)]) = false or convert(distance[cat("a2", beamindex)], 'unit_free') > a2distance then

							distance[cat("a2", beamindex, "_fastener")] := {};		# stores fastener points that are within minimum distance
								
							distance[cat("a2", beamindex)] := a2distance * Unit('mm');
							distance[cat("a2", beamindex, "_fastener")] := {i, k};
							segm2 := geometry:-segment(parse(cat("a2", beamindex)), fastenerPointlist[k], parse(cat("a1_", beamBoundaryline, i, k)));
							dummy1 := cat("a2", beamindex, "=", convert(round(convert(distance[cat("a2", beamindex)], 'unit_free')), string), "mm");
							annotation2 := plots:-textplot([op(geometry:-coordinates(geometry:-midpoint(parse(cat("a2", beamindex, "M")), segm2))) , dummy1],
									'align' = {'above', 'right'}, 'color' = "Blue", 'rotation' = alpha);

						# add point to list of points which have minimum distance to another point
						elif convert(distance[cat("a2", beamindex)], 'unit_free') = a2distance then
							distance[cat("a2", beamindex, "_fastener")] := distance[cat("a2", beamindex, "_fastener")] union {i, k};
							
						end if;
							
					end if;																				
					
				end do;
				a1_FastenersInRow[cat(beamindex, i)] := a1_row;
				a2_FastenersInColumn[cat(beamindex, i)] := a2_column;
								
			end do;	# fastenerpointlist

			# graphics annotations
			if assigned(distance[cat("a1", beamindex)]) and distance[cat("a1", beamindex)] <> 0 then
				# segmentlist := [op(segmentlist), segm1('color' = "DarkGrey")];
				annotations := annotations union {annotation1, Segment2Arrow(segm1)}
			end if;

			if assigned(distance[cat("a2", beamindex)]) and distance[cat("a2", beamindex)] <> 0 then
				# segmentlist := [op(segmentlist), segm2('color' = "DarkGrey")];
				annotations := annotations union {annotation2, Segment2Arrow(segm2)}
			end if;				
		end if;			
		
	end do; # beamboundaryline


	# calculate maximum number of points in a row with minimum distance	
	# a1	
	for i in indices(a1_FastenersInRow, 'indexorder', 'nolist') do
		if numelems(a1_FastenersInRow[i]) = 1 or searchtext("steel", i) > 0 then
			next;		# point does only has itself in the list
		end if;			
		beamindex := substring(i, 1..1);
		if assigned(a1_nFastenersInRow[beamindex]) = false or a1_nFastenersInRow[beamindex] < numelems(a1_FastenersInRow[i]) then
			# check if fastener points are in list of points that are minimum distance points
			if a1_FastenersInRow[i] subset distance[cat("a1", beamindex, "_fastener")] then
				a1_nFastenersInRow[beamindex] := numelems(a1_FastenersInRow[i])
			end if;
		end if;
	end do;
	
	distance["a1_FastenersInRow"] := a1_FastenersInRow;
	distance["a1_nFastenersInRow"] := eval(a1_nFastenersInRow);

	# a2
	for i in indices(a2_FastenersInColumn, 'indexorder', 'nolist') do
		
#			if searchtext("steel", i) > 0 then
#				next							
#			end if;

		if searchtext("steel", i) > 0 then
			beamindex := "steel"
		else
			beamindex := substring(i, 1..1)
		end if;
		
		if assigned(a2_nFastenersInColumn[beamindex]) = false or a2_nFastenersInColumn[beamindex] < numelems(a2_FastenersInColumn[i]) then
			
			if assigned(a2_nFastenersInColumn[beamindex]) = false then
				a2_nFastenersInColumn[beamindex] := numelems(a2_FastenersInColumn[i])
					
			# check if fastener points are in list of points that are minimum distance points
			elif a2_FastenersInColumn[i] subset distance[cat("a2", beamindex, "_fastener")] then
				a2_nFastenersInColumn[beamindex] := numelems(a2_FastenersInColumn[i])
				
			end if;
		end if;
	end do;
	
	distance["a2_FastenersInColumn"] := a2_FastenersInColumn;
	distance["a2_nFastenersInColumn"] := eval(a2_nFastenersInColumn);		

	# end of calculation a1, a2, a3, a4

	# calculating values for splitting capacity according to german NA, as shown in Limtreboka page 250
	local FastenersInRowTotal, FastenersInRowDistance, FastenersInRowBeam, foundmatch;
	FastenersInRowTotal := table();		# splits fasteners in beams
	FastenersInRowDistance := table();		# distance of rows to beam edges

	for i in indices(a1_FastenersInRow, 'indexorder', 'nolist') do			

		if  searchtext("steel", i) > 0 then
			next
		else
			beamindex := substring(i, 1..1);
		end if;
		
		if assigned(FastenersInRowTotal[beamindex]) then
			FastenersInRowBeam := FastenersInRowTotal[beamindex]	# table where rows of fasteners are stored
		else
			FastenersInRowBeam := table();
			FastenersInRowTotal[beamindex] := eval(FastenersInRowBeam);
			FastenersInRowDistance[beamindex] := table();
		end if;

		# check if stored set of fasteners can be reduced or needs to be expanded
		foundmatch := false;
		if numelems(FastenersInRowBeam) > 0 then
			for j from 1 to numelems(FastenersInRowBeam) do
						
				if FastenersInRowBeam[j] subset a1_FastenersInRow[i] then
					FastenersInRowBeam[j] := eval(a1_FastenersInRow[i]);		# change content to new data
					foundmatch := true
				end if;

				if a1_FastenersInRow[i] subset FastenersInRowBeam[j] then	# new data is subset of existing
					foundmatch := true			
				end if;
				
			end do;
		else				
			FastenersInRowBeam[1] := eval(a1_FastenersInRow[i]);		# new line
			foundmatch := true
		end if;
		
		if foundmatch = false then
			FastenersInRowBeam[j] := eval(a1_FastenersInRow[i]);		# loop ends with j + 1
		end if;

	end do;		

	# check timber net area in grain direction
	local FastenersInColumnTotal, FastenersInColumnDistance, FastenersInColumnBeam;
	FastenersInColumnTotal := table();		# splits fasteners in beams
	FastenersInColumnDistance := table();		# distance of rows to beam edges

	for i in indices(a2_FastenersInColumn, 'indexorder', 'nolist') do			

		if  searchtext("steel", i) > 0 then
			next
		else
			beamindex := substring(i, 1..1);
		end if;
		
		if assigned(FastenersInColumnTotal[beamindex]) then
			FastenersInColumnBeam := FastenersInColumnTotal[beamindex]	# table where columns of fasteners are stored
		else
			FastenersInColumnBeam := table();
			FastenersInColumnTotal[beamindex] := eval(FastenersInColumnBeam);
			FastenersInColumnDistance[beamindex] := table();
		end if;

		# check if stored set of fasteners can be reduced or needs to be expanded
		foundmatch := false;
		if numelems(FastenersInColumnBeam) > 0 then
			for j from 1 to numelems(FastenersInColumnBeam) do
						
				if FastenersInColumnBeam[j] subset a2_FastenersInColumn[i] then
					FastenersInColumnBeam[j] := eval(a2_FastenersInColumn[i]);		# change content to new data
					foundmatch := true
				end if;

				if a2_FastenersInColumn[i] subset FastenersInColumnBeam[j] then	# new data is subset of existing
					foundmatch := true			
				end if;
				
			end do;
		else				
			FastenersInColumnBeam[1] := eval(a2_FastenersInColumn[i]);		# new line
			foundmatch := true
		end if;
		
		if foundmatch = false then
			FastenersInColumnBeam[j] := eval(a2_FastenersInColumn[i]);		# loop ends with j + 1
		end if;

	end do;		


	# calculate distances from row to left and right edge of beam
	local distL, distR, h_e, h_e_index;
	h_e := table();
	h_e_index := table();
	
	# FastenersInRowDistance
	
	for beamindex in indices(FastenersInRowTotal, 'nolist') do		# beam
		
		for i in indices(FastenersInRowTotal[beamindex], 'nolist') do		# fastener row
			
			# numelems(FastenersInRowTotal[beamindex][i]);
			distL := [];	# list of distances in row
			distR := [];
			for j in indices(FastenersInRowTotal[beamindex][i], 'nolist') do
				
				dummy := eval(FastenersInRowTotal[beamindex][i][j]);	# Fastener Point
				intPointL := cat("a_F", dummy, "BLL", beamindex);	# a_F1BLL1
				intPointR := cat("a_F", dummy, "BLR", beamindex);	# a_F1BLL1
				
				distL := [op(distL), distance[intPointL]];
				distR := [op(distR), distance[intPointR]];					
			end do;
			
			FastenersInRowDistance[beamindex][cat(i, "L")] := Statistics:-Mean(distL);
			FastenersInRowDistance[beamindex][cat(i, "R")] := Statistics:-Mean(distR);

			if assigned(h_e[cat(beamindex, "L")]) = false or h_e[cat(beamindex, "L")] < FastenersInRowDistance[beamindex][cat(i, "L")] then
				h_e[cat(beamindex, "L")] := FastenersInRowDistance[beamindex][cat(i, "L")];
				h_e_index[cat(beamindex, "L")] := i
			end if;

			if assigned(h_e[cat(beamindex, "R")]) = false or h_e[cat(beamindex, "R")] < FastenersInRowDistance[beamindex][cat(i, "R")] then
				h_e[cat(beamindex, "R")] := FastenersInRowDistance[beamindex][cat(i, "R")];
				h_e_index[cat(beamindex, "R")] := i
			end if;
			
		end do;			
		
	end do;

	distance["FastenersInRow"] := FastenersInRowTotal;
	distance["FastenersInColumn"] := FastenersInColumnTotal;
	distance["FastenersInRowDistance"] := FastenersInRowDistance;
	distance["h_e"] := h_e;					# calculated distance h_e
	distance["h_e_index"] := h_e_index;			# row index of h_e row

	# write calculated values to document
	for i in {"1", "2", "steel"} do		# beams
		for k in {"1", "2", "3", "4"} do	# distance
			dummy := cat("a", k, i);
			if ComponentExists(cat("TextArea_", dummy)) and GetProperty(cat("TextArea_", dummy), 'enabled') = "true" then
				if assigned(WhateverYouNeed["calculatedvalues"]["distance"][dummy]) then
					SetProperty(cat("TextArea_", dummy), 'visible', "true");
					SetProperty(cat("TextArea_", dummy), 'value', round(convert(WhateverYouNeed["calculatedvalues"]["distance"][dummy], 'unit_free')))
				else
					SetProperty(cat("TextArea_", dummy), 'visible', "false")
				end if;				
			end if;
		end do;			
	end do;

	#check 		
	return annotations
end proc:


PointlistGeta12 := proc(var::string, pointList::list, tolerance)
	description "Calculates a1/a2 acc. to EC5, fig. 8.7a of a pointlist";
	local val, coord1, coord2, i, a_min, a;

	a := 1000;	# default value for a1 or a2

	# get list over y coordinates
	# for a1: y-coordinates
	# for a2: x-coordinates
	coord2 := {};
	for i from 1 to nops(pointList) do
		if var = "a1" then
			coord2 := coord2 union {pointList[i][2]}
		elif var = "a2" then
			coord2 := coord2 union {pointList[i][1]}
		else
			error "Unknown variable"
		end if;
	end do;

	a_min := 0;
	# store values
	for val in coord2 do
		coord1 := {};
		for i from 1 to nops(pointList) do
			if var = "a1" then
				if abs(pointList[i][2] - val) < tolerance then
					coord1 := coord1 union {pointList[i][1]};
				end if
			elif var = "a2" then
				if abs(pointList[i][1] - val) < tolerance then
					coord1 := coord1 union {pointList[i][2]};
				end if
			end if;
		end do;

		if nops(coord1) > 1 then
			a := abs(coord1[2] - coord1[1]);
			for i from 3 to nops(coord1) do
				a := min(a, abs(coord1[i] - coord1[i-1]));
			end do;
		end if;

		if a_min = 0 or a < a_min then
			a_min := a
		end if;
	end do;

	return a_min;
end proc:


# deprecated, we do calculate all loadcases always
SetComponentsCriticalLoadcase := proc(action::string, WhateverYouNeed::table)
	local maxloadedFastener;
	
	if action = "activate" then
		if ComponentExists("TextArea_loadcaseMax") and ComponentExists("TextArea_criticalnodeAllloadcases") and
			ComponentExists("TextArea_xMax") and ComponentExists("TextArea_yMax") then

			SetProperty("TextArea_loadcaseMax", 'enabled', "true");
			# SetProperty("MathContainer_maxF", 'enabled', "true");
			# SetProperty("MathContainer_maxF_Fx", 'enabled', "true");
			# SetProperty("MathContainer_maxF_Fy", 'enabled', "true");
			SetProperty("TextArea_xMax", 'enabled', "true");
			SetProperty("TextArea_yMax", 'enabled', "true");

			maxloadedFastener := WhateverYouNeed["results"]["maxloadedFastener"];
			
			SetProperty("MathContainer_FxMax", 'value', round2(maxloadedFastener["Fx"], 2));
			SetProperty("MathContainer_FyMax", 'value', round2(maxloadedFastener["Fy"], 2));
			SetProperty("MathContainer_FMax", 'value', round2(maxloadedFastener["F"], 2));
			SetProperty("MathContainer_alphaMax", 'value', round2(maxloadedFastener["alpha"], 2));
			SetProperty("TextArea_xMax", 'value', round2(maxloadedFastener["x"], 2));
			SetProperty("TextArea_yMax", 'value', round2(maxloadedFastener["y"], 2));
			SetProperty("TextArea_loadcaseMax", 'value', round2(maxloadedFastener["loadcase"], 2));
			SetProperty("TextArea_criticalnodeAllloadcases", 'value', round2(maxloadedFastener["fastener"], 2));				
		end if;
		
	elif action = "deactivate" then
		if ComponentExists("TextArea_loadcaseMax") and ComponentExists("TextArea_criticalnodeAllloadcases") and
			ComponentExists("TextArea_xMax") and ComponentExists("TextArea_yMax") then
				
			SetProperty("TextArea_loadcaseMax", 'enabled', "false");
			# SetProperty("MathContainer_maxF", 'enabled', "false");
			# SetProperty("MathContainer_maxF_Fx", 'enabled', "false");
			# SetProperty("MathContainer_maxF_Fy", 'enabled', "false");
			SetProperty("TextArea_xMax", 'enabled', "false");
			SetProperty("TextArea_yMax", 'enabled', "false");
		end if;
	end if;
end proc:


BeamsideForceDirection := proc(beamindex::string, WhateverYouNeed::table)::string;
	description "returns beamside, in which direction force is pointing to";
	local calculations, activesettings, warnings, beamside, loadcase, force, alphaForce, Fx, Fy, alphaBeam, alphaDelta, Fx_, Fy_, activeFastenerPattern;

	calculations := WhateverYouNeed["calculations"];	
	activesettings := calculations["activesettings"];	
	warnings := WhateverYouNeed["warnings"];
	loadcase := activesettings["activeloadcase"];
	activeFastenerPattern := activesettings["activeFastenerPattern"];
	force := eval(calculations["loadcases"][loadcase]);

	if WhateverYouNeed["calculations"]["structure"]["FastenerPatterns"][activeFastenerPattern]["reactionforces"] = "true" then
		Fx := -force["F_hd"];
		Fy := -force["F_vd"];			
	else
		Fx := force["F_hd"];
		Fy := force["F_vd"];	
	end if;	

	Fx_ := convert(Fx, 'unit_free');
	Fy_ := convert(Fy, 'unit_free');
	
	if Fx = 0 and Fy = 0 then
		alphaForce := 0
	else
# Bug appears here, support case 00156673
		# alphaForce := convert(arctan(Fy, Fx) * Unit('radian'), 'units', 'degree')
		alphaForce := convert(arctan(Fy_, Fx_) * Unit('radian'), 'units', 'degree')
	end if;		

	alphaBeam := evalf(WhateverYouNeed["calculations"]["structure"]["connection"][cat("graindirection", beamindex)]);

	alphaDelta := alphaForce - alphaBeam;
	
	if alphaDelta < 0 then
		alphaDelta := alphaDelta + 360 * Unit('degree')
	end if;

	if alphaDelta = 0 then
		beamside := "E"
	elif alphaDelta > 0 and alphaDelta < 180 * Unit('degree') then
		beamside := "L"
	elif alphaDelta = 180 * Unit('degree') then			
		beamside := "S"
	elif alphaDelta > 180 * Unit('degree') and alphaDelta < 360 * Unit('degree') then
		beamside := "R"
	else
		Alert(cat("BeamsideForceDirection: wrong angle: ", alphaDelta), warnings, 4);
		beamside := "Unknown"
	end if;

	return beamside
end proc:


BlockShearPath := proc(WhateverYouNeed::table)::list;
	uses NODEFunctions, DocumentTools, Units[Simple];
	description "Block Shear and Plug Shear failure at multiple dowel-type steel-to-timber connections";
	local structure, fasteners, fastenerPointlist, beamBoundarylines, FastenersInColumn, i, beamBoundaryline, dummy, beamindex, beamside, dist, segments, 
			lvmax, llmin, lrmin, lvmaxPoints, llminPoints, lrminPoints, BlockShear, a3side, distance, dummy1, j, d_,
			lparline, rparline, vperpline, Ptvl, Ptvr, Pl, Pr, geometryList, lvl, lvr, lt;

	structure := WhateverYouNeed["calculations"]["structure"]; 
	fasteners := WhateverYouNeed["results"]["FastenerGroup"]["Fasteners"];     					# matrix with fastener point coordinates	
	fastenerPointlist := WhateverYouNeed["calculatedvalues"]["graphicsElements"]["fastenerPointlist"];
	beamBoundarylines := WhateverYouNeed["calculatedvalues"]["graphicsElements"]["beamBoundarylines"];	# BLL1: boundary line beam 1, Left (Right, Start, End)
	FastenersInColumn := WhateverYouNeed["calculatedvalues"]["distance"]["FastenersInColumn"];
	distance := WhateverYouNeed["calculatedvalues"]["distance"];
	d_ := convert(structure["fastener"]["fastener_d"], 'unit_free');

	dist := distance["dist"]; 		# calculated in NODEFastenerPattern:-calculate_a
	segments := distance["segments"];
	lvmax := 0;
	llmin := 0;
	lrmin := 0;
	lvmaxPoints := {};
	llminPoints := {};
	lrminPoints := {};
	geometryList := [];

	BlockShear := table();

	if structure["connection"]["connection1"] = "Steel" or structure["connection"]["connection2"] = "Steel" then
				
		for i from 1 to numelems(fastenerPointlist) do				# F1, F2,...
			
			for beamBoundaryline from 1 to numelems(beamBoundarylines) do	# BLL1: boundary line beam 1, Left (Right, Start, End)
				
				if searchtext("steel", beamBoundarylines[beamBoundaryline]) = 0 then
					beamindex := substring(convert(beamBoundarylines[beamBoundaryline], string), -1..-1);
					beamside := substring(convert(beamBoundarylines[beamBoundaryline], string), -2..-2);
				else
					next
				end if;

				dummy := cat("a_", convert(fastenerPointlist[i], string), convert(beamBoundarylines[beamBoundaryline], string));	# a_F1BLL1

				a3side := WhateverYouNeed["calculatedvalues"]["distance"][cat("a3", beamindex, "side")];		# beam end side for a3 distance
				
				if beamside = a3side then		# S or E, find point furthers away from edge end
									
					if dist[dummy] > lvmax then
						lvmax := dist[dummy];
						lvmaxPoints := {i};
						geometry:-PerpendicularLine(vperpline, fastenerPointlist[i], parse(cat("BLL", beamindex)));
					
					elif dist[dummy] < lvmax + d_ then
						lvmaxPoints := lvmaxPoints union {i}
					
					end if;

					# check if existing points in list is outside new lvmax - d
					for j in lvmaxPoints do

						dummy1 := cat("a_", convert(fastenerPointlist[j], string), convert(beamBoundarylines[beamBoundaryline], string));	# a_F1BLL1							
						if dist[dummy1] < lvmax - d_ then
							lvmaxPoints := lvmaxPoints minus {j};
						end if;
							
					end do;					
					
				elif beamside = "L" or beamside = "R" then

					if beamside = "L" then

						if dist[dummy] < llmin or llmin = 0 then							
							
							llmin := dist[dummy];
							llminPoints := llminPoints union {i};
							geometry:-ParallelLine(lparline, fastenerPointlist[i], parse(cat("BLL", beamindex)));
							geometry:-intersection(Pl, lparline, parse(cat("BL", a3side, beamindex)));	# intersection point with beam start/end
							
						elif dist[dummy] < llmin + d_ then							
							llminPoints := llminPoints union {i}						
						end if;

						# check if existing points in list is outside new llmin + d
						for j in llminPoints do

							dummy1 := cat("a_", convert(fastenerPointlist[j], string), convert(beamBoundarylines[beamBoundaryline], string));	# a_F1BLL1							
							if dist[dummy1] > llmin + d_ then					
								llminPoints := llminPoints minus {j};						
							end if;
							
						end do;					
					
					elif beamside = "R" then

						if dist[dummy] < lrmin or lrmin = 0 then
							lrmin := dist[dummy];
							lrminPoints := lrminPoints union {i};
							geometry:-ParallelLine(rparline, fastenerPointlist[i], parse(cat("BLL", beamindex)));
							geometry:-intersection(Pr, rparline, parse(cat("BL", a3side, beamindex)));	# intersection point with beam start/end
							
						elif dist[dummy] < lrmin + d_ then
							lrminPoints := lrminPoints union {i}
						end if;

						# check if existing points in list is outside new lrmin + d
						for j in lrminPoints do

							dummy1 := cat("a_", convert(fastenerPointlist[j], string), convert(beamBoundarylines[beamBoundaryline], string));	# a_F1BLL1							
							if dist[dummy1] > lrmin + d_ then
								lrminPoints := lrminPoints minus {j};							
							end if;
							
						end do;
						
					end if;														
					
				end if;
				
			end do;
			
		end do;

		# find intersection points between parallel line and perpline
		geometry:-intersection(Ptvl, lparline, vperpline);				# intersection point between v-line and t-line left side
		geometry:-intersection(Ptvr, rparline, vperpline);				# intersection point between v-line and t-line right side

		# calculate distances	
		dist["a_lvl"] := evalf(geometry:-distance(Pl, Ptvl)) - d_ * (numelems(llminPoints) - 0.5);	# assume fastener in edge point
		dist["a_lvr"] := evalf(geometry:-distance(Pr, Ptvr)) - d_ * (numelems(lrminPoints) - 0.5);
		dist["a_lt"] := evalf(geometry:-distance(Ptvl, Ptvr))  - d_ * (numelems(lvmaxPoints) - 1);		# assuming fasteners in both edge points

		BlockShear["lvmax"]:= lvmax;
		BlockShear["llmin"]:= llmin;
		BlockShear["lrmin"]:= lrmin;
		BlockShear["lvmaxPoints"] := lvmaxPoints;
		BlockShear["llminPoints"] := llminPoints;
		BlockShear["lrminPoints"] := lrminPoints;
		WhateverYouNeed["calculatedvalues"]["BlockShear"] := BlockShear;

		# segments
		geometry:-segment(lvl, Pl, Ptvl);
		geometry:-segment(lvr, Pr, Ptvr);
		geometry:-segment(lt, Ptvl, Ptvr);

		# send back Block Shear path
		geometryList := [op(geometryList), lvl('color' = "coral", 'linestyle' = dashdot), 
									lvr('color' = "coral", 'linestyle' = dashdot),
									lt('color' = "coral", 'linestyle' = dashdot)];	

	else
		# no check necessary
		
	end if;	

	return geometryList

end proc:


CheckPointInPolygon := proc(WhateverYouNeed::table)::boolean;
	description "Check if point is inside a polygon";
	local structure, dummy, part, beamPoints, polygon, beamBoundarylines, fastenerPointlist, beamnumber, i, j, InsidePolygon;

	structure := WhateverYouNeed["calculations"]["structure"];
	beamPoints := WhateverYouNeed["calculatedvalues"]["graphicsElements"]["beamPoints"];
	fastenerPointlist := WhateverYouNeed["calculatedvalues"]["graphicsElements"]["fastenerPointlist"];
	beamnumber := table();
	InsidePolygon := true;

	for part from 1 to 2 do
		
		polygon := [];

		# get index of part
		if assigned(structure["connection"][cat("connection", part)]) then
			if structure["connection"][cat("connection", part)] = "Timber" then
				beamnumber[part] := convert(part, string)
			elif structure["connection"][cat("connection", part)] = "Steel" then
				beamnumber[part] := "steel"
			end if
		end if;

		for dummy in ["BSL", "BEL", "BER", "BSR"] do		
			for j in entries(beamPoints, 'nolist') do
				if convert(j, string) = cat(dummy, beamnumber[part]) then
					polygon := [op(polygon), geometry:-coordinates(j)];			# add element to the list					
				end if;
			end do;
		end do;

		# check if fastener points are inside polygon
		for i from 1 to numelems(fastenerPointlist) do
			if ComputationalGeometry:-PointInPolygon(geometry:-coordinates(fastenerPointlist[i]), polygon) <> "inside" then
				InsidePolygon := false;
				Alert(cat("Fastener point ", i, " is outside beam ", i), WhateverYouNeed["warnings"], 4);
			end if;
		end do;

	end do;

	return InsidePolygon

end proc: