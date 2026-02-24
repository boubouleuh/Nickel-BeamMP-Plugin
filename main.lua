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
    if _VERSION == "Lua 5.4" then
        print("[Nickel] Error : Sorry Nickel cant work on this server binary, please read the readme.md file to be helped using the required binary")
        print("[Nickel] Discord if you want to ask for help : https://discord.gg/h5P84FFw7B")
        return
    end
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
local ok, Tree = pcall(dofile, root_path .. "Tree/init.lua")

if not ok then
    print("^1[Nickel] CRITICAL ERROR: Failed to load Tree framework.^r")
    print(tostring(Tree))
    return
end

print("[Nickel] Loaded Tree framework.")
-- Make Tree global if needed, or just use it locally to load manifest
_G.Tree = Tree

print("[Nickel] Initializing via Tree framework...")
local success, err = pcall(Tree.LoadManifest, root_path .. "nickel_manifest.lua", true)
if not success then
    print("^1[Nickel] Manifest loading failed: " .. tostring(err) .. "^r")
else
    print("[Nickel] Initialization complete.")
end