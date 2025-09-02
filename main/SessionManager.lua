SessionManager = {}
SessionManager.playerSessions = {}


function SessionManager:getPlayerSession(beammpid)
    if not self.playerSessions[beammpid] then
        self.playerSessions[beammpid] = {}
    end
    return self.playerSessions[beammpid]
end

function SessionManager:setPlayerData(beammpid, key, value)
    local session = self:getPlayerSession(beammpid)
    session[key] = value
end

function SessionManager:getPlayerData(beammpid, key)
    local session = self:getPlayerSession(beammpid)
    return session[key]
end

function SessionManager:removePlayerData(beammpid, key)
    local session = self:getPlayerSession(beammpid)
    session[key] = nil
end

function SessionManager:clearPlayerSession(beammpid)
    self.playerSessions[beammpid] = nil
end

function SessionManager:clearAllSessions()
    self.playerSessions = {}
end

return SessionManager