-- gui/tabs/users.lua
-- Content for the "PLAYERS" tab

local tabKey = "tab_users"
local UI = Mega.UI
local Services = Mega.Services

-- Create the container frame for this tab
local TabFrame = Instance.new("ScrollingFrame")
TabFrame.Name = tabKey
TabFrame.Size = UDim2.new(1, 0, 1, 0)
TabFrame.BackgroundTransparency = 1
TabFrame.BorderSizePixel = 0
TabFrame.ScrollBarThickness = 4
TabFrame.ScrollBarImageColor3 = Mega.Settings.Menu.AccentColor
TabFrame.Visible = false
TabFrame.Parent = Mega.Objects.ContentContainer

local ContentLayout = Instance.new("UIListLayout", TabFrame)
ContentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Padding = UDim.new(0, 8)

Mega.Objects.TabFrames[tabKey] = TabFrame

--#region -- Player List
UI.CreateSection(TabFrame, "section_player_list")

local PlayerListFrame = Instance.new("ScrollingFrame")
PlayerListFrame.Size = UDim2.new(0.95, 0, 0, 400)
PlayerListFrame.BackgroundColor3 = Mega.Settings.Menu.BackgroundColor
PlayerListFrame.BackgroundTransparency = 0.5
PlayerListFrame.BorderSizePixel = 0
PlayerListFrame.ScrollBarThickness = 6
PlayerListFrame.Parent = TabFrame
local PlayerListLayout = Instance.new("UIListLayout", PlayerListFrame)
PlayerListLayout.Padding = UDim.new(0, 5)

local function updatePlayerList()
    if not TabFrame.Visible then return end

    local existingPlayers = {}
    for _, item in ipairs(PlayerListFrame:GetChildren()) do
        if item:IsA("Frame") then existingPlayers[item.Name] = true end
    end

    for _, player in ipairs(Services.Players:GetPlayers()) do
        existingPlayers[player.Name] = false -- Mark as seen
        
        local playerFrame = PlayerListFrame:FindFirstChild(player.Name)
        if not playerFrame then
            playerFrame = Instance.new("Frame", PlayerListFrame)
            playerFrame.Name = player.Name
            playerFrame.Size = UDim2.new(1, 0, 0, 40)
            playerFrame.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
            Instance.new("UICorner", playerFrame).CornerRadius = UDim.new(0, 6)

            local layout = Instance.new("UIListLayout", playerFrame)
            layout.FillDirection = Enum.FillDirection.Horizontal
            layout.Padding = UDim.new(0, 10)
            layout.VerticalAlignment = Enum.VerticalAlignment.Center

            local nameLabel = Instance.new("TextLabel", playerFrame)
            nameLabel.Size = UDim2.new(0.3, 0, 1, 0)
            nameLabel.Text = player.Name
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextColor3 = Color3.new(1,1,1)
            nameLabel.BackgroundTransparency = 1
            
            local hpLabel = Instance.new("TextLabel", playerFrame)
            hpLabel.Name = "HP"
            hpLabel.Size = UDim2.new(0.2, 0, 1, 0)
            hpLabel.Font = Enum.Font.Gotham
            hpLabel.TextColor3 = Color3.new(1,1,1)
            hpLabel.BackgroundTransparency = 1

            local distLabel = Instance.new("TextLabel", playerFrame)
            distLabel.Name = "Dist"
            distLabel.Size = UDim2.new(0.2, 0, 1, 0)
            distLabel.Font = Enum.Font.Gotham
            distLabel.TextColor3 = Color3.new(1,1,1)
            distLabel.BackgroundTransparency = 1
            
            local followButton = Instance.new("TextButton", playerFrame)
            followButton.Size = UDim2.new(0.2, 0, 0, 30)
            followButton.Text = "Follow"
            followButton.BackgroundColor3 = Mega.Settings.Menu.AccentColor
            Instance.new("UICorner", followButton).CornerRadius = UDim.new(0, 4)
            followButton.MouseButton1Click:Connect(function()
                Mega.States.Player.FollowTarget = player
            end)
        end
        
        -- Update existing labels
        local char = player.Character
        local localChar = Services.LocalPlayer.Character
        if char and char.PrimaryPart and localChar and localChar.PrimaryPart then
            playerFrame.HP.Text = string.format("HP: %.0f", char.Humanoid.Health)
            playerFrame.Dist.Text = string.format("%.1fm", (char.PrimaryPart.Position - localChar.PrimaryPart.Position).Magnitude)
        else
            playerFrame.HP.Text = "HP: N/A"
            playerFrame.Dist.Text = "Dist: N/A"
        end
    end

    -- Remove players who have left
    for name, stillExists in pairs(existingPlayers) do
        if stillExists then
            local frame = PlayerListFrame:FindFirstChild(name)
            if frame then frame:Destroy() end
        end
    end
end

-- Update list every 2 seconds when visible
Services.RunService.Heartbeat:Connect(function(step)
    -- Use a simple timer to avoid running every frame
    if not TabFrame.Visible then return end
    local timer = (timer or 0) + step
    if timer >= 2 then
        timer = 0
        updatePlayerList()
    end
end)
--#endregion

