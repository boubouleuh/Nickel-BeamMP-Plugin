
local defaultMoney = 0
DatabaseManager:addColumn(User, "money", defaultMoney)   -- Add money field to User table


-- Injecting money methods into User class
function User:getMoney()
    return tonumber(self.money) or 0
end

function User:setMoney(amount)
    self.money = amount
    return self:save()
end

function User:addMoney(amount)
    local current = self:getMoney()
    self:setMoney(current + amount)
end

function User:removeMoney(amount)
    local current = self:getMoney()
    self:setMoney(current - amount)
end

Utils.nkprint("[example_extension] Money system loaded and User table updated!", "info")