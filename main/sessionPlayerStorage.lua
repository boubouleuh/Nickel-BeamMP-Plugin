local new = require("objects.New")

local sessionPlayerStorage = {}
local instances = {} 

function sessionPlayerStorage:new(beammpid)
    if instances[beammpid] then
        return instances[beammpid]
    end

    local self = {
        beammpid = beammpid
    }
    self = new._object(sessionPlayerStorage, self)

    instances[beammpid] = self
    return self
end

function sessionPlayerStorage:set(key, value)
    self[key] = value
end

function sessionPlayerStorage:get(key)
    return self[key]
end

function sessionPlayerStorage:remove(key)
    self[key] = nil
end

function sessionPlayerStorage:clear()
    for k in pairs(self) do
        self[k] = nil
    end
end

return sessionPlayerStorage