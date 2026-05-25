# Create_NODESteelMaterial
# Based on Creating the AISC Shapes Database Package, Samir Khan (skhan@maplesoft.com) , September 2019. 
# v 0.2
# Andreas Zieritz

# Program reads materialdatabase and writes to Maple library
# Importing and Parsing Data

data:=convert(ExcelTools:-Import("Data/Materialdata.xlsx","steel","A2:J33"), Matrix):
data:=subs("&ndash;" = NULL,data):

# This is the metadata from the spreadsheet
# - ingen dots in variablename!

metadata:=[ 
 	[A, "steeltype", 1, "Stålsort, e.g. S 235 H"]
	,[B, "steelcode", 1, "Standard, e.g. NS-EN 10210-1"]
	,[C, "f_y_0_40", (MPa), "flytespenning, t=0-40mm"]
	,[D, "f_u_0_40", (MPa), "strekkfasthet, t=0-40mm"]
	,[E, "f_y_40_80", (MPa), "flytespenning, t=40-80mm"]
	,[F, "f_u_40_80", (MPa), "strekkfasthet, t=40-80mm"]
	,[G, "E", (MPa), "elastisitetsmodul"]
	,[H, "nu", 1, "Poisson tall"]
	,[I, "G", (MPa), "skjærmodul"]
	,[J, "alpha_t", (1/K), "temperaturutvidelseskoeffisient"]]:

# Create a table data structure and read the material data into it
# i...number of rows with values
# j...number of columns with values

# List of steelcodes

standarder := {}:

for ind,val in data do # loop over data
   if ind[2] = 2 then  # ind returnerer linje, rad, vi trenger bare det som står i kolonne 2
       standarder:=standarder union {val};
   end if
end do;

steeltypeTocode := table():     # initialisering av variablen som lagrer stålsort

for ind,val in standarder do
     val;
     steeltypeTocode[val] := {}   # initialisering av indeksvariablen
end do:

for i from 1 to upperbound(data)[1] do      # går gjennom listen og lagrer stålsortene
     steeltypeTocode[data[i,2]] := steeltypeTocode[data[i,2]] union {data[i,1]};
end do:

# steel defined in 2 ways
# reason is that steel quality can be defined in 2 different codes, with slightly different material parameters

# Create a table data structure and read the material data into it
# i...number of rows with values
# j...number of columns with values

# https://www.mapleprimes.com/questions/229521-This-Is-Not-A-List#answer268450

dataTable:=table():
temp:=seq(
	dataTable[data[i,1]] = 
		table([ 
   		seq(metadata[j,2] = 
     		 `if`(data[i,j]<>NULL, data[i,j]*Unit(metadata[j,3]), NULL) 
   		,j = 1..10)
 		])
		,i=1..32):

assign(temp):

dataTable1:=table():
temp1:=seq(
	dataTable1[eval({data[i,1], data[i,2]})] = 

		table([ 
   		seq(metadata[j,2] = 
     		 `if`(data[i,j]<>NULL, data[i,j]*Unit(metadata[j,3]), NULL) 
   		,j = 1..10)
 		])
		,i=1..32):

assign(temp1):