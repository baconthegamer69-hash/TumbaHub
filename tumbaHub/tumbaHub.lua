-- TUMBA MEGA CHEAT SYSTEM v5.0 (Refactored)
-- Main entry point & module loader
-- Made by @kreml1nAgent (tg)

if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- The global table that will hold everything
Mega = {
    Objects = {
        Connections = {},
        GUI = nil,
        PlayerListItems = {},
        Toggles = {},
        BeeCache = {}
    },
    Features = {},
    LoadedModules = {}
}

local baseURL = "https://raw.githubusercontent.com/baconthegamer69-hash/TumbaHub/main/tumbaHub/"

-- Module Loader
function Mega.LoadModule(path)
    if Mega.LoadedModules[path] then
        return
    end

    local url = baseURL .. path
    local success, content = pcall(function() return game:HttpGet(url) end)

    if success and content and not content:find("404: Not Found") then
        -- Wrap the module content in a function to pass the Mega table
        -- and control the environment.
        local chunk, err = loadstring("return function(Mega, game, script) " .. content .. " end")
        if chunk then
            local moduleFunc = chunk()
            local success, err = pcall(moduleFunc, Mega, game, script)
            if success then
                Mega.LoadedModules[path] = true
            else
                warn("Execution error in module:", path, "|", err)
            end
        else
            warn("Syntax error in module:", path, "|", err)
        end
    else
        warn("Failed to download module from GitHub:", path)
    end
end


-- Load core components in order
Mega.LoadModule("core/services.lua")
Mega.LoadModule("core/settings.lua")
Mega.LoadModule("core/localization.lua")
Mega.LoadModule("core/config.lua")

-- Load libraries
Mega.LoadModule("library/notifications.lua")
Mega.LoadModule("library/ui_builder.lua")

-- Load features
Mega.LoadModule("features/esp.lua")
Mega.LoadModule("features/aimbot.lua")
Mega.LoadModule("features/beekeeper.lua")
Mega.LoadModule("features/farmer_cletus.lua")
Mega.LoadModule("features/taliah.lua")
Mega.LoadModule("features/metal_detector.lua")
Mega.LoadModule("features/stella_star_collector.lua")

-- Load the main GUI
Mega.LoadModule("gui/main_window.lua")

print("🔥 TUMBA MEGA SYSTEM (Refactored) LOADED SUCCESSFULLY!")
print("🎮 Use RightShift to open the menu")
