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
if type(States.Player.AntiVoid) ~= "table" then
    local oldState = type(States.Player.AntiVoid) == "boolean" and States.Player.AntiVoid or false
    States.Player.AntiVoid = { Enabled = oldState, YLevel = 29, ESP = false, ESPTransparency = 0.5 }
end
if States.Player.AntiVoid.YLevel == nil then States.Player.AntiVoid.YLevel = 29 end
if States.Player.AntiVoid.ESP == nil then States.Player.AntiVoid.ESP = false end
if States.Player.AntiVoid.ESPTransparency == nil then States.Player.AntiVoid.ESPTransparency = 0.5 end

if not Mega.Objects.AntiVoidConnections then Mega.Objects.AntiVoidConnections = {} end
local connections = Mega.Objects.AntiVoidConnections

for k, conn in pairs(connections) do
    if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
end
table.clear(connections)

local espPart = nil

function Mega.Features.AntiVoid.UpdateESP()
    if not States.Player.AntiVoid.Enabled or not States.Player.AntiVoid.ESP then
        if espPart then
            espPart:Destroy()
            espPart = nil
        end
        return
    end

    if not espPart then
        espPart = Instance.new("Part")
        espPart.Name = "AntiVoidESP"
        espPart.Anchored = true
        espPart.CanCollide = false
        espPart.Size = Vector3.new(2048, 2, 2048)
        espPart.Material = Enum.Material.ForceField
        espPart.Color = Color3.fromRGB(255, 50, 50)
        espPart.CastShadow = false
        espPart.Parent = Services.Workspace
    end
    
    espPart.Transparency = States.Player.AntiVoid.ESPTransparency
end

function Mega.Features.AntiVoid.SetEnabled(state)
    States.Player.AntiVoid.Enabled = state
    Mega.Features.AntiVoid.UpdateESP()
    
    if state then
        connections.AntiVoidLoop = Services.RunService.Heartbeat:Connect(function()
            if not States.Player.AntiVoid.Enabled then return end
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")
            
            if espPart and hrp then
                espPart.Position = Vector3.new(hrp.Position.X, States.Player.AntiVoid.YLevel, hrp.Position.Z)
            end
            
            if not hrp or not hum then return end
            
            if hrp.Position.Y < States.Player.AntiVoid.YLevel then
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
        Mega.Features.AntiVoid.UpdateESP()
    end
end

if type(States.Player.AntiVoid) == "table" and States.Player.AntiVoid.Enabled then
    Mega.Features.AntiVoid.SetEnabled(true)
end
