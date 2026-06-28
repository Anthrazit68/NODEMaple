# NODETimberSplitRing.mm : timber fasteners, split ring properties tracking API
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

NODETimberSplitRing := module()
    description "Data API and design placement dimensions for dynamic split ring connectors";
    option package;

    # Public API entry bounds exposed to worksheets and structural checking modules
    export producer, type, information, serviceclass, dc, hc, t, r, a1, a2, a3t, a3c, a4t, a4c;

    # Encapsulated module-level configurations - zero global context leakage
    local metadata, type_, dc_, producer_, information_, serviceclass_, 
          hc_, t_, r_, a1_, a2_, a3t_, a3c_, a4t_, a4c_;

# $include MUST sit at the absolute start of the file line (column 1) to build correctly
$include "Timber/Data_NODETimberSplitRing.mm"

    # Safely evaluate, copy, and bind local variable layouts into public tracking handles
    producer     := eval(producer_);
    type         := eval(type_); 
    information  := eval(information_);
    serviceclass := eval(serviceclass_);
    dc           := eval(dc_);
    hc           := eval(hc_);
    t            := eval(t_);
    r            := eval(r_);
    a1           := eval(a1_);
    a2           := eval(a2_);
    a3t          := eval(a3t_);
    a3c          := eval(a3c_);
    a4t          := eval(a4t_);
    a4c          := eval(a4c_);

end module: