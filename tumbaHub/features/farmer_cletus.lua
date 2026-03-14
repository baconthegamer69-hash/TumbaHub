-- features/farmer_cletus.lua
-- Logic for Cletus (Farming) - Original tumbaHub.lua Logic

Mega.Features.Cletus = {}

local Services = Mega.Services
local LocalPlayer = Services.LocalPlayer
local States = Mega.States

-- Remote
local CropHarvestRemote
task.spawn(function()
    pcall(function()
        CropHarvestRemote = Services.ReplicatedStorage:WaitForChild("rbxts_include", 10):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):WaitForChild("CropHarvest")
    end)
end)

local vector = vector or {create = function(x, y, z) return Vector3.new(x, y, z) end}

-- Cletus ESP Logic
local cletusEspFolder = Services.CoreGui:FindFirstChild("CletusESP")
if not cletusEspFolder then
    cletusEspFolder = Instance.new("Folder")
    cletusEspFolder.Name = "CletusESP"
    cletusEspFolder.Parent = Services.CoreGui
end

local cletusConnections = {}

local function EnableCletusESP()
    for _, conn in pairs(cletusConnections) do
        if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
    end
    table.clear(cletusConnections)
    cletusEspFolder:ClearAllChildren()
    
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
             table.insert(cletusConnections, conn)
             
             local ancestryConn = crop.AncestryChanged:Connect(function(_, parent)
                 if not parent then
                     local espName = crop:GetDebugId()
                     local existing = cletusEspFolder:FindFirstChild(espName)
                     if existing then existing:Destroy() end
                 end
             end)
             table.insert(cletusConnections, ancestryConn)
         end
         
         local addedConn = Services.CollectionService:GetInstanceAddedSignal("Crop"):Connect(onCropAdded)
         table.insert(cletusConnections, addedConn)
         
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

if not Mega.Objects.CletusConnections then Mega.Objects.CletusConnections = {} end
if Mega.Objects.CletusConnections.Loop then
    Mega.Objects.CletusConnections.Loop:Disconnect()
end

local lastCletusRun = 0
Mega.Objects.CletusConnections.Loop = Services.RunService.Heartbeat:Connect(function()
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
                    if crop:IsA("BasePart") and crop.Parent then
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
end)

function Mega.Features.Cletus.SetEnabled(state)
    States.Cletus.Enabled = state
    EnableCletusESP()
end

function Mega.Features.Cletus.UpdateVisuals()
    UpdateCletusTransparency()
end

function Mega.Features.Cletus.RecreateESP()
    EnableCletusESP()
end

if States.Cletus.Enabled then
    EnableCletusESP()
end
