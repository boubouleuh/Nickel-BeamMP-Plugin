UserRepository = {}

---Find user by BeamMP ID
---@param beammpid number
---@return User|nil
function UserRepository.findByBeammpid(beammpid)
    return DatabaseManager:withConnection(function()
        local user = DatabaseManager:getClassByBeammpId(User, beammpid)
        if user then
            return user
        end
        return nil
    end)
end

---Find user by name
---@param name string
---@return User|nil
function UserRepository.findByName(name)
    return DatabaseManager:withConnection(function()
        local userData = DatabaseManager:getEntry(User, "name", name)
        if userData then
            return DatabaseManager:mapRowToClass(User, userData)
        end
        return nil
    end)
end

---Find all users
function UserRepository.findAll()
    return DatabaseManager:withConnection(function()
        return DatabaseManager:getAllEntry(User)
    end)
end

--Find all whitelisted users
function UserRepository.findAllWhitelisted()
    return DatabaseManager:withConnection(function()
        return DatabaseManager:getAllEntry(User, {{whitelisted = true}})
    end)
end

---Save user to database
---@param user User
---@return boolean
function UserRepository.save(user)
    return DatabaseManager:save(user, true)
end

---Delete user by BeamMP ID
---@param beammpid number
---@return boolean
function UserRepository.delete(beammpid)
    return DatabaseManager:withConnection(function()
        return DatabaseManager:deleteObject(User, {{"beammpid", beammpid}})
    end)
end

---Check if user exists
---@param beammpid number
---@return boolean
function UserRepository.exists(beammpid)
    return DatabaseManager:withConnection(function()
        local userData = DatabaseManager:getEntry(User, "beammpid", beammpid)
        return userData ~= nil
    end)
end

---Get existing user or create new one (optimized single transaction)
---@param beammpid number
---@param name string|nil
---@return User
function UserRepository.getOrCreate(beammpid, name)
    -- Try to get existing user first
    local user = DatabaseManager:withConnection(function()
        return DatabaseManager:getClassByBeammpId(User, beammpid)
    end)
    
    if user then
        -- User exists, check if name needs update
        if name and user.name ~= name then
            user.name = name
            DatabaseManager:save(user, true)  -- save handles its own connection
            Utils.nkprint("[User] Updated user name: " .. name .. " (ID: " .. beammpid .. ")", "debug")
        end
        return user
    else
        -- User doesn't exist, create new one
        local newUser = User.new(beammpid, name or "Unknown")
        DatabaseManager:save(newUser, true)  -- save handles its own connection
        Utils.nkprint("[User] Created new user: " .. (name or "Unknown") .. " (ID: " .. beammpid .. ")", "info")
        return newUser
    end
end