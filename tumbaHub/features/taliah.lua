-- features/taliah.lua
-- Logic for Taliah kit (Chickens ESP and Auto Collect)

if not Mega.Features then Mega.Features = {} end
Mega.Features.Taliah = {}

local Services = Mega.Services
local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

-- Убедимся, что настройки существуют (fallback)
if States.Taliah == nil then
    States.Taliah = {
        Enabled = false,
        ESP = false,
        ESPTransparency = 0.2,
        AutoCollect = false,
        CollectRadius = 5
    }
end

if not Mega.Objects.TaliahConnections then Mega.Objects.TaliahConnections = {} end
local connections = Mega.Objects.TaliahConnections

-- Remote
local HarvestRemote
task.spawn(function()
    pcall(function()
        HarvestRemote = Services.ReplicatedStorage:WaitForChild("rbxts_include", 10):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):WaitForChild("BedwarsHarvestCrop")
    end)
end)

local function UpdateChickenESP()
    for _, block in ipairs(Services.CollectionService:GetTagged("HarvestableCrop")) do
        if block.Name == "chicken_egg_block" then
            local stage = block:GetAttribute("CropStage")
            
            -- Находим визуальную цель (stage_4 или сам блок)
            local target = block:FindFirstChild("stage_4") or block
            
            -- Принудительная видимость для stage_4
            if target.Name == "stage_4" then
                local targetTransparency = (States.Taliah.Enabled and States.Taliah.ESP) and 0 or 1
                if target:IsA("BasePart") then
                    target.Transparency = targetTransparency
                elseif target:IsA("Model") then
                    for _, v in ipairs(target:GetDescendants()) do
                        if v:IsA("BasePart") then v.Transparency = targetTransparency end
                    end
                end
            end

            if target ~= block then
                local oldEsp = block:FindFirstChild("TaliahESP")
                if oldEsp then oldEsp:Destroy() end
            end
            
            local esp = target:FindFirstChild("TaliahESP")
            
            if States.Taliah.Enabled and States.Taliah.ESP and stage == 4 then
                if not esp then
                    esp = Instance.new("Highlight")
                    esp.Name = "TaliahESP"
                    esp.FillColor = Color3.fromRGB(255, 170, 0) -- Оранжевый
                    esp.OutlineColor = Color3.fromRGB(255, 255, 255)
                    esp.FillTransparency = States.Taliah.ESPTransparency
                    esp.OutlineTransparency = 0
                    esp.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    esp.Adornee = target
                    esp.Parent = target
                else
                    -- Обновляем свойства, если уже существует
                    esp.FillTransparency = States.Taliah.ESPTransparency
                    esp.FillColor = Color3.fromRGB(255, 170, 0)
                    esp.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    esp.Adornee = target
                    esp.Parent = target
                end
            else
                if esp then esp:Destroy() end
                -- Очищаем возможные остатки, если цель сменилась
                local leftover = block:FindFirstChild("TaliahESP")
                if leftover then leftover:Destroy() end
            end
        end
    end
end

function Mega.Features.Taliah.UpdateESP()
    UpdateChickenESP()
end

local lastTaliahCheck = 0
local function AutoCollectLoop()
    if not States.Taliah.Enabled or not States.Taliah.AutoCollect then return end
    
    -- Небольшой троттлинг для производительности
    if tick() % 0.2 > 0.05 then return end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    for _, block in ipairs(Services.CollectionService:GetTagged("HarvestableCrop")) do
        if block.Name == "chicken_egg_block" then
            local stage = block:GetAttribute("CropStage")
            if stage == 4 then
                local dist = (block.Position - root.Position).Magnitude
                if dist <= States.Taliah.CollectRadius then
                    -- 1. Сбор через Remote (если есть)
                    if HarvestRemote then
                        task.spawn(function()
                            pcall(function()
                                HarvestRemote:InvokeServer({
                                    blockInstance = block
                                })
                            end)
                        end)
                    end
                    
                    -- 2. Сбор через ProximityPrompt (резервный вариант)
                    local prompt = block:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt and prompt.Enabled then
                        if fireproximityprompt then
                            fireproximityprompt(prompt)
                        else
                            task.spawn(function()
                                prompt:InputHoldBegin()
                                task.wait(prompt.HoldDuration)
                                prompt:InputHoldEnd()
                            end)
                        end
                    end
                end
            end
        end
    end
end

function Mega.Features.Taliah.SetEnabled(state)
    States.Taliah.Enabled = state
    UpdateChickenESP()
    
    if state then
        if not connections.TaliahAdded then
            connections.TaliahAdded = Services.CollectionService:GetInstanceAddedSignal("HarvestableCrop"):Connect(function(block)
                if block.Name == "chicken_egg_block" then
                    block:GetAttributeChangedSignal("CropStage"):Connect(function()
                        UpdateChickenESP()
                    end)
                    UpdateChickenESP()
                end
            end)
        end
        
        if not connections.TaliahLoop then
            connections.TaliahLoop = Services.RunService.Heartbeat:Connect(AutoCollectLoop)
        end
    else
        if connections.TaliahAdded then
            connections.TaliahAdded:Disconnect()
            connections.TaliahAdded = nil
        end
        if connections.TaliahLoop then
            connections.TaliahLoop:Disconnect()
            connections.TaliahLoop = nil
        end
    end
end

-- Инициализация, если уже включено в конфигурации
if States.Taliah.Enabled then
    Mega.Features.Taliah.SetEnabled(true)
end