local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Teams = game:GetService("Teams")

-- Toggles
local espEnabled = true
local healthEnabled = false
local menuVisible = false
local teamModeEnabled = false -- Added Team Mode Toggle

local processed = {}
local queue = {}

-- GUI Setup
local gui = Instance.new("ScreenGui")
gui.Name = "UniversalESP"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
gui.Enabled = false

-- Container for dragging buttons
local container = Instance.new("Frame", gui)
container.BackgroundTransparency = 0.8
container.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
container.BorderSizePixel = 0
container.Size = UDim2.new(0, 200, 0, 180) -- Extended size
container.Position = UDim2.new(0.5, -100, 0.5, -90)
container.Active = true
container.Draggable = true

local toggleBtn = Instance.new("TextButton", container)
toggleBtn.Size = UDim2.new(0, 150, 0, 30)
toggleBtn.Position = UDim2.new(0, 25, 0, 10)
toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.Text = "ESP: ON"
toggleBtn.TextSize = 16

local refreshBtn = Instance.new("TextButton", container)
refreshBtn.Size = UDim2.new(0, 150, 0, 30)
refreshBtn.Position = UDim2.new(0, 25, 0, 50)
refreshBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
refreshBtn.Font = Enum.Font.SourceSansBold
refreshBtn.Text = "Refresh ESP"
refreshBtn.TextSize = 16

local healthBtn = Instance.new("TextButton", container)
healthBtn.Size = UDim2.new(0, 150, 0, 30)
healthBtn.Position = UDim2.new(0, 25, 0, 90)
healthBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
healthBtn.TextColor3 = Color3.new(1, 1, 1)
healthBtn.Font = Enum.Font.SourceSansBold
healthBtn.Text = "Health: OFF"
healthBtn.TextSize = 16

local teamModeBtn = Instance.new("TextButton", container)
teamModeBtn.Size = UDim2.new(0, 150, 0, 30)
teamModeBtn.Position = UDim2.new(0, 25, 0, 130) -- Changed position
teamModeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
healthBtn.TextColor3 = Color3.new(1, 1, 1)
teamModeBtn.Font = Enum.Font.SourceSansBold
teamModeBtn.Text = "Team Mode: OFF"
teamModeBtn.TextSize = 16

-- Clear ESP for a specific model
local function clearESP(model)
    if model and processed[model] then
        if model:FindFirstChild("ESP_Highlight") then
            model.ESP_Highlight:Destroy()
        end
        if model:FindFirstChild("ESP_Name") then
            model.ESP_Name:Destroy()
        end
        processed[model] = nil
    end
end

-- Add ESP
local function addESP(model, nameText, color)
    if not model or not model:IsA("Model") or processed[model] then return end

    local head = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
    local humanoid = model:FindFirstChild("Humanoid")
    if not head then return end

    -- Highlight
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = color
    highlight.Adornee = model
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = model

    -- Billboard GUI name tag
    local tag = Instance.new("BillboardGui")
    tag.Name = "ESP_Name"
    tag.Adornee = head
    tag.Size = UDim2.new(0, 120, 0, 25)
    tag.StudsOffset = Vector3.new(0, 2.5, 0)
    tag.AlwaysOnTop = true

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = color
    label.Font = Enum.Font.ArialBold
    label.TextSize = 18
    label.Text = nameText .. (healthEnabled and humanoid and (" | " .. math.floor(humanoid.Health)) or "")

    label.Parent = tag

    local function updateHealthText()
        if humanoid and healthEnabled then
            label.Text = nameText .. " | " .. math.floor(humanoid.Health)
        else
            label.Text = nameText
        end
    end

    if humanoid then
        humanoid.HealthChanged:Connect(updateHealthText)
    end

    tag.Parent = model
    processed[model] = true

    updateHealthText() -- Initial update
end

-- Get Team Color
local function getTeamColor(player)
    if teamModeEnabled and player.Team then
        return player.TeamColor.Color
    else
        return Color3.fromRGB(255, 165, 0) -- Default orange
    end
end

-- Refresh ESP
local function refreshESP()
    if not espEnabled then return end

    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end
    local myPos = myChar.HumanoidRootPart.Position

    -- Clear processed table before refreshing
    for model, _ in pairs(processed) do
        clearESP(model)
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local teamColor = getTeamColor(player)
            addESP(player.Character, player.Name, teamColor)
        end
    end

    for _, model in ipairs(workspace:GetChildren()) do
        if model:IsA("Model") and model:FindFirstChild("Humanoid") and model:FindFirstChild("HumanoidRootPart") then
            if not Players:GetPlayerFromCharacter(model) then
                local dist = (myPos - model.HumanoidRootPart.Position).Magnitude
                if dist < 500 then
                    addESP(model, model.Name, Color3.fromRGB(255, 0, 0))
                end
            end
        end
    end
end

-- Button Events
toggleBtn.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    toggleBtn.Text = espEnabled and "ESP: ON" or "ESP: OFF"
    if not espEnabled then
        for model, _ in pairs(processed) do
            clearESP(model)
        end
    else
        refreshESP()
    end
end)

refreshBtn.MouseButton1Click:Connect(refreshESP)

healthBtn.MouseButton1Click:Connect(function()
    healthEnabled = not healthEnabled
    healthBtn.Text = healthEnabled and "Health: ON" or "Health: OFF"
    refreshESP() -- Auto refresh on health toggle
end)

teamModeBtn.MouseButton1Click:Connect(function()
    teamModeEnabled = not teamModeEnabled
    teamModeBtn.Text = teamModeEnabled and "Team Mode: ON" or "Team Mode: OFF"
    refreshESP()
end)

-- Track Players
local function trackPlayer(player)
    local function handleCharacter(character)
        if not espEnabled then return end

        -- Add ESP as soon as they spawn
        local teamColor = getTeamColor(player)
        addESP(character, player.Name, teamColor)
    end

    -- Handle existing character
    if player.Character then
        if processed[player.Character] then
            clearESP(player.Character)
        end
        if espEnabled then
            handleCharacter(player.Character)
        end
    end

    -- Handle character added event
    player.CharacterAdded:Connect(function(character)
        -- Wait for humanoid and root part to exist before adding ESP
        character:WaitForChild("Humanoid", 5)
        character:WaitForChild("HumanoidRootPart", 5)

        if espEnabled then
            handleCharacter(character)
        end
    end)

    -- Remove ESP on death
    if player.Character then
        player.Character.Humanoid.Died:Connect(function()
            clearESP(player.Character)
        end)
    end

    -- Handle character removing event
    player.CharacterRemoving:Connect(clearESP)
end

-- Iterate through existing players
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        trackPlayer(player)
    end
end

-- Handle new players joining.

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        trackPlayer(player)
    end
end)

-- Menu Toggle
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if input.KeyCode == Enum.KeyCode.RightShift then
        menuVisible = not menuVisible
        gui.Enabled = menuVisible
    end
end)

-- Ensure no leftover ESP after toggle off
RunService.Heartbeat:Connect(function()
    if not espEnabled then
        for model, _ in pairs(processed) do
            clearESP(model)
        end
    end
end)

-- Initial ESP
refreshESP()
