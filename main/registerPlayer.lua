
RegisterPlayer = {}

function RegisterPlayer.register(beammpid, name, ip, isguest)
    if not isguest then
      return DatabaseManager:withConnection(function()
        local user = User.getOrCreate(beammpid, name)

        -- Avatar download is non-critical, run it in a thread to not block the player
        if name then
            Nickel.CreateThread(function()
                Online.savePlayerAvatarImg(name, 40)
            end)
        end

        if ip then
            user:addIp(ip)
        end

        local roles = RoleRepository.findAllDefault()
        for _, role in ipairs(roles) do
            user:assignRole(role.roleName)
        end

        local canConnect, status, reason = user:canConnect()
        if not canConnect then
            return reason or "Access denied"
        end

        Utils.nkprint("[registerPlayer] Successfully registered user: " .. name .. " (ID: " .. beammpid .. ")", "info")
        return nil
      end)

    else
        local conditionsConfig = ConfigManager.GetSetting("conditions")
        local guestsAllowed = conditionsConfig and conditionsConfig.guest
        if not guestsAllowed then
            return MessagesManager:GetMessage(-1, "conditions.guest_not_allowed") or "Guests are not allowed on this server"
        end
        
        return nil
    end
end