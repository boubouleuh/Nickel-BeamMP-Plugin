-- Global server-wide session storage (no player scoping)
-- Provides simple key/value operations similar to sessionPlayerStorage per-player API.

local data = {}
local M = {}

function M.set(key, value)
    data[key] = value
end

function M.get(key)
    return data[key]
end

function M.remove(key)
    data[key] = nil
end

function M.clear()
    for k in pairs(data) do data[k] = nil end
end

function M.dump()
    local copy = {}
    for k,v in pairs(data) do copy[k] = v end
    return copy
end

-- Optionally expose raw table (read-only convention)
function M._raw()
    return data
end

return M
