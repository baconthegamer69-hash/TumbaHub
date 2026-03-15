-- features/follow.lua
-- Logic for Follow Player (Camera tracking)

if not Mega.Features then Mega.Features = {} end
Mega.Features.Follow = {}

local Services = Mega.Services or {
    RunService = game:GetService("RunService"),
    Workspace = game:GetService("Workspace")
}
local States = Mega.States

if not Mega.Objects.FollowConnections then Mega.Objects.FollowConnections = {} end
local connections = Mega.Objects.FollowConnections

for k, conn in pairs(connections) do
    if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
end
table.clear(connections)

function Mega.Features.Follow.StopFollow()
    States.Player.FollowTarget = nil
    Services.Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
    if Mega.ShowNotification then
        Mega.ShowNotification(Mega.GetText("notify_follow_stop"))
    end
end

connections.FollowLoop = Services.RunService.Heartbeat:Connect(function()
    if States.Player.FollowTarget then
        local target = States.Player.FollowTarget
        if target.Character and target.Character:FindFirstChildOfClass("Humanoid") then
            local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                Services.Workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
                Services.Workspace.CurrentCamera.CFrame = targetRoot.CFrame * CFrame.new(0, 5, 15)
            end

            if target.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then
                Mega.Features.Follow.StopFollow()
            end
        else
            Mega.Features.Follow.StopFollow()
        end
    end
end)