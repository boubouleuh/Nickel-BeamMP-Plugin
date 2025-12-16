---@meta
local Nickel = ...
local OriginalRegisterEvent = MP.RegisterEvent
local handlers = {}

local function safeCall(name, func, ...)
    local ok, res = pcall(func, ...)
    if not ok then 
        print("^1[Nickel] Event Error (" .. name .. "): " .. tostring(res) .. "^r")
        return nil
    end
    return res
end

function MP.RegisterEvent(evt, handler, p3, p4)
    if not OriginalRegisterEvent then return end
    
    local timerMs = type(p3) == "number" and p3 or nil
    local name = type(p3) == "string" and p3 or p4 or (type(handler) == "string" and handler) or "anonymous"

    if not handlers[evt] then
        handlers[evt] = {}
        local dispatch = "Nickel_Evt_" .. evt
        _G[dispatch] = function(...)
            if handlers[evt] then
                for _, item in ipairs(handlers[evt]) do 
                    local res = safeCall(evt, item.fn, ...)
                    if res ~= nil then return res end
                end
            end
        end
        OriginalRegisterEvent(evt, dispatch)
    end

    local fn = type(handler) == "function" and handler or _G[handler]
    if fn then table.insert(handlers[evt], { fn = fn, name = name }) end

    if timerMs then
        MP.CreateEventTimer(evt, timerMs)
        -- Return a cancel function for convenience
        return function() MP.CancelEventTimer(evt) end
    end
end

function AddEventHandler(evt, fn) MP.RegisterEvent(evt, fn) end
Nickel.RegisterEvent = MP.RegisterEvent

function Nickel.TriggerEvent(evt, ...)
    if handlers[evt] then
        for _, item in ipairs(handlers[evt]) do
            safeCall(evt, item.fn, ...)
        end
    end
end

function Nickel.ResetEvents()
    handlers = {}
    print("^3[Nickel] Event handlers cleared.^r")
end

function Nickel.ListEvents()
    print("^3[Nickel] Registered Events:^r")
    for evt, items in pairs(handlers) do
        print("  - " .. evt .. " (" .. #items .. " handlers)")
        for _, item in ipairs(items) do
            print("    > " .. item.name)
        end
    end
end
