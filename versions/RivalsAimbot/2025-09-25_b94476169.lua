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
guiFrame.Size = UDim2.new(0, 220, 0, 400) -- Increased height to accommodate new GUI elements
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
fovLabel.Text = "FOV: 90 (Press [Z] / [X] to change)"
fovLabel.BorderSizePixel = 0
fovLabel.Parent = guiFrame

-- // Smoothing Label
local smoothingLabel = Instance.new("TextLabel")
smoothingLabel.Size = UDim2.new(0, 200, 0, 20)
smoothingLabel.Position = UDim2.new(0.5, -100, 0, 80)
smoothingLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
smoothingLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
smoothingLabel.Text = "Smoothing: 0.1 (Press [C] / [V] to change)"
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
playerListFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Initialized CanvasSize
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
local fov = 90
local smoothingFactor = 0.1
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
        fov = math.max(1, fov - 5)
        fovLabel.Text = "FOV: "..fov.." (Press [Z] / [X] to change)"
    elseif input.KeyCode == Enum.KeyCode.X then
        fov = math.min(180, fov + 5)
        fovLabel.Text = "FOV: "..fov.." (Press [Z] / [X] to change)"
    elseif input.KeyCode == Enum.KeyCode.C then
        smoothingFactor = math.max(0.01, smoothingFactor - 0.01)
        smoothingLabel.Text = "Smoothing: "..string.format("%.2f", smoothingFactor).." (Press [C] / [V] to change)"
    elseif input.KeyCode == Enum.KeyCode.V then
        smoothingFactor = math.min(1, smoothingFactor + 0.01)
        smoothingLabel.Text = "Smoothing: "..string.format("%.2f", smoothingFactor).." (Press [C] / [V] to change)"
    elseif input.KeyCode == Enum.KeyCode.H then
        -- Toggle GUI visibility using the "H" key
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

local function hasLineOfSight(player)
    local localPlayer = Players.LocalPlayer
    if not (localPlayer.Character and player.Character) then return false end
    local headPosition = player.Character.Head.Position
    local rootPartPosition = localPlayer.Character.HumanoidRootPart.Position
    local ray = Ray.new(rootPartPosition, (headPosition - rootPartPosition).Unit * 500)
    local hit = workspace:FindPartOnRay(ray, localPlayer.Character)
    return hit and hit:IsDescendantOf(player.Character)
end

-- // Nearest target finder
local function getNearestPlayer()
    local localPlayer = Players.LocalPlayer
    local nearestPlayer, shortestDistance = nil, math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and
           player.Character and
           player.Character:FindFirstChild("HumanoidRootPart") and
           isPlayerVisible(player) and -- Add visibility check
           hasLineOfSight(player) and -- Add line of sight check
           not blacklist[player.Name] then -- Blacklist Check

            local distance = (localPlayer.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude

            if distance < shortestDistance then
                shortestDistance = distance
                nearestPlayer = player
            end
        end
    end

    return nearestPlayer
end

-- // Aim at target
local function moveMouseToPlayer(player)
    if player and player.Character and player.Character:FindFirstChild("Head") then
        local screenPos = Camera:WorldToViewportPoint(player.Character.Head.Position)
        local mousePos = UserInputService:GetMouseLocation()
        local delta = Vector2.new(screenPos.X, screenPos.Y) - mousePos
        if delta.Magnitude > 1 then
            mousemoverel(delta.X * smoothingFactor, delta.Y * smoothingFactor)
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
            button.BackgroundColor3 = blacklist[player.Name] and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(50, 200, 50)
            button.Parent = playerListFrame

            button.MouseButton1Click:Connect(function()
                blacklist[player.Name] = not blacklist[player.Name]
                button.BackgroundColor3 = blacklist[player.Name] and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(50, 200, 50)
            end)
        end
    end

    -- Update canvas size
    playerListFrame.CanvasSize = UDim2.new(0, 0, 0, #playerListFrame:GetChildren() * 26)
end

-- // Main loop
RunService.RenderStepped:Connect(function()
    if aimbotEnabled then
        local target = getNearestPlayer()
        if target then
            moveMouseToPlayer(target)
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
    task.wait(1)
    populatePlayerList()
end)
