
local https = require 'ssl.https'

local online = {}

function online.getPlayerJson(playername)

    print("getPlayerJson")
    local url = string.format("https://forum.beammp.com/u/%s.json", playername)

    print(url)
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

return online