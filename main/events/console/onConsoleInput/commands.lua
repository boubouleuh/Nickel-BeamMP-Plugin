

return function(cmd, managers) 
    --check if managers is provided
    if not managers or type(managers) ~= "table" then
        error("Invalid managers object provided.")
    end
    return managers.cmdManager:CreateCommand(-2, cmd, true)
end
