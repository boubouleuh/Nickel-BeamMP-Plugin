
local function get_current_path()
    local str = debug.getinfo(1, "S").source
    if str:sub(1, 1) == "@" then
        str = str:sub(2)
    end
    return str:match("(.*/)")
end

local root_path = get_current_path()
local Tree = dofile(root_path .. "Tree/init.lua")

-- Make Tree global if needed, or just use it locally to load manifest
_G.Tree = Tree

print("[Nickel] Initializing via Tree framework...")
Tree.LoadManifest(root_path .. "nickel_manifest.lua", true)
print("[Nickel] Initialization complete.")
