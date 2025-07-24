
local utils = require("utils.misc")

local updater = {}


local function execute_in_dir(dir, command)
    local full_command = "cd " .. dir .. " && " .. command
    return os.execute(full_command)
end

function updater.get_git_version()
    local temp_file = "git_version.txt"
    local script_path = utils.script_path()
    local redirect = MP.GetOSName() == "windows" and "2>nul" or "2>/dev/null"

    local function read_file(file_path)
        local file = io.open(file_path, "r")
        if file then
            local content = file:read("*a"):gsub("[\r\n%s]+", "")
            file:close()
            return content
        end
        return nil
    end

    local command = "git tag --contains HEAD " .. redirect .. " > " .. temp_file
    execute_in_dir(script_path, command)
    local version = read_file(script_path .. temp_file)

    if not version or version == "" then
        command = "git rev-parse --short HEAD " .. redirect .. " > " .. temp_file
        execute_in_dir(script_path, command)
        version = read_file(script_path .. temp_file) or "unknown"
    end

    command = "git rev-parse --abbrev-ref HEAD " .. redirect .. " > " .. temp_file
    execute_in_dir(script_path, command)
    local branch = read_file(script_path .. temp_file) or "unknown"

    command = "git status --porcelain " .. redirect .. " > " .. temp_file
    execute_in_dir(script_path, command)
    local status = read_file(script_path .. temp_file)
    local dirty = status and #status > 0 and "-dirty" or ""

    os.remove(script_path .. temp_file) 

    return string.format("%s (%s)%s", version, branch, dirty)
end

function updater.check(cfgManager)
    local redirect = MP.GetOSName() == "windows" and "2>nul" or "2>/dev/null"
    local git_check = os.execute("git --version " .. redirect)
    if not git_check then
        utils.nkprint("Git is not installed on your system. The auto updater will not work.", "warn")
        return
    end
    if FS.Exists(utils.script_path() .. ".git") then
        if cfgManager:GetSetting("advanced").autoupdate then
            local success, termType, exitCode = execute_in_dir(utils.script_path(), "git pull origin dev")
            print("Git pull result: ", success, termType, exitCode)
            if exitCode == 0 then
                utils.RunAsync(function()
                   utils.hotreload()
                end, 2000)
            end
        else
            utils.nkprint("Auto-updates are disabled. To enable them, set 'autoupdate' to 'true' in the configuration file.", "warn")
        end
    else
        utils.nkprint("This project is not a Git repository. Initializing ...", "warn")
        updater.init_git()
        utils.nkprint("Project initialized successfully!", "info")
    end
end

function updater.init_git()
    execute_in_dir(utils.script_path(), "git init")
    execute_in_dir(utils.script_path(), "git remote add origin https://github.com/boubouleuh/Nickel-BeamMP-Plugin.git")
    execute_in_dir(utils.script_path(), "git fetch origin dev")
    execute_in_dir(utils.script_path(), "git checkout -b main origin/dev")

end

return updater