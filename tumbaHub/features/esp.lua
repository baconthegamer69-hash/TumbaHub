-- features/esp.lua
-- All logic for Player ESP and Kit ESP.

Mega.Features.ESP = {}

local Services = Mega.Services
local States = Mega.States
local Settings = Mega.Settings

local espFolder = Instance.new("Folder", Services.CoreGui)
espFolder.Name = "TumbaESP_Container"

local kitEspFolder = Instance.new("Folder", espFolder)
kitEspFolder.Name = "TumbaKitESP_Container"

local playerEspConnections = {}
local kitEspConnections = {}
local kitEspObjects = {}

local ICONS = {
    ["iron"] = "rbxassetid://6850537969",
    ["bee"] = "rbxassetid://7343272839",
    ["natures_essence_1"] = "rbxassetid://11003449842",
    ["thorns"] = "rbxassetid://9134549615",
    ["mushrooms"] = "rbxassetid://9134534696",
    ["wild_flower"] = "rbxassetid://9134545166",
    ["crit_star"] = "rbxassetid://9866757805",
    ["vitality_star"] = "rbxassetid://9866757969",
    ["alchemy_crystal"] = "rbxassetid://9134545166"
}

--#region Kit ESP Logic
local function espadd(v, icon)
    if not v or not v.PrimaryPart then return end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = v.PrimaryPart
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.fromOffset(32, 32)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 3, 1.5)
    billboard.Parent = kitEspFolder

    local image = Instance.new("ImageLabel", billboard)
    image.BackgroundTransparency = 0.5
    image.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    image.Image = ICONS[icon] or ""
    image.Size = UDim2.fromScale(1, 1)
    Instance.new("UICorner", image).CornerRadius = UDim.new(0, 4)

    kitEspObjects[v] = billboard

    local conn = v.AncestryChanged:Connect(function(_, parent)
        if not parent then
            if kitEspObjects[v] == billboard then kitEspObjects[v] = nil end
            billboard:Destroy()
        end
    end)
    billboard.Destroying:Connect(function()
        conn:Disconnect()
        if kitEspObjects[v] == billboard then kitEspObjects[v] = nil end
    end)
end

local function addKit(tag, icon, isCustom)
    local function processInstance(v)
        if isCustom then
            if v.Name == tag and v:IsA("Model") then espadd(v, icon) end
        else
            if v:HasTag(tag) then espadd(v, icon) end
        end
    end

    table.insert(kitEspConnections, Services.CollectionService:GetInstanceAddedSignal(tag):Connect(function(v) espadd(v.PrimaryPart and v, icon) end))
    table.insert(kitEspConnections, Services.CollectionService:GetInstanceRemovedSignal(tag):Connect(function(v) if kitEspObjects[v.PrimaryPart] then kitEspObjects[v.PrimaryPart]:Destroy() end end))
    
    if isCustom then
        table.insert(kitEspConnections, Services.Workspace.ChildAdded:Connect(processInstance))
        for _, child in ipairs(Services.Workspace:GetChildren()) do processInstance(child) end
    else
        for _, instance in ipairs(Services.CollectionService:GetTagged(tag)) do processInstance(instance) end
    end
end

function Mega.Features.ESP.RecreateKitESP()
    for _, v in pairs(kitEspConnections) do v:Disconnect() end
    table.clear(kitEspConnections)
    kitEspFolder:ClearAllChildren()
    table.clear(kitEspObjects)

    if not States.KitESP.Enabled then return end

    local filters = States.KitESP.Filters
    if filters.Iron then addKit("hidden-metal", "iron") end
    if filters.Bee then addKit("bee", "bee") end
    if filters.Thorns then addKit("Thorns", "thorns", true) end
    if filters.Mushrooms then addKit("Mushrooms", "mushrooms", true) end
    if filters.Sorcerer then addKit("alchemy_crystal", "alchemy_crystal") end
end

function Mega.Features.ESP.SetKitEnabled(state)
    kitEspFolder.Enabled = state
    Mega.Features.ESP.RecreateKitESP()
end
--#endregion

--#region Player ESP Logic
if not Mega.Objects.ESP then Mega.Objects.ESP = {} end

local function CreateESP(player)
    if player == Services.LocalPlayer then return end

    local esp = {
        box = Drawing.new("Square"),
        name = Drawing.new("Text"),
        distance = Drawing.new("Text"),
        healthBarBack = Drawing.new("Square"),
        healthBarFront = Drawing.new("Square"),
        tracer = Drawing.new("Line")
    }

    esp.box.Visible = false
    esp.box.Thickness = 2
    esp.box.Filled = false
    esp.box.ZIndex = 1

    esp.name.Visible = false
    esp.name.Size = 14
    esp.name.Center = true
    esp.name.Outline = true
    esp.name.ZIndex = 1

    esp.distance.Visible = false
    esp.distance.Size = 12
    esp.distance.Center = true
    esp.distance.Outline = true
    esp.distance.ZIndex = 1

    esp.healthBarBack.Visible = false
    esp.healthBarBack.Thickness = 1
    esp.healthBarBack.Color = Color3.fromRGB(0, 0, 0)
    esp.healthBarBack.Filled = true

    esp.healthBarFront.Visible = false
    esp.healthBarFront.Thickness = 1
    esp.healthBarFront.Filled = true

    esp.tracer.Visible = false
    esp.tracer.Thickness = 1
    esp.tracer.ZIndex = 1

    Mega.Objects.ESP[player] = esp
end

local function RemoveESP(player)
    if Mega.Objects.ESP[player] then
        for _, drawing in pairs(Mega.Objects.ESP[player]) do
            drawing:Remove()
        end
        Mega.Objects.ESP[player] = nil
    end
end

local function UpdateESPColors()
    for player, esp in pairs(Mega.Objects.ESP) do
        if player and player.Character then
            local isTeam = player.Team and (player.Team == Services.LocalPlayer.Team)
            local color = States.ESP.EnemyColor
            
            if States.ESP.UseTeamColor and player.Team and player.Team.TeamColor then
                color = player.Team.TeamColor.Color
            elseif isTeam then
                color = States.ESP.TeamColor
            else
                color = States.ESP.EnemyColor
            end

            esp.box.Color = color
            esp.name.Color = color
            esp.distance.Color = color
            esp.tracer.Color = color
        end
    end
end

local function UpdateESP()
    local camera = Services.Workspace.CurrentCamera
    local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
    
    local localChar = Services.LocalPlayer.Character
    local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")

    for player, esp in pairs(Mega.Objects.ESP) do
        local isVisible = false
        
        if player and player.Character and localRoot then
            local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
            local head = player.Character:FindFirstChild("Head")
            local humanoid = player.Character:FindFirstChild("Humanoid")

            if rootPart and head and humanoid and humanoid.Health > 0 then
                local isTeammate = player.Team and Services.LocalPlayer.Team and (player.Team == Services.LocalPlayer.Team)
                
                if not (isTeammate and not States.ESP.ShowTeam) then
                    local screenPos, onScreen = camera:WorldToViewportPoint(rootPart.Position)
                    local distance = (localRoot.Position - rootPart.Position).Magnitude

                    if onScreen and distance <= States.ESP.MaxDistance then
                        isVisible = true
                        local scale = 1000 / distance
                        local width = scale * 2
                        local height = scale * 3

                        if States.ESP.Boxes then
                            esp.box.Visible = States.ESP.Enabled
                            esp.box.Position = Vector2.new(screenPos.X - width / 2, screenPos.Y - height / 2)
                            esp.box.Size = Vector2.new(width, height)
                        else
                            esp.box.Visible = false
                        end

                        if States.ESP.Names then
                            esp.name.Visible = States.ESP.Enabled
                            esp.name.Position = Vector2.new(screenPos.X, screenPos.Y - height / 2 - 20)
                            esp.name.Text = player.Name
                        else
                            esp.name.Visible = false
                        end

                        if States.ESP.Distance then
                            esp.distance.Visible = States.ESP.Enabled
                            esp.distance.Position = Vector2.new(screenPos.X, screenPos.Y + height / 2 + 10)
                            esp.distance.Text = Mega.GetText("esp_studs", math.floor(distance))
                        else
                            esp.distance.Visible = false
                        end

                        if States.ESP.Health then
                            local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                            local barHeight = height * healthPercent
                            local barColor = Color3.fromHSV(0.33 * healthPercent, 1, 1)

                            esp.healthBarBack.Visible = States.ESP.Enabled
                            esp.healthBarBack.Position = Vector2.new(screenPos.X - width / 2 - 7, screenPos.Y - height / 2)
                            esp.healthBarBack.Size = Vector2.new(4, height)

                            esp.healthBarFront.Visible = States.ESP.Enabled
                            esp.healthBarFront.Color = barColor
                            esp.healthBarFront.Position = Vector2.new(screenPos.X - width / 2 - 7, screenPos.Y - height / 2 + (height - barHeight))
                            esp.healthBarFront.Size = Vector2.new(4, barHeight)
                        else
                            esp.healthBarBack.Visible = false
                            esp.healthBarFront.Visible = false
                        end

                        if States.ESP.Tracers then
                            esp.tracer.Visible = States.ESP.Enabled
                            esp.tracer.From = Vector2.new(screenPos.X, screenPos.Y + height / 2)
                            esp.tracer.To = screenCenter
                        else
                            esp.tracer.Visible = false
                        end
                    end
                end
            end
        end
        
        if not isVisible then
            esp.box.Visible = false
            esp.name.Visible = false
            esp.distance.Visible = false
            esp.healthBarBack.Visible = false
            esp.healthBarFront.Visible = false
            esp.tracer.Visible = false
        end
    end
end

-- Initialize ESP for all players
for _, player in pairs(Services.Players:GetPlayers()) do
    CreateESP(player)
end

table.insert(playerEspConnections, Services.Players.PlayerAdded:Connect(function(player)
    CreateESP(player)
end))

table.insert(playerEspConnections, Services.Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
end))

function Mega.Features.ESP.SetEnabled(state)
    States.ESP.Enabled = state
    if state then
        if not Mega.Objects.ESPRenderConnection then
            Mega.Objects.ESPRenderConnection = Services.RunService.RenderStepped:Connect(function()
                UpdateESP()
                UpdateESPColors()
            end)
        end
    else
        if Mega.Objects.ESPRenderConnection then
            Mega.Objects.ESPRenderConnection:Disconnect()
            Mega.Objects.ESPRenderConnection = nil
        end
        for player, esp in pairs(Mega.Objects.ESP) do
            esp.box.Visible = false
            esp.name.Visible = false
            esp.distance.Visible = false
            esp.healthBarBack.Visible = false
            esp.healthBarFront.Visible = false
            esp.tracer.Visible = false
        end
    end
end
--#endregion
