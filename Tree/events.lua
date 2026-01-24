local Nickel = ...
-- VV this should fix the c stack overflow (need test)
if not _G.Nickel_OriginalRegisterEvent then
    _G.Nickel_OriginalRegisterEvent = MP.RegisterEvent
end
local OriginalRegisterEvent = _G.Nickel_OriginalRegisterEvent

local handlers = {}

local function safeCall(name, func, ...)
    local ok, res = xpcall(func, debug.traceback, ...)
    if not ok then 
        Nickel.reportError(res)
        print("^1[Nickel] Event Error (" .. name .. "): " .. res .. "^r")
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
        
        if not _G[dispatch] then 
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
    end

    local fn = type(handler) == "function" and handler or _G[handler]
    if fn then
        local found = false
        if name ~= "anonymous" then
            for i, item in ipairs(handlers[evt]) do
                if item.name == name then
                    handlers[evt][i] = { fn = fn, name = name }
                    found = true
                    break
                end
            end
        end
        if not found then
            table.insert(handlers[evt], { fn = fn, name = name })
        end
    end

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

function Nickel.ListGlobals()
    local core, ext = {}, {}
    for k, v in pairs(_G) do
        if (Nickel.IsGlobalProtected and Nickel.IsGlobalProtected(k)) or k == "_G" then
            table.insert(core, k)
        else
            table.insert(ext, k)
        end
    end
    table.sort(core)
    table.sort(ext)

    print("^3[Nickel] --- Core Globals ---^r")
    for _, k in ipairs(core) do
        print("  - " .. tostring(k) .. " : " .. tostring(_G[k]))
    end

    print("^3[Nickel] --- Extension Globals ---^r")
    for _, k in ipairs(ext) do
        print("  - " .. tostring(k) .. " : " .. tostring(_G[k]))
    end
end