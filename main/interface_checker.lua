InterfaceChecker = {}
InterfaceChecker.isInstalled = false
InterfaceChecker.zipPath = nil
local SIGNATURE_FILE = "lua/ge/extensions/nickel.lua"

function InterfaceChecker.CheckForInterfaceMod()
    local isWindows = MP.GetOSName() == "Windows"
    local searchDir = Utils.getBeamMPConfig().General.ResourceFolder .. "/Client/"
    
    if isWindows then
        searchDir = searchDir:gsub("/", "\\")
    end

    local foundZipPath = nil
    
    local zipFiles = {}
    local filesInDir = FS.ListFiles(searchDir)
    if filesInDir then
        for _, filename in pairs(filesInDir) do
             if FS.GetExtension(filename) == ".zip" then
                table.insert(zipFiles, filename)
             end
        end
    else
        Utils.nkprint("Unable to list files in " .. searchDir .. " (Check if the directory exists)", "error")
        return false, nil
    end

    for _, zipName in ipairs(zipFiles) do
        local fullPath = searchDir .. zipName
        local isMatch = false
        
        if isWindows then
            local resFile = "temp_zip_res.txt"
            local psScript = string.format([[
                $ErrorActionPreference = 'SilentlyContinue'
                Add-Type -AssemblyName System.IO.Compression.FileSystem
                $found = $false
                try {
                    $zip = [System.IO.Compression.ZipFile]::OpenRead('%s')
                    foreach($entry in $zip.Entries) {
                        if($entry.FullName -eq '%s') { $found = $true; break }
                    }
                    $zip.Dispose()
                } catch { 
                }
                if($found) { "MATCH" | Out-File -FilePath "%s" -Encoding ascii }
            ]], fullPath, SIGNATURE_FILE, resFile)
            
            local scriptFile = "check_zip.ps1"
            local f = io.open(scriptFile, "w")
            if f then
                f:write(psScript)
                f:close()
                os.execute('powershell -ExecutionPolicy Bypass -File "' .. scriptFile .. '"')
                os.remove(scriptFile)
                
                local rf = io.open(resFile, "r")
                if rf then
                    local content = rf:read("*a")
                    rf:close()
                    os.remove(resFile)
                    if content and content:match("MATCH") then
                        isMatch = true
                    end
                end
            end
        else
            local safePath = fullPath:gsub('"', '\\"')
            local tmp = os.tmpname()
            if coroutine.running() then
                local donefile = tmp .. ".done"
                os.execute('(unzip -l "' .. safePath .. '" > ' .. tmp .. ' 2>/dev/null; echo done > ' .. donefile .. ') &')
                while true do
                    local f = io.open(donefile, "r")
                    if f then
                        f:close()
                        os.remove(donefile)
                        break
                    end
                    Nickel.Wait(50)
                end
            else
                os.execute('unzip -l "' .. safePath .. '" > ' .. tmp .. ' 2>/dev/null')
            end
            local uf = io.open(tmp, "r")
            if uf then
                local content = uf:read("*a")
                uf:close()
                if content and content:find(SIGNATURE_FILE, 1, true) then
                    isMatch = true
                end
            end
            os.remove(tmp)
        end
        
        if isMatch then
            foundZipPath = fullPath
            break 
        end
    end

    if foundZipPath then
        Utils.nkprint("Interface Mod found in: " .. foundZipPath, "info")
        InterfaceChecker.isInstalled = true
        InterfaceChecker.zipPath = foundZipPath
        return true, foundZipPath
    else
        Utils.nkprint("Interface Mod not found in " .. searchDir .. " (Signature: " .. SIGNATURE_FILE .. ")", "warn")
        InterfaceChecker.isInstalled = false
        return false, nil
    end
end

-- Defer ZIP inspection to a thread (os.execute calls are blocking)
Nickel.CreateThread(function()
    InterfaceChecker.CheckForInterfaceMod()
end)
