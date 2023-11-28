local PermissionsHandler = require("main.permissions.PermissionsHandler")

local default = {}

function default.init(dbManager)

    PermissionsManager = PermissionsHandler.new(dbManager)

    PermissionsManager:addRole("Member", 0, true)

    PermissionsManager:addRole("Moderator", 1, false) -- TODO need to run that only the first time but idk how for the moment

    PermissionsManager:addRole("Administrator", 2, false)

    PermissionsManager:addRole("Owner", 3, false)



end

return default