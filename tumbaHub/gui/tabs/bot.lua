-- gui/tabs/bot.lua
-- Content for the "BOT" tab

local tabKey = "tab_bot"
local UI = Mega.UI

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

ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    TabFrame.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 40)
end)
TabFrame.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 40)

Mega.Objects.TabFrames[tabKey] = TabFrame

task.spawn(function()
    pcall(function() Mega.LoadModule("features/bot.lua") end)
end)

--#region -- Main Bot
UI.CreateSection(TabFrame, "section_bot_main")
UI.CreateToggle(TabFrame, "toggle_bot", "Bot.Enabled", function(state)
    Mega.States.Bot.Enabled = state
    if Mega.Features.Bot and Mega.Features.Bot.SetEnabled then 
        Mega.Features.Bot.SetEnabled(state) 
    end
end)

UI.CreateSection(TabFrame, "section_bot_targets")
UI.CreateToggle(TabFrame, "toggle_bot_beds", "Bot.TargetBeds")
UI.CreateToggle(TabFrame, "toggle_bot_players", "Bot.TargetPlayers")
UI.CreateToggle(TabFrame, "toggle_bot_pathfinding", "Bot.Pathfinding")

UI.CreateSection(TabFrame, "section_bot_modules")
UI.CreateToggle(TabFrame, "toggle_bot_killaura", "Bot.AutoKillaura")
UI.CreateToggle(TabFrame, "toggle_bot_scaffold", "Bot.AutoScaffold")
UI.CreateToggle(TabFrame, "toggle_bot_bednuke", "Bot.AutoBedNuke")
UI.CreateToggle(TabFrame, "toggle_bot_antivoid", "Bot.AutoAntiVoid")