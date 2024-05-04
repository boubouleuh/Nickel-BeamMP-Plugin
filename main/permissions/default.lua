local PermissionsHandler = require("main.permissions.PermissionsHandler")

local default = {}

function default.init(PermissionsManager)

    print("INITIALIZING ROLE DEFAULT")
    PermissionsManager:addRole("Member", 0, true)

    PermissionsManager:addRole("Moderator", 1, false) -- TODO need to run that only the first time but idk how for the moment

    PermissionsManager:addRole("Administrator", 2, false)

    PermissionsManager:addRole("Owner", 3, false)


    PermissionsManager:assignCommand("dm", "Member")

    PermissionsManager:assignCommand("grantcommand", "Administrator")
    PermissionsManager:assignCommand("grantrole", "Administrator")
    PermissionsManager:assignCommand("revokerole", "Administrator")
    PermissionsManager:assignCommand("revokecommand", "Administrator")



end

return default