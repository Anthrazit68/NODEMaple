gamma_M := proc(MatConntype::string)
    local gamma_M;

    # NS-EN 1995, NA.2.4.1
	if MatConntype = "Solid timber" then
		gamma_M := 1.25

	elif MatConntype = "Glued laminated timber" or timbertype = "CLT" then
		gamma_M := 1.15

    elif MatConntype = "Connections" then
        gamma_M := 1.3

    else
        gamma_M := 9999
        
	end if;

end proc: