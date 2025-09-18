
InterfaceUtils = {}

--- send a string to one client (ONLY PLAYERID)
---@param id integer
---@param event_name string
---@param data string   
function InterfaceUtils.sendString(id, event_name, data)
    local beammpid = Utils.getPlayerBeamMPID(MP.GetPlayerName(id))
    if SessionManager.getData(beammpid, "synced") then
        Utils.nkprint("(" .. id .. ") [" .. event_name .. "] ", "debug")
        Utils.nkprint(data, "debug")       
        MP.TriggerClientEvent(id, event_name, data)
    end 
end

--- send a string to every clients (ONLY PLAYERID)
---@param event_name string
---@param data string
function InterfaceUtils.sendStringToAll(event_name, data)
    local onlineplayers = MP.GetPlayers()
    for i, v in pairs(onlineplayers) do
        InterfaceUtils.sendString(i, event_name, data)
    end
end

--- send a table to one client (ONLY PLAYERID)
---@param id integer
---@param event_name string
---@param data table   
function InterfaceUtils.sendTable(id, event_name, data)
    local beammpid = Utils.getPlayerBeamMPID(MP.GetPlayerName(id))
    if SessionManager.getData(beammpid, "synced") then
        Utils.nkprint("(" .. id .. ") [" .. event_name .. "] ", "debug")
        Utils.nkprint(Util.JsonEncode(data), "debug")
        MP.TriggerClientEventJson(id, event_name, data)
    end
end

--- send a table to every clients (ONLY PLAYERID)
---@param event_name string
---@param data table
function InterfaceUtils.sendTableToAll(event_name, data)
    local onlineplayers = MP.GetPlayers()
    for i, v in pairs(onlineplayers) do
        InterfaceUtils.sendTable(i, event_name, data)
    end
end

--- send nothing one client, useful to just trigger a client function when needed (ONLY PLAYERID)
---@param id integer
---@param event_name string
function InterfaceUtils.sendNothing(id, event_name)
    local beammpid = Utils.getPlayerBeamMPID(MP.GetPlayerName(id))
    if SessionManager.getData(beammpid, "synced") then
        Utils.nkprint("(" .. id .. ") [" .. event_name .. "] ", "debug")
        MP.TriggerClientEvent(id, event_name, "")
    end
end

--- send nothing to every clients, useful to just trigger a client function when needed (ONLY PLAYERID)
---@param event_name string
function InterfaceUtils.sendNothingToAll(event_name)
    local onlineplayers = MP.GetPlayers()
    for i, v in pairs(onlineplayers) do
        InterfaceUtils.sendNothing(i, event_name)
    end
end

--- send every players to client
---@param receiver_id integer
---@param offset integer
function InterfaceUtils.sendPlayers(receiver_id, offset)
    if receiver_id < 0 then
        error("Error in sendPlayer: receiver_id is negative, if you try to send to all players, please loop into every players manually to call this function")
    end

    local seeAdvancedUserInfos = PermissionsManager:hasPermissionForAction(Utils.getPlayerBeamMPID(MP.GetPlayerName(receiver_id)), "seeAdvancedUserInfos")
    local onlinePlayers = MP.GetPlayers()
    local allUsers = UserRepository.findAll() or {}
    
    local players = {}
    for _, user in ipairs(allUsers) do
        local playerData = {
            beammpid = user.beammpid,
            name = user.name,
            whitelisted = Utils.isTruthy(user.whitelisted),
            online = onlinePlayers[Utils.GetPlayerId(user.name)] ~= nil,
            roles = {},
            status = {},
            ips = {}
        }
        
        -- Get user roles
        local userRoles = UserRoleRepository.findByBeammpid(user.beammpid) or {}
        for _, userRole in ipairs(userRoles) do
            local role = RoleRepository.findById(userRole.roleID)
            if role then
                table.insert(playerData.roles, {
                    name = role.roleName,
                    permlvl = role.permlvl
                })
            end
        end
        
        -- Get user status
        local userStatuses = UserStatusRepository.findAllByUser(user.beammpid) or {}
        for _, status in ipairs(userStatuses) do
            if Utils.isTruthy(status.is_status_value) then
                table.insert(playerData.status, {
                    status_type = status.status_type,
                    status_value = status.is_status_value,
                    reason = status.reason or "",
                    expiry_time = status.expiry_time
                })
            end
        end
        
        -- Get user IPs (only if has permission)
        if seeAdvancedUserInfos then
            local userIps = UserIpRepository.findAllByUser(user.beammpid) or {}
            for _, ipRecord in ipairs(userIps) do
                if ipRecord.ip then
                    table.insert(playerData.ips, ipRecord.ip)
                end
            end
        end
        
        -- Add avatar if enabled
        if ConfigManager.GetSetting("client").b64avatar then
            playerData.b64img = "data:image/png;base64," .. Online.getPlayerB64Img(user.beammpid)
        end
        
        table.insert(players, playerData)
    end

    local maxPacketSize = 30000000 -- 30 MB
    local currentPacket = {}
    local currentSize = 0

    for i, v in ipairs(players) do
        local playerData = Util.JsonEncode(v) 
        local playerSize = #playerData

        if currentSize + playerSize > maxPacketSize then
            InterfaceUtils.sendTable(receiver_id, "NKinsertPlayers", currentPacket)
            currentPacket = {}
            currentSize = 0
        end
        table.insert(currentPacket, v)
        currentSize = currentSize + playerSize
    end

    if #currentPacket > 0 then
        InterfaceUtils.sendTable(receiver_id,"NKinsertPlayers", currentPacket)
    end

    InterfaceUtils.resetUserInfos(receiver_id)
end

function InterfaceUtils.resetUserInfos(receiver_id)
    local userInfos = {}
    userInfos.self_action_perm = {}
    local actions = PermissionsManager:getActions(Utils.getPlayerBeamMPID(MP.GetPlayerName(receiver_id)))
    for _, action in ipairs(actions) do
        table.insert(userInfos.self_action_perm, action.actionName)
    end
    InterfaceUtils.sendTable(receiver_id, "NKgetUserInfos", userInfos)
end

function InterfaceUtils.resetAllUserInfos()
    local onlineplayers = MP.GetPlayers()
    for i, v in pairs(onlineplayers) do
        InterfaceUtils.resetUserInfos(i)
    end
end

function InterfaceUtils.sendUserCommands(receiver_id)
    local beammpid = Utils.getPlayerBeamMPID(MP.GetPlayerName(receiver_id))
    local commands = PermissionsManager:getCommands(beammpid)
    local userCommands = {}
    local commandCache = CommandsManager:GetCommands()
    for i, v in ipairs(commands) do
        local command = commandCache[v.commandName]
        if command then
            if command.type and command.type == "user" then
                userCommands[v.commandName] = {
                    args = command.args or {},
                    type = command.type
                }
            end
        end
    end
    InterfaceUtils.sendTable(receiver_id, "NKgetUserCommands", userCommands)
end

function InterfaceUtils.sendGlobalCommands(receiver_id)
    local beammpid = Utils.getPlayerBeamMPID(MP.GetPlayerName(receiver_id))
    local commands = PermissionsManager:getCommands(beammpid)
    local globalCommands = {}
    local commandCache = CommandsManager:GetCommands()
    for i, v in ipairs(commands) do
        local command = commandCache[v.commandName]
        if command then
            if command.type and command.type == "global" then
                globalCommands[v.commandName] = {
                    args = command.args or {},
                    type = command.type,
                    extension = command.extension
                }
            end
        end
    end
    InterfaceUtils.sendTable(receiver_id, "NKgetGlobalCommands", globalCommands)
end

--- send one player to client
---@param receiver_id integer
---@param beammpid integer
function InterfaceUtils.sendPlayer(receiver_id, beammpid)
    if receiver_id < 0 then
        error("Error in sendPlayer: receiver_id is negative, if you try to send to all players, please loop into every players manually to call this function")
    end

    local user = UserRepository.findByBeammpid(beammpid)
    if not user then
        return
    end

    local onlinePlayers = MP.GetPlayers()
    local playerData = {
        beammpid = user.beammpid,
        name = user.name,
        whitelisted = Utils.isTruthy(user.whitelisted),
        online = onlinePlayers[Utils.GetPlayerId(user.name)] ~= nil,
        roles = {},
        status = {},
        ips = {}
    }
    
    -- Get user roles
    local userRoles = UserRoleRepository.findByBeammpid(user.beammpid) or {}
    for _, userRole in ipairs(userRoles) do
        local role = RoleRepository.findById(userRole.roleID)
        if role then
            table.insert(playerData.roles, {
                name = role.roleName,
                permlvl = role.permlvl
            })
        end
    end
    
    -- Get user status
    local userStatuses = UserStatusRepository.findByBeammpid(user.beammpid) or {}
    for _, status in ipairs(userStatuses) do
        if Utils.isTruthy(status.is_status_value) then
            table.insert(playerData.status, {
                status_type = status.status_type,
                status_value = status.is_status_value,
                reason = status.reason or "",
                expiry_time = status.expiry_time
            })
        end
    end
    
    -- Get user IPs (only if has permission)
    if PermissionsManager:hasPermissionForAction(Utils.getPlayerBeamMPID(MP.GetPlayerName(receiver_id)), "seeAdvancedUserInfos") then
        local userIps = UserIpRepository.findByBeammpid(user.beammpid) or {}
        for _, ipRecord in ipairs(userIps) do
            if ipRecord.ip then
                table.insert(playerData.ips, ipRecord.ip)
            end
        end
    end
    
    -- Add avatar if enabled
    if ConfigManager.GetSetting("client").b64avatar then
        playerData.b64img = "data:image/png;base64," .. Online.getPlayerB64Img(user.beammpid)
    end

    InterfaceUtils.resetUserInfos(receiver_id)
    InterfaceUtils.sendTable(receiver_id, "NKinsertPlayers", {playerData})
end

--- send every roles to client
---@param id integer
---@param event_name string
function InterfaceUtils.sendRoles(id, event_name)
    local roles = RoleRepository.findAll()

    local rolesfinal = {}
    for i, v in pairs(roles) do
        table.insert(rolesfinal, {permlvl = v.permlvl, roleName = v.roleName})
    end

    InterfaceUtils.sendTable(id, event_name, rolesfinal)
end