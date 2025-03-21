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
local concat = table.concat
local error = error
local getinfo = debug.getinfo
local find = string.find
local format = string.format
local gsub = string.gsub
local match = string.match
local sub = string.sub
local trim_space = require('string.trim')
local split = require('string.split')
local ipairs = ipairs
local pairs = pairs
local setmetatable = setmetatable
local sort = table.sort
local tostring = tostring
local type = type
local pcall = pcall
local require = require
local dump = require('dump')
local deepcopy = require('metamodule.deepcopy')
local normalize = require('metamodule.normalize')
local eval = require('metamodule.eval')
local is = require('metamodule.is')
local seal = require('metamodule.seal')
--- constants
local PKG_PATH = (function()
    local list = split(package.path, ';', nil, true)
    local res = {}

    sort(list)
    for _, path in ipairs(list) do
        path = trim_space(path)
        if #path > 0 then
            path = normalize(path)
            path = gsub(path, '%.', '%%.')
            path = gsub(path, '%-', '%%-')
            path = gsub(path, '%?', '(.+)')
            res[#res + 1] = '^' .. path
        end
    end
    res[#res + 1] = '(.+)%.lua'

    return res
end)()
local REGISTRY = {
    -- data structure
    -- [<regname>] = {
    --     embeds = {
    --         [<list-of-embedded-module-names>, ...]
    --         [<embedded-module-name>] = <index-number-in-list>, ...]
    --     },
    --     metamethods = {
    --         __tostring = <function>,
    --         [<name> = <function>, ...]
    --     },
    --     methods = {
    --         init = <function>,
    --         instanceof = <function>,
    --         [<name> = <function>, ...]
    --     },
    --     vars = {
    --         _NAME = <string>,
    --         [_PACKAGE = <string>],
    --         [<name> = <non-function-value>, ...]
    --     }
    -- },
    -- [<instanceof-function>] = <regname>
}

local function DEFAULT_INITIALIZER(self)
    return self
end

local function DEFAULT_TOSTRING(self)
    return self._STRING
end

--- register new metamodule
--- @param s string
--- @vararg any
local function errorf(s, ...)
    local msg = format(s, ...)
    local calllv = 2
    local lv = 2
    local info = getinfo(lv, 'nS')

    while info do
        if info.what ~= 'C' and not find(info.source, 'metamodule') then
            calllv = lv
            break
        end
        -- prev = info
        lv = lv + 1
        info = getinfo(lv, 'nS')
    end

    return error(msg, calllv)
end

-- new_constructor
--- @param new_table function
--- @param metatable table
--- @param new_metatable function?
--- @return fun(...) constructor
local function new_constructor(new_table, metatable, new_metatable)
    --- @param ... any
    --- @return table _M
    return function(...)
        local instance = new_table()
        instance._STRING = gsub(tostring(instance), 'table', instance._NAME)
        if new_metatable then
            metatable = new_metatable()
        end

        setmetatable(instance, metatable)
        return instance:init(...)
    end
end

--- register new metamodule
--- @param regname string
--- @param decl table
--- @return function constructor
--- @return string? error
local function register(regname, decl)
    -- already registered
    if REGISTRY[regname] then
        return nil, format('%q is already registered', regname)
    end

    -- set <instanceof> method
    local src = format('return %q', regname)
    local instanceof, err = eval(src)
    if err then
        return nil, err
    end
    decl.methods['instanceof'] = instanceof

    -- set default <init> method
    if not decl.methods['init'] then
        decl.methods['init'] = DEFAULT_INITIALIZER
    end
    -- set default <__tostring> metamethod
    if not decl.metamethods['__tostring'] then
        decl.metamethods['__tostring'] = DEFAULT_TOSTRING
    end

    REGISTRY[regname] = decl
    REGISTRY[instanceof] = regname

    -- create metatable
    local metatable = {}
    for k, v in pairs(decl.metamethods) do
        metatable[k] = v
    end

    -- create method table
    local index = {}
    -- append all embedded module methods to the __index field
    local embeds = {}
    for _, name in ipairs(decl.embeds) do
        embeds[#embeds + 1] = name
    end
    while #embeds > 0 do
        local tbl = {}

        for i = 1, #embeds do
            local name = embeds[i]
            local m = REGISTRY[name]
            local methods = {}
            for k, v in pairs(m.methods) do
                methods[k] = v
            end
            index[name] = methods
            -- keeps the embedded module names
            for _, v in ipairs(m.embeds) do
                tbl[#tbl + 1] = v
            end
        end
        embeds = tbl
    end
    -- append methods
    for k, v in pairs(decl.methods) do
        index[k] = v
    end

    -- set methods to __index field if __index is defined
    local indexfn = metatable.__index
    local new_metatable
    if type(indexfn) == 'function' then
        -- create new metatable generation function
        --
        --  return {
        --      <key> = <id>.metamethods.<key>,
        --      __index = function(self, key)
        --          if <id>.methods[key] then
        --              return <id>.methods[key]
        --          else
        --              return __index(self, key)
        --          end
        --      end,
        --  }
        --
        local id = '__MM_' .. match(tostring(metatable), '0x%d+')
        local lines = {
            'return {',
            format([[
    __index = function(self, key)
        if %s.methods[key] then
            return %s.methods[key]
        else
            return %s.metamethods.__index(self, key)
        end
    end,]], id, id, id),
        }
        metatable.__index = nil
        for k in pairs(metatable) do
            lines[#lines + 1] = format('    %s = %s.metamethods.%s,', k, id, k)
        end
        metatable.__index = indexfn
        lines[#lines + 1] = '}'
        src = concat(lines, '\n')
        new_metatable, err = eval(src, {
            [id] = {
                methods = index,
                metamethods = metatable,
            },
        })
        if err then
            return nil, err
        end
    elseif indexfn ~= nil then
        errorf('__index must be function or nil')
    else
        metatable.__index = index
        index = nil
    end

    -- create new vars table generation function
    src = format('return %s', dump(decl.vars))
    local new_table
    new_table, err = eval(src)
    if err then
        return nil, err
    end

    -- create constructor
    return new_constructor(new_table, metatable, new_metatable)
end

--- load registered module
--- @param regname string
--- @return table module
--- @return string? error
local function loadModule(regname)
    local m = REGISTRY[regname]

    -- if it is not registered yet, try to load a module
    if not m then
        local segs = split(regname, '.', nil, true)
        local nseg = #segs
        local pkg = regname

        -- remove module-name
        if nseg > 1 and is.moduleName(segs[nseg]) then
            pkg = concat(segs, '.', 1, nseg - 1)
        end

        if is.packageName(pkg) then
            -- load package in protected mode
            local ok, err = pcall(function()
                require(pkg)
            end)

            if not ok then
                return nil, err
            end

            -- get loaded module
            m = REGISTRY[regname]
        end
    end

    if not m then
        return nil, 'not found'
    end

    return m
end

local IDENT_FIELDS = {
    ['_PACKAGE'] = true,
    ['_NAME'] = true,
    ['_STRING'] = true,
}

--- embed methods and metamethods of modules to module declaration table and
--- returns the list of module names and the methods of all modules
--- @param decl table
--- @param ... string base module names
--- @return table moduleNames
local function embedModules(decl, ...)
    local moduleNames = {}
    local chkdup = {}
    local vars = {}
    local methods = {}
    local metamethods = {}

    for _, regname in ipairs({
        ...,
    }) do
        -- check for duplication
        if chkdup[regname] then
            errorf('cannot embed module %q twice', regname)
        end
        chkdup[regname] = true
        moduleNames[#moduleNames + 1] = regname
        moduleNames[regname] = #moduleNames

        local m, err = loadModule(regname)

        -- unable to load the specified module
        if err then
            errorf('cannot embed module %q: %s', regname, err)
        end

        -- embed m.vars
        local circular = {
            [tostring(m.vars)] = regname,
        }
        for k, v in pairs(m.vars) do
            -- if no key other than the identity key is defined in the VAR,
            -- copy the key-value pairs.
            if not IDENT_FIELDS[k] and not decl.vars[k] then
                v, err = deepcopy(v, regname .. '.' .. k, circular)
                if err then
                    errorf('field %q cannot be used: %s', k, err)
                end
                -- overwrite the field of previous embedded module
                vars[k] = v
            end
        end

        -- embed m.metamethods
        for k, v in pairs(m.metamethods) do
            if not decl.metamethods[k] then
                -- overwrite the field of previous embedded module
                metamethods[k] = v
            end
        end

        -- add embedded module methods into methods.<regname> field
        for k, v in pairs(m.methods) do
            if not decl.methods[k] then
                -- overwrite the field of previous embedded module
                methods[k] = v
            end
        end
    end

    -- add vars, methods and metamethods field of embedded modules
    for src, dst in pairs({
        [vars] = decl.vars,
        [methods] = decl.methods,
        [metamethods] = decl.metamethods,
    }) do
        for k, v in pairs(src) do
            if not dst[k] then
                dst[k] = v
            end
        end
    end

    return moduleNames
end

local RESERVED_FIELDS = {
    ['constructor'] = true,
    ['instanceof'] = true,
}

local METAFIELD_TYPES = {
    __add = 'function',
    __sub = 'function',
    __mul = 'function',
    __div = 'function',
    __mod = 'function',
    __pow = 'function',
    __unm = 'function',
    __idiv = 'function',
    __band = 'function',
    __bor = 'function',
    __bxor = 'function',
    __bnot = 'function',
    __shl = 'function',
    __shr = 'function',
    __concat = 'function',
    __len = 'function',
    __eq = 'function',
    __lt = 'function',
    __le = 'function',
    __index = 'function',
    __newindex = 'function',
    __call = 'function',
    __tostring = 'function',
    __gc = 'function',
    __mode = 'string',
    __name = 'string',
    __close = 'function',
}

--- inspect module declaration table
--- @param regname string
--- @param moddecl table
--- @return table delc
local function inspect(regname, moddecl)
    local circular = {
        [tostring(moddecl)] = regname,
    }
    local vars = {}
    local methods = {}
    local metamethods = {}

    for k, v in pairs(moddecl) do
        local vt = type(v)

        if type(k) ~= 'string' then
            errorf('field name must be string: %q', tostring(k))
        elseif IDENT_FIELDS[k] or RESERVED_FIELDS[k] then
            errorf('reserved field %q cannot be used', k)
        end

        if is.metamethodName(k) then
            if vt ~= 'function' then
                if METAFIELD_TYPES[k] == 'function' then
                    errorf('the type of metatable field %q must be %s', k,
                           METAFIELD_TYPES[k])
                end

                -- use as variable
                local cpval, err = deepcopy(v, regname .. '.' .. k, circular)
                if err then
                    errorf('field %q cannot be used: %s', k, err)
                end
                v = cpval
            end
            metamethods[k] = v
        elseif vt == 'function' then
            -- use as method
            methods[k] = v
        elseif k == 'init' then
            errorf('field "init" must be function')
        else
            -- use as variable
            local cpval, err = deepcopy(v, regname .. '.' .. k, circular)
            if err then
                errorf('field %q cannot be used: %s', k, err)
            end
            -- use as variable
            vars[k] = cpval
        end
    end

    return {
        vars = vars,
        methods = methods,
        metamethods = metamethods,
    }
end

--- create constructor of new metamodule
--- @param pkgname string
--- @param modname string
--- @param moddecl table
--- @param ... string base module names
--- @return function constructor
local function new(pkgname, modname, moddecl, ...)
    -- verify modname
    if modname ~= nil and not is.moduleName(modname) then
        errorf('module name must be the following pattern string: %q',
               is.PAT_MODNAME)
    end
    -- prepend package-name
    local regname = modname

    if not pkgname then
        if not modname then
            errorf('module name must not be nil')
        end
    elseif modname then
        regname = pkgname .. '.' .. modname
    else
        regname = pkgname
    end

    -- verify moddecl
    if type(moddecl) ~= 'table' then
        errorf('module declaration must be table')
    end

    -- prevent duplication
    if REGISTRY[regname] then
        if pkgname then
            errorf('module name %q already defined in package %q',
                   modname or pkgname, pkgname)
        end
        errorf('module name %q already defined', modname)
    end

    -- inspect module declaration table
    local decl = inspect(regname, moddecl)

    -- embed another modules
    decl.embeds = embedModules(decl, ...)
    -- register to registry
    decl.vars._PACKAGE = pkgname
    decl.vars._NAME = regname
    local newfn, err = register(regname, decl)
    if err then
        errorf('failed to register %q: %s', regname, err)
    end

    -- seal the declaration table to prevent misuse
    seal(moddecl)

    return newfn
end

--- converts pathname in package.path to module names
--- @param s string
--- @return string|nil
local function pathname2modname(s)
    for _, pattern in ipairs(PKG_PATH) do
        local cap = match(s, pattern)
        if cap then
            -- remove '/init' suffix
            cap = gsub(cap, '/init$', '')
            return gsub(cap, '/', '.')
        end
    end
end

--- get the package name from the filepath of the 'new' function caller.
--- the package name is the same as the modname argument of the require function.
--- returns nil if called by a function other than the require function.
--- @return string|nil
local function get_pkgname()
    -- get a pathname of 'new' function caller
    local pathname = normalize(sub(getinfo(3, 'nS').source, 2))
    local lv = 4

    -- traverse call stack to search 'require' function
    repeat
        local info = getinfo(lv, 'nS')

        if info then
            if info.what == 'C' and info.name == 'require' then
                -- found source of 'require' function
                return pathname2modname(pathname)
            end
            -- check next level
            lv = lv + 1
        end
    until info == nil
end

--- instanceof
--- @param obj any
--- @param name? string
--- @return boolean
local function instanceof(obj, name)
    if type(name) ~= 'string' then
        error('name must be string', 2)
    elseif type(obj) ~= 'table' or type(obj.instanceof) ~= 'function' then
        return false
    end

    local regname = REGISTRY[obj.instanceof]
    if not regname then
        -- obj is not metamodule
        return false
    elseif regname == name then
        return true
    end

    -- search in embeds field
    return REGISTRY[regname].embeds[name] ~= nil
end

--- dump registry table
--- @return string
local function dumpRegstiry()
    return dump(REGISTRY)
end

return {
    dump = dumpRegstiry,
    instanceof = instanceof,
    new = setmetatable({}, {
        __metatable = 1,
        __newindex = function(_, k)
            errorf('attempt to assign to a readonly property: %q', k)
        end,
        --- wrapper function to create a new metamodule
        -- usage: metamodule.<modname>([moddecl, [embed_module, ...]])
        __index = function(_, modname)
            local pkgname = get_pkgname()
            return function(...)
                return new(pkgname, modname, ...)
            end
        end,
        __call = function(_, ...)
            local pkgname = get_pkgname()
            return new(pkgname, nil, ...)
        end,
    }),
}
