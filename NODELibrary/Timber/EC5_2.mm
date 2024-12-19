# EC5_2.mm : Eurocode 5 chapter 2
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

gamma_M := proc(MatConntype::string)
    local gamma_M;

    # NS-EN 1995, NA.2.4.1
	if MatConntype = "Solid timber" then
		gamma_M := 1.25

	elif MatConntype = "Glued laminated timber" or timbertype = "CLT" then
		gamma_M := 1.15

    elif MatConntype = "Connections" then
        gamma_M := 1.3

    else
        gamma_M := 9999
        
	end if;

end proc: