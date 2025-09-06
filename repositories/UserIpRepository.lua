UserIpRepository = {}

function UserIpRepository.findAllByUser(beammpid)
    return DatabaseManager:withConnection(function()
        return DatabaseManager:getAllClassByBeammpId(UserIp, beammpid) or {}
    end)
end

function UserIpRepository.findByUserAndIp(beammpid, ip)
    return DatabaseManager:withConnection(function()
        local conditions = {{"beammpid", beammpid}, {"ip", ip}}
        local ips = DatabaseManager:getAllEntry(UserIp, conditions)
        return ips and #ips > 0 and ips[1] or nil
    end)
end

function UserIpRepository.save(userIp)
    return DatabaseManager:save(userIp, true)
end

function UserIpRepository.delete(beammpid, ip)
    return DatabaseManager:withConnection(function()
        local conditions = {{"beammpid", beammpid}, {"ip", ip}}
        return DatabaseManager:deleteObject(UserIp, conditions)
    end)
end