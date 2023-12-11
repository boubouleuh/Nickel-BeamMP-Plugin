

local onConsoleInput = {}
function onConsoleInput.new(cmdManager) 
    function onInput(cmd)
        return cmdManager:CreateCommand(-1, cmd, true, cmdManager.msgManager)
    end
    MP.RegisterEvent("onConsoleInput", "onInput")

end




return onConsoleInput