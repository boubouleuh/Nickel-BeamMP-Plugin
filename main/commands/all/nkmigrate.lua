local command = RegisterCommand("nkmigrate")
command.consoleOnly = true

--- command
function command.init(sender_id, sender_name)
    Utils.nkprint("Starting migration from old Nickel...", "info")
    local oldDataPath = Utils.script_path() .. "data/"
    
    if not FS.Exists(oldDataPath) then
        Utils.nkprint("Old data directory not found at: " .. oldDataPath, "error")
        MessagesManager:SendMessage(sender_id, "Migration failed: Old data directory not found.")
        return false
    end

    -- Monkey patch DatabaseManager to prevent closing connection during transaction
    local originalClose = DatabaseManager.closeConnection
    DatabaseManager.closeConnection = function() end

    DatabaseManager:openConnection()
    
    local db = DatabaseManager.db
    if db and db.exec then
        db:exec("BEGIN TRANSACTION")
    end

    local usersPath = oldDataPath .. "users/"
    local files = FS.ListFiles(usersPath)
    
    if files then
        local totalFiles = 0
        for _, filename in ipairs(files) do
            if filename:match("%.json$") then
                totalFiles = totalFiles + 1
            end
        end
        Utils.nkprint("Found " .. totalFiles .. " user files to migrate.", "info")

        local count = 0
        for _, filename in ipairs(files) do
            if filename:match("%.json$") then
                local f = io.open(usersPath .. filename, "r")
                if f then
                    local content = f:read("*a")
                    f:close()
                    local userData = Util.JsonDecode(content)

                    if userData and userData.beammpid then
                        local user = User.getOrCreate(userData.beammpid, userData.name)
                        if userData.whitelisted ~= nil then
                            user.whitelisted = userData.whitelisted
                        end
                        user:save()

                        if userData.banned and userData.banned.bool then
                            user:ban(userData.banned.reason or "Imported Ban")
                        end
                        if userData.muted and userData.muted.bool then
                            user:mute(userData.muted.reason or "Imported Mute")
                        end
                        if userData.tempbanned and userData.tempbanned.bool then
                            user:tempBan(userData.tempbanned.reason or "Imported TempBan", userData.tempbanned.time)
                        end
                        if userData.tempmuted and userData.tempmuted.bool then
                            user:tempMute(userData.tempmuted.reason or "Imported TempMute", userData.tempmuted.time)
                        end
                        if userData.ip then
                            user:addIp(userData.ip)
                        end
                        if userData.ipbanned and userData.ipbanned.bool then
                            user:banAllIps()
                        end
                        count = count + 1
                        if count % 50 == 0 or count == totalFiles then
                             Utils.nkprint("Migrated " .. count .. "/" .. totalFiles .. " users...", "info")
                        end
                    end
                end
            end
        end
        
        if db and db.exec then
            db:exec("COMMIT")
        end

        Utils.nkprint("Migrated " .. count .. " users.", "info")
        MessagesManager:SendMessage(sender_id, "Migration completed. Migrated " .. count .. " users.")
    else
        if db and db.exec then
            db:exec("COMMIT")
        end
        Utils.nkprint("No users directory found.", "warn")
        MessagesManager:SendMessage(sender_id, "Migration completed (no users found).")
    end

    -- Restore DatabaseManager
    DatabaseManager.closeConnection = originalClose
    DatabaseManager:closeConnection()

    return true
end
