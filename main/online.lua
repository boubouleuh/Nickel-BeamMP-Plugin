local utils = require("utils.misc")
local success, module = pcall(require, 'ssl.https')
local https = nil
if success then
    https = module
else
    https = {request = function(url)
        local response = ""
        
        if MP.GetOSName() == "Windows" then
            response = os.execute('powershell -Command "Invoke-WebRequest -Uri ' .. url .. ' -OutFile temp.txt"')
        else
            response = os.execute("wget -q -O temp.txt " .. url)
        end
        
        if response then
            local file = io.open("temp.txt", "r")
            local content = file:read("*all")
            file:close()
            os.remove("temp.txt")
            return content, 200
        else
            return "", 404
        end
    end}
end



local mime = require("mime")
local online = {}

function online.getPlayerJson(playername)
    
    local url = string.format("https://forum.beammp.com/u/%s.json", playername)
    print(url)
    local body, code = https.request(url)
    
    -- Check if the request was successful (status code 200)
    if code == 200 then
        -- Access the content of the response
        local json = Util.JsonDecode(body)
        return json
    else
        print("Failed to get player data. Status code:", code)
        return nil
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