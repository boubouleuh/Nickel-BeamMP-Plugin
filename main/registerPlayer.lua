
RegisterPlayer = {}

function RegisterPlayer.register(beammpid, name, ip, isguest)
    if not isguest then
        local user = User.getOrCreate(beammpid, name)

        if name then
            Online.savePlayerAvatarImg(name, 40)
        end

        if ip then
            user:addIp(ip)
        end

        local roles = RoleRepository.findAllDefault()
        print(roles)
        for _, role in ipairs(roles) do
            user:assignRole(role.roleName)
        end
        local canConnect, status = user:canConnect()
        if not canConnect then
            if status == "ip_banned" then
                return "Your IP address is banned from this server"
            end
            
            if status == "not_whitelisted" then
                return MessagesManager:GetMessage(-1, "conditions.whitelist_required") or "You are not whitelisted on this server"
            end
            
            if status == "banned" then
                if user:isTempBanned() then
                    return user:getStatus("istempbanned").reason
                end
                if user:isBanned() then
                    return user:getStatus("isbanned").reason
                end
            end
            
            return "Access denied"
        end

        Utils.nkprint("[registerPlayer] Successfully registered user: " .. name .. " (ID: " .. beammpid .. ")", "info")
        return nil

    else
        local conditionsConfig = ConfigManager.GetSetting("conditions")
        local guestsAllowed = conditionsConfig and conditionsConfig.guest
        if not guestsAllowed then
            return MessagesManager:GetMessage(-1, "conditions.guest_not_allowed") or "Guests are not allowed on this server"
        end
        
        return nil
    end
end