-- features/farmer_cletus.lua
-- Logic for Cletus (Farming) - Autonomous Version

if not Mega.Features then Mega.Features = {} end
Mega.Features.Cletus = {}

local Services = Mega.Services
local LocalPlayer = Services.LocalPlayer
local States = Mega.States

if not Mega.Objects.CletusConnections then Mega.Objects.CletusConnections = {} end
local connections = Mega.Objects.CletusConnections

for k, conn in pairs(connections) do
    if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
end
table.clear(connections)

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

local function UpdateCropESP()
    for _, crop in ipairs(Services.CollectionService:GetTagged("Crop")) do
        if crop:IsA("BasePart") then
            local stage = crop:GetAttribute("CropStage")
            local espName = crop:GetDebugId()
            local esp = cletusEspFolder:FindFirstChild(espName)
            
            if States.Cletus.Enabled and States.Cletus.ESP and stage and stage >= 3 then
                if not esp then
                    esp = Instance.new("BoxHandleAdornment")
                    esp.Name = espName
                    esp.Adornee = crop
                    esp.Size = crop.Size + Vector3.new(0.1, 0.1, 0.1)
                    
                    local color = Color3.fromRGB(0, 255, 0)
                    local cName = crop.Name:lower()
                    if cName:find("carrot") then
                        color = Color3.fromRGB(255, 170, 0)
                    elseif cName:find("melon") then
                        color = Color3.fromRGB(170, 255, 127)
                    end
                    esp.Color3 = color
                    esp.AlwaysOnTop = true
                    esp.ZIndex = 5
                    esp.Parent = cletusEspFolder
                end
                esp.Transparency = States.Cletus.ESPTransparency
            else
                if esp then esp:Destroy() end
            end
        end
    end
end

local function OnCropAdded(crop)
    if crop:IsA("BasePart") then
        local conn = crop:GetAttributeChangedSignal("CropStage"):Connect(function()
            UpdateCropESP()
        end)
        table.insert(connections, conn)
        UpdateCropESP()
    end
end

connections.CropAdded = Services.CollectionService:GetInstanceAddedSignal("Crop"):Connect(OnCropAdded)
for _, crop in ipairs(Services.CollectionService:GetTagged("Crop")) do
    OnCropAdded(crop)
end

local lastEspState = false
local lastEspTrans = States.Cletus.ESPTransparency
connections.StateWatcher = Services.RunService.Heartbeat:Connect(function()
    local currentEspState = States.Cletus.Enabled and States.Cletus.ESP
    local currentTrans = States.Cletus.ESPTransparency
    
    if currentEspState ~= lastEspState or currentTrans ~= lastEspTrans then
        lastEspState = currentEspState
        lastEspTrans = currentTrans
        UpdateCropESP()
    end
end)

local lastCletusRun = 0
connections.AutoHarvestLoop = Services.RunService.Heartbeat:Connect(function()
    if not States.Cletus.Enabled or not States.Cletus.AutoHarvest then return end
    
    if tick() - lastCletusRun < 0.5 then return end
    lastCletusRun = tick()

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    for _, crop in ipairs(Services.CollectionService:GetTagged("Crop")) do
        if crop:IsA("BasePart") and crop.Parent then
            local stage = crop:GetAttribute("CropStage")
            if stage and stage >= 3 then
                local dist = (hrp.Position - crop.Position).Magnitude
                if dist <= States.Cletus.Range then
                    if CropHarvestRemote then
                        local blockPos = Vector3.new(math.round(crop.Position.X / 3), math.round(crop.Position.Y / 3), math.round(crop.Position.Z / 3))
                        local args = {{ ["position"] = vector.create(blockPos.X, blockPos.Y, blockPos.Z) }}
                        task.spawn(function()
                            pcall(function() CropHarvestRemote:InvokeServer(unpack(args)) end)
                        end)
                    end
                    
                    local prompt = crop:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt and prompt.Enabled then
                        if fireproximityprompt then
                            fireproximityprompt(prompt)
                        else
                            task.spawn(function()
                                pcall(function()
                                    prompt:InputHoldBegin()
                                    task.wait(prompt.HoldDuration)
                                    prompt:InputHoldEnd()
                                end)
                            end)
                        end
                    end
                end
            end
        end
    end
end)

function Mega.Features.Cletus.SetEnabled(state) States.Cletus.Enabled = state end
function Mega.Features.Cletus.UpdateVisuals() end
function Mega.Features.Cletus.RecreateESP() end
