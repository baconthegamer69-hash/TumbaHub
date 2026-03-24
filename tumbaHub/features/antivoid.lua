-- features/antivoid.lua
-- Logic for Anti-Void (Hovering below Y=29)

if not Mega.Features then Mega.Features = {} end
Mega.Features.AntiVoid = {}

local Services = Mega.Services or {
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players"),
    UserInputService = game:GetService("UserInputService")
}
local LocalPlayer = Services.Players.LocalPlayer
local States = Mega.States

if not States.Player then States.Player = {} end
if States.Player.AntiVoid == nil then States.Player.AntiVoid = false end

if not Mega.Objects.AntiVoidConnections then Mega.Objects.AntiVoidConnections = {} end
local connections = Mega.Objects.AntiVoidConnections

for k, conn in pairs(connections) do
    if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
end
table.clear(connections)

function Mega.Features.AntiVoid.SetEnabled(state)
    States.Player.AntiVoid = state
    
    if state then
        connections.AntiVoidLoop = Services.RunService.Heartbeat:Connect(function()
            if not States.Player.AntiVoid then return end
            local char = LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChild("Humanoid")
            if not hrp or not hum then return end
            
            if hrp.Position.Y < 29 then
                local bv = hrp:FindFirstChild("AntiVoidBV")
                if not bv then
                    bv = Instance.new("BodyVelocity")
                    bv.Name = "AntiVoidBV"
                    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                    bv.Parent = hrp
                    hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z)
                end
                
                local speed = hum.WalkSpeed
                local upVel = 0
                if Services.UserInputService:IsKeyDown(Enum.KeyCode.Space) then upVel = 30 end
                if Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then upVel = -30 end
                
                bv.Velocity = Vector3.new(hum.MoveDirection.X * speed, upVel, hum.MoveDirection.Z * speed)
            else
                local bv = hrp:FindFirstChild("AntiVoidBV")
                if bv then bv:Destroy() end
            end
        end)
    else
        if connections.AntiVoidLoop then
            connections.AntiVoidLoop:Disconnect()
            connections.AntiVoidLoop = nil
        end
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and hrp:FindFirstChild("AntiVoidBV") then
            hrp.AntiVoidBV:Destroy()
        end
    end
end

if States.Player.AntiVoid then
    Mega.Features.AntiVoid.SetEnabled(true)
end