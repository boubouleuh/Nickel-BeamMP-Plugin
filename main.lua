local function get_current_path()
    local str = debug.getinfo(1, "S").source
    if str:sub(1, 1) == "@" then
        str = str:sub(2)
    end
    if MP.GetOSName() == "Windows" then
        str = str:gsub("\\", "/")
    end
    return str:match("(.*/)")
end

if MP.GetOSName() == "Windows" then
    os.execute("chcp 65001")
        print("^ this is just to set utf-8 encoding on windows console so emoji print correctly ^")

    local include_path = get_current_path() .. "include/"
    for _, file in ipairs(FS.ListFiles(include_path)) do
        if FS.Exists(file) then
            goto continue
        end
        FS.Copy(include_path .. file, file)
        ::continue::
    end
end

local root_path = get_current_path()
local Tree = dofile(root_path .. "Tree/init.lua")

-- Make Tree global if needed, or just use it locally to load manifest
_G.Tree = Tree

print("[Nickel] Initializing via Tree framework...")
Tree.LoadManifest(root_path .. "nickel_manifest.lua", true)
print("[Nickel] Initialization complete.")
