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
local gmatch = string.gmatch
local gsub = string.gsub
local sub = string.sub
local concat = table.concat

--- normalize path string
---@param s string
---@return string
local function normalize(s)
    local res = {}
    local len = 0

    -- remove double slash
    s = gsub(s, '/+', '/')
    -- extract segments
    for seg in gmatch(s, '[^/]+') do
        if seg == '..' then
            -- remove last segment if exists
            if len > 0 then
                res[len] = nil
                len = len - 1
            end
        elseif seg ~= '.' then
            -- add segment
            len = len + 1
            res[len] = seg
        end
    end

    local fc = sub(s, 1, 1)
    if fc == '/' then
        -- absolute path
        return '/' .. concat(res, '/')
    elseif fc == '.' then
        -- relative path
        return './' .. concat(res, '/')
    end
    -- relative path
    return concat(res, '/')
end

return normalize
