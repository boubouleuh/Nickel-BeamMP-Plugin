
local new = require("objects.New")
local Command = require("objects.Command")

local utils = require("utils.misc")

CommandsHandler = {}


function CommandsHandler.init(msgManager)
    local self = {}
    self.msgManager = msgManager
    self.dbManager = msgManager.dbManager
    self.configManager = msgManager.configManager
    self.commands = {}
    local files = FS.ListFiles(utils.script_path() .. "main/commands/all")

    local function checkCommands()
        local commands = self.dbManager:getAllEntry(Command)


        if next(self.commands) ~= nil then
        
            for key, _ in pairs(self.commands) do
                if not utils.element_exist_in_table(key, commands[1]) then
                    self.dbManager:deleteObject(Command, "commandName", key)
                end
            end
        else
            for _, command in pairs(commands) do
                self.dbManager:deleteObject(Command, "commandName", command.commandName)
            end

        end
    end

    local function addCommand(commandName)

        local command = Command.new(commandName)
        self.dbManager:save(command)
        self.commands[commandName] = require("main.commands.all." .. commandName)
    end


    for _, file in pairs(files) do
        local string = string.gsub(file, ".lua", "")
        addCommand(string)
    end

    checkCommands()

    return new._object(CommandsHandler, self)
end







function CommandsHandler:CreateCommand(sender_id, message, allowSpaceOnLastArg, msgManager)
    --if callback function exist

    if not string.sub(message, 1, string.len("/")) == "/" then
        return
    end

    local command = string.match(message, "%S+")
    local commandWithoutPrefix = string.sub(command, 2)

    local callback = self.commands[commandWithoutPrefix].init


    if callback == nil then
        return  "Command " .. command .. " not found"
    end


    local prefixcommand = self.configManager.config.commands.prefix .. command
 
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
        table.insert(args, msgManager)
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

    return callback(sender_id, table.unpack(args)) -- for test, need permissions check
end



return CommandsHandler