

local utils = {}
--- send a string to the client
---@param id integer
---@param event_name string
---@param data string   
function utils.sendString(id, event_name, data)
    MP.TriggerClientEvent(id, event_name, data) 
end

--- send a table to the client
---@param id integer
---@param event_name string
---@param data table   
function utils.sendTable(id, event_name, data)
    MP.TriggerClientEventJson(id, event_name, data)
end

return utils