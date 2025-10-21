local tree = {}

function tree.script_path()
  local separator = package.config:sub(1, 1)
  local scriptPath = debug.getinfo(1, "S").source:sub(2):gsub("[\\/][^\\/]+$", separator)
  local scriptDir = scriptPath:gsub(separator .. "utils" .. separator .. "$", separator)
  return scriptDir
end

function tree.execute_in_dir(dir, command)
    local full_command = "cd " .. dir .. " && " .. command
    return os.execute(full_command)
end


function tree.check_tree()
    local redirect = MP.GetOSName() == "windows" and "2>nul" or "2>/dev/null"
    local git_check = os.execute("git --version " .. redirect)
    if not git_check then
        Utils.nkprint("Git is not installed on your system. the plugin will not work.", "warn")
        return
    end
    local tree_path = "Resources/Server/Tree-BeamMP-Plugin/"
    if not FS.Exists(tree_path) then
        print("Tree Framework not found. Cloning ...")
        tree.execute_in_dir("Resources/Server/", "git clone https://github.com/Kipstz/Tree-BeamMP-Plugin.git")
        print("Tree Framework cloned successfully!")
    elseif not FS.Exists("Resources/Server/Tree-BeamMP-Plugin/.git") then
        print("Tree Framework is not a Git repository. Initializing ...")
        tree.execute_in_dir(tree_path, "git init")
        tree.execute_in_dir(tree_path, "git remote add origin https://github.com/Kipstz/Tree-BeamMP-Plugin.git")
        tree.execute_in_dir(tree_path, "git fetch origin main")
        tree.execute_in_dir(tree_path, "git checkout -b main origin/main")
        print("Tree Framework initialized successfully!")
    end
end

return tree