
local new = require("objects.New")

local userIps = require("objects.UserIps")


local Service = {}



function Service.new(beammpid, dbManager)
    local self = {}
    self.dbManager = dbManager  -- You can set this to a specific value if needed
    self.beammpid = beammpid
    return new._object(Service, self)
end
  

function Service:getAllIps()
    self.dbManager:openConnection()
    local status = self.dbManager:getAllClassByBeammpId(userIps, self.beammpid)
    self.dbManager:closeConnection()
    return status
end

function Service:banip(ip)
    local ips = self:getAllIps()
    for _, value in ipairs(ips) do
        if value.ip == ip then
            value.is_banned = true
            local result = self.dbManager:save(value, true)
            return result
        end
    end
end

function Service:banAllIps()
    local ips = self:getAllIps()
    local count = 0
    for _, value in ipairs(ips) do
        count = count + 1
        value.is_banned = true
        self.dbManager:save(value, true)
    end
    return count
end


return Service