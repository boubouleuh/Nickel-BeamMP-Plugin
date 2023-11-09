local user = require("objects.User")


local registerPlayer = {}

function registerPlayer.register(beammpid, name, dbManager)
        -- Insérer ou mettre à jour un utilisateur
    user = user.new(beammpid, name)
    -- dbManager:insertOrUpdateObject("Users", utilisateur)

    dbManager:save(user)
end

return registerPlayer