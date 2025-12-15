---@meta
local Nickel = ...
local threads = {}
local counter = 0

function Wait(ms) MP.Sleep(ms) end

local function newThread(func, ms, isTimeout)
    if type(func) ~= "function" then return end
    counter = counter + 1
    local id = "Nickel_T_" .. counter
    
    MP.RegisterEvent(id, function()
        local ok, err = pcall(func)
        if not ok then print("^1[Nickel] "..(isTimeout and "Timeout" or "Thread").." Error: " .. tostring(err) .. "^r") end
        MP.CancelEventTimer(id)
        threads[id] = nil
    end)
    
    threads[id] = true
    MP.CreateEventTimer(id, ms)
    return counter
end

function CreateThread(fn) return newThread(fn, 1, false) end
function SetTimeout(ms, fn) return newThread(fn, ms, true) end

Nickel.Threads = threads
Nickel.CreateThread = CreateThread
Nickel.SetTimeout = SetTimeout
Nickel.Wait = Wait
