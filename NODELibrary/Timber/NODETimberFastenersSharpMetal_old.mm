# NODETimberFastenersSharpMetal : timber fasteners, Rothoblaas sharp metal stripes
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

NODETimberFastenersSharpMetal:= module ()

	export fasteners, producers, products, detailinformation, serviceclass, width, withscrew:
	export f_v0k, f_v90k, f_vEGk, k_ser0k, k_ser90k, k_serEGk:
	# export `f_v,0,k`, `f_v,90,k`, `f_v,EG,k`, `k_ser,0,k`, `k_ser,90,k`, `k_ser,EG,k`:
	option package;

	global prod, bet, descr, fm_serviceclass, fm_width, fm_withscrew, fm_fv0k, fm_fv90k, fm_fvEGk, fm_kser0k, fm_kser90k, fm_kserEGk;
	
	fasteners := "Sharp Metal";
	producers := eval(prod);
	products := eval(bet);
	
	detailinformation := eval(descr);
	serviceclass := eval(fm_serviceclass);
	width := eval(fm_width);
	withscrew := eval(fm_withscrew);

	f_v0k := eval(fm_fv0k);
	f_v90k := eval(fm_fv90k);
	f_vEGk := eval(fm_fvEGk);
	k_ser0k := eval(fm_kser0k);
	k_ser90k := eval(fm_kser90k);
	k_serEGk := eval(fm_kserEGk);
	
	#assign(`f_v,0,k`, eval(fm_fv0k));
	#assign(`f_v,90,k`, eval(fm_fv90k));
	#assign(`f_v,EG,k`, eval(fm_fvEGk));
	#assign(`k_ser,0,k`, eval(fm_kser0k));
	#assign(`k_ser,90,k`, eval(fm_kser90k));
	#assign(`k_ser,EG,k`, eval(fm_kserEGk));

end module: