# NODEXML.mm : subroutines for reading and writing XML files
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
	
	# XMLFileInOut := proc(action::string, projectdata::table, componentVariables::table, material::string, materials::list, materialdata::table, section::table, sections::list, calculations::table, 
	# 				structure::table, loadcases::table, warnings::table)

	XMLFileInOut := proc(action::string, WhateverYouNeed::table)
		uses DocumentTools;
		description "Write out data to xml file";
		local items, i, successful, parent, child, dummy, storeitems;

		# get set of saveable items
		storeitems := {};
		for dummy in WhateverYouNeed["componentvariables"]["var_storeitems"] do
			
			if searchtext("/", dummy) > 0 then 		# "calculations/positionnumber"
				parent := StringTools:-Split(dummy, "/")[1];
				child := StringTools:-Split(dummy, "/")[2];
				storeitems := storeitems union {parent}
			else
				storeitems := storeitems union {dummy}
			end if;
		end do;

		# check if saveable items should be saved		
		items := {};
		for i in storeitems do		#{"projectdata", "materials", "sections", "calculations"}
			if ComponentExists(cat("CheckBox_", i)) then
				if GetProperty(cat("CheckBox_", i), 'enabled') = "true" and GetProperty(cat("CheckBox_", i), 'value') = "true" then
					items := items union {i};
				end if
			end if;
		end do;

		if action = "export" then
			successful := checkBeforeWriteout(items, WhateverYouNeed); 	# need to check if materials or sections that are used are also saved in list of active materials
			if successful then
				XMLWrite(items, WhateverYouNeed)
			end if;
					
		elif action = "import" then
			successful := XMLImport(items, WhateverYouNeed);
			runAfterXMLImport(successful, WhateverYouNeed);	# local routines to be run after XMLImport
			
		else
			Alert(cat("XMLFileInOut unknown command: ", action), WhateverYouNeed["warnings"], 3)
		end if;
	
	end proc:


	XMLImport := proc(items::set, WhateverYouNeed::table)
		description "Import from XML file";
		uses DocumentTools;
		local var_projectdata, xmldata, materials, sections, material, componentVariables, warnings, calculationtype;
		local i, counter, rqdata, projectdata, successful, logXMLImport;

		material := WhateverYouNeed["material"];
		componentVariables := WhateverYouNeed["componentvariables"];
		warnings := WhateverYouNeed["warnings"];
		calculationtype := WhateverYouNeed["calculations"]["calculationtype"];
		logXMLImport := "XMLImport \n import";

		rqdata := [];
		var_projectdata := componentVariables["var_projectdata"];
		# var_materials := componentVariables["var_materials"];
		# var_sections := componentVariables["var_sections"];
		# var_calculations := componentVariables["var_calculations"];
	
		# get data
		if member("projectdata", items) then
			rqdata := [op(rqdata), ["projectdata", ["all"]]];
		end if;

		if member("materials", items) then
			rqdata := [op(rqdata), ["materials", material, ["all"]]];
		end if;

		if member("sections", items) then
			rqdata := [op(rqdata), ["sections", material, ["all"]]];
		end if;

		if member("calculations", items) then
			rqdata := [op(rqdata), ["calculations", calculationtype, ["all"]]];
		end if;

		# this one is the main routine, where we fetch the ordered items from the XML file
		xmldata, successful := XMLRead(rqdata, WhateverYouNeed);
		if successful = false then
			return successful
		end if;

		# read data
		for counter from 1 to numelems(rqdata) do

			if rqdata[counter][1] = "projectdata" then
				
				projectdata := table();
				WhateverYouNeed["projectdata"] := projectdata;
				
				# store values in global variable
				for i in indices(xmldata[counter], 'nolist') do
					projectdata[i] := eval(xmldata[counter][i]);
					var_projectdata := var_projectdata minus {i}
				end do;
		 
				if numelems(var_projectdata) > 0 then
					Alert(cat("projectdata: variables not defined in file: ", convert(var_projectdata, string)), warnings, 2);
				end if;

				logXMLImport := cat(logXMLImport, ", projectdata");
			
			elif rqdata[counter][1] = "materials" then					
				# if nops(xmldata[counter]) = 0 then
				#	Alert("Ingen gyldig material i xml fil funnet");
				#	return;
				# end if;

				materials := table();		
				WhateverYouNeed["materials"] := materials;		# table of materials

				# store values in global variable
				for i in indices(xmldata[counter], 'nolist') do
					materials[i] := eval(xmldata[counter][i]);
				end do;

				logXMLImport := cat(logXMLImport, ", materials");

			elif rqdata[counter][1] = "sections" then					
				sections := table();
				WhateverYouNeed["sections"] := sections;

				# store values in global variable
				for i in indices(xmldata[counter], 'nolist') do
					sections[i] := eval(xmldata[counter][i]);
				end do;

				logXMLImport := cat(logXMLImport, ", sections");

			elif rqdata[counter][1] = "calculations" then					
				if nops(xmldata[counter]) = 0 then
					Alert("No valid calculation found in file", warnings, 2);
					successful := false;
					return successful;
				end if;

				logXMLImport := cat(logXMLImport, ", calculations \n");

				for i in indices(xmldata[counter], 'nolist') do	# {"materialdata", "section", "structure", "calculations", "loadcases"} "positionnumber", "positiontitle", "calculationtype"

					if type(eval(xmldata[counter][i]), string) then
						WhateverYouNeed["calculations"][i] := eval(xmldata[counter][i]);						
						
					elif type(eval(xmldata[counter][i]), table) then
						if member(i, GetStoreitemsCalculations(WhateverYouNeed)) then
							WhateverYouNeed["calculations"][i] := eval(xmldata[counter][i]);
						else
							Alert(cat("Unknown element ", i), warnings, 2);
						end if
						
					else
						Alert(cat("Unknown type ", whattype(xmldata[counter][i]), " variable: ", i, ", ", eval(xmldata[counter][i])), warnings, 2);
						
					end if;
					
					logXMLImport := cat(logXMLImport, "...", i, " imported \n");
				end do;
			end if;
		
		end do;
		WhateverYouNeed["logs"]["XMLImport"] := logXMLImport;		
		return successful
	end proc:


	XMLWrite := proc(exportItems::set, WhateverYouNeed::table)
		description "Write out XML file";
		uses Maplets[Elements], XMLTools;
		local xmltree, xmlmaterials, xmlMaterial, xmlencoding, xmlcomment, xmlversion, software, material, materials, ind, ind1, j, n, item;
		local xmlSection, xmlsections, section, sections;
		local xmlCalculation, xmlcalculations, xmlcalculationtype, calculationtype;
		local xmlprojectdata;
		local maplet, afilename, action, writeposition, foundcalculationtype, mainType;

		# open file dialogue box, and 
		# https://www.mapleprimes.com/questions/230384-File-Open-Dialogue-Box
		maplet := Maplet(FileDialog['FD2']('filefilter' = "xml", 'filterdescription' = "XML file", 'onapprove' = Shutdown(['FD2']), 'oncancel' = Shutdown()));
		afilename := Maplets[Display](maplet);
		if type(afilename, list) then
			afilename := afilename[1];
			if searchtext(".xml", afilename, -4..-1) = 0 then				# mest sannsynlig ny fil, xml ending ikke lagt inn
				afilename := cat(afilename , ".xml")
			end if;
			if FileTools[Exists](afilename) then						# filnavn existerer allerede, merge eller overwrite ?
				maplet := Maplet(QuestionDialog("File exists already: Make new file (Yes) or update content (No)?",	'onapprove'=Shutdown("overwrite"), 'ondecline'=Shutdown("merge")));
				action := Maplets[Display](maplet);
			else
				action := "overwrite";
			end if;
		else
			return
		end if;		

		if action = "overwrite" then	# lager ny fil
			xmlversion := "2024.11";
			software := "NODE common file format, generated via Maple";
			xmltree := XMLElement("database", ["version" = xmlversion, "source_software" = software]);	# general information
		else	# merge
			xmltree := CleanXML(ParseFile(afilename, prolog = true));
		end if;
		
		for mainType in exportItems do		#"projectdata", "materials", "sections", "calculations"
			n := ContentModelCount(xmltree);
			writeposition := 1;

			# Adding projectdata information, always in first position in XML file
			if mainType = "projectdata" then
					
				xmlprojectdata := XMLElement("projectdata");
				for item in indices(WhateverYouNeed["projectdata"], 'nolist') do
					xmlprojectdata := AddAttribute(xmlprojectdata, item, WhateverYouNeed["projectdata"][item])
				end do;
				
				if numelems(GetChildByName(xmltree, "projectdata")) > 0 then
					xmltree := ReplaceChild(writeposition = xmlprojectdata, xmltree);
				else	# no projectdata definition stored in file yet
					xmltree := AddChild(xmltree, xmlprojectdata, min(n, writeposition-1));
				end if;
	
				# Adding structural structure information
				# xmlstructure := XMLElement("structure", ["structuralstructure" = convert(structuralstructure, string), "length" = convert(lg, string)]);
				# dummy := XMLElement("sectiondata", ["height" = convert(height, string), "E" = convert(E, string), "Iy" = convert(Iy, string), "alphaT" = convert(alphaT, string)]);
				# xmlstructure := AddChild(xmlstructure, dummy, 0);
				# xmltree := AddChild(xmltree, xmlstructure, 1)

			elif mainType = "materials" then

				if numelems(GetChildByName(xmltree, "projectdata")) > 0 then
					writeposition := 2
				end if;
			
				material := WhateverYouNeed["material"];			# "timber"
				materials := WhateverYouNeed["materials"];		# table of materials
			
				if material = "timber" then
					xmlMaterial := XMLMaterialTimber(materials)		# Materialspesifikke xml elementer blir generert i eget rutine
				elif material = "concrete" then
					xmlMaterial := XMLMaterialConcrete(materials)
				elif material = "steel" then
					xmlMaterial := XMLMaterialSteel(materials)
				else
					Alert("Error in XMLWrite: material invalid", WhateverYouNeed["warnings"], 4)
				end if;

				if numelems(GetChildByName(xmltree, "materials")) > 0 then
					xmlmaterials := GetChildByName(xmltree, "materials")[1];								# GetChildByName returns list, need to go into list
					if ContentModelCount(xmlmaterials) > 0 then											# det finnes allerede noen materialer som er definert i listen
						if numelems(GetChildByName(xmlmaterials, material)) = 0 then						# materialet er ikke definert enn�, legg til material p� slutten av listen
							xmlmaterials := AddChild(xmlmaterials, xmlMaterial, ContentModelCount(xmlmaterials));
						else
							for ind from 1 to ContentModelCount(xmlmaterials) do
								if ElementName(GetChild(xmlmaterials, ind)) = material then
									xmlmaterials := ReplaceChild(ind = xmlMaterial, xmlmaterials);			# erstatt eksisterende definisjon av timber med ny
								end if;
							end do;
						end if;
					else
						xmlmaterials := AddChild(xmlmaterials, xmlMaterial, ContentModelCount(xmlmaterials))		# legg til material p� slutten av listen
					end if;
					xmltree := ReplaceChild(writeposition = xmlmaterials, xmltree);							# deretter m� ogs� xmlmaterials erstattes/oppdateres i xmltree, material i 1. posisjon
					
				else # materials definisjon mangler ogs�
					xmlmaterials := XMLElement("materials");
					xmlmaterials := AddChild(xmlmaterials, xmlMaterial, 0);
					xmltree := AddChild(xmltree, xmlmaterials, min(n, writeposition-1));
				end if;
				
			elif mainType = "sections" then
				
				if numelems(GetChildByName(xmltree, "projectdata")) > 0 then
					writeposition := 2
				end if;
				if numelems(GetChildByName(xmltree, "materials")) > 0 then
					writeposition := writeposition + 1
				end if;
				
				# section := WhateverYouNeed["section"];
				section := WhateverYouNeed["material"];
				sections := WhateverYouNeed["sections"];
				
				if section = "steel" then
					xmlSection := XMLSectionSteel(sections)
				elif section = "timber" then
					xmlSection := XMLSectionTimber(sections)
				else
					Alert("Error in XMLWrite: section material invalid", WhateverYouNeed["warnings"], 4);
				end if;

				if numelems(GetChildByName(xmltree, "sections")) > 0 then
					xmlsections := GetChildByName(xmltree, "sections")[1];								# GetChildByName returns list, need to go into list
					if ContentModelCount(xmlsections) > 0 then										# det finnes allerede noen tverrsnitt som er definert i listen
						if numelems(GetChildByName(xmlsections, section)) = 0 then						# tverrsnitt ikke definert enn�, legg til p� slutten av listen
							xmlsections := AddChild(xmlsections, xmlSection, ContentModelCount(xmlsections));
						else
							for ind from 1 to ContentModelCount(xmlsections) do
								if ElementName(GetChild(xmlsections, ind)) = section then
									xmlsections := ReplaceChild(ind = xmlSection, xmlsections);			# erstatt eksisterende definisjon av tverrsnitt med ny
								end if;
							end do;
						end if;
					else
						xmlsections := AddChild(xmlsections, xmlSection, 0)							# legg til tverrsnitt
					end if;
					xmltree := ReplaceChild(writeposition = xmlsections, xmltree);						# deretter m� ogs� xmlsections erstattes/oppdateres i xmltree, tverrsnitt vanligvis i 2. posisjon
					
				else # tverrsnitt definisjon mangler ogs�
					xmlsections := XMLElement("sections");
					xmlsections := AddChild(xmlsections, xmlSection, 0);
					xmltree := AddChild(xmltree, xmlsections,  min(n, writeposition-1));					# legges p� slutten, kan v�re i 1. eller 2. posisjon, litt avhengig om det er definert section i filen allerede
				end if;

			elif mainType = "calculations" then

				# get new write position in xml file
				if numelems(GetChildByName(xmltree, "projectdata")) > 0 then
					writeposition := 2
				end if;
				if numelems(GetChildByName(xmltree, "materials")) > 0 then
					writeposition := writeposition + 1
				end if;
				if numelems(GetChildByName(xmltree, "sections")) > 0 then
					writeposition := writeposition + 1
				end if;

				# check what to write out in calculation
				# materialdata, section, structure, calculations, loadcases
				
				calculationtype := WhateverYouNeed["calculations"]["calculationtype"];			# "NS-EN 1995-1-1, part 1-1, Section 6: Ultimate limit state design principles"
				xmlCalculation := XMLCalculations(WhateverYouNeed);

				if numelems(GetChildByName(xmltree, "calculations")) > 0 then
					
					xmlcalculations := GetChildByName(xmltree, "calculations")[1];						# GetChildByName returns list, need to go into list
					
					if ContentModelCount(xmlcalculations) > 0 then									# det finnes allerede noen beregninger i listen

						# find if there is a calculation of that type already
						foundcalculationtype := 0;
						for j from 1 to ContentModelCount(xmlcalculations) do
							if HasAttribute(GetChild(xmlcalculations, j), "calculationtype") then
								if AttributeValue(GetChild(xmlcalculations, j), "calculationtype") = calculationtype then
									foundcalculationtype := j;
								end if;
							else
								Alert("Warning: calculation missing attribute 'calculationtype'", WhateverYouNeed["warnings"], 2)
							end if;
						end do;
						
						if foundcalculationtype = 0 then			# this type of calculation is not defined yet
							
							xmlcalculationtype := XMLElement("calculation", ["calculationtype" = calculationtype]);
							xmlcalculationtype := AddChild(xmlcalculationtype, xmlCalculation, 0);
							xmlcalculations := AddChild(xmlcalculations, xmlcalculationtype, ContentModelCount(xmlcalculations) - 1);		# add at end of other calculations
							
						else		# calculationtype already exists
														
							xmlcalculationtype := GetChild(xmlcalculations, foundcalculationtype);

							if ContentModelCount(xmlcalculationtype) > 0 then				# calculationtype defined, some calculations defined already

								# find if there is a calculation with the same positionnumber already
								local samecalculationfound, positionnumber;
								samecalculationfound := 0;
										
								for ind1 from 1 to ContentModelCount(xmlcalculationtype) do		# find calculation with same positionnumber and replace
											
									if HasAttribute(GetChild(xmlcalculationtype, ind1), "positionnumber") then
										positionnumber := AttributeValue(GetChild(xmlcalculationtype, ind1), "positionnumber");
										if positionnumber = WhateverYouNeed["calculations"]["positionnumber"] then
											samecalculationfound := ind1;
										end if;
									else
										Alert("Warning: Calculation missing attribute 'positionnumber'", WhateverYouNeed["warnings"], 2);
									end if;

								end do;
									
								if samecalculationfound = 0 then
									xmlcalculationtype := AddChild(xmlcalculationtype, xmlCalculation, ContentModelCount(xmlcalculationtype));
								else
									xmlcalculationtype := ReplaceChild(samecalculationfound = xmlCalculation, xmlcalculationtype);
								end if;
										
							else						# calculationtype defined already, but empty
									
								xmlcalculationtype := AddChild(xmlcalculationtype, xmlCalculation, 0);
																			
							end if;
							xmlcalculations := ReplaceChild(foundcalculationtype = xmlcalculationtype, xmlcalculations);
									
						end if;
						
					else	# calculations defined in file, but empty

						xmlcalculationtype := XMLElement("calculation", ["calculationtype" = calculationtype]);
						xmlcalculationtype := AddChild(xmlcalculationtype, xmlCalculation, 0);
						xmlcalculations := AddChild(xmlcalculations, xmlcalculationtype, 0);
						
					end if;
					xmltree := ReplaceChild(writeposition = xmlcalculations, xmltree);					# deretter m� ogs� xmlsections erstattes/oppdateres i xmltree, calculations vanligvis i 4. posisjon
					
				else # no calculations stored in file yet
					xmlcalculations := XMLElement("calculations");
					xmlcalculationtype := XMLElement("calculation", ["calculationtype" = calculationtype]);
					xmlcalculationtype := AddChild(xmlcalculationtype, xmlCalculation, 0);
					xmlcalculations := AddChild(xmlcalculations, xmlcalculationtype, 0);
					xmltree := AddChild(xmltree, xmlcalculations,  min(n, writeposition-1));				# legges p� slutten, litt avhengig om det er definert section i filen allerede
																							# Maple 2023 bug: https://mapleprimes.com/questions/236887-UnitsSimple-Min--Bug
					
				end if;

			else
				
				Alert(cat(mainType, " undefined command for XML import"), WhateverYouNeed["warnings"], 4)
			end if;
			
		end do;
	
		# writeout
		# https://www.mapleprimes.com/questions/230385-XMLTools--File-Formatting
		# Get afilename
	
		xmlencoding := "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
		xmlcomment := "<!-- (c) NODE radgivende ingenioerer AS 2020, https://www.node.no -->\n";
		xmltree := cat(xmlencoding, xmlcomment, PrintToString(xmltree));
		FileTools:-Text:-WriteString(afilename, xmltree);
		fclose(afilename);

	end proc:


	XMLRead := proc(requesteddata::list, WhateverYouNeed::table)
		description "Read in XML file";
		uses Maplets[Elements], XMLTools;
		# local projecttitle, projectnumber, position, designer;
		local xmlprojectdata, xmlversion, software, xmlmaterial;
		local xmlsection, xmlsections, xmlsectiondefinition;
		local xmltree, xmlmaterials, xmlmaterialdefinition;
		local dummy, xmlitems, xmldummy, xmldummy1, xmldummy2;
		local xmlcalculation, xmlcalculations, foundcalculationtype, xmlcalculationtype, posnumber, posindex, pickedvalue;
		local afilename, i, j, k, m, n, p, q, maplet, returndata, returndata1, returndata2, returndata3, returndata4, returndata5, nameIndex, rq2, rq3, successful, warnings;

		warnings := WhateverYouNeed["warnings"];
		returndata := [];

		# get filename
		# https://www.mapleprimes.com/questions/230384-File-Open-Dialogue-Box
		maplet := Maplet(FileDialog['FD2']('filefilter' = "xml", 'filterdescription' = "XML file", 'onapprove' = Shutdown(['FD2']), 'oncancel' = Shutdown()));
		afilename := Maplets[Display](maplet);
		if type(afilename, list) = false then
			Alert("File could not be opened", warnings, 5);
			successful := false;
			return returndata, successful;
		elif FileTools[Exists](afilename[1]) = false then
			Alert("File could not be opened", warnings, 5);
			successful := false;
			return returndata, successful;
		else
			afilename := afilename[1];
			successful := true
		end if;

		# requested data is a list and can have this format
		# 1.) chapter to read, e.g. "projectdata", "material", "section" or "all"
		# 2.) material to read, e.g. "timber", "steel", "concrete" or "all"
		# 3.) specific item to return, e.g. "name", or "all"
		# there can be multiple items in the list
		# [["material", "timber", "name"]]
	

		xmltree := CleanXML(ParseFile(afilename, prolog = true));	# https://www.mapleprimes.com/questions/230537-XMLTools--FirstChild

		# .xsd file check - unsure if it is working yet
		# https://www.mapleprimes.com/questions/239423-XMLTools--Validate--Schema-Location?sq=239423
		# XMLTools:-Validate(xmltree, schema = "NODEMaple.xsd");
		
		# logfile := FileTools[Text][Open]((cat(afilename,".log"), create, overwrite));		# create logfile in same directory as xml file
		# FileTools[Text][WriteString](logfile, cat("logfile for file ", afilename, "\n"));

		# har absolutt ingen anelse hva dette her gj�r, men kanskje det fikser problemer med HasChild p� XMLDocuments
		# https://www.mapleprimes.com/questions/230855-XMLTools--HasChild
		# xmltree := subsindets(xmltree, function, s -> setattribute(s, ':-inert'));

		# Header information
		# MyContent := ProcessAttributes(xmltree, {"version", "source_software"}, AttributeValues, 'name' = 'database');
		
		if HasAttribute(xmltree, "source_software") then
			software := AttributeValue(xmltree, "source_software");		# Koyaanisqatsi
		end if;
		
		if HasAttribute(xmltree, "version") then
			xmlversion := AttributeValue(xmltree, "version");					# 2020.08
		end if;

	
		# FileTools[Text][WriteString](logfile, cat("source software: ", software, "\t version: ", xmlversion, "\n"));

		# read projectdata information
		# if HasChild(xmltree, XMLElement("projectdata")) then				fungerer ikke, se https://www.mapleprimes.com/questions/230855-XMLTools--HasChild



		for i from 1 to nops(requesteddata) do		# outer list, go through requests
			
			# outer loop for requested data
			# "projectdata", "material", "section", "all"

			if requesteddata[i][1] = "projectdata" then
				
				if numelems(GetChildByName(xmltree, "projectdata")) > 0 then				# workaround
					rq2 := requesteddata[i][2];			# "all"
					returndata1 := table();
					
					xmlprojectdata := GetChildByName(xmltree, "projectdata")[1];			# GetChildByName returns list, need to go into list

					for n from 1 to nops(rq2) do		# got through requested values

						if HasAttribute(xmlprojectdata, rq2[n]) = true then		# found requested attribute value in xml file
							returndata1[rq2[n]] := AttributeValue(xmlprojectdata, rq2[n]);
						elif rq2[n] = "all" then
							for p in AttributeNames(xmlprojectdata) do
								returndata1[p] := AttributeValue(xmlprojectdata, p);
							end do
						end if;
								
					end do;
					
				end if;
				
			elif requesteddata[i][1] = "materials" then

				rq2 := requesteddata[i][2];			# "timber", "steel", "concrete" or "all"
				rq3 := requesteddata[i][3];			# this one needs to be a list with what is requested
				returndata1 := table();
				
				if numelems(GetChildByName(xmltree, "materials")) > 0 then

					for j from 1 to numelems(GetChildByName(xmltree, "materials")) do	# det burde bare v�re 1 materials definition i filen
							
						xmlmaterials := GetChildByName(xmltree, "materials")[j];		# GetChildByName returns list, need to go into list

						if numelems(GetChildByName(xmlmaterials, rq2)) > 0 then		# find requested material class

							for k from 1 to numelems(GetChildByName(xmlmaterials, rq2)) do		# get material classes (concrete, timber, steel), should just return one value

								xmlmaterialdefinition := GetChildByName(xmlmaterials, rq2)[k];			# get desired material class
								xmlmaterial := GetChildByName(xmlmaterialdefinition, "material");		# list of all data of defined material

								for m from 1 to numelems(xmlmaterial) do							# go through materials definition list
									returndata2 := table();		# store values of what needs to be returned
							
									for n from 1 to nops(rq3) do		# got through requested values

										if HasAttribute(xmlmaterial[m], rq3[n]) = true then		# found requested attribute value in xml file
											returndata2[rq3[n]] := AttributeValue(xmlmaterial[m], rq3[n]);
											
										elif rq3[n] = "all" then
											
											for p in AttributeNames(xmlmaterial[m]) do
												returndata2[p] := AttributeValue(xmlmaterial[m], p);
											end do
										end if;
									
									end do;
									returndata1[AttributeValue(xmlmaterial[m], "name")] := eval(returndata2);
								end do;
								
							end do;
							
						else 	# material not found
						end if;				
						
					end do;
					
				else	# didn't find any materials in xml file			
				end if;
				
			elif requesteddata[i][1] = "sections" then
				
				rq2 := requesteddata[i][2];			# "timber", "steel", "concrete" or "all"
				rq3 := requesteddata[i][3];			# this one needs to be a list with what is requested
				returndata1 := table();	

				if numelems(GetChildByName(xmltree, "sections")) > 0 then

					for j from 1 to numelems(GetChildByName(xmltree, "sections")) do	
							
						xmlsections := GetChildByName(xmltree, "sections")[j];		# GetChildByName returns list, need to go into list

						if numelems(GetChildByName(xmlsections, rq2)) > 0 then		# find requested section material class

							for k from 1 to numelems(GetChildByName(xmlsections, rq2)) do		# now go through all specific section definitions of that section material class

								xmlsectiondefinition := GetChildByName(xmlsections, rq2)[k];
								xmlsection := GetChildByName(xmlsectiondefinition, "section");						# list of all data of defined material

								for m from 1 to numelems(xmlsection) do
									returndata2 := table();		# store values of what needs to be returned
							
									for n from 1 to nops(rq3) do		# got through requested values

										if HasAttribute(xmlsection[m], rq3[n]) = true then		# found requested attribute value in xml file
											returndata2[rq3[n]] := AttributeValue(xmlsection[m], rq3[n])			# ["C20 / serviceclass 1 / Korttidslast"]
											
										elif rq3[n] = "all" then
											
											for p in AttributeNames(xmlsection[m]) do
												returndata2[p] := AttributeValue(xmlsection[m], p);
											end do
										end if;
									
									end do;
									returndata1[AttributeValue(xmlsection[m], "name")] := eval(returndata2);
									
								end do;

							end do;
							
						else 	# section not found
						end if;				
						
					end do;
					
				else	# didn't find any sections in xml file							
				end if;

			elif requesteddata[i][1] = "calculations" then

				rq2 := requesteddata[i][2];			# calculation type
				rq3 := requesteddata[i][3];			# this one needs to be a list with what is requested
				returndata1 := table();

				if numelems(GetChildByName(xmltree, "calculations")) > 0 then
					
					xmlcalculations := GetChildByName(xmltree, "calculations")[1];						# GetChildByName returns list, need to go into list
					
					if ContentModelCount(xmlcalculations) > 0 then									# there are some calculations already defined

						# find if there is a definition of that specific type of calculation in the file (should only be one of them)
						foundcalculationtype := 0;
						for j from 1 to ContentModelCount(xmlcalculations) do
							if HasAttribute(GetChild(xmlcalculations, j), "calculationtype") then
								if AttributeValue(GetChild(xmlcalculations, j), "calculationtype") = rq2 then
									foundcalculationtype := j;
								end if;
							else
								Alert("Warning: XML definition for calculation (1) missing attribute 'calculationtype'", warnings, 4)
							end if;
						end do;
						
						if foundcalculationtype = 0 then			# this type of calculation is not defined yet
							Alert("No calculation found in file", warnings, 4);
						else		# calculationtype already exists
							xmlcalculationtype := GetChild(xmlcalculations, foundcalculationtype);
						end if;

						# find which calculation that should be loaded
						foundcalculationtype := {};		
						for j from 1 to ContentModelCount(xmlcalculationtype) do
							if HasAttribute(GetChild(xmlcalculationtype, j), "calculationtype") then
								if AttributeValue(GetChild(xmlcalculationtype, j), "calculationtype") = rq2 then
									foundcalculationtype := foundcalculationtype union {j};
								end if;
							else
								Alert("XML definisjon for calculation (2) missing attribute 'type'", warnings, 4)
							end if;
						end do;
						
						if numelems(foundcalculationtype) = 0 then			# denne type beregning er ikke definert enn�														
							Alert("No calculation found in file", warnings, 4);
							
						else		# calculationtype already exists
							
							if numelems(foundcalculationtype) = 1 then
								xmlcalculation := GetChild(xmlcalculationtype, foundcalculationtype[1]);
							else
								posnumber := table();
								posindex := table();
								for k from 1 to numelems(foundcalculationtype) do
									posindex[k] := foundcalculationtype[k];
									posnumber[k] := AttributeValue(GetChild(xmlcalculationtype, foundcalculationtype[k]), "positionnumber")
								end do;
								maplet := Maplet([["Choose positionnumber:  ", ComboBox['CoB1'](convert(posnumber, list))], [Button("OK", Shutdown(['CoB1'])), Button("Cancel", Shutdown())]]);
								pickedvalue := Maplets[Display](maplet)[1];	# valgt posisjonsnummer
								for k from 1 to numelems(foundcalculationtype) do
									if posnumber[k] = pickedvalue then
										xmlcalculation := GetChild(xmlcalculationtype, posindex[k]);
									end if;
								end do;
							end if;
							
							returndata2 := table();		# store values of what needs to be returned
							# Calculation can have both attributes on top level, but also in children. Need to go through both of them
							# top level attributes
							
							for n from 1 to nops(rq3) do		# got through requested values
								
								if HasAttribute(xmlcalculation, rq3[n]) = true then		# found requested attribute value in xml file
									returndata2[rq3[n]] := AttributeValue(xmlcalculation, rq3[n]);
									
								elif rq3[n] = "all" then
									for p in AttributeNames(xmlcalculation) do
										returndata2[p] := AttributeValue(xmlcalculation, p);
									end do
								end if;
								
							end do;
						
							xmlitems := {"structure", "materialdata", "section", "loadcases", "activesettings"};	

							# loop over defined calculation
							for j from 1 to ContentModelCount(xmlcalculation) do

								for dummy in xmlitems do														

									# https://www.mapleprimes.com/questions/230855-XMLTools--HasChild
									if ElementName(GetChild(xmlcalculation, j)) = dummy then
										
										xmldummy := GetChildByName(xmlcalculation, dummy)[1];		# structure, loadcases
										returndata3 := table();

										# adding attributes
										for p in AttributeNames(xmldummy) do
											if isNumeric(p, WhateverYouNeed) then
												returndata3[p] := parse(AttributeValue(xmldummy, p));
											else
												returndata3[p] := AttributeValue(xmldummy, p)
											end if;																						
										end do;

										# adding children								
										for m from 1 to ContentModelCount(xmldummy) do		# ContentModelCount counts number of children (attributes are not counted)
											returndata4 := table();
											xmldummy1 := GetChild(xmldummy, m);
																	
											if HasAttribute(xmldummy1, "name") then						
												nameIndex := AttributeValue(xmldummy1, "name")		# loadcase 1
											else
												nameIndex := ElementTypeName(xmldummy1)				# FastenerPatterns
											end if;

											for p in AttributeNames(xmldummy1) do
												if isNumeric(p, WhateverYouNeed) then
													returndata4[p] := eval(parse(AttributeValue(xmldummy1, p)))
												else
													returndata4[p] := AttributeValue(xmldummy1, p)
												end if;													
											end do;
												
											# adding children
											for p from 1 to ContentModelCount(xmldummy1) do				# 1, FastenerPattern
												returndata5 := table();
												xmldummy2 := GetChild(xmldummy1, p);

												for q in AttributeNames(xmldummy2) do
													if isNumeric(q, WhateverYouNeed) then
														returndata5[q] := eval(parse(AttributeValue(xmldummy2, q)))
													else
														returndata5[q] := AttributeValue(xmldummy2, q)
													end if;
												end do;

												if HasAttribute(xmldummy2, "name") then
													returndata4[AttributeValue(xmldummy2, "name")] := eval(returndata5);
												else
													returndata4[ElementTypeName(xmldummy2)] := eval(returndata5);
												end if;
												
											end do;
											
											returndata3[nameIndex] := eval(returndata4);
																	
										end do;

										returndata2[dummy] := eval(returndata3);
									
									end if;

								end do;	
								
							end do;

							returndata1 := eval(returndata2);
						
						end if;	# foundcalculationtype
					else
						Alert("No calculations found in file", warnings, 4);
					end if;	# xmlcalculations
				else
					Alert("No calculations found in file", warnings, 4);
			
				end if;	# xmltree calculations
							
			else
				
				Alert(cat("Requested command '", requesteddata[i][1], "' unknown"), warnings, 4);
				
			end if;
			
			returndata := [op(returndata), eval(returndata1)];
			
		end do;	# requesteddata
		
			# FileTools[Text][WriteString](logfile, cat("projectnumber: ", projectnumber, "\t projecttitle: ", projecttitle, "\n"));
			# FileTools[Text][WriteString](logfile, cat("position: ", position, "\t designer: ", designer, "\n"));

			# if HasChild(xmltree, XMLElement("materials")) then
				
		return returndata, successful;
		
	end proc:


	XMLMaterialTimber := proc(materials::table)
		description "Skriv materialspesifikk XML del";
		local xmltimber, xmlitem, ind, material, xmlvalues1, xmlvalues2, counter;
		uses XMLTools;
		# f�rst lager vi xmltimber definisjon i xml filen
		xmltimber := XMLElement("timber"); 
		counter := 0;
		
		for ind in indices(materials, 'nolist', 'indexorder') do
			material := materials[ind];
			xmlitem := XMLElement("material", ["material" = material["material"], "name" = material["name"], "timbertype" = material["timbertype"], 
			"strengthclass" = material["strengthclass"], "serviceclass" = material["serviceclass"], "loaddurationclass" = material["loaddurationclass"],
			"gamma_M" = convert(material["gamma_M"], string), "k_mod" = convert(material["k_mod"], string)]);
		
			xmlvalues1 := XMLElement("values_c", [
			"f_mk" = convert(material["f_mk"], string),
			"f_t0k" = convert(material["f_t0k"], string),
			"f_t90k" = convert(material["f_t90k"], string),
			"f_c0k" = convert(material["f_c0k"], string),
			"f_c90k" = convert(material["f_c90k"], string),
			"f_vk" = convert(material["f_vk"], string),
			"f_rk" = convert(material["f_rk"], string),
			"E_m0mean" = convert(material["E_m0mean"], string),
			"E_m0k" = convert(material["E_m0k"], string),
			"E_m90mean" = convert(material["E_m90mean"], string),
			"E_9005" = convert(material["E_9005"], string), 
			"G_mean" = convert(material["G_mean"], string), 
			"G_005" = convert(material["G_005"], string), 
			"G_rmean" = convert(material["G_rmean"], string),
			"G_r05" = convert(material["G_r05"], string), 
			"rho_k" = convert(material["rho_k"], string),
			"rho_mean" = convert(material["rho_mean"], string)]); 
	
			xmlvalues2 := XMLElement("values_d", [
			"f_md" = convert(material["f_md"], string),
			"f_t0d" = convert(material["f_t0d"], string),
			"f_t90d" = convert(material["f_t90d"], string),
			"f_c0d" = convert(material["f_c0d"], string),
			"f_c90d" = convert(material["f_c90d"], string),
			"f_vd" = convert(material["f_vd"], string),
			"f_rd" = convert(material["f_rd"], string)]);
		
			xmlitem := AddChild(xmlitem, xmlvalues1, 0);
			xmlitem := AddChild(xmlitem, xmlvalues2, 1);
			xmltimber := AddChild(xmltimber, xmlitem, counter);
			counter := counter + 1;
		end do;
		return xmltimber;
		
	end proc:


	XMLMaterialConcrete := proc(materials::table)
		description "Skriv materialspesifikk XML del";
		local xmlconcrete, xmlitem, ind, material, xmlvalues, counter;
		uses XMLTools;
		# f�rst lager vi xmltimber definisjon i xml filen
		xmlconcrete := XMLElement("concrete"); 
		counter := 0;

		for ind in indices(materials, 'nolist', 'indexorder') do
			material := materials[ind];
			xmlitem := XMLElement("material", ["material" = material["material"], "name" = material["name"], "strengthclass_NS" = material["strengthclass_NS"], "strengthclass_CEN" = material["strengthclass_CEN"],
			"exposureclass" = material["exposureclass"], "durabilityclass" = material["durabilityclass"], "gamma_C" = convert(material["gamma_C"], string)]);
		
			xmlvalues := XMLElement("values", [
			"f_ck" = convert(material["f_ck"], string),
			"f_ckcube" = convert(material["f_ckcube"], string),
			"f_cm" = convert(material["f_cm"], string),
			"f_ctm" = convert(material["f_ctm"], string),
			"f_ctk005" = convert(material["f_ctk005"], string),
			"f_ctk095" = convert(material["f_ctk095"], string),
			"E_cm" = convert(material["E_cm"], string),

			"epsilon_c1" = convert(material["epsilon_c1"], string),
			"epsilon_cu1" = convert(material["epsilon_cu1"], string),
			"epsilon_c2" = convert(material["epsilon_c2"], string),
			"epsilon_cu2" = convert(material["epsilon_cu2"], string),
			"epsilon_c3" = convert(material["epsilon_c3"], string),
			"epsilon_cu3" = convert(material["epsilon_cu3"], string),
			"n" = convert(material["n"], string),
			"alpha_cc" = convert(material["alpha_cc"], string),
			"alpha_ct" = convert(material["alpha_ct"], string),
	
			"f_cd" = convert(material["f_cd"], string),
			"f_ctd" = convert(material["f_ctd"], string)]);

			xmlitem := AddChild(xmlitem, xmlvalues, 0);
			xmlconcrete := AddChild(xmlconcrete, xmlitem, counter);
			counter := counter + 1;
		end do;
		return xmlconcrete;
		
	end proc:


	XMLMaterialSteel := proc(materials::table)
		description "Skriv materialspesifikk XML del";
		local xmlsteel, xmlitem, ind, material, xmlvalues, counter;
		uses XMLTools;
		
		# f�rst lager vi xmlsteel definisjon i xml filen
		xmlsteel := XMLElement("steel"); 
		counter := 0;
		
		for ind in indices(materials, 'nolist', 'indexorder') do
			material := materials[ind];
			xmlitem := XMLElement("material", ["material" = material["material"], "name" = material["name"], "steelcode" = material["steelcode"], 
			"steelgrade" = material["steelgrade"], "thicknessclass" = material["thicknessclass"], "gamma_M0" = convert(material["gamma_M0"], string)]);
		
			xmlvalues := XMLElement("values", [
			"f_uk" = convert(material["f_uk"], string),
			"f_yk" = convert(material["f_yk"], string),
			"f_ud" = convert(material["f_ud"], string),
			"f_yd" = convert(material["f_yd"], string), 
			"E" = convert(material["E"], string),
			"G" = convert(material["G"], string), 
			"nu" = convert(material["nu"], string),
			"alpha_t" = convert(material["alpha_t"], string)]); 

			xmlitem := AddChild(xmlitem, xmlvalues, 0);
			xmlsteel := AddChild(xmlsteel, xmlitem, counter);
			counter := counter + 1;
		end do;
		return xmlsteel;
		
	end proc:


	XMLSectionSteel := proc(sections::table)
		description "Skriv sections- XML del";
		local xmlsection, xmlitem, xmlvalue, sectionvalues, ind, item, Textfelt, section, counter;
		uses XMLTools;
		
		# f�rst lager vi XMLMaterialSteel definisjon i xml filen
		xmlsection := XMLElement("steel"); 
		counter := 0;
		
		for ind in indices(sections, 'nolist', 'indexorder') do
			section := sections[ind];
			xmlitem := XMLElement("section", ["name" = section["name"], "sectiontype" = section["sectiontype"], "section" = section["section"], "code" = section["standard"]]);
			sectionvalues := [indices(section)[1..,1]];									# liste over hvilke parameter som er definert i profilen

			xmlvalue := XMLElement("geometry");
			Textfelt := ["h", "b", "t_w", "t_f", "h_w", "d", "t", "r", "r_o", "r_i"];
			for item in Textfelt do								# g�r gjennom variabler av aktuell section
				if member(item, sectionvalues) then
					xmlvalue := AddAttribute(xmlvalue, item, convert(section[item], string))
				end if
			end do;	
			xmlitem := AddChild(xmlitem, xmlvalue, 0);

			xmlvalue := XMLElement("cross_section_properties");
			Textfelt := ["A", "A_m", "U", "U_o", "U_i", "U_m", "m_k", "g_k", "alpha_1", "alpha_2", "alpha_3", "alpha_4", "d_L", "w_1", "w_2", "w_3", 
			"I_y", "I_z", "I_p", "W_el_y", "W_el_z", "W_pl_y", "W_pl_z", "i_y", "i_z", "i_p", "S_y", "S_z", "alpha_pl_y", "alpha_pl_z", "I_t0", "I_t"];
			for item in Textfelt do								# g�r gjennom variabler av aktuell section
				if member(item, sectionvalues) then
					xmlvalue := AddAttribute(xmlvalue, item, convert(section[item], string))
				end if
			end do;	
			xmlitem := AddChild(xmlitem, xmlvalue, 1);

			xmlvalue := XMLElement("shear_torsion_warping_properties");
			Textfelt := ["A_vy", "A_steg", "A_z", "A_vz", "I_omega", "W_omega", "omega_0", "omega_1", "omega_2", "omega_3", "omega_max", "S_omega_0", "S_omega_1", "S_omega_2", "S_omega_3", "S_omega_max"];
			for item in Textfelt do								# g�r gjennom variabler av aktuell section
				if member(item, sectionvalues) then
					xmlvalue := AddAttribute(xmlvalue, item, convert(section[item], string))
				end if
			end do;	
			xmlitem := AddChild(xmlitem, xmlvalue, 2);

			xmlvalue := XMLElement("capacity");
			Textfelt := ["N_pl_RK_S235", "V_pl_y_RK_S235", "V_pl_z_RK_S235", "M_el_y_Rk_S235", "M_el_z_Rk_S235", "M_pl_y_Rk_S235", "M_pl_z_Rk_S235"];	# liste over mulige sectionsparameter
			for item in Textfelt do								# g�r gjennom variabler av aktuell section
				if member(item, sectionvalues) then
					xmlvalue := AddAttribute(xmlvalue, item, convert(section[item], string))
				end if
			end do;	
			xmlitem := AddChild(xmlitem, xmlvalue, 3);

			xmlvalue := XMLElement("buckling_cross_section_class");
			Textfelt := ["buckling_curve_y_S235-420", "buckling_curve_z_S235-420", "buckling_curve_y_S460", "buckling_curve_z_S460", "cross_section_class_bending_S235", "cross_section_class_compression_S235", 
			"cross_section_class_bending_S355", "cross_section_class_compression_S355", "cross_section_class_bending_S460". "cross_section_class_compression_S460"];
			for item in Textfelt do								# g�r gjennom variabler av aktuell section
				if member(item, sectionvalues) then
					xmlvalue := AddAttribute(xmlvalue, item, convert(section[item], string))
				end if
			end do;	
			xmlitem := AddChild(xmlitem, xmlvalue, 4);
		
			xmlsection := AddChild(xmlsection, xmlitem, counter);
			counter := counter + 1;
		end do;
		
		return xmlsection;
		
	end proc:



	XMLSectionTimber := proc(sections::table)
		description "Skriv sections- XML del";
		local xmlsection, xmlitem, xmlvalue, sectionvalues, ind, item, Textfelt, section, counter;
		uses XMLTools;
		
		xmlsection := XMLElement("timber"); 
		counter := 0;
		
		for ind in indices(sections, 'nolist', 'indexorder') do
			section := sections[ind];
			xmlitem := XMLElement("section", ["name" = section["name"], "sectiontype" = section["sectiontype"]]);
			sectionvalues := [indices(section)[1..,1]];									# liste over hvilke parameter som er definert i profilen

			xmlvalue := XMLElement("geometry");
			Textfelt := ["h", "b"];
			for item in Textfelt do								# g�r gjennom variabler av aktuell section
				if member(item, sectionvalues) then
					xmlvalue := AddAttribute(xmlvalue, item, convert(section[item], string))
				end if
			end do;	
			xmlitem := AddChild(xmlitem, xmlvalue, 0);

			xmlvalue := XMLElement("cross_section_properties");
			Textfelt := ["A", "I_y", "I_z", "I_t", "W_y", "W_z", "i_y", "i_z"];
			for item in Textfelt do								# g�r gjennom variabler av aktuell section
				if member(item, sectionvalues) then
					xmlvalue := AddAttribute(xmlvalue, item, convert(section[item], string))
				end if
			end do;	
			xmlitem := AddChild(xmlitem, xmlvalue, 1);
		
			xmlsection := AddChild(xmlsection, xmlitem, counter);
			counter := counter + 1;
		end do;
		
		return xmlsection;
		
	end proc:


	XMLCalculations := proc(WhateverYouNeed::table)
		description "Convert calculation to XML";
		local xmlcalculation, dummy, dummy1, dummy2, dummy3, xmlLevel0, xmlLevel1, xmlLevel2, counter, item, item1, item2, item3, storeitems;
		uses XMLTools;

		# get set of saveable items
		storeitems := GetStoreitemsCalculations(WhateverYouNeed);

		counter := 0;
		xmlcalculation := XMLElement("calculation");
		
		for dummy in storeitems do	# {"loadcases", "structure", "active*", "calculationtype"; "positionnumber", "positiontitle"}

			if assigned(WhateverYouNeed["calculations"][dummy]) then

				item := WhateverYouNeed["calculations"][dummy];	

				if type(item, table) then		# "structure", "loadcases"

					xmlLevel0 := XMLElement(dummy);

					for dummy1 in indices(item, 'nolist', 'indexorder') do 

						item1 := item[dummy1];
															
						if type(item1, table) then	# "structure - FastenerPatterns", "loadcases - 1"
							
							if dummy = "loadcases" then
								xmlLevel1 := XMLElement("loadcase")
							else
								xmlLevel1 := XMLElement(convert(dummy1, string))		# FastenerPatterns
							end if;

							# we want name to be first
							if assigned(item1["name"]) then
								xmlLevel1 := AddAttribute(xmlLevel1, "name", convert(item1["name"], string));
							end if;

							for dummy2 in indices(item1, 'nolist', 'indexorder') do

								item2 := item1[dummy2];					

								if type(item2, table) then
								
									# FastenerPatterns -> FastenerPattern name = ...
									if substring(convert(dummy1, string), -1..-1) = "s" then
										xmlLevel2 := XMLElement(substring(convert(dummy1, string), 1..-2));
									else
										xmlLevel2 := XMLElement(convert(dummy1, string));
									end if;

									# we want name to be first
									if assigned(item2["name"]) then
										xmlLevel2 := AddAttribute(xmlLevel2, "name", convert(item2["name"], string));
									end if;
									
									for dummy3 in indices(item2, 'nolist', 'indexorder') do
										
										item3 := item2[dummy3];
										
										if type(item3, string) or type(item3, numeric) then
											if dummy3 <> "name" then
												xmlLevel2 := AddAttribute(xmlLevel2, dummy3, convert(item3, string));
											end if;

										else
											
											Alert("Error: too many table levels in XMLCalculations", WhateverYouNeed["warnings"], 3);

										end if
										
									end do;
									
									xmlLevel1 := AddChild(xmlLevel1, xmlLevel2, ContentModelCount(xmlLevel1));
									
								else																	
									if dummy2 <> "name" then
										xmlLevel1 := AddAttribute(xmlLevel1, dummy2, convert(eval(item2), string));			# direct writeout after readin might give strange Units conversions 'Units:-Simple:-`-`(Units:-Simple:-`*`(75.8,Units:-Unit(kN)))
									end if;									
																		
								end if
								
							end do;

							xmlLevel0 := AddChild(xmlLevel0, xmlLevel1, ContentModelCount(xmlLevel0));

						else

							xmlLevel0 := AddAttribute(xmlLevel0, dummy1, convert(item1, string));
						
						end if;

					end do;

					xmlcalculation := AddChild(xmlcalculation, xmlLevel0, counter);
					counter := counter + 1;						
										
				else
					
					xmlcalculation := AddAttribute(xmlcalculation, dummy, convert(item, string));				
							
				end if;
				
			end if;
		
		end do;
	
		return xmlcalculation;
	end proc:


	GetStoreitemsCalculations := proc(WhateverYouNeed::table)
		description "Get items to be stored in calculations";
		local storeitems, dummy, parent, child;
	
		# get set of saveable items
		storeitems := {};
		for dummy in WhateverYouNeed["componentvariables"]["var_storeitems"] do			
			if searchtext("/", dummy) > 0 then 		# "calculations/positionnumber"
				parent := StringTools:-Split(dummy, "/")[1];
				child := StringTools:-Split(dummy, "/")[2];
				if parent = "calculations" then
					storeitems := storeitems union {child}
				end if;
			end if;
		end do;
		
		return storeitems
	end proc:


runAfterXMLImport := proc(successful::boolean, WhateverYouNeed::table)
	description "After import of xml file";
	uses DocumentTools;
	local i, val, material, materials, sections, activematerial, activesection, activeloadcase, activeFastenerPattern, forceSectionUpdate, partsnumber, posnumber, warnings, XMLImportlog;

	# local variables
	material := WhateverYouNeed["material"];
	materials := WhateverYouNeed["materials"];
	warnings := WhateverYouNeed["warnings"];
	sections := WhateverYouNeed["sections"];
	activematerial := WhateverYouNeed["calculations"]["activesettings"]["activematerial"];
	activesection := WhateverYouNeed["calculations"]["activesettings"]["activesection"];
	activeloadcase := WhateverYouNeed["calculations"]["activesettings"]["activeloadcase"];
	activeFastenerPattern := WhateverYouNeed["calculations"]["activesettings"]["activeFastenerPattern"];
	forceSectionUpdate := false;
	partsnumber := "";
	XMLImportlog := WhateverYouNeed["logs"]["XMLImport"];

	XMLImportlog := cat(XMLImportlog, "\n runAfterXMLImport: \n");

	StoredsettingsToComponents(WhateverYouNeed);		# setting default variables to components

	if successful then
		StoreSettings(WhateverYouNeed);
		StoredsettingsToComponents(WhateverYouNeed);
		
		for i in WhateverYouNeed["componentvariables"]["var_ComboBox"] do
			
			if i = "materials" and ComponentExists("ComboBox_materials") then

				# store material values
				for val in indices(WhateverYouNeed["materials"], 'nolist') do
					if material = "concrete" then
						NODEConcreteEN1992:-GetMaterialdata(val, WhateverYouNeed)
						
					elif material = "steel" then
						NODESteelEN1993:-GetMaterialdata(val, WhateverYouNeed)
					
					elif material = "timber" then
						NODETimberEN1995:-GetMaterialdata(val, WhateverYouNeed)
					
					end if;
					
					if assigned(WhateverYouNeed["materialdata"]["name"]) then
						materials[WhateverYouNeed["materialdata"]["name"]] := eval(WhateverYouNeed["materialdata"]);						
					else
						Alert("materialdata name not assigned", warnings, 1);
					end if;
				end do;

				XMLImportlog := cat(XMLImportlog, "ComboBox_materials - ", material, " \n");

				posnumber := ListTools:-Search(activematerial, GetProperty("ComboBox_materials", 'itemlist'));
				if posnumber = 0 or posnumber > numelems(GetProperty("ComboBox_materials", 'itemlist')) then
					Alert(cat("Active material ", activematerial, " not in list of materials"), warnings, 1);
					SetProperty("ComboBox_materials", 'selectedindex', 0);	 # pick first element in the list
				else
					SetProperty("ComboBox_materials", 'selectedindex', posnumber-1);	 # Combobox start with 0, lists with 1
				end if;
				MaterialChanged(material, activematerial, WhateverYouNeed, forceSectionUpdate, partsnumber)
				
			elif i = "sections" and ComponentExists("ComboBox_sections") then

				# store section values
				for val in GetProperty("ComboBox_sections", 'itemlist') do
				
					if material = "steel" then
						NODESteelEN1993:-GetSectiondata(val, WhateverYouNeed)

					# no sections for concrete at the moment
					elif material = "concrete" then
						# sectiondata := NODEConcreteEN1992:-GetSectiondata(val, warnings)					
					
					elif material = "timber" then
						NODETimberEN1995:-GetSectiondata(val, WhateverYouNeed)
					
					end if;

					if assigned(WhateverYouNeed["sectiondata"]["name"]) then
						sections[WhateverYouNeed["sectiondata"]["name"]] := eval(WhateverYouNeed["sectiondata"]);						
					else
						Alert("sectiondata name not assigned", warnings, 1);
					end if;
				end do;

				XMLImportlog := cat(XMLImportlog, "...Combobox_sections - ", material, " \n");

				posnumber := ListTools:-Search(activesection, GetProperty("ComboBox_sections", 'itemlist'));
				if posnumber = 0 or posnumber > numelems(GetProperty("ComboBox_sections", 'itemlist')) then
					Alert(cat("Active section ",activesection, " not in list of stored sections"), warnings, 1);
					SetProperty("ComboBox_sections", 'selectedindex', 0);	 # pick first element in the list
				else
					SetProperty("ComboBox_sections", 'selectedindex', posnumber-1);	 # Combobox start with 0, lists with 1
				end if;
				SectionChanged(material, activesection, WhateverYouNeed, "")
				
			elif i = "loadcases" and ComponentExists("ComboBox_loadcases") then
				posnumber := ListTools:-Search(activeloadcase, GetProperty("ComboBox_loadcases", 'itemlist'));
				if posnumber = 0 or posnumber > numelems(GetProperty("ComboBox_loadcases", 'itemlist')) then
					Alert(cat("Active loadcase ", activeloadcase, " not in list of stored loadcases"), warnings, 1);
					SetProperty("ComboBox_loadcases", 'selectedindex', 0);	 # pick first element in the list
				else
					SetProperty("ComboBox_loadcases", 'selectedindex', posnumber-1);	 # Combobox start with 0, lists with 1
				end if;

				XMLImportlog := cat(XMLImportlog, "...Combobox_loadcases \n");
				
				WriteLoadsToDocument(activeloadcase, WhateverYouNeed)

			elif i = "FastenerPatterns" and ComponentExists("ComboBox_FastenerPatterns") then
				posnumber := ListTools:-Search(activeFastenerPattern, GetProperty("ComboBox_FastenerPatterns", 'itemlist'));
				if posnumber = 0 or posnumber > numelems(GetProperty("ComboBox_FastenerPatterns", 'itemlist')) then
					Alert(cat("Active fastener pattern ", activeFastenerPattern, " not in list of FastenerPatterns"), warnings, 1);
					SetProperty("ComboBox_FastenerPatterns", 'selectedindex', 0);	 # pick first element in the list
				else
					SetProperty("ComboBox_FastenerPatterns", 'selectedindex', posnumber-1);	 # Combobox start with 0, lists with 1
				end if;
				NODEFastenerPattern:-ModifyFastenerPattern("SelectFastenerPattern", WhateverYouNeed);

				XMLImportlog := cat(XMLImportlog, "...Combobox_FastenerPatterns \n");

			elif i = "loadcases" or i = "materials" or i = "sections" then
				# predefined variables apparently not used

			else
				XMLImportlog := cat(XMLImportlog, "...", i, " \n");
				runAfterXMLImportLocal(WhateverYouNeed, i);
				# Alert(cat("Unknown variable ", i, " in runAfterXMLImport."), warnings, 1)
				
			end if;
		end do;

		WhateverYouNeed["logs"]["XMLImport"] := XMLImportlog;

		RunAfterRestoresettings(WhateverYouNeed);		# local procedures after restore
		MainCommon("all");							# run calculation after import
		# MainCommon("calculation");					# run calculation after import
		
	end if;
end proc:


checkBeforeWriteout := proc(items, WhateverYouNeed::table)
	uses DocumentTools;
	description "Need to check that materials, sections and other stuff is saved properly";
	local i, dummy, dummy1, activestuff, successful;

	successful := true;

	for i in WhateverYouNeed["componentvariables"]["var_ComboBox"] do
		
		if substring(i, -1..-1) = "s" then
			
			dummy1 := cat("active", substring(i, 1..-2));		# activeloadcase, activematerial, activesection, activeFastenerPattern
			
			if member(i, {"materials", "sections"}) then
				if member(i, items) then
					dummy := WhateverYouNeed[i]
				else
					next		# in case where materials or sections are not stored, continue with next item
				end if;
				
			elif member(i, {"loadcases"}) then
				dummy := WhateverYouNeed["calculations"][i]
				
			elif member(i, {"FastenerPatterns"}) then
				dummy := WhateverYouNeed["calculations"]["structure"][i]
				
			else
				Alert(cat("Undefined type ", i), WhateverYouNeed["warnings"], 2)
			end if;
			
			if ComponentExists(cat("TextArea_", dummy1)) then
				# now check if active*** is in list of ***
				activestuff := GetProperty(cat("TextArea_", dummy1), 'value');
				
				if member(activestuff, {indices(dummy, 'nolist')}) then
					# 
				else	
					Alert(cat("Couldn't find ", activestuff, " in ", i, ": ", indices(dummy, 'nolist')), WhateverYouNeed["warnings"], 2);
					successful := false
				end if;
				
			else # might be specific sheet like material or section properties that doesn't implement everything, drop it
				# Alert(cat("Couldn't find ", cat("TextArea_", dummy)), WhateverYouNeed["warnings"], 2);
				# successful := false
			end if;
			
		else
			# 2024-04-16: problems during export of EC5_8 with "connection" and "fastener"
			# Alert(cat("Can't check variable ", i), WhateverYouNeed["warnings"], 1);
			# successful := false
		end if;
	end do;

	return successful
end proc: