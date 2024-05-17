
local utils = require("utils.misc")

local init = {}


function init.initialize()
    local files = FS.ListFiles(utils.script_path() .. "extensions")
    for _, file in pairs(files) do

        if file:sub(-#".lua") == ".lua" then
            require("extensions." .. file:match("(.+)%..+$")).start()
        end

    end
end

return init