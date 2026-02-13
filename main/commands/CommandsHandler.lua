CommandsManager = {}

NickelCommands = NickelCommands or {}

function RegisterCommand(name, commandData)
    commandData = commandData or {}
    
    -- Détection automatique de l'extension via le chemin du fichier appelant
    local source = debug.getinfo(2, "S").source
    -- Cherche le dossier après "extensions/" dans le chemin
    local extensionName = source:match("extensions[/\\]([^/\\]+)")
    
    commandData.extension = extensionName or "nickel"
    
    NickelCommands[name] = commandData
    
    return commandData 
end
--- init commands
function CommandsManager.init()
    local commandCount = Utils.tableLength(NickelCommands)
    Utils.nkprint("[CommandsHandler] Initializing with " .. tostring(commandCount) .. " registered commands", "info")

    -- Single connection for all command registration + cleanup
    DatabaseManager:withConnection(function()
        for commandName, commandData in pairs(NickelCommands) do
            local command = Command.new(commandName)
            DatabaseManager:save(command)
            
            commandData.description = MessagesManager:GetMessage(-2, "commands." .. commandName .. ".description") or "No description"
        end

        -- Remove commands not present in memory from the database
        local commandsFromDB = DatabaseManager:getAllEntry(Command)
        for _, command in pairs(commandsFromDB) do
            if not NickelCommands[command.commandName] then
                local conditions = {
                    {"commandName", command.commandName},
                }
                DatabaseManager:deleteObject(Command, conditions)
                Utils.nkprint("[CommandsHandler] Removed obsolete command from database: " .. command.commandName, "warn")
            end
        end
    end)
end


function CommandsManager:GetCommands()
    return Utils.shallowCopy(NickelCommands)
end




function CommandsManager:CreateCommand(sender_id, message, allowSpaceOnLastArg)
    --if callback function exist
    local prefix = ConfigManager.GetSetting("commands").prefix

    if string.sub(message, 1, string.len(prefix)) ~= prefix then
        return
    end

    local command = string.match(message, "%S+"):lower()
    local commandWithoutPrefix = string.sub(command, 2)

    local commandObject = NickelCommands[commandWithoutPrefix]

    if commandObject == nil then
        MessagesManager:SendMessage(sender_id, "commands.not_found", {Command = commandWithoutPrefix})
        return
    end

    local callback = commandObject.init
    local prefixcommand = ConfigManager.GetSetting("commands").prefix .. command
 
    --command test to check if the command is equal to the prefixcommand (the command is the first word of the string)

    --get arguments in message without the command
    local args = {}
    local argstring = string.sub(message, #prefixcommand+1)

    --get number of args of callback function
    local info = debug.getinfo(callback, "u")
    local numParams = info.nparams
    local numCommandArgs = math.max(numParams - 2, 0)  -- Changed from -3 to -2 since we removed CommandsManager parameter
    local i = 0
    --allow space on last argument
    if allowSpaceOnLastArg and numCommandArgs > 0 then -- That logic was rewritten by an AI and hardly tested by me.

        argstring = argstring:gsub("^%s*", "")  

 
        for i = 1, numCommandArgs - 1 do
            local arg, remaining = argstring:match("^(%S+)%s*(.*)")
            if not arg then break end
            args[i] = arg
            argstring = remaining:gsub("^%s*", "")
        end


        args[numCommandArgs] = argstring:match("^%s*(.-)%s*$") or ""
    else

        for arg in string.gmatch(argstring, "%S+") do
            table.insert(args, arg)
        end
    end

    local access = false
    local playername = MP.GetPlayerName(sender_id)
    if sender_id == -2 then
        playername = "console"
        access = true
    end
    local beammpid
    if sender_id ~= nil then
        if sender_id ~= -2 then
            beammpid = Utils.getPlayerBeamMPID(playername)
        else
            beammpid = -2
        end
    end



    if access or User.getOrCreate(beammpid, playername):hasPermission(commandWithoutPrefix) then
        local bool = callback(sender_id, playername, table.unpack(args))
        if sender_id == -2 then
            local resultMessage = bool and "successfully" or "failed to"
            return "Nickel command '" .. command .. "' " .. resultMessage .. " run"
        else
            return 1
        end
    else
        MessagesManager:SendMessage(sender_id, "commands.permissions.insufficient")
        return
    end
    
end