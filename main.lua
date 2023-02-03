
CONFIG = {
    PREFIX = ";",
    NOGUEST = "true",
    NOGUESTMSG = "Guest are forbidden, please create a beammp account :)",
    WELCOMESTAFF = "Welcome Staff",
    WELCOMEPLAYER = "Welcome",
    AUTOUPDATE = "false"
}
function script_path()
    return debug.getinfo(2, "S").source:match("(.*[/\\])") or "./"
end

function file_exists(name)
    local f = io.open(name, "r")
    return f ~= nil and io.close(f)
 end

COMMANDLIST = {}
VERSIONPATH = script_path() .. "version.txt"
CONFIGPATH = script_path() .. "NickelConfig.toml"
VERSION = "1.2.3"



function onInit()

--make version txt if not exist
    if not file_exists(VERSIONPATH) then
        local file = io.open(VERSIONPATH, "w")
        file:write("--" .. VERSION) -- two (-) to not trigger an error with beammp
        file:close()
    end


--check if old config.toml exist to move it

    if not file_exists("config.toml") then
        if not file_exists(CONFIGPATH) then
            local file = io.open(CONFIGPATH, "w")

            for key, value in pairs(CONFIG) do
                file:write(key .. " = " .. '"' .. value .. '"' .. "\n")
            end
            file:close()
        else
            --check if file contains the same keys as config array
            local file = io.open(CONFIGPATH, "r")
            local content = file:read("*all")
            file:close()

            --loop in config array
            for key, value in pairs(CONFIG) do
                --check if key is not in file
                if not string.match(content, key) then
                    --add key to file
                    file = io.open(CONFIGPATH, "a")
                    file:write(key .. " = " .. '"' .. value .. '"' .. "\n")
                    file:close()
                end
            end
        end
    else
        local oldfile = io.open("config.toml", "r")
        local oldcontent = oldfile:read("*all")
        oldfile:close()
        --write newfile
        local newfile = io.open(CONFIGPATH, "w")
        --add newline on the end of the content
        oldcontent = oldcontent .. "\n"
        --remove newline at the end of the value and add "" on the value and add the newline after this
        oldcontent = string.gsub(oldcontent, "(.-)%s*=%s*(.-)%s*\n", "%1 = \"%2\"\n")
  
        newfile:write(oldcontent)
        newfile:close()
        --delete old file

        local os = MP.GetOSName()
        if os == "Windows" then
            local exec = io.popen("del config.toml")
            if exec then
                print("config.toml moved to " .. CONFIGPATH)
            else
                print("failed to delete old config file ")
            end
        else
            local error, error_message = FS.Remove("config.toml")
            if error then
                print("failed to delete old config file " .. error_message)
            else
                print("config.toml moved to " .. CONFIGPATH)
            end
        end

        
        --loop in config array
        for key, value in pairs(CONFIG) do
            --check if key is not in file
            if not string.match(oldcontent, key) then
                --add key to file
                file = io.open(CONFIGPATH, "a")
                file:write(key .. " = " .. '"' .. value .. '"' .. "\n")
                file:close()
            end
        end
    end


    --open ban file then loop in bans line
    if not file_exists("bans.txt") then
        local file = io.open("bans.txt", "w")
        file:close()
    end    
    local file = io.open("bans.txt", "r")
    local content = file:read("*all")
    file:close()

    --loop in lines
    for line in content:gmatch("[^\r\n]+") do
        --check if line is not empty
        if line ~= "" then
            --if line have beammp id after name
            if string.match(line, "%s") then
                print(line .. " ban line good")
            else
                --delete line
                print(line .. " ban line bad, deleting line (please reban the player with the command)")
                content = string.gsub(content, line .. "\n", "")
                --write new content to file
                file = io.open("bans.txt", "w")
                file:write(content)
                file:close()
            end
        end
    end

    --prefix and guest
    PREFIX = getConfigValue("PREFIX")

    --check files
    --array with all file name
    local files = {"staff.txt", "bans.txt", "banips.txt"}
    
    --loop in files
    for key, value in pairs(files) do
        checkFileEndWithNewLine(value)
    end


    MP.SendChatMessage(-1, "^l^7 Nickel |^r^o plugin loaded successfully")

end


--function getConfigValue
function getConfigValue(config_name)
    local file = io.open(CONFIGPATH, "r")
    local content = file:read("*all")
    file:close()

    --string match for value like : VARIABLE = "value" (work for every variable and value)

    return string.match(content, config_name .. "%s*=%s*\"(.-)\"%s*\n")
    
end

--function editConfigValue
function editConfigValue(config_name, new_value)
    local file = io.open(CONFIGPATH, "r")
    local content = file:read("*all")
    file:close()

    --string match for value like : VARIABLE = value (work for every variable and value)

    local value = string.match(content, config_name .. "%s*=%s*(.-)%s*\n")
    
    --check if value is not nil
    if value ~= nil then
        --replace value
        content = string.gsub(content, config_name .. "%s*=%s*(.-)%s*\n", config_name .. " = " .. new_value .. "\n")
        --write new content to file
        file = io.open(CONFIGPATH, "w")
        file:write(content)
        file:close()
    end
end


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

--getPlayerBeamMPID with GetPlayerIdentifiers
function getPlayerBeamMPID(player_id)
    local identifiers = MP.GetPlayerIdentifiers(player_id)
    if identifiers == nil then
        return -1
    end
    local player_beammp_id = identifiers['beammp']
    return player_beammp_id
end


function checkFileEndWithNewLine(file_name)


    --check if file exists
    if not file_exists(file_name) then
        local file = io.open(file_name, "w")
        file:close()
        print(file_name .. " created")
        return
    end
    
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
            MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Please enter a parameter")
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
    -- check if parameter is already in staffs
    local player_target = GetPlayerId(parameter)
    local is_in_staffs = false
    local file = io.open("staff.txt", "r")
    for line in file:lines() do
        local staff_name, beammp_id = string.match(line, "(%S+)%s+(%S+)")
        if staff_name == parameter then
            is_in_staffs = true
            break
        end
    end
    file:close()
    -- if not in staffs, add it
    if not is_in_staffs then
        local beammp_id = getPlayerBeamMPID(player_target)
        checkFileEndWithNewLine("staff.txt")
        --write staff to file
        local file = io.open("staff.txt", "a+")
        file:write(parameter .. " " .. beammp_id .. "\n")
        file:close()
        MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Staff " .. parameter .. " added")
        MP.SendChatMessage(player_target, "^l^7 Nickel |^r^o You are now a staff")
    else
        MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Staff " .. parameter .. " already in staffs")
    end
end

--removeStaff function
function removeStaff(sender_id, parameter)
    -- check if parameter is in staffs
    local is_in_staffs = false
    local file = io.open("staff.txt", "r")
    for line in file:lines() do
        local staff_name, beammp_id = string.match(line, "(%S+)%s+(%S+)")
        if staff_name == parameter then
            is_in_staffs = true
            break
        end
    end
    file:close()
    -- if in staffs, remove it
    if is_in_staffs then
        local file = io.open("staff.txt", "r")
        local content = file:read("*all")
        file:close()
        content = string.gsub(content, parameter .. "%s+%S+%s*\n", "")
        file = io.open("staff.txt", "w")
        file:write(content)
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
    local player_beammp_id = getPlayerBeamMPID(player_id)
    -- check if player is online
    if player_id ~= -1 then
        local file = io.open("bans.txt", "a+")

        --check if parameter exist in file
        local is_in_bans = false
        for line in file:lines() do

            --if line start with parameter
            if string.match(line, parameter) then
                is_in_bans = true
                break
            end
        end
        if is_in_bans == false then
            checkFileEndWithNewLine("bans.txt")
            file:write(parameter .. " " .. player_beammp_id .. "\n")
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

--noguest command, parameter can be true or false
function noguest(sender_id, parameter)
    -- check if parameter is true or false
    local actual_noguest = getConfigValue("NOGUEST")
    if parameter == "true" then
        if actual_noguest == "true" then
            MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o No guest mode already activated")
        else
            -- set noguest to true
            editConfigValue("NOGUEST", "true")
            MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o No guest mode activated")
        end
    elseif parameter == "false" then
        if actual_noguest == "false" then
            MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o No guest mode already deactivated")
        else
            -- set noguest to false
            editConfigValue("NOGUEST", "false")
            MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o No guest mode deactivated")
        end
        
    else
        MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Invalid parameter. Valid parameter : true or false")
    end
end


function handleConsoleInput(cmd)

    if cmd == "addstaff" or cmd == "addstaff " then
        return "Usage : addstaff <player_name>"
    end
    local delim = cmd:find(' ')
    if delim then
        local message = cmd:sub(delim+1)
        if cmd:sub(1, delim-1) == "addstaff" then
            -- check if parameter is not already in staffs
            local is_in_staffs = false
            for key, value in pairs(STAFFS) do
                if value == message then
                    is_in_staffs = true
                    break
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
                break
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











function unban(sender_id, parameter)
    local fileRead = io.open("bans.txt", "r")
    lines = {}
    is_banned = false
    for line in fileRead:lines() do
        --if line start with parameter
        if string.match(line, parameter) then
            is_banned = true
        else
            lines[#lines + 1] = line
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
end

--unbanip command
function unbanip(sender_id, parameter)
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

end

--countdown
function countdown(sender_id)
    local time = 5

    MP.SendChatMessage(-1, "^l^7 Nickel |^r^o Countdown started")
    for i = time, 1, -1 do
        MP.SendChatMessage(-1, "^l^7 Nickel |^r^o " .. i)
        MP.Sleep(1000)
    end
    MP.SendChatMessage(-1, "^l^7 Nickel |^r^o GOOO !")
end

function checkForUpdates()
    if getConfigValue("AUTOUPDATE") == "true" then
        local function httpRequest(url)
            --check os
            if MP.GetOSName() == "Windows" then
                local response = io.popen("curl -s " .. url .. " --output temp.txt", "r")
                response:close()
                if response then
                    local file = io.open("temp.txt", "r")
                    local content = file:read("*all")
                    file:close()
                    os.remove("temp.txt")
                    return content
                else
                    return ""
                end
            else
                --dont use curl
                local response = io.popen("wget -q -O temp.txt " .. url, "r")
                response:close()
                if response then
                    local file = io.open("temp.txt", "r")
                    local content = file:read("*all")
                    file:close()
                    os.remove("temp.txt")
                    return content
                else
                    return ""
                end
            end
        end
        
        -- Récupérer la version actuelle de votre script local à partir de version.txt
        local oldversion = io.open(VERSIONPATH, "r")
        local localVersion = oldversion:read()


        --retire les deux premier caractères de localVersion (--)
        localVersion = string.sub(localVersion, 3)

        oldversion:close()
        

        --this go to this https://api.github.com/repos/boubouleuh/Nickel-BeamMP-Plugin/releases/latest

        local response = httpRequest("https://nickel.martadash.fr/version.txt")

        if response == "" then
            print("Get remote version failed to check update !")
            return
        end
        -- Récupérer la version distante à partir de la réponse

        local remoteVersion = response:match('"tag_name": "([^"]+)"')

        if remoteVersion == nil then
            print("Get remote version failed to check update ! Try again later ! (if this message show up every time, disable auto update in config)")
            return
        end
 
        -- Comparer les versions locales et distantes
        if remoteVersion > localVersion then
            print(localVersion, remoteVersion)
            -- Effectuer la mise à jour
            print("Update available !")
            local url = "https://raw.githubusercontent.com/boubouleuh/Nickel-BeamMP-Plugin/" .. remoteVersion .. "/main.lua"
            -- Télécharger la dernière version de votre script depuis GitHub
            local response = httpRequest(url)
            print(url)
            --if download fail 
            if response == nil then
                print("Update failed !")
                return
            else
                print("Update downloaded !")
            end
            -- Écrire la réponse dans un fichier pour mettre à jour votre script
            local main = io.open(script_path() .. "main.lua", "w")
            main:write(response)
            main:close()
            
            -- Mettre à jour la version locale dans version.txt
            local newversion = io.open(VERSIONPATH, "w")
            newversion:write("--" .. remoteVersion)
            newversion:close()

            print("Update done !")
        end

    end
end



function CountSeconds()

    local file = io.open("staff.txt", "r")
    lines = {}
    local modif = false
    --check if line contain a staff and if yes check if there is the beammp id after the name and if not append the beammp id
    for line in file:lines() do
        --get first word of line
        local staff = string.match(line, "%S+")
        local staff_id = GetPlayerId(staff)
        if staff_id ~= -1 then
            local staff_beammp_id = getPlayerBeamMPID(staff_id)
            if string.find(line, staff_beammp_id) == nil then
                line = staff .. " " .. staff_beammp_id
                modif = true
            end
        end
        lines[#lines + 1] = line
    end
    file:close()
    if modif == true then
        local fileWrite = io.open("staff.txt", "w")
        for _, line in pairs(lines) do
            fileWrite:write(line .. "\n")
        end
        fileWrite:close()
    end

    -- global value staff
    local file = io.open("staff.txt", "r")
    STAFFS = {}
    -- append every line to staffs 
    for line in file:lines() do
        --get first word of line
        local staff = string.match(line, "%S+")
        table.insert(STAFFS, staff)
    end
    file:close()
end


function onPlayerJoin(player_id)
    -- check if player is staff
    local WELCOMESTAFF = getConfigValue("WELCOMESTAFF")
    local WELCOMEPLAYER = getConfigValue("WELCOMEPLAYER")
    local player_name = MP.GetPlayerName(player_id)
    local is_staff = false
    for key, value in pairs(STAFFS) do
        if value == player_name then
            -- send message to player
            is_staff = true
            break
        end
    end
    if is_staff then
        MP.SendChatMessage(-1, "^l^7 Nickel |^r^o  " .. WELCOMESTAFF .. " " .. player_name)
    else
        MP.SendChatMessage(-1, "^l^7 Nickel |^r^o " .. WELCOMEPLAYER .. " " .. player_name)
    end

end

function onPlayerAuth(name, role, isGuest)

    local noguest = getConfigValue("NOGUEST")
    local noguestmsg = getConfigValue("NOGUESTMSG")
    if noguest == "true" then
        if isGuest then
            return noguestmsg
        end
    end


end

function onPlayerConnecting(player_id)
    local ipban = io.open("banips.txt", "r")
    --get ip of player
    local player_identifiers = MP.GetPlayerIdentifiers(player_id)
    local player_ip = player_identifiers['ip']

    if ipban:read("*a"):find(player_ip) then
        MP.DropPlayer(player_id, "You are ip banned from this server")
    end
    ipban:close()

    local normalban = io.open("bans.txt", "r")
    local player_beammpid = getPlayerBeamMPID(player_id)
    if normalban:read("*a"):find(player_beammpid) then
        MP.DropPlayer(player_id, "You are banned from this server")
    end
    normalban:close()
end

function MyChatMessageHandler(sender_id, sender_name, message)

    --if message start with PREFIX
    if string.sub(message, 1, string.len(PREFIX)) == PREFIX then
        is_staff = false
        for key, value in pairs(STAFFS) do
            if value == sender_name then
                is_staff = true
                break
            end
        end
        --get the first word of message
        local command = string.match(message, "%S+")
        if is_staff then


            CreateCommandWithParameter(sender_id, message, "removestaff", removeStaff)
            CreateCommandWithParameter(sender_id, message, "addstaff", addStaff)
            CreateCommandWithoutParameter(sender_id, message, "ip", ip)
            CreateCommandWithParameter(sender_id, message, "kick", kick)
            CreateCommandWithParameter(sender_id, message, "ban", ban)
            CreateCommandWithParameter(sender_id, message, "banip", banip)
            CreateCommandWithParameter(sender_id, message, "unban", unban)
            CreateCommandWithParameter(sender_id, message, "unbanip", unbanip)
            CreateCommandWithParameter(sender_id, message, "noguest", noguest)
            CreateCommandWithoutParameter(sender_id, message, "countdown", countdown)

            CreateCommandWithoutParameter(sender_id, message, "help", help)
            if COMMANDLIST[command] == nil then
                MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Command not found")
            end
            COMMANDLIST = {}
            return -1
        else
            CreateCommandWithoutParameter(sender_id, message, "countdown", countdown)

            CreateCommandWithoutParameter(sender_id, message, "help", help)
            if COMMANDLIST[command] == nil then
                MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Command not found")
            end
            COMMANDLIST = {}
            return -1
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


MP.RegisterEvent("CheckUpdate", "checkForUpdates")
MP.CreateEventTimer("CheckUpdate", 60000)
