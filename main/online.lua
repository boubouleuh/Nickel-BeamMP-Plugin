local https = {request = function(url)
    local response = ""

    if MP.GetOSName() == "Windows" then
        response = os.execute('powershell -Command "Invoke-WebRequest -Uri ' .. url .. ' -OutFile temp.txt"')
        else
            response = os.execute("wget -q -O temp.txt " .. url)
        end
        
        if response then
            local file = io.open("temp.txt", "rb")
            if not file then
                return "", 404
            end
            local content = file:read("*all")
            file:close()
            os.remove("temp.txt")
            return content, 200
        else
            return "", 404
        end
    end
}

Online = {}

function Online.getPlayerJson(playername)
    
    local url = string.format("https://forum.beammp.com/u/%s.json", playername)
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

function Online.downloadInterface()
    local url = "https://api.github.com/repos/boubouleuh/Nickel-Interface/releases/latest"
    
    local body, code = https.request(url)
    
    if code == 200 then
        local release_data = Util.JsonDecode(body)
                local zip_url = nil
        if release_data and release_data.assets then
            for _, asset in ipairs(release_data.assets) do
                if asset.name:match("%.zip$") then
                    zip_url = asset.browser_download_url
                    break
                end
            end
        end
        
        if not zip_url then
            Utils.nkprint("No ZIP file found in GitHub release", "warn")
            return ""
        end
        
        local zip_body, zip_code = https.request(zip_url)
        
        if zip_code == 200 then
            local file_path = InterfaceChecker.zipPath or "Resources/Client/nickel-interface.zip"
            
            local file = io.open(file_path, "wb")
            if file then
                file:write(zip_body)
                file:close()
                Utils.nkprint("Interface downloaded successfully: " .. file_path, "info")
                return file_path
            end
            InterfaceChecker.CheckForInterfaceMod()
        end
    else
        Utils.nkprint("Failed to fetch GitHub release. Status code: " .. code, "error")
        return ""
    end
end
function Online.getPlayerB64Img(beammpid)

    local file_path = string.format(Utils.script_path() .. "/player_avatars/%s_avatar.png", beammpid)
    local file = io.open(file_path, "rb")

    if file then
        local image = file:read("*all")
        file:close() -- Close the file
        return MIME.b64(image)
    else
        local file_path = string.format(Utils.script_path() .. "/player_avatars/default_avatar.png")
        local file = io.open(file_path, "rb")
        local image = file:read("*all")
        file:close() -- Close the file
        return MIME.b64(image)
    end
end

local function shellEscapeSingleQuotes(str)
    return str:gsub("'", "'\\''")
end

function Online.sendDiscordMessage(webhook, message, username, avatar, embedTitle, embedDescription, color, authorName, authorUrl, authorIcon, footerText, footerIcon)
    local function escape(str)
        return tostring(str or "")
            :gsub('\\', '\\\\')
            :gsub('"', '\\"')
            :gsub('\n', '\\n')
            :gsub('\r', '')
            :gsub('\27', '\\u001b')
    end

    local authorJson = ""
    if authorName then
        authorJson = string.format(
            '"author":{"name":"%s"%s%s},',
            escape(authorName),
            authorUrl and string.format(',"url":"%s"', escape(authorUrl)) or "",
            authorIcon and string.format(',"icon_url":"%s"', escape(authorIcon)) or ""
        )
    end

    local footerJson = ""
    if footerText then
        footerJson = string.format(
            '"footer":{"text":"%s"%s},',
            escape(footerText),
            footerIcon and string.format(',"icon_url":"%s"', escape(footerIcon)) or ""
        )
    end

    local timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")

    local json = string.format(
        '{"content":"%s","username":"%s","avatar_url":"%s","embeds":[{%s%s"title":"%s","description":"%s","color":%d,"timestamp":"%s"}]}',
        escape(message),
        escape(username),
        escape(avatar),
        authorJson,
        footerJson,
        escape(embedTitle),
        escape(embedDescription),
        tonumber(color) or 16777215,
        timestamp
    )

    local escapedJson = shellEscapeSingleQuotes(json)

    local cmd
    if MP.GetOSName() == "Windows" then
        local psJson = json:gsub('"', '""')
        cmd = string.format(
            'powershell -Command "Invoke-WebRequest -Uri \'%s\' -Method Post -Body \\"%s\\" -ContentType \'application/json\'"',
            webhook, psJson
        )
    else
        cmd = string.format(
            "wget -q --header='Content-Type: application/json' --post-data='%s' '%s' -O /dev/null",
            escapedJson, webhook
        )
    end
    local result = os.execute(cmd)
    return result == true or result == 0
end

function Online.savePlayerAvatarImg(playername, size)
    local url = string.format("https://forum.beammp.com/u/%s.json", playername)

    local body, code, headers, status = https.request(url)
    
    -- Check if the request was successful (status code 200)
    if code == 200 then

        local placeholder = "{(.-)}"
        local json = Util.JsonDecode(body)
   
        local url2 = string.format("https://forum.beammp.com/%s", json.user.avatar_template:gsub(placeholder, size))
        local body2, code2, headers2, status2 = https.request(url2)

        if code2 == 200 then
            local file_path = string.format(Utils.script_path() .. "/player_avatars/%s_avatar.png", json.user.id)

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

function Online.getServerIP()

    local url = "https://api.ipify.org/?format=raw"

    local body, code, headers, status = https.request(url)
    
    -- Check if the request was successful (status code 200)
    if code == 200 then
        return body
    else
        print("Failed to get ip. Status code:", code)
    end
end