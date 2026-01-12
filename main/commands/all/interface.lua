
local command = RegisterCommand("interface")
command.consoleOnly = true

--- command
function command.init(sender_id, sender_name, installORuninstall)
    if installORuninstall == nil or installORuninstall ~= "install" and installORuninstall ~= "uninstall" then
        MessagesManager:SendMessage(sender_id, "commands.interface.missing_args", {Prefix = ConfigManager.GetSetting("commands").prefix})
        return false
    end
    if installORuninstall == "install" then
        Nickel.CreateThread(function()
            Online.downloadInterface()
            InterfaceChecker.CheckForInterfaceMod()
        end)
    elseif installORuninstall == "uninstall" then
        FS.Remove(InterfaceChecker.zipPath)
        Utils.nkprint("Interface Mod uninstalled from: " .. InterfaceChecker.zipPath, "info")
        InterfaceChecker.CheckForInterfaceMod()
    end

    return true
end