
return Event(function(player_name, player_role, is_guest, identifiers)
    local beammpid = identifiers["beammp"]
    local ip = identifiers["ip"]
    
    local result = RegisterPlayer.register(beammpid, player_name, ip, is_guest)
    
    if result then
        -- Si result n'est pas nil, c'est un message d'erreur (refus de connexion)
        Utils.nkprint("[onPlayerAuth] Player denied: " .. player_name .. " - " .. result, "warning")
        return result
    end

    Utils.nkprint("[onPlayerAuth] Player authorized: " .. player_name .. " (ID: " .. (beammpid or "guest") .. ")", "info")
    return nil
end)