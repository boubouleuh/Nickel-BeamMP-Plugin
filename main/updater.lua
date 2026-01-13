Updater = {}
Updater.target = ConfigManager.GetSetting("advanced").target or "main"

local function exec(path, cmd)
    return os.execute("cd " .. path .. " && " .. cmd)
end

local function exec_ret(path, cmd)
    local tmp = os.tmpname()
    local ok, type, code = os.execute("cd " .. path .. " && " .. cmd .. " > " .. tmp .. " 2>&1")
    local f = io.open(tmp, "r")
    local out = f and f:read("*a") or ""
    if f then f:close() end
    os.remove(tmp)
    return ok, code, (out:gsub("^%s*(.-)%s*$", "%1"))
end

local function clean(str) return str and str:gsub("[\r\n%s]+", "") or "" end

local function update_tags(path)
    exec(path, "git fetch --tags origin")

    local _, code, current = exec_ret(path, "git describe --tags --exact-match HEAD")
    if code ~= 0 then current = nil else current = clean(current) end
    
    local allow_prerelease = ConfigManager.GetSetting("advanced").allow_prerelease
    local latest = nil

    -- Get all tags merged into target, sorted by version descending
    local _, code, out = exec_ret(path, "git tag --merged origin/" .. Updater.target .. " --sort=-v:refname")
    
    if code == 0 and out then
        for tag in out:gmatch("[^\r\n]+") do
            tag = clean(tag)
            if tag ~= "" then
                if allow_prerelease then
                    latest = tag
                    break
                else
                    -- Exclude pre-releases (containing hyphen)
                    if not tag:match("-") then
                        latest = tag
                        break
                    end
                end
            end
        end
    end

    if not latest or latest == "" then
        -- Fallback: try git describe
        local _, _, desc = exec_ret(path, "git describe --tags --abbrev=0 origin/" .. Updater.target)
        latest = clean(desc)
        
        -- If we found a tag but it's a pre-release and we don't allow them, check if we should skip
        if latest and latest ~= "" and not allow_prerelease and latest:match("-") then
             Utils.nkprint("Latest tag found is a pre-release ("..latest..") but allow_prerelease is false. Skipping update.", "info")
             return
        end
    end

    if not latest or latest == "" then
        return Utils.nkprint("No remote tags found.", "info")
    end

    if current and current ~= "" then
        -- Check if we are trying to downgrade (if latest is an ancestor of current, current is newer)
        local _, is_ancestor_code, _ = exec_ret(path, "git merge-base --is-ancestor tags/" .. latest .. " tags/" .. current)
        
        if is_ancestor_code == 0 and latest ~= current then
             Utils.nkprint("Current version ("..current..") is ahead of latest configured version ("..latest.."). Skipping downgrade.", "info")
             return
        end

        if latest ~= current then
            Utils.nkprint("New tag available: " .. current .. " -> " .. latest, "info")
            local _, code, out = exec_ret(path, "git checkout tags/" .. latest)
            if code ~= 0 then Utils.nkprint("Checkout failed: " .. out, "error") end
        else
            Utils.nkprint("Up to date (tag: " .. current .. ")", "info")
        end
        return
    end

    local _, code, _ = exec_ret(path, "git merge-base --is-ancestor tags/" .. latest .. " HEAD")
    
    if code == 0 then
        Utils.nkprint("Local version is ahead of latest tag (" .. latest .. "). Skipping update.", "info")
    else
        Utils.nkprint("Local version is older than tag " .. latest .. ". Updating...", "info")
        local _, code, out = exec_ret(path, "git checkout tags/" .. latest)
        if code ~= 0 then Utils.nkprint("Checkout failed: " .. out, "error") end
    end
end

local function update_target(path)
    exec(path, "git fetch origin " .. Updater.target)
    local _, _, localH = exec_ret(path, "git rev-parse HEAD")
    local _, _, remoteH = exec_ret(path, "git rev-parse origin/" .. Updater.target)
    
    if clean(localH) ~= clean(remoteH) then
        Utils.nkprint("Updating target " .. Updater.target .. "...", "info")
        local _, code, out = exec_ret(path, "git pull --ff-only origin " .. Updater.target)
        if code ~= 0 then Utils.nkprint("Update failed: " .. out, "error") end
    else
        Utils.nkprint("Target " .. Updater.target .. " is up to date.", "info")
    end
end

function Updater.get_git_version(path)
    local _, code, version = exec_ret(path, "git describe --tags --exact-match HEAD")
    
    if code ~= 0 then
        local _, _, hash = exec_ret(path, "git rev-parse --short HEAD")
        version = clean(hash) or "unknown"
    else
        version = clean(version)
    end
    
    local _, _, status = exec_ret(path, "git status --porcelain")
    local dirty = (status and #status > 0) and "-dirty" or ""
    
    return string.format("%s (%s)%s", version, Updater.target, dirty)
end

function Updater.check()
    local path = Utils.script_path()
    if not FS.Exists(path .. ".git") then
        Utils.nkprint("Initializing Git...", "warn")
        exec(path, "git init")
        exec(path, "git remote add origin https://github.com/boubouleuh/Nickel-BeamMP-Plugin.git")
        exec(path, "git fetch origin " .. Updater.target)
        exec(path, "git checkout -B " .. Updater.target)
        exec(path, "git reset origin/" .. Updater.target)
        exec(path, "git branch --set-upstream-to=origin/" .. Updater.target .. " " .. Updater.target)
    end

    if not ConfigManager.GetSetting("advanced").autoupdate then return end

    if ConfigManager.GetSetting("advanced").update_type == "tags" then
        update_tags(path)
    else
        update_target(path)
    end
end

Updater.check()