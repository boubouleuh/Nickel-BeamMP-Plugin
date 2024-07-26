
local https = require 'ssl.https'
local mime = require("mime")

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

function online.getPlayerB64Img(playername, size)

    local url = string.format("https://forum.beammp.com/u/%s.json", playername)

    local body, code, headers, status = https.request(url)
    
    -- Check if the request was successful (status code 200)
    if code == 200 then

        local placeholder = "{(.-)}"
        local json = Util.JsonDecode(body)
   
        local url2 = string.format("https://forum.beammp.com/%s", json.user.avatar_template:gsub(placeholder, size))
        local body2, code2, headers2, status2 = https.request(url2)

        if code2 == 200 then
            return mime.b64(body2)
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