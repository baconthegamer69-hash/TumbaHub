-- features/farmer_cletus.lua
-- Logic for Cletus (Farming) - Robust & Autonomous Version

if not Mega.Features then Mega.Features = {} end
Mega.Features.Cletus = {}

local Services = {
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    CollectionService = game:GetService("CollectionService"),
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players")
}
local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

if States.Cletus == nil then
    States.Cletus = {
        Enabled = false,
        Range = 20,
        AutoHarvest = false,
        ESP = false,
        ESPTransparency = 0.75
    }
end

if not Mega.Objects.CletusConnections then Mega.Objects.CletusConnections = {} end
local connections = Mega.Objects.CletusConnections

for k, conn in pairs(connections) do
    if typeof(conn) == "RBXScriptConnection" then
        conn:Disconnect()
    end
end
table.clear(connections)

-- Remote
local CropHarvestRemote
task.spawn(function()
    pcall(function()
        CropHarvestRemote = Services.ReplicatedStorage:WaitForChild("rbxts_include", 10):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):WaitForChild("CropHarvest")
    end)
end)

-- Helper for vector.create
local vectorHelper = vector
if not vectorHelper and getgenv then
    pcall(function() vectorHelper = getgenv().vector end)
end

local function UpdateCropESP(crop)
    if not crop or not crop:IsA("BasePart") then return end

    local stage = crop:GetAttribute("CropStage")
    local isActive = States.Cletus.Enabled and States.Cletus.ESP
    local isReady = stage and stage >= 3

    local existing = crop:FindFirstChild("TumbaCletusESP")

    if isActive and isReady then
        if not existing then
            existing = Instance.new("BoxHandleAdornment")
            existing.Name = "TumbaCletusESP"
            existing.Adornee = crop
            existing.Size = crop.Size + Vector3.new(0.1, 0.1, 0.1)
            existing.AlwaysOnTop = true
            existing.ZIndex = 5
            -- Прямая привязка к парту (обходит защиты экзекьюторов на CoreGui)
            existing.Parent = crop 
        end
            
        local color = Color3.fromRGB(0, 255, 0)
        if crop.Name:lower():find("carrot") then
            color = Color3.fromRGB(255, 170, 0)
        elseif crop.Name:lower():find("melon") then
            color = Color3.fromRGB(170, 255, 127)
        end
        existing.Color3 = color
        existing.Transparency = States.Cletus.ESPTransparency
    else
        if existing then existing:Destroy() end
    end
end

connections.CropAdded = Services.CollectionService:GetInstanceAddedSignal("Crop"):Connect(function(crop)
    if crop:IsA("BasePart") then
        local conn = crop:GetAttributeChangedSignal("CropStage"):Connect(function() UpdateCropESP(crop) end)
        table.insert(connections, conn)
        UpdateCropESP(crop)
    end
end)

for _, crop in ipairs(Services.CollectionService:GetTagged("Crop")) do
    if crop:IsA("BasePart") then
        local conn = crop:GetAttributeChangedSignal("CropStage"):Connect(function() UpdateCropESP(crop) end)
        table.insert(connections, conn)
        UpdateCropESP(crop)
    end
end

-- Автономный наблюдатель за изменениями состояния UI
local lastEspState = false
local lastEspTrans = States.Cletus.ESPTransparency

connections.StateWatcher = Services.RunService.Heartbeat:Connect(function()
    local currentEspState = States.Cletus.Enabled and States.Cletus.ESP
    local currentTrans = States.Cletus.ESPTransparency
    
    if currentEspState ~= lastEspState or currentTrans ~= lastEspTrans then
        lastEspState = currentEspState
        lastEspTrans = currentTrans
        
        for _, crop in ipairs(Services.CollectionService:GetTagged("Crop")) do
            UpdateCropESP(crop)
        end
    end
end)

-- Автономный цикл сбора урожая
local lastCletusRun = 0
connections.AutoHarvestLoop = Services.RunService.Heartbeat:Connect(function()
    if not States.Cletus.Enabled or not States.Cletus.AutoHarvest or not CropHarvestRemote then return end

    if tick() - lastCletusRun > 0.5 then
        lastCletusRun = tick()

        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        
        if hrp then
            for _, crop in ipairs(Services.CollectionService:GetTagged("Crop")) do
                if crop:IsA("BasePart") then
                    local stage = crop:GetAttribute("CropStage")
                    if stage and stage >= 3 then
                        local dist = (hrp.Position - crop.Position).Magnitude
                        if dist <= States.Cletus.Range then
                            local bx = math.round(crop.Position.X / 3)
                            local by = math.round(crop.Position.Y / 3)
                            local bz = math.round(crop.Position.Z / 3)
                            
                            local posObj = (vectorHelper and vectorHelper.create) and vectorHelper.create(bx, by, bz) or Vector3.new(bx, by, bz)
                            local args = {{ ["position"] = posObj }}
                            
                            task.spawn(function()
                                pcall(function() CropHarvestRemote:InvokeServer(unpack(args)) end)
                            end)
                        end
                    end
                end
            end
        end
    end
end)

-- Пустые функции для обратной совместимости, чтобы UI не выдавал ошибку,
-- если он попытается их вызвать.
function Mega.Features.Cletus.SetEnabled(state)
    States.Cletus.Enabled = state
end

function Mega.Features.Cletus.UpdateVisuals()
end

function Mega.Features.Cletus.RecreateESP()
end
