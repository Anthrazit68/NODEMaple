# Create_NODETimberToothedPlateConnectors
# 2024-06-08
# Andreas Zieritz
# Importing and Parsing Data

with(ArrayTools):
data:=convert(ExcelTools:-Import("Data/TimberFasteners.xlsx","ToothedPlateConnectors","A3:W79"), Matrix):

# This is the metadata from the spreadsheet
# - ingen punkter i variabelnavn!

metadata:=[ 
 [A, "prod", 1, "Producer"]
,[B, "type", 1, "Type"]
,[C, "sides", 1, "1 or 2-sided"]
,[D, "information", 1, "Type detail"]
,[E, "serviceclass", 1, "fm_serviceclass"]
,[F, "dc", (mm), "dc"]
,[F, "d1", (mm), "d1"]
,[H, "h1", (mm), "h1"]
,[I, "hc", (mm), "hc"]
,[J, "t", (mm), "t"]
,[K, "d2", (mm), "d2"]
,[L, "la1", (mm), "a1"]
,[M, "la2", (mm), "a2"]
,[N, "t1", (mm), "t1"]
,[O, "t2", (mm), "t2"]
,[P, "a1", (mm), "a1"]
,[Q, "a2", (mm), "a2"]
,[R, "a3t", (mm), "a3,t"]
,[S, "a3c", (mm), "a3,c"]
,[T, "a4t", (mm), "a4,t"]
,[U, "a4c", (mm), "a4,c"]
,[V, "Rvk", (kN), "Rf,uk"]
]:

# 1.) Index over types C1...C7
sides_ := {}:
for ind,val in data do	     # loop over types
  if ind[2]= 3 then          # 3.nd column
    sides_:=sides_ union {convert(round(val), string)}
  end if
end do;

# 2.) get type
type_:=table():
for ind,val in sides_ do
	type_[val]:={}   # initialisering av indeksvariable
end do:
for i from 1 to upperbound(data)[1] do 
	type_[convert(round(data[i,3]), string)] := type_[convert(round(data[i,3]), string)] union {data[i,2]}
end do:

# Need to rewrite that, indexing over db gives no meaning
# db should be removed from the list, d1 is the only thing that is important.

# 3.) get diameter
dc_:=table():
for ind,val in sides_ do
  for ind1, val1 in type_[val] do
	dc_[val, val1]:={}   # initialisering av indeksvariable
  end do;
end do:
for i from 1 to upperbound(data)[1] do 
  dc_[convert(round(data[i,3]), string), data[i, 2]] := dc_[convert(round(data[i,3]), string), data[i, 2]] union {data[i,6] * Unit(metadata[6,3])}
end do:

# indexing the rest

producer_:=table():
information_:=table():
serviceclass_:=table():
d1_:=table():
h1_:=table():
hc_:=table():
t_:=table():
d2_:=table():
la1_:=table():
la2_:=table():
t1_:=table():
t2_:=table():
a1_:=table():
a2_:=table():
a3t_:=table():
a3c_:=table():
a4t_:=table():
a4c_:=table():
Rvk_:=table():
for ind,val in sides_ do
  for ind1,val1 in type_[val] do
    for ind2,val2 in dc_[val, val1] do
       producer_[val, val1, round(convert(val2, unit_free))]:={};
       information_[val, val1, round(convert(val2, unit_free))]:={};
       serviceclass_[val, val1, round(convert(val2, unit_free))]:={};
       d1_[val, val1, round(convert(val2, unit_free))]:={};
       h1_[val, val1, round(convert(val2, unit_free))]:={};
       hc_[val, val1, round(convert(val2, unit_free))]:={};
       t_[val, val1, round(convert(val2, unit_free))]:={};
       d2_[val, val1, round(convert(val2, unit_free))]:={};
       la1_[val, val1, round(convert(val2, unit_free))]:={};
       la2_[val, val1, round(convert(val2, unit_free))]:={};
       t1_[val, val1, round(convert(val2, unit_free))]:={};
       t2_[val, val1, round(convert(val2, unit_free))]:={};
       a1_[val, val1, round(convert(val2, unit_free))]:={};
       a2_[val, val1, round(convert(val2, unit_free))]:={};
       a3t_[val, val1, round(convert(val2, unit_free))]:={};
       a3c_[val, val1, round(convert(val2, unit_free))]:={};
       a4t_[val, val1, round(convert(val2, unit_free))]:={};
       a4c_[val, val1, round(convert(val2, unit_free))]:={};
       Rvk_[val, val1, round(convert(val2, unit_free))]:={};
    end do;
  end do;
end do:

for i from 1 to upperbound(data)[1] do 
  producer_[convert(round(data[i,3]), string), data[i,2], round(data[i,6])] := producer_[convert(round(data[i,3]), string), data[i,2], round(data[i,6])] union {data[i,1]};
  information_[convert(round(data[i,3]), string), data[i,2], round(data[i,6])] := information_[convert(round(data[i,3]), string), data[i,2], round(data[i,6])] union {data[i,4]};
  serviceclass_[convert(round(data[i,3]), string), data[i,2], round(data[i,6])] := serviceclass_[convert(round(data[i,3]), string), data[i,2], round(data[i,6])] union {data[i,5]};
  d1_[convert(round(data[i,3]), string), data[i,2], round(data[i,6])] := d1_[convert(round(data[i,3]), string), data[i,2], round(data[i,6])] union {data[i,7]* Unit(metadata[7, 3])};
  h1_[convert(round(data[i,3]), string), data[i,2], round(data[i,6])] := h1_[convert(round(data[i,3]), string), data[i,2], round(data[i,6])] union {data[i,8]* Unit(metadata[8, 3])};
  hc_[convert(round(data[i,3]), string), data[i,2], round(data[i,6])] := hc_[convert(round(data[i,3]), string), data[i,2], round(data[i,6])] union {data[i,9]* Unit(metadata[9, 3])};
  t_[convert(round(data[i,3]), string), data[i,2], round(data[i,6])] := t_[convert(round(data[i,3]), string), data[i,2], round(data[i,6])] union {data[i,10]* Unit(metadata[10, 3])};
  d2_[convert(round(data[i,3]), string), data[i,2], round(data[i,6])] := d2_[convert(round(data[i,3]), string), data[i,2], round(data[i,6])] union {data[i,11]* Unit(metadata[11, 3])};
  la1_[convert(round(data[i,3]), string), data[i,2], round(data[i,6])] := la1_[convert(round(data[i,3]), string), data[i,2], round(data[i,6])] union {data[i,12]* Unit(metadata[12, 3])};
  la2_[convert(round(data[i,3]), string), data[i,2], round(data[i,6])] := la2_[convert(round(data[i,3]), string), data[i,2], round(data[i,6])] union {data[i,13]* Unit(metadata[13, 3])};
  t1_[convert(round(data[i,3]), string), data[i,2], round(data[i,6])] := t1_[convert(round(data[i,3]), string), data[i,2], round(data[i,6])] union {data[i,14]* Unit(metadata[14, 3])};
  t2_[convert(round(data[i,3]), string), data[i,2], round(data[i,6])] := t2_[convert(round(data[i,3]), string), data[i,2], round(data[i,6])] union {data[i,15]* Unit(metadata[15, 3])};
  a1_[convert(round(data[i,3]), string), data[i,2], round(data[i,6])] := a1_[convert(round(data[i,3]), string), data[i,2], round(data[i,6])] union {data[i,16]* Unit(metadata[16, 3])};
  a2_[convert(round(data[i,3]), string), data[i,2], round(data[i,6])] := a2_[convert(round(data[i,3]), string), data[i,2], round(data[i,6])] union {data[i,17]* Unit(metadata[17, 3])};
  a3t_[convert(round(data[i,3]), string), data[i,2], round(data[i,6])] := a3t_[convert(round(data[i,3]), string), data[i,2], round(data[i,6])] union {data[i,18]* Unit(metadata[18, 3])};
  a3c_[convert(round(data[i,3]), string), data[i,2], round(data[i,6])] := a3c_[convert(round(data[i,3]), string), data[i,2], round(data[i,6])] union {data[i,19]* Unit(metadata[19, 3])};
  a4t_[convert(round(data[i,3]), string), data[i,2], round(data[i,6])] := a4t_[convert(round(data[i,3]), string), data[i,2], round(data[i,6])] union {data[i,20]* Unit(metadata[20, 3])};
  a4c_[convert(round(data[i,3]), string), data[i,2], round(data[i,6])] := a4c_[convert(round(data[i,3]), string), data[i,2], round(data[i,6])] union {data[i,21]* Unit(metadata[21, 3])};
  Rvk_[convert(round(data[i,3]), string), data[i,2], round(data[i,6])] := Rvk_[convert(round(data[i,3]), string), data[i,2], round(data[i,6])] union {data[i,22]* Unit(metadata[22, 3])};
end do: