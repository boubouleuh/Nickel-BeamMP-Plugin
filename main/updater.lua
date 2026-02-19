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
    exec_cmd(path, "git fetch --tags")
    local ok, out = exec_cmd(path, "git describe --tags --always --dirty")
    if not ok or out == "" then return "unknown (" .. Updater.target .. ")" end
    return string.format("%s (%s)", out, Updater.target)
end
Nickel.Version = Updater.get_git_version()
function Updater.check(force)
    local path = Utils.script_path()
    local advanced = ConfigManager.GetSetting("advanced")
    local current_time = 0
    if FS.Exists(path .. ".git") then
        local ok, time_out = exec_cmd(path, "git log -1 --format=%ct")
        if ok then current_time = tonumber(time_out) or 0 end
    end
    if not FS.Exists(path .. ".git") then
        Utils.nkprint("Initializing Git Repository...", "warn")
        exec_cmd(path, string.format("git init -b %s", Updater.target))
        exec_cmd(path, "git remote add origin https://github.com/boubouleuh/Nickel-BeamMP-Plugin.git")
        
        if advanced.update_type == "tags" then
            exec_cmd(path, "git fetch --tags")
            local _, latest_data = exec_cmd(path, "git tag --sort=creatordate --format='%(creatordate:unix) %(refname:short)' | tail -n1")
            local latest_time_str, latest_name = latest_data:match("(%d+)%s+(.+)")
            
            if latest_name then
                exec_cmd(path, "git reset --hard " .. latest_name)
                current_time = tonumber(latest_time_str) or 0
            end
        else
            exec_cmd(path, "git fetch origin " .. Updater.target)
            exec_cmd(path, "git reset --hard origin/" .. Updater.target)
            exec_cmd(path, "git branch --set-upstream-to=origin/" .. Updater.target .. " " .. Updater.target)
        end
    end

    if not advanced.autoupdate and not force then return end

    exec_cmd(path, "git fetch origin --tags")

    if advanced.update_type == "tags" then
        local _, latest_data = exec_cmd(path, "git tag --sort=creatordate --format='%(creatordate:unix) %(refname:short)' | tail -n1")
        local latest_time_str, latest_name = latest_data:match("(%d+)%s+(.+)")
        local latest_time = tonumber(latest_time_str) or 0

        if latest_name and (latest_time > current_time or force) then
            Utils.nkprint("Update found: " .. latest_name, "info")
            exec_cmd(path, "git stash push -m \"Nickel AutoUpdate Backup\"")
            local ok, err = exec_cmd(path, "git reset --hard " .. latest_name)
            if not ok then 
                Utils.nkprint("Update failed: " .. err, "error") 
            else
                Utils.nkprint("Updated successfully to " .. latest_name, "info")
            end
        else
            Utils.nkprint("Plugin up to date", "info")
        end
    else
        local _, current_branch = exec_cmd(path, "git rev-parse --abbrev-ref HEAD")
        if current_branch ~= Updater.target then
            Utils.nkprint("Switching target branch to " .. Updater.target, "warn")
            exec_cmd(path, "git fetch origin " .. Updater.target)
            exec_cmd(path, "git checkout -B " .. Updater.target .. " origin/" .. Updater.target)
        end

        local _, localH = exec_cmd(path, "git rev-parse HEAD")
        local _, remoteH = exec_cmd(path, "git rev-parse origin/" .. Updater.target)
        if localH ~= remoteH or force then
            Utils.nkprint("Updating branch " .. Updater.target .. "...", "info")
            exec_cmd(path, "git stash push -m \"Nickel AutoUpdate Backup\"")
            local ok, err = exec_cmd(path, "git pull origin " .. Updater.target)
            if not ok then Utils.nkprint("Pull failed: " .. err, "error") end
        else
            Utils.nkprint("Branch up to date.", "info")
        end
    end
end

Nickel.CreateThread(function()
    Nickel.Wait(1000)
    Updater.check()
end)
