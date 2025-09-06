UserStatusRepository = {}

-- Helper function to normalize boolean values for database queries
local function normalizeBoolean(value)
    if value == true or value == "true" or value == 1 or value == "1" then
        return 1
    elseif value == false or value == "false" or value == 0 or value == "0" then
        return 0
    else
        return value  -- Return as-is if not a recognizable boolean
    end
end

function UserStatusRepository.findByUserAndType(beammpid, statusType)
    return DatabaseManager:withConnection(function()
        local conditions = {{"beammpid", beammpid}, {"status_type", statusType}}
        local statuses = DatabaseManager:getAllEntry(UserStatus, conditions)
        return statuses and #statuses > 0 and statuses[1] or nil
    end)
end

function UserStatusRepository.findActiveByUserAndType(beammpid, statusType)
    return DatabaseManager:withConnection(function()
        local conditions = {{"beammpid", beammpid}, {"status_type", statusType}, {"is_status_value", normalizeBoolean(true)}}
        local statuses = DatabaseManager:getAllEntry(UserStatus, conditions)
        -- Return the most recent active status (assuming they're ordered by creation)
        return statuses and #statuses > 0 and statuses[#statuses] or nil
    end)
end

function UserStatusRepository.findAllByUser(beammpid)
    return DatabaseManager:withConnection(function()
        return DatabaseManager:getAllEntry(UserStatus, {{"beammpid", beammpid}}) or {}
    end)
end

function UserStatusRepository.save(userStatus)
    return DatabaseManager:save(userStatus, true)
end

function UserStatusRepository.deleteByUserAndType(beammpid, statusType)
    return DatabaseManager:withConnection(function()
        local conditions = {{"beammpid", beammpid}, {"status_type", statusType}}
        return DatabaseManager:deleteObject(UserStatus, conditions)
    end)
end

function UserStatusRepository.deleteById(statusId)
    return DatabaseManager:withConnection(function()
        return DatabaseManager:deleteObject(UserStatus, {{"id", statusId}})
    end)
end

function UserStatusRepository.deactivateByUserAndType(beammpid, statusType)
    return DatabaseManager:withConnection(function()
        local conditions = {{"beammpid", beammpid}, {"status_type", statusType}, {"is_status_value", normalizeBoolean(true)}}
        local activeStatuses = DatabaseManager:getAllEntry(UserStatus, conditions)
        
        local deactivated = false
        if activeStatuses and #activeStatuses > 0 then
            for _, status in ipairs(activeStatuses) do
                status.is_status_value = normalizeBoolean(false)
                -- Don't use save here as it would create nested connections
                DatabaseManager:insertOrUpdateObject(status.tableName, status, true)
                deactivated = true
            end
        end
        return deactivated
    end)
end