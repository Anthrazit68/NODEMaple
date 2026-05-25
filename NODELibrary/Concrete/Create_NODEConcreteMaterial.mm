# Create_NODEConcreteMaterial
# Based on Creating the AISC Shapes Database Package, Samir Khan (skhan@maplesoft.com) , September 2019. 
# v 0.2
# Andreas Zieritz

# Program reads materialdatabase and writes to Maple library

# Importing and Parsing Data

data:=convert(ExcelTools:-Import("Data/Materialdata.xlsx","concrete","A1:D21"), Matrix):
data:=subs("&ndash;" = NULL,data):

# This is the metadata from the spreadsheet
# - ingen dots in variablename!

# reading f_ck and f_ck,cube - all other values are calculated
metadata:=[[A, "strengthclass_NS", 1, "Strength class NS, e.g. B35, LB30"]
		,[B, "strengthclass_CEN", 1, "Strength class CEN, e.g. C20/25, LC25/28"]
		,[C, "f_ck", (MPa), "betongens karakteristiske sylindertrykkfasthet etter 28 døgn"]
		,[D, "f_ck,cube", (MPa), "betongens karakteristiske terningtrykkfasthet etter 28 døgn"]]:

# ,[E, "f_cm", (MPa), "middelverdi av betongens sylindertrykkfasthet"]
# ,[F, "f_ctm", (MPa), "middelverdi av betongens aksialstrekkfasthet"]
# ,[G, "f_ctk,0,05", (MPa), "betongens karakteristiske aksialstrekkfasthet"]
# ,[H, "f_ctk,0,95", (MPa), "betongens karakteristiske aksialstrekkfasthet"]
# ,[I, "E_cm", (GPa), "sekantmodul, elastisitetsmodul for betong"]
# ,[J, "epsilon_c1", 1, "trykktøyning i betongen ved største spenning fc"]
# ,[K, "epsilon_cu1", 1, "tøyningsgrense for trykk i betongen"]
# ,[L, "epsilon_c2", 1, "trykktøyning i betongen"]
# ,[M, "epsilon_cu2", 1, "tøyningsgrense for trykk i betongen"]
# ,[N, "n", 1, " "]
# ,[O, "epsilon_c3", 1, "trykktøyning i betongen"]
# ,[P, "epsilon_cu3", 1, "tøyningsgrense for trykk i betongen"]]:


# Create a table data structure and read the material data into it
# i...number of rows with values
# j...number of columns with values

# if all values required, change j = 1..4 to j = 1..16
dataTable:=table():
temp:=seq(
	dataTable[data[i,1]] = 
	table([ 
		seq(metadata[j,2] = 
			`if`(data[i,j]<>NULL, data[i,j]*Unit(metadata[j,3]), NULL) 
		,j = 1..4)
		 ])
	,i=2..21):