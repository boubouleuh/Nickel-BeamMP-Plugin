

local command = {
    type = "user",
    args = {
        {name = "rolename", type = "string"},
        {name = "playername", type = "string"}
    }
}

--- command
function command.init(sender_id, sender_name, _, rolename, playername)
    if rolename == nil or playername == nil then
        MessagesManager:SendMessage(sender_id, "commands.revokerole.missing_args", {Prefix = ConfigManager.GetSetting("commands").prefix})
        return false
    end

    rolename = Utils.capitalize(rolename)

    if MP.IsPlayerGuest(Utils.GetPlayerId(playername)) then
        MessagesManager:SendMessage(sender_id, "commands.guest_not_compatible")
        return false
    end

    local beammpid = Utils.getPlayerBeamMPID(playername)

    if beammpid ~= nil then
        if sender_id ~= -2 then
            local senderBeammpid = Utils.getPlayerBeamMPID(sender_name)
            if not PermissionsManager:canManage(senderBeammpid, beammpid) then
                MessagesManager:SendMessage(sender_id, "commands.permissions.insufficient.manage", {Player = playername})
                return false
            end
            if not PermissionsManager:canManageRole(senderBeammpid, rolename) then
                MessagesManager:SendMessage(sender_id, "commands.permissions.insufficient.manage_role", {Role = rolename})
                return false
            end
        end

        DatabaseManager:withConnection(function()
            local role = DatabaseManager:getAllEntry(Role, {{"roleName", rolename}})
            if not role then
                MessagesManager:SendMessage(sender_id, "commands.revokerole.role_not_found", {Role = rolename})
                return
            end
            
            local existingUserRole = DatabaseManager:getAllEntry(UserRole, {{"beammpid", beammpid}, {"roleID", role.roleID}})
            if not existingUserRole then
                MessagesManager:SendMessage(sender_id, "commands.revokerole.does_not_have_role", {Player = playername, Role = rolename})
            else
                DatabaseManager:delete(UserRole, {{"beammpid", beammpid}, {"roleID", role.roleID}})
                MessagesManager:SendMessage(sender_id, "commands.revokerole.success", {Player = playername, Role = rolename})
            end
        end)
        
        return true
    else
        MessagesManager:SendMessage(sender_id, "player.not_found", {Player = playername})
        return false
    end
end

RegisterNickelCommand("revokerole", command)