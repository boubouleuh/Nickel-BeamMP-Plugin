
local utils = require("utils.misc")

local init = {}

-- Initialize all extension modules
local function initialize(managers)
    -- Check if managers parameter exists
    if not managers then
        return
    end
    
    -- Get the path to extensions directory
    local extensionsPath = utils.script_path() .. "extensions"
    local files = FS.ListFiles(extensionsPath)
    
    -- Check if files list exists
    if not files then
        return
    end
    
    -- Loop through each file in extensions directory
    for _, file in pairs(files) do
        -- Skip if file is nil
        if not file then
            goto continue
        end
        
        -- Check if file is a Lua file
        local fileExtension = FS.GetExtension(file)
        if fileExtension ~= "lua" then
            goto continue
        end
        
        -- Extract extension name without .lua extension
        local extensionName = FS.GetFilename(file, false)
        if not extensionName then
            goto continue
        end
        
        -- Load the extension module
        local extension = require("extensions." .. extensionName)
        -- Check if extension exists and has start method
        if extension and extension.start then
            extension.start(managers)
        end
        
        ::continue::
    end
end

init.initialize = initialize

return init