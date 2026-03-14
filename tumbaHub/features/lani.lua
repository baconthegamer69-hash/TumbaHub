-- features/lani.lua
-- Logic for Lani (PaladinAbilityRequest)

if not Mega.Features then Mega.Features = {} end
Mega.Features.Lani = {}

local Services = Mega.Services or {
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    Players = game:GetService("Players"),
    UserInputService = game:GetService("UserInputService")
}
local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

if not Mega.Objects.LaniConnections then Mega.Objects.LaniConnections = {} end
local connections = Mega.Objects.LaniConnections

for k, conn in pairs(connections) do
    if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
end
table.clear(connections)

local PaladinAbilityRequestRemote
task.spawn(function()
    pcall(function()
        PaladinAbilityRequestRemote = Services.ReplicatedStorage:WaitForChild("rbxts_include", 10):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):WaitForChild("PaladinAbilityRequest")
    end)
end)

connections.LaniInput = Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode.Name == States.Misc.Lani.Keybind and States.Misc.Lani.Enabled then
        if States.Misc.Lani.Target and States.Misc.Lani.Target.Parent then
            if PaladinAbilityRequestRemote then
                PaladinAbilityRequestRemote:FireServer({ ["target"] = States.Misc.Lani.Target })
            end
        end
    end
end)

local function InitializeLaniUI()
    local LaniContainer = Mega.Objects.LaniContainer
    if not LaniContainer then return end
    
    LaniContainer:ClearAllChildren()

    local LaniTargetLabel = Instance.new("TextLabel")
    LaniTargetLabel.Size = UDim2.new(1, 0, 0, 25)
    LaniTargetLabel.BackgroundTransparency = 1
    LaniTargetLabel.TextColor3 = Mega.Settings.Menu.AccentColor or Color3.fromRGB(200, 70, 255)
    LaniTargetLabel.Font = Enum.Font.GothamBold
    LaniTargetLabel.TextSize = 14
    local currentTargetName = States.Misc.Lani.Target and States.Misc.Lani.Target.Name or "None"
    LaniTargetLabel.Text = Mega.GetText("lani_target", currentTargetName) or ("Target: " .. currentTargetName)
    LaniTargetLabel.Parent = LaniContainer

    local LaniPlayerList = Instance.new("ScrollingFrame")
    LaniPlayerList.Size = UDim2.new(1, 0, 1, -30)
    LaniPlayerList.Position = UDim2.new(0, 0, 0, 30)
    LaniPlayerList.BackgroundTransparency = 1
    LaniPlayerList.BorderSizePixel = 0
    LaniPlayerList.ScrollBarThickness = 4
    LaniPlayerList.Parent = LaniContainer
    
    local LaniListLayout = Instance.new("UIListLayout")
    LaniListLayout.Parent = LaniPlayerList
    LaniListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    LaniListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    LaniListLayout.Padding = UDim.new(0, 5)

    local function RefreshLaniPlayers()
        for _, v in pairs(LaniPlayerList:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
        
        for _, p in ipairs(Services.Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(0.95, 0, 0, 35)
                
                local isTarget = (States.Misc.Lani.Target == p)
                btn.BackgroundColor3 = isTarget and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(40, 45, 60)
                
                btn.Text = p.Name
                btn.TextColor3 = Color3.new(1,1,1)
                btn.Font = Enum.Font.Gotham
                btn.TextSize = 14
                btn.Parent = LaniPlayerList
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
                
                btn.MouseButton1Click:Connect(function()
                    if States.Misc.Lani.Target == p then
                        States.Misc.Lani.Target = nil
                        LaniTargetLabel.Text = Mega.GetText("lani_target", "None") or "Target: None"
                    else
                        States.Misc.Lani.Target = p
                        LaniTargetLabel.Text = Mega.GetText("lani_target", p.Name) or ("Target: " .. p.Name)
                    end
                    RefreshLaniPlayers()
                end)
            end
        end
        LaniPlayerList.CanvasSize = UDim2.new(0, 0, 0, LaniListLayout.AbsoluteContentSize.Y)
    end

    connections.LaniPlayerRefresh = Services.Players.PlayerAdded:Connect(function() if LaniContainer.Visible then RefreshLaniPlayers() end end)
    connections.LaniPlayerRefresh2 = Services.Players.PlayerRemoving:Connect(function() if LaniContainer.Visible then RefreshLaniPlayers() end end)

    Mega.Features.Lani.RefreshPlayers = RefreshLaniPlayers
    if States.Misc.Lani.Enabled then RefreshLaniPlayers() end
end

task.spawn(function()
    while not Mega.Objects.LaniContainer do task.wait(0.1) end
    InitializeLaniUI()
end)
