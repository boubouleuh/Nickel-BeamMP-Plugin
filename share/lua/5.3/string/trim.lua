--
-- Copyright (C) 2022 Masatoshi Fukunaga
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
--- file-scope variables
local error = error
local type = type
local find = string.find
local format = string.format
local sub = string.sub
local setmetatable = setmetatable

--- trim_space returns s with all leading and trailing whitespace removed.
--- @param s string
--- @return string
local function trim_space(_, s)
    if type(s) ~= 'string' then
        error(format('invalid argument #1 (string expected, got %s)', type(s)),
              2)
    elseif s == '' then
        return ''
    end

    -- remove leading whitespaces
    local _, pos = find(s, '^%s+')
    if pos then
        s = sub(s, pos + 1)
    end

    -- remove trailing whitespaces
    pos = find(s, '%s+$')
    if pos then
        return sub(s, 1, pos - 1)
    end

    return s
end

--- trim_suffix returns s with the suffix removed.
--- @param s string
--- @param suffix string
--- @return string
local function trim_suffix(s, suffix)
    if type(s) ~= 'string' then
        error(format('invalid argument #1 (string expected, got %s)', type(s)),
              2)
    elseif type(suffix) ~= 'string' then
        error(format('invalid argument #2 (string expected, got %s)',
                     type(suffix)), 2)
    end

    local len = #s
    local slen = #suffix
    if len == 0 or slen == 0 or len < slen then
        return s
    elseif s == suffix then
        return ''
    elseif sub(s, -slen) == suffix then
        -- remove suffix
        return sub(s, 1, len - slen)
    end

    return s
end

--- trim_prefix returns s with the prefix removed.
--- @param s string
--- @param prefix string
--- @return string
local function trim_prefix(s, prefix)
    if type(s) ~= 'string' then
        error(format('invalid argument #1 (string expected, got %s)', type(s)),
              2)
    elseif type(prefix) ~= 'string' then
        error(format('invalid argument #2 (string expected, got %s)',
                     type(prefix)), 2)
    end

    local len = #s
    local plen = #prefix
    if len == 0 or plen == 0 or len < plen then
        return s
    elseif s == prefix then
        return ''
    elseif sub(s, 1, plen) == prefix then
        -- remove prefix
        return sub(s, plen + 1)
    end

    return s
end

return setmetatable({
    prefix = trim_prefix,
    suffix = trim_suffix,
}, {
    __call = trim_space,
})
