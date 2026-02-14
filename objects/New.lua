New = {}

function New._object(class, o)
   o = o or {}
   setmetatable(o, { __index = class })
   return o
end
