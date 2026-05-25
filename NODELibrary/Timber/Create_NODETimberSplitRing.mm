# Create_NODETimberSplitRing
# 2024-06-08
# Andreas Zieritz
# Importing and Parsing Data

with(ArrayTools):
data:=convert(ExcelTools:-Import("Data/TimberFasteners.xlsx","Simpson SplitRing","A3:N9"), Matrix):

# This is the metadata from the spreadsheet
# - ingen punkter i variabelnavn!

metadata:=[ 
 [A, "prod", 1, "Producer"]
,[B, "type", 1, "Type"]
,[C, "information", 1, "Type detail"]
,[D, "serviceclass", 1, "fm_serviceclass"]
,[E, "dc", (mm), "dc"]
,[F, "hc", (mm), "hc"]
,[G, "t", (mm), "t"]
,[H, "r", (mm), "r"]
,[I, "a1", (mm), "a1"]
,[J, "a2", (mm), "a2"]
,[K, "a3t", (mm), "a3,t"]
,[L, "a3c", (mm), "a3,c"]
,[M, "a4t", (mm), "a4,t"]
,[N, "a4c", (mm), "a4,c"]
]:

# 1.) Index over types A1
type_ := {}:
for ind,val in data do	     # loop over types
  if ind[2]= 2 then          # 2.nd column
    type_:=type_ union {val}
  end if
end do;

# 2.) get type
dc_:=table():
for ind,val in type_ do
	dc_[val]:={}   # initialisering av indeksvariable
end do:
for i from 1 to upperbound(data)[1] do 
	dc_[data[i,2]] := dc_[data[i,2]] union {data[i,5]* Unit(metadata[5,3])}
end do:

# indexing the rest
producer_:=table():
information_:=table():
serviceclass_:=table():
hc_:=table():
t_:=table():
r_:=table():
a1_:=table():
a2_:=table():
a3t_:=table():
a3c_:=table():
a4t_:=table():
a4c_:=table():

for ind,val in type_ do
  for ind1,val1 in dc_[val] do
     producer_[val, round(convert(val1, unit_free))]:={};
     information_[val, round(convert(val1, unit_free))]:={};
     serviceclass_[val, round(convert(val1, unit_free))]:={};
     hc_[val, round(convert(val1, unit_free))]:={};
     t_[val, round(convert(val1, unit_free))]:={};
     r_[val, round(convert(val1, unit_free))]:={};
     a1_[val, round(convert(val1, unit_free))]:={};
     a2_[val, round(convert(val1, unit_free))]:={};
     a3t_[val, round(convert(val1, unit_free))]:={};
     a3c_[val, round(convert(val1, unit_free))]:={};
     a4t_[val, round(convert(val1, unit_free))]:={};
     a4c_[val, round(convert(val1, unit_free))]:={};   
  end do;
end do:

for i from 1 to upperbound(data)[1] do 
  producer_[data[i,2], round(data[i,5])] := producer_[data[i,2], round(data[i,5])] union {data[i,1]};
  information_[data[i,2], round(data[i,5])] := information_[data[i,2], round(data[i,5])] union {data[i,3]};
  serviceclass_[data[i,2], round(data[i,5])] := serviceclass_[data[i,2], round(data[i,4])] union {data[i,4]};
  hc_[data[i,2], round(data[i,5])] := hc_[data[i,2], round(data[i,5])] union {data[i,6]* Unit(metadata[6, 3])};
  t_[data[i,2], round(data[i,5])] := t_[data[i,2], round(data[i,5])] union {data[i,7]* Unit(metadata[7, 3])};
  r_[data[i,2], round(data[i,5])] := r_[data[i,2], round(data[i,5])] union {data[i,8]* Unit(metadata[8, 3])};
  a1_[data[i,2], round(data[i,5])] := a1_[data[i,2], round(data[i,5])] union {data[i,9]* Unit(metadata[9, 3])};
  a2_[data[i,2], round(data[i,5])] := a2_[data[i,2], round(data[i,5])] union {data[i,10]* Unit(metadata[10, 3])};
  a3t_[data[i,2], round(data[i,5])] := a3t_[data[i,2], round(data[i,5])] union {data[i,11]* Unit(metadata[11, 3])};
  a3c_[data[i,2], round(data[i,5])] := a3c_[data[i,2], round(data[i,5])] union {data[i,12]* Unit(metadata[12, 3])};
  a4t_[data[i,2], round(data[i,5])] := a4t_[data[i,2], round(data[i,5])] union {data[i,13]* Unit(metadata[13, 3])};
  a4c_[data[i,2], round(data[i,5])] := a4c_[data[i,2], round(data[i,5])] union {data[i,14]* Unit(metadata[14, 3])};
end do: