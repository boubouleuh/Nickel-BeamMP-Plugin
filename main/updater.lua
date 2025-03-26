
local utils = require("utils.misc")

local updater = {}

-- 📌 Vérifie si le projet est déjà un dépôt Git
function updater.check()
    if not os.execute("git --version") then
        utils.nkprint("Git is not installed on your system. The auto updater will not work.", "warn")
        return
    end
    if FS.Exists(utils.script_path() .. ".git") then
        os.execute("git pull origin dev")
    else
        utils.nkprint("This project is not a Git repository. Initializing ...", "warn")
        updater.init_git()
        utils.nkprint("Project initialized successfully!", "info")
    end
end

-- 🚀 Initialise un dépôt Git si besoin
function updater.init_git()
    os.execute("git init")
    os.execute("git remote add origin https://github.com/boubouleuh/Nickel-BeamMP-Plugin.git")
    os.execute("git fetch origin dev")
    os.execute("git checkout -b main origin/dev")
end

return updater