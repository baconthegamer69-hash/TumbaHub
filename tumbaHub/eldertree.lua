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

-- Очищаем старые коннекты, если скрипт перезапускается
for _, conn in pairs(connections) do
    if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
end
table.clear(connections)

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

local espCache = {}
local function ClearESP()
    espFolder:ClearAllChildren()
    table.clear(espCache)
end

local function CreateOrbESP(orb)
    if not orb or not orb.PrimaryPart then return end
    if espCache[orb] then return end
    
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
        if not parent then 
            if espCache[orb] == billboard then espCache[orb] = nil end
            billboard:Destroy() 
        end
    end)
    
    espCache[orb] = billboard
    billboard.Destroying:Connect(function() 
        conn:Disconnect() 
        if espCache[orb] == billboard then espCache[orb] = nil end
    end)
end

local lastCheck = 0
local lastEspState = false

connections.MainLoop = Services.RunService.Heartbeat:Connect(function()
    -- 1. Полностью автономный контроль ESP
    local currentEspState = (States.Eldertree.Enabled and States.Eldertree.ESP)
    if currentEspState ~= lastEspState then
        lastEspState = currentEspState
        ClearESP()
        if currentEspState then
            if not connections.ESPAdded then
                connections.ESPAdded = Services.CollectionService:GetInstanceAddedSignal("treeOrb"):Connect(function(orb)
                    if States.Eldertree.Enabled and States.Eldertree.ESP then CreateOrbESP(orb) end
                end)
            end
            for _, orb in ipairs(Services.CollectionService:GetTagged("treeOrb")) do
                CreateOrbESP(orb)
            end
        else
            if connections.ESPAdded then
                connections.ESPAdded:Disconnect()
                connections.ESPAdded = nil
            end
        end
    end

    -- 2. Авто-сбор
    if not States.Eldertree.Enabled or not ConsumeTreeOrbRemote then return end
    
    if tick() - lastCheck < 0.1 then return end
    lastCheck = tick()
    
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local orbs = Services.CollectionService:GetTagged("treeOrb")
    for _, orb in ipairs(orbs) do
        if orb:IsA("Model") and orb.PrimaryPart then
            local dist = (root.Position - orb.PrimaryPart.Position).Magnitude
            if dist <= States.Eldertree.Range then
                local secret = orb:GetAttribute("TreeOrbSecret")
                if secret then
                    local args = { { treeOrbSecret = secret } }
                    task.spawn(function()
                        pcall(function() 
                            ConsumeTreeOrbRemote:InvokeServer(unpack(args)) 
                        end)
                    end)
                end
            end
        end
    end
end)

-- Оставляем эти функции для обратной совместимости, чтобы ничего не сломалось
-- если другие скрипты попытаются их вызвать, но логика уже обрабатывается в MainLoop
function Mega.Features.Eldertree.SetEnabled(state)
    States.Eldertree.Enabled = state
end

function Mega.Features.Eldertree.UpdateESP()
    -- Пусто, так как MainLoop автоматически обнаружит изменение States.Eldertree.ESP
end
