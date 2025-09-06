
---@class User
---@field tableName string
---@field beammpid number
---@field name string
---@field whitelisted boolean
---@field language string|nil
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
      "name TEXT NOT NULL",
      "whitelisted BOOLEAN NOT NULL",
      "language TEXT"
    }
end

---Find user by BeamMP ID
---@param beammpid number
---@return User|nil
function User.findByBeammpid(beammpid)
    return UserRepository.findByBeammpid(beammpid)
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
    return self.whitelisted
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
function User:getAllIps()
    return UserIpRepository.findAllByUser(self.beammpid)
end

function User:isIpBanned()
    local ips = self:getAllIps()
    if not ips or type(ips) ~= "table" then return false end
    
    for _, ip in ipairs(ips) do
        if ip.is_banned == 1 then
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
        if ip.is_banned == 0 then
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
        if ip.is_banned == 1 then
            ip.is_banned = false
            UserIpRepository.save(ip)
            count = count + 1
        end
    end
    return count
end

-- Permission checks
function User:canConnect()
    if self:isBanned() or self:isTempBanned() then
        return false, "banned"
    end
    
    if self:isIpBanned() then
        return false, "ip_banned"
    end
    
    if ConfigManager.GetSetting("whitelist") and ConfigManager.GetSetting("whitelist").enabled then
        if not self:isWhitelisted() then
            return false, "not_whitelisted"
        end
    end
    
    return true, "allowed"
end

function User:canSpeak()
    return not (self:isMuted() or self:isTempMuted())
end

function User:getActiveStatuses()
    local statuses = {}
    local allStatuses = UserStatusRepository.findAllByUser(self.beammpid)
    
    for _, status in ipairs(allStatuses) do
        local isActive = status.is_status_value
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