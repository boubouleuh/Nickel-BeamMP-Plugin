

EventDispatcher.setPath(Utils.extension_path() .. "events/") -- This set the event dispatcher path of the current extension
EventDispatcher.load("console") --Load the event category "console"

local user = User.getOrCreate(39917, "bouboule") --Hard coded user for the example, but you are more likely to do it in a command or an event so thosse parameters will be available from it
if user and ExampleConfig.get("auto_add_money") then
    user:addMoney(100)
    print("[example_extension] The player has " .. user:getMoney() .. "$")
end