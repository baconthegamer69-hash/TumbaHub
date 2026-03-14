-- features/noelle.lua
-- Logic for Noelle Slime Manager

if not Mega.Features then Mega.Features = {} end
Mega.Features.Noelle = {}

local Services = Mega.Services or {
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    Workspace = game:GetService("Workspace"),
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players")
}
local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

if not States.Noelle then
    States.Noelle = { Enabled = false, SaveBinds = false, Binds = {} }
end

if not Mega.Objects.NoelleConnections then Mega.Objects.NoelleConnections = {} end
local connections = Mega.Objects.NoelleConnections

for k, conn in pairs(connections) do
    if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
end
table.clear(connections)

local RequestMoveSlime
local SlimeDataFolder
task.spawn(function()
    pcall(function()
        RequestMoveSlime = Services.ReplicatedStorage:WaitForChild("rbxts_include", 10):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):WaitForChild("RequestMoveSlime")
        SlimeDataFolder = Services.Workspace:WaitForChild("SlimeDataFolder", 10)
    end)
end)

local lastBindTick = 0
connections.NoelleBindLoop = Services.RunService.Heartbeat:Connect(function()
    if not States.Noelle.Enabled then return end
    if not RequestMoveSlime then return end
    if tick() - lastBindTick < 1 then return end
    lastBindTick = tick()
    
    if not SlimeDataFolder then return end
    local myName = LocalPlayer.Name
    
    for slimeType, targetId in pairs(States.Noelle.Binds) do
        local slimeName = myName .. "_Slime_" .. slimeType
        local slimeObj = SlimeDataFolder:FindFirstChild(slimeName)
        if slimeObj then
            local slimeId = slimeObj:GetAttribute("Id")
            if not slimeId and slimeObj:FindFirstChild("Id") then slimeId = slimeObj.Id.Value end
            if slimeId then
                local args = {{ slimeId = slimeId, targetPlayerUserId = targetId }}
                task.spawn(function() pcall(function() RequestMoveSlime:InvokeServer(unpack(args)) end) end)
            end
        end
    end
end)

local RefreshPlayerList = function() end

local function InitializeNoelleUI()
    local NoelleContainer = Mega.Objects.NoelleContainer
    NoelleContainer:ClearAllChildren()

    local SlimeSelectContainer = Instance.new("ScrollingFrame")
    SlimeSelectContainer.Name = "SlimeSelect"
    SlimeSelectContainer.Size = UDim2.new(1, 0, 1, 0)
    SlimeSelectContainer.BackgroundTransparency = 1
    SlimeSelectContainer.BorderSizePixel = 0
    SlimeSelectContainer.ScrollBarThickness = 4
    SlimeSelectContainer.Parent = NoelleContainer

    local SLayout = Instance.new("UIListLayout")
    SLayout.Parent = SlimeSelectContainer
    SLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    SLayout.SortOrder = Enum.SortOrder.LayoutOrder
    SLayout.Padding = UDim.new(0, 5)

    local PlayerManageContainer = Instance.new("Frame")
    PlayerManageContainer.Name = "PlayerManage"
    PlayerManageContainer.Size = UDim2.new(1, 0, 1, 0)
    PlayerManageContainer.BackgroundTransparency = 1
    PlayerManageContainer.Visible = false
    PlayerManageContainer.Parent = NoelleContainer

    local HeaderFrame = Instance.new("Frame")
    HeaderFrame.Size = UDim2.new(1, 0, 0, 40)
    HeaderFrame.BackgroundTransparency = 1
    HeaderFrame.Parent = PlayerManageContainer

    local BackBtn = Instance.new("TextButton")
    BackBtn.Size = UDim2.new(0, 80, 1, -5)
    BackBtn.Position = UDim2.new(0, 5, 0, 2)
    BackBtn.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
    BackBtn.Text = "⬅ Back"
    BackBtn.TextColor3 = Color3.new(1,1,1)
    BackBtn.Font = Enum.Font.GothamBold
    BackBtn.TextSize = 12
    BackBtn.Parent = HeaderFrame
    Instance.new("UICorner", BackBtn).CornerRadius = UDim.new(0, 6)

    local TargetNameLabel = Instance.new("TextLabel")
    TargetNameLabel.Size = UDim2.new(1, -90, 1, 0)
    TargetNameLabel.Position = UDim2.new(0, 90, 0, 0)
    TargetNameLabel.BackgroundTransparency = 1
    TargetNameLabel.Text = "Slime"
    TargetNameLabel.TextColor3 = Mega.Settings.Menu.AccentColor or Color3.fromRGB(200, 70, 255)
    TargetNameLabel.Font = Enum.Font.GothamBold
    TargetNameLabel.TextSize = 16
    TargetNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    TargetNameLabel.Parent = HeaderFrame

    local PlayerScroll = Instance.new("ScrollingFrame")
    PlayerScroll.Size = UDim2.new(1, 0, 1, -45)
    PlayerScroll.Position = UDim2.new(0, 0, 0, 45)
    PlayerScroll.BackgroundTransparency = 1
    PlayerScroll.BorderSizePixel = 0
    PlayerScroll.ScrollBarThickness = 4
    PlayerScroll.Parent = PlayerManageContainer

    local PLayout = Instance.new("UIListLayout")
    PLayout.Parent = PlayerScroll
    PLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    PLayout.SortOrder = Enum.SortOrder.LayoutOrder
    PLayout.Padding = UDim.new(0, 5)

    local currentSelectedSlimeType = nil

    BackBtn.MouseButton1Click:Connect(function()
        PlayerManageContainer.Visible = false
        SlimeSelectContainer.Visible = true
        currentSelectedSlimeType = nil
    end)

    local SLIME_TYPES = {
        { Name = "Heal Slime", Type = 0, Color = Color3.fromRGB(50, 255, 100) },
        { Name = "Void Slime", Type = 1, Color = Color3.fromRGB(150, 50, 255) },
        { Name = "Sticky Slime", Type = 2, Color = Color3.fromRGB(255, 150, 50) },
        { Name = "Frosty Slime", Type = 3, Color = Color3.fromRGB(50, 200, 255) },
    }

    local function OpenPlayerManager(slimeData)
        currentSelectedSlimeType = slimeData.Type
        TargetNameLabel.Text = slimeData.Name
        SlimeSelectContainer.Visible = false
        PlayerManageContainer.Visible = true
        RefreshPlayerList()
    end

    for _, slime in ipairs(SLIME_TYPES) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.95, 0, 0, 40)
        btn.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
        btn.Text = slime.Name
        btn.TextColor3 = slime.Color
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 15
        btn.Parent = SlimeSelectContainer
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        
        btn.MouseButton1Click:Connect(function()
            OpenPlayerManager(slime)
        end)
    end
    SlimeSelectContainer.CanvasSize = UDim2.new(0, 0, 0, SLayout.AbsoluteContentSize.Y)

    RefreshPlayerList = function()
        if not currentSelectedSlimeType then return end
        
        for _, v in pairs(PlayerScroll:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
        
        local noneBtn = Instance.new("TextButton")
        noneBtn.Size = UDim2.new(0.95, 0, 0, 35)
        local isBoundToMe = States.Noelle.Binds[currentSelectedSlimeType] == LocalPlayer.UserId or States.Noelle.Binds[currentSelectedSlimeType] == nil
        noneBtn.BackgroundColor3 = isBoundToMe and Color3.fromRGB(0, 100, 200) or Color3.fromRGB(50, 50, 60)
        noneBtn.Text = "Self (Take Back)"
        noneBtn.TextColor3 = Color3.new(1,1,1)
        noneBtn.Font = Enum.Font.GothamBold
        noneBtn.TextSize = 14
        noneBtn.Parent = PlayerScroll
        Instance.new("UICorner", noneBtn).CornerRadius = UDim.new(0, 6)
        
        noneBtn.MouseButton1Click:Connect(function()
            States.Noelle.Binds[currentSelectedSlimeType] = LocalPlayer.UserId
            RefreshPlayerList()
        end)

        for _, p in ipairs(Services.Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(0.95, 0, 0, 35)
                
                local isBound = States.Noelle.Binds[currentSelectedSlimeType] == p.UserId
                btn.BackgroundColor3 = isBound and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(40, 45, 60)
                
                btn.Text = p.Name
                btn.TextColor3 = Color3.new(1,1,1)
                btn.Font = Enum.Font.Gotham
                btn.TextSize = 14
                btn.Parent = PlayerScroll
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
                
                btn.MouseButton1Click:Connect(function()
                    States.Noelle.Binds[currentSelectedSlimeType] = p.UserId
                    RefreshPlayerList()
                end)
            end
        end
        PlayerScroll.CanvasSize = UDim2.new(0, 0, 0, PLayout.AbsoluteContentSize.Y)
    end

    connections.NoellePlayerRefresh = Services.Players.PlayerAdded:Connect(function()
        if States.Noelle.Enabled and PlayerManageContainer.Visible then RefreshPlayerList() end
    end)

    connections.NoellePlayerRefresh2 = Services.Players.PlayerRemoving:Connect(function()
        if States.Noelle.Enabled and PlayerManageContainer.Visible then RefreshPlayerList() end
    end)

    if States.Noelle.Enabled and PlayerManageContainer.Visible then RefreshPlayerList() end
end

task.spawn(function()
    while not Mega.Objects.NoelleContainer do task.wait(0.1) end
    InitializeNoelleUI()
end)

function Mega.Features.Noelle.SetEnabled(state)
    States.Noelle.Enabled = state
    if state then RefreshPlayerList() end
end
