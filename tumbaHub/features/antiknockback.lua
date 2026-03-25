-- features/antiknockback.lua
-- Logic for Anti-Knockback

if not Mega.Features then Mega.Features = {} end
Mega.Features.AntiKnockback = {}

local Services = Mega.Services or {
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players")
}
local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

if not States.Player then States.Player = {} end
if States.Player.AntiKnockback == nil then States.Player.AntiKnockback = false end
if States.Player.KnockbackStrength == nil then States.Player.KnockbackStrength = 0 end

if not Mega.Objects.AntiKnockbackConnections then Mega.Objects.AntiKnockbackConnections = {} end
local connections = Mega.Objects.AntiKnockbackConnections

for k, conn in pairs(connections) do
    if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
end
table.clear(connections)

function Mega.Features.AntiKnockback.SetEnabled(state)
    States.Player.AntiKnockback = state
    
    if state then
        connections.AntiKBLoop = Services.RunService.RenderStepped:Connect(function()
            if not States.Player.AntiKnockback then return end
            
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")
            if not hrp or not hum then return end

            -- 1. Удаляем объекты, создающие физическое отбрасывание (игнорируя нужные нам)
            for _, obj in pairs(hrp:GetChildren()) do
                if obj:IsA("BodyVelocity") or obj:IsA("LinearVelocity") or obj:IsA("BodyForce") or obj:IsA("BodyPosition") then
                    local name = obj.Name
                    if name ~= "VapeFlyVelocity" and name ~= "VapeFlyGyro" and name ~= "AntiVoidBV" and name ~= "BedNukeBypass" then
                        obj:Destroy()
                    end
                end
            end

            -- 2. Гасим моментальное изменение AssemblyLinearVelocity (рывки)
            local currentVel = hrp.AssemblyLinearVelocity
            local horizontalVel = Vector3.new(currentVel.X, 0, currentVel.Z)
            local walkSpeed = hum.WalkSpeed
            
            -- Если горизонтальная скорость превышает вашу скорость бега (+ небольшой запас), это значит вас отбросило
            if horizontalVel.Magnitude > walkSpeed + 2 then
                local strengthMultiplier = States.Player.KnockbackStrength / 100
                local reducedVel = horizontalVel.Unit * (horizontalVel.Magnitude * strengthMultiplier)
                hrp.AssemblyLinearVelocity = Vector3.new(reducedVel.X, currentVel.Y, reducedVel.Z)
            end
        end)
    else
        if connections.AntiKBLoop then
            connections.AntiKBLoop:Disconnect()
            connections.AntiKBLoop = nil
        end
    end
end

if States.Player.AntiKnockback then
    Mega.Features.AntiKnockback.SetEnabled(true)
end