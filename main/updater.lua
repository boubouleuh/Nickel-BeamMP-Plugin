Updater = {}
Updater.target = ConfigManager.GetSetting("advanced").target or "main"

local function exec_cmd(path, cmd)
    local tmp = os.tmpname()
    local full_cmd = string.format("cd %q && %s > %q 2>&1", path, cmd, tmp)
    
    local success = os.execute(full_cmd)
    
    local f = io.open(tmp, "r")
    local out = f and f:read("*a") or ""
    if f then f:close() end
    os.remove(tmp)
    
    return success, out:gsub("^%s*(.-)%s*$", "%1")
end

function Updater.get_git_version(path)
    local path = path or Utils.script_path()
    local ok, out = exec_cmd(path, "git describe --tags --always --dirty")
    if not ok or out == "" then return "unknown (" .. Updater.target .. ")" end
    return string.format("%s (%s)", out, Updater.target)
end

function Updater.check(force)
    local path = Utils.script_path()
    local advanced = ConfigManager.GetSetting("advanced")
    
    if not FS.Exists(path .. ".git") then
        Utils.nkprint("Initializing Git Repository...", "warn")
        exec_cmd(path, "git init && git remote add origin https://github.com/boubouleuh/Nickel-BeamMP-Plugin.git")
        exec_cmd(path, "git fetch origin " .. Updater.target)
        exec_cmd(path, "git checkout -B " .. Updater.target .. " origin/" .. Updater.target)
    end

    if not advanced.autoupdate and not force then return end

    exec_cmd(path, "git fetch origin --tags")

    if advanced.update_type == "tags" then
        local _, latest = exec_cmd(path, "git ls-remote --tags --sort='v:refname' origin | tail -n1 | cut -d/ -f3")
        local _, current = exec_cmd(path, "git describe --tags --abbrev=0 2>/dev/null")

        if latest ~= current or force then
            Utils.nkprint("Update found: " .. (current or "none") .. " -> " .. latest, "info")
            if force then exec_cmd(path, "git stash") end
            local ok, err = exec_cmd(path, "git checkout tags/" .. latest)
            if not ok then Utils.nkprint("Update failed: " .. err, "error") end
        else
            Utils.nkprint("Plugin up to date (Tag: " .. latest .. ")", "info")
        end
    else
        local _, localH = exec_cmd(path, "git rev-parse HEAD")
        local _, remoteH = exec_cmd(path, "git rev-parse origin/" .. Updater.target)

        if localH ~= remoteH or force then
            Utils.nkprint("Updating branch " .. Updater.target .. "...", "info")
            if force then exec_cmd(path, "git stash") end
            local ok, err = exec_cmd(path, "git pull origin " .. Updater.target)
            if not ok then Utils.nkprint("Pull failed: " .. err, "error") end
        else
            Utils.nkprint("Branch " .. Updater.target .. " is up to date.", "info")
        end
    end
end

Nickel.CreateThread(function()
    Nickel.Wait(1000)
    Updater.check()
end)