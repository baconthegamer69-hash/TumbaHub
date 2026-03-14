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
    -- Here you would ideally reload the entire GUI to apply language changes
end, true)

UI.CreateSlider(TabFrame, "slider_menu_transparency", "Settings.Menu.Transparency", 0, 100, function(v) 
    local trans = v / 100
    Mega.Settings.Menu.Transparency = trans
    if Mega.Objects.GUI then
        Mega.Objects.GUI.MainFrame.BackgroundTransparency = trans
    end
end)

UI.CreateKeybindButton(TabFrame, "keybind_menu", "Keybinds.Menu")

UI.CreateButton(TabFrame, "button_change_theme", function() Mega.ShowNotification("Theme changing is not implemented yet.", 3) end)
--#endregion

--#region -- Config Management
UI.CreateSection(TabFrame, "section_settings_config")

local _, configNameBox = UI.CreateTextBox(TabFrame, "textbox_config_name", Mega.GetText("textbox_config_name"))

local configDropdown
local function refreshConfigList()
    local configs = Mega.ConfigSystem.GetList()
    if configDropdown then configDropdown:Destroy() end
    configDropdown = UI.CreateDropdown(TabFrame, "dropdown_config_list", "Temp.SelectedConfig", configs)
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
        -- You would need a full GUI refresh function here
    end
end)

UI.CreateButton(TabFrame, "button_config_delete", function()
    local name = Mega.States.Temp and Mega.States.Temp.SelectedConfig
    if name and name ~= "" and isfile and isfile("TumbaConfig_" .. name .. ".json") then
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
    -- Destroy all GUI elements
    if Mega.Objects.GUI then Mega.Objects.GUI:Destroy() end
    -- You might need to restore more original settings here (e.g. from Visuals)
end)
--#endregion

