

local user = User.getOrCreate(39917, "bouboule")
if user then
    user:addMoney(100)
    print("The player has " .. user:getMoney() .. "$")
end