-- Database Management Class
local Misc = {}


function Misc.script_path()
    local str = debug.getinfo(2, "S").source:sub(1):gsub("\\", "/")
    local _, pos = str:find(".*/")
    return str:sub(1, pos - 1)
end

function Misc.get_key_for_value( t, value )
    for k,v in pairs(t) do
      if v==value then return k end
    end
    return nil
end
  
return Misc;