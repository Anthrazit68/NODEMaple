# NODETimberFasteners : timber fastener properties
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

NODETimberFasteners:= module ()
	export fasteners, producers, producer_products, fasteners_producers, fasteners_products, detailinformation, serviceclass, l, d, fasteners_d, dh, l1, l2:
	export M_yRk, f_axk, f_headk, f_tensk, f_uk, b_max:
	# export `M_y,Rk`, `f_ax,k`, `f_head,k`, `f_tens,k`:
	
	option package;

	global fm, prod, fm_producers, producers_connectionstypes, bet, fm_d, fm_l, fm_dh, fm_l1, fm_l2, fm_fuk, fm_descr, fm_serviceclass, fm_MyRk, fm_faxk, fm_fheadk, fm_ftensk, prod_con_dia, fm_Bmax;
	
	fasteners := eval(fm);				# liste over alle fasteners
	producers := eval(fm_producers);		# liste over alle producers

	# [festemiddel]
	fasteners_d := eval(fm_d);
	
	# [festemiddel, diameter]
	fasteners_producers := eval(prod);

	# [festemiddel, diameter, produsent]
	fasteners_products := eval(bet);

	# [produsent]
	producer_products := eval(producers_connectionstypes);

	# [produsent, produkt]
	detailinformation := eval(fm_descr);
	serviceclass := eval(fm_serviceclass);
	d := eval(prod_con_dia);
	
	# [produsent, festemiddel, diameter]
	l := eval(fm_l);
	dh:= eval(fm_dh);
	l1:=eval(fm_l1);
	l2:=eval(fm_l2);
	# `M_y,Rk` := eval(fm_MyRk);
	M_yRk := eval(fm_MyRk);
	# `f_ax,k` := eval(fm_faxk);
	f_axk := eval(fm_faxk);
	# `f_head,k` := eval(fm_fheadk);
	f_headk := eval(fm_fheadk);
	# `f_tens,k` := eval(fm_ftensk);		
	f_tensk := eval(fm_ftensk);
	f_uk := eval(fm_fuk);
	b_max := eval(fm_Bmax);
    
end module: