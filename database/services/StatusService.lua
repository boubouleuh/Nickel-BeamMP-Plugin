
local new = require("objects.New")

local userStatus = require("objects.UserStatus")

local interfaceUtils = require("main.client.interfaceUtils")

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

    for _, value in ipairs(status) do
        value.tableName = userStatus.tableName
    end
    self.dbManager:closeConnection()
    return status
end


function Service:getStatus(status_type)
    local status = self:getAllStatus()
    print(status)
    local result = {}
    for _, value in ipairs(status) do
        if value.status_type == status_type then
            print("StatusService:getStatus")
            print(value)
            table.insert(result, value)
        end
    end
    return result
end

function Service:checkStatus(status_type)
    local status = self:getAllStatus()
    print("StatusService:checkStatus")
    print(status)
    for _, value in ipairs(status) do
        print(value.status_type, status_type, value.is_status_value)
        if value.status_type == status_type and value.is_status_value == 1 then
            return true
        end
    end
    return false
end

function Service:disableStatus(status_type)
    local status = self:getStatus(status_type)

    if status == nil then
        return "nickel.nochange"
    end

    for _, value in ipairs(status) do
        if value.is_status_value == 1 then
            value.is_status_value = 0
            self.dbManager:save(value, true)
        end
    end

    interfaceUtils.sendString(-1, "NKResetPlayerList", "")

    return result
    
end
function Service:removeStatus(status_type)
    self.dbManager:openConnection()
    local conditions = {
      {"status_type", status_type},
      {"beammpid", self.beammpid}
    }
    local result = self.dbManager:deleteObject(userStatus, conditions)
    self.dbManager:closeConnection()

    interfaceUtils.sendString(-1, "NKResetPlayerList", "")

    return result
end

function Service:createStatus(status_type, reason, time)

    local userStatusClass = userStatus.new(self.beammpid, status_type, true, reason, time or nil)

    local result = self.dbManager:save(userStatusClass, false)
    interfaceUtils.sendString(-1, "NKResetPlayerList", "")
    return result
end

function Service:checkStatusTime(status_type)
    local status = self:getAllStatus()
    
    for _, value in ipairs(status) do
        print("StatusService:checkStatusTime")
        print(value)
        if value.status_type == status_type and value.is_status_value == 1 then
            return value.expiry_time <= os.time()
        end
    end
    return false
end


return Service