return Event(function()
    Nickel.heartbeat()
end):Every(1800000) -- every 30 minutes