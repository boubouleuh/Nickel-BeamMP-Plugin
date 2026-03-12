---@class User
User = {}
User.tableName = "Users"

---Create new User instance
---@param beammpid number
---@param name string
---@return User
function User.new(beammpid, name)
  local self = {}
  setmetatable(self, {__index = User})
  self.tableName = User.tableName
  self.beammpid = beammpid or 0
  self.name = name or ""
  self.whitelisted = false
  self.language = nil
  return self
end

function User.getColumns()
    return {
      "beammpid INTEGER PRIMARY KEY",
      "name VARCHAR(191) NOT NULL",
      "whitelisted BOOLEAN NOT NULL",
      "language VARCHAR(191)"
    }
end

---Find user by BeamMP ID
---@param beammpid number
---@return User|nil
function User.findByBeammpid(beammpid)
    return UserRepository.findByBeammpid(beammpid)
end

---Find user by name
---@param name string
---@return User|nil
function User.findByName(name)
    return UserRepository.findByName(name)
end

---Get existing user or create new one
---@param beammpid number
---@param name string|nil
---@return User
function User.getOrCreate(beammpid, name)
    return UserRepository.getOrCreate(beammpid, name)
end

-- Instance methods
---Save user to database
---@return boolean
function User:save()
    return UserRepository.save(self)
end

---Delete user from database
---@return boolean
function User:delete()
    return UserRepository.delete(self.beammpid)
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
    local status = UserStatusRepository.findActiveByUserAndType(self.beammpid, statusType)
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
    local status = UserStatus.new(self.beammpid, statusType, true, reason, expiryTime)
    return UserStatusRepository.save(status)
end

function User:removeStatus(statusType)
    return UserStatusRepository.deleteByUserAndType(self.beammpid, statusType)
end

function User:deactivateStatus(statusType)
    return UserStatusRepository.deactivateByUserAndType(self.beammpid, statusType)
end

function User:getStatus(statusType)
    return UserStatusRepository.findByUserAndType(self.beammpid, statusType)
end

function User:getAllStatuses()
    return UserStatusRepository.findAllByUser(self.beammpid)
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
    local existingIp = UserIpRepository.findByUserAndIp(self.beammpid, ip)
    if existingIp then
        return
    end
    
    local newUserIp = UserIp.new(self.beammpid, ip)
    return UserIpRepository.save(newUserIp)
end

function User:getAllIps()
    return UserIpRepository.findAllByUser(self.beammpid)
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
            UserIpRepository.save(ip)
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
            UserIpRepository.save(ip)
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
    local allStatuses = UserStatusRepository.findAllByUser(self.beammpid)
    
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
    return UserRoleRepository.getUserRolesWithDetails(self.beammpid)
end

function User:assignRole(rolename)
    local role = RoleRepository.findByName(rolename)
    if not role then
        return "commands.grantrole.role_not_found"
    end
    
    local existingUserRole = UserRoleRepository.findByBeammpidAndRoleId(self.beammpid, role.roleID)
    if existingUserRole and #existingUserRole > 0 then
        return "commands.grantrole.already_has_role"
    end
    
    local newUserRole = UserRole.new(self.beammpid, role.roleID)
    return UserRoleRepository.save(newUserRole)
end

function User:unassignRole(rolename)
    local role = RoleRepository.findByName(rolename)
    if not role then
        return "commands.grantrole.role_not_found"
    end
    
    if role.is_default == 1 then
        return "commands.grantrole.cannot_unassign_default_role"
    end
    
    return UserRoleRepository.deleteByBeammpidAndRoleId(self.beammpid, role.roleID)
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
    local allCommands = CommandRepository.findAll()
    
    for _, command in ipairs(allCommands) do
        if self:hasPermission(command.commandName) then
            table.insert(commands, command)
        end
    end
    return commands
end

function User:getActions()
    local actions = {}
    local allActions = ActionRepository.findAll()
    
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

    local command = CommandRepository.findByName(commandname)
    if not command then
        return false
    end

    -- Check direct role-command permissions
    for _, userRole in ipairs(userRoles) do
        local roleCommandEntries = RoleCommandRepository.findByRoleAndCommand(userRole.roleID, command.commandID)
        if #roleCommandEntries > 0 then
            return true
        end
    end

    -- Check inherited permissions from lower permission levels
    for _, userRole in ipairs(userRoles) do
        local role = RoleRepository.findById(userRole.roleID)
        local lowerPermissions = role and tonumber(role.permlvl) - 1 or 0

        while lowerPermissions >= 0 do
            local lowerRole = RoleRepository.findByPermissionLevel(lowerPermissions)
            if lowerRole then
                local lowerRoleCommandEntries = RoleCommandRepository.findByRoleAndCommand(lowerRole.roleID, command.commandID)
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

    local action = ActionRepository.findByName(actionName)
    if not action then
        return false
    end

    -- Check direct role-action permissions
    for _, userRole in ipairs(userRoles) do
        local roleActionEntries = RoleActionRepository.findByRoleAndAction(userRole.roleID, action.actionID)
        if #roleActionEntries > 0 then
            return true
        end
    end

    -- Check inherited permissions from lower permission levels
    for _, userRole in ipairs(userRoles) do
        local role = RoleRepository.findById(userRole.roleID)
        local lowerPermissions = role and tonumber(role.permlvl) - 1 or 0

        while lowerPermissions >= 0 do
            local lowerRole = RoleRepository.findByPermissionLevel(lowerPermissions)
            if lowerRole then
                local lowerRoleActionEntries = RoleActionRepository.findByRoleAndAction(lowerRole.roleID, action.actionID)
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

    local role = RoleRepository.findByName(rolename)
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