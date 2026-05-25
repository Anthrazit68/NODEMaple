# Create_NODETimberFastenersWashers
# 2021-05-24
# Andreas Zieritz

# - Washers for connections
# - index on bolt diameter
# - 2024-04-13: implemented 8.5.2(3) checks

# Importing and Parsing Data

with(ArrayTools):
data:=convert(ExcelTools:-Import("Data/TimberFasteners.xlsx","Washers","A2:G34"), Matrix):

# This is the metadata from the spreadsheet
# - ingen punkter i variabelnavn!

metadata:=[ 
 [A, "prod", 1, "Producer"]
,[B, "bet", 1, "Type"]
,[C, "descr", 1, "Usage"]
,[D, "fm_dbolt", (mm), "bolt diameter"]
,[E, "fm_dint", (mm), "internal diameter"]
,[F, "fm_dext", (mm), "external diameter"]
,[G, "fm_s", (mm), "thickness"]
]:

# Indeksering: diameter -> produsent -> produkt
# Diameter
fm_dbolt := {}:
for ind,val in data do
	if ind[2]= 4 then
		fm_dbolt:=fm_dbolt union {val * Unit(metadata[4,3])}
	end if
end do;

# Produsent
prod:=table():
for ind,val in fm_dbolt do
	prod[convert(val, unit_free)]:={}
end do:

for i from 1 to upperbound(data)[1] do 
	prod[data[i,4]] := prod[data[i,4]] union {data[i,1]}
end do:

# Produkt
bet:=table():
for ind,val in fm_dbolt do
  for ind1,val1 in prod[convert(val, unit_free)] do
    bet[convert(val, unit_free), val1]:={};
  end do;
end do:

for i from 1 to upperbound(data)[1] do       
  bet[data[i,4], data[i,1]] := bet[data[i,4], data[i,1]] union {data[i,2]};
end do:

descr := table():
fm_dint := table():
fm_dext:=table():
fm_s := table():
for ind,val in fm_dbolt do
  for ind1,val1 in prod[convert(val, unit_free)] do
    for ind2,val2 in bet[convert(val, unit_free), val1] do
      descr[convert(val, unit_free), val1, val2]:={};
      fm_dint[convert(val, unit_free), val1, val2]:={};
      fm_dext[convert(val, unit_free), val1, val2]:={};
      fm_s[convert(val, unit_free), val1, val2]:={};
    end do;
  end do;
end do:

for i from 1 to upperbound(data)[1] do
  descr[data[i,4], data[i,1], data[i,2]] := fm_dint[data[i,4], data[i,1], data[i,2]] union {data[i,3]};
  fm_dint[data[i,4], data[i,1], data[i,2]] := fm_dint[data[i,4], data[i,1], data[i,2]] union {data[i,5] * Unit(metadata[5,3])};
  fm_dext[data[i,4], data[i,1], data[i,2]] := fm_dext[data[i,4], data[i,1], data[i,2]] union {data[i,6] * Unit(metadata[6,3])};
  fm_s[data[i,4], data[i,1], data[i,2]] := fm_s[data[i,4], data[i,1], data[i,2]] union {data[i,7] * Unit(metadata[7,3])};
end do: