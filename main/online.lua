
local https = require 'ssl.https'
local mime = require("mime")
local utils = require("utils.misc")
local online = {}

function online.getPlayerJson(playername)

    local url = string.format("https://forum.beammp.com/u/%s.json", playername)

    local body, code, headers, status = https.request(url)
    
    -- Check if the request was successful (status code 200)
    if code == 200 then
        -- Access the content of the response
        local json = Util.JsonDecode(body)
        return json
    else
        print("Failed to get player data. Status code:", code)
    end
end

function online.getPlayerB64Img(beammpid)

    local file_path = string.format(utils.script_path() .. "/player_avatars/%s_avatar.png", beammpid)
    local file = io.open(file_path, "r")

    if file then
        local image = file:read("*all")
        file:close() -- Close the file
        return mime.b64(image)
    else
        local file_path = string.format(utils.script_path() .. "/player_avatars/default_avatar.png")
        local file = io.open(file_path, "r")
        local image = file:read("*all")
        file:close() -- Close the file
        return mime.b64(image)
    end
end

function online.savePlayerAvatarImg(playername, size)
    local url = string.format("https://forum.beammp.com/u/%s.json", playername)

    local body, code, headers, status = https.request(url)
    
    -- Check if the request was successful (status code 200)
    if code == 200 then

        local placeholder = "{(.-)}"
        local json = Util.JsonDecode(body)
   
        local url2 = string.format("https://forum.beammp.com/%s", json.user.avatar_template:gsub(placeholder, size))
        local body2, code2, headers2, status2 = https.request(url2)

        if code2 == 200 then
            local file_path = string.format(utils.script_path() .. "/player_avatars/%s_avatar.png", json.user.id)

            -- Open the file in binary write mode
            local file = io.open(file_path, "wb")
            if file then
                file:write(body2) -- Write the image data to the file
                file:close() -- Close the file
                return file_path -- Return the file path of the saved image
            else
                return "" -- Return an empty string if the file couldn't be opened
            end
        else
            return ""    
        end

        
    else
        return ""
    end
end

function online.getServerIP()

    local url = "https://api.ipify.org/?format=raw"

    local body, code, headers, status = https.request(url)
    
    -- Check if the request was successful (status code 200)
    if code == 200 then
        return body
    else
        print("Failed to get ip. Status code:", code)
    end
end
return online