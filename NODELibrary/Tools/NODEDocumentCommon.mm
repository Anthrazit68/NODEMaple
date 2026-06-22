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

    export RegisterHandlers, startupcheck, Reset, InitCommon, MainCommon, StoresettingsLocal, RestoresettingsLocal, RunXMLHandlers;

    global WhateverYouNeed;
    
    local initList, mainList, resetList, xmlList, readList, storesettings, loadvariables, loadcases, warnings, var, startupStatus;

    initList := [];
    mainList := [];
    resetList := [];
    xmlList := [];
    readList := [];


    InitCommon := proc(materialType::string, calculationtype::string)
        description "Initialize common data structures and store the active material type";
        uses NODEFunctions;
        local p;

        WhateverYouNeed := table();
        
        # Initialize generic library definitions using the shared global calculationtype
        LibInitCommon(WhateverYouNeed, calculationtype);

        WhateverYouNeed["material"] := materialType;

        # run InitSpecific's
        if nops(initList) > 0 then
            for p in initList do p(); end do;
        end if;             

        # Mark startup as completed so it doesn't re-run configuration on every manual execution
        startupStatus := false;
    end proc:


    MainCommon := proc(action::string)
        description "Main execution routine triggered after user input or resets";
        local activeMat, activeType, p;
        uses DocumentTools;        

        # Robust fallback check if the global table has been wiped from memory
        if not assigned(WhateverYouNeed) or type(WhateverYouNeed, table) = false then
            
            # Read directly from the sheet's GUI components to recover the state safely
            activeMat  := `if`(ComponentExists("TextArea_material"), GetProperty("TextArea_material", value), "steel");
            activeType := `if`(ComponentExists("TextArea_calculationtype"), GetProperty("TextArea_calculationtype", value), "Universal");
            
            InitCommon(activeMat, activeType);
        end if;
        
        ResetWarnings(WhateverYouNeed);
        ReadComponentsCommon(action, WhateverYouNeed);
        
        if MASTERALARM(WhateverYouNeed["warnings"]) = false and 
           (action = "calculation" or WhateverYouNeed["calculations"]["autocalc"]) then

            # Delegates core calculation execution to the sheet's global Main procedure
            if nops(mainList) > 0 then
                for p in mainList do p(action); end do;
            end if;   

        end if;
    end proc:


    RegisterHandlers := proc({initProc::procedure := NULL}, {mainProc::procedure := NULL}, {resetProc::procedure := NULL}, {xmlProc::procedure := NULL}, {readProc::procedure := NULL})
        description "Register other initialization procedures using keyword-arguments";

        # Eksisterende registrering
        if initProc <> NULL then initList := [op(initList), eval(initProc)]; end if;
        if mainProc <> NULL then mainList := [op(mainList), eval(mainProc)]; end if;
        
        # NYTT: Registrering av de tre nye prosedyrene
        if resetProc <> NULL then resetList := [op(resetList), eval(resetProc)]; end if;
        if xmlProc <> NULL then xmlList := [op(xmlList), eval(xmlProc)]; end if;
        if readProc <> NULL then readList := [op(readList), eval(readProc)]; end if;
    end proc:


    Reset := proc()
        description "Reset the active calculation document";
        local p;
        storesettings := Matrix(1,1);
        InitCommon();
        
        # run specific reset procedures
        if nops(resetList) > 0 then
            for p in resetList do p(); end do;
        end if;

        MainCommon("reset");
    end proc:


    RestoresettingsLocal := proc()
        description "Restore settings matrix from module memory back to active UI components";
        Restoresettings(storesettings, WhateverYouNeed);
        StoredsettingsToComponents(WhateverYouNeed);
    end proc:


    RunXMLHandlers := proc(i::string)
        description "Running registered XML procedures from specific modules";
        local p;
        if nops(xmlList) > 0 then
            for p in xmlList do 
                p(i); # forward command (e.g. "fastener")
            end do;
        end if;
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