# Create_NODETimberMaterial
# Based on Creating the AISC Shapes Database Package, Samir Khan (skhan@maplesoft.com) , September 2019. 
# v 0.5
# Andreas Zieritz
# 2020-03-07 erstattet punkter med komma i variabelnavn
# 2020-03-12 endret E__0,05, G__0,05
# 2020-03-16 endret navn på fil og library
# 2020-04-13 endret navn på library
# 2020-05-01 konvertert til Maple Workbook
# 2022-02-18 endret betegnelser til engelsk

# - Programmet leser materialdatabasen (Excel fil) og skriver en Maple library som andre Maple programmer kan bruke senere.
# - NODEMaterial.mla må kopieres fra NODE_Development til NODE_Library
# Importing and Parsing Data

data:=convert(ExcelTools:-Import("Data/Materialdata.xlsx","timber","A1:R42"), Matrix):
data:=subs("&ndash;" = NULL,data):

# This is the metadata from the spreadsheet
# - ingen punkter i variabelnavn!

metadata:=[ 
 [A, "strengthclass", 1, "Strength class, e.g. C24, GL30c"]
,[B, "f_m,k", (N/mm^2), "Bending strength"]
,[C, "f_t,0,k", (N/mm^2), "Tension parallel strength"]
,[D, "f_t,90,k", (N/mm^2), "Tension perpendicular strength"]
,[E, "f_c,0,k", (N/mm^2), "Compression parallel strength"]
,[F, "f_c,90,k", (N/mm^2), "Compression perpendicular strength"]
,[G, "f_v,k", (N/mm^2), "Shear strength"]
,[H, "f_r,k", (N/mm^2), "Rolling shear strength"]
,[I, "E_m,0,mean", (N/mm^2), "Mean modulus of elasticity parallel"]
,[J, "E_m,0,k", (N/mm^2), "5% modulus of elasticity parallel"]
,[K, "E_m,90,mean", (N/mm^2), "Mean modulus of elasticity perpendicular"]
,[L, "E_90,05", (N/mm^2), "5% modulus of elasticity perpendicular"]
,[M, "G_mean", (N/mm^2), "Mean shear modulus"]
,[N, "G_0,05", (N/mm^2), "5% modulus of shear"]
,[O, "G_r,mean", (N/mm^2), "Mean modulus of rolling shear"]
,[P, "G_r,05", (N/mm^2), "5% modulus of rolling shear"]
,[Q, "rho_k", (kg/m^3), "Density"]
,[R, "rho_mean", (kg/m^3), "Mean density"]]:


# Create a table data structure and read the material data into it
# i...number of rows with values
# j...number of columns with values

dataTable:=table():
temp:=seq(
dataTable[data[i,1]] = 

table([ 

   seq(metadata[j,2] = 

      `if`(data[i,j]<>NULL, data[i,j]*Unit(metadata[j,3]), NULL) 

   ,j = 1..18)

 ])

,i=2..42):

assign(temp):

convert(data[1,2..],list):
convert(metadata[2..,2],list):
convert(data[2..,1],list):