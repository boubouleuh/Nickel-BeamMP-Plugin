local Nickel = ...
---Color code support for BeamMP console output
---@class Nickel.Colors
Nickel.Colors = {}

local originalPrint = print

---BeamMP color code to ANSI escape sequence mapping
local colors = {
    ["^r"] = "\27[0m",     -- reset
    ["^n"] = "\27[4m",     -- underline
    ["^l"] = "\27[1m",     -- bold
    ["^o"] = "\27[3m",     -- italic
    
    ["^0"] = "\27[30m",    -- black
    ["^1"] = "\27[31m",    -- red
    ["^2"] = "\27[32m",    -- green
    ["^3"] = "\27[33m",    -- yellow
    ["^4"] = "\27[34m",    -- blue
    ["^5"] = "\27[36m",    -- cyan
    ["^6"] = "\27[35m",    -- magenta
    ["^7"] = "\27[37m",    -- white
    ["^8"] = "\27[90m",    -- grey
    ["^9"] = "\27[91m",    -- light red
}

---Initialize color code support by overriding the global print function
function Nickel.Colors.init()
    print = function(...)
        local args = {...}
        for i, arg in ipairs(args) do
            if type(arg) == "string" then
                for code, ansi in pairs(colors) do
                    arg = arg:gsub("%"..code, ansi)
                end
                -- Always reset at the end
                arg = arg .. "\27[0m"
                args[i] = arg
            end
        end
        originalPrint(table.unpack(args))
    end
end

-- Auto-initialize when loaded
Nickel.Colors.init()