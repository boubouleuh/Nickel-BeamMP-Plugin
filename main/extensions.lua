ExtensionsManager = {}

function ExtensionsManager.init()
    local extensionsPath = Utils.script_path() .. "extensions"
    local dirs = FS.ListDirectories(extensionsPath)
    local loadedExtensions = {}

    if dirs then
        for _, dir in pairs(dirs) do
            local manifestPath = extensionsPath .. "/" .. dir .. "/ext_manifest.lua"
            if FS.Exists(manifestPath) then
                Nickel.LoadManifest(manifestPath)
                table.insert(loadedExtensions, dir)
                Utils.nkprint("Extension loaded: " .. dir, "info")
            end
        end
    end

    if #loadedExtensions > 0 then
        Utils.nkprint("Extensions loaded (" .. #loadedExtensions .. "): " .. table.concat(loadedExtensions, ", "), "info")
    else
        Utils.nkprint("No extensions found or loaded.", "warn")
    end
end

ExtensionsManager.init()