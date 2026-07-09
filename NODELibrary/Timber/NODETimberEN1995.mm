# NODETimberEN1995 : Eurocode 5, timber constructions
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

NODETimberEN1995 := module()
	description "Dimensioning of timber structures according to EN1995-1-1";
	option package;
	global WhateverYouNeed;
	uses Units[Simple], NODEFunctions, DocumentTools, StringTools;

	export EC5_612, EC5_613, EC5_614, EC5_615, EC5_616, EC5_617, EC5_618, EC5_622, EC5_623, EC5_624, EC5_63, EC5_643,
	       calculate_k_64, GetMaterialdata, GetSectiondata, strengthclassExists, SetComboBoxMaterial, SetComboBoxSection, Changed_bh, GetActiveSectionName, kh, 
	       EC5_812, EC5_814, EC5_814_NA_DE, EC5_62net, EC5_832, EC5_833, AnnexA, calculateMinimumdistances, calculate_amin_max, calculateShearplanes, calculate_t_total, calculate_t, calculate_f_h0k,
	       BoltandSteelCapacity, calculate_F_axR, checkPredrilled, GetFastenervalues, calculate_n_ef, checkServiceclass, gamma_M, checkOpeningGeometry, calculate_BeamWithOpening, GetCalculatedFastener,
	       ReadComponentsSpecific_fastener, ReadComponentsSpecific_connection, SetComboFastenersAfterXMLImport, SetComboConnectionAfterXMLImport, SetVisibilityComboboxConnection, validateConnection, SetComboConnection, 
	       SetComboFasteners, SetVisibilityWasher, SetVisibilityShearConnector, SetVisibilityTimberCut, SetComboBoxSharpMetal, SetComboBoxSplitRing, SetComboBoxToothedPlateConnectors, SetVisibilityCutProfile,
	       SetVisibilityOpening, SetLoadExcentricity, CheckLoadExcentricity;
	       
	       # version   not working as it already is defined in NODEFunctions
	       
	local ModuleLoad, kmod, EC5_615_EN, EC5_615_NTI, calculate_k_c90, calculate_F_90R, calculate_F_vR, 
		calculate_alpha_rope, calculate_k_ef, calculate_f_axk, calculate_f_headk, calculate_f_hk, calculate_F_vR_89_810, calculate_amin_alpha,
		PrintMinimumdistance, calculate_amin_steel, calculate_n_ef_872, f_k1k;

# The introducer ("$") must appear as the first character of a line to be recognized as a preprocessor directive.
$include "Timber/EC5_2.mm";

$include "Timber/EC5_61.mm";
$include "Timber/EC5_62.mm";
$include "Timber/EC5_63.mm";
$include "Timber/EC5_64.mm";

$include "Timber/EC5_81.mm";
$include "Timber/EC5_82.mm";
$include "Timber/EC5_83.mm";
$include "Timber/EC5_85.mm";
$include "Timber/EC5_87.mm";

$include "Timber/EC5_89_810.mm";
$include "Timber/EC5_Annex.mm";
$include "Timber/EC5_8_minimumdistance.mm";
$include "Timber/EC5_general.mm";

$include "Timber/NODETimberLibrary.mm";

end module: