
RegisterPlayer = {}

function RegisterPlayer.register(beammpid, name, ip, isguest)
    if not beammpid then
        Utils.nkprint("[registerPlayer] Invalid BeamMP ID for player: " .. (name or "Unknown"), "error")
        return "Invalid player data"
    end

    if not isguest then
        local user = UsersService.getOrCreateUser(beammpid, name)
        if not user then
            Utils.nkprint("[registerPlayer] Failed to create user: " .. name, "error")
            return "Failed to register user"
        end

        if name then
            Online.savePlayerAvatarImg(name, 40)
        end

        if ip then
            DatabaseManager:withConnection(function()
                local existingIp = DatabaseManager:getEntry(UserIp, {{"beammpid", beammpid}})
                if existingIp then
                    existingIp.ip = ip
                    DatabaseManager:save(existingIp)
                else
                    local newUserIp = UserIp.new(beammpid, ip)
                    DatabaseManager:save(newUserIp)
                end
            end)
        end

        DatabaseManager:withConnection(function()
            local userRoles = DatabaseManager:getAllEntries(UserRole, {{"beammpid", beammpid}})
            if #userRoles == 0 then
                local defaultRoles = DatabaseManager:getAllEntries(Role, {{"isDefault", 1}})
                for _, role in ipairs(defaultRoles) do
                    local userRole = UserRole.new(beammpid, role.roleID)
                    DatabaseManager:save(userRole)
                    Utils.nkprint("[registerPlayer] Assigned default role '" .. role.roleName .. "' to " .. name, "debug")
                end
            end
        end)

        if not StatusService.canPlayerConnect(beammpid) then
            local banReason = StatusService.getStatusReason(beammpid, "isbanned") or 
                             StatusService.getStatusReason(beammpid, "istempbanned")
            
            Utils.nkprint("[registerPlayer] Banned user denied: " .. name .. " (reason: " .. (banReason or "No reason") .. ")", "warning")
            return banReason or "You are banned from this server"
        end

        local conditionsConfig = Settings.GetSetting("conditions")
        if conditionsConfig and conditionsConfig.whitelist_required then
            local isWhitelisted = UsersService.isUserWhitelisted(beammpid)
            if not isWhitelisted then
                Utils.nkprint("[registerPlayer] Non-whitelisted user denied: " .. name, "warning")
                return MessagesManager:GetMessage(-1, "conditions.whitelist_required") or "You are not whitelisted on this server"
            end
        end

        if ip then
            -- local usersIpsService = UsersIpsService.new(beammpid)
            -- if usersIpsService:isIpBanned() then
            --     return "Your IP address is banned from this server"
            -- end
        end

        Utils.nkprint("[registerPlayer] Successfully registered user: " .. name .. " (ID: " .. beammpid .. ")", "info")
        return nil

    else
        local conditionsConfig = Settings.GetSetting("conditions")
        local guestsAllowed = conditionsConfig and conditionsConfig.guest
        if not guestsAllowed then
            Utils.nkprint("[registerPlayer] Guest denied: " .. (name or "Unknown"), "warning")
            return MessagesManager:GetMessage(-1, "conditions.guest_not_allowed") or "Guests are not allowed on this server"
        end
        
        Utils.nkprint("[registerPlayer] Guest allowed: " .. (name or "Unknown"), "info")
        return nil
    end
end