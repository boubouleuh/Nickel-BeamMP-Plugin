---@class User: ModelInstance, ModelClass
---@field beammpid number
---@field name string
---@field whitelisted boolean
---@field language string?
User = Model{
    __tablename__ = "Users",
    Fields.Integer("beammpid"):PrimaryKey(),
    Fields.String("name"):NotNull(),
    Fields.Boolean("whitelisted"):NotNull():Default(false),
    Fields.String("language")
}

---Create new User instance
---@param beammpid number
---@param name string
---@return User
function User.create(beammpid, name)
  local newUser = User({ beammpid = beammpid, name = name , whitelisted = false, language = nil })
  return newUser
end

---Find user by BeamMP ID
---@param beammpid number
---@return User|nil
function User.findByBeammpid(beammpid)
    return User:find({ beammpid = beammpid })[1]
end

---Find user by name
---@param name string
---@return User|nil
function User.findByName(name)
    return User:find({ name = name })[1]
end

---Get existing user or create new one
---@param beammpid number
---@param name string|nil
---@return User
function User.getOrCreate(beammpid, name)
    local user = User.findByBeammpid(beammpid)
    if user then
        if name and user.name ~= name then
            user.name = name
            user:save()
        end
        return user
    end
    local newUser = User.create(beammpid, name or "Unknown")
    newUser:save()
    return newUser
end

function User:setWhitelisted(whitelisted)
    self.whitelisted = whitelisted
    return self:save()
end

function User:setLanguage(language)
    self.language = language
    return self:save()
end

function User:isWhitelisted()
    return Utils.isTruthy(self.whitelisted)
end

-- Status methods
function User:isStatusExpired(status)
    if not status.expiry_time then
        return false
    end
    
    local currentTime = os.time()
    local expiryTime = status.expiry_time
    
    -- Handle different timestamp formats
    if type(expiryTime) == "string" then
        -- MariaDB/MySQL datetime format: "2024-09-04 12:30:45"
        local year, month, day, hour, min, sec = expiryTime:match("(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
        if year then
            local timeTable = {
                year = tonumber(year) or 0,
                month = tonumber(month) or 1,
                day = tonumber(day) or 1,
                hour = tonumber(hour) or 0,
                min = tonumber(min) or 0,
                sec = tonumber(sec) or 0
            }
            expiryTime = os.time(timeTable)
        else
            -- Try ISO format: "2024-09-04T12:30:45"
            year, month, day, hour, min, sec = expiryTime:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)")
            if year then
                local timeTable = {
                    year = tonumber(year) or 0,
                    month = tonumber(month) or 1,
                    day = tonumber(day) or 1,
                    hour = tonumber(hour) or 0,
                    min = tonumber(min) or 0,
                    sec = tonumber(sec) or 0
                }
                expiryTime = os.time(timeTable)
            else
                -- If we can't parse, assume it's already expired to be safe
                return true
            end
        end
    elseif type(expiryTime) == "number" then
        -- SQLite unix timestamp - use as is
        -- No conversion needed
    else
        -- Unknown format, assume expired to be safe
        return true
    end
    
    return currentTime > expiryTime
end

function User:hasStatus(statusType)
    local status = UserStatus:where("beammpid", "=", self.beammpid)
        :where("status_type", "=", statusType)
        :where("is_status_value", "=", true):get()[1]
    if not status then
        return false
    end
    
    if self:isStatusExpired(status) then
        self:deactivateStatus(statusType)
        return false
    end
    
    return true
end

function User:addStatus(statusType, reason, expiryTime)
    local status = UserStatus:where("beammpid", "=", self.beammpid)
        :where("status_type", "=", statusType):get()[1]
    if not status then
        status = UserStatus.create(self.beammpid, statusType, true, reason, expiryTime)
    else
        status.is_status_value = true
        status.reason = reason or ""
        status.expiry_time = expiryTime
    end
    return status:save()
end

function User:removeStatus(statusType)
    local statuses = UserStatus:where("beammpid", "=", self.beammpid)
        :where("status_type", "=", statusType):get()
    local success = true
    for _, status in ipairs(statuses) do
        local deleted = status:delete()
        success = deleted and success
    end
    return success
end

function User:deactivateStatus(statusType)
    local statuses = UserStatus:where("beammpid", "=", self.beammpid)
        :where("status_type", "=", statusType):get()
    local success = true
    for _, status in ipairs(statuses) do
        status.is_status_value = false
        local saved = status:save()
        success = saved and success
    end
    return success
end

function User:getStatus(statusType)
    return UserStatus:where("beammpid", "=", self.beammpid)
        :where("status_type", "=", statusType):get()[1]
end

function User:getAllStatuses()
    return UserStatus:where("beammpid", "=", self.beammpid):get()
end

-- High-level status checks
function User:isBanned()
    return self:hasStatus("isbanned")
end

function User:isTempBanned()
    return self:hasStatus("istempbanned")
end

function User:isMuted()
    return self:hasStatus("ismuted")
end

function User:isTempMuted()
    return self:hasStatus("istempmuted")
end

function User:ban(reason)
    return self:addStatus("isbanned", reason)
end

function User:tempBan(reason, expiryTime)
    return self:addStatus("istempbanned", reason, expiryTime)
end

function User:unban()
    self:deactivateStatus("isbanned")
    self:deactivateStatus("istempbanned")
    return true  -- Always return true as operations completed
end

function User:mute(reason)
    return self:addStatus("ismuted", reason)
end

function User:tempMute(reason, expiryTime)
    return self:addStatus("istempmuted", reason, expiryTime)
end

function User:unmute()
    self:deactivateStatus("ismuted")
    self:deactivateStatus("istempmuted")
    return true  -- Always return true as operations completed
end

-- IP methods

function User:addIp(ip)
    local existingIp = UserIp:where("beammpid", "=", self.beammpid)
        :where("ip", "=", ip):get()[1]
    if existingIp then
        return
    end
    
    local newUserIp = UserIp.create(self.beammpid, ip)
    return newUserIp:save()
end

function User:getAllIps()
    return UserIp:where("beammpid", "=", self.beammpid):get()
end

function User:isIpBanned()
    local ips = self:getAllIps()
    if not ips or type(ips) ~= "table" then return false end
    
    for _, ip in ipairs(ips) do
        if Utils.isTruthy(ip.is_banned) then
            return true
        end
    end
    return false
end

function User:banAllIps()
    local ips = self:getAllIps()
    if not ips or type(ips) ~= "table" then return 0 end
    
    local count = 0
    for _, ip in ipairs(ips) do
        if not Utils.isTruthy(ip.is_banned) then
            ip.is_banned = true
            ip:save()
            count = count + 1
        end
    end
    return count
end

function User:unbanAllIps()
    local ips = self:getAllIps()
    if not ips or type(ips) ~= "table" then return 0 end
    
    local count = 0
    for _, ip in ipairs(ips) do
        if Utils.isTruthy(ip.is_banned) then
            ip.is_banned = false
            ip:save()
            count = count + 1
        end
    end
    return count
end

-- Permission checks
function User:canConnect()
    if self:isTempBanned() then
        local status = self:getStatus("istempbanned")
        return false, "banned", status and status.reason or "Temporarily banned"
    end

    if self:isBanned() then
        local status = self:getStatus("isbanned")
        return false, "banned", status and status.reason or "Banned"
    end
    
    if self:isIpBanned() then
        return false, "ip_banned", "Your IP address is banned from this server"
    end
    
    if ConfigManager.GetSetting("conditions").whitelist then
        if not self:isWhitelisted() then
            return false, "not_whitelisted", MessagesManager:GetMessage(-1, "conditions.whitelist_required")
        end
    end
    
    return true, "allowed", nil
end

function User:canSpeak()
    return not (self:isMuted() or self:isTempMuted())
end

function User:getActiveStatuses()
    local statuses = {}
    local allStatuses = self:getAllStatuses()
    
    for _, status in ipairs(allStatuses) do
        local isActive = Utils.isTruthy(status.is_status_value)
        if isActive and self:isStatusExpired(status) then
            self:deactivateStatus(status.status_type)
            isActive = false
        end
        
        if isActive then
            table.insert(statuses, status)
        end
    end
    
    return statuses
end

-- Role management methods
function User:getRoles()
    local roles = {}
    local userRoles = UserRole:where("beammpid", "=", self.beammpid):get()
    for _, userRole in ipairs(userRoles) do
        local role = Role:where("roleID", "=", userRole.roleID):get()[1]
        if role then
            table.insert(roles, role)
        end
    end
    return roles
end

function User:assignRole(rolename)
    local role = Role:where("roleName", "=", rolename):get()[1]
    if not role then
        return "commands.grantrole.role_not_found"
    end
    
    local existingUserRole = UserRole:where("beammpid", "=", self.beammpid)
        :where("roleID", "=", role.roleID):get()[1]
    if existingUserRole then
        return "commands.grantrole.already_has_role"
    end
    
    local newUserRole = UserRole.create(self.beammpid, role.roleID)
    return newUserRole:save()
end

function User:unassignRole(rolename)
    local role = Role:where("roleName", "=", rolename):get()[1]
    if not role then
        return "commands.grantrole.role_not_found"
    end
    
    if Utils.isTruthy(role.is_default) then
        return "commands.grantrole.cannot_unassign_default_role"
    end
    
    local userRole = UserRole:where("beammpid", "=", self.beammpid)
        :where("roleID", "=", role.roleID):get()[1]
    return userRole and userRole:delete() or false
end

function User:getHighestRole()
    local roles = self:getRoles()
    local highestRole = nil
    for _, role in ipairs(roles) do
        if highestRole == nil or role.permlvl > highestRole.permlvl then
            highestRole = role
        end
    end
    return highestRole
end

function User:getCommands()
    local commands = {}
    local allCommands = Command:all()
    
    for _, command in ipairs(allCommands) do
        if self:hasPermission(command.commandName) then
            table.insert(commands, command)
        end
    end
    return commands
end

function User:getActions()
    local actions = {}
    local allActions = Action:all()
    
    for _, action in ipairs(allActions) do
        if self:hasPermissionForAction(action.actionName) then
            table.insert(actions, action)
        end
    end
    return actions
end

function User:hasPermission(commandname)
    if self.beammpid == -2 then
        return true  -- Console has full permission
    end

    local userRoles = self:getRoles()
    if not userRoles or #userRoles == 0 then
        return false
    end

    local command = Command:where("commandName", "=", commandname):get()[1]
    if not command then
        return false
    end

    -- Check direct role-command permissions
    for _, userRole in ipairs(userRoles) do
        local roleCommandEntries = RoleCommand:where("roleID", "=", userRole.roleID)
            :where("commandID", "=", command.commandID):get()
        if #roleCommandEntries > 0 then
            return true
        end
    end

    -- Check inherited permissions from lower permission levels
    for _, userRole in ipairs(userRoles) do
        local role = Role:where("roleID", "=", userRole.roleID):get()[1]
        local lowerPermissions = role and tonumber(role.permlvl) - 1 or 0

        while lowerPermissions >= 0 do
            local lowerRole = Role:where("permlvl", "=", lowerPermissions):get()[1]
            if lowerRole then
                local lowerRoleCommandEntries = RoleCommand:where("roleID", "=", lowerRole.roleID)
                    :where("commandID", "=", command.commandID):get()
                if #lowerRoleCommandEntries > 0 then
                    return true
                end
            end
            lowerPermissions = lowerPermissions - 1
        end
    end
    
    return false
end

function User:hasPermissionForAction(actionName)
    if self.beammpid == -2 then
        return true  -- Console has full permission
    end

    local userRoles = self:getRoles()
    if not userRoles or #userRoles == 0 then
        return false
    end

    local action = Action:where("actionName", "=", actionName):get()[1]
    if not action then
        return false
    end

    -- Check direct role-action permissions
    for _, userRole in ipairs(userRoles) do
        local roleActionEntries = RoleAction:where("roleID", "=", userRole.roleID)
            :where("actionID", "=", action.actionID):get()
        if #roleActionEntries > 0 then
            return true
        end
    end

    -- Check inherited permissions from lower permission levels
    for _, userRole in ipairs(userRoles) do
        local role = Role:where("roleID", "=", userRole.roleID):get()[1]
        local lowerPermissions = role and tonumber(role.permlvl) - 1 or 0

        while lowerPermissions >= 0 do
            local lowerRole = Role:where("permlvl", "=", lowerPermissions):get()[1]
            if lowerRole then
                local lowerRoleActionEntries = RoleAction:where("roleID", "=", lowerRole.roleID)
                    :where("actionID", "=", action.actionID):get()
                if #lowerRoleActionEntries > 0 then
                    return true
                end
            end
            lowerPermissions = lowerPermissions - 1
        end
    end
    
    return false
end

-- Administrative role management (instance methods)
function User:canManageRole(rolename)
    local managerRoles = self:getRoles()
    if #managerRoles == 0 then
        return false
    end

    local role = Role:where("roleName", "=", rolename):get()[1]
    if not role then
        return false
    end

    for _, managerRole in ipairs(managerRoles) do
        if managerRole.permlvl > role.permlvl then
            return true
        end
    end
    return false
end

function User:canManage(managed_beammpid)
    local managed = User.findByBeammpid(managed_beammpid)
    
    if not managed then
        return false
    end
    
    local managerRoles = self:getRoles()
    local managedRoles = managed:getRoles()
    
    if #managerRoles == 0 or #managedRoles == 0 then
        return false
    end

    local maxManagedRoleLevel = 0
    for _, managedRole in ipairs(managedRoles) do
        if managedRole.permlvl > maxManagedRoleLevel then
            maxManagedRoleLevel = managedRole.permlvl
        end
    end

    for _, managerRole in ipairs(managerRoles) do
        if managerRole.permlvl > maxManagedRoleLevel then
            return true
        end
    end

    return false
end