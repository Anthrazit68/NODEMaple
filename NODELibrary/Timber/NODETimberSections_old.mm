# NODETimberSections : timber section properties
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

NODETimberSections:= module()
	export timbertype, section_b, section_h:
	option package;

	global tretype, profil_h, profil_b;
	
	timbertype := tretype;

	# https://www.mapleprimes.com/questions/229310-Variable-From-Library-Different-Than
	# m� bruke eval() for tables, se ogs�
	# https://www.maplesoft.com/support/help/Maple/view.aspx?path=last_name_eval&term=last_name_eval
	section_b := eval(profil_b);
	section_h := eval(profil_h);
end module: