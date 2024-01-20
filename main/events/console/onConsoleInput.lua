

local onConsoleInput = {}
function onConsoleInput.new(cmdManager) 
    function onInput(cmd)
        print("POROUUTT")
        return cmdManager:CreateCommand(-1, cmd, true, cmdManager)
    end
    MP.RegisterEvent("onConsoleInput", "onInput")

end




return onConsoleInput