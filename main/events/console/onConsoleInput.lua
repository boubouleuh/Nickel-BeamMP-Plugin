

local onConsoleInput = {}
function onConsoleInput.new(cmdManager) 
    function onInput(cmd)
        return cmdManager:CreateCommand(-2, cmd, true, cmdManager)
    end
    MP.RegisterEvent("onConsoleInput", "onInput")

end




return onConsoleInput