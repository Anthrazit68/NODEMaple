# NODESteelBolts.mm: steel bolt
# Copyright (C) 2026  Andreas Zieritz

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

NODESteelbolts := module()
    description "Data and procedures for bolts according to EN 1993-1-8";
    option package;
    export boltgrades, f_ub, f_ub_tab, F_tRk, F_tRd, F_tRd_tab, As_nom, allmembers;

    # Encapsulated data on module level - zero global variables!
    local boltgrades_, f_ub_, f_ub_tab_, F_tRd_tab_, As_nom_, memberNames;

# $include MUST be at the absolute start of the line (column 1) to build properly
$include "Steel/Data_NODESteelbolts.mm"

    # Exported lists and tables for GUI / external calculation access
    boltgrades := eval(boltgrades_);
    f_ub       := eval(f_ub_);
    f_ub_tab   := eval(f_ub_tab_);
    F_tRd_tab  := eval(F_tRd_tab_);
    As_nom     := eval(As_nom_);

    # Gather and sort all available bolt sizes (e.g., M12, M16, M20...)
    memberNames := sort([indices(As_nom, 'nolist')], NODEFunctions:-SortStructuralnames);

    allmembers := proc()
        return memberNames;
    end proc:

    F_tRk := proc(bolt::string, boltgrade::string)
        local capacity;
        uses NODEFunctions;

        if assigned(f_ub[boltgrade]) and assigned(As_nom[bolt]) then
            capacity := f_ub[boltgrade] * As_nom[bolt];
            capacity := convert(capacity, 'units', 'kN');
            return capacity;
        else
            NODEFunctions:-Alert(cat("NODESteelbolts:-F_tRk: undefined boltgrade ", boltgrade, " or bolttype ", bolt, "."), table(), 2);
            return 0;
        end if;
    end proc:

    F_tRd := proc(bolt::string, boltgrade::string, countersunk::boolean)
        local gammaM2, capacity, k2;
        uses NODEFunctions;
    
        gammaM2 := 1.25;
        if countersunk then
            k2 := 0.63;
        else
            k2 := 0.9;
        end if;

        if assigned(f_ub[boltgrade]) and assigned(As_nom[bolt]) then
            capacity := k2 * f_ub[boltgrade] * As_nom[bolt] / gammaM2;
            capacity := convert(capacity, 'units', 'kN');
            return capacity;
        else
            NODEFunctions:-Alert(cat("NODESteelbolts:-F_tRd: undefined boltgrade ", boltgrade, " or bolttype ", bolt, "."), table(), 2);
            return 0;
        end if;
    end proc:
   
end module: