# NODETimberSections.mm : timber section properties tracking API
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

NODETimberSections := module()
    description "Data API providing engineering profile cross-section tracking maps for structural wood layouts";
    option package;

    # Public API tracking structures exposed directly to worksheet selectors and checking scripts
    export timbertype, section_b, section_h;

    # Encapsulated module-level configurations - zero global execution leaking
    local metadata, tretype, profil_b, profil_h;

# $include MUST sit at the absolute start of the file line (column 1) to build correctly
$include "Timber/Data_NODETimberSections.mm"

    # Safely evaluate, copy, and bind local variable layouts into public tracking handles
    timbertype := eval(tretype);
    section_b  := eval(profil_b);
    section_h  := eval(profil_h);

end module: