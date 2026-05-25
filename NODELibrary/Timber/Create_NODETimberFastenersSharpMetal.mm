# Create_NODETreFestemidlerSharpMetal
# 2021-09-11
# Andreas Zieritz

# - Beregning av verdier for Rothoblaas Sharp Metal forbindelser

#Importing and Parsing Data

with(ArrayTools):
data:=convert(ExcelTools:-Import("Data/TimberFasteners.xlsx","Rothoblaas Sharp Metal","A2:L5"), Matrix):
# This is the metadata from the spreadsheet
# - ingen punkter i variabelnavn!

metadata:=[ 
 [A, "prod", 1, "Produsent"]
,[B, "bet", 1, "Betegnelse"]
,[C, "descr", 1, "Beskrivelse"]
,[D, "fm_serviceclass", 1, "fm_serviceclass"]
,[E, "fm_width", (mm), "Bredde av spikerbånd"]
,[F, "fm_withscrew", 1, "Forbindelse med skrue"]
,[G, "f_v,0,k", (N/mm^2), "Shear strength parallel"]
,[H, "f_v,90,k", (N/mm^2), "Shear strength normal"]
,[I, "f_v,EG,k", (N/mm^2), "Shear strength edge"]
,[J, "k_ser,0,k", (N/mm^3), "Deformation factor parallel"]
,[K, "k_ser,90,k", (N/mm^3), "Deformation factor normal"]
,[L, "k_ser,EG,k", (N/mm^3), "Deformation factor edge"]
]:

# Indeksering: diameter -> produsent -> produkt
# Diameter
fm_withscrew := {}:
for ind,val in data do
	if ind[2]= 6 then
		fm_withscrew:=fm_withscrew union {val}
	end if
end do;

# Produsent
prod:=table():
for ind,val in fm_withscrew do
	prod[val]:={}
end do:

for i from 1 to upperbound(data)[1] do 
	prod[data[i,6]] := prod[data[i,6]] union {data[i,1]}
end do:

# Produkt
bet:=table():
for ind,val in fm_withscrew do
  for ind1,val1 in prod[val] do
    bet[val, val1]:={};
  end do;
end do:
for i from 1 to upperbound(data)[1] do       
  bet[data[i,6], data[i,1]] := bet[data[i,6], data[i,1]] union {data[i,2]};
end do:

descr := table():
fm_serviceclass := table():
fm_width:=table():
fm_fv0k := table():
fm_fv90k := table():
fm_fvEGk := table():
fm_kser0k := table():
fm_kser90k := table():
fm_kserEGk := table():

for ind,val in fm_withscrew do
  for ind1,val1 in prod[val] do
    for ind2,val2 in bet[val, val1] do
      descr[val, val1, val2] := {};
      fm_serviceclass[val, val1, val2] := {};
      fm_width[val, val1, val2] := {};
      fm_fv0k[val, val1, val2] := {};
      fm_fv90k[val, val1, val2] := {};
      fm_fvEGk[val, val1, val2] := {};
      fm_kser0k[val, val1, val2] := {};
      fm_kser90k[val, val1, val2] := {};
      fm_kserEGk[val, val1, val2] := {};
    end do;
  end do;
end do:

for i from 1 to upperbound(data)[1] do       
  descr[data[i,6], data[i,1], data[i,2]] := descr[data[i,6], data[i,1], data[i,2]] union {data[i,3]};
 fm_serviceclass[data[i,6], data[i,1], data[i,2]] := fm_serviceclass[data[i,6], data[i,1], data[i,2]] union {data[i,4]};
  fm_width[data[i,6], data[i,1], data[i,2]] := fm_width[data[i,6], data[i,1], data[i,2]] union {data[i,5] * Unit(metadata[5,3])};
  fm_fv0k[data[i,6], data[i,1], data[i,2]] := fm_fv0k[data[i,6], data[i,1], data[i,2]] union {data[i,7] * Unit(metadata[7,3])};
  fm_fv90k[data[i,6], data[i,1], data[i,2]] := fm_fv90k[data[i,6], data[i,1], data[i,2]] union {data[i,8] * Unit(metadata[8,3])};
  fm_fvEGk[data[i,6], data[i,1], data[i,2]] := fm_fvEGk[data[i,6], data[i,1], data[i,2]] union {data[i,9] * Unit(metadata[9,3])};
  fm_kser0k[data[i,6], data[i,1], data[i,2]] := fm_kser0k[data[i,6], data[i,1], data[i,2]] union {data[i,10] * Unit(metadata[10,3])};
  fm_kser90k[data[i,6], data[i,1], data[i,2]] := fm_kser90k[data[i,6], data[i,1], data[i,2]] union {data[i,11] * Unit(metadata[11,3])};
  fm_kserEGk[data[i,6], data[i,1], data[i,2]] := fm_kserEGk[data[i,6], data[i,1], data[i,2]] union {data[i,12] * Unit(metadata[12,3])};
end do: