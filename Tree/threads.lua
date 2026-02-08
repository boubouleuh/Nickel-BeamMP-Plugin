Nickel = ...
local threads = {} -- ID -> { co = coroutine, wakeTime = number }
local counter = 0

-- Global tick timer configuration
local TICK_RATE = 50 -- ms (20 ticks/second)
local TIMER_ID = "Nickel_JobSystem_Tick"
local TIME = 0 -- Monotonic time in ms based on ticks

--- Yields the current coroutine for a specified amount of time
---@param ms number Time to wait in milliseconds
local function Wait(ms)
    local co = coroutine.running()
    if not co then
        print("^1[Nickel] Warning: Wait() called outside of a coroutine. Using blocking sleep.^r")
        MP.Sleep(ms)
        return
    end
    coroutine.yield(ms)
end

--- job system loop
local function tick()
    TIME = TIME + TICK_RATE
    local now = TIME
    
    for id, data in pairs(threads) do
        if data.co and coroutine.status(data.co) ~= "dead" then
            if now >= data.wakeTime then
                local ok, result = coroutine.resume(data.co)
                if not ok then
                    Nickel.reportError(result)
                    print("^1[Nickel] Thread Error ("..id.."): " .. result .. "^r")
                    threads[id] = nil
                else
                    if coroutine.status(data.co) == "dead" then
                        threads[id] = nil
                    else
                        local wait = tonumber(result) or 0
                        data.wakeTime = now + wait
                    end
                end
            end
        else
            threads[id] = nil
        end
    end
end

MP.RegisterEvent(TIMER_ID, tick)
MP.CancelEventTimer(TIMER_ID)
MP.CreateEventTimer(TIMER_ID, TICK_RATE)

--- Creates a new thread (coroutine)
---@param func function The function to run in the thread
---@return number id The thread ID
local function newThread(func)
    if type(func) ~= "function" then return end
    counter = counter + 1
    local id = counter
    
    local co = coroutine.create(function() func(id) end)
    threads[id] = { co = co, wakeTime = 0 }
    
    return id
end

local function CreateThread(fn)
    return newThread(fn)
end

local function SetTimeout(ms, fn)
    return newThread(function(id)
        Wait(ms)
        fn(id)
    end)
end

local function SetInterval(ms, fn)
    return newThread(function(id)
        while true do
            Wait(ms)
            fn(id)
        end
    end)
end

local function StopThread(id)
    if threads[id] then
        threads[id] = nil
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