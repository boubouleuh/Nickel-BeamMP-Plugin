
local new = require("objects.New")

local userClass = require("objects.User")


local Service = {}



function Service.new(beammpid, dbManager)
    local self = {}
    self.dbManager = dbManager  -- You can set this to a specific value if needed
    self.beammpid = beammpid
    return new._object(Service, self)
end
  

function Service:getUser()
    self.dbManager:openConnection()
    local status = self.dbManager:getClassByBeammpId(userClass, self.beammpid)
    self.dbManager:closeConnection()
    return status
end

function Service:setWhitelisted(bool)
    local user = self:getUser()

    user:setKey("whitelisted", bool)
   
    local result = self.dbManager:save(user, true)

    return result
end

function Service:setLanguage(region)
    local user = self:getUser()

    user:setKey("language", region)
   
    local result = self.dbManager:save(user, true)

    return result
end



return Service