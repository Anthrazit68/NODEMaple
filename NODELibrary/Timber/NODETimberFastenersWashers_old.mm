# NODETimberFastenersWashers : timber fasteners, washer properties
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

NODETimberFastenersWashers:= module ()
	export fasteners, producers, producer_products, detailinformation, dbolt, dint, dext, s, A_ef, N_axk:
	option package;

	global prod, bet, descr, fm_dbolt, fm_dint, fm_dext, fm_s;
	
	fasteners := "Skive";
	producers := eval(prod);
	producer_products := eval(bet);
	
	detailinformation := eval(descr);
	# klimaklasse := eval(fm_serviceclass);
	dbolt := eval(fm_dbolt);		# diameter bolt
	dint:= eval(fm_dint);		# internal diameter
	dext:= eval(fm_dext);		# external diameter
	s := eval(fm_s);			# thickness

	A_ef := proc(dia, prod, typ)
		local A_, dext_, dint_;
		uses Units[Simple];

		dint_ := dint[convert(dia, 'unit_free'), prod, typ][1];
		dext_ := evalf(min(dext[convert(dia, 'unit_free'), prod, typ][1], 12 * s[convert(dia, 'unit_free'), prod, typ][1], 4 * convert(dia, 'unit_free') * Unit('mm')));		# 8.5.2(3)
		
		A_ := evalf((dext_^2 - dint_^2) * Pi / 4);

		return A_
		
	end proc:

	N_axk := (dia, prod, typ) -> convert(evalf(7.5 * Unit('N/mm^2') * A_ef(dia, prod, typ)), 'units', 'kN');
	
end module: