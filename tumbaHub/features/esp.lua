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
-- NOTE: This is a standard implementation of Player ESP logic, as the original was not fully provided.
local function createESPDrawings(player)
    local character = player.Character
    if not character or not character.PrimaryPart then return end

    local drawing = {}
    drawing.Container = Instance.new("BillboardGui", espFolder)
    drawing.Container.Adornee = character.PrimaryPart
    drawing.Container.AlwaysOnTop = true
    drawing.Container.Size = UDim2.fromOffset(200, 200)
    drawing.Container.StudsOffset = Vector3.new(0, 2, 0)
    
    drawing.Box = Instance.new("Frame", drawing.Container)
    drawing.Box.Size = UDim2.fromScale(1,1)
    drawing.Box.BackgroundTransparency = 1
    drawing.Box.BorderColor3 = States.ESP.EnemyColor
    drawing.Box.BorderSizePixel = 2
    
    drawing.NameLabel = Instance.new("TextLabel", drawing.Container)
    drawing.NameLabel.Position = UDim2.fromScale(0.5, -0.2)
    drawing.NameLabel.Size = UDim2.fromScale(1, 0.2)
    drawing.NameLabel.BackgroundTransparency = 1
    drawing.NameLabel.Text = player.Name
    drawing.NameLabel.TextColor3 = Color3.new(1,1,1)
    drawing.NameLabel.Font = Enum.Font.SourceSans
    drawing.NameLabel.TextSize = 16
    drawing.NameLabel.TextStrokeTransparency = 0
    
    drawing.DistanceLabel = Instance.new("TextLabel", drawing.Container)
    drawing.DistanceLabel.Position = UDim2.fromScale(0.5, 1.1)
    drawing.DistanceLabel.Size = UDim2.fromScale(1, 0.2)
    drawing.DistanceLabel.BackgroundTransparency = 1
    drawing.DistanceLabel.TextColor3 = Color3.new(1,1,1)
    drawing.DistanceLabel.Font = Enum.Font.SourceSans
    drawing.DistanceLabel.TextSize = 14
    
    -- Add more drawings like Health, Tracers etc. here

    return drawing
end

local function updateESP()
    espFolder.Enabled = States.ESP.Enabled
    if not States.ESP.Enabled then return end
    
    for _, player in ipairs(Services.Players:GetPlayers()) do
        if player == Services.LocalPlayer then continue end
        
        local esp = player:FindFirstChild("TumbaESP")
        if not esp then
            esp = Instance.new("Folder", player)
            esp.Name = "TumbaESP"
        end

        local drawing = esp:FindFirstChild("Drawing")
        if not player.Character or not player.Character.PrimaryPart or player.Character.Humanoid.Health <= 0 then
            if drawing then drawing:Destroy() end
            continue
        end

        if not drawing then
            drawing = createESPDrawings(player)
            drawing.Container.Name = "Drawing"
            drawing.Container.Parent = esp
        end
        
        local distance = (Services.LocalPlayer.Character.PrimaryPart.Position - player.Character.PrimaryPart.Position).Magnitude
        if distance > States.ESP.MaxDistance then
            drawing.Container.Visible = false
            continue
        end
        drawing.Container.Visible = true
        
        -- Update visibility based on settings
        drawing.Box.Visible = States.ESP.Boxes
        drawing.NameLabel.Visible = States.ESP.Names
        drawing.DistanceLabel.Visible = States.ESP.Distance
        
        -- Update values
        drawing.DistanceLabel.Text = string.format("%.1fm", distance)
        -- Update colors, health bars etc.
    end
end

function Mega.Features.ESP.SetEnabled(state)
    States.ESP.Enabled = state
    if state then
        table.insert(playerEspConnections, Services.RunService.RenderStepped:Connect(updateESP))
    else
        for _, conn in ipairs(playerEspConnections) do conn:Disconnect() end
        table.clear(playerEspConnections)
        espFolder:ClearAllChildren()
    end
end
--#endregion

