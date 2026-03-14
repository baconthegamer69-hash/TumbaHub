-- gui/tabs/farm.lua
-- Content for the "KIT" (Farm) tab

local tabKey = "tab_farm"
local UI = Mega.UI

-- Ensure states exist to prevent errors (Fallback defaults)
if not Mega.States.Beekeeper then Mega.States.Beekeeper = { Enabled = false, ShowIcons = true, ShowHighlight = true, ShowHiveLevels = false, AutoCatch = false } end
if not Mega.States.Cletus then Mega.States.Cletus = { Enabled = false, Range = 20, AutoHarvest = false, ESP = false, ESPTransparency = 0.75 } end
if not Mega.States.Eldertree then Mega.States.Eldertree = { Enabled = false, Range = 30, ESP = false } end
if not Mega.States.StarCollector then Mega.States.StarCollector = { Enabled = false, Range = 60, ESP = false } end
if not Mega.States.Metal then Mega.States.Metal = { Enabled = false, ESP = true, AutoCollect = false, Range = 25 } end
if not Mega.States.Taliah then Mega.States.Taliah = { Enabled = false, ESP = false, ESPTransparency = 0.2, AutoCollect = false, CollectRadius = 5 } end
if not Mega.States.Fisherman then Mega.States.Fisherman = { Enabled = false } end
if not Mega.States.Noelle then Mega.States.Noelle = { Enabled = false, SaveBinds = false, Binds = {} } end

-- Load feature modules for this tab
Mega.LoadModule("features/beekeeper.lua")
Mega.LoadModule("features/farmer_cletus.lua")
Mega.LoadModule("features/eldertree.lua")

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

--#region -- Beekeeper
UI.CreateToggleWithSettings(TabFrame, "toggle_beekeeper", "Beekeeper.Enabled", function(state)
    if Mega.Features.Beekeeper then
        Mega.Features.Beekeeper.SetEnabled(state)
    end
end, {
    UI.CreateToggle(nil, "toggle_bee_icons", "Beekeeper.ShowIcons", function() if Mega.Features.Beekeeper then Mega.Features.Beekeeper.UpdateVisuals() end end),
    UI.CreateToggle(nil, "toggle_bee_highlight", "Beekeeper.ShowHighlight", function() if Mega.Features.Beekeeper then Mega.Features.Beekeeper.UpdateVisuals() end end),
    UI.CreateToggle(nil, "toggle_hive_levels", "Beekeeper.ShowHiveLevels", function() if Mega.Features.Beekeeper then Mega.Features.Beekeeper.UpdateVisuals() end end),
    UI.CreateToggle(nil, "toggle_auto_catch", "Beekeeper.AutoCatch")
})
--#endregion

--#region -- Cletus
UI.CreateToggleWithSettings(TabFrame, "toggle_cletus", "Cletus.Enabled", function(state)
    if Mega.Features.Cletus then
        Mega.Features.Cletus.SetEnabled(state)
    end
end, {
    UI.CreateToggle(nil, "toggle_cletus_harvest", "Cletus.AutoHarvest"),
    UI.CreateToggle(nil, "toggle_cletus_esp", "Cletus.ESP", function() if Mega.Features.Cletus then Mega.Features.Cletus.RecreateESP() end end),
    UI.CreateSlider(nil, "slider_cletus_range", "Cletus.Range", 5, 100),
    UI.CreateSlider(nil, "slider_cletus_esp_transparency", "Cletus.ESPTransparency", 0, 100, function(v) Mega.States.Cletus.ESPTransparency = v/100; if Mega.Features.Cletus then Mega.Features.Cletus.UpdateVisuals() end end)
})
--#endregion

--#region -- Eldertree
UI.CreateToggleWithSettings(TabFrame, "toggle_eldertree", "Eldertree.Enabled", function(state)
    if Mega.Features.Eldertree then
        Mega.Features.Eldertree.SetEnabled(state)
    end
end, {
    UI.CreateToggle(nil, "toggle_eldertree_autocollect", "Eldertree.AutoCollect", function(state)
        if Mega.Features.Eldertree and Mega.Features.Eldertree.SetAutoCollect then Mega.Features.Eldertree.SetAutoCollect(state) end
    end),
    UI.CreateToggle(nil, "toggle_eldertree_esp", "Eldertree.ESP", function()
        if Mega.Features.Eldertree then Mega.Features.Eldertree.UpdateESP() end
    end),
    UI.CreateSlider(nil, "slider_eldertree_range", "Eldertree.Range", 5, 100)
})
--#endregion

--#region -- Star Collector
UI.CreateToggleWithSettings(TabFrame, "toggle_star_collector", "StarCollector.Enabled", nil, {
    UI.CreateToggle(nil, "toggle_star_collector_esp", "StarCollector.ESP"),
    UI.CreateSlider(nil, "slider_star_collector_range", "StarCollector.Range", 5, 100)
})
--#endregion

--#region -- Metal Detector
UI.CreateToggleWithSettings(TabFrame, "toggle_metal", "Metal.Enabled", nil, {
    UI.CreateToggle(nil, "toggle_metal_esp", "Metal.ESP"),
    UI.CreateToggle(nil, "toggle_metal_collect", "Metal.AutoCollect"),
    UI.CreateSlider(nil, "slider_metal_range", "Metal.Range", 5, 100)
})
--#endregion

--#region -- Taliah
UI.CreateToggleWithSettings(TabFrame, "toggle_taliah", "Taliah.Enabled", nil, {
    UI.CreateToggle(nil, "toggle_taliah_esp", "Taliah.ESP"),
    UI.CreateToggle(nil, "toggle_taliah_collect", "Taliah.AutoCollect"),
    UI.CreateSlider(nil, "slider_taliah_radius", "Taliah.CollectRadius", 5, 50),
    UI.CreateSlider(nil, "slider_taliah_esp_transparency", "Taliah.ESPTransparency", 0, 100, function(v) Mega.States.Taliah.ESPTransparency = v/100 end)
})
--#endregion

--#region -- Fisherman
UI.CreateSection(TabFrame, "toggle_fisherman")
UI.CreateToggle(TabFrame, "toggle_autofish", "Fisherman.Enabled")
--#endregion

--#region -- Noelle
UI.CreateSection(TabFrame, "noelle_title")
UI.CreateToggle(TabFrame, "toggle_noelle_save_binds", "Noelle.SaveBinds")
UI.CreateButton(TabFrame, "button_noelle_manager", function()
    Mega.ShowNotification("Noelle Manager is not implemented yet.", 3)
end)
--#endregion
