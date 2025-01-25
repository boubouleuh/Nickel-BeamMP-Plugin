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

        managers:addRole("Member", 0, true)

        managers:addRole("Moderator", 1, false) 

        managers:addRole("Administrator", 2, false)

        managers:addRole("Owner", 3, false)


        managers:assignCommand("dm", "Member")
        managers:assignCommand("help", "Member")
        managers:assignCommand("countdown", "Member")

        managers:assignCommand("createrole", "Administrator")
        managers:assignCommand("deleterole", "Administrator")
        managers:assignCommand("grantcommand", "Administrator")
        managers:assignCommand("grantrole", "Administrator")
        managers:assignCommand("revokerole", "Administrator")
        managers:assignCommand("revokecommand", "Administrator")
        managers:assignCommand("grantaction", "Administrator")
        managers:assignCommand("revokeaction", "Administrator")
        managers:assignCommand("listroles", "Administrator")

        managers:assignCommand("whitelist", "Moderator")
        managers:assignCommand("kick", "Moderator")
        managers:assignCommand("ban", "Moderator")
        managers:assignCommand("tempban", "Moderator")
        managers:assignCommand("banip", "Moderator")
        managers:assignCommand("unban", "Moderator")
        managers:assignCommand("mute", "Moderator")
        managers:assignCommand("unmute", "Moderator")
        managers:assignCommand("tempmute", "Moderator")

        managers:assignAction("editEnvironment", "Moderator")
        managers:assignAction("seeAdvancedUserInfos", "Moderator")
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