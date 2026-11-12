# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2026 <your name>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details: https://www.gnu.org/licenses/gpl-3.0.txt

""" 
NODEMaple_PopulateValueList.py

Populates standard GH value lists with values and optionally export values. If no export values are defined, index of chosen value is exported

Input:
  list_name        : name of value list component to be modified
  names            : list with values
  values           : export values for chosen items, if empty, index values are returned
 """

import Grasshopper as gh
from Grasshopper.Kernel.Special import GH_ValueListItem

doc = ghenv.Component.OnPingDocument()

# list_name og names må alltid være definert
if doc and list_name and names:
    
    # 1. Finn Value List på lerretet basert på Nickname
    target_list = None
    for obj in doc.Objects:
        if isinstance(obj, gh.Kernel.Special.GH_ValueList) and obj.NickName == list_name:
            target_list = obj
            break

    if target_list:
        formatted_items = []
        has_custom_values = bool(values and len(values) > 0)

        for i, name in enumerate(names):
            n = str(name).strip()
            
            if has_custom_values and i < len(values):
                # Bruk oppgitt verdi fra 'values'
                val_raw = str(values[i]).strip()
                try:
                    float(val_raw)
                    expr = val_raw
                except ValueError:
                    expr = '"{}"'.format(val_raw)
            else:
                # Fallback: Bruk listenummer / indeks som heltall
                expr = str(i)

            formatted_items.append((n, expr))

        # Kontroller gjeldende tilstand for å unngå unødvendig oppdatering
        current_state = [(item.Name, item.Expression) for item in target_list.ListItems]
        
        if current_state != formatted_items:
            def update_callback(d):
                target_list.ListItems.Clear()
                for n, expr in formatted_items:
                    target_list.ListItems.Add(GH_ValueListItem(n, expr))
                
                target_list.Attributes.ExpireLayout()
                target_list.ExpireSolution(False)

            doc.ScheduleSolution(1, gh.Kernel.GH_Document.GH_ScheduleDelegate(update_callback))