# NODETimberFastenersWashers.mm : timber fasteners, washer properties and mechanical checks
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

NODETimberFastenersWashers := module()
    description "Data API and Eurocode 5 Clause 8.5.2(3) capacity evaluation for connection washers";
    option package;

    # Public API entry bounds exposed to external spreadsheets or calculation blocks
    export fasteners, producers, producer_products, detailinformation, dbolt, dint, dext, s, 
           A_ef, N_axk;

    # Encapsulated module-level configurations - zero global context pollution
    local metadata, fm_dbolt, prod, bet, descr, fm_dint, fm_dext, fm_s;

# $include MUST sit at the absolute start of the file line (column 1) to build correctly
$include "Timber/Data_NODETimberFastenersWashers.mm"

    # Safely evaluate and bind dynamic properties into public handles
    fasteners         := "Skive";
    producers         := eval(prod);
    producer_products := eval(bet);
    detailinformation := eval(descr);
    dbolt             := eval(fm_dbolt);
    dint              := eval(fm_dint);
    dext              := eval(fm_dext);
    s                 := eval(fm_s);

    # Eurocode 5 EN 1995-1-1: Clause 8.5.2(3) effective area checking procedure
    A_ef := proc(dia, prodName::string, typ::string)
        local A_, dext_, dint_, s_, rawDia, key;
        uses Units[Simple];

        rawDia := convert(dia, 'unit_free');
        key    := rawDia, prodName, typ;

        if assigned(dint[key]) and assigned(dext[key]) and assigned(s[key]) then
            # Extract first members safely from configuration datasets
            dint_ := op([dint[key]])[1];
            dext_ := op([dext[key]])[1];
            s_    := op([s[key]])[1];

            # Apply EN 1995-1-1 8.5.2(3) maximum limit check: dext_eff = min(dext, 12s, 4d)
            dext_ := evalf(min(dext_, 12 * s_, 4 * rawDia * Unit('mm')));
            
            # Area calculation: A_ef = (dext_eff^2 - dint^2) * Pi / 4
            A_ := evalf((dext_^2 - dint_^2) * Pi / 4);
            return A_;
        else
            error "NODETimberFastenersWashers:-A_ef: undefined dimensions for parameters %1, %2, %3", dia, prodName, typ;
        end if;
    end proc:

    # Characteristic axial capacity based on bearing area configuration
    N_axk := proc(dia, prodName::string, typ::string)
        uses Units[Simple];
        return convert(evalf(7.5 * Unit('N/mm^2') * A_ef(dia, prodName, typ)), 'units', 'kN');
    end proc:

end module: