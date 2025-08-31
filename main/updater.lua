
local utils = require("utils.misc")

local updater = {}

-- Execute command in specific directory
local function executeInDir(dir, command)
    local fullCommand = "cd " .. dir .. " && " .. command
    return os.execute(fullCommand)
end

-- Execute command in specific directory and return output
local function executeInDirReturn(dir, command)
    local tempFile = os.tmpname()
    local fullCommand = "cd " .. dir .. " && " .. command .. " > " .. tempFile .. " 2>&1"
    local success, termType, exitCode = os.execute(fullCommand)
    
    local file = io.open(tempFile, "r")
    local output = ""
    if file then
        output = file:read("*a")
        file:close()
        os.remove(tempFile)
    end
    
    return success, termType, exitCode, output
end

-- Read file content and clean it
local function readFile(filePath)
    local file = io.open(filePath, "r")
    if not file then
        return nil
    end
    
    local content = file:read("*a"):gsub("[\r\n%s]+", "")
    file:close()
    return content
end

-- Get git version information
function updater.getGitVersion()
    local tempFile = "git_version.txt"
    local scriptPath = utils.script_path()
    local redirect = MP.GetOSName() == "windows" and "2>nul" or "2>/dev/null"
    
    -- Get version from git tag
    local command = "git tag --contains HEAD " .. redirect .. " > " .. tempFile
    executeInDir(scriptPath, command)
    local version = readFile(scriptPath .. tempFile)
    
    -- Fallback to commit hash if no tag
    if not version or version == "" then
        command = "git rev-parse --short HEAD " .. redirect .. " > " .. tempFile
        executeInDir(scriptPath, command)
        version = readFile(scriptPath .. tempFile) or "unknown"
    end
    
    -- Get current branch
    command = "git rev-parse --abbrev-ref HEAD " .. redirect .. " > " .. tempFile
    executeInDir(scriptPath, command)
    local branch = readFile(scriptPath .. tempFile) or "unknown"
    
    -- Check if working directory is dirty
    command = "git status --porcelain " .. redirect .. " > " .. tempFile
    executeInDir(scriptPath, command)
    local status = readFile(scriptPath .. tempFile)
    local dirty = status and #status > 0 and "-dirty" or ""
    
    os.remove(scriptPath .. tempFile)
    
    return string.format("%s (%s)%s", version, branch, dirty)
end

-- Check for updates
function updater.check(cfgManager)
    local redirect = MP.GetOSName() == "windows" and "2>nul" or "2>/dev/null"
    
    -- Check if git is installed
    local gitCheck = os.execute("git --version " .. redirect)
    if not gitCheck then
        utils.nkprint("Git is not installed on your system. The auto updater will not work.", "warn")
        return
    end
    
    -- Check if this is a git repository
    if not FS.Exists(utils.script_path() .. ".git") then
        utils.nkprint("This project is not a Git repository. Initializing ...", "warn")
        updater.initGit()
        utils.nkprint("Project initialized successfully!", "info")
        return
    end
    
    -- Check if auto-updates are enabled
    if not cfgManager:GetSetting("advanced").autoupdate then
        utils.nkprint("Auto-updates are disabled. To enable them, set 'autoupdate' to 'true' in the configuration file.", "warn")
        return
    end
    
    local repoPath = utils.script_path()
    
    -- Fetch latest changes from remote
    local fetchSuccess, fetchTerm, fetchExit, fetchOut = executeInDirReturn(repoPath, "git fetch origin dev")
    print("Git fetch result:", fetchSuccess, fetchTerm, fetchExit, fetchOut)
    
    if fetchExit ~= 0 then
        utils.nkprint("Remote fetch failed: " .. (fetchOut or ""), "error")
        return
    end
    
    -- Get local and remote hashes
    local _, _, _, localHash = executeInDirReturn(repoPath, "git rev-parse HEAD")
    local _, _, _, remoteHash = executeInDirReturn(repoPath, "git rev-parse origin/dev")
    
    localHash = localHash and localHash:gsub("%s+", "") or nil
    remoteHash = remoteHash and remoteHash:gsub("%s+", "") or nil
    
    if not localHash or not remoteHash then
        utils.nkprint("Could not read local/remote hashes.", "warn")
        return
    end
    
    if localHash == remoteHash then
        utils.nkprint("No update available (HEAD == origin/dev).", "info")
        return
    end
    
    -- Pull latest changes
    utils.nkprint("New remote version detected: " .. localHash .. " -> " .. remoteHash, "info")
    local pullSuccess, pullTerm, pullExit, pullOut = executeInDirReturn(repoPath, "git pull --ff-only origin dev")
    print("Git pull result:", pullSuccess, pullTerm, pullExit, pullOut)
    
    if pullExit ~= 0 then
        utils.nkprint("Update failed: " .. (pullOut or ""), "error")
        return
    end
    
    -- Hot reload after successful update
    utils.RunAsync(function()
        utils.hotreload()
    end, 2000)
end

-- Initialize git repository
function updater.initGit()
    local scriptPath = utils.script_path()
    
    executeInDir(scriptPath, "git init")
    executeInDir(scriptPath, "git remote add origin https://github.com/boubouleuh/Nickel-BeamMP-Plugin.git")
    executeInDir(scriptPath, "git fetch origin dev")
    executeInDir(scriptPath, "git checkout -b main origin/dev")
end

return updater