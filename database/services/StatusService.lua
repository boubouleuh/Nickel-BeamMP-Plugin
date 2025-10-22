StatusService = {}

function StatusService.hasActiveStatus(beammpid, statusType)
    if not DatabaseManager then return false end
    
    return DatabaseManager:withConnection(function()
        local status = DatabaseManager:getAllEntry(UserStatus, {{"beammpid", beammpid}, {"status_type", statusType}})
        if not status or not status.is_status_value then
            return false
        end
        
        -- Check expiry for temporary statuses
        if status.expiry_time and os.time() > status.expiry_time then
            DatabaseManager:delete(UserStatus, {{"id", status.id}})
            return false
        end
        
        return true
    end)
end

function StatusService.isPlayerBanned(beammpid)
    return StatusService.hasActiveStatus(beammpid, "isbanned")
end

function StatusService.isPlayerTempBanned(beammpid)
    return StatusService.hasActiveStatus(beammpid, "istempbanned")
end

function StatusService.isPlayerMuted(beammpid)
    return StatusService.hasActiveStatus(beammpid, "ismuted")
end

function StatusService.isPlayerTempMuted(beammpid)
    return StatusService.hasActiveStatus(beammpid, "istempmuted")
end

function StatusService.getStatusReason(beammpid, statusType)
    if not DatabaseManager then return nil end
    
    return DatabaseManager:withConnection(function()
        local status = DatabaseManager:getAllEntry(UserStatus, {{"beammpid", beammpid}, {"status_type", statusType}})
        return status and status.reason or nil
    end)
end

function StatusService.canPlayerSpeak(beammpid)
    return not (StatusService.isPlayerMuted(beammpid) or StatusService.isPlayerTempMuted(beammpid))
end

function StatusService.canPlayerConnect(beammpid)
    return not (StatusService.isPlayerBanned(beammpid) or StatusService.isPlayerTempBanned(beammpid))
end

function StatusService.createStatus(beammpid, status_type, reason, expiry_time)
    local statusEntry = UserStatus.new(beammpid, status_type, true, reason, expiry_time)
    return DatabaseManager:withConnection(function()
        return DatabaseManager:save(statusEntry, false)
    end)
end

function StatusService.removeStatus(beammpid, status_type)
    return DatabaseManager:withConnection(function()
        local conditions = {{"beammpid", beammpid}, {"status_type", status_type}}
        return DatabaseManager:delete(UserStatus, conditions)
    end)
end

function StatusService.getStatusDetails(beammpid, status_type)
    return DatabaseManager:withConnection(function()
        return DatabaseManager:getAllEntry(UserStatus, {{"beammpid", beammpid}, {"status_type", status_type}})
    end)
end

