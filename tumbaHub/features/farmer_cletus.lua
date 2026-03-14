-- features/farmer_cletus.lua
-- Logic for Cletus (Farming) extracted from tumbaHub.lua

if not Mega.Features then Mega.Features = {} end
Mega.Features.Cletus = {}

-- Define services locally since Mega.Services might not exist
local Services = {
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    CollectionService = game:GetService("CollectionService"),
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players"),
    CoreGui = game:GetService("CoreGui")
}
local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

-- Убедимся, что настройки существуют (fallback)
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

-- Очистка старых соединений на случай перезапуска
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
if not vectorHelper then
    vectorHelper = {
        create = function(x, y, z)
            return Vector3.new(x, y, z)
        end
    }
end

-- ESP Container
local cletusGui = Services.CoreGui:FindFirstChild("CletusESP_GUI")
if not cletusGui then
    cletusGui = Instance.new("ScreenGui")
    cletusGui.Name = "CletusESP_GUI"
    cletusGui.Parent = Services.CoreGui
end

local cletusEspFolder = cletusGui:FindFirstChild("CletusESP")
if not cletusEspFolder then
    cletusEspFolder = Instance.new("Folder")
    cletusEspFolder.Name = "CletusESP"
    cletusEspFolder.Parent = cletusGui
end

local espCache = {}

local function RemoveCropESP(crop)
    if espCache[crop] then
        espCache[crop]:Destroy()
        espCache[crop] = nil
    end
end

local function UpdateCropESP(crop)
    if not crop or not crop:IsA("BasePart") then return end

    local stage = crop:GetAttribute("CropStage")
    local isActive = States.Cletus.Enabled and States.Cletus.ESP
    local isReady = stage and stage >= 3

    if isActive and isReady then
        local esp = espCache[crop]
        if not esp then
            esp = Instance.new("BoxHandleAdornment")
            esp.Name = "CropESP"
            esp.Adornee = crop
            esp.Size = crop.Size + Vector3.new(0.1, 0.1, 0.1)
            
            local color = Color3.fromRGB(0, 255, 0)
            if crop.Name:lower():find("carrot") then
                color = Color3.fromRGB(255, 170, 0)
            elseif crop.Name:lower():find("melon") then
                color = Color3.fromRGB(170, 255, 127)
            end
            esp.Color3 = color
            esp.AlwaysOnTop = true
            esp.ZIndex = 5
            esp.Parent = cletusEspFolder
            espCache[crop] = esp
        end
        esp.Transparency = States.Cletus.ESPTransparency
    else
        RemoveCropESP(crop)
    end
end

local function RefreshAllESP()
    for _, crop in ipairs(Services.CollectionService:GetTagged("Crop")) do
        UpdateCropESP(crop)
    end
end

local function OnCropAdded(crop)
    if crop:IsA("BasePart") then
        local conn = crop:GetAttributeChangedSignal("CropStage"):Connect(function()
            UpdateCropESP(crop)
        end)
        table.insert(connections, conn)
        
        local ancConn = crop.AncestryChanged:Connect(function(_, parent)
            if not parent then
                RemoveCropESP(crop)
            end
        end)
        table.insert(connections, ancConn)
        
        UpdateCropESP(crop)
    end
end

connections.CropAdded = Services.CollectionService:GetInstanceAddedSignal("Crop"):Connect(OnCropAdded)
connections.CropRemoved = Services.CollectionService:GetInstanceRemovedSignal("Crop"):Connect(RemoveCropESP)

for _, crop in ipairs(Services.CollectionService:GetTagged("Crop")) do
    OnCropAdded(crop)
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
        
        if not currentEspState then
            for crop, esp in pairs(espCache) do
                esp:Destroy()
            end
            table.clear(espCache)
            cletusEspFolder:ClearAllChildren()
        else
            RefreshAllESP()
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
            local crops = Services.CollectionService:GetTagged("Crop")
            for _, crop in ipairs(crops) do
                if crop:IsA("BasePart") then
                    local stage = crop:GetAttribute("CropStage")
                    if stage and stage >= 3 then
                        local dist = (hrp.Position - crop.Position).Magnitude
                        if dist <= States.Cletus.Range then
                            local bx = math.round(crop.Position.X / 3)
                            local by = math.round(crop.Position.Y / 3)
                            local bz = math.round(crop.Position.Z / 3)
                            
                            local args = {{ ["position"] = vectorHelper.create(bx, by, bz) }}
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
