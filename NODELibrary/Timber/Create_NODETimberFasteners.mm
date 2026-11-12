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
           f_uk, b_max,
           # Query API (same call shapes as NODESteelMaterial / NODESteelProfiles)
           Property;

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

    # -----------------------------------------------------------------------
    # Property : unified query interface, mirroring the material/profile API
    #
    # Queries:
    #   Property("allmembers")
    #       -> all fastener types (Nail, Screw, Bolt, Dowel, ...)
    #   Property(<type>, "allmembers")
    #       -> every designation of that type as "producer@product"
    #          (flat, deduplicated across diameters and producers)
    #   Property(<type>, "producers")
    #       -> all producers offering at least one product of that type
    #   Property(<type>, "diameters")
    #       -> all diameters of that type, unit-free numbers, sorted
    #          (decimals supported, e.g. 6.2)
    #   Property("metadata")  or  Property(<type>, "metadata")
    #       -> variable names (column 2 of the metadata table):
    #          fm, prod, bet, descr, serviceclass, d, l, dh, M_y_Rk,
    #          f_ax_k, f_head_k, f_tens_k, l1, l3, f_uk, B_max
    #   Property(<type>, <d>, <producer>, "members")
    #       -> "producer@product" list filtered by diameter and/or producer;
    #          pass "-" to leave d or producer unfiltered
    #   Property("value", <type>, <member>, <d>, <ls>, <varname>)
    #       -> value of <varname> for member "producer@product";
    #          d   = number/string-number or "-" (auto: unique diameter with data)
    #          ls  = number/string-number or "-" (auto: shortest available length)
    #   Property("value", <type>, <member>, <d>, "-", "lengths")
    #       -> comma-joined text list of ALL available lengths of the member
    #          (not part of the metadata record; used by the Lengths
    #          component to populate the length value list)
    #
    # Return conventions per variable (follows the metadata definition:
    # a record row is identified by producer, product, d and l, so every
    # field is a SCALAR with its unit):
    #   - unit "1" columns are TEXT: fm, prod, bet, descr, serviceclass
    #     (serviceclass is a classification 1/2/3: whole floats like 2.0
    #      are printed as "2")
    #   - unit-bearing columns are QUANTITIES (returned with their units,
    #     parsed by Units:-Split in the Grasshopper components):
    #       d, l, dh, M_y_Rk, f_ax_k, f_head_k, f_tens_k, l1, l3, f_uk, B_max
    #     where l  = the SELECTED length (ls argument)
    #           dh = head diameter AT the selected length
    #   - "lengths" (helper query, not in metadata): comma-joined,
    #     unit-free, rounded text list of all lengths of the member
    #
    # Numeric input normalisation:
    #   Grasshopper/panels may deliver diameters and lengths as strings
    #   ("24", "6.2") or as floats (24.0) while the database is keyed by
    #   the raw Excel import values (often integers: 24). Therefore:
    #     - string numerics are parsed (parse)
    #     - explicit d is SNAPPED to the closest actual key of
    #       fm_d[<type>] within tolerance before any table indexing,
    #       so 24, 24.0, "24" and "24.0" all hit the same record
    #   "members" compares diameters with the same tolerance loop.
    #
    # Other naming/keys follow Create_NODETimberFasteners.mm:
    #   - prod/bet are keyed by UNIT-FREE diameters, fasteners_d carries
    #     units -> every descent converts with convert(..., 'unit_free'),
    #     same as SetComboFasteners does in the worksheet GUI
    #   - Excel column N (threaded length from head, "l3") is stored
    #     in table fm_l2 (kept for backwards compatibility)
    #
    # NOTE: all loop variables are declared local explicitly,
    # otherwise Maple warns "implicitly declared local".
    # -----------------------------------------------------------------------
    Property := proc()
        local what, dia, pd, m, dfree, res, ds, pos, producer, product,
              ls_r, ls_c, pname, vals, x, lsr, mkey, tol, dnum, lsnum;

        tol := 10^(-9);

        # ------------------- one-argument queries --------------------------
        if nargs = 1 then
            what := args[1];
            if what = "allmembers" then
                # All fastener types defined in the database
                return sort([op(fm)]);
            elif what = "metadata" then
                # Variable names of the fastener data records
                return [seq(m[2], m in metadata)];
            else
                error "unknown query %1", what;
            end if;

        # ------------------- Property(type, query) ------------------------
        elif nargs = 2 then
            what := args[1];
            if not assigned(fm_d[what]) then
                error "unknown fastener type %1", what;
            end if;
            if args[2] = "allmembers" then
                # Flat member list: "producer@product", all d and producers
                res := {};
                for dia in fm_d[what] do
                    dfree := convert(dia, 'unit_free');
                    for pd in prod[what, dfree] do
                        res := res union map(b -> cat(pd, "@", b),
                                             bet[what, dfree, pd]);
                    end do;
                end do;
                return sort([op(res)]);
            elif args[2] = "producers" then
                # All producers of this fastener type
                res := {};
                for dia in fm_d[what] do
                    res := res union prod[what, convert(dia, 'unit_free')];
                end do;
                return sort([op(res)]);
            elif args[2] = "diameters" then
                # All diameters of this fastener type, unit-free, sorted
                res := {};
                for dia in fm_d[what] do
                    res := res union {convert(dia, 'unit_free')};
                end do;
                return sort([op(res)]);
            elif args[2] = "metadata" then
                return [seq(m[2], m in metadata)];
            else
                error "unknown query %1 for fastener type %2", args[2], what;
            end if;

        # ------------------- Property(type, d, producer, "members") --------
        elif nargs = 4 and args[4] = "members" then
            what := args[1];
            if not assigned(fm_d[what]) then
                error "unknown fastener type %1", what;
            end if;
            # Normalise the diameter argument: strings ("24", "6.2") -> numbers
            if args[2] = "-" then
                dnum := "-";
            elif type(args[2], string) then
                dnum := parse(args[2]);
            else
                dnum := args[2];
            end if;
            res := {};
            for dia in fm_d[what] do
                dfree := convert(dia, 'unit_free');
                # "-" means: no diameter filter (tolerant float comparison)
                if dnum <> "-" and abs(evalf(dnum - dfree)) > tol then
                    next;
                end if;
                for pd in prod[what, dfree] do
                    if args[3] <> "-" and pd <> args[3] then
                        next;
                    end if;
                    res := res union map(b -> cat(pd, "@", b),
                                         bet[what, dfree, pd]);
                end do;
            end do;
            return sort([op(res)]);

        # ------------------- Property("value", type, member, d, ls, var) --
        elif nargs = 6 and args[1] = "value" then
            what := args[2];
            if not assigned(fm_d[what]) then
                error "unknown fastener type %1", what;
            end if;
            mkey := args[3];
            pos := StringTools:-Search("@", mkey);
            if pos = 0 then
                error "member %1 must be of the form producer@product", mkey;
            end if;
            producer := mkey[1 .. pos-1];
            product   := mkey[pos+1 .. -1];
            if not assigned(fm_descr[producer, product]) then
                error "unknown member %1", mkey;
            end if;

            # Normalise the diameter argument: strings ("24", "6.2") -> numbers
            if args[4] = "-" then
                dnum := "-";
            elif type(args[4], string) then
                dnum := parse(args[4]);
            else
                dnum := args[4];
            end if;

            # Resolve diameter:
            #   "-" -> the unique diameter with data for this product
            #   given -> SNAPPED to the closest actual key of fm_d[what]
            #            (so 24.0 matches an integer 24 key, etc.)
            ds := [];
            for dia in fm_d[what] do
                dfree := convert(dia, 'unit_free');
                if dnum = "-" then
                    if assigned(fm_l[producer, product, dfree]) then
                        ds := [op(ds), dfree];
                    end if;
                elif abs(evalf(dnum - dfree)) <= tol then
                    ds := [op(ds), dfree];
                end if;
            end do;
            ds := [op({op(ds)})];
            if numelems(ds) = 1 then
                dfree := ds[1];
            elif numelems(ds) = 0 then
                error "no matching diameter %1 for fastener type %2",
                      args[4], what;
            else
                error "diameter ambiguous for %1, supply diameter", mkey;
            end if;

            # Helper value: all available lengths of this member at dfree,
            # unit-free, rounded, sorted, deduplicated
            ls_c := sort([op({seq(round(convert(x, 'unit_free')),
                                   x in fm_l[producer, product, dfree])})]);

            # Normalise the length argument: strings ("40") -> numbers
            if args[5] = "-" then
                lsnum := "-";
            elif type(args[5], string) then
                lsnum := parse(args[5]);
            else
                lsnum := args[5];
            end if;

            # Resolve length: given value (snapped to nearest key), or shortest
            if lsnum = "-" then
                if numelems(ls_c) = 0 then
                    error "no length data for %1 at d = %2", mkey, dfree;
                end if;
                ls_r := ls_c[1];
            else
                # snap to the closest available length within tolerance
                ls_r := NULL:
                for x in ls_c do
                    if abs(evalf(lsnum - x)) <= 0.5 then
                        ls_r := x;
                        break;
                    end if;
                end do;
                if ls_r = NULL then
                    error "no matching length %1 for %2 at d = %3",
                          args[5], mkey, dfree;
                end if;
            end if;

            pname := args[6];
            if pname = "fm" then
                return what;
            elif pname = "prod" then
                return producer;
            elif pname = "bet" then
                return product;
            elif pname = "descr" then
                vals := fm_descr[producer, product][1];
                if whattype(vals) = float then
                    # empty Excel field converted to 0 in the set
                    return "";
                end if;
                return vals;
            elif pname = "serviceclass" then
                # Classification (1/2/3), not a quantity -> return as STRING
                vals := fm_serviceclass[producer, product][1];
                if whattype(vals) = float and vals = 0 then
                    # empty Excel field converted to 0 in the set
                    return "";
                end if;
                if type(vals, numeric) and abs(evalf(vals - round(vals))) <= tol then
                    # whole number stored as float (2.0) -> print as "2",
                    # not "2.0"; genuine decimals (1.5) keep their digits
                    return convert(round(vals), string);
                end if;
                return convert(vals, string);
            elif pname = "d" then
                # Diameter of the selected record
                return dfree * Unit('mm');
            elif pname = "l" then
                # Selected length of the record (scalar with unit, num)
                return ls_r * Unit('mm');
            elif pname = "dh" then
                # Head diameter AT the selected length (scalar with unit, num)
                return fm_dh[producer, product, dfree, ls_r][1];
            elif pname = "M_y_Rk" then
                return fm_MyRk[producer, product, dfree][1];
            elif pname = "f_ax_k" then
                return fm_faxk[producer, product, dfree][1];
            elif pname = "f_head_k" then
                return fm_fheadk[producer, product, dfree][1];
            elif pname = "f_tens_k" then
                return fm_ftensk[producer, product, dfree][1];
            elif pname = "l1" then
                return fm_l1[producer, product, dfree, ls_r][1];
            elif pname = "l3" then
                # Excel column N stored in fm_l2 (backwards-compatible name)
                return fm_l2[producer, product, dfree, ls_r][1];
            elif pname = "f_uk" then
                return fm_fuk[producer, product, dfree, ls_r][1];
            elif pname = "B_max" then
                return fm_Bmax[producer, product, dfree, ls_r][1];
            elif pname = "lengths" then
                # Helper query for the Lengths component (NOT part of the
                # metadata record): all available lengths, comma-joined
                if numelems(ls_c) = 0 then
                    return "";
                end if;
                return StringTools:-Join(convert~(ls_c, string), ", ");
            else
                error "unknown variable %1", pname;
            end if;

        else
            error "invalid call to Property; expected Property(\"allmembers\"), "
                  "Property(<type>, \"allmembers\"/\"producers\"/\"diameters\"/\"metadata\"), "
                  "Property(<type>, <d>, <producer>, \"members\"), or "
                  "Property(\"value\", <type>, <member>, <d>, <ls>, <varname>)";
        end if;
    end proc;

end module: