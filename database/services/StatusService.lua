
local new = require("objects.New")

local userStatus = require("objects.UserStatus")


---@class StatusService
local Service = {}



function Service.new(beammpid, dbManager)
    local self = {}
    self.dbManager = dbManager  -- You can set this to a specific value if needed
    self.beammpid = beammpid
    return new._object(Service, self)
end
  

function Service:getAllStatus()
    self.dbManager:openConnection()
    local status = self.dbManager:getAllClassByBeammpId(userStatus, self.beammpid)
    self.dbManager:closeConnection()
    return status
end

function Service:getStatus(status_type)
    local status = self:getAllStatus()
    for _, value in ipairs(status) do
        if value.status_type == status_type then
            return value
        end
    end
end

function Service:checkStatus(status_type)
    local status = self:getAllStatus()
    
    for _, value in ipairs(status) do
        if value.status_type == status_type and value.is_status_value == 1 then
            return true
        end
    end
    return false
end


function Service:removeStatus(status_type)
    self.dbManager:openConnection()
  
    local conditions = {
      {"status_type", status_type},
      {"beammpid", self.beammpid}
    }
    local result = self.dbManager:deleteObject(userStatus, conditions)
    self.dbManager:closeConnection()
    return result
end

function Service:createStatus(status_type, reason, time)

    local userStatusClass = userStatus.new(self.beammpid, status_type, true, reason, time or nil)

    local result = self.dbManager:save(userStatusClass, false)

    return result
end

function Service:checkStatusTime(status_type)
    local status = self:getAllStatus()
    
    for _, value in ipairs(status) do
        if value.status_type == status_type then
            return value.time <= os.time()
        end
    end
    return false
end


return Service