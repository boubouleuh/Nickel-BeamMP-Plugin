
return function(player_name, player_role, is_guest, identifiers)
    local beammpid = identifiers["beammp"]
    local ip = identifiers["ip"]
    
    if not beammpid then
        Utils.nkprint("[onPlayerAuth] Invalid BeamMP ID for player: " .. player_name, "error")
        return "Invalid player data"
    end

    local result = RegisterPlayer.register(beammpid, player_name, ip, is_guest)
    
    if result then
        -- Si result n'est pas nil, c'est un message d'erreur (refus de connexion)
        Utils.nkprint("[onPlayerAuth] Player denied: " .. player_name .. " - " .. result, "warning")
        return result
    end

    Utils.nkprint("[onPlayerAuth] Player authorized: " .. player_name .. " (ID: " .. beammpid .. ")", "info")
    return nil
end