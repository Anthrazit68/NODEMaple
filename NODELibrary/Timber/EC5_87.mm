# EC5_87.mm : Eurocode 5 chapter 8.7
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

GetCalculatedFastener := proc(WhateverYouNeed::table)

    description "check calculation type for metal fasteners";
    local fastener, chosenFastener, d, calculatedFastener, warnings;

    fastener := WhateverYouNeed["calculations"]["structure"]["fastener"];
    chosenFastener :=  fastener["chosenFastener"];
    d := fastener["d"];
    warnings := WhateverYouNeed["warnings"];

    # check how we should design fastener
    if (chosenFastener = "Nail" and d <= 8 * Unit('mm')) or (chosenFastener = "Screw" and d <= 6 * Unit('mm')) or fastener["calculateAsNail"] = "true" then		# 8.7.1
        calculatedFastener := "Nail"
        
    elif chosenFastener = "Bolt" or (chosenFastener = "Nail" and d > 8 * Unit('mm')) or (chosenFastener = "Screw" and d > 6 * Unit('mm')) then
        calculatedFastener := "Bolt"
        
    elif chosenFastener = "Dowel" and d > 6 * Unit('mm') and d < 30 * Unit('mm') then
        calculatedFastener := "Dowel"
        
    elif chosenFastener = "Screw" then		# that should be impossible
        calculatedFastener := "Screw";
        warnings := Alert("calculated fastener: Screw - should be impossible", warnings, 5);
        
    else								# that should be impossible either
        calculatedFastener := "Unknown";
        warnings := Alert("unknown calculated fastener", warnings, 5);
        
    end if;

    WhateverYouNeed["calculatedvalues"]["fastenervalues"]["calculatedFastener"] := calculatedFastener;

end proc: