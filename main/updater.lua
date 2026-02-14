Updater = {}
Updater.target = ConfigManager.GetSetting("advanced").target or "main"

local function isInCoroutine()
    local co, isMain = coroutine.running()
    return co ~= nil and not isMain
end

local function exec(path, cmd)
    if isInCoroutine() then
        local donefile = os.tmpname()
        os.execute("(cd " .. path .. " && " .. cmd .. " >/dev/null 2>&1; echo done > " .. donefile .. ") &")
        while true do
            local f = io.open(donefile, "r")
            if f then
                f:close()
                os.remove(donefile)
                return true
            end
            Nickel.Wait(50)
        end
    else
        return os.execute("cd " .. path .. " && " .. cmd)
    end
end

local function exec_ret(path, cmd)
    if isInCoroutine() then
        local tmp = os.tmpname()
        local donefile = tmp .. ".done"
        os.execute("(cd " .. path .. " && " .. cmd .. " > " .. tmp .. " 2>&1; echo $? > " .. donefile .. ") &")
        while true do
            local f = io.open(donefile, "r")
            if f then
                local exitCode = tonumber(f:read("*a"):match("(%d+)")) or -1
                f:close()
                local of = io.open(tmp, "r")
                local out = of and of:read("*a") or ""
                if of then of:close() end
                os.remove(tmp)
                os.remove(donefile)
                return exitCode == 0, exitCode, (out:gsub("^%s*(.-)%s*$", "%1"))
            end
            Nickel.Wait(50)
        end
    else
        local tmp = os.tmpname()
        local ok, _, code = os.execute("cd " .. path .. " && " .. cmd .. " > " .. tmp .. " 2>&1")
        local f = io.open(tmp, "r")
        local out = f and f:read("*a") or ""
        if f then f:close() end
        os.remove(tmp)
        return ok, code, (out:gsub("^%s*(.-)%s*$", "%1"))
    end
end

local function clean(str) return str and str:gsub("[\r\n%s]+", "") or "" end

local function update_tags(path, force)
    exec(path, "git fetch --tags origin")

    local _, code, current = exec_ret(path, "git describe --tags --exact-match HEAD")
    if code ~= 0 then current = nil else current = clean(current) end
    
    local allow_prerelease = ConfigManager.GetSetting("advanced").allow_prerelease
    local latest = nil

    -- Use GitHub API to check for releases
    local apiUrl = "https://api.github.com/repos/boubouleuh/Nickel-BeamMP-Plugin/releases"
    local _, _, jsonStr = exec_ret(path, "wget -qO - --header='User-Agent: Nickel' " .. apiUrl)
    local releases
    if jsonStr and jsonStr ~= "" then
        releases = Util.JsonDecode(jsonStr)
    end

    if releases and type(releases) == "table" then
        for _, release in ipairs(releases) do
            -- If we allow pre-releases OR if the release is NOT marked as pre-release on GitHub
            if allow_prerelease or not release.prerelease then
                latest = release.tag_name
                break
            end
        end
    else
         Utils.nkprint("Failed to fetch/decode releases from GitHub API.", "warn")
    end



    if not latest or latest == "" then
        return Utils.nkprint("No remote tags found.", "info")
    end

    if current and current ~= "" then
        -- Check if we are trying to downgrade (if latest is an ancestor of current, current is newer)
        local _, is_ancestor_code, _ = exec_ret(path, "git merge-base --is-ancestor tags/" .. latest .. " tags/" .. current)
        
        if not force and is_ancestor_code == 0 and latest ~= current then
             Utils.nkprint("Current version ("..current..") is ahead of latest configured version ("..latest.."). Skipping downgrade.", "info")
             return
        end

        if latest ~= current then
            Utils.nkprint("New tag available: " .. current .. " -> " .. latest, "info")
            if force then
                Utils.nkprint("Force update: Stashing local changes...", "info")
                exec(path, "git stash push -m \"Nickel AutoUpdate Stash\"")
            end
            local _, code, out = exec_ret(path, "git checkout tags/" .. latest)
            if code ~= 0 then Utils.nkprint("Checkout failed: " .. out, "error") end
        else
            Utils.nkprint("Up to date (tag: " .. current .. ")", "info")
        end
        return
    end

    local _, code, _ = exec_ret(path, "git merge-base --is-ancestor tags/" .. latest .. " HEAD")
    
    if not force and code == 0 then
        Utils.nkprint("Local version is ahead of latest tag (" .. latest .. "). Skipping update.", "info")
    else
        Utils.nkprint("Local version is older than tag " .. latest .. ". Updating...", "info")
        if force then
            Utils.nkprint("Force update: Stashing local changes...", "info")
            exec(path, "git stash push -m \"Nickel AutoUpdate Stash\"")
        end
        local _, code, out = exec_ret(path, "git checkout tags/" .. latest)
        if code ~= 0 then Utils.nkprint("Checkout failed: " .. out, "error") end
    end
end

local function update_target(path, force)
    exec(path, "git fetch origin " .. Updater.target)
    if force then
        Utils.nkprint("Force update: Stashing local changes...", "info")
        exec(path, "git stash push -m \"Nickel AutoUpdate Stash\"")

        local _, code, out = exec_ret(path, "git reset --hard origin/" .. Updater.target)
        if code ~= 0 then 
            Utils.nkprint("Force update failed: " .. out, "error") 
        else
            Utils.nkprint("Force updated target " .. Updater.target .. " (local changes stashed).", "info")
        end
        return
    end

    local _, _, localH = exec_ret(path, "git rev-parse HEAD")
    local _, _, remoteH = exec_ret(path, "git rev-parse origin/" .. Updater.target)
    
    if clean(localH) ~= clean(remoteH) then
        Utils.nkprint("Updating target " .. Updater.target .. "...", "info")
        local _, code, out = exec_ret(path, "git pull origin " .. Updater.target)
        if code ~= 0 then Utils.nkprint("Update failed: " .. out, "error") end
    else
        Utils.nkprint("Target " .. Updater.target .. " is up to date.", "info")
    end
end

function Updater.get_git_version(path)
    -- Single shell script to get tag, hash and dirty status
    local scriptFile = os.tmpname() .. ".sh"
    local sf = io.open(scriptFile, "w")
    if sf then
        sf:write('#!/bin/sh\n')
        sf:write('cd "' .. path .. '" 2>/dev/null\n')
        sf:write('TAG=$(git describe --tags --exact-match HEAD 2>/dev/null) || TAG=""\n')
        sf:write('HASH=$(git rev-parse --short HEAD 2>/dev/null) || HASH="unknown"\n')
        sf:write('STATUS=$(git status --porcelain 2>/dev/null)\n')
        sf:write('echo "TAG:${TAG}"\n')
        sf:write('echo "HASH:${HASH}"\n')
        sf:write('echo "STATUS:${STATUS}"\n')
        sf:close()
    end

    local _, _, combined = exec_ret(".", "sh " .. scriptFile)
    os.remove(scriptFile)

    local tag = clean(combined:match("TAG:([^\n]+)") or "")
    local hash = clean(combined:match("HASH:([^\n]+)") or "unknown")
    local status = combined:match("STATUS:([^\n]*)") or ""

    local version
    if tag ~= "" then
        version = tag
    else
        version = hash
    end
    
    local dirty = (clean(status) ~= "") and "-dirty" or ""
    
    return string.format("%s (%s)%s", version, Updater.target, dirty)
end

function Updater.check(force)
    if force == nil then force = false end
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

    if not ConfigManager.GetSetting("advanced").autoupdate and not force then return end

    if ConfigManager.GetSetting("advanced").update_type == "tags" then
        update_tags(path, force)
    else
        update_target(path, force)
    end
end

Nickel.CreateThread(function()
    Updater.check()
end)