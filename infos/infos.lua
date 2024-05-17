
local utils = require("utils.misc")

local infos = {}
function infos.getInfosKey(key) 

    local json = io.open(utils.script_path() .. "infos/infos.json", "r")  
    local content = json:read("*all")
    json:close()
    local tbl = Util.JsonDecode(content);
    return tbl[key]
end

function infos.setInfosKey(key, value) 

    local json1 = io.open(utils.script_path() .. "infos/infos.json", "r")
    local content = json1:read("*all")
    json1:close()
    local tbl1 = Util.JsonDecode(content);
    tbl1[key] = value
    local json2 = io.open(utils.script_path() .. "infos/infos.json", "w")
    local json3 = Util.JsonEncode(tbl1)
    json2:write(json3)
    json2:close()
    
end

return infos