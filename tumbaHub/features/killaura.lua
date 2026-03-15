-- features/killaura.lua
-- Logic for Killaura (Original Logic Restored)

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

local function getWeapon()
    local char = LocalPlayer.Character
    if not char then return nil end
    if char:FindFirstChild("HandInvItem") and char.HandInvItem.Value then
        return char.HandInvItem.Value
    end
    
    local tool = char:FindFirstChildOfClass("Tool")
    if tool and (tool.Name:lower():find("sword") or tool.Name:lower():find("blade") or tool.Name:lower():find("scythe")) then
        return tool
    end
    
    local inv = Services.ReplicatedStorage:FindFirstChild("Inventories") and Services.ReplicatedStorage.Inventories:FindFirstChild(LocalPlayer.Name)
    if inv then
        for _, v in pairs(inv:GetChildren()) do
            if v.Name:lower():find("sword") or v.Name:lower():find("blade") or v.Name:lower():find("scythe") then 
                return v 
            end
        end
    end
    return nil
end

local vec3 = (vector and vector.create) or Vector3.new

local killauraActive = false

function Mega.Features.Killaura.SetEnabled(state)
    States.Combat.Killaura.Enabled = state
    
    if state and not killauraActive then
        killauraActive = true
        task.spawn(function()
            while States.Combat.Killaura.Enabled do
                if not Mega.Objects.GUI or not Mega.Objects.GUI.Parent then 
                    killauraActive = false
                    break 
                end
                
                if SwordHitRemote then
                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    local weapon = getWeapon()
                    
                    if hrp and weapon then
                        for _, obj in pairs(Services.Workspace:GetChildren()) do
                            if obj ~= char and (obj:FindFirstChild("Humanoid") or obj.Name:find("Dummy")) then
                                local tHrp = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
                                local hum = obj:FindFirstChild("Humanoid")
                                
                                if tHrp and (not hum or hum.Health > 0) then
                                    local p = Services.Players:GetPlayerFromCharacter(obj)
                                    local isEnemy = true
                                    if p and p.Team and LocalPlayer.Team and p.Team == LocalPlayer.Team then
                                        isEnemy = false
                                    end

                                    if isEnemy then
                                        local dist = (hrp.Position - tHrp.Position).Magnitude
                                        if dist < States.Combat.Killaura.Range and dist > 0 then
                                            local direction = (tHrp.Position - hrp.Position).Unit
                                            local spoofedSelfPos = hrp.Position
                                            if dist > 14 then
                                                spoofedSelfPos = tHrp.Position - (direction * 14)
                                            end
                                            
                                            local args = {
                                                {
                                                    ["chargedAttack"] = { ["chargeRatio"] = 0 },
                                                    ["entityInstance"] = obj,
                                                    ["validate"] = {
                                                        ["targetPosition"] = { ["value"] = vec3(tHrp.Position.X, tHrp.Position.Y, tHrp.Position.Z) },
                                                        ["selfPosition"] = { ["value"] = vec3(spoofedSelfPos.X, spoofedSelfPos.Y, spoofedSelfPos.Z) },
                                                        ["raycast"] = {
                                                            ["cameraPosition"] = { ["value"] = vec3(spoofedSelfPos.X, spoofedSelfPos.Y + 3, spoofedSelfPos.Z) },
                                                            ["cursorDirection"] = { ["value"] = vec3(direction.X, direction.Y, direction.Z) }
                                                        }
                                                    },
                                                    ["weapon"] = weapon
                                                }
                                            }
                                            pcall(function() SwordHitRemote:FireServer(unpack(args)) end)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                
                if States.Combat.Killaura.Delay > 0 then
                    task.wait(States.Combat.Killaura.Delay / 1000)
                else
                    Services.RunService.Heartbeat:Wait()
                end
            end
            killauraActive = false
        end)
    end
end
