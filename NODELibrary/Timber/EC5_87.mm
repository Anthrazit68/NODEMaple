# calculate_n_ef_872

# 8.7 Skrueforbindelser

# 8.3.1.1(8)
calculate_n_ef_872 := proc(WhateverYouNeed::table)
	description "beregner n_ef for en gruppe av strekkbelastede skruer";
	global AntallForbindelser;
	local n_ef, axiallyLoaded, chosenFastener;

	axiallyLoaded := WhateverYouNeed["calculatedvalues"]["axiallyLoaded"];
	chosenFastener := WhateverYouNeed["calculations"]["structure"]["fastener"]["chosenFastener"];
	
	n_ef := AntallForbindelser[1] * AntallForbindelser[2];
	
	if chosenFastener = "Screw" and axiallyLoaded and n_ef > 1 then
		n_ef := n_ef ^ 0.9; # (8.41)
	end if;
	
	return n_ef;
end proc: