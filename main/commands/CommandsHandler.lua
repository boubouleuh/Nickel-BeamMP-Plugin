

CommandsHandler = {}


function CommandsHandler.CreateCommand(sender_id, message, command, allowSpaceOnLastArg, callback)
    --if callback function exist
    if callback == nil then
        return  "Command " .. command .. " not found"
    end


    local prefixcommand = PREFIX .. command
    local sender_name = nil
    if sender_id ~= "console" then
        sender_name = MP.GetPlayerName(sender_id)
    else
        sender_name = "console"
    end
    --command test to check if the command is equal to the prefixcommand (the command is the first word of the string)

    local commandtest = string.match(message, "%S+")
    --get arguments in message without the command
    local args = {}
    local argstring = string.sub(message, #prefixcommand+1)
    -- check if message is command 
    if commandtest and commandtest == prefixcommand then
        nkprint(sender_name .. " issued command : " .. prefixcommand)
        
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
        if sender_id ~= "console" then
            if HasPermission(sender_id, command) then
                callback(sender_id, table.unpack(args))
            else
                MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o You don't have permission to use this command")
            end
        else
            return callback(sender_id, table.unpack(args))
        end
    else
        return nil
    end
end



return CommandsHandler