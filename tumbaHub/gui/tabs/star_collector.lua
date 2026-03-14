-- features/star_collector.lua
-- Logic for Star Collector extracted from tumbaHub.lua

if not Mega.Features then Mega.Features = {} end
Mega.Features.StarCollector = {}

-- Define services locally
local Services = {
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    CollectionService = game:GetService("CollectionService"),
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players"),
    CoreGui = game:GetService("CoreGui"),
    Workspace = game:GetService("Workspace")
}
local LocalPlayer = Services.Players.LocalPlayer

local States = Mega.States
local StarState = States.StarCollector

-- Ensure objects exist
if not Mega.Objects.StarConnections then Mega.Objects.StarConnections = {} end
local connections = Mega.Objects.StarConnections

-- Remote
local CollectStarRemote
task.spawn(function()
    pcall(function()
        CollectStarRemote = Services.ReplicatedStorage:WaitForChild("rbxts_include", 10):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):WaitForChild("CollectCollectableEntity")
    end)
end)

-- ESP Logic
local espFolder = Instance.new("Folder")
espFolder.Name = "StarCollectorESP"
if Mega.Objects.GUI then
    espFolder.Parent = Mega.Objects.GUI
else
    espFolder.Parent = Services.CoreGui
end

local ICONS = {
    ["CritStar"] = "rbxassetid://9866757805",
    ["VitalityStar"] = "rbxassetid://9866757969"
}

local function ClearESP()
    for _, conn in pairs(connections) do
        if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
    end
    table.clear(connections)
    espFolder:ClearAllChildren()
end

local function EnableESP()
    ClearESP()
    if not StarState.Enabled or not StarState.ESP then return end

    local function createEsp(model)
        if not model or not model.PrimaryPart then return end
        local icon = ICONS[model.Name]
        if not icon then return end

        local billboard = Instance.new("BillboardGui")
        billboard.Adornee = model.PrimaryPart
        billboard.AlwaysOnTop = true
        billboard.Size = UDim2.fromOffset(32, 32)
        billboard.StudsOffsetWorldSpace = Vector3.new(0, 3, 1.5)
        billboard.Parent = espFolder

        local image = Instance.new("ImageLabel", billboard)
        image.BackgroundTransparency = 0.5
        image.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        image.Image = icon
        image.Size = UDim2.fromScale(1, 1)
        Instance.new("UICorner", image).CornerRadius = UDim.new(0, 4)

        -- Cleanup on destroy
        table.insert(connections, model.AncestryChanged:Connect(function(_, parent)
            if not parent then billboard:Destroy() end
        end))
    end

    local function check(v)
        if v:IsA("Model") and (v.Name == "CritStar" or v.Name == "VitalityStar") then
            createEsp(v)
        end
    end

    table.insert(connections, Services.Workspace.ChildAdded:Connect(check))
    for _, v in ipairs(Services.Workspace:GetChildren()) do
        check(v)
    end
end

-- Auto Collect Logic
local lastCheck = 0
local function AutoCollectLoop()
    if not StarState.Enabled then return end
    if not CollectStarRemote then return end
    
    if tick() - lastCheck < 0.1 then return end
    lastCheck = tick()

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local stars = Services.CollectionService:GetTagged("stars")
    for _, star in ipairs(stars) do
        if star:IsA("Model") and star.PrimaryPart then
            local distance = (root.Position - star.PrimaryPart.Position).Magnitude
            
            if distance <= StarState.Range then
                local starId = star:GetAttribute("Id")
                if starId then
                    local args = { { id = starId, collectableName = star.Name } }
                    task.spawn(function()
                        pcall(function()
                            CollectStarRemote:FireServer(unpack(args))
                        end)
                    end)
                end
            end
        end
    end
end

-- Public Functions
function Mega.Features.StarCollector.SetEnabled(state)
    StarState.Enabled = state
    
    if state then
        EnableESP()
        if not Mega.Objects.Connections.StarCollectorLoop then
            Mega.Objects.Connections.StarCollectorLoop = Services.RunService.Heartbeat:Connect(AutoCollectLoop)
        end
    else
        ClearESP()
        if Mega.Objects.Connections.StarCollectorLoop then
            Mega.Objects.Connections.StarCollectorLoop:Disconnect()
            Mega.Objects.Connections.StarCollectorLoop = nil
        end
    end
end

function Mega.Features.StarCollector.UpdateESP()
    EnableESP()
end

-- Initialize if enabled
if StarState.Enabled then
    Mega.Features.StarCollector.SetEnabled(true)
end