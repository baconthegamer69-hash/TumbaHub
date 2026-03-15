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

    local content = nil
    local success = false
    
    -- 1. Сначала пробуем загрузить локальный файл (для тестов в VS Code)
    if isfile and readfile then
        local localPath = "tumbaHub/" .. path
        if isfile(localPath) then
            success, content = pcall(function() return readfile(localPath) end)
        elseif isfile(path) then
            success, content = pcall(function() return readfile(path) end)
        end
    end

    -- 2. Если локального файла нет, качаем с GitHub
    if not success or not content then
        local url = baseURL .. path
        success, content = pcall(function() return game:HttpGet(url) end)
        if success and content:find("404: Not Found") then success = false; content = nil end
    end

    if success and content then
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
Mega.LoadModule("features/noelle.lua")
Mega.LoadModule("features/lani.lua")
Mega.LoadModule("features/chest_steal.lua")
Mega.LoadModule("features/auto_deposit.lua")
Mega.LoadModule("features/killaura.lua")

-- Load the main GUI
Mega.LoadModule("gui/main_window.lua")

print("🔥 TUMBA MEGA SYSTEM (Refactored) LOADED SUCCESSFULLY!")
print("🎮 Use RightShift to open the menu")
