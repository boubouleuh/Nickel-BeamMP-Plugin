local store = {}

local M = {}


local function ensure(beammpid)
    if beammpid == nil then return nil end
    local t = store[beammpid]
    if not t then
        t = {}
        store[beammpid] = t
    end
    return t
end

function M.set(beammpid, key, value)
    local t = ensure(beammpid)
    if not t then return end
    t[key] = value
end

function M.get(beammpid, key)
    local t = store[beammpid]
    if not t then return nil end
    return t[key]
end

function M.remove(beammpid, key)
    local t = store[beammpid]
    if not t then return end
    t[key] = nil
end

function M.clear(beammpid)
    if beammpid == nil then return end
    store[beammpid] = {}
end

function M.clearAll()
    for k in pairs(store) do store[k] = nil end
end

function M.dump(beammpid)
    local t = store[beammpid]
    if not t then return {} end
    local copy = {}
    for k,v in pairs(t) do copy[k]=v end
    return copy
end

return M