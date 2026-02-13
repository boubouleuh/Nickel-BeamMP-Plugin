
DefaultPermissions = {}

--- initialize default roles and permissions
function DefaultPermissions.init()
    local infoValue = DatabaseManager:withConnection(function()
        return DatabaseManager:getEntry(Infos, "infoKey", "isInitialDatabaseLaunch").infoValue
    end)

    if infoValue == "false" then
        DatabaseManager:withConnection(function()
            PermissionsManager:addRole("Member", 0, true)
            PermissionsManager:addRole("Moderator", 1, false)
            PermissionsManager:addRole("Administrator", 2, false)
            PermissionsManager:addRole("Owner", 3, false)

            PermissionsManager:assignCommand("dm", "Member")
            PermissionsManager:assignCommand("help", "Member")
            PermissionsManager:assignCommand("countdown", "Member")

            PermissionsManager:assignCommand("createrole", "Administrator")
            PermissionsManager:assignCommand("deleterole", "Administrator")
            PermissionsManager:assignCommand("grantcommand", "Administrator")
            PermissionsManager:assignCommand("grantrole", "Administrator")
            PermissionsManager:assignCommand("revokerole", "Administrator")
            PermissionsManager:assignCommand("revokecommand", "Administrator")
            PermissionsManager:assignCommand("grantaction", "Administrator")
            PermissionsManager:assignCommand("revokeaction", "Administrator")
            PermissionsManager:assignCommand("listroles", "Administrator")
            PermissionsManager:assignCommand("listactions", "Administrator")

            PermissionsManager:assignCommand("forcenametags", "Moderator")

            PermissionsManager:assignCommand("whitelist", "Moderator")
            PermissionsManager:assignCommand("kick", "Moderator")
            PermissionsManager:assignCommand("ban", "Moderator")
            PermissionsManager:assignCommand("tempban", "Moderator")
            PermissionsManager:assignCommand("banip", "Moderator")
            PermissionsManager:assignCommand("unban", "Moderator")
            PermissionsManager:assignCommand("mute", "Moderator")
            PermissionsManager:assignCommand("unmute", "Moderator")
            PermissionsManager:assignCommand("tempmute", "Moderator")
            PermissionsManager:assignCommand("broadcast", "Moderator")

            PermissionsManager:assignAction("editEnvironment", "Moderator")
            PermissionsManager:assignAction("seeAdvancedUserInfos", "Moderator")
            PermissionsManager:assignAction("editInterfaceSettings", "Administrator")
        end)
    end

    local everyCommands, everyCommandBinded, everyActions, everyRoleActions = DatabaseManager:withConnection(function()
        local everyCommands = DatabaseManager:getAllEntry(Command)
        local everyCommandBinded = DatabaseManager:getAllEntry(RoleCommand)
        local everyActions = DatabaseManager:getAllEntry(Action)
        local everyRoleActions = DatabaseManager:getAllEntry(RoleAction)
        return everyCommands, everyCommandBinded, everyActions, everyRoleActions
    end)
        -- Create a dictionary to store role associations
    local commandRoles = {}

    -- Fill the dictionary with role commands
    for _, roleCommand in ipairs(everyCommandBinded) do
        commandRoles[roleCommand.commandID] = true
    end

    -- Check each command to see if it has an associated role
    for _, command in ipairs(everyCommands) do
        if not commandRoles[command.commandID] and not NickelCommands[command.commandName].consoleOnly then
            Utils.nkprint(string.format("Command '%s' (ID: %d) is not associated with any role. Use the command '%sgrantcommand %s <role>' to assign it to a role.", command.commandName, command.commandID, ConfigManager.GetSetting("commands").prefix , command.commandName), "warn")
        end
    end

    -- Create a dictionary to store role associations
    local actionRoles = {}

    -- Fill the dictionary with role actions
    for _, roleAction in ipairs(everyRoleActions) do
        actionRoles[roleAction.actionID] = true
    end

    -- Check each action to see if it has an associated role
    for _, action in ipairs(everyActions) do
        if not actionRoles[action.actionID] then
            Utils.nkprint(string.format("Action '%s' (ID: %d) is not associated with any role. Use the command '%sgrantaction %s <role>' to assign it to a role.", action.actionName, action.actionID, ConfigManager.GetSetting("commands").prefix , action.actionName), "warn")
        end
    end

end

-- Note: DefaultPermissions.init() should be called from main.lua after database tables are created