local command = RegisterCommand("cemigrate")
command.consoleOnly = true
function command.init(sender_id, sender_name)
    Utils.nkprint("Starting Cobalt migration...", "info")
    local dataPath = Utils.script_path() .. "data/playerPermissions.json"
    
    if not FS.Exists(dataPath) then
        Utils.nkprint("playerPermissions.json not found at: " .. dataPath, "error")
        MessagesManager:SendMessage(sender_id, "Migration failed: File not found.")
        return false
    end

    local f = io.open(dataPath, "r")
    if not f then return false end
    local content = f:read("*a")
    f:close()
    
    local data = Util.JsonDecode(content)

    -- Monkey patch DatabaseManager
    local originalClose = DatabaseManager.closeConnection
    DatabaseManager.closeConnection = function() end
    DatabaseManager:openConnection()
    local db = DatabaseManager.db
    if db and db.exec then db:exec("BEGIN TRANSACTION") end

    local count = 0
    local skipped = 0
    local total = 0
    
    for key, _ in pairs(data) do 
        if not key:match("^group:") then
            total = total + 1 
        end
    end
    Utils.nkprint("Found " .. total .. " users to process.", "info")

    for key, userData in pairs(data) do
        if not key:match("^group:") then
            local name = key
            local beammpid = nil
            

            -- Try to find in DB first
            local existingUser = DatabaseManager:getEntry(User, "name", name)
            if existingUser then
                beammpid = existingUser.beammpid
            else
                -- slow
                local id = Utils.getPlayerBeamMPID(name)
                if id and id ~= -1 then
                    beammpid = id
                end
            end
           

            if not beammpid then
                 skipped = skipped + 1
            else
                local user = User.getOrCreate(beammpid, name)
                
                if userData.whitelisted ~= nil then
                    user.whitelisted = userData.whitelisted
                end

                if userData.banned then
                    user:ban(userData.banReason or "Imported Ban")
                end
                if userData.muted then
                    user:mute("Imported Mute")
                end
                
                user:save()
                count = count + 1
                if count % 10 == 0 then
                    Utils.nkprint("Migrated " .. count .. "/" .. total .. " users...", "info")
                end
            end
        end
    end

    if db and db.exec then db:exec("COMMIT") end
    DatabaseManager.closeConnection = originalClose
    DatabaseManager:closeConnection()

    Utils.nkprint("Migration finished. Migrated: " .. count .. ", Skipped (no ID): " .. skipped, "info")
    MessagesManager:SendMessage(sender_id, "Cobalt Migration finished. Migrated: " .. count .. ", Skipped: " .. skipped)
    return true
end
