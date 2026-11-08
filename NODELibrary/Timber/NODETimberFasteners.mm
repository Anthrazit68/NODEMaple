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
    #   - l and dh vary with length -> returned as comma-joined,
    #     unit-free, rounded text lists ready for value lists
    #
    # NOTE: all loop variables are declared local explicitly,
    # otherwise Maple warns "implicitly declared local".
    # -----------------------------------------------------------------------
    Property := proc()
        local what, dia, pd, m, dfree, res, ds, pos, producer, product,
              ls_r, ls_c, pname, vals, x, lsr, mkey, tol, dnum, lsnum;

        tol := 10^(-9);

        # Helper semantics (inlined to stay module-local):
        #   dnum / lsnum hold the numeric value of the d / ls arguments
        #   after parse() normalisation of string numerics.

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

            # Normalise the length argument: strings ("40") -> numbers
            if args[5] = "-" then
                lsnum := "-";
            elif type(args[5], string) then
                lsnum := parse(args[5]);
            else
                lsnum := args[5];
            end if;

            # Resolve length: given value rounded, or shortest available
            if lsnum = "-" then
                ls_c := sort([op({seq(round(convert(x, 'unit_free')),
                                       x in fm_l[producer, product, dfree])})]);
                if numelems(ls_c) = 0 then
                    error "no length data for %1 at d = %2", mkey, dfree;
                end if;
                ls_r := ls_c[1];
            else
                ls_r := round(evalf(lsnum));
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
                return fm_serviceclass[producer, product][1];
            elif pname = "d" then
                return dfree * Unit('mm');
            elif pname = "l" then
                # All available lengths, unit-free, rounded, comma-joined
                ls_c := sort([op({seq(round(convert(x, 'unit_free')),
                                       x in fm_l[producer, product, dfree])})]);
                return StringTools:-Join(convert~(ls_c, string), ", ");
            elif pname = "dh" then
                # Head diameters across all lengths of this product
                vals := {};
                for x in fm_l[producer, product, dfree] do
                    lsr := round(convert(x, 'unit_free'));
                    if assigned(fm_dh[producer, product, dfree, lsr]) then
                        vals := vals union map(y -> round(convert(y, 'unit_free')),
                                               fm_dh[producer, product, dfree, lsr]);
                    end if;
                end do;
                return StringTools:-Join(convert~(sort([op(vals)]), string), ", ");
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