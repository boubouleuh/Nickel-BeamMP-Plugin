SessionManager = {}
SessionManager.playerSessions = {}

-- Get or create player session
function SessionManager.get(beammpid)
    if not SessionManager.playerSessions[beammpid] then
        SessionManager.playerSessions[beammpid] = {
            beammpid = beammpid,
            connected_at = os.time(),
            data = {}
        }
    end
    return SessionManager.playerSessions[beammpid]
end

-- Set player data
function SessionManager.set(beammpid, key, value)
    local session = SessionManager.get(beammpid)
    session.data[key] = value
    return value
end

-- Get player data with optional default
function SessionManager.getData(beammpid, key, defaultValue)
    local session = SessionManager.get(beammpid)
    local value = session.data[key]
    return value ~= nil and value or defaultValue
end

-- Check if data exists
function SessionManager.has(beammpid, key)
    local session = SessionManager.playerSessions[beammpid]
    return session and session.data[key] ~= nil
end

-- Remove specific data
function SessionManager.remove(beammpid, key)
    local session = SessionManager.playerSessions[beammpid]
    if session then
        session.data[key] = nil
    end
end

-- Get all player data
function SessionManager.getAll(beammpid)
    local session = SessionManager.playerSessions[beammpid]
    return session and session.data or {}
end

-- Clear entire player session
function SessionManager.clear(beammpid)
    SessionManager.playerSessions[beammpid] = nil
end

-- Get all players with active sessions
function SessionManager.getAllPlayers()
    local players = {}
    for beammpid, session in pairs(SessionManager.playerSessions) do
        table.insert(players, {
            beammpid = beammpid,
            connected_at = session.connected_at,
            data_count = 0
        })
        for _ in pairs(session.data) do
            players[#players].data_count = players[#players].data_count + 1
        end
    end
    return players
end

-- Clear all sessions
function SessionManager.clearAll()
    SessionManager.playerSessions = {}
end

-- Increment numeric value
function SessionManager.increment(beammpid, key, amount)
    amount = amount or 1
    local current = SessionManager.getData(beammpid, key, 0)
    local newValue = tonumber(current) and (tonumber(current) + amount) or amount
    SessionManager.set(beammpid, key, newValue)
    return newValue
end

-- Decrement numeric value
function SessionManager.decrement(beammpid, key, amount)
    return SessionManager.increment(beammpid, key, -(amount or 1))
end

-- Add to list/array
function SessionManager.addToList(beammpid, key, value)
    local list = SessionManager.getData(beammpid, key, {})
    if type(list) ~= "table" then
        list = {list}
    end
    table.insert(list, value)
    SessionManager.set(beammpid, key, list)
    return list
end

-- Remove from list/array
function SessionManager.removeFromList(beammpid, key, value)
    local list = SessionManager.getData(beammpid, key, {})
    if type(list) == "table" then
        for i = #list, 1, -1 do
            if list[i] == value then
                table.remove(list, i)
            end
        end
        SessionManager.set(beammpid, key, list)
    end
    return list
end

-- Toggle boolean value
function SessionManager.toggle(beammpid, key, defaultValue)
    defaultValue = defaultValue or false
    local current = SessionManager.getData(beammpid, key, defaultValue)
    local newValue = not current
    SessionManager.set(beammpid, key, newValue)
    return newValue
end

-- Get connection time in seconds
function SessionManager.getConnectionTime(beammpid)
    local session = SessionManager.playerSessions[beammpid]
    if session then
        return os.time() - session.connected_at
    end
    return 0
end

return SessionManager