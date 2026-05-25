# Create_NODETimberSections
# v 0.2
# 2020-04-13
# Andreas Zieritz

# - Programmet leser tverrsnittsdatabasen (Excel fil) og skriver en Maple library som andre Maple programmer kan bruke senere.
# - NODETre.mla må kopieres fra NODE_Development til NODE_Library
# Importing and Parsing Data

with(ArrayTools):
data:=convert(ExcelTools:-Import("Data/TimberDimensions.xlsx","Timber","A2:C92"), Matrix):

# This is the metadata from the spreadsheet
# - ingen punkter i variabelnavn!

metadata:=[ 
 [A, "Typ", 1, "Solid timber, Glued laminated timber eller CLT"]
,[B, "b", (mm), "bredde"]
,[C, "h", (mm), "høyde"]]:

# Lag en liste over hvilke tretyper vi har i regnearket (f. eks. solidtimber og glulam)

tretype := {}:
for ind,val in data do	     # loop over tverrsnittsdata
	if ind[2]= 1 then   # ind returnerer linje, rad (f. eks. 54.,3.), vi trenger bare det som står i rad 1
		tretype:=tretype union {val}
	end if
end do;

# Hent hvilken bredder vi har for de enkelte tretypene

profil_b:=table():          # initialisering av variablen som lagrer bredder

for ind,val in tretype do
	profil_b[val]:={}   # initialisering av indeksvariablen for tretypene lagres i en liste
end do:

for i from 1 to upperbound(data)[1] do      # nå fyller vi listen av bredder for de tretypene
	profil_b[data[i,1]] := profil_b[data[i,1]] union {round(data[i,2])}
end do:

# OBS! Data som er lest inn har en komma etter tallet. Dette lager litt utfordring for table index etterpå, ettersom de blir behandlet alfanumerisk. 90 er ulik 90.0.

# Lag liste over hvilke høyder vi har for de enkelte tretypene og breddene
profil_h:=table():		# initialisering av varialen som lagrer høyder

for ind,val in tretype do			# loop over tretyper
	for ind1,val1 in profil_b[val] do	# loop over profilbredder
		profil_h[val, val1]:={}	# høyder for de tretypene og bredder lagres i en liste
	end do;
end do:

for i from 1 to upperbound(data)[1] do       # nå fyller vi listen av bredder for de tretypene
	profil_h[data[i,1], round(data[i,2])] := profil_h[data[i,1], round(data[i,2])] union {round(data[i,3])}
end do:
