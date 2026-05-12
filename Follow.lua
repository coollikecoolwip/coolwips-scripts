--// SERVICES
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

--// STATE VARIABLES
local state = {
    following = false,
    selectedPlayer = nil,
    mimicConnection = nil,
    followDistance = 5,
    speedMode = false,
    defaultWalkSpeed = 16, -- Default walkspeed to restore
    guiVisible = true -- For GUI toggle
}

--// GUI HELPERS
local function applyCorner(obj, radius)
    local corner = Instance.new("UICorner", obj)
    corner.CornerRadius = UDim.new(0, radius)
end

local function applyStroke(obj, thickness, color)
    local stroke = Instance.new("UIStroke", obj)
    stroke.Thickness = thickness
    stroke.Color = color or Color3.fromRGB(80, 80, 80) -- Default subtle grey
end

--// GUI ROOT
local gui = Instance.new("ScreenGui")
gui.Name = "FollowProGUI"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

--// MAIN FRAME
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 260, 0, 520)
frame.Position = UDim2.new(0, 20, 0.5, -260)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
applyCorner(frame, 12)
applyStroke(frame, 1, Color3.fromRGB(60, 60, 60))
frame.Active = true
frame.Draggable = true

--// TITLE
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 45)
title.Text = "FOLLOW SYSTEM"
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.BackgroundTransparency = 1

--// DISTANCE BOX
local distanceBox = Instance.new("TextBox", frame)
distanceBox.Size = UDim2.new(0.9, 0, 0, 32)
distanceBox.Position = UDim2.new(0.05, 0, 0, 55)
distanceBox.PlaceholderText = "Follow Distance"
distanceBox.Text = tostring(state.followDistance)
distanceBox.Font = Enum.Font.Gotham
distanceBox.TextSize = 14
distanceBox.TextColor3 = Color3.fromRGB(255, 255, 255)
distanceBox.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
distanceBox.BorderSizePixel = 0
applyCorner(distanceBox, 8)
applyStroke(distanceBox, 1)

--// SPEED MODE BUTTON
local speedBtn = Instance.new("TextButton", frame)
speedBtn.Size = UDim2.new(0.9, 0, 0, 32)
speedBtn.Position = UDim2.new(0.05, 0, 0, 95)
speedBtn.Text = "Speed Mode: OFF"
speedBtn.Font = Enum.Font.GothamBold
speedBtn.TextSize = 14
speedBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
speedBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
speedBtn.BorderSizePixel = 0
applyCorner(speedBtn, 8)
applyStroke(speedBtn, 1)

speedBtn.MouseButton1Click:Connect(function()
    state.speedMode = not state.speedMode
    speedBtn.Text = "Speed Mode: " .. (state.speedMode and "ON" or "OFF")
    speedBtn.BackgroundColor3 = state.speedMode
        and Color3.fromRGB(0, 170, 120) -- Green for ON
        or Color3.fromRGB(70, 70, 70) -- Grey for OFF
end)

--// START / STOP BUTTON
local toggleBtn = Instance.new("TextButton", frame)
toggleBtn.Size = UDim2.new(0.9, 0, 0, 36)
toggleBtn.Position = UDim2.new(0.05, 0, 0, 135)
toggleBtn.Text = "START FOLLOW"
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 15
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 75) -- Green for START
toggleBtn.BorderSizePixel = 0
applyCorner(toggleBtn, 10)

--// PLAYER LIST FRAME
local listFrame = Instance.new("ScrollingFrame", frame)
listFrame.Position = UDim2.new(0, 10, 0, 185)
listFrame.Size = UDim2.new(1, -20, 1, -195) -- Takes up remaining space
listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
listFrame.ScrollBarThickness = 6
listFrame.BackgroundTransparency = 1

--// UIListLayout for automatic player list arrangement
local layout = Instance.new("UIListLayout", listFrame)
layout.Padding = UDim.new(0, 8) -- Spacing between player buttons
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Top

-- Update CanvasSize automatically based on content
-- This connection ensures the scrollbar is always up-to-date.
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    listFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10) -- Add a little padding at the bottom
end)

--// REFRESH BUTTON
local refreshBtn = Instance.new("TextButton", frame)
refreshBtn.Size = UDim2.new(0.9, 0, 0, 30)
refreshBtn.Position = UDim2.new(0.05, 0, 0, 170) -- Position above the player list
refreshBtn.Text = "Refresh Players"
refreshBtn.BackgroundColor3 = Color3.fromRGB(120, 120, 220) -- Accent color for refresh
refreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
refreshBtn.Font = Enum.Font.GothamBold
refreshBtn.TextSize = 13
refreshBtn.BorderSizePixel = 0
applyCorner(refreshBtn, 8)
applyStroke(refreshBtn, 1)

--// FUNCTIONS

local function stopMimic()
    state.following = false
    if state.mimicConnection then
        state.mimicConnection:Disconnect()
        state.mimicConnection = nil
    end
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
    if hum then
        hum.WalkSpeed = state.defaultWalkSpeed -- Restore default walkspeed
        hum:Move(Vector3.zero) -- Stop movement
    end
    toggleBtn.Text = "START FOLLOW"
    toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 75) -- Green for START
end

local function startMimic(target)
    if not target or not target.Character then return end
    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
    if not humanoid then return end

    state.defaultWalkSpeed = humanoid.WalkSpeed -- Store the player's current walkspeed

    state.mimicConnection = RunService.RenderStepped:Connect(function()
        if not state.following or not target.Character or not LocalPlayer.Character then return end

        local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")

        if myRoot and targetRoot then
            local offsetVec = (targetRoot.Position - myRoot.Position)
            local dist = offsetVec.Magnitude

            if dist > state.followDistance then
                local speedBoost = state.speedMode and math.clamp(math.floor(dist / 5), 0, 100) or 0
                humanoid.WalkSpeed = state.defaultWalkSpeed + speedBoost -- Apply speed boost
                humanoid:Move(offsetVec.Unit, false)
            else
                humanoid:Move(Vector3.zero) -- Stop moving if close enough
            end
        end
    end)

    toggleBtn.Text = "STOP FOLLOW"
    toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60) -- Red for STOP
end

local function teleportToPlayer(player)
    if player and player.Character then
        local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if targetRoot and myRoot then
            myRoot.CFrame = targetRoot.CFrame + Vector3.new(0, 3, 0) -- Teleport slightly above target
        end
    end
end

-- THIS IS THE KEY FUNCTION FOR POPULATING THE PLAYER LIST
local function createButtons()
    -- Clear all existing buttons from the listFrame to prevent duplicates
    for _, child in ipairs(listFrame:GetChildren()) do
        if child:IsA("Frame") then -- Assuming player entries are within Frames
            child:Destroy()
        end
    end

    -- Get all players in the game
    local allPlayers = Players:GetPlayers()
    local playerList = {} -- Temporary table to hold players other than LocalPlayer

    -- Filter out the LocalPlayer
    for _, player in ipairs(allPlayers) do
        if player ~= LocalPlayer then
            table.insert(playerList, player)
        end
    end

    -- Sort players alphabetically by name (optional, but good for consistent order)
    table.sort(playerList, function(a, b)
        return a.Name < b.Name
    end)

    -- Now, create buttons for each player in the filtered and sorted list
    for _, player in ipairs(playerList) do
        local playerFrame = Instance.new("Frame", listFrame)
        playerFrame.Size = UDim2.new(0.95, 0, 0, 42) -- Use relative size for frame
        playerFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40) -- Slightly darker than main frame
        applyCorner(playerFrame, 8)
        applyStroke(playerFrame, 1)

        -- Follow Button
        local followBtn = Instance.new("TextButton", playerFrame)
        followBtn.Size = UDim2.new(0.6, -6, 1, -6) -- Relative size with padding
        followBtn.Position = UDim2.new(0, 3, 0, 3)
        followBtn.Text = player.Name
        followBtn.Font = Enum.Font.GothamBold
        followBtn.TextSize = 14
        followBtn.TextColor3 = Color3.new(1,1,1)
        followBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 255) -- Blue for follow
        followBtn.BorderSizePixel = 0
        applyCorner(followBtn, 6)

        followBtn.MouseButton1Click:Connect(function()
            local val = tonumber(distanceBox.Text)
            if val and val >= 2 and val <= 50 then -- Clamp distance between 2 and 50
                state.followDistance = val
            else
                distanceBox.Text = tostring(state.followDistance) -- Reset to current valid distance if invalid
            end

            stopMimic()
            state.selectedPlayer = player
            state.following = true
            startMimic(player)
        end)

        -- Goto Button
        local gotoBtn = Instance.new("TextButton", playerFrame)
        gotoBtn.Size = UDim2.new(0.35, -6, 1, -6) -- Relative size with padding
        gotoBtn.Position = UDim2.new(0.62, 3, 0, 3)
        gotoBtn.Text = "GOTO"
        gotoBtn.Font = Enum.Font.GothamBold
        gotoBtn.TextSize = 14
        gotoBtn.TextColor3 = Color3.new(1,1,1)
        gotoBtn.BackgroundColor3 = Color3.fromRGB(120, 120, 255) -- Purple accent
        gotoBtn.BorderSizePixel = 0
        applyCorner(gotoBtn, 6)

        gotoBtn.MouseButton1Click:Connect(function()
            teleportToPlayer(player)
        end)
    end
    -- The UIListLayout handles the actual positioning and spacing.
    -- The CanvasSize update is connected to the layout's AbsoluteContentSize.
end

--// EVENT CONNECTIONS
toggleBtn.MouseButton1Click:Connect(function()
    if state.following then
        stopMimic()
    elseif state.selectedPlayer then
        -- Update follow distance from textbox, with validation
        local val = tonumber(distanceBox.Text)
        if val and val >= 2 and val <= 50 then
            state.followDistance = val
        else
            distanceBox.Text = tostring(state.followDistance) -- Reset if invalid
        end

        state.following = true
        startMimic(state.selectedPlayer)
    end
end)

-- Call createButtons initially to populate the list when the script runs
createButtons()

-- Refresh the player list when players join or leave
Players.PlayerAdded:Connect(function(player)
    task.wait(1) -- Allow a brief moment for the player's character to load
    createButtons()
end)

Players.PlayerRemoving:Connect(function(player)
    -- If the player being removed is the selected one, stop following
    if state.selectedPlayer == player then
        stopMimic()
    end
    createButtons() -- Refresh list after player leaves
end)

-- Connect the refresh button to the createButtons function
refreshBtn.MouseButton1Click:Connect(function()
    createButtons()
end)

--// GUI TOGGLE
local toggleFrame = Instance.new("Frame", gui)
toggleFrame.Size = UDim2.new(0, 100, 0, 40)
toggleFrame.Position = UDim2.new(0, 10, 0, 10)
toggleFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
applyCorner(toggleFrame, 10)
applyStroke(toggleFrame, 1)
toggleFrame.Active = true
toggleFrame.Draggable = true

local toggleGuiBtn = Instance.new("TextButton", toggleFrame)
toggleGuiBtn.Size = UDim2.new(1, 0, 1, 0)
toggleGuiBtn.Position = UDim2.new(0, 0, 0, 0)
toggleGuiBtn.Text = "Toggle GUI"
toggleGuiBtn.BackgroundTransparency = 1
toggleGuiBtn.TextColor3 = Color3.new(1, 1, 1)
toggleGuiBtn.Font = Enum.Font.GothamBold
toggleGuiBtn.TextSize = 14
toggleGuiBtn.BorderSizePixel = 0

toggleGuiBtn.MouseButton1Click:Connect(function()
    state.guiVisible = not state.guiVisible
    frame.Visible = state.guiVisible
end)

-- Ensure the main frame is visible initially
frame.Visible = state.guiVisible
