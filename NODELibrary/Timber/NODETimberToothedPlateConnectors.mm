# NODETimberToothedPlateConnectors.mm : timber fasteners, toothed plate connectors (Bulldogs)
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

NODETimberToothedPlateConnectors := module()
    description "Data API and positioning specifications for toothed plate connectors (Bulldog type) under EN 1995-1-1";
    option package;

    # Public API tracking handles exposed directly to worksheet elements and calculation checks
    export producer, type, sides, information, serviceclass, dc, d1, h1, hc, t, d2, 
           la1, la2, t1, t2, a1, a2, a3t, a3c, a4t, a4c, Rvk;

    # Encapsulated module-level local tables - zero global contamination
    local metadata, sides_, type_, dc_, producer_, information_, serviceclass_, 
          d1_, h1_, hc_, t_, d2_, la1_, la2_, t1_, t2_, a1_, a2_, a3t_, a3c_, a4t_, a4c_, Rvk_;

# $include MUST sit at the absolute start of the file line (column 1) to build correctly
$include "Timber/Data_NODETimberToothedPlateConnectors.mm"

    # Safely evaluate, copy, and bind local variable layouts into public tracking handles
    producer     := eval(producer_);
    type         := eval(type_);
    sides        := eval(sides_);
    information  := eval(information_);
    serviceclass := eval(serviceclass_);
    dc           := eval(dc_);
    d1           := eval(d1_);
    h1           := eval(h1_);
    hc           := eval(hc_);
    t            := eval(t_);
    d2           := eval(d2_);
    la1          := eval(la1_);
    la2          := eval(la2_);
    t1           := eval(t1_);
    t2           := eval(t2_);
    a1           := eval(a1_);
    a2           := eval(a2_);
    a3t          := eval(a3t_);
    a3c          := eval(a3c_);
    a4t          := eval(a4t_);
    a4c          := eval(a4c_);
    Rvk          := eval(Rvk_);

end module: