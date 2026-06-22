# NODEFastenerPattern.mm : calculation of geometry and forces in fasteners
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

NODEStatics := module()

    description "Module for running standalone Loads on Fastener Group workbook":
    option package;
    
    global WhateverYouNeed; 
    export InitSpecific, ResetSpecific, runAfterXMLImportLocal, Main, ReadComponentsSpecific;
    uses DocumentTools, NODEFunctions, NODEFastenerPattern;


    InitSpecific := proc()
        description "Deklarer globale variabler og oppsett for Fastener Pattern";        
        local var_calculations_FastenerPatterns, FastenerPatterns, var_numeric;

        WhateverYouNeed["calculations"]["calculationtype_short"] := "Fastener Group";

        var_calculations_FastenerPatterns := {
            "FastenerPatternUnits", "FastenerPatternCoordinates",
            "FastenerPatternType1", "center_x1", "center_y1", "grid_x1", "grid_y1", "grid_alpha_11", "grid_alpha_21", "radial_diameter1", "radial_items1", "radial_alpha1",
            "FastenerPatternType2", "center_x2", "center_y2", "grid_x2", "grid_y2", "grid_alpha_12", "grid_alpha_22", "radial_diameter2", "radial_items2", "radial_alpha2",
            "FastenerPatternType3", "center_x3", "center_y3", "grid_x3", "grid_y3", "grid_alpha_13", "grid_alpha_23", "radial_diameter3", "radial_items3", "radial_alpha3",
            "coordinates", "reactionforces"
        }; 
        
        var_numeric := {"center_", "radial_", "loadcenter_"}; 
                        
        WhateverYouNeed["componentvariables"]["var_calculations"] := WhateverYouNeed["componentvariables"]["var_calculations"] union var_calculations_FastenerPatterns;
        WhateverYouNeed["componentvariables"]["var_numeric"] := eval(var_numeric);
        WhateverYouNeed["componentvariables"]["var_ComboBox"] := eval(WhateverYouNeed["componentvariables"]["var_ComboBox"] union {"FastenerPatterns"});
        
        # need to setup variable for storing values, but only if missing
        if assigned(WhateverYouNeed["calculations"]["structure"]["FastenerPatterns"]) = false then
            FastenerPatterns := table();
            WhateverYouNeed["calculations"]["structure"]["FastenerPatterns"] := eval(FastenerPatterns);
        end if;
    end proc:


    Main := proc(action::string)        
        if MASTERALARM(WhateverYouNeed["warnings"]) = false then
            if action = "calculation" or WhateverYouNeed["calculations"]["autocalc"] then
                NODEFastenerPattern:-CalculateForcesInConnection(WhateverYouNeed);
                if WhateverYouNeed["calculations"]["calculatingAllLoadcases"] = false then
                    NODEFastenerPattern:-PlotResults(WhateverYouNeed)
                end if;	
            end if;
        end if;
    end proc:


    ReadComponentsSpecific := proc(TypeOfAction::string)
        NODEFastenerPattern:-ModifyFastenerPattern("AddFastenerPattern", WhateverYouNeed);
    end proc:


    ResetSpecific := proc()
        description "reset GUI components to standardvalues";
        DocumentTools:-SetProperty("ComboBox_FastenerPatternType1", 'selectedindex', 1); 
        DocumentTools:-SetProperty("TextArea_center_x1", 'value', "0"); 
        DocumentTools:-SetProperty("TextArea_center_y1", 'value', "0"); 
        DocumentTools:-SetProperty("TextArea_grid_x1", 'value', "0"); 
        DocumentTools:-SetProperty("TextArea_grid_y1", 'value', "0");
        DocumentTools:-SetProperty("TextArea_grid_alpha_11", 'value', "0");
        DocumentTools:-SetProperty("TextArea_grid_alpha_21", 'value', "0");
        DocumentTools:-SetProperty("ComboBox_FastenerPatternType2", 'selectedindex', 0);
        DocumentTools:-SetProperty("ComboBox_FastenerPatternType3", 'selectedindex', 0);
        DocumentTools:-SetProperty("CheckBox_FastenerPatternCoordinates", 'enabled', "false");
        
        NODEFastenerPattern:-SetVisibilityFastenerPattern();
        
        DocumentTools:-SetProperty("ComboBox_FastenerPatterns", 'itemlist', ["1"]);
        DocumentTools:-SetProperty("TextArea_activeFastenerPattern", 'value', "1");
        NODEFastenerPattern:-ModifyFastenerPattern("AddFastenerPattern", WhateverYouNeed);
    end proc:

   
    runAfterXMLImportLocal := proc(i::string)
        description "Procedure run after import of XML file, called in NODEXML:-runAfterXMLImport";
        local warnings;

        warnings := WhateverYouNeed["warnings"];

        if i = "fastener" then
            SetComboFastenersAfterXMLImport(WhateverYouNeed);		# EC5_8_SetVisibilityCombobox
        else
            Alert(cat("runAfterXMLUImportLocal: unhandled command ", i), warnings, 2);
        end if;
    end proc:

end module: