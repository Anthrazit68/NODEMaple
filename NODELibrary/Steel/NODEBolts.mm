# NODESteelEN1993.mm : EN 1993 (steel) general procedures
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

NODEBolts:= module()
	
	export boltgrades, f_ub, f_ub_tab, F_tRk, F_tRd, F_tRd_tab, As_nom;
	option package;

	global boltgrades_, f_ub_, f_ub_tab_, F_tRd_tab_, As_nom_;

	boltgrades := eval(boltgrades_);
	f_ub := eval(f_ub_);
	f_ub_tab := eval(f_ub_tab_);
	F_tRd_tab := eval(F_tRd_tab_);
	As_nom := eval(As_nom_);

	F_tRk := proc(bolt::string, boltgrade::string)
		local F_tRk;

		if assigned(f_ub[boltgrade]) and assigned(As_nom[bolt]) then
			F_tRk := f_ub[boltgrade] * As_nom[bolt];
			F_tRk := convert(F_tRk, 'units', 'kN');

			return F_tRk
		else
			NODEFunctions:-Alert(cat("NODEBolts:-F_tRk: undefined boltgrade ", boltgrade, " or bolttype ", bolt, "."), table(), 2);
			return 0
		end if;
		
	end proc:

	F_tRd := proc(bolt::string, boltgrade::string, countersunk::boolean)
		local gammaM2, F_tRd, k2;
	
		gammaM2 := 1.25;
		if countersunk then
			k2 := 0.63
		else
			k2 := 0.9
		end if;

		if assigned(f_ub[boltgrade]) and assigned(As_nom[bolt]) then
			F_tRd := k2 * f_ub[boltgrade] * As_nom[bolt] / gammaM2;
			F_tRd := convert(F_tRd, 'units', 'kN');

			return F_tRd
		else
			NODEFunctions:-Alert(cat("NODEBolts:-F_tRd: undefined boltgrade ", boltgrade, " or bolttype ", bolt, "."), table(), 2);
			return 0
		end if;
	
   	end proc:
   
end module: