# NODETimberFastenersSharpMetal.mm : timber fasteners, Rothoblaas sharp metal stripes
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

NODETimberFastenersSharpMetal := module()
    description "Data and access tracking API for Rothoblaas Sharp Metal connectors";
    option package;

    # Public API tracking entries mapped to worksheets or structural checking algorithms
    export fasteners, producers, products, detailinformation, serviceclass, width, withscrew,
           f_v0k, f_v90k, f_vEGk, k_ser0k, k_ser90k, k_serEGk;

    # Encapsulated module-level local tables - zero global context leakage
    local metadata, fm_withscrew, prod, bet, descr, fm_serviceclass, fm_width,
          fm_fv0k, fm_fv90k, fm_fvEGk, fm_kser0k, fm_kser90k, fm_kserEGk;

# $include MUST sit at the absolute beginning of the file line (column 1) to build correctly
$include "Timber/Data_NODETimberFastenersSharpMetal.mm"

    # Safely evaluate and bind localized definitions into the package interface exports
    fasteners         := "Sharp Metal";
    producers         := eval(prod);
    products          := eval(bet);
    detailinformation := eval(descr);
    serviceclass      := eval(fm_serviceclass);
    width             := eval(fm_width);
    withscrew         := eval(fm_withscrew);
    f_v0k             := eval(fm_fv0k);
    f_v90k            := eval(fm_fv90k);
    f_vEGk            := eval(fm_fvEGk);
    k_ser0k           := eval(fm_kser0k);
    k_ser90k          := eval(fm_kser90k);
    k_serEGk          := eval(fm_kserEGk);

end module: