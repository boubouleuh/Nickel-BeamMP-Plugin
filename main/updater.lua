
local utils = require("utils.misc")

local updater = {}


local function execute_in_dir(dir, command)
    local full_command = "cd " .. dir .. " && " .. command
    return os.execute(full_command)
end
local function execute_in_dir_popen(dir, command)
    local full_command = "cd " .. dir .. " && " .. command
    local handle = io.popen(full_command)
    if handle then
        local result = handle:read("*a")
        handle:close()
        return result
    end
    return nil -- Si la commande échoue
end

local function get_latest_commit(dir)
    local commit_hash = execute_in_dir(dir, "git rev-parse HEAD")
    if commit_hash then
        return commit_hash:match("%S+") -- Nettoie les espaces ou sauts de ligne
    else
        return nil -- Si la commande échoue
    end
end

-- 📌 Vérifie si le projet est déjà un dépôt Git
function updater.check()
    if not os.execute("git --version") then
        utils.nkprint("Git is not installed on your system. The auto updater will not work.", "warn")
        return
    end
    if FS.Exists(utils.script_path() .. ".git") then
        local before_pull = get_latest_commit(utils.script_path())
        execute_in_dir(utils.script_path(), "git pull origin dev")
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