
local utils = require("utils.misc")

local init = {}

local function initialize(managers)
    if not managers then
        return
    end
    
    -- Get the path to extensions directory
    local extensionsPath = utils.script_path() .. "extensions"
    local files = FS.ListFiles(extensionsPath)
    
    if not files then
        return
    end
    
    -- Loop through each file in extensions directory
    for _, file in pairs(files) do
        if not file then
            goto continue
        end
        
        local fileExtension = FS.GetExtension(file)
        if fileExtension ~= ".lua" then
            goto continue
        end
        
        local extensionName = FS.GetFilename(file, false)
        if not extensionName then
            goto continue
        end
        
        -- Remove .lua extension using regex
        extensionName = extensionName:gsub("%.lua$", "")
        
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