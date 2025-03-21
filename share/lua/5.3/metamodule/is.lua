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
local ipairs = ipairs
local type = type
local find = string.find
local split = require('string.split')

local PAT_PKGNAME = '^[a-z0-9]+$'

--- return true if name is a valid package name
--- @param name string
--- @return boolean
local function isPackageName(name)
    if type(name) ~= 'string' then
        return false
    end

    for _, v in ipairs(split(name, '.', nil, true)) do
        if not find(v, PAT_PKGNAME) then
            return false
        end
    end

    return true
end

local PAT_MODNAME = '^[A-Z][a-zA-Z0-9]*$'

--- return true if name is a valid module name
--- @param name string
--- @return boolean
local function isModuleName(name)
    return type(name) == 'string' and find(name, PAT_MODNAME) ~= nil
end

local PAT_METAMETHOD = '^__[a-z]+$'

--- return true if name starts with two underscores(_)
--- @param name string
--- @return boolean
local function isMetamethodName(name)
    return type(name) == 'string' and find(name, PAT_METAMETHOD) ~= nil
end

return {
    packageName = isPackageName,
    PAT_MODNAME = PAT_MODNAME,
    moduleName = isModuleName,
    metamethodName = isMetamethodName,
}
