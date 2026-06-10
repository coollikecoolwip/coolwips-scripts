-- // Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera

-- // GUI Creation
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AimbotGui"
screenGui.Parent = CoreGui
screenGui.ResetOnSpawn = false

local guiFrame = Instance.new("Frame")
guiFrame.Size = UDim2.new(0, 220, 0, 400) -- Increased height to accommodate new GUI elements [T0](1)
guiFrame.Position = UDim2.new(0, 10, 0, 10)
guiFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
guiFrame.BorderSizePixel = 0
guiFrame.Active = true
guiFrame.Draggable = true
guiFrame.Parent = screenGui

-- // Toggle Button
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 200, 0, 30)
toggleButton.Position = UDim2.new(0.5, -100, 0, 10)
toggleButton.Text = "Aimbot Disabled"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
toggleButton.BorderSizePixel = 0
toggleButton.Parent = guiFrame

-- // FOV Label
local fovLabel = Instance.new("TextLabel")
fovLabel.Size = UDim2.new(0, 200, 0, 20)
fovLabel.Position = UDim2.new(0.5, -100, 0, 50)
fovLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
fovLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
fovLabel.Text = "FOV: 300 (Press [Z] / [X] to change)" -- Default FOV set to 300 [AI KNOWLEDGE]({})
fovLabel.BorderSizePixel = 0
fovLabel.Parent = guiFrame

-- // Smoothing Label
local smoothingLabel = Instance.new("TextLabel")
smoothingLabel.Size = UDim2.new(0, 200, 0, 20)
smoothingLabel.Position = UDim2.new(0.5, -100, 0, 80)
smoothingLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
smoothingLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
smoothingLabel.Text = "Smoothing: 0.1 (Press [C] / [V] to change)" -- Default Smoothing set to 0.1 [T1](2)
smoothingLabel.BorderSizePixel = 0
smoothingLabel.Parent = guiFrame

-- // Blacklist Player List Label
local blacklistPlayerListLabel = Instance.new("TextLabel")
blacklistPlayerListLabel.Size = UDim2.new(0, 200, 0, 20)
blacklistPlayerListLabel.Position = UDim2.new(0.5, -100, 0, 110)
blacklistPlayerListLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
blacklistPlayerListLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
blacklistPlayerListLabel.Text = "Select Players to Blacklist:"
blacklistPlayerListLabel.BorderSizePixel = 0
blacklistPlayerListLabel.Parent = guiFrame

-- // Scrolling Frame for Player List
local playerListFrame = Instance.new("ScrollingFrame")
playerListFrame.Size = UDim2.new(0, 200, 0, 150)
playerListFrame.Position = UDim2.new(0.5, -100, 0, 140)
playerListFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
playerListFrame.BorderSizePixel = 0
playerListFrame.ScrollBarThickness = 12
playerListFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Initialized CanvasSize [T2](3)
playerListFrame.Parent = guiFrame

-- // UIListLayout for Player List
local playerListLayout = Instance.new("UIListLayout")
playerListLayout.SortOrder = Enum.SortOrder.Name
playerListLayout.Padding = UDim.new(0, 2)
playerListLayout.Parent = playerListFrame

-- // Refresh Button
local refreshButton = Instance.new("TextButton")
refreshButton.Size = UDim2.new(0, 75, 0, 30)
refreshButton.Position = UDim2.new(0.5, 0, 0, 300)
refreshButton.Text = "Refresh"
refreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
refreshButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
refreshButton.BorderSizePixel = 0
refreshButton.Parent = guiFrame

-- // GUI Toggle Button
local guiToggleButton = Instance.new("TextButton")
guiToggleButton.Size = UDim2.new(0, 75, 0, 30)
guiToggleButton.Position = UDim2.new(0.5, -75, 0, 300)
guiToggleButton.Text = "Hide GUI"
guiToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
guiToggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
guiToggleButton.BorderSizePixel = 0
guiToggleButton.Parent = guiFrame

-- // Settings
local aimbotEnabled = false
local fov = 300 -- Default FOV set to 300 [AI KNOWLEDGE]({})
local smoothingFactor = 0.1 -- Default Smoothing [T1](2)
local minimumEngagementDistance = 5
local blacklist = {}
local guiVisible = true  -- Start with GUI visible

-- // Toggle function
local function toggleAimbot()
    aimbotEnabled = not aimbotEnabled
    toggleButton.Text = aimbotEnabled and "Aimbot Enabled" or "Aimbot Disabled"
end
toggleButton.MouseButton1Click:Connect(toggleAimbot)

-- // Keybinds for settings
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.Q then
        toggleAimbot()
    elseif input.KeyCode == Enum.KeyCode.Z then
        -- Change FOV increment to 10 [AI KNOWLEDGE]({})
        fov = math.max(150, fov - 10)
        fovLabel.Text = "FOV: "..fov.." (Press [Z] / [X] to change)"
    elseif input.KeyCode == Enum.KeyCode.X then
        -- Change FOV increment to 10 [AI KNOWLEDGE]({})
        fov = math.min(700, fov + 10)
        fovLabel.Text = "FOV: "..fov.." (Press [Z] / [X] to change)"
    elseif input.KeyCode == Enum.KeyCode.C then
        smoothingFactor = math.max(0.01, smoothingFactor - 0.01)
        smoothingLabel.Text = "Smoothing: "..string.format("%.2f", smoothingFactor).." (Press [C] / [V] to change)"
    elseif input.KeyCode == Enum.KeyCode.V then
        smoothingFactor = math.min(1, smoothingFactor + 0.01)
        smoothingLabel.Text = "Smoothing: "..string.format("%.2f", smoothingFactor).." (Press [C] / [V] to change)"
    elseif input.KeyCode == Enum.KeyCode.H then
        -- Toggle GUI visibility using the "H" key [T3](4)
        guiVisible = not guiVisible
        guiFrame.Visible = guiVisible
        guiToggleButton.Text = guiVisible and "Hide GUI" or "Show GUI"
    end
end)

-- // Visibility check
local function isPlayerVisible(player)
    if player and player.Character and player.Character:FindFirstChild("Head") then
        local screenPos = Camera:WorldToViewportPoint(player.Character.Head.Position)
        return screenPos.Z > 0
    end
    return false
end

-- // Line of sight check
local function hasLineOfSight(player)
    local localPlayer = Players.LocalPlayer
    if not (localPlayer.Character and player.Character) then return false end
    local headPosition = player.Character.Head.Position
    local rootPartPosition = localPlayer.Character.HumanoidRootPart.Position
    local ray = Ray.new(rootPartPosition, (headPosition - rootPartPosition).Unit * 500)
    local hit = workspace:FindPartOnRay(ray, localPlayer.Character) -- Ensure raycast doesn't hit player's own character [T4](5)
    return hit and hit:IsDescendantOf(player.Character) -- Checks if the ray hit the target player's character [T4](5)
end

-- // Nearest target finder
local function getNearestPlayer()
    local localPlayer = Players.LocalPlayer
    local nearestPlayer, shortestDistance = nil, math.huge

    -- Ensure camera and local player character are valid before proceeding [AI KNOWLEDGE]({})
    if not Camera or not localPlayer.Character then return nil end

    for _, player in ipairs(Players:GetPlayers()) do
        -- Skip self, blacklisted players, and ensure player character is valid and alive [T5](6)
        if player ~= localPlayer and
           player.Character and
           player.Character:FindFirstChild("HumanoidRootPart") and
           player.Character:FindFirstChild("Humanoid") and -- Ensure Humanoid exists [T5](6)
           player.Character.Humanoid.Health > 0 and -- Add health check [T5](6)
           isPlayerVisible(player) and
           hasLineOfSight(player) and
           not blacklist[player.Name] then

            local distance = (localPlayer.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude -- Calculate distance [T5](6)

            -- Check if target is within FOV circle and closer than current nearest [AI KNOWLEDGE]({})
            local screenPos = Camera:WorldToViewportPoint(player.Character.Head.Position)
            local mousePos = UserInputService:GetMouseLocation()
            local delta = Vector2.new(screenPos.X, screenPos.Y) - mousePos

            if delta.Magnitude <= fov and distance >= minimumEngagementDistance then -- Check FOV and minimum engagement distance [T5](6)
                if distance < shortestDistance then
                    shortestDistance = distance
                    nearestPlayer = player
                end
            end
        end
    end
    return nearestPlayer
end

-- // Aim at target (mouse movement)
local function moveMouseToPlayer(player)
    if player and player.Character and player.Character:FindFirstChild("Head") then
        local screenPos = Camera:WorldToViewportPoint(player.Character.Head.Position)
        local mousePos = UserInputService:GetMouseLocation()
        local delta = Vector2.new(screenPos.X, screenPos.Y) - mousePos

        -- Apply smoothing to the mouse movement for a less jerky aim [T5](6) [AI KNOWLEDGE]({})
        if delta.Magnitude > 1 then -- Only move if the delta is significant enough
            mousemoverel(delta.X * smoothingFactor, delta.Y * smoothingFactor) -- This line correctly moves the mouse [T5](6) [AI KNOWLEDGE]({})
        end
    end
end

-- // Function to populate player list
local function populatePlayerList()
    -- Clear existing buttons
    for _, obj in ipairs(playerListFrame:GetChildren()) do
        if obj:IsA("TextButton") then
            obj:Destroy()
        end
    end

    -- Create buttons for each player
    local players = Players:GetPlayers()
    table.sort(players, function(a, b)
        return a.Name < b.Name
    end)

    for _, player in ipairs(players) do
        if player ~= Players.LocalPlayer then
            local button = Instance.new("TextButton")
            button.Size = UDim2.new(1, 0, 0, 24)
            button.Text = player.Name
            button.TextColor3 = Color3.new(1, 1, 1)
            -- Set button color based on blacklist status [T6](7)
            button.BackgroundColor3 = blacklist[player.Name] and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(50, 200, 50)
            button.Parent = playerListFrame

            button.MouseButton1Click:Connect(function()
                blacklist[player.Name] = not blacklist[player.Name]
                button.BackgroundColor3 = blacklist[player.Name] and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(50, 200, 50)
            end)
        end
    end

    -- Update canvas size for scrolling [T6](7)
    playerListFrame.CanvasSize = UDim2.new(0, 0, 0, #playerListFrame:GetChildren() * 26)
end

-- // FOV Circle (visual feedback) - Initialized ONCE
local circle = Drawing.new("Circle")
circle.Color = Color3.new(1,1,1)
circle.Thickness = 1
circle.Filled = false

-- // Main loop
RunService.RenderStepped:Connect(function()
    -- Update circle properties to match current settings
    circle.Position = UserInputService:GetMouseLocation()
    circle.Radius = fov
    circle.Visible = aimbotEnabled

    if aimbotEnabled then
        local target = getNearestPlayer()
        if target then
            moveMouseToPlayer(target) -- Call the function to move the mouse
        end
    end
end)

-- // Refresh Button Functionality
refreshButton.MouseButton1Click:Connect(populatePlayerList)

-- // GUI Toggle Button Functionality
guiToggleButton.MouseButton1Click:Connect(function()
    guiVisible = not guiVisible
    guiFrame.Visible = guiVisible
    guiToggleButton.Text = guiVisible and "Hide GUI" or "Show GUI"
end)

-- // Initial population of player list
populatePlayerList()

-- // Ensure Player List Updates on Player Join
Players.PlayerAdded:Connect(function()
    task.wait(1) -- Small delay to ensure player object is fully created [T7](8)
    populatePlayerList()
end)

-- // Update player list when a player leaves
Players.PlayerRemoving:Connect(populatePlayerList)
