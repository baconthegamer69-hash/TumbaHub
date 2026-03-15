-- gui/tabs/settings.lua
-- Content for the "SETTINGS" tab

local tabKey = "tab_settings"
local UI = Mega.UI

-- Create the container frame for this tab
local TabFrame = Instance.new("ScrollingFrame")
TabFrame.Name = tabKey
TabFrame.Size = UDim2.new(1, 0, 1, 0)
TabFrame.BackgroundTransparency = 1
TabFrame.BorderSizePixel = 0
TabFrame.ScrollBarThickness = 4
TabFrame.ScrollBarImageColor3 = Mega.Settings.Menu.AccentColor
TabFrame.Visible = false
TabFrame.Parent = Mega.Objects.ContentContainer

local ContentLayout = Instance.new("UIListLayout", TabFrame)
ContentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Padding = UDim.new(0, 8)

Mega.Objects.TabFrames[tabKey] = TabFrame

-- Защита от сбоев UI билдера: создаем нужные пути, если их нет
if not Mega.States.Localization then Mega.States.Localization = {} end
local currentLangMap = { en = "language_english", ru = "language_russian", es = "language_spanish", pt = "language_portuguese", ko = "language_korean", ja = "language_japanese", uk = "language_ukrainian" }
Mega.States.Localization.CurrentLanguage = currentLangMap[Mega.Localization.CurrentLanguage] or "language_english"

if not Mega.States.Settings then Mega.States.Settings = { Menu = {} } end
Mega.States.Settings.Menu.Transparency = math.floor((Mega.Settings.Menu.Transparency or 0.1) * 100)

if not Mega.States.Temp then Mega.States.Temp = {} end

--#region -- Appearance
UI.CreateSection(TabFrame, "section_settings_appearance")

UI.CreateDropdown(TabFrame, "dropdown_language", "Localization.CurrentLanguage", {
    "language_english", "language_russian", "language_spanish", "language_portuguese", "language_korean", "language_japanese", "language_ukrainian"
}, function(val)
    local langMap = {
        language_english = "en", language_russian = "ru", language_spanish = "es",
        language_portuguese = "pt", language_korean = "ko", language_japanese = "ja",
        language_ukrainian = "uk"
    }
    local lang = langMap[val] or "en"
    Mega.Localization.CurrentLanguage = lang
    Mega.SaveLanguage(lang)
    Mega.ShowNotification(Mega.GetText("notify_language_changed", Mega.GetText(val)), 3)
    
    if Mega.ReloadGUI then
        task.spawn(function() task.wait(0.2); Mega.ReloadGUI() end)
    end
end, true)

UI.CreateSlider(TabFrame, "slider_menu_transparency", "Settings.Menu.Transparency", 0, 100, function(v) 
    local trans = v / 100
    Mega.Settings.Menu.Transparency = trans
    if Mega.Objects.GUI and Mega.Objects.GUI:FindFirstChild("MainFrame") then
        Mega.Objects.GUI.MainFrame.BackgroundTransparency = trans
    end
end)

UI.CreateKeybindButton(TabFrame, "keybind_menu", "Keybinds.Menu", function(key)
    Mega.States.Keybinds.Menu = key
end)

UI.CreateButton(TabFrame, "button_change_theme", function()
    local colors = {
        Color3.fromRGB(255, 50, 50), Color3.fromRGB(0, 255, 255),
        Color3.fromRGB(50, 255, 100), Color3.fromRGB(200, 70, 255),
        Color3.fromRGB(255, 165, 0)
    }
    Mega.Settings.Menu.AccentColor = colors[math.random(1, #colors)]
    
    if Mega.ShowNotification then Mega.ShowNotification(Mega.GetText("notify_theme_changed"), 2) end
    if Mega.ReloadGUI then task.spawn(function() task.wait(0.2); Mega.ReloadGUI() end) end
end)
--#endregion

--#region -- Config Management
UI.CreateSection(TabFrame, "section_settings_config")

local _, configNameBox = UI.CreateTextBox(TabFrame, "textbox_config_name", Mega.GetText("textbox_config_name"))

local configDropdown
local function refreshConfigList()
    local configs = Mega.ConfigSystem.GetList()
    if #configs == 0 then table.insert(configs, "default") end
    if configDropdown then configDropdown:Destroy() end
    Mega.States.Temp.SelectedConfig = configs[1]
    configDropdown = UI.CreateDropdown(TabFrame, "dropdown_config_list", "Temp.SelectedConfig", configs, function(val) Mega.States.Temp.SelectedConfig = val end, false)
end

refreshConfigList() -- Initial population

UI.CreateButton(TabFrame, "button_config_save", function()
    local name = configNameBox.Text
    if name and name ~= "" then
        Mega.ConfigSystem.Save(name)
        Mega.ShowNotification(Mega.GetText("notify_config_saved"), 2)
        refreshConfigList()
    else
        Mega.ShowNotification(Mega.GetText("notify_enter_name"), 2)
    end
end)

UI.CreateButton(TabFrame, "button_config_load", function()
    local name = Mega.States.Temp and Mega.States.Temp.SelectedConfig
    if name and name ~= "" then
        Mega.ConfigSystem.Load(name)
        Mega.ShowNotification(Mega.GetText("notify_config_loaded"), 2)
        if Mega.ReloadGUI then
            task.spawn(function() task.wait(0.2); Mega.ReloadGUI() end)
        end
    end
end)

UI.CreateButton(TabFrame, "button_config_delete", function()
    local name = Mega.States.Temp and Mega.States.Temp.SelectedConfig
    if name and name ~= "" and name ~= "default" and isfile and isfile("TumbaConfig_" .. name .. ".json") then
        delfile("TumbaConfig_" .. name .. ".json")
        Mega.ShowNotification(Mega.GetText("notify_config_deleted"), 2)
        refreshConfigList()
    end
end)

UI.CreateButton(TabFrame, "button_config_refresh", refreshConfigList)
--#endregion

--#region -- Script Cleanup
UI.CreateSection(TabFrame, "button_cleanup")

UI.CreateButton(TabFrame, "button_cleanup", function()
    Mega.ShowNotification(Mega.GetText("notify_cleanup"), 2)
    -- Disconnect all connections
    for _, c in ipairs(Mega.Objects.Connections) do pcall(c.Disconnect, c) end
    for _, c in pairs(Mega.Objects.ESP or {}) do
        if type(c) == "table" then
            for _, d in pairs(c) do pcall(function() d:Remove() end) end
        end
    end
    -- Destroy all GUI elements
    if Mega.Objects.GUI then Mega.Objects.GUI:Destroy() end
    if Mega.Services.CoreGui:FindFirstChild("TumbaESP_Container") then Mega.Services.CoreGui.TumbaESP_Container:Destroy() end
    -- You might need to restore more original settings here (e.g. from Visuals)
end)
--#endregion
