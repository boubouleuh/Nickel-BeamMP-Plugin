local PermissionsHandler = require("main.permissions.PermissionsHandler")
local RoleCommand = require("objects.RoleCommand")
local Command = require("objects.Command")
local utils = require("utils.misc")
local Infos = require("objects.Infos")
local default = {}

function default.init(PermissionsManager)


    local dbManager = PermissionsManager.dbManager
    dbManager:openConnection()
    if dbManager:getEntry(Infos, "infoKey", "isInitialDatabaseLaunch").infoValue == "true" then

        PermissionsManager:addRole("Member", 0, true)

        PermissionsManager:addRole("Moderator", 1, false) 

        PermissionsManager:addRole("Administrator", 2, false)

        PermissionsManager:addRole("Owner", 3, false)


        PermissionsManager:assignCommand("dm", "Member")

        PermissionsManager:assignCommand("createrole", "Administrator")
        PermissionsManager:assignCommand("deleterole", "Administrator")
        PermissionsManager:assignCommand("grantcommand", "Administrator")
        PermissionsManager:assignCommand("grantrole", "Administrator")
        PermissionsManager:assignCommand("revokerole", "Administrator")
        PermissionsManager:assignCommand("revokecommand", "Administrator")

        PermissionsManager:assignCommand("kick", "Moderator")
        PermissionsManager:assignCommand("ban", "Moderator")
        PermissionsManager:assignCommand("tempban", "Moderator")
        PermissionsManager:assignCommand("banip", "Moderator")
        PermissionsManager:assignCommand("unban", "Moderator")
        PermissionsManager:assignCommand("mute", "Moderator")
        PermissionsManager:assignCommand("unmute", "Moderator")
        PermissionsManager:assignCommand("tempmute", "Moderator")
    end
    dbManager:closeConnection()
    dbManager:openConnection()
    local everyCommands = dbManager:getAllEntry(Command)
    local everyCommandBinded = dbManager:getAllEntry(RoleCommand)
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
            utils.nkprint(string.format("Command '%s' (ID: %d) is not associated with any role", command.commandName, command.commandID), "warn")
        end
    end
    

end

return default