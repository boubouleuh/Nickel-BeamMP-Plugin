return function() 
    DatabaseManager:withConnection(function()
        local versionInfo = DatabaseManager:getEntry(Infos, "infoKey", "version")
        if versionInfo then
            Utils.nkprint("Thanks for using Nickel version " .. versionInfo.infoValue , "info")
        else
            Utils.nkprint("Thanks for using Nickel with Tree Framework!", "info")
        end
    end)
    Utils.nkprint("Please join the Nickel discord if you want to : https://discord.gg/h5P84FFw7B", "info")
end

