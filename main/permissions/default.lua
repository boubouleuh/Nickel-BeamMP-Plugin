local PermissionsHandler = require("main.permissions.PermissionsHandler")
local RoleCommand = require("objects.RoleCommand")
local Command = require("objects.Command")
local utils = require("utils.misc")
local Infos = require("objects.Infos")
local Action = require("objects.Action")
local RoleAction = require("objects.RoleAction")
local default = {}

--- initialize default roles and permissions
---@param managers managers
function default.init(managers)

    ---@type DatabaseManager
    local dbManager = managers.dbManager
    dbManager:openConnection()

    if dbManager:getEntry(Infos, "infoKey", "isInitialDatabaseLaunch").infoValue == "false" then

        managers.permManager:addRole("Member", 0, true)

        managers.permManager:addRole("Moderator", 1, false) 

        managers.permManager:addRole("Administrator", 2, false)

        managers.permManager:addRole("Owner", 3, false)


        managers.permManager:assignCommand("dm", "Member")
        managers.permManager:assignCommand("help", "Member")
        managers.permManager:assignCommand("countdown", "Member")

        managers.permManager:assignCommand("createrole", "Administrator")
        managers.permManager:assignCommand("deleterole", "Administrator")
        managers.permManager:assignCommand("grantcommand", "Administrator")
        managers.permManager:assignCommand("grantrole", "Administrator")
        managers.permManager:assignCommand("revokerole", "Administrator")
        managers.permManager:assignCommand("revokecommand", "Administrator")
        managers.permManager:assignCommand("grantaction", "Administrator")
        managers.permManager:assignCommand("revokeaction", "Administrator")
        managers.permManager:assignCommand("listroles", "Administrator")
        managers.permManager:assignCommand("listactions", "Administrator")

        managers.permManager:assignCommand("forcenametags", "Moderator")

        managers.permManager:assignCommand("whitelist", "Moderator")
        managers.permManager:assignCommand("kick", "Moderator")
        managers.permManager:assignCommand("ban", "Moderator")
        managers.permManager:assignCommand("tempban", "Moderator")
        managers.permManager:assignCommand("banip", "Moderator")
        managers.permManager:assignCommand("unban", "Moderator")
        managers.permManager:assignCommand("mute", "Moderator")
        managers.permManager:assignCommand("unmute", "Moderator")
        managers.permManager:assignCommand("tempmute", "Moderator")
        managers.permManager:assignCommand("broadcast", "Moderator")

        managers.permManager:assignAction("editEnvironment", "Moderator")
        managers.permManager:assignAction("seeAdvancedUserInfos", "Moderator")
        managers.permManager:assignAction("editInterfaceSettings", "Administrator")
    end
    dbManager:closeConnection()
    dbManager:openConnection()
    local everyCommands = dbManager:getAllEntry(Command)
    local everyCommandBinded = dbManager:getAllEntry(RoleCommand)
    local everyActions = dbManager:getAllEntry(Action)
    local everyRoleActions = dbManager:getAllEntry(RoleAction)
    dbManager:closeConnection()
        -- Create a dictionary to store role associations
    local commandRoles = {}

    -- Fill the dictionary with role commands
    for _, roleCommand in ipairs(everyCommandBinded) do
        commandRoles[roleCommand.commandID] = true
    end

    -- Check each command to see if it has an associated role
    for _, command in ipairs(everyCommands) do
        if not commandRoles[command.commandID] then
            utils.nkprint(string.format("Command '%s' (ID: %d) is not associated with any role. Use the command '%sgrantcommand %s <role>' to assign it to a role.", command.commandName, command.commandID, managers.cfgManager:GetSetting("commands").prefix , command.commandName), "warn")
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
            utils.nkprint(string.format("Action '%s' (ID: %d) is not associated with any role. Use the command '%sgrantaction %s <role>' to assign it to a role.", action.actionName, action.actionID, managers.cfgManager:GetSetting("commands").prefix , action.actionName), "warn")
        end
    end
 

end

return default