-- features/bed_nuke.lua
-- Logic for Bed Nuker

if not Mega.Features then Mega.Features = {} end
Mega.Features.BedNuke = {}

local Services = Mega.Services or {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    CollectionService = game:GetService("CollectionService"),
    RunService = game:GetService("RunService")
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

local function BedNukeLoop()
    if not States.Combat.BedNuke.Enabled or not DamageBlockRemote then return end
    
    -- Троттлинг 20 тиков в секунду, чтобы избежать кика за спам
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
        local blockPos = closestBed:GetAttribute("BlockPosition")
        if not blockPos then
            local bedPart = closestBed:IsA("BasePart") and closestBed or closestBed.PrimaryPart
            blockPos = Vector3.new(math.round(bedPart.Position.X / 3), math.round(bedPart.Position.Y / 3), math.round(bedPart.Position.Z / 3))
        end

        if blockPos then
            local posArg = vector.create(blockPos.X, blockPos.Y, blockPos.Z)
            local args = {
                {
                    ["blockRef"] = {
                        ["blockPosition"] = posArg
                    },
                    ["hitPosition"] = posArg,
                    ["hitNormal"] = vector.create(0, 1, 0)
                }
            }
            
            local delayMs = States.Combat.BedNuke.Delay or 0
            for i = 1, States.Combat.BedNuke.PacketsPerTick do
                task.spawn(function()
                    if delayMs > 0 then task.wait(delayMs / 1000) end
                    pcall(function()
                        if DamageBlockRemote:IsA("RemoteEvent") then
                            DamageBlockRemote:FireServer(unpack(args))
                        elseif DamageBlockRemote:IsA("RemoteFunction") then
                            DamageBlockRemote:InvokeServer(unpack(args))
                        end
                    end)
                end)
            end
        end
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
    end
end

if States.Combat.BedNuke.Enabled then
    Mega.Features.BedNuke.SetEnabled(true)
end
