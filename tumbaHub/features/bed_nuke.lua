-- features/bed_nuke.lua
-- Logic for Bed Nuker

if not Mega.Features then Mega.Features = {} end
Mega.Features.BedNuke = {}

local Services = Mega.Services or {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    CollectionService = game:GetService("CollectionService"),
    RunService = game:GetService("RunService"),
    CoreGui = game:GetService("CoreGui")
}
local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

-- Гарантируем, что настройки существуют
if not States.Combat then States.Combat = {} end
if not States.Combat.BedNuke then
    States.Combat.BedNuke = { Enabled = false, Range = 25, MinRange = 1, PacketsPerTick = 1, Delay = 0 }
end

if not Mega.Objects.BedNukeConnections then Mega.Objects.BedNukeConnections = {} end
local connections = Mega.Objects.BedNukeConnections

for k, conn in pairs(connections) do
    if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
end
table.clear(connections)

local DamageBlockRemote
task.spawn(function()
    pcall(function()
        DamageBlockRemote = Services.ReplicatedStorage:WaitForChild("rbxts_include", 10)
            :WaitForChild("node_modules")
            :WaitForChild("@easy-games")
            :WaitForChild("block-engine")
            :WaitForChild("node_modules")
            :WaitForChild("@rbxts")
            :WaitForChild("net")
            :WaitForChild("out")
            :WaitForChild("_NetManaged")
            :WaitForChild("DamageBlock")
    end)
end)

local vector = vector or {create = function(x, y, z) return Vector3.new(x, y, z) end}
local lastCheck = 0
local lastBreakTime = 0

local espFolder = Services.CoreGui:FindFirstChild("BedNukeESP")
if not espFolder then
    espFolder = Instance.new("Folder")
    espFolder.Name = "BedNukeESP"
    espFolder.Parent = Services.CoreGui
end

local function DrawESP(blocks)
    espFolder:ClearAllChildren()
    for _, bPos in ipairs(blocks) do
        local box = Instance.new("BoxHandleAdornment")
        box.Size = Vector3.new(3.1, 3.1, 3.1)
        box.CFrame = CFrame.new(bPos * 3)
        box.AlwaysOnTop = true
        box.ZIndex = 5
        box.Transparency = 0.5
        box.Color3 = Color3.fromRGB(255, 50, 50)
        box.Adornee = game.Workspace.Terrain -- Привязываем к террейну
        box.Parent = espFolder
    end
end

local function GetBlocksToBreak(hrpPos, bedPart)
    local blocksList = {}
    local seen = {}
    local bedPos = bedPart.Position
    
    local dir = (bedPos - hrpPos).Unit
    local dist = (bedPos - hrpPos).Magnitude
    
    local overlap = OverlapParams.new()
    overlap.FilterType = Enum.RaycastFilterType.Whitelist
    local whitelist = {}
    
    -- Ищем папку с блоками на карте
    local blocksFolder = game.Workspace:FindFirstChild("Map") and game.Workspace.Map:FindFirstChild("Blocks") or game.Workspace:FindFirstChild("Blocks")
    if blocksFolder then table.insert(whitelist, blocksFolder) end
    
    -- Добавляем в whitelist все кровати
    for _, b in ipairs(Services.CollectionService:GetTagged("bed")) do
        if b then table.insert(whitelist, b) end
    end
    overlap.FilterDescendantsInstances = whitelist

    -- Построение маршрута (в линию)
    for i = 0, dist, 1.5 do
        local point = hrpPos + dir * i
        
        -- Ограничение: на уровне OY кровати и выше
        if point.Y >= (bedPos.Y - 1.5) then
            local bPos = Vector3.new(
                math.round(point.X / 3),
                math.round(point.Y / 3),
                math.round(point.Z / 3)
            )
            
            local key = string.format("%d,%d,%d", bPos.X, bPos.Y, bPos.Z)
            if not seen[key] then
                seen[key] = true
                
                local realPos = bPos * 3
                local parts = game.Workspace:GetPartBoundsInBox(CFrame.new(realPos), Vector3.new(2.5, 2.5, 2.5), overlap)
                local hasTarget = false
                for _, p in ipairs(parts) do
                    if p.CanCollide or p.Name:lower():find("bed") then
                        hasTarget = true
                        break
                    end
                end
                
                if hasTarget then
                    table.insert(blocksList, bPos)
                end
            end
        end
    end
    
    -- Всегда добавляем кровать
    local bedBPos = Vector3.new(
        math.round(bedPos.X / 3),
        math.round(bedPos.Y / 3),
        math.round(bedPos.Z / 3)
    )
    local bedKey = string.format("%d,%d,%d", bedBPos.X, bedBPos.Y, bedBPos.Z)
    if not seen[bedKey] then
        table.insert(blocksList, bedBPos)
    end
    
    return blocksList
end

local function BedNukeLoop()
    if not States.Combat.BedNuke.Enabled or not DamageBlockRemote then 
        if espFolder then espFolder:ClearAllChildren() end
        return 
    end
    
    -- Троттлинг
    if tick() - lastCheck < 0.05 then return end
    lastCheck = tick()

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local myTeamId = LocalPlayer:GetAttribute("Team")
    local beds = Services.CollectionService:GetTagged("bed")
    local closestBed = nil
    local closestDist = States.Combat.BedNuke.Range
    local minAllowedDist = States.Combat.BedNuke.MinRange or 1

    for _, bed in ipairs(beds) do
        if bed:IsA("BasePart") or bed:IsA("Model") then
            local bedPart = bed:IsA("BasePart") and bed or bed.PrimaryPart
            if bedPart then
                local bedTeamId = bed:GetAttribute("TeamId") or bed:GetAttribute("Team")
                local health = bed:GetAttribute("Health")
                
                if bedTeamId ~= myTeamId and (not health or health > 0) then
                    local dist = (bedPart.Position - hrp.Position).Magnitude
                    if dist <= closestDist and dist >= minAllowedDist then
                        closestDist = dist
                        closestBed = bed
                    end
                end
            end
        end
    end

    if closestBed then
        local bedPart = closestBed:IsA("BasePart") and closestBed or closestBed.PrimaryPart
        if not bedPart then 
            if espFolder then espFolder:ClearAllChildren() end
            return 
        end

        -- Вычисляем оптимальный прямой маршрут до кровати
        local blocksToBreak = GetBlocksToBreak(hrp.Position, bedPart)
        
        -- Рендер ESP (красных блоков)
        DrawESP(blocksToBreak)
        
        local delayMs = States.Combat.BedNuke.Delay or 0
        local delaySec = delayMs / 1000

        if #blocksToBreak > 0 and (tick() - lastBreakTime >= delaySec) then
            local packetsFired = 0
            
            for _, blockPos in ipairs(blocksToBreak) do
                if packetsFired >= States.Combat.BedNuke.PacketsPerTick then break end
                
                local posArg = vector.create(blockPos.X, blockPos.Y, blockPos.Z)
                local hitPosArg = vector.create(blockPos.X * 3, blockPos.Y * 3, blockPos.Z * 3)
                
                local args = {
                    {
                        ["blockRef"] = {
                            ["blockPosition"] = posArg
                        },
                        ["hitPosition"] = hitPosArg,
                        ["hitNormal"] = vector.create(0, 1, 0)
                    }
                }
                
                task.spawn(function()
                    pcall(function()
                        if DamageBlockRemote:IsA("RemoteEvent") then
                            DamageBlockRemote:FireServer(unpack(args))
                        elseif DamageBlockRemote:IsA("RemoteFunction") then
                            DamageBlockRemote:InvokeServer(unpack(args))
                        end
                    end)
                end)
                
                packetsFired = packetsFired + 1
            end
            
            lastBreakTime = tick()
        end
    else
        if espFolder then espFolder:ClearAllChildren() end
    end
end

function Mega.Features.BedNuke.SetEnabled(state)
    States.Combat.BedNuke.Enabled = state
    if state then
        if not connections.BedNukeLoop then
            connections.BedNukeLoop = Services.RunService.Heartbeat:Connect(BedNukeLoop)
        end
    else
        if connections.BedNukeLoop then
            connections.BedNukeLoop:Disconnect()
            connections.BedNukeLoop = nil
        end
        if espFolder then espFolder:ClearAllChildren() end
    end
end

if States.Combat.BedNuke.Enabled then
    Mega.Features.BedNuke.SetEnabled(true)
end
