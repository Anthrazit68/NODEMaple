# NODEDocumentCommon.mm
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

NODEDocumentCommon := module()
    description "Universal control and interface routines shared across all material documents";
    option package;
    uses DocumentTools, StringTools, NODEFunctions;

    export startupcheck, Reset, InitCommon, MainCommon, ExcelInOut, 
           StoresettingsLocal, RestoresettingsLocal;

    # calculationtype and startup must be global to sync seamlessly with the sheet layout
    global calculationtype, Main, InitSpecific, WhateverYouNeed;
    
    # Fully encapsulated internal memory structures
    local storesettings, calculationdata, loadvariables, loadcases, warnings, var, startupStatus;


    ExcelInOut := proc(action::string)
        description "Call Excel read and write operations mapping to runtime configurations";
        var := table();
        var["loadvariables"] := loadvariables;
        var["loadcases"] := loadcases;

        ExcelFileInOut(action, calculationdata["calculationtype_short"], var, warnings);
    end proc:


    InitCommon := proc(materialType::string, calculationtype::string)
        description "Initialize common data structures and store the active material type";
        uses NODEFunctions;

        WhateverYouNeed := table();
        
        # Initialize generic library definitions using the shared global calculationtype
        LibInitCommon(WhateverYouNeed, calculationtype);

        WhateverYouNeed["material"] := materialType;

        # Run specific initialization if defined in the worksheet
        if type(eval(InitSpecific), procedure) then
            InitSpecific(WhateverYouNeed);
        end if;

        # Mark startup as completed so it doesn't re-run configuration on every manual execution
        startupStatus := false;
    end proc:


    MainCommon := proc(action::string)
        description "Main execution routine triggered after user input or resets";
        
        # If the user clicks "Execute entire code", make sure the table exists
        if not assigned(WhateverYouNeed) or type(WhateverYouNeed, table) = false then
            InitCommon();
        end if;
        
        ResetWarnings(WhateverYouNeed);
        ReadComponentsCommon(action, WhateverYouNeed);
        
        if MASTERALARM(WhateverYouNeed["warnings"]) = false and 
           (action = "calculation" or WhateverYouNeed["calculations"]["autocalc"]) then
            # Delegates core calculation execution to the sheet's global Main procedure
            if type(eval(Main), procedure) then
                Main(evaluatedTable);
            end if;
        end if;

    end proc:


    Reset := proc()
        description "Reset the active calculation document";
        storesettings := Matrix(1,1);
        InitCommon();
        MainCommon("reset");
    end proc:


    RestoresettingsLocal := proc()
        description "Restore settings matrix from module memory back to active UI components";
        Restoresettings(storesettings, WhateverYouNeed);
        StoredsettingsToComponents(WhateverYouNeed);
    end proc:


    startupcheck := proc()::boolean;
        description "Check if code is run during startup or via execute entire code";
        if startupStatus = false then
            return false;
        else
            startupStatus := true;
            return true;
        end if;
    end proc:


    StoresettingsLocal := proc(saveitems::table)
        description "Saves component state matrix to the local module boundary";
        storesettings[1,1] := eval(saveitems);
    end proc:

end module: