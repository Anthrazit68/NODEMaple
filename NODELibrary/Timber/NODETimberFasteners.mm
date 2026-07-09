# NODETimberFasteners.mm : timber fastener properties and tracking API
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

NODETimberFasteners := module()
    description "Data and access tracking procedures for timber mechanical fasteners";
    option package;
    
    # Exported API boundaries accessed directly by worksheet GUI or structural checks
    export fasteners, producers, producer_products, fasteners_producers, fasteners_products, 
           detailinformation, serviceclass, d, l, fasteners_d, dh, l1, l2, M_yRk, f_axk, f_headk, f_tensk, 
           f_uk, b_max;

    # Module-level encapsulated tables and variables - zero global contamination
    local metadata, fm, fm_d, prod, bet, fm_producers, producers_connectionstypes,
          fm_descr, fm_serviceclass, prod_con_dia, fm_l, fm_MyRk, fm_faxk, 
          fm_fheadk, fm_ftensk, fm_dh, fm_l1, fm_l2, fm_fuk, fm_Bmax;

# $include MUST be placed at the absolute start of line column 1 to build correctly
$include "Timber/Data_NODETimberFasteners.mm"

    # Safely evaluate and bind raw data fields into the public package handle exports
    fasteners           := eval(fm);
    producers           := eval(fm_producers);
    fasteners_d         := eval(fm_d);
    fasteners_producers := eval(prod);
    fasteners_products  := eval(bet);
    producer_products   := eval(producers_connectionstypes);
    detailinformation   := eval(fm_descr);
    serviceclass        := eval(fm_serviceclass);
    d                   := eval(prod_con_dia);
    l                   := eval(fm_l);
    dh                  := eval(fm_dh);
    l1                  := eval(fm_l1);
    l2                  := eval(fm_l2);
    M_yRk               := eval(fm_MyRk);
    f_axk               := eval(fm_faxk);
    f_headk             := eval(fm_fheadk);
    f_tensk             := eval(fm_ftensk);
    f_uk                := eval(fm_fuk);
    b_max               := eval(fm_Bmax);

end module: