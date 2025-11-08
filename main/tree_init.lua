local tree = {}


tree.release = "25b9ec668291d4f18da3ae25ad1a6bc0eb61c92c"

function tree.get_release()
    return tree.release
end

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
        print("Git is not installed on your system. The plugin will not work.")
        return
    end

    local tree_path = "Resources/Server/Tree-BeamMP-Plugin/"
    local manual_release = tree.get_release()

    if not FS.Exists(tree_path) then
        print("Tree Framework not found. Cloning...")
        tree.execute_in_dir("Resources/Server/", "git clone https://github.com/Kipstz/Tree-BeamMP-Plugin.git")
        if manual_release then
            print("Tree: Checking out manual release: " .. manual_release)
            tree.execute_in_dir(tree_path, "git fetch --all --tags")
            tree.execute_in_dir(tree_path, "git checkout " .. manual_release)
        end
        print("Tree Framework cloned successfully!")
    end
end

return tree