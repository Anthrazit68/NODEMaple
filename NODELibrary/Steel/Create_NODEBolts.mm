# Based on Creating the AISC Shapes Database Package, Samir Khan (skhan@maplesoft.com) , September 2019. 
# v 0.1
# Andreas Zieritz

# Program reads materialdatabase and writes to Maple library
# Importing and Parsing Data

data:=convert(ExcelTools:-Import("Data/TimberFasteners.xlsx","BoltGrades","A1:M19"), Matrix):
data:=subs("&ndash;" = NULL,data):

# This is the metadata from the spreadsheet
# no dots in variablename!

metadata:=[ 
[A, "bolt", 1, "Bolt type"]
,[B, "As_nom", (mm^2), "nominal section area"]
,[C, "Ftensk_4_6", (kN), "tensile strengt, 4.6 quality"]
,[D, "Ftensk_4_8", (kN), "tensile strengt, 4.8 quality"]
,[E, "Ftensk_5_6", (kN), "tensile strengt, 5.6 quality"]
,[F, "Ftensk_5_8", (kN), "tensile strengt, 5.8 quality"]
,[G, "Ftensk_6_8", (kN), "tensile strengt, 6.8 quality"]
,[H, "Ftensk_8_8", (kN), "tensile strengt, 8.8 quality"]
,[I, "Ftensk_10_9", (kN), "tensile strengt, 10.9 quality"]
,[J, "Ftensk_50", (kN), "tensile strengt, A1 / A5 - 50 quality"]
,[K, "Ftensk_70", (kN), "tensile strengt, A1 / A5 - 70 quality"]
,[L, "Ftensk_80", (kN), "tensile strengt, A1 / A5 - 80 quality"]
,[M, "Ftensk_100", (kN), "tensile strengt, A1 / A5 - 100 quality"]]:

# Create a table data structure and read the material data into it
# i...number of rows with values
# j...number of columns with values

boltgrades_ := convert(data[1,3..13], list):

f_ub_ := table():
f_ub_tab_ := table():

for j from 3 to 13 do
f_ub_[data[1, j]] := data[2, j] * Unit('N/mm^2');
f_ub_tab_[data[1, j]] := data[3, j] * Unit('N/mm^2');
end do:

F_tRd_tab_ := table():

for i from 4 to 19 do
for j from 3 to 13 do
    F_tRd_tab_[data[i, 1], data[1, j]] := data[i,j] * Unit('kN')
end do
end do:

As_nom_ := table():

for i from 4 to 19 do
As_nom_[data[i, 1]] := data[i, 2] * Unit('mm^2')
end do: