-- features/killaura.lua
-- Logic for Killaura (Optimized Single Target + Visual Marker)

if not Mega.Features then Mega.Features = {} end
Mega.Features.Killaura = {}

local Services = Mega.Services or {
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    Workspace = game:GetService("Workspace"),
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players"),
    CoreGui = game:GetService("CoreGui")
}
local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

if not States.Combat then States.Combat = {} end
if not States.Combat.Killaura then
    States.Combat.Killaura = { Enabled = false, Range = 25, Delay = 0 }
end

if not Mega.Objects.KillauraConnections then Mega.Objects.KillauraConnections = {} end
local connections = Mega.Objects.KillauraConnections

for k, conn in pairs(connections) do
    if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
end
table.clear(connections)

local SwordHitRemote
task.spawn(function()
    pcall(function()
        SwordHitRemote = Services.ReplicatedStorage:WaitForChild("rbxts_include", 10):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):WaitForChild("SwordHit")
    end)
end)

local targetMarker
local function GetTargetMarker()
    if not targetMarker then
        targetMarker = Instance.new("BillboardGui")
        targetMarker.Name = "KillauraTargetMarker"
        targetMarker.Size = UDim2.new(0, 45, 0, 45)
        targetMarker.StudsOffset = Vector3.new(0, 4, 0)
        targetMarker.AlwaysOnTop = true

        local icon = Instance.new("ImageLabel", targetMarker)
        icon.Size = UDim2.new(1, 0, 1, 0)
        icon.BackgroundTransparency = 1
        icon.Image = "rbxassetid://13426210080" -- Иконка прицела
        icon.ImageColor3 = Color3.fromRGB(255, 50, 50)
        
        -- Анимация вращения маркера
        connections.MarkerSpin = Services.RunService.RenderStepped:Connect(function()
            if targetMarker.Adornee then
                icon.Rotation = icon.Rotation + 3
            end
        end)
    end
    if Services.CoreGui and targetMarker.Parent ~= Services.CoreGui then
        targetMarker.Parent = Services.CoreGui:FindFirstChild("TumbaESP_Container") or Services.CoreGui
    end
    return targetMarker
end

local function getWeapon()
    local char = LocalPlayer.Character
    if not char then return nil end
    if char:FindFirstChild("HandInvItem") and char.HandInvItem.Value then
        return char.HandInvItem.Value
    end
    
    local inv = Services.ReplicatedStorage:FindFirstChild("Inventories") and Services.ReplicatedStorage.Inventories:FindFirstChild(LocalPlayer.Name)
    if inv then
        local possibleWeapons = {"sword", "blade", "scythe", "dao", "mace", "hammer", "dagger", "sickle", "glove", "axe", "pickaxe"}
        for _, wName in ipairs(possibleWeapons) do
            for _, v in pairs(inv:GetChildren()) do
                if v.Name:lower():find(wName) then 
                    return v 
                end
            end
        end
    end
    return nil
end

local lastHitTime = 0
local vec3 = (vector and vector.create) or Vector3.new

connections.KillauraLoop = Services.RunService.Heartbeat:Connect(function()
    local marker = GetTargetMarker()
    
    if not States.Combat.Killaura.Enabled or not SwordHitRemote then
        marker.Adornee = nil
        return
    end

    local delaySecs = States.Combat.Killaura.Delay / 1000
    if tick() - lastHitTime < delaySecs then return end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local weapon = getWeapon()

    if not hrp or not weapon then
        marker.Adornee = nil
        return
    end

    local closestTarget = nil
    local closestDist = States.Combat.Killaura.Range

    -- Находим ТОЛЬКО одного ближайшего игрока/моба
    for _, obj in pairs(Services.Workspace:GetChildren()) do
        if obj ~= char then
            local tHrp = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
            local hum = obj:FindFirstChildOfClass("Humanoid")
            
            if tHrp and (hum or obj.Name:find("Dummy")) then
                if not hum or hum.Health > 0 then
                    local p = Services.Players:GetPlayerFromCharacter(obj)
                    local isEnemy = true
                    if p and p.Team and LocalPlayer.Team and p.Team == LocalPlayer.Team then
                        isEnemy = false
                    end

                    if isEnemy then
                        local dist = (hrp.Position - tHrp.Position).Magnitude
                        if dist < closestDist and dist > 0 then
                            closestDist = dist
                            closestTarget = obj
                        end
                    end
                end
            end
        end
    end

    if closestTarget then
        local tHrp = closestTarget:FindFirstChild("HumanoidRootPart") or closestTarget.PrimaryPart
        marker.Adornee = tHrp -- Вешаем маркер на цель
        
        local direction = (tHrp.Position - hrp.Position).Unit
        local spoofedSelfPos = closestDist > 14.4 and (tHrp.Position - (direction * 14.4)) or hrp.Position
        
        local args = { { ["chargedAttack"] = { ["chargeRatio"] = 0 }, ["entityInstance"] = closestTarget, ["validate"] = { ["targetPosition"] = { ["value"] = vec3(tHrp.Position.X, tHrp.Position.Y, tHrp.Position.Z) }, ["selfPosition"] = { ["value"] = vec3(spoofedSelfPos.X, spoofedSelfPos.Y, spoofedSelfPos.Z) }, ["raycast"] = { ["cameraPosition"] = { ["value"] = vec3(spoofedSelfPos.X, spoofedSelfPos.Y + 3, spoofedSelfPos.Z) }, ["cursorDirection"] = { ["value"] = vec3(direction.X, direction.Y, direction.Z) } } }, ["weapon"] = weapon } }
        task.spawn(function() pcall(function() SwordHitRemote:FireServer(unpack(args)) end) end)
        lastHitTime = tick()
    else
        marker.Adornee = nil -- Убираем маркер, если нет целей
    end
end)

function Mega.Features.Killaura.SetEnabled(state)
    States.Combat.Killaura.Enabled = state
    if not state and targetMarker then
        targetMarker.Adornee = nil
    end
end
