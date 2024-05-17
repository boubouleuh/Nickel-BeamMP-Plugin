
local new = require("objects.New")
local Command = require("objects.Command")

local utils = require("utils.misc")

CommandsHandler = {}


function CommandsHandler.init(managers)
    local self = {}
    self.msgManager = managers.msgManager
    self.dbManager = managers.dbManager
    self.cfgManager = managers.cfgManager
    self.permManager = managers.permManager
    self.commands = {}
    local inbuildCommands = FS.ListFiles(utils.script_path() .. "main/commands/all")
    local extensionsCommands =  FS.ListFiles(utils.script_path() .. "extensions/commands")

    local files = utils.mergeTables(inbuildCommands, extensionsCommands)


    local function checkCommands()  --WATCH THIS IF COMMAND ARE NOT HANDLED CORRECTLY
        self.dbManager:openConnection()

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


        self.dbManager:closeConnection()
    end



    local function addCommand(commandName)

        local command = Command.new(commandName)
        self.dbManager:save(command)

        local success, module = pcall(require, "main.commands.all." .. commandName)
            --if it exist then its a inbuilt command
        if success then
            self.commands[commandName] = module
        else
            self.commands[commandName] = require("extensions.commands." .. commandName)
        end --if not then its an extension command

       
    end


    for _, file in pairs(files) do
        local string = string.gsub(file, ".lua", "")
        addCommand(string)
    end

    checkCommands()

    return new._object(CommandsHandler, self)
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
        self.msgManager:SendMessage(sender_id, "commands.not_found", commandWithoutPrefix)
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
    local numParams = info.nparams - 1 -- -1 because the first argument is the sender_id
    
    local i = 0
    --allow space on last argument
    if allowSpaceOnLastArg then
        for arg in string.gmatch(argstring, "%S+") do

            if i == numParams then
                --insert arg with the last one if there is space
                --if args not empty

                if #args > 0 then
                    table.insert(args, i, args[i] .. " " .. arg)
                else
                    table.insert(args, arg)
                end
                
            else
                table.insert(args, arg)
            end
            if i ~= numParams then
                i = i + 1
            end
        end

    else
        for arg in string.gmatch(argstring, "%S+") do
            table.insert(args, arg)
        end
    end
        
    -- appel du callback avec les arguments


    -- if sender_id ~= "console" then
    --     if HasPermission(sender_id, command) then
    --         callback(sender_id, table.unpack(args))
    --     else
    --         msgManager:sendMessage(sender_id, "commands.permissions.insufficient") 
    --     end
    -- else
    --     return callback(sender_id, table.unpack(args))
    -- end

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
        local bool = callback(sender_id, playername, self, table.unpack(args)) -- TODO WAY TO PREVENT TWO USER WITH THE SAME HIERARCHY TO MANAGE EACH OTHER
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