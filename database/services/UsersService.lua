

UsersService = {}

function UsersService.new(beammpid)
    local self = {}
    self.beammpid = beammpid
    
    function self:getOrCreateUser(name)
        return DatabaseManager:withConnection(function()
            local user = DatabaseManager:getAllEntry(User, {{"beammpid", self.beammpid}})
            if not user then
                user = User.new(self.beammpid, name or "Unknown")
                DatabaseManager:save(user)
                Utils.nkprint("[UsersService] Created new user: " .. (name or "Unknown") .. " (ID: " .. self.beammpid .. ")", "info")
            elseif name and user.name ~= name then
                user.name = name
                DatabaseManager:save(user)
                Utils.nkprint("[UsersService] Updated user name: " .. name .. " (ID: " .. self.beammpid .. ")", "debug")
            end
            return user
        end)
    end
    
    function self:getUser()
        return DatabaseManager:withConnection(function()
            return DatabaseManager:getAllEntry(User, {{"beammpid", self.beammpid}})
        end)
    end
    
    function self:isBanned()
        return DatabaseManager:withConnection(function()
            local banStatus = DatabaseManager:getAllEntry(UserStatus, {{"beammpid", self.beammpid}, {"status_type", "isbanned"}})
            return banStatus and banStatus.is_status_value
        end)
    end
    
    function self:isTempBanned()
        return DatabaseManager:withConnection(function()
            local tempBanStatus = DatabaseManager:getAllEntry(UserStatus, {{"beammpid", self.beammpid}, {"status_type", "istempbanned"}})
            if tempBanStatus and tempBanStatus.is_status_value then
                local currentTime = os.time()
                if tempBanStatus.expiry_time and currentTime > tempBanStatus.expiry_time then
                    DatabaseManager:delete(UserStatus, {{"id", tempBanStatus.id}})
                    return false
                end
                return true
            end
            return false
        end)
    end
    
    function self:isMuted()
        return DatabaseManager:withConnection(function()
            local muteStatus = DatabaseManager:getAllEntry(UserStatus, {{"beammpid", self.beammpid}, {"status_type", "ismuted"}})
            return muteStatus and muteStatus.is_status_value
        end)
    end
    
    function self:isTempMuted()
        return DatabaseManager:withConnection(function()
            local tempMuteStatus = DatabaseManager:getAllEntry(UserStatus, {{"beammpid", self.beammpid}, {"status_type", "istempmuted"}})
            if tempMuteStatus and tempMuteStatus.is_status_value then
                local currentTime = os.time()
                if tempMuteStatus.expiry_time and currentTime > tempMuteStatus.expiry_time then
                    DatabaseManager:delete(UserStatus, {{"id", tempMuteStatus.id}})
                    return false
                end
                return true
            end
            return false
        end)
    end
    
    function self:isWhitelisted()
        return DatabaseManager:withConnection(function()
            local user = DatabaseManager:getAllEntry(User, {{"beammpid", self.beammpid}})
            return user and Utils.isTruthy(user.whitelisted)
        end)
    end
    
    function self:setWhitelisted(whitelisted)
        return DatabaseManager:withConnection(function()
            local user = DatabaseManager:getAllEntry(User, {{"beammpid", self.beammpid}})
            if user then
                user.whitelisted = whitelisted and 1 or 0
                DatabaseManager:save(user)
                return true
            end
            return false
        end)
    end
    
    function self:setLanguage(language)
        return DatabaseManager:withConnection(function()
            local user = DatabaseManager:getAllEntry(User, {{"beammpid", self.beammpid}})
            if user then
                user.language = language
                DatabaseManager:save(user)
                return true
            end
            return false
        end)
    end
    
    function self:getActiveStatuses()
        return DatabaseManager:withConnection(function()
            local statuses = {}
            local allStatuses = DatabaseManager:getAllEntries(UserStatus, {{"beammpid", self.beammpid}})
            
            for _, status in ipairs(allStatuses) do
                local isActive = status.is_status_value
                if isActive and status.expiry_time and os.time() > status.expiry_time then
                    DatabaseManager:delete(UserStatus, {{"id", status.id}})
                    isActive = false
                end
                
                if isActive then
                    table.insert(statuses, status)
                end
            end
            
            return statuses
        end)
    end
    
    function self:canConnect()
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
    
    function self:isIpBanned()
        local usersIpsService = UsersIpsService.new(self.beammpid)
        return usersIpsService:isIpBanned()
    end

    return self
end

return UsersService