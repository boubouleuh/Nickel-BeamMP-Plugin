
local command = RegisterCommand("grantrole", {
    args = {
        {name = "rolename", type = "string"},
        {name = "playername", type = "string"}
    }
})

--- command
function command.init(sender_id, sender_name, rolename, playername)
    if rolename == nil or playername == nil then
        MessagesManager:SendMessage(sender_id, "commands.grantrole.missing_args", {Prefix = ConfigManager.GetSetting("commands").prefix})
        return false
    end

    rolename = Utils.capitalize(rolename)

    if MP.IsPlayerGuest(Utils.GetPlayerId(playername)) then
        MessagesManager:SendMessage(sender_id, "commands.guest_not_compatible")
        return false
    end

    local target_beammpid = Utils.getPlayerBeamMPID(playername)
    if target_beammpid == nil then
        MessagesManager:SendMessage(sender_id, "player.not_found", {Player = playername})
        return false
    end
    local target_user = User.getOrCreate(target_beammpid, playername)


    if sender_id ~= -2 then
        local sender_beammpid = Utils.getPlayerBeamMPID(sender_name)
        local sender_user = User.getOrCreate(sender_beammpid, sender_name)
        if not sender_user:canManage(target_beammpid) then
            MessagesManager:SendMessage(sender_id, "commands.permissions.insufficient.manage", {Player = playername})
            return false
        end
        if not sender_user:canManageRole(rolename) then
            MessagesManager:SendMessage(sender_id, "commands.permissions.insufficient.manage_role", {Role = rolename})
            return false
        end
    end
    local code = target_user:assignRole(rolename)


    MessagesManager:SendMessage(sender_id, "database.code." .. code)

    InterfaceUtils.updatePlayer(target_beammpid)
    
    return true
end