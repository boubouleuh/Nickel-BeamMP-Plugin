
local utils = require("utils.misc")

local updater = {}


local function execute_in_dir(dir, command)
    local full_command = "cd " .. dir .. " && " .. command
    return os.execute(full_command)
end


local function get_latest_commit(dir)
    local temp_file = "latest_commit.txt"
    local command = "cd " .. dir .. " && git rev-parse HEAD > " .. temp_file
    if os.execute(command) then
        local file = io.open(dir .. temp_file, "r")
        if file then
            local commit_hash = file:read("*l") -- Lire la première ligne
            file:close()
            os.remove(dir .. temp_file)
            print(commit_hash)
            return commit_hash
        end
    end
    return nil -- Si la commande échoue
end

-- 📌 Vérifie si le projet est déjà un dépôt Git
function updater.check()
    local git_check = execute_in_dir(utils.script_path(), "git --version > /dev/null 2>&1")
    if not git_check then
        utils.nkprint("Git is not installed on your system. The auto updater will not work.", "warn")
        return
    end
    if FS.Exists(utils.script_path() .. ".git") then
        local before_pull = get_latest_commit(utils.script_path())
        MP.Sleep(500)
        execute_in_dir(utils.script_path(), "git pull origin dev > /dev/null 2>&1")
        MP.Sleep(500)
        local after_pull = get_latest_commit(utils.script_path())

        if before_pull == after_pull then
            utils.nkprint("Already up to date.", "info")
        else
            utils.nkprint("Update applied successfully!", "success")
        end
    else
        utils.nkprint("This project is not a Git repository. Initializing ...", "warn")
        updater.init_git()
        utils.nkprint("Project initialized successfully!", "info")
    end
end

-- 🚀 Initialise un dépôt Git si besoin
function updater.init_git()
    execute_in_dir(utils.script_path(), "git init")
    execute_in_dir(utils.script_path(), "git remote add origin https://github.com/boubouleuh/Nickel-BeamMP-Plugin.git")
    execute_in_dir(utils.script_path(), "git fetch origin dev")
    execute_in_dir(utils.script_path(), "git checkout -b main origin/dev")

end

return updater