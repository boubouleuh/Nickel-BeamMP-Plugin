
local new = require("objects.New")
local Command = require("objects.Command")

local utils = require("utils.misc")
---@class CommandsHandler
CommandsHandler = {}

--- init commands
---@param managers managers
function CommandsHandler.init(managers)
    local self = {}

    ---@type MessagesHandler
    self.msgManager = managers.msgManager
    ---@type DatabaseManager
    self.dbManager = managers.dbManager
    ---@type Settings
    self.cfgManager = managers.cfgManager
    ---@type PermissionsHandler
    self.permManager = managers.permManager
    self.commands = {}
    local inbuildCommands = FS.ListFiles(utils.script_path() .. "main/commands/all")
    local extensionsCommands = {}
    local extensionsFolders = FS.ListDirectories(utils.script_path() .. "extensions")

    for _, extensionFolder in pairs(extensionsFolders) do
        local commandsPath = utils.script_path() .. "extensions/" .. extensionFolder .. "/commands"
        if FS.Exists(commandsPath) then
            local commands = FS.ListFiles(commandsPath)
            for _, command in pairs(commands) do
                table.insert(extensionsCommands, {command = command, extension = extensionFolder})
            end
        end
    end



    local function checkCommands()  --WATCH THIS IF COMMAND ARE NOT HANDLED CORRECTLY
        self.dbManager:withConnection(function()
            local commandsFromDB = self.dbManager:getAllEntry(Command)

            -- Remove commands not present in memory from the database
            for _, command in pairs(commandsFromDB) do
                if not self.commands[command.commandName] then
                    local conditions = {
                        {"commandName", command.commandName},
                    }

                    self.dbManager:deleteObject(Command, conditions)
                end
            end
        end)
    end



    local function addCommand(commandName, extensionName)
        local command = Command.new(commandName)
        self.dbManager:save(command)
    
        local success, module
    
        -- Vérifie si c'est une commande intégrée
        success, module = pcall(require, "main.commands.all." .. commandName)
        if success then
            self.commands[commandName] = module
            self.commands[commandName].extension = 'nickel'
        else
            -- Sinon, tente de charger depuis une extension
            success, module = pcall(require, "extensions." .. extensionName .. ".commands." .. commandName)
            if success then
                self.commands[commandName] = module
                self.commands[commandName].extension = extensionName
            else
                utils.nkprint("Failed to load command: " .. commandName, "error")
                return
            end
        end
    
        self.commands[commandName].description = self.msgManager:GetMessage(-2, "commands." .. commandName .. ".description") or ""
    end

    for _, file in pairs(inbuildCommands) do
        local commandName = string.gsub(file, ".lua", "")
        addCommand(commandName, nil) -- Pas d'extensionName pour les commandes intégrées
    end
    
    for _, commandData in pairs(extensionsCommands) do
        local commandName = string.gsub(commandData.command, ".lua", "")
        addCommand(commandName, commandData.extension)
    end


    checkCommands()

    return new._object(CommandsHandler, self)
end


function CommandsHandler:GetCommands()
    return utils.shallowCopy(self.commands)
end




function CommandsHandler:CreateCommand(sender_id, message, allowSpaceOnLastArg)
    --if callback function exist

    local prefix = self.cfgManager.config.commands.prefix


    if string.sub(message, 1, string.len(prefix)) ~= prefix then
        return
    end

    local command = string.match(message, "%S+")
    local commandWithoutPrefix = string.sub(command, 2)



    local commandObject = self.commands[commandWithoutPrefix]

    if commandObject == nil then
        self.msgManager:SendMessage(sender_id, "commands.not_found", {Command = commandWithoutPrefix})
        return
    end

    local callback = commandObject.init

    local prefixcommand = self.cfgManager.config.commands.prefix .. command
 
    --command test to check if the command is equal to the prefixcommand (the command is the first word of the string)

    --get arguments in message without the command
    local args = {}
    local argstring = string.sub(message, #prefixcommand+1)

    --get number of args of callback function
    local info = debug.getinfo(callback, "u")
    local numParams = info.nparams
    local numCommandArgs = math.max(numParams - 3, 0)
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


    local playername = MP.GetPlayerName(sender_id)
    if sender_id == -2 then
        playername = "console"
    end
    local beammpid
    if sender_id ~= nil then
        if sender_id ~= -2 then
            beammpid = utils.getPlayerBeamMPID(playername)
        else
            beammpid = -2
        end
    end


    if self.permManager:hasPermission(beammpid, commandWithoutPrefix) then
        local bool = callback(sender_id, playername, self, table.unpack(args))
        if sender_id == -2 then
            local resultMessage = bool and "successfully" or "failed to"
            return "Nickel command '" .. command .. "' " .. resultMessage .. " run"
        else
            return 1
        end
    else
        self.msgManager:SendMessage(sender_id, "commands.permissions.insufficient")
        return 1
    end
    
end



return CommandsHandler