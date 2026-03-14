-- gui/tabs/player.lua
-- Content for the "PLAYER" tab

local tabKey = "tab_player"
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
ContentLayout.Padding = UDim.new(0, 0) -- Padding is handled by the component frame now

Mega.Objects.TabFrames[tabKey] = TabFrame

--#region -- Movement
UI.CreateSection(TabFrame, "section_player_movement")

UI.CreateToggleWithSettings(TabFrame, "toggle_speed", "Player.Speed", nil, {
    UI.CreateSlider(nil, "slider_speed", "Player.SpeedValue", 16, 200)
})

UI.CreateToggleWithSettings(TabFrame, "toggle_fly", "Player.Fly", nil, {
    UI.CreateSlider(nil, "slider_fly_speed", "Player.FlySpeed", 1, 100),
    UI.CreateDropdown(nil, "dropdown_fly_mode", "Player.FlyMode", {"Velocity", "Default"}, function(val)
        Mega.States.Player.FlyMode = val
    end)
})

UI.CreateToggle(TabFrame, "toggle_inf_jump", "Player.InfiniteJump")
UI.CreateToggle(TabFrame, "toggle_nofall", "Player.NoFall")
--#endregion

--#region -- Defense / Utility
UI.CreateSection(TabFrame, "section_player_defense")

UI.CreateToggle(TabFrame, "toggle_godmode", "Player.GodMode")
UI.CreateToggle(TabFrame, "toggle_noclip", "Player.NoClip")

UI.CreateToggleWithSettings(TabFrame, "toggle_antiknockback", "Player.AntiKnockback", nil, {
    UI.CreateSlider(nil, "slider_knockback_strength", "Player.KnockbackStrength", 0, 100)
})

UI.CreateToggleWithSettings(TabFrame, "toggle_spider", "Player.Spider", nil, {
     UI.CreateSlider(nil, "slider_spider_speed", "Player.SpiderSpeed", 1, 50)
})

UI.CreateToggleWithSettings(TabFrame, "toggle_scaffold", "Player.Scaffold.Enabled", nil, {
    UI.CreateKeybindButton(nil, "keybind_scaffold", "Keybinds.Scaffold"),
    UI.CreateSlider(nil, "slider_scaffold_yoffset", "Player.Scaffold.YOffset", -100, 0, function(val) Mega.States.Player.Scaffold.YOffset = val / 10 end),
    UI.CreateSlider(nil, "slider_scaffold_predict", "Player.Scaffold.Predict", 0, 100, function(val) Mega.States.Player.Scaffold.Predict = val / 100 end)
})
--#endregion

--#region -- Misc Movement
UI.CreateSection(TabFrame, "section_utils_fun") -- Using existing translation key

UI.CreateToggleWithSettings(TabFrame, "toggle_spinbot", "Player.SpinBot", nil, {
    UI.CreateSlider(nil, "slider_spinspeed", "Player.SpinSpeed", 1, 100)
})

UI.CreateToggleWithSettings(TabFrame, "toggle_fastbreak", "Player.FastBreak", nil, {
    UI.CreateSlider(nil, "slider_break_speed", "Player.BreakSpeed", 1, 10)
})
--#endregion


-- Simple player logic that can live here
local function onRenderStep()
    local char = Mega.Services.LocalPlayer.Character
    if not char then return end

    if Mega.States.Player.Speed then
        char.Humanoid.WalkSpeed = Mega.States.Player.SpeedValue
    else
        if char.Humanoid.WalkSpeed == Mega.States.Player.SpeedValue then
             char.Humanoid.WalkSpeed = 16 -- Default speed
        end
    end
    
    if Mega.States.Player.InfiniteJump then
        Mega.Services.UserInputService.JumpRequest:Connect(function()
            if Mega.States.Player.InfiniteJump then
                 char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
end

Mega.Services.RunService.RenderStepped:Connect(onRenderStep)

