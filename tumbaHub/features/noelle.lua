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

connections.NoelleBindLoop = Services.RunService.Heartbeat:Connect(function()
    if not States.Noelle.Enabled then return end
    if not RequestMoveSlime then return end
    if tick() % 1 > 0.1 then return end -- Каждую ~1 секунду
    for slimeId, targetId in pairs(States.Noelle.Binds) do
        local args = {{ slimeId = slimeId, targetPlayerUserId = targetId }}
        task.spawn(function() pcall(function() RequestMoveSlime:InvokeServer(unpack(args)) end) end)
    end
end)

local NoelleContainer = Mega.Objects.NoelleContainer
if not NoelleContainer then
    warn("NoelleContainer not found!")
    return
end

NoelleContainer:ClearAllChildren()

local PlayerSelectContainer = Instance.new("ScrollingFrame")
PlayerSelectContainer.Name = "PlayerSelect"
PlayerSelectContainer.Size = UDim2.new(1, 0, 1, 0)
PlayerSelectContainer.BackgroundTransparency = 1
PlayerSelectContainer.BorderSizePixel = 0
PlayerSelectContainer.ScrollBarThickness = 4
PlayerSelectContainer.Parent = NoelleContainer

local PLayout = Instance.new("UIListLayout")
PLayout.Parent = PlayerSelectContainer
PLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
PLayout.SortOrder = Enum.SortOrder.LayoutOrder
PLayout.Padding = UDim.new(0, 5)

local SlimeManageContainer = Instance.new("Frame")
SlimeManageContainer.Name = "SlimeManage"
SlimeManageContainer.Size = UDim2.new(1, 0, 1, 0)
SlimeManageContainer.BackgroundTransparency = 1
SlimeManageContainer.Visible = false
SlimeManageContainer.Parent = NoelleContainer

-- UI элементы менеджера слаймов
local HeaderFrame = Instance.new("Frame")
HeaderFrame.Size = UDim2.new(1, 0, 0, 40)
HeaderFrame.BackgroundTransparency = 1
HeaderFrame.Parent = SlimeManageContainer

local BackBtn = Instance.new("TextButton")
BackBtn.Size = UDim2.new(0, 120, 1, -5)
BackBtn.Position = UDim2.new(0, 5, 0, 2)
BackBtn.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
BackBtn.Text = Mega.GetText("noelle_back") or "⬅ Back"
BackBtn.TextColor3 = Color3.new(1,1,1)
BackBtn.Font = Enum.Font.GothamBold
BackBtn.TextSize = 12
BackBtn.Parent = HeaderFrame
Instance.new("UICorner", BackBtn).CornerRadius = UDim.new(0, 6)

local TargetNameLabel = Instance.new("TextLabel")
TargetNameLabel.Size = UDim2.new(1, -130, 1, 0)
TargetNameLabel.Position = UDim2.new(0, 130, 0, 0)
TargetNameLabel.BackgroundTransparency = 1
TargetNameLabel.Text = "Player"
TargetNameLabel.TextColor3 = Mega.Settings.Menu.AccentColor or Color3.fromRGB(200, 70, 255)
TargetNameLabel.Font = Enum.Font.GothamBold
TargetNameLabel.TextSize = 16
TargetNameLabel.TextXAlignment = Enum.TextXAlignment.Left
TargetNameLabel.Parent = HeaderFrame

local SlimeScroll = Instance.new("ScrollingFrame")
SlimeScroll.Size = UDim2.new(1, 0, 1, -90)
SlimeScroll.Position = UDim2.new(0, 0, 0, 45)
SlimeScroll.BackgroundTransparency = 1
SlimeScroll.BorderSizePixel = 0
SlimeScroll.ScrollBarThickness = 4
SlimeScroll.Parent = SlimeManageContainer

local SLayout = Instance.new("UIListLayout")
SLayout.Parent = SlimeScroll
SLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SLayout.SortOrder = Enum.SortOrder.LayoutOrder
SLayout.Padding = UDim.new(0, 5)

local ActionsFrame = Instance.new("Frame")
ActionsFrame.Size = UDim2.new(1, 0, 0, 40)
ActionsFrame.Position = UDim2.new(0, 0, 1, -40)
ActionsFrame.BackgroundTransparency = 1
ActionsFrame.Parent = SlimeManageContainer

local ActionLayout = Instance.new("UIListLayout")
ActionLayout.Parent = ActionsFrame
ActionLayout.FillDirection = Enum.FillDirection.Horizontal
ActionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ActionLayout.Padding = UDim.new(0, 5)

local currentTarget = nil
local selectedSlimesForAction = {}

local RefreshSlimesForTarget -- Forward declaration

local function CreateActionButton(text, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.23, 0, 1, 0)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.Parent = ActionsFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

CreateActionButton(Mega.GetText("noelle_give") or "GIVE", Color3.fromRGB(0, 180, 100), function()
    if not currentTarget or not RequestMoveSlime then return end
    local count = 0
    for slimeId, _ in pairs(selectedSlimesForAction) do
        count = count + 1
        local args = {{ slimeId = slimeId, targetPlayerUserId = currentTarget.UserId }}
        task.spawn(function() pcall(function() RequestMoveSlime:InvokeServer(unpack(args)) end) end)
    end
    if Mega.ShowNotification then Mega.ShowNotification(string.format("Gave %d slimes", count), 2) end
    RefreshSlimesForTarget()
end)

CreateActionButton(Mega.GetText("noelle_bind") or "BIND", Color3.fromRGB(100, 100, 255), function()
    if not currentTarget then return end
    local count = 0
    for slimeId, _ in pairs(selectedSlimesForAction) do
        States.Noelle.Binds[slimeId] = currentTarget.UserId
        count = count + 1
    end
    if Mega.ShowNotification then Mega.ShowNotification(string.format("Bound %d slimes", count), 2) end
    RefreshSlimesForTarget()
end)

CreateActionButton(Mega.GetText("noelle_unbind") or "UNBIND", Color3.fromRGB(255, 100, 100), function()
    local count = 0
    for slimeId, _ in pairs(selectedSlimesForAction) do
        if States.Noelle.Binds[slimeId] then
            States.Noelle.Binds[slimeId] = nil
            count = count + 1
        end
    end
    if Mega.ShowNotification then Mega.ShowNotification(string.format("Unbound %d slimes", count), 2) end
    RefreshSlimesForTarget()
end)

CreateActionButton(Mega.GetText("noelle_remove") or "TAKE BACK", Color3.fromRGB(200, 60, 60), function()
    if not RequestMoveSlime then return end
    local count = 0
    for slimeId, _ in pairs(selectedSlimesForAction) do
        count = count + 1
        local args = {{ slimeId = slimeId, targetPlayerUserId = LocalPlayer.UserId }}
        task.spawn(function() pcall(function() RequestMoveSlime:InvokeServer(unpack(args)) end) end)
    end
    if Mega.ShowNotification then Mega.ShowNotification(string.format("Took back %d slimes", count), 2) end
    RefreshSlimesForTarget()
end)

RefreshSlimesForTarget = function()
    for _, v in pairs(SlimeScroll:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    selectedSlimesForAction = {}
    
    if not SlimeDataFolder then return end
    local myName = LocalPlayer.Name
    
    for _, child in ipairs(SlimeDataFolder:GetChildren()) do
        if string.sub(child.Name, 1, #myName) == myName then
            local slimeId = child:GetAttribute("Id")
            if not slimeId and child:FindFirstChild("Id") then slimeId = child.Id.Value end
            
            if slimeId then
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(0.95, 0, 0, 35)
                btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
                btn.Parent = SlimeScroll
                
                local dName = string.sub(child.Name, #myName + 2)
                if dName == "Slime_0" then dName = "Heal"
                elseif dName == "Slime_1" then dName = "Damage"
                elseif dName == "Slime_2" then dName = "Collect"
                elseif dName == "Slime_3" then dName = "Frosty"
                end
                
                local isBoundToCurrent = (States.Noelle.Binds[slimeId] == currentTarget.UserId)
                local isBoundToOther = (States.Noelle.Binds[slimeId] and States.Noelle.Binds[slimeId] ~= currentTarget.UserId)
                
                local statusText = ""
                if isBoundToCurrent then 
                    statusText = " [BOUND]" 
                    btn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
                elseif isBoundToOther then
                    statusText = " " .. (Mega.GetText("noelle_bound_other") or "(Bound)")
                    btn.BackgroundColor3 = Color3.fromRGB(100, 50, 50)
                end
                
                btn.Text = dName .. statusText
                btn.TextColor3 = Color3.new(1,1,1)
                btn.Font = Enum.Font.Gotham
                btn.TextSize = 14
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
                
                btn.MouseButton1Click:Connect(function()
                    if selectedSlimesForAction[slimeId] then
                        selectedSlimesForAction[slimeId] = nil
                        if States.Noelle.Binds[slimeId] == currentTarget.UserId then
                            btn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
                        elseif States.Noelle.Binds[slimeId] then
                            btn.BackgroundColor3 = Color3.fromRGB(100, 50, 50)
                        else
                            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
                        end
                    else
                        selectedSlimesForAction[slimeId] = true
                        btn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
                    end
                end)
            end
        end
    end
    SlimeScroll.CanvasSize = UDim2.new(0, 0, 0, SLayout.AbsoluteContentSize.Y)
end

local function OpenSlimeManager(player)
    currentTarget = player
    TargetNameLabel.Text = Mega.GetText("noelle_manage", player.Name)
    PlayerSelectContainer.Visible = false
    SlimeManageContainer.Visible = true
    RefreshSlimesForTarget()
end

BackBtn.MouseButton1Click:Connect(function()
    SlimeManageContainer.Visible = false
    PlayerSelectContainer.Visible = true
    currentTarget = nil
end)

local function RefreshPlayerList()
    for _, v in pairs(PlayerSelectContainer:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    
    for _, p in ipairs(Services.Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0.95, 0, 0, 40)
            btn.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
            btn.Text = p.Name
            btn.TextColor3 = Color3.new(1,1,1)
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 14
            btn.Parent = PlayerSelectContainer
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
            
            btn.MouseButton1Click:Connect(function() OpenSlimeManager(p) end)
        end
    end
    PlayerSelectContainer.CanvasSize = UDim2.new(0, 0, 0, PLayout.AbsoluteContentSize.Y)
end

connections.NoellePlayerRefresh = Services.Players.PlayerAdded:Connect(function()
    if States.Noelle.Enabled and PlayerSelectContainer.Visible then RefreshPlayerList() end
end)

connections.NoellePlayerRefresh2 = Services.Players.PlayerRemoving:Connect(function()
    if States.Noelle.Enabled and PlayerSelectContainer.Visible then RefreshPlayerList() end
end)

function Mega.Features.Noelle.SetEnabled(state)
    States.Noelle.Enabled = state
    if state then RefreshPlayerList() end
end
