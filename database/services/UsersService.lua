
local new = require("objects.New")

local userClass = require("objects.User")
local utils = require("utils.misc")

local Service = {}



function Service.new(beammpid, dbManager)
    local self = {}
    self.dbManager = dbManager  -- You can set this to a specific value if needed
    self.beammpid = beammpid
    return new._object(Service, self)
end
  

function Service:getUser()
    return self.dbManager:withConnection(function()
        return self.dbManager:getClassByBeammpId(userClass, self.beammpid)
    end)
end

function Service:setWhitelisted(bool)
    local user = self:getUser()
    
    user:setKey("whitelisted", bool)
   
    local result = self.dbManager:save(user, true)

    return result
end

function Service:isWhitelisted()
    local user = self:getUser()

    local b = user:getKey("whitelisted")

    return utils.isTruthy(b)

end

function Service:setLanguage(region)
    local user = self:getUser()

    user:setKey("language", region)
   
    local result = self.dbManager:save(user, true)

    return result
end



return Service