---@meta
Nickel = ...
local threads = {}
local counter = 0

local function Wait(ms) MP.Sleep(ms) end

local function newThread(func, ms, isTimeout)
    if type(func) ~= "function" then return end
    counter = counter + 1
    local id = "Nickel_T_" .. counter
    
    MP.RegisterEvent(id, function(...)
        if select("#", ...) > 0 then return end
        local ok, err = pcall(func)
        if not ok then print("^1[Nickel] "..(isTimeout and "Timeout" or "Thread").." Error: " .. tostring(err) .. "^r") end
        MP.CancelEventTimer(id)
        threads[id] = nil
    end)
    
    threads[id] = true
    MP.CreateEventTimer(id, ms)
    return counter
end

local function CreateThread(fn) return newThread(fn, 1, false) end
local function SetTimeout(ms, fn) return newThread(fn, ms, true) end

local function SetInterval(ms, fn)
    if type(fn) ~= "function" then return end
    counter = counter + 1
    local currentId = counter
    local id = "Nickel_T_" .. currentId
    
    MP.RegisterEvent(id, function(...)
        if select("#", ...) > 0 then return end
        local ok, err = pcall(fn, currentId)
        if not ok then print("^1[Nickel] Interval Error: " .. tostring(err) .. "^r") end
    end)
    
    threads[id] = true
    MP.CreateEventTimer(id, ms)
    return currentId
end

local function StopThread(id)
    local eventId = "Nickel_T_" .. id
    if threads[eventId] then
        MP.CancelEventTimer(eventId)
        threads[eventId] = nil
        return true
    end
    return false
end

Nickel.Threads = threads
Nickel.CreateThread = CreateThread
Nickel.SetTimeout = SetTimeout
Nickel.SetInterval = SetInterval
Nickel.StopThread = StopThread
Nickel.Wait = Wait