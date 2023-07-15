

--IF YOU NEED HELP OR YOU WANT TO HELP THE NICKEL PROJECT PLEASE COME ON THE DISCORD ! : https://discord.gg/h5P84FFw7B

------------ START OF UTILITY FUNCTIONS ------------

function script_path()
    return debug.getinfo(2, "S").source:match("(.*[/\\])") or "./"
end

function file_exists(name)
    local f = io.open(name, "r")
    return f ~= nil and io.close(f)
 end


------------ START OF CONFIG AND GLOBAL VARIABLE ------------
--!! EDIT THE CONFIG IN THE .TOML FILE, NOT HERE  !!--

CONFIG = {
    PREFIX = ";",
    NOGUEST = "true",
    NOGUESTMSG = "Guest are forbidden, please create a beammp account :)",
    WELCOMESTAFF = "Welcome Staff",
    WELCOMEPLAYER = "Welcome",
    AUTOUPDATE = "true",
    VOTEKICK = "true",
    KEEPINGLOGSDAYS = "3",
    WHITELIST = "false",
    MAXPING = "500",
    PINGTRESHOLD = "20",
    KICKPINGMSG = "Too high ping"
}


VOTEKICKLIST = {}
PERMISSIONPATH = script_path() .. "data/permissions.json"
VERSIONPATH = script_path() .. "version.txt"
USERPATH = script_path() .. "data/users/"
OLDPATH = script_path() .. "data/old/"
CONFIGPATH = script_path() .. "NickelConfig.toml"
LOGSPATH = script_path() .. "data/logs/"
VERSION = "2.0.2"

------------ END OF CONFIG AND GLOBAL VARIABLE ------------

--logs
function log(message)
    local keepinglogsdays = getConfigValue("KEEPINGLOGSDAYS")
    local date = os.date("%d-%m-%Y")
    local empty = true
    
    --date with hours
    local dateHours = os.date("%d-%m-%Y %H:%M:%S")
    
    --check if log folder exists, if not create it
    if not file_exists(LOGSPATH) then
        FS.CreateDirectory(LOGSPATH)
    end
    
    -- iterate through files in LOGSPATH
    for key, file in pairs(FS.ListFiles(LOGSPATH)) do
        local dateInfile = file:sub(1, 10)
        
        -- get timestamp for date in file
        local dateTimestampinFile = os.time({year = dateInfile:sub(7, 10), month = dateInfile:sub(4,5), day = dateInfile:sub(1, 2)})
        
        -- check if file is older than keepinglogsdays
        if os.difftime(os.time(), dateTimestampinFile) > tonumber(keepinglogsdays) * 24 * 60 * 60 then
            FS.Remove(LOGSPATH .. file)
        else
            empty = false
            local file = io.open(LOGSPATH .. file, "a+")
            file:write(dateHours .. " [NICKEL] " .. message .. "\n")
            file:close()
        end
    end
    
    -- create new file if no files exist or all files are older than keepinglogsdays
    if empty then
        local file = io.open(LOGSPATH .. date .. ".log", "a+")
        file:write(dateHours .. " [NICKEL] " .. message .. "\n")
        file:close()
    end
end


--GetJsonUser
function GetJsonUser(player_id)
    local player_beammp_id = getPlayerBeamMPID(player_id)
    if player_beammp_id == nil then
        return nil
    end
    local file = io.open(USERPATH .. player_beammp_id .. ".json", "r")
    if file == nil then
        return nil
    end
    local content = file:read("*all")
    file:close()
    return Util.JsonDecode(content)
end

--GetAllIpBanned
function getAllIpBanned()
    local ips = {}
    for key, file in pairs(FS.ListFiles(USERPATH)) do
        local file = io.open(USERPATH .. file, "r")
        local content = file:read("*all")
        file:close()
        local json = Util.JsonDecode(content)
        if json.ipbanned == true then
            table.insert(ips, json.ip)
        end
    end
    return ips
end

--updateValueOfUser
function updateSimpleValueOfUser(player_id, key, value)
    local player_beammp_id = getPlayerBeamMPID(player_id)
    if player_beammp_id == nil then
        return nil
    end
    local file = io.open(USERPATH .. player_beammp_id .. ".json", "r")
    if file == nil then
        return nil
    end
    local content = file:read("*all")
    file:close()
    local json = Util.JsonDecode(content)
    json[key] = value
    local newcontent = Util.JsonEncode(json)
    file = io.open(USERPATH .. player_beammp_id .. ".json", "w")
    file:write(newcontent)
    file:close()

    nkprintwarning(json.beammpid .. " -> " .. json.name .. " : field " .. key .. " updated with " .. value)
end
--updateComplexValueOfUser (table) like "banned":{"bool":false,"reason":""}
function updateComplexValueOfUser(player_id, key, subkey, value)
    local player_beammp_id = getPlayerBeamMPID(player_id)
    if player_beammp_id == nil then
        return nil
    end
    local file = io.open(USERPATH .. player_beammp_id .. ".json", "r")
    if file == nil then
        return nil
    end
    local content = file:read("*all")
    file:close()
    local json = Util.JsonDecode(content)
    json[key][subkey] = value
    local newcontent = Util.JsonEncode(json)
    file = io.open(USERPATH .. player_beammp_id .. ".json", "w")
    file:write(newcontent)
    file:close()

    nkprintwarning(json.beammpid .. " -> " .. json.name .. " : field " .. key .. "." .. subkey .. " updated with " .. tostring(value))
end

--updateSimpleValueOfUserWithJsonFileAndNotID
function updateSimpleValueOfUserWithJson(json, key, value)
    json[key] = value
    local newcontent = Util.JsonEncode(json)
    file = io.open(USERPATH .. json.beammpid .. ".json", "w")
    file:write(newcontent)
    file:close()
    nkprintwarning(json.beammpid .. " -> " .. json.name .. " : field " .. key .. " updated with " .. tostring(value))
end

--updateComplexValueOfUserWithJsonFileAndNotID
function updateComplexValueOfUserWithJson(json, key, subkey, value)
    json[key][subkey] = value
    local newcontent = Util.JsonEncode(json)
    file = io.open(USERPATH .. json.beammpid .. ".json", "w")
    file:write(newcontent)
    file:close()
    nkprintwarning(json.beammpid .. " -> " .. json.name .. " : field " .. key .. "." .. subkey .. " updated with " .. tostring(value))
end



function httpRequest(url)
    --check os
    if MP.GetOSName() == "Windows" then
        local response = os.execute("curl -s " .. url .. " --output temp.txt")
        -- response:close()
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
        local response = os.execute("wget -q -O temp.txt " .. url)
        -- response:close()
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

--get permlevel of name
function getPermLevelOfName(name)
    local file = io.open(PERMISSIONPATH, "r")
    local content = file:read("*all")
    file:close()
    local json = Util.JsonDecode(content)
    for key, value in pairs(json.permissionLevels) do
        if value.name == name then
            return value.level
        end
    end
    return nil
end

--getPermNameOfLevel
function getPermNameOfLevel(level)
    local file = io.open(PERMISSIONPATH, "r")
    local content = file:read("*all")
    file:close()
    local json = Util.JsonDecode(content)
    for key, value in pairs(json.permissionLevels) do
        if value.level == level then
            return value.name
        end
    end
    return nil
end
--nkprint
function nkprint(message)
    print(print_color("[NICKEL] ", "gray") .. message)
    log(message)
end

--nkprinterror
function nkprinterror(message)
    print(print_color("[NICKEL] ", "gray") .. print_color("[ERROR] " .. message, "red"))
    log("[ERROR] " .. message)
end

--nkprintwarning
function nkprintwarning(message)
    print(print_color("[NICKEL] ", "gray") .. print_color("[WARN] " .. message, "yellow"))
    log("[WARN] " .. message)
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
    if player_beammp_id == nil then
        return -1
    end
    return player_beammp_id
end

--get the lowest permlevel in permission file
function getLowestPermLevel()
    local file = io.open(PERMISSIONPATH, "r")
    local content = file:read("*all")
    file:close()
    local json = Util.JsonDecode(content)
    local lowest = 99999
    for key, value in pairs(json.permissionLevels) do
        if value.level < lowest then
            lowest = value.level
        end
    end
    return lowest

end



function checkFileEndWithNewLine(file_name)


    --check if file exists
    if not file_exists(file_name) then
        local file = io.open(file_name, "w")
        file:close()
        nkprint(file_name .. " created")
        return
    end
    
    local file = io.open(file_name, "r")
    local content = file:read("*all")

    --check if file is empty
    if content == "" then
        file:close()
        nkprint(file_name .. " is empty")
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
        nkprint("Modified " .. file_name .. " and added newline character at the end of each line.")
    else
        nkprint(file_name .. " is already formatted correctly.")
    end
end




--isStaffWithJson function
function isStaffWithJson(json)
    if json.permlvl ~= getLowestPermLevel() then
        return true
    end
    return false
end 



--is staff function
function isStaff(player_id)
    local player_beammp_id = getPlayerBeamMPID(player_id)
    if player_beammp_id == -1 then
        return false
    end
    local file = io.open(USERPATH .. player_beammp_id .. ".json", "r")
    local content = file:read("*all")
    local usertable = Util.JsonDecode(content)
    file:close()
    if usertable.permlvl ~= getLowestPermLevel() then
        return true
    end
    return false
end



function print_color(message, color)
    -- Les codes de couleur ANSI pour différentes couleurs
    local colors = {
      black = "\27[30m",
      red = "\27[31m",
      green = "\27[32m",
      yellow = "\27[33m",
      blue = "\27[34m",
      magenta = "\27[35m",
      cyan = "\27[36m",
      white = "\27[37m",
      gray = "\27[90m",
    }
  
    -- Vérifie si la couleur spécifiée est valide
    if not colors[color] then
      color = "white"
    end
  
    -- Affiche le message dans la couleur spécifiée
    return colors[color] .. message .. "\27[0m"
end


--HasPermission of command
function HasPermission(player_id, command)
    local player_beammp_id = getPlayerBeamMPID(player_id)
    if player_beammp_id == nil then
        return false
    end
    local user = io.open(USERPATH .. player_beammp_id .. ".json", "r")
    local permissions = io.open(PERMISSIONPATH, "r")
    local permcontent = permissions:read("*all")
    local permtable = Util.JsonDecode(permcontent)
    local usercontent = user:read("*all")
    local usertable = Util.JsonDecode(usercontent)
    user:close()
    permissions:close()
    local levels = getAllPermLvl()

    for _, level in ipairs(levels) do
        for key, value in pairs(permtable.permissionLevels) do
            if value.level == level then
                for _, commandperm in ipairs(value.commands) do
                    if commandperm == command then
                        if usertable.permlvl >= level then
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end
--getAllPermLvl function

function getAllPermLvl()
    local permissions = io.open(PERMISSIONPATH, "r")
    local permcontent = permissions:read("*all")
    local permtable = Util.JsonDecode(permcontent)
    permissions:close()
  -- for permlvl if is higher than a other in the array with using index like : permtable.permissionLevels[index]
    local levels = {}
    for _, level in ipairs(permtable.permissionLevels) do
        table.insert(levels, level.level)
    end

    return levels
    
end




--getMaxPermLvl
function getMaxPermLvl()
    local permissions = io.open(PERMISSIONPATH, "r")
    local permcontent = permissions:read("*all")
    local permtable = Util.JsonDecode(permcontent)
    permissions:close()
  -- for permlvl if is higher than a other in the array with using index like : permtable.permissionLevels[index]
    local maxLevel = 0
    for _, level in ipairs(permtable.permissionLevels) do
        if level.level > maxLevel then
            maxLevel = level.level
        end
    end
    return maxLevel
    
end


--getUserFileWithName (the player cant be connected)

function getJsonUserByName(player_name)
    --for in users
    for key, file in ipairs(FS.ListFiles(USERPATH)) do
        local user = io.open(USERPATH .. file, "r")
        local content = user:read("*all")
        local usertable = Util.JsonDecode(content)
        user:close()
        if usertable.name == player_name then
            return usertable
        end
        
    end
end

--time converter
function timeConverter(time)
    local oldtime = time

    local time = time:lower()
    local time = time:gsub(" ", "")
    local time = time:gsub("s", "")
    local time = time:gsub("m", "")
    local time = time:gsub("h", "")
    local time = time:gsub("d", "")
    local time = tonumber(time)
    if time == nil then
        return nil
    end
    if oldtime:lower():find("s") then
        return time
    elseif oldtime:lower():find("m") then
        return time * 60
    elseif oldtime:lower():find("h") then
        return time * 60 * 60
    elseif oldtime:lower():find("d") then
        return time * 60 * 60 * 24
    else
        return nil
    end
end




--Init User with beammp id and name in parameter
function InitUserWithBeamMPID(beamid, name)
    if not file_exists(USERPATH) then
        FS.CreateDirectory(USERPATH)
    end
    local user = {}
    beamid = tostring(beamid)
    user.name = name
    user.beammpid = beamid
    user.permlvl = getLowestPermLevel()
    user.banned = {bool= false, reason = ""}
    user.ipbanned = {bool = false, reason = ""}
    user.tempbanned = {bool = false, reason = "", time = 0}
    user.muted = {bool = false, reason = ""}
    user.tempmuted = {bool = false, reason = "", time = 0}
    user.ip = ""
    user.whitelisted = false

    local file = USERPATH .. beamid .. ".json"
    if not file_exists(file) then
    -- Util.JsonEncode in file
        local json = Util.JsonEncode(user)
        local file = io.open(file, "w")
        file:write(json)
        file:close()
        return true
    else
        return false
    end
end

--getUserApi
function getBeamIDFromApi(name)
    local apiurl = "https://forum.beammp.com/u/"
    local response = httpRequest(apiurl .. name .. ".json")
    if response ~= "" then
        local jsonResponse = Util.JsonDecode(response)
        return jsonResponse.user.id -- beam id
    else
        return nil
    end
end
------------ END OF UTILITY FUNCTIONS ------------








------------ START OF INITIALIZATION ------------

function onInit()

    InitPerm() --initialize perms



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
                print("failed to delete old config file")
            end
        else                --ONLY PRINT HERE TO PREVENT BUG
            local error, error_message = FS.Remove("config.toml")
            if error then
                print("failed to delete old config file " .. error_message)
            else
                print("config.toml moved to " .. CONFIGPATH)
            end
        end
    end




    --check files
    --array with all file name
    local oldfiles = {"staff.txt", "bans.txt", "banips.txt"}
    local isOld = false
    --loop in files
    for key, value in pairs(oldfiles) do
        if file_exists(value) then
            isOld = true
            if not file_exists(OLDPATH) then
                FS.CreateDirectory(OLDPATH)
            end
            FS.Copy(value, OLDPATH .. value)
            FS.Remove(value)
        end
    end
    if isOld then
        nkprinterror("Migrating old bans and staff files from 1.2.5. Old files saved in " .. OLDPATH .. " , you need to re add staff and bans, Sorry for the inconvenience")
    end
    nkprint("Starting Nickel plugin version : " .. VERSION .. "\nPlease join the discord of this plugin ! : https://discord.gg/h5P84FFw7B ")
    MP.SendChatMessage(-1, "^l^7 Nickel |^r^o plugin loaded successfully")
    PREFIX = getConfigValue("PREFIX")

end

--init user in json
function initUser(id)
    if not file_exists(USERPATH) then
        FS.CreateDirectory(USERPATH)
    end
    if getPlayerBeamMPID(id) == -1 then
        if getConfigValue("NOGUEST") == "true" then
            MP.DropPlayer(id, getConfigValue("NOGUESTMSG"))
        end
        return
    end
    local user = {}
    local player_identifiers = MP.GetPlayerIdentifiers(id)

    user.name = MP.GetPlayerName(id)
    user.beammpid = getPlayerBeamMPID(id)
    user.permlvl = getLowestPermLevel()
    user.banned = {bool= false, reason = ""}
    user.ipbanned = {bool = false, reason = ""}
    user.tempbanned = {bool = false, reason = "", time = 0}
    user.muted = {bool = false, reason = ""}
    user.tempmuted = {bool = false, reason = "", time = 0}
    user.ip = player_identifiers['ip']
    user.whitelisted = false

    local file = USERPATH .. user.beammpid .. ".json"
    if not file_exists(file) then
    -- Util.JsonEncode in file
        local json = Util.JsonEncode(user)
        local file = io.open(file, "w")
        file:write(json)
        file:close()
    else
        local edited = false
        local json = io.open(file, "r")
        local jsoncontent = json:read("*a")
        json:close()
        local decodedJson = Util.JsonDecode(jsoncontent)

        --if decodedJson.permlvl in getAllPermLvl() 
        if not getAllPermLvl()[decodedJson.permlvl] then
            decodedJson.permlvl = getLowestPermLevel()
            edited = true
        end

        


       --check if a key is added in the code
        for key, value in pairs(user) do
            if decodedJson[key] == nil then
                decodedJson[key] = value
                edited = true
            end
        end
        
        --check if ip have changed
        if decodedJson.ip ~= user.ip then
            decodedJson.ip = user.ip
            edited = true
        end

        --check if name have changed
        if decodedJson.name ~= user.name then
            decodedJson.name = user.name
            edited = true
        end

        if edited then
            json = io.open(file, "w")
            json:write(Util.JsonEncode(decodedJson))
            json:close()
        end

    end
end


--Init permissions config
function InitPerm()
    --if USERPATH dosnt exist
    if not file_exists(USERPATH) then
        FS.CreateDirectory(USERPATH)
    end
    if not file_exists(PERMISSIONPATH) then

        local config = {
            permissionLevels = {
            {
                level = 0,
                name = "member",
                commands = {
                    "votekick","countdown","help","dm"
                }
            },
            {
                level = 1,
                name = "moderator",
                commands = {
                    "ban","unban","kick","tempban","mute","tempmute","unmute","say"
                }
            },
            {
                level = 2,
                name = "administrator",
                commands = {
                    "ip","banip","unbanip","noguest","setrole"
                }
            },
            }
        }
        -- Convertir la table en format JSON
        local configStr = Util.JsonEncode(config)
        local configPretty = Util.JsonPrettify(configStr)
        -- Enregistrer le fichier de configuration
        local file = io.open(PERMISSIONPATH, "w")
        file:write(configPretty)
        file:close()
    end
end
------------ END OF INITIALIZATION ------------



------------ START OF COMMAND CREATOR ------------


-- function to create command with or without parameters
function CreateCommand(sender_id, message, command, allowSpaceOnLastArg, callback)
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



------------ END OF COMMAND CREATOR ------------



------------ START OF COMMANDS ------------
FUNCTIONSCOMMANDTABLE={}

-- Fonction pour créer une commande
function InitCMD(command_name, command_func, command_desc)
    -- Créer la table pour la commande si elle n'existe pas encore
    if not FUNCTIONSCOMMANDTABLE[command_name] then
      FUNCTIONSCOMMANDTABLE[command_name] = {}
    end
    
    -- Ajouter la description de la commande à la table, si fournie
    if command_desc then
      FUNCTIONSCOMMANDTABLE[command_name].description = command_desc
    else
        FUNCTIONSCOMMANDTABLE[command_name].description = "No description available"
    end
    
    -- Ajouter la fonction de commande à la table
    FUNCTIONSCOMMANDTABLE[command_name].command = command_func
end

--ip
InitCMD("ip", function(sender_id)
    
        -- create list
        local players = MP.GetPlayers()
        -- loop in players and add their name to the list
        local playersAndIp = {}
        for key, value in pairs(players) do
            local player_name = value
            local player_identifiers = MP.GetPlayerIdentifiers(key)
            local player_ip = player_identifiers['ip']
            table.insert(playersAndIp, player_name .. " - " .. player_ip)
        end
        -- if players is empty
        if #playersAndIp == 0 then
            if sender_id ~= "console" then
                MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o No players online")
            else
                return "No players online"
            end
        end

        local message = ""
        for key, value in pairs(playersAndIp) do
            if sender_id ~= "console" then

                MP.SendChatMessage(sender_id,"^l^7 Nickel |^r^o " .. value)
            else
                message = message .. value .. "\n"
            end
        end
        if #message ~= 0 then
            return message
        end
  
    end
, "Show players ip")

--setrole
InitCMD("setrole",function(sender_id, name, rolename)

    if name == nil or rolename == nil then
        if sender_id ~= "console" then
            MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Usage : setrole [name] [rolename]")
            return
        else
            return "Usage : setrole [name] [rolename]"
        end
    end
    -- check if parameter is already in staffs
    local player_target = GetPlayerId(name)
    local target_json = GetJsonUser(player_target)
    local permlvl = getPermLevelOfName(rolename)

    if player_target == -1 or player_target == nil or target_json == nil then

        --setrole offline
        local beamid = getBeamIDFromApi(name)
        if beamid ~= nil then
            InitUserWithBeamMPID(beamid, name)
            local jsonUser = getJsonUserByName(name)
            local permlvl = getPermLevelOfName(rolename)

            if sender_id ~= "console" then
                local senderJson = GetJsonUser(sender_id)
                if jsonUser.permlvl >= senderJson.permlvl then
                    if sender_id ~= "console" then
                        MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o You cant do this to this user")
                        return
                    else
                        return "You cant do this to this user"
                    end
                end
            end

            if permlvl == nil then
                if sender_id ~= "console" then
                    MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Role not found")
                    return
                else
                    return "Role not found"
                end
            end

            local oldpermname = getPermNameOfLevel(jsonUser.permlvl)




            updateSimpleValueOfUserWithJson(jsonUser, "permlvl", permlvl)
            if sender_id ~= "console" then
                MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o " .. oldpermname .. " " .. name .. " is now " .. rolename)
                return
            else
                return oldpermname .. " " .. name .. " is now " .. rolename   
            end
        else
            if sender_id ~= "console" then
                MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player not found")
                return
            else
                return "Player not found"
            end
        end
    end
    if sender_id ~= "console" then
        local senderJson = GetJsonUser(sender_id)
        if target_json.permlvl >= senderJson.permlvl then
            if sender_id ~= "console" then
                MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o You cant do this to this user")
                return
            else
                return "You cant do this to this user"
            end
        end
    end

    if permlvl == nil then
        if sender_id ~= "console" then
            MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Role not found")
            return
        else
            return "Role not found"
        end
    end

    local oldpermname = getPermNameOfLevel(target_json.permlvl)

    updateSimpleValueOfUser(player_target, "permlvl", permlvl)
    if sender_id ~= "console" then
        MP.SendChatMessage(player_target, "^l^7 Nickel |^r^o You are now " .. rolename)
        MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o " .. oldpermname .. " " .. name .. " is now " .. rolename)
    else
        MP.SendChatMessage(player_target, "^l^7 Nickel |^r^o You are now " .. rolename)
        return oldpermname .. " " .. name .. " is now " .. rolename      
    end
        
end
, "Set the role of a player with a role name that exists in permissions.json")



--help
InitCMD("help", function(sender_id)
    if sender_id ~= "console" then
        MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Commands list :")

        for k, v in pairs(FUNCTIONSCOMMANDTABLE) do

            if HasPermission(sender_id, k) then
                MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o " .. PREFIX .. k .. " : " .. v.description)
            end

        end
    else
        local array = {}
        for k, v in pairs(FUNCTIONSCOMMANDTABLE) do

            table.insert(array, k .. " : " .. v.description)
        end
        return "Command list : \n\n" .. table.concat(array, "\n")
    end
end
, "Show this menu")

--votekick command
InitCMD("votekick", function(sender_id, parameter)
    if sender_id == "console" then
        return "You can't use this command from console"
    end
    -- get player id
    local sender_name = MP.GetPlayerName(sender_id)
    local player_id = GetPlayerId(parameter)
    local is_staff = isStaff(player_id)
    if getConfigValue("VOTEKICK") == "true" then
        if player_id ~= sender_id then
            if not is_staff then
                -- check if player is online
                if player_id ~= -1 then
                    if #MP.GetPlayers() > 2 then
                        -- check if player is not already in votekick
                        if VOTEKICKLIST[player_id] == nil then
                            -- add player to votekick list

                            VOTEKICKLIST[player_id] = {votes = 1 , senders = {sender_id}} --register senderid
                            -- send chat message to all players
                            MP.SendChatMessage(-1, "^l^7 Nickel |^r^o Player " .. sender_name .. " started a vote to kick " .. parameter .. " from the server")
                            MP.SendChatMessage(-1, "^l^7 Nickel |^r^o Type ^l^7 ;votekick " .. parameter .. " ^r^o to vote")
                        else
                            -- check if every sender id is connected, if not remove the sender id and a vote
                            for key, value in pairs(VOTEKICKLIST[player_id].senders) do
                                if not MP.IsPlayerConnected(key) then
                                    VOTEKICKLIST[player_id][key] = nil
                                    VOTEKICKLIST[player_id] = VOTEKICKLIST[player_id].votes - 1
                                end
                            end
                            -- check if sender id is already in senders
                            local is_in_senders = false
                            for key, value in pairs(VOTEKICKLIST[player_id].senders) do
                                if value == sender_id then
                                    is_in_senders = true
                                    break
                                end
                            end
                            if not is_in_senders then
                                VOTEKICKLIST[player_id].votes = VOTEKICKLIST[player_id].votes + 1
                                table.insert(VOTEKICKLIST[player_id].senders, sender_id) --register player who voted 
                                MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o You voted to kick " .. parameter)
                                --votekick ratio
                                local ratio = #MP.GetPlayers() / 2
                                if VOTEKICKLIST[player_id].votes >= ratio then
                                    MP.DropPlayer(player_id, "Kicked by vote")
                                    MP.SendChatMessage(-1, "^l^7 Nickel |^r^o Player " .. parameter .. " kicked with " .. VOTEKICKLIST[player_id].votes .. " votes")
                                    VOTEKICKLIST[player_id] = nil
                                else
                                    MP.SendChatMessage(-1, "^l^7 Nickel |^r^o Player " .. parameter .. " has " .. VOTEKICKLIST[player_id].votes .. " votes")
                                end
                            else
                                MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o You already voted to kick " .. parameter)
                            end
                        end
                    else
                        MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o You cant votekick player " .. parameter .. " because there is not enough players")
                    end
                else
                    MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. parameter .. " not found")
                end
            else
                MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o You cant votekick player " .. parameter .. " because is a staff")
            end
        else
            MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o You cant votekick yourself")
        end
    else
        MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o You cant votekick player " .. parameter .. " because votekick is disabled on this server")
    end
end
, "Start a vote to kick a troublesome player")

-- kick command
InitCMD("kick", function(sender_id, parameter)
    -- get player id
    if parameter == nil then
        if sender_id ~= "console" then
            MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Usage : kick [player]")
            return
        else
            return "Usage : kick [player]"
        end
    end


    local player_id = GetPlayerId(parameter)
    local is_staff = isStaff(player_id)
    -- check if player is online
    if player_id ~= -1 then
        if not is_staff then
            MP.DropPlayer(player_id, "Kicked")
            if sender_id ~= "console" then
                MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. parameter .. " kicked")
                return      
            else
                return "Player " .. parameter .. " kicked"
            end
        else
            if sender_id ~= "console" then
                MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o You cant kick player " .. parameter .. " because is a staff")
                return
            else
                return "You cant kick player " .. parameter .. " because is a staff"
            end
        end
    else
        if sender_id ~= "console" then
            MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. parameter .. " not found")
            return
        else
            return "Player " .. parameter .. " not found"
        end
    end
end
, "Kick a troublesome player")

--ban command
InitCMD("ban", function(sender_id, name, reason)
    if name == nil then
        if sender_id ~= "console" then
            MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Usage : ban [player] [reason]")
            return
        else
            return "Usage : ban [player] [reason]"
        end
    end
    if reason == nil then
        reason = "No reason"
    end
    local player_id = GetPlayerId(name)
    local is_staff = isStaff(player_id)
    -- check if player is online
    if player_id ~= -1 then
        if not is_staff then
            local jsonUser = getJsonUserByName(name)
            

            if jsonUser.banned.bool or jsonUser.tempbanned.bool then
                if sender_id ~= "console" then
                    MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. name .. " already banned")
                    return
                else
                    return "Player " .. name .. " already banned"
                end
            end
            updateComplexValueOfUser(player_id, "banned", "bool", true)
            updateComplexValueOfUser(player_id, "banned", "reason", reason)
            MP.DropPlayer(player_id, "Banned" .. " for " .. reason)
            if sender_id ~= "console" then
                MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. name .. " banned for " .. reason)
                return
            else
                return "Player " .. name .. " banned for " .. reason
            end
        else
            if sender_id ~= "console" then
                MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o You cant ban player " .. name .. " because is a staff")
                return
            else
                return "You cant ban player " .. name .. " because is a staff"
            end
        end
    else

        --ban offline
        local beamid = getBeamIDFromApi(name)
        if beamid ~= nil then
            InitUserWithBeamMPID(beamid, name)
            local jsonUser = getJsonUserByName(name)
            if isStaffWithJson(jsonUser) then
                if sender_id ~= "console" then
                    MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o You cant ban player " .. name .. " because is a staff")
                    return
                else
                    return "You cant ban player " .. name .. " because is a staff"
                end
            end

            if jsonUser.banned.bool or jsonUser.tempbanned.bool then
                if sender_id ~= "console" then
                    MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. name .. " already banned")
                    return
                else
                    return "Player " .. name .. " already banned"
                end
            end
            updateComplexValueOfUserWithJson(jsonUser, "banned", "bool", true)
            updateComplexValueOfUserWithJson(jsonUser, "banned", "reason", reason)
            if sender_id ~= "console" then
                MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. name .. " banned for " .. reason)
            else
                return "Player " .. name .. " banned for " .. reason
            end
        else
            if sender_id ~= "console" then
                MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. name .. " not found")
                return
            else
                return "Player " .. name .. " not found"
            end
        end
    end
end
, "Ban a very troublesome player")

--private message
InitCMD("dm", function(sender_id, target_name, message)
    local target_id = GetPlayerId(target_name)
    local sender_name = MP.GetPlayerName(sender_id)
    if target_id ~= -1 then
        if sender_id ~= target_id then
            
            MP.SendChatMessage(sender_id,"To -> " .. target_name .. " : " .. message)
            MP.SendChatMessage(target_id,"From -> " .. sender_name .. " : " .. message)
        else
            MP.SendChatMessage(sender_id, "You cant dm yourself")
        end
    else
        if sender_id ~= "console" then
            MP.SendChatMessage(sender_id, "Player not found")
        else
            return "Player not found"
        end
    end
end
, "Send a private message to another player")

--banip command with username and reason parameter
InitCMD("banip", function(sender_id, name, reason)
    -- get player id
    if name == nil then
        if sender_id ~= "console" then
            MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Usage : banip [player] [reason]")
            return
        else
            return "Usage : banip [player] [reason]"
        end
    end
    if reason == nil then
        reason = "No reason"
    end
    local player_id = GetPlayerId(name)
    local is_staff = isStaff(player_id)
    -- check if player is online
    if player_id ~= -1 then
        if not is_staff then
            local jsonUser = getJsonUserByName(name)
            if jsonUser.ipbanned.bool then
                if sender_id ~= "console" then
                    MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. name .. " already ip banned")
                    return
                else
                    return "Player " .. name .. " already ip banned"
                end
            end
            updateComplexValueOfUser(player_id, "ipbanned", "bool", true)
            updateComplexValueOfUser(player_id, "ipbanned", "reason", reason)
            print("work")
            MP.DropPlayer(player_id, "Ip banned" .. " for " .. reason)
            print("work")
            if sender_id ~= "console" then
                MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. name .. " ip banned for " .. reason)
                return
            else
                return "Player " .. name .. " ip banned for " .. reason
            end
        else
            if sender_id ~= "console" then
                MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o You cant ip ban player " .. name .. " because is a staff")
                return
            else
                return "You cant ip ban player " .. name .. " because is a staff"
            end
        end
    else
        if sender_id ~= "console" then 
            MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. name .. " not found")
            return
        else
            return "Player " .. name .. " not found"
        end
    end
end
, "Ban ip a very troublesome player")



--tempban command
InitCMD("tempban", function(sender_id, name, time, reason)
    -- get player id
    if name == nil  then
        if sender_id ~= "console" then
            MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Usage : tempban [player] [time] [reason]")
            return
        else
            return "Usage : tempban [player] [time] [reason]"
        end
    end
    if reason == nil then
        reason = "No reason"
    end
    local player_id = GetPlayerId(name)
    local is_staff = isStaff(player_id)
    -- check if player is online
    if player_id ~= -1 then
        if not is_staff then
            if time == nil then
                if sender_id ~= "console" then
                    MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Invalid time format, time have to be like : 5s / 5m / 5h / 5d for example")
                    return
                else
                    return "Invalid time format, time have to be like : 5s / 5m / 5h / 5d for example"
                end
            end
            time = timeConverter(time)
            local endtime = os.time() + time
            local enddate = os.date("%d/%m/%Y %H:%M:%S", endtime)
            local jsonUser = getJsonUserByName(name)
            if jsonUser.tempbanned.bool or jsonUser.banned.bool then
                if sender_id ~= "console" then
                    MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. name .. " already banned")
                    return
                else
                    return "Player " .. name .. " already banned"
                end
            end
            updateComplexValueOfUser(player_id, "tempbanned", "bool", true)
            updateComplexValueOfUser(player_id, "tempbanned", "reason", reason .. " until " .. enddate)
            updateComplexValueOfUser(player_id, "tempbanned", "time", endtime)
            MP.DropPlayer(player_id, "Banned" .. " for " .. reason .. " until " .. enddate)
            if sender_id ~= "console" then
                MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. name .. " banned for " .. reason .. " until " .. enddate)
                return
            else
                return "Player " .. name .. " banned for " .. reason .. " until " .. enddate
            end	
        else
            if sender_id ~= "console" then
                MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o You cant ban player " .. name .. " because is a staff")
                return
            else
                return "You cant ban player " .. name .. " because is a staff"
            end
        end
    else
        
        --tempban offline
        local beamid = getBeamIDFromApi(name)
        if beamid ~= nil then
            time = timeConverter(time)
            local endtime = os.time() + time
            local enddate = os.date("%d/%m/%Y %H:%M:%S", endtime)


            InitUserWithBeamMPID(beamid, name)
            local jsonUser = getJsonUserByName(name)
            if isStaffWithJson(jsonUser) then
                if sender_id ~= "console" then
                    MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o You cant ban player " .. name .. " because is a staff")
                    return
                else
                    return "You cant ban player " .. name .. " because is a staff"
                end
            end
            if jsonUser.banned.bool or jsonUser.tempbanned.bool then
                if sender_id ~= "console" then
                    MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. name .. " already banned")
                    return
                else
                    return "Player " .. name .. " already banned"
                end
            end
            updateComplexValueOfUserWithJson(jsonUser, "tempbanned", "bool", true)
            updateComplexValueOfUserWithJson(jsonUser, "tempbanned", "reason", reason)
            updateComplexValueOfUserWithJson(jsonUser, "tempbanned", "time", endtime)
            if sender_id ~= "console" then
                MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. name .. " banned for " .. reason .. " until " .. enddate)
            else
                return "Player " .. name .. " banned for " .. reason .. " until " .. enddate
            end
        else
            if sender_id ~= "console" then
                MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. name .. " not found")
                return
            else
                return "Player " .. name .. " not found"
            end
        end
    end
end
, "Tempban a very troublesome player")

--unban command
InitCMD("unban", function(sender_id, name)
    -- get player id
    if name == nil then
        if sender_id ~= "console" then
            MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Usage : unban [player]")
            return
        else
            return "Usage : unban [player]"
        end
    end
    local json = getJsonUserByName(name)
    if json ~= nil then
        if json.banned.bool or json.tempbanned.bool then

            updateComplexValueOfUserWithJson(json, "tempbanned", "bool", false)
            updateComplexValueOfUserWithJson(json, "tempbanned", "time", 0)
            updateComplexValueOfUserWithJson(json, "banned", "bool", false)
            if sender_id ~= "console" then
                MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. name .. " unbanned")
                return
            else
                return "Player " .. name .. " unbanned"
            end
        elseif json.ipbanned.bool then
            updateComplexValueOfUserWithJson(json, "ipbanned", "bool", false)
            if sender_id ~= "console" then
                MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. name .. " ip unbanned")
                return
            else
                return "Player " .. name .. " ip unbanned"
            end
        else
            if sender_id ~= "console" then
                MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. name .. " not banned")
                return
            else
                return "Player " .. name .. " not banned"
            end
        end

    else
        --unban offline
        local beamid = getBeamIDFromApi(name)
        if beamid ~= nil then
            InitUserWithBeamMPID(beamid, name)
            local jsonUser = getJsonUserByName(name)
            if jsonUser.banned.bool or jsonUser.tempbanned.bool then
                updateComplexValueOfUserWithJson(jsonUser, "tempbanned", "bool", false)
                updateComplexValueOfUserWithJson(jsonUser, "tempbanned", "time", 0)
                updateComplexValueOfUserWithJson(jsonUser, "banned", "bool", false)
                if sender_id ~= "console" then
                    MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. name .. " unbanned")
                    return
                else
                    return "Player " .. name .. " unbanned"
                end
            elseif jsonUser.ipbanned.bool then
                updateComplexValueOfUserWithJson(jsonUser, "ipbanned", "bool", false)
                if sender_id ~= "console" then
                    MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. name .. " ip unbanned")
                    return
                else
                    return "Player " .. name .. " ip unbanned"
                end
            else
                if sender_id ~= "console" then
                    MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. name .. " not banned")
                    return
                else
                    return "Player " .. name .. " not banned"
                end
            end
        else
            if sender_id ~= "console" then
                MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. name .. " not found")
                return
            else
                return "Player " .. name .. " not found"
            end
        end
    end
end
, "Undo a player's ban")

--mute command
InitCMD("mute", function(sender_id, name, reason)
    -- get player id
    if name == nil then
        if sender_id ~= "console" then
            MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Usage : mute [player] [reason]")
            return
        else
            return "Usage : mute [player] [reason]"
        end
    end
    if reason == nil then
        reason = "No reason"
    end
    local player_id = GetPlayerId(name)
    local is_staff = isStaff(player_id)
    -- check if player is online
    if player_id ~= -1 then
        if not is_staff then
            local jsonUser = getJsonUserByName(name)
            if jsonUser.muted.bool or jsonUser.tempmuted.bool then
                if sender_id ~= "console" then
                    MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. name .. " already muted")
                    return
                else
                    return "Player " .. name .. " already muted"
                end
            end
            updateComplexValueOfUser(player_id, "muted", "bool", true)
            updateComplexValueOfUser(player_id, "muted", "reason", reason)
            if sender_id ~= "console" then
                MP.SendChatMessage(player_id, "^l^7 Nickel |^r^o You have been muted" .. " for " .. reason)
                MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. name .. " muted for " .. reason)
                return
            else
                MP.SendChatMessage(player_id, "^l^7 Nickel |^r^o You have been muted" .. " for " .. reason)
                return "Player " .. name .. " muted for " .. reason
            end

        else
            if sender_id ~= "console" then
                MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o You cant mute player " .. name .. " because is a staff")
                return
            else
                return "You cant mute player " .. name .. " because is a staff"
            end
        end
    else
        --mute offline
        local beamid = getBeamIDFromApi(name)
        if beamid ~= nil then
            InitUserWithBeamMPID(beamid, name)
            local jsonUser = getJsonUserByName(name)
            if jsonUser.muted.bool or jsonUser.tempmuted.bool then
                if sender_id ~= "console" then
                    MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. name .. " already muted")
                    return
                else
                    return "Player " .. name .. " already muted"
                end
            end
            updateComplexValueOfUserWithJson(jsonUser, "muted", "bool", true)
            updateComplexValueOfUserWithJson(jsonUser, "muted", "reason", reason)
            if sender_id ~= "console" then
                MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. name .. " muted for " .. reason)
            else
                return "Player " .. name .. " muted for " .. reason
            end
        else
            if sender_id ~= "console" then
                MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. name .. " not found")
            else
                return "Player " .. name .. " not found"
            end
        end
    end
end
, "Mute a troublesome player")

--unmute command
InitCMD("unmute", function(sender_id, parameter)
    -- get player id
    if parameter == nil then
        if sender_id ~= "console" then
            MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Usage : unmute [player]")
            return
        else
            return "Usage : unmute [player]"
        end
    end
    local json = getJsonUserByName(parameter)
    if json ~= nil then
        if json.muted.bool or json.tempmuted.bool then
            updateComplexValueOfUserWithJson(json, "tempmuted", "bool", false)
            updateComplexValueOfUserWithJson(json, "muted", "bool", false)
            if sender_id ~= "console" then
                MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. parameter .. " unmuted")
                return
            else
                return "Player " .. parameter .. " unmuted"
            end
        else
            if sender_id ~= "console" then
                MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. parameter .. " not muted")
                return
            else
                return "Player " .. parameter .. " not muted"
            end
        end

    else
        --unmute offline
        local beamid = getBeamIDFromApi(parameter)
        if beamid ~= nil then
            InitUserWithBeamMPID(beamid, parameter)
            local jsonUser = getJsonUserByName(parameter)
            if jsonUser.muted.bool or jsonUser.tempmuted.bool then
                updateComplexValueOfUserWithJson(jsonUser, "tempmuted", "bool", false)
                updateComplexValueOfUserWithJson(jsonUser, "muted", "bool", false)
                if sender_id ~= "console" then
                    MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. parameter .. " unmuted")
                    return
                else
                    return "Player " .. parameter .. " unmuted"
                end
            else
                if sender_id ~= "console" then
                    MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. parameter .. " not muted")
                    return
                else
                    return "Player " .. parameter .. " not muted"
                end
            end
        else
            if sender_id ~= "console" then
                MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. parameter .. " not found")
                return
            else
                return "Player " .. parameter .. " not found"
            end
        end
    end
end
, "Undo a player's mute")

--tempmute
InitCMD("tempmute", function(sender_id, name, time, reason)
    -- get player id
    if name == nil then
        if sender_id ~= "console" then
            MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Usage : tempmute [player] [time] [reason]")
            return
        else
            return "Usage : tempmute [player] [time] [reason]"
        end
    end
    if reason == nil then
        reason = "No reason"
    end
    local player_id = GetPlayerId(name)
    local is_staff = isStaff(player_id)
    -- check if player is online
    if player_id ~= -1 then
        if not is_staff then
            time = timeConverter(time)
            if time == nil then
                if sender_id ~= "console" then
                    MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Invalid time format, time have to be like : 5s / 5m / 5h / 5d for example")
                    return
                else
                    return "Invalid time format, time have to be like : 5s / 5m / 5h / 5d for example"
                end
            end
            time = timeConverter(time)
            local endtime = os.time() + time
            local enddate = os.date("%d/%m/%Y %H:%M:%S", endtime)
            local jsonUser = getJsonUserByName(name)
            if jsonUser.muted.bool or jsonUser.tempmuted.bool then
                if sender_id ~= "console" then
                    MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. name .. " already muted")
                    return
                else
                    return "Player " .. name .. " already muted"
                end
            end
            updateComplexValueOfUser(player_id, "tempmuted", "bool", true)
            updateComplexValueOfUser(player_id, "tempmuted", "reason", reason .. " until " .. enddate)
            updateComplexValueOfUser(player_id, "tempmuted", "time", endtime)
            if sender_id ~= "console" then
                MP.SendChatMessage(player_id, "^l^7 Nickel |^r^o You have been muted" .. " for " .. reason .. " until " .. enddate)
                MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. name .. " muted for " .. reason .. " until " .. enddate)
                return
            else
                MP.SendChatMessage(player_id, "^l^7 Nickel |^r^o You have been muted" .. " for " .. reason .. " until " .. enddate)
                return "Player " .. name .. " muted for " .. reason .. " until " .. enddate
            end
        else
            if sender_id ~= "console" then
                MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o You cant mute player " .. name .. " because is a staff")
                return
            else
                return "You cant mute player " .. name .. " because is a staff"
            end
        end
    else
        --mute offline
        local beamid = getBeamIDFromApi(name)
        if beamid ~= nil then
            InitUserWithBeamMPID(beamid, name)
            local jsonUser = getJsonUserByName(name)
            if not isStaff(beamid) then
                time = timeConverter(time)
                if time == nil then
                    if sender_id ~= "console" then
                        MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Invalid time format, time have to be like : 5s / 5m / 5h / 5d for example")
                        return
                    else
                        return "Invalid time format, time have to be like : 5s / 5m / 5h / 5d for example"
                    end
                end

                local endtime = os.time() + time
                local enddate = os.date("%d/%m/%Y %H:%M:%S", endtime)
                if jsonUser.muted.bool or jsonUser.tempmuted.bool then
                    if sender_id ~= "console" then
                        MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. name .. " already muted")
                        return
                    else
                        return "Player " .. name .. " already muted"
                    end
                end
                updateComplexValueOfUserWithJson(jsonUser, "tempmuted", "bool", true)
                updateComplexValueOfUserWithJson(jsonUser, "tempmuted", "reason", reason .. " until " .. enddate)
                updateComplexValueOfUserWithJson(jsonUser, "tempmuted", "time", endtime)
                if sender_id ~= "console" then
                    MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. name .. " muted for " .. reason .. " until " .. enddate)
                    return
                else
                    return "Player " .. name .. " muted for " .. reason .. " until " .. enddate
                end
            else
                if sender_id ~= "console" then
                    MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o You cant mute player " .. name .. " because is a staff")
                    return
                else
                    return "You cant mute player " .. name .. " because is a staff"
                end
            end
        else
            if sender_id ~= "console" then
                MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. name .. " not found")
            else
                return "Player " .. name .. " not found"
            end
        end
    end
end
, "Tempmute a troublesome player")

--countdown
InitCMD("countdown", function(sender_id)
    if sender_id == "console" then
        return "You can't use this command from console"
    end
    local time = 5
    MP.SendChatMessage(-1, "^l^7 Nickel |^r^o Countdown started")
    for i = time, 1, -1 do
        MP.SendChatMessage(-1, "^l^7 Nickel |^r^o " .. i)
        MP.Sleep(1000)
    end
    MP.SendChatMessage(-1, "^l^7 Nickel |^r^o GOOO !")
end
, "Initiate a countdown timer")

--say command
InitCMD("say", function(sender_id, parameter)
    if parameter == nil then
        if sender_id ~= "console" then
            MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Usage : say [message]")
            return
        else
            return "Usage : say [message]"
        end
    end
    MP.SendChatMessage(-1, "^l^7 Nickel Announcement |^r^o " .. parameter)
    if sender_id == "console" then
        return parameter
    end
end
, "Broadcast a message to all players")

--whitelist command
InitCMD("whitelist", function(sender_id, parameter, name)
    if parameter == nil then
        if sender_id ~= "console" then
            MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Usage : whitelist [add/remove] [player]")
            return
        else
            return "Usage : whitelist [add/remove] [player]"
        end
    end
    local player_id = MP.GetPlayerId(name)
    if player_id == nil then

        --whitelist offline
        local beamid = getBeamIDFromApi(name)
        if beamid ~= nil then
            InitUserWithBeamMPID(beamid, name)
            local jsonUser = getJsonUserByName(name)
            if parameter == "add" then
                if jsonUser.whitelisted then
                    if sender_id ~= "console" then
                        MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. name .. " already whitelisted")
                        return
                    else
                        return "Player " .. name .. " already whitelisted"
                    end
                end
                updateComplexValueOfUserWithJson(jsonUser, "whitelisted", "bool", true)
                if sender_id ~= "console" then
                    MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. name .. " whitelisted")
                    return
                else
                    return "Player " .. name .. " whitelisted"
                end
            elseif parameter == "remove" then
                if not jsonUser.whitelisted then
                    if sender_id ~= "console" then
                        MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. name .. " not whitelisted")
                        return
                    else
                        return "Player " .. name .. " not whitelisted"
                    end
                end
                updateComplexValueOfUserWithJson(jsonUser, "whitelisted", "bool", false)
                if sender_id ~= "console" then
                    MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. name .. " unwhitelisted")
                    return
                else
                    return "Player " .. name .. " unwhitelisted"
                end
            else
                if sender_id ~= "console" then
                    MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Usage : whitelist [add/remove] [player]")
                    return
                else
                    return "Usage : whitelist [add/remove] [player]"
                end
            end
        else
            if sender_id ~= "console" then
                MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. name .. " not found")
                return
            else
                return "Player " .. name .. " not found"
            end
        end


        if sender_id ~= "console" then
            MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. name .. " not found")
            return
        else
            return "Player " .. name .. " not found"
        end
    end
    local jsonUser = GetJsonUser(player_id)

    if parameter == "add" then
        if jsonUser.whitelisted then
            if sender_id ~= "console" then
                MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. name .. " already whitelisted")
                return
            else
                return "Player " .. name .. " already whitelisted"
            end
        end
        updateComplexValueOfUser(player_id, "whitelisted", "bool", true)
        if sender_id ~= "console" then
            MP.SendChatMessage(player_id, "^l^7 Nickel |^r^o You have been whitelisted")
            MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. name .. " whitelisted")
            return
        else
            MP.SendChatMessage(player_id, "^l^7 Nickel |^r^o You have been whitelisted")
            return "Player " .. name .. " whitelisted"
        end
    elseif parameter == "remove" then
        if not jsonUser.whitelisted then
            if sender_id ~= "console" then
                MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. name .. " not whitelisted")
                return
            else
                return "Player " .. name .. " not whitelisted"
            end
        end
        updateComplexValueOfUser(player_id, "whitelisted", "bool", false)
        if sender_id ~= "console" then
            MP.SendChatMessage(player_id, "^l^7 Nickel |^r^o You have been unwhitelisted")
            MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Player " .. name .. " unwhitelisted")
            return
        else
            MP.SendChatMessage(player_id, "^l^7 Nickel |^r^o You have been unwhitelisted")
            return "Player " .. name .. " unwhitelisted"
        end
    else
        if sender_id ~= "console" then
            MP.SendChatMessage(sender_id, "^l^7 Nickel |^r^o Usage : whitelist [add/remove] [player]")
            return
        else
            return "Usage : whitelist [add/remove] [player]"
        end
    end
end
, "Add or remove a player from the whitelist")
------------ END OF COMMANDS ------------




------------ START OF EVENTS ------------

function checkForUpdates()
    
    -- Récupérer la version actuelle de votre script local à partir de version.txt
    local oldversion = io.open(VERSIONPATH, "r")
    local localVersion = oldversion:read()


    --retire les deux premier caractères de localVersion (--)
    localVersion = string.sub(localVersion, 3)

    oldversion:close()
    

    --this go to this https://api.github.com/repos/boubouleuh/Nickel-BeamMP-Plugin/releases/latest

    local response = Util.JsonDecode(httpRequest("https://nickel.martadash.fr/version.txt"))

    if response == "" then
        nkprinterror("Get remote version failed to check update !")
        return
    end
    -- Récupérer la version distante à partir de la réponse

    local remoteVersion = response.tag_name

    if remoteVersion == nil then
        nkprinterror("Get remote version failed to check update (Check server probably down) ! Try again later ! If it keep happening ask for help in the discord : https://discord.gg/h5P84FFw7B")
        return
    end

    -- Comparer les versions locales et distantes
    if remoteVersion > localVersion then
        -- Effectuer la mise à jour
        if getConfigValue("AUTOUPDATE") == "false" then

            nkprintwarning("An update is available ! " .. localVersion .. " -> " .. remoteVersion .. "\nAUTOUPDATE is deactivated in " .. CONFIGPATH .. " if you want to update automatically, set it to true")

            return
        else
            local url = "https://raw.githubusercontent.com/boubouleuh/Nickel-BeamMP-Plugin/" .. remoteVersion .. "/main.lua"
            -- Télécharger la dernière version de votre script depuis GitHub
            local response = httpRequest(url)
            --if download fail 
            if response == nil then
                nkprinterror("Update failed !")
                return
            else
                nkprint("Update downloaded !")
            end
            -- Écrire la réponse dans un fichier pour mettre à jour votre script
            local main = io.open(script_path() .. "main.lua", "w")
            main:write(response)
            main:close()
            
            -- Mettre à jour la version locale dans version.txt
            local newversion = io.open(VERSIONPATH, "w")
            newversion:write("--" .. remoteVersion)
            newversion:close()

            nkprint("Update done !")
        end
        
    end

end



function handleConsoleInput(cmd)
    --if message start with PREFIX
    if string.sub(cmd, 1, string.len(PREFIX)) == PREFIX then

        local command = string.match(cmd, "%S+")

        local commandWithoutPrefix = string.sub(command, 2)

        --run function in CommandWIthoutPrefix (its a string name of the function)

        if FUNCTIONSCOMMANDTABLE[commandWithoutPrefix] == nil then
            return
        end

        return CreateCommand("console", cmd, commandWithoutPrefix, true, FUNCTIONSCOMMANDTABLE[commandWithoutPrefix].command)

    end
 end


function onPlayerJoin(player_id)
    -- check if player is staff
    local WELCOMESTAFF = getConfigValue("WELCOMESTAFF")
    local WELCOMEPLAYER = getConfigValue("WELCOMEPLAYER")
    local player_name = MP.GetPlayerName(player_id)
    local is_staff = isStaff(player_id)
    if is_staff and WELCOMESTAFF ~= "" then
        MP.SendChatMessage(-1, "^l^7 Nickel |^r^o  " .. WELCOMESTAFF .. " " .. player_name)
    elseif WELCOMEPLAYER ~= "" then
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
    --init player
    initUser(player_id)



    local player_name = MP.GetPlayerName(player_id)
    local status, player_identifiers = pcall(MP.GetPlayerIdentifiers, player_id)
    if status then
        local user = GetJsonUser(player_id)
        if user.banned.bool then
            MP.DropPlayer(player_id, "You are banned from this server for " .. user.banned.reason)
        
        elseif user.ipbanned.bool then
            MP.DropPlayer(player_id, "You are ip banned from this server for " .. user.ipbanned.reason)

        elseif user.tempbanned.bool then
            if user.tempbanned.time < os.time() then
                updateComplexValueOfUser(player_id, "tempbanned", "bool", false)
                updateComplexValueOfUser(player_id, "tempbanned", "time", 0)
            else
                MP.DropPlayer(player_id, "You are temp banned from this server for " .. user.tempbanned.reason)
            end
        elseif getConfigValue("WHITELIST") == "true" then
                if not user.whitelisted then
                    MP.DropPlayer(player_id, "Whitelist enabled : You are not whitelisted on this server")
                end
        else
            for key, value in pairs(getAllIpBanned()) do
                if value == player_identifiers["ip"] then
                    MP.DropPlayer(player_id, "You are ip banned from this server for " .. user.ipbanned.reason)
                    updateComplexValueOfUser(player_id, "ipbanned", "bool", true)
                    return
                end
            end
        end

    else
        nkprintwarning(player_name .. " has no beammp id, its a guest")
    end
end
    

function MyChatMessageHandler(sender_id, sender_name, message)
    local senderJson = GetJsonUser(sender_id)
    if senderJson ~= nil then

        if senderJson.muted.bool then
                MP.SendChatMessage(sender_id, "You are muted")
                return 1
        elseif senderJson.tempmuted.bool then
            if senderJson.tempmuted.time < os.time() then
                updateComplexValueOfUser(sender_id, "tempmuted", "bool", false)
                updateComplexValueOfUser(sender_id, "tempmuted", "time", 0)
            else
                MP.SendChatMessage(sender_id, "You are temp muted for " .. senderJson.tempmuted.reason)
                return 1
            end
        end
    end
    --if message start with PREFIX
    if string.sub(message, 1, string.len(PREFIX)) == PREFIX then
        --get the first word of message
        local command = string.match(message, "%S+")
        local commandWithoutPrefix = string.sub(command, 2)

        --run function in CommandWIthoutPrefix (its a string name of the function)
        CreateCommand(sender_id, message, commandWithoutPrefix, true, FUNCTIONSCOMMANDTABLE[commandWithoutPrefix].command)
        return -1
    end
end

PINGARRAY = {}

function CheckPing()

    local players = MP.GetPlayers()

    for key, value in pairs(players) do

        print(PINGARRAY)

        local vehicleRaw = MP.GetPlayerVehicles(key)
        if vehicleRaw ~= nil then

         
        
            local vehicleRaw = MP.GetPlayerVehicles(key)
            local vehicle = vehicleRaw[#vehicleRaw] --Get only existing vehicle
            local username, num1, num2 = string.match(vehicle, 'USER:(%w+):(%d+)-(%d+)')

            local Raw = MP.GetPositionRaw(tonumber(num1), tonumber(num2))

            -- print(Raw.ping)

            local Maxping = "0." .. getConfigValue("MAXPING")

            if Raw.ping > tonumber(Maxping) then

                if PINGARRAY[key] == nil then
                    PINGARRAY[key] = 1
                
                else
                    PINGARRAY[key] = PINGARRAY[key] + 1
                end

                if PINGARRAY[key] > tonumber(getConfigValue("PINGTRESHOLD")) then
                    MP.DropPlayer(key, getConfigValue("KICKPINGMSG"))
                end
            elseif Raw.ping <= tonumber(Maxping) / 2 then
                PINGARRAY[key] = 0
            end
        end
    end
end

------------ END OF EVENTS ------------

MP.RegisterEvent("CheckPing", "CheckPing") -- registering our event for the timer
MP.CancelEventTimer("CheckPing")
MP.CreateEventTimer("CheckPing", 1000)

MP.RegisterEvent("onConsoleInput", "handleConsoleInput")
MP.RegisterEvent("onChatMessage", "MyChatMessageHandler")
MP.RegisterEvent("onPlayerJoin", "onPlayerJoin")
MP.RegisterEvent("onPlayerAuth", "onPlayerAuth")
MP.RegisterEvent("onPlayerConnecting", "onPlayerConnecting")
MP.CancelEventTimer("EverySecond")

MP.RegisterEvent("CheckUpdate", "checkForUpdates")
MP.CreateEventTimer("CheckUpdate", 1800000)
