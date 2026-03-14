-- gui/tabs/esp.lua
-- Content for the "ESP" tab

local tabKey = "tab_esp"
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
ContentLayout.Padding = UDim.new(0, 0)

Mega.Objects.TabFrames[tabKey] = TabFrame

-- Load the actual ESP logic feature module
Mega.LoadModule("features/esp.lua")

--#region -- Main Player ESP
UI.CreateSection(TabFrame, "section_esp_main")

UI.CreateToggleWithSettings(TabFrame, "toggle_esp", "ESP.Enabled", function(state)
    if Mega.Features.ESP then
        Mega.Features.ESP.SetEnabled(state)
    end
end, {
    UI.CreateSection(nil, "section_esp_visuals"),
    UI.CreateToggle(nil, "toggle_esp_boxes", "ESP.Boxes"),
    UI.CreateToggle(nil, "toggle_esp_names", "ESP.Names"),
    UI.CreateToggle(nil, "toggle_esp_health", "ESP.Health"),
    UI.CreateToggle(nil, "toggle_esp_distance", "ESP.Distance"),
    UI.CreateToggle(nil, "toggle_esp_tracers", "ESP.Tracers"),
    UI.CreateToggle(nil, "toggle_esp_team", "ESP.ShowTeam"),
    UI.CreateSlider(nil, "slider_esp_max_dist", "ESP.MaxDistance", 50, 2000),
    UI.CreateSection(nil, "section_esp_colors"),
    UI.CreateButton(nil, "button_team_color", function() Mega.ShowNotification("Color pickers are not implemented yet.", 3) end),
    UI.CreateButton(nil, "button_enemy_color", function() Mega.ShowNotification("Color pickers are not implemented yet.", 3) end)
})
--#endregion


--#region -- Kit ESP
UI.CreateSection(TabFrame, "section_kit_esp")

UI.CreateToggleWithSettings(TabFrame, "toggle_kit_esp", "KitESP.Enabled", function(state)
    if Mega.Features.ESP then
        Mega.Features.ESP.SetKitEnabled(state)
    end
    Mega.ShowNotification(Mega.GetText(state and "notify_kit_esp_on" or "notify_kit_esp_off"))
end, {
    UI.CreateSection(nil, "section_kit_filters"),
    UI.CreateToggle(nil, "toggle_kit_iron", "KitESP.Filters.Iron"),
    UI.CreateToggle(nil, "toggle_kit_bee", "KitESP.Filters.Bee"),
    UI.CreateToggle(nil, "toggle_kit_thorns", "KitESP.Filters.Thorns"),
    UI.CreateToggle(nil, "toggle_kit_mushrooms", "KitESP.Filters.Mushrooms"),
    UI.CreateToggle(nil, "toggle_kit_sorcerer", "KitESP.Filters.Sorcerer"),
    UI.CreateButton(nil, "button_kit_esp_apply", function()
        if Mega.Features.ESP then
            Mega.Features.ESP.RecreateKitESP()
        end
        Mega.ShowNotification(Mega.GetText("notify_kit_esp_updated"))
    end)
})
--#endregion

