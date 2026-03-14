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

-- Ensure objects exist
if not Mega.Objects.CletusConnections then Mega.Objects.CletusConnections = {} end
local connections = Mega.Objects.CletusConnections

-- Remote
local CropHarvestRemote
task.spawn(function()
    pcall(function()
        CropHarvestRemote = Services.ReplicatedStorage:WaitForChild("rbxts_include", 10):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):WaitForChild("CropHarvest")
    end)
    if not CropHarvestRemote then
        warn("TumbaHub: CropHarvestRemote not found! AutoHarvest will not work.")
    else
        print("TumbaHub: CropHarvestRemote found.")
    end
end)

-- Helper for vector.create
local vector = vector -- Capture global if exists
if not vector and getgenv then
    pcall(function() vector = getgenv().vector end)
end
if not vector then
    vector = {
        create = function(x, y, z)
            return Vector3.new(x, y, z)
        end
    }
end

-- ESP Folder
local cletusEspFolder = Instance.new("Folder")
cletusEspFolder.Name = "CletusESP"
-- Try to parent to main GUI if exists, else CoreGui
if Mega.Objects.GUI then
    cletusEspFolder.Parent = Mega.Objects.GUI
else
    cletusEspFolder.Parent = Services.CoreGui
end

local function ClearCletusESP()
    for _, conn in pairs(connections) do
        if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
    end
    table.clear(connections)
    cletusEspFolder:ClearAllChildren()
end

local function EnableCletusESP()
    ClearCletusESP()
    
    if States.Cletus.Enabled and States.Cletus.ESP then
         local function updateCrop(crop)
            if not crop:IsA("BasePart") then return end
            local espName = crop:GetDebugId()
            local existing = cletusEspFolder:FindFirstChild(espName)
            
            local stage = crop:GetAttribute("CropStage")
            
            if stage and stage >= 3 then
                if not existing then
                    local esp = Instance.new("BoxHandleAdornment")
                    esp.Name = espName
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
                    esp.Transparency = States.Cletus.ESPTransparency
                    esp.Parent = cletusEspFolder
                end
            else
                if existing then existing:Destroy() end
            end
         end
         
         local function onCropAdded(crop)
             updateCrop(crop)
             local conn = crop:GetAttributeChangedSignal("CropStage"):Connect(function()
                 updateCrop(crop)
             end)
             table.insert(connections, conn)
             
             local ancestryConn = crop.AncestryChanged:Connect(function(_, parent)
                 if not parent then
                     local espName = crop:GetDebugId()
                     local existing = cletusEspFolder:FindFirstChild(espName)
                     if existing then existing:Destroy() end
                 end
             end)
             table.insert(connections, ancestryConn)
         end
         
         local addedConn = Services.CollectionService:GetInstanceAddedSignal("Crop"):Connect(onCropAdded)
         table.insert(connections, addedConn)
         
         for _, crop in ipairs(Services.CollectionService:GetTagged("Crop")) do
             onCropAdded(crop)
         end
    end
end

local function UpdateCletusTransparency()
    for _, h in ipairs(cletusEspFolder:GetChildren()) do
        if h:IsA("BoxHandleAdornment") then
            h.Transparency = States.Cletus.ESPTransparency
        end
    end
end

local lastCletusRun = 0
local function AutoHarvestLoop()
    if not States.Cletus.Enabled then return end
    
    -- Auto Harvest Logic
    if States.Cletus.AutoHarvest and CropHarvestRemote then
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
                                local blockPos = Vector3.new(math.round(crop.Position.X / 3), math.round(crop.Position.Y / 3), math.round(crop.Position.Z / 3))
                                local args = {{ ["position"] = vector.create(blockPos.X, blockPos.Y, blockPos.Z) }}
                                task.spawn(function()
                                    pcall(function() CropHarvestRemote:InvokeServer(unpack(args)) end)
                                end)
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Public Functions
function Mega.Features.Cletus.SetEnabled(state)
    States.Cletus.Enabled = state
    
    if state then
        EnableCletusESP()
        if not Mega.Objects.Connections.CletusLoop then
            Mega.Objects.Connections.CletusLoop = Services.RunService.Heartbeat:Connect(AutoHarvestLoop)
        end
    else
        ClearCletusESP()
        if Mega.Objects.Connections.CletusLoop then
            Mega.Objects.Connections.CletusLoop:Disconnect()
            Mega.Objects.Connections.CletusLoop = nil
        end
    end
end

function Mega.Features.Cletus.UpdateVisuals()
    UpdateCletusTransparency()
end

function Mega.Features.Cletus.RecreateESP()
    EnableCletusESP()
end

-- Initialize if enabled
if States.Cletus.Enabled then
    Mega.Features.Cletus.SetEnabled(true)
end

-- Register cleanup
if Mega.Objects.Connections then
    table.insert(Mega.Objects.Connections, {
        Disconnect = function() Mega.Features.Cletus.SetEnabled(false) end
    })
end
