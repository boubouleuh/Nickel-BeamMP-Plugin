--
-- Copyright (C) 2021 Masatoshi Fukunaga
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--
local type = type
local tostring = tostring
local format = string.format
local pairs = pairs

--- deep-copy the value of src
---@param val any
---@param key string
---@param circular table
---@return any value
---@return string? error
local function deepCopy(val, key, circular)
    if type(val) ~= 'table' then
        return val
    end

    local ref = tostring(val)
    -- circular reference
    if circular[ref] then
        return nil,
               format(
                   'unable to copy circularly referenced values: %q refers to %q',
                   key, circular[ref])
    end

    circular[ref] = key
    local tbl = {}
    for k, v in pairs(val) do
        local cpy, err = deepCopy(v, key .. '.' .. k, circular)
        if err then
            return nil, err
        end
        tbl[k] = cpy
    end
    circular[ref] = nil

    return tbl
end

return deepCopy
