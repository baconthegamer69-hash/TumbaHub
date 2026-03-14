-- features/eldertree.lua
-- Logic for Eldertree (Tree Orbs collection and ESP)

if not Mega.Features then Mega.Features = {} end
Mega.Features.Eldertree = {}

local Services = {
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    CollectionService = game:GetService("CollectionService"),
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players"),
    CoreGui = game:GetService("CoreGui")
}
local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

-- Ensure connection container exists
if not Mega.Objects.EldertreeConnections then Mega.Objects.EldertreeConnections = {} end
local connections = Mega.Objects.EldertreeConnections

-- Remote
local ConsumeTreeOrbRemote
task.spawn(function()
    pcall(function()
        ConsumeTreeOrbRemote = Services.ReplicatedStorage:WaitForChild("rbxts_include", 10):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):WaitForChild("ConsumeTreeOrb")
    end)
end)

-- ESP Setup
local espFolder = Instance.new("Folder")
espFolder.Name = "EldertreeESP"
if Mega.Objects.GUI then
    espFolder.Parent = Mega.Objects.GUI
else
    espFolder.Parent = Services.CoreGui
end

local ORB_ICON = "rbxassetid://11003449842"

local function ClearESP()
    if connections.ESPAdded then connections.ESPAdded:Disconnect() end
    connections.ESPAdded = nil
    espFolder:ClearAllChildren()
end

local function CreateOrbESP(orb)
    if not orb or not orb.PrimaryPart then return end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = orb.PrimaryPart
    billboard.Size = UDim2.fromOffset(32, 32)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 3, 1.5)
    billboard.AlwaysOnTop = true
    billboard.Parent = espFolder
    
    local img = Instance.new("ImageLabel")
    img.Size = UDim2.fromScale(1, 1)
    img.BackgroundTransparency = 0.5
    img.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    img.Image = ORB_ICON
    img.Parent = billboard
    Instance.new("UICorner", img).CornerRadius = UDim.new(0, 4)
    
    local conn = orb.AncestryChanged:Connect(function(_, parent)
        if not parent then billboard:Destroy() end
    end)
    billboard.Destroying:Connect(function() conn:Disconnect() end)
end

local function EnableESP()
    ClearESP()
    if not States.Eldertree.Enabled or not States.Eldertree.ESP then return end
    
    connections.ESPAdded = Services.CollectionService:GetInstanceAddedSignal("treeOrb"):Connect(function(orb)
        CreateOrbESP(orb)
    end)
    
    for _, orb in ipairs(Services.CollectionService:GetTagged("treeOrb")) do
        CreateOrbESP(orb)
    end
end

-- Auto Collect Logic
local lastCheck = 0
local function AutoCollectLoop()
    if not States.Eldertree.Enabled then return end
    if not ConsumeTreeOrbRemote then return end
    
    if tick() - lastCheck < 0.1 then return end
    lastCheck = tick()
    
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    for _, orb in ipairs(Services.CollectionService:GetTagged("treeOrb")) do
        if orb:IsA("Model") and orb.PrimaryPart then
            local dist = (root.Position - orb.PrimaryPart.Position).Magnitude
            if dist <= States.Eldertree.Range then
                local secret = orb:GetAttribute("TreeOrbSecret")
                if secret then
                    task.spawn(function()
                        pcall(function() ConsumeTreeOrbRemote:InvokeServer({ treeOrbSecret = secret }) end)
                    end)
                end
            end
        end
    end
end

function Mega.Features.Eldertree.SetEnabled(state)
    States.Eldertree.Enabled = state
    EnableESP()
    
    if state then
        if not connections.Loop then
            connections.Loop = Services.RunService.Heartbeat:Connect(AutoCollectLoop)
        end
    else
        if connections.Loop then
            connections.Loop:Disconnect()
            connections.Loop = nil
        end
    end
end

function Mega.Features.Eldertree.UpdateESP()
    EnableESP()
end

if States.Eldertree.Enabled then
    Mega.Features.Eldertree.SetEnabled(true)
end