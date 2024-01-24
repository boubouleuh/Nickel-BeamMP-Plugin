

local onConsoleInput = {}
function onConsoleInput.new(cmdManager) 
    function onInput(cmd)
        print("POROUUTT")
        return cmdManager:CreateCommand(-2, cmd, true, cmdManager)
    end
    MP.RegisterEvent("onConsoleInput", "onInput")

end




return onConsoleInput