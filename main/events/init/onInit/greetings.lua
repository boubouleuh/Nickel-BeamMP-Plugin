return Event(function()
    Utils.nkprint("Thanks for using Nickel!", "info")
    -- Defer blocking calls to a thread, show IMPORTANT messages last
    Nickel.CreateThread(function()
        Nickel.heartbeat()
        Utils.nkprint("Nickel version: " .. Updater.get_git_version(Utils.script_path()), "info")
        Utils.nkprint("Please join the Nickel discord if you want to : https://discord.gg/h5P84FFw7B", "important")
        Utils.nkprint("You can also support the project on buymeacoffee : https://buymeacoffee.com/bouboule Thanks you alot if you do !!", "important")
    end)
end)

