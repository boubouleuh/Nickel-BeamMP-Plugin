
PREFIX = ";"
COMMANDLIST = {}


-- GetPlayerId function
function GetPlayerId(player_name)
    local players = MP.GetPlayers()
    for key, value in pairs(players) do
        if value == player_name then
            return key
        end
    end
    return -1
end


function checkFileEndWithNewLine(file_name)
    local file = io.open(file_name, "r")
    local content = file:read("*all")

    --check if file is empty
    if content == "" then
        file:close()
        print(file_name .. " is empty")
        return
    end
    file:close()
    
    local modified = false
    if content:sub(-1) ~= "\n" then
        content = content .. "\n"
        modified = true
    end
    
    if modified then
        file = io.open(file_name, "w")
        file:write(content)
        file:close()
        print("Modified " .. file_name .. " and added newline character at the end of each line.")
    else
        print(file_name .. " is already formatted correctly.")
    end
end



-- function to create command with parameter (using chatmessage handler and message value)
function CreateCommandWithParameter(sender_id, message, command, callback)
        
        command = PREFIX .. command


    
        if COMMANDLIST[command] == nil then
            COMMANDLIST[command] = command
        end
        if string.match(message, command .. "$") then
            MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Please enter a name")
            return
        end
            if string.match(message, command .. "%s") then
                -- get parameter
                local parameter = string.sub(message, string.len(command) + 2)
                -- check if parameter is not empty
                -- call callback with parameter
                callback(sender_id, parameter)
            end

end

--function to create command without parameter
function CreateCommandWithoutParameter(sender_id, message, command, callback)

    command = PREFIX .. command
    -- check if message is command
    if message == command then
        -- call callback
        callback(sender_id)
    end

    if COMMANDLIST[command] == nil then
        COMMANDLIST[command] = command
    end

   
end

--ip
function ip(sender_id)
    -- create list
    local players = MP.GetPlayers()
    -- loop in players and add their name to the list
    for key, value in pairs(players) do
        local player_name = value
        local player_identifiers = MP.GetPlayerIdentifiers(key)
        local player_ip = player_identifiers['ip']
        MP.SendChatMessage(sender_id,"^l^7 Nickel |^r^o " .. player_name .. " - " .. player_ip)
    end
end


--addStaff
function addStaff(sender_id, parameter)
    -- check if parameter is not already in staffs
    local is_in_staffs = false
    for key, value in pairs(STAFFS) do
        if value == parameter then
            is_in_staffs = true
        end
    end
    -- if not in staffs, add it
    if is_in_staffs == false then
        checkFileEndWithNewLine("staff.txt")
        --write staff to file
        local file = io.open("staff.txt", "a+")
        file:write(parameter .. "\n")
        file:close()
        MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Staff " .. parameter .. " added")
    else
        MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Staff " .. parameter .. " already in staffs")
    end
end



--removeStaff
function removeStaff(sender_id, parameter)
    -- check if parameter is in staffs
    local is_in_staffs = false
    for key, value in pairs(STAFFS) do
        if value == parameter then
            is_in_staffs = true
        end
    end
    -- if in staffs, remove it
    if is_in_staffs == true then
        checkFileEndWithNewLine("staff.txt")
        --write staff to file
        local file = io.open("staff.txt", "w")
        for key, value in pairs(STAFFS) do
            if value ~= parameter then
                file:write(value .. "\n")
            end
        end
        file:close()
        MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Staff " .. parameter .. " removed")
    else
        MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Staff " .. parameter .. " not in staffs")
    end
end

--help
function help(sender_id)
    MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Commands list :")
    for key, value in pairs(COMMANDLIST) do
        if value ~= ";help" then
            MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o >> " .. value)
        end
    end
end


-- kick command
function kick(sender_id, parameter)
    -- get player id
    local player_id = GetPlayerId(parameter)
    -- check if player is online
    if player_id ~= -1 then
        -- kick player
        MP.DropPlayer(player_id, "Kicked by ".. MP.GetPlayerName(sender_id))
        MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. parameter .. " kicked")
    else
        MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. parameter .. " not found")
    end
end 

--ban command
function ban(sender_id, parameter)
    -- get player id
    local player_id = GetPlayerId(parameter)
    -- check if player is online
    if player_id ~= -1 then
        local file = io.open("bans.txt", "a+")

        --check if parameter exist in file
        local is_in_bans = false
        for line in file:lines() do
            if line == parameter then
                is_in_bans = true
            end
        end
        if is_in_bans == false then
            checkFileEndWithNewLine("bans.txt")
            file:write(parameter .. "\n")
            file:close()
            -- ban player
            MP.DropPlayer(player_id, "Banned by ".. MP.GetPlayerName(sender_id))
            
            MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. parameter .. " banned")
        else
            MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. parameter .. " already banned")
        end

    else
        MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. parameter .. " not found")
    end

end

function onInit()
    --array with all file name
    local files = {"staff.txt", "bans.txt", "banips.txt"}
    
    --loop in files
    for key, value in pairs(files) do
        checkFileEndWithNewLine(value)
    end


    MP.SendChatMessage(-1, "^l^7 Nickel |^r^o plugin loaded successfully")

end
function handleConsoleInput(cmd)
    local delim = cmd:find(' ')
    if delim then
        local message = cmd:sub(delim+1)
        if cmd:sub(1, delim-1) == "addstaff" then
            -- check if parameter is not already in staffs
            local is_in_staffs = false
            for key, value in pairs(STAFFS) do
                if value == message then
                    is_in_staffs = true
                end
            end
            -- if not in staffs, add it
            if is_in_staffs == false then
                --write staff to file
                local file = io.open("staff.txt", "a+")
                file:write(message .. "\n")
                file:close()
                return "Staff " .. message .. " added"
            else
                return "Staff " .. message .. " already in staffs"
            end
                
        end
    else
        return "Please insert a name after this command"

    end
end



--banip command with banips.txt
function banip(sender_id, parameter)

    -- get player id
    local player_id = GetPlayerId(parameter)
    -- check if player is online
    if player_id ~= -1 then

        --get ip of player
        local player_identifiers = MP.GetPlayerIdentifiers(player_id)
        local player_ip = player_identifiers['ip']
        local file = io.open("banips.txt", "a+")

        --check if parameter exist in file
        local is_in_bans = false
        for line in file:lines() do
            if line == parameter then
                is_in_bans = true
            end
        end
        if is_in_bans == false then
            checkFileEndWithNewLine("banips.txt")
            file:write(player_ip .. "\n")
            file:close()
            -- ban player
            MP.DropPlayer(player_id, "Banned by ".. MP.GetPlayerName(sender_id))
            
            MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. parameter .. " ip banned")
        else
            MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. parameter .. " already ip banned")
        end

    else
        MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. parameter .. " not found")
    end
end

--unban command
function unban(sender_id, parameter)
    -- get player id
    local player_id = GetPlayerId(parameter)
    -- check if player is online
    if player_id ~= -1 then
        local fileRead = io.open("bans.txt", "r")
        lines = {}
        is_banned = false
        for line in fileRead:lines() do
            if line ~= parameter then
                lines[#lines + 1] = line
            else
                is_banned = true
            end
        end
        fileRead:close()
        if is_banned == false then
            MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. parameter .. " not banned")
            return
        end
        local fileWrite = io.open("bans.txt", "w")
        for i, line in ipairs(lines) do
            fileWrite:write(line .. "\n")
        end
            MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. parameter .. " unbanned")
            fileWrite:close()
            return 
        
    else
        MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. parameter .. " not found")
    end

end

--unbanip command
function unbanip(sender_id, parameter)
    -- check if player is online
    local fileRead = io.open("banips.txt", "r")
    lines = {}
    is_banned = false
    for line in fileRead:lines() do
        if line ~= parameter then
            lines[#lines + 1] = line
        else
            is_banned = true
        end
    end
    fileRead:close()
    if is_banned == false then
        MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Ip " .. parameter .. " not banned")
        return
    end
    local fileWrite = io.open("banips.txt", "w")
    for i, line in ipairs(lines) do
        fileWrite:write(line .. "\n")
    end
        MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Ip " .. parameter .. " unbanned")
        fileWrite:close()
        return 

end

function CountSeconds()
    local file = io.open("staff.txt", "a+")

    -- global value staff
    STAFFS = {}
    -- append every line to staffs 
    for line in file:lines() do
        table.insert(STAFFS, line)

    end
end


function onPlayerJoin(player_id, player_name)
    -- check if player is staff


    for key, value in pairs(STAFFS) do
        if value == player_name then
            -- send message to player
            MP.SendChatMessage(player_id, "^l^7 Nickel |^r^o Welcome staff " .. player_name)
        end
    end
end

function onPlayerAuth(name, role)
    local normalban = io.open("bans.txt", "a+")
   
    if normalban:read("*a"):find(name) then
        return "You are banned from this server"
    end
end

function onPlayerConnecting(player_id)
    local ipban = io.open("banips.txt", "a+")
    --get ip of player
    local player_identifiers = MP.GetPlayerIdentifiers(player_id)
    local player_ip = player_identifiers['ip']

    if ipban:read("*a"):find(player_ip) then
        MP.DropPlayer(player_id, "You are ip banned from this server")
    end
end


function MyChatMessageHandler(sender_id, sender_name, message)


        --if message start with PREFIX
        if string.sub(message, 1, string.len(PREFIX)) == PREFIX then

            -- check if sender is staff
            for key, value in pairs(STAFFS) do
                if value == sender_name then
                    
                    --get the first word of message
                    local command = string.match(message, "%S+")
                

                    CreateCommandWithParameter(sender_id, message, "removestaff", removeStaff)
                    CreateCommandWithParameter(sender_id, message, "addstaff", addStaff)
                    CreateCommandWithoutParameter(sender_id, message, "ip", ip)
                    CreateCommandWithParameter(sender_id, message, "kick", kick)
                    CreateCommandWithParameter(sender_id, message, "ban", ban)
                    CreateCommandWithParameter(sender_id, message, "banip", banip)
                    CreateCommandWithParameter(sender_id, message, "unban", unban)
                    CreateCommandWithParameter(sender_id, message, "unbanip", unbanip)

                    CreateCommandWithoutParameter(sender_id, message, "help", help)

                    if COMMANDLIST[command] == nil then
                        MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Command not found")
                    end


                    return -1
                end
                --if value equal the last value of STAFFS
                if value == STAFFS[#STAFFS] then
                    MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o You are not staff")
                    return -1
                end
            end
        
        end
end






MP.RegisterEvent("onChatMessage", "MyChatMessageHandler")
MP.RegisterEvent("onPlayerJoin", "onPlayerJoin")
MP.RegisterEvent("onPlayerAuth", "onPlayerAuth")
MP.RegisterEvent("onPlayerConnecting", "onPlayerConnecting")
MP.RegisterEvent("EverySecond", "CountSeconds")
MP.RegisterEvent("onConsoleInput", "handleConsoleInput")


MP.CreateEventTimer("EverySecond", 1000)

