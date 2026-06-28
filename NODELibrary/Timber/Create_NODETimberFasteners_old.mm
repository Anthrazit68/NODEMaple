# Create_NODETimberFasteners.mm :create timber fastener database
# Copyright (C) 2026  Andreas Zieritz

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

with(ArrayTools):
data:=convert(ExcelTools:-Import("Data/TimberFasteners.xlsx","TimberFasteners","A2:P3024"), Matrix):

# This is the metadata from the spreadsheet
# - no "." allowed in variable names

metadata:=[ 
 [A, "fm", 1, "Spiker, bolt, skrue eller dybel"]
,[B, "prod", 1, "prod"]
,[C, "bet", 1, "bet"]
,[D, "descr", 1, "fm_descr"]
,[E, "serviceclass", 1, "fm_serviceclass"]
,[F, "d", (mm), "fm_d"]
,[G, "l", (mm), "lengde"]
,[H, "dh", (mm), "fm_d hodet"]
,[I, "M_y,Rk", (N*m), "My,Rk"]
,[J, "f_ax,k", (N/mm^2), "fax,k"]
,[K, "f_head,k", (N/mm^2), "fhead,k"]
,[L, "f_tens,k", (kN), "ftens,k"]
,[M, "l1", (mm), "threaded length from tip"]
,[N, "l2", (mm), "threaded length from head"]
,[O, "f_uk", (N/mm^2), "f,uk"]
,[P, "B_max", (mm), "B max"]
]:

# 1.) Her begynner første indeksering: Festemiddel -> diameter -> produsent -> typer
# Lag en liste over hvilke festemidler vi har i regnearket (f. eks. skruer eller spiker)

fm := {}:
for ind,val in data do	     # loop over festemidler
  if ind[2]= 1 then
    fm:=fm union {val}
  end if
end do;

# Hent diameter
fm_d:=table():
for ind,val in fm do
	fm_d[val]:={}   # initialisering av indeksvariablee
end do:

for i from 1 to upperbound(data)[1] do 
	fm_d[data[i,1]] := fm_d[data[i,1]] union {data[i,6] * Unit(metadata[6,3])}
end do:

# Producer
prod:=table():          # initialisering av variablen som lagrer produsent
for ind,val in fm do			# loop over festemidler
  for ind1,val1 in fm_d[val] do	# loop over diameter
    prod[val, convert(val1, unit_free)]:={}	# init
  end do;
end do:
for i from 1 to upperbound(data)[1] do
  prod[data[i,1], data[i,6]] := prod[data[i,1], data[i,6]] union {data[i,2]}
end do:

# Types
bet:=table():
for ind,val in fm do
  for ind1,val1 in fm_d[val] do
    for ind2,val2 in prod[val, convert(val1, unit_free)] do
       bet[val, convert(val1, unit_free), val2]:={};
    end do;
  end do;
end do:
for i from 1 to upperbound(data)[1] do 
  bet[data[i,1], data[i,6], data[i,2]] := bet[data[i,1], data[i,6], data[i,2]] union {data[i,3]}
end do:

# 2.) Her begynner 2. indeksering: 
# Produsent -> typer
fm_producers := {}:
for ind,val in data do	     # loop over festemidler
  if ind[2]= 2 then
    fm_producers:=fm_producers union {val}
  end if
end do;

producers_connectionstypes := table():
for ind,val in fm_producers do
	producers_connectionstypes[val]:={}
end do:

for i from 1 to upperbound(data)[1] do 
  producers_connectionstypes[data[i,2]] := producers_connectionstypes[data[i,2]] union {data[i,3]}
end do:

# 2.1.) Betegnelse, Klimaklasse, Diameter
fm_descr:=table():
fm_serviceclass:=table():
prod_con_dia:=table():
for ind,val in fm_producers do
  for ind1,val1 in producers_connectionstypes[val] do	# loop over diameter
    fm_descr[val, val1]:={};
    fm_serviceclass[val, val1]:={};
    prod_con_dia[val, val1]:={};
  end do;
end do:
for i from 1 to upperbound(data)[1] do
  fm_descr[data[i,2], data[i,3]] := fm_descr[data[i,2], data[i,3]] union {data[i,4]};
  fm_serviceclass[data[i,2], data[i,3]] := fm_serviceclass[data[i,2], data[i,3]] union {data[i,5]};
  prod_con_dia[data[i,2], data[i,3]] := prod_con_dia[data[i,2], data[i,3]] union {data[i,6] * Unit(metadata[6,3])}
end do:

fm_l:=table():
fm_MyRk:=table():
fm_faxk:=table():
fm_fheadk:=table():
fm_ftensk:=table():
for ind,val in fm_producers do
  for ind1,val1 in producers_connectionstypes[val] do
    for ind2,val2 in prod_con_dia[val, val1] do
      fm_l[val, val1, convert(val2, unit_free)]:={};
      fm_MyRk[val, val1, convert(val2, unit_free)]:={};
      fm_faxk[val, val1, convert(val2, unit_free)]:={};
      fm_fheadk[val, val1, convert(val2, unit_free)]:={};
      fm_ftensk[val, val1, convert(val2, unit_free)]:={};
    end do;
  end do;
end do:


for i from 1 to upperbound(data)[1] do
  fm_l[data[i,2], data[i,3], data[i,6]] := fm_l[data[i,2], data[i,3], data[i,6]] union {data[i,7] * Unit(metadata[7, 3])};

  fm_MyRk[data[i,2], data[i,3], data[i,6]] := fm_MyRk[data[i,2], data[i,3], data[i,6]] union {data[i,9] * Unit(metadata[9, 3])};
  fm_faxk[data[i,2], data[i,3], data[i,6]] := fm_faxk[data[i,2], data[i,3], data[i,6]] union {data[i,10] * Unit(metadata[10, 3])};
  fm_fheadk[data[i,2], data[i,3], data[i,6]] := fm_fheadk[data[i,2], data[i,3], data[i,6]] union {data[i,11] * Unit(metadata[11, 3])};
  fm_ftensk[data[i,2], data[i,3], data[i,6]] := fm_ftensk[data[i,2], data[i,3], data[i,6]] union {data[i,12] * Unit(metadata[12, 3])};
end do:

fm_dh:=table():
fm_l1:=table():
fm_l2:=table():
fm_fuk := table():
fm_Bmax := table():
for ind,val in fm_producers do

  for ind1,val1 in producers_connectionstypes[val] do

    for ind2,val2 in prod_con_dia[val, val1] do

      for ind3,val3 in fm_l[val, val1, convert(val2, unit_free)] do

        fm_dh[val, val1, convert(val2, unit_free), round(convert(val3, unit_free))]:={};
        fm_l1[val, val1, convert(val2, unit_free), round(convert(val3, unit_free))]:={};
        fm_l2[val, val1, convert(val2, unit_free), round(convert(val3, unit_free))]:={};
        fm_fuk[val, val1, convert(val2, unit_free), round(convert(val3, unit_free))]:={};
        fm_Bmax[val, val1, convert(val2, unit_free), round(convert(val3, unit_free))]:={};

      end do;

    end do;

  end do;

end do:

for i from 1 to upperbound(data)[1] do
  fm_dh[data[i,2], data[i,3], data[i,6], round(data[i,7])] := 
      fm_dh[data[i,2], data[i,3], data[i,6], round(data[i,7])] union {data[i,8] * Unit(metadata[8, 3])};

  fm_l1[data[i,2], data[i,3], data[i,6], round(data[i,7])] := 
      fm_l1[data[i,2], data[i,3], data[i,6], round(data[i,7])] union {data[i,13] * Unit(metadata[13, 3])};

  fm_l2[data[i,2], data[i,3], data[i,6], round(data[i,7])] := 
      fm_l2[data[i,2], data[i,3], data[i,6], round(data[i,7])] union {data[i,14] * Unit(metadata[14, 3])};

  fm_fuk[data[i,2], data[i,3], data[i,6], round(data[i,7])] := 
     fm_fuk[data[i,2], data[i,3], data[i,6], round(data[i,7])] union {data[i,15] * Unit(metadata[15, 3])};

  fm_Bmax[data[i,2], data[i,3], data[i,6], round(data[i,7])] := 
     fm_Bmax[data[i,2], data[i,3], data[i,6], round(data[i,7])] union {data[i,16] * Unit(metadata[16, 3])};

end do: