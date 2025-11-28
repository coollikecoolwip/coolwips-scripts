local refreshInterval = 5
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Toggles
local espEnabled = true
local healthEnabled = false
local menuVisible = false
local teamModeEnabled = false

local espData = {} -- Stores ESP info
local targetDistance = 1000 -- ESP target distance

-- GUI Setup
local gui = Instance.new("ScreenGui")
gui.Name = "UniversalESP"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
gui.Enabled = false

-- Container
local container = Instance.new("Frame", gui)
container.BackgroundTransparency = 0.8
container.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
container.BorderSizePixel = 0
container.Size = UDim2.new(0, 200, 0, 180)
container.Position = UDim2.new(0.5, -100, 0.5, -90)
container.Active = true
container.Draggable = true

local function newButton(parent, y, text)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(0, 150, 0, 30)
    btn.Position = UDim2.new(0, 25, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 16
    btn.Text = text
    return btn
end

local toggleBtn = newButton(container, 10, "ESP: ON")
local refreshBtn = newButton(container, 50, "Refresh ESP")
local healthBtn = newButton(container, 90, "Health: OFF")
local teamModeBtn = newButton(container, 130, "Team Mode: OFF")

-- Clear ESP
local function clearESP(model)
    if espData[model] then
        if espData[model].highlight then
            espData[model].highlight:Destroy()
        end
        if espData[model].tag then
            espData[model].tag:Destroy()
        end
        espData[model] = nil
    end
end

-- Add ESP
local function addESP(model, nameText, color)
    if not model or not model:IsA("Model") then return end
    local head = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
    local humanoid = model:FindFirstChild("Humanoid")

    if not head then return end

    -- Create Highlight
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = color
    highlight.Adornee = model
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = model

    -- Create BillboardGui
    local tag = Instance.new("BillboardGui")
    tag.Name = "ESP_Name"
    tag.Adornee = head
    tag.Size = UDim2.new(0, 120, 0, 25)
    tag.StudsOffset = Vector3.new(0, 2.5, 0)
    tag.AlwaysOnTop = true
    tag.Parent = model

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = color
    label.Font = Enum.Font.ArialBold
    label.TextSize = 18
    label.Text = nameText .. (healthEnabled and humanoid and (" | " .. math.floor(humanoid.Health)) or "")
    label.Parent = tag

    local function updateHealth()
        if humanoid and healthEnabled then
            label.Text = nameText .. " | " .. math.floor(humanoid.Health)
        else
            label.Text = nameText
        end
    end

    if humanoid then
        humanoid.HealthChanged:Connect(updateHealth)
    end

    espData[model] = {
        highlight = highlight,
        tag = tag,
        label = label,
        name = nameText,
        color = color
    }

    updateHealth()
end

-- Update ESP (only if changed)
local function updateESP(model, nameText, color)
    if not espData[model] then return end

    local data = espData[model]
    local humanoid = model:FindFirstChild("Humanoid")

    if data.name ~= nameText or data.color ~= color then
        data.name = nameText
        data.color = color
        data.label.TextColor3 = color
        data.highlight.OutlineColor = color
    end

    if humanoid and healthEnabled then
        data.label.Text = nameText .. " | " .. math.floor(humanoid.Health)
    else
        data.label.Text = nameText
    end
end

-- Get Team Color
local function getTeamColor(player)
    if teamModeEnabled and player.Character then
        local head = player.Character:FindFirstChild("Head") or player.Character:FindFirstChild("HumanoidRootPart")
        if head then
            for _, child in pairs(head:GetChildren()) do
                if child:IsA("BillboardGui") then
                    local label = child:FindFirstChildOfClass("TextLabel")
                    if label and label.TextColor3 then
                        return label.TextColor3
                    end
                end
            end
        end
    end
    if teamModeEnabled and player.Team then
        return player.TeamColor.Color
    else
        return Color3.fromRGB(255, 165, 0)
    end
end

-- Recursive NPC finder
local function findHumanoidModels(parent)
    local models = {}
    for _, obj in ipairs(parent:GetChildren()) do
        if obj:IsA("Model") then
            local humanoid = obj:FindFirstChildOfClass("Humanoid")
            local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head")
            if humanoid and root then
                table.insert(models, obj)
            end
        end
        for _, child in ipairs(findHumanoidModels(obj)) do
            table.insert(models, child)
        end
    end
    return models
end

-- Refresh ESP
local function refreshESP()
    if not espEnabled then
        for model in pairs(espData) do
            clearESP(model)
        end
        return
    end

    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end
    local myPos = myChar.HumanoidRootPart.Position

    local currentTargets = {}

    -- Tag Players
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local character = player.Character
            currentTargets[character] = true
            local color = getTeamColor(player)

            if not espData[character] then
                addESP(character, player.Name, color)
            else
                updateESP(character, player.Name, color)
            end
        end
    end

    -- Tag NPCs
    local npcModels = findHumanoidModels(workspace)
    for _, model in ipairs(npcModels) do
        if not Players:GetPlayerFromCharacter(model) then
            currentTargets[model] = true
            local dist = (myPos - (model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head")).Position).Magnitude
            if dist <= targetDistance then
                if not espData[model] then
                    addESP(model, model.Name, Color3.fromRGB(255, 0, 0))
                else
                    updateESP(model, model.Name, Color3.fromRGB(255, 0, 0))
                end
            else
                clearESP(model)
            end
        end
    end

    -- Clear Missing
    for model in pairs(espData) do
        if not currentTargets[model] then
            clearESP(model)
        end
    end
end

-- Button Actions
toggleBtn.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    toggleBtn.Text = espEnabled and "ESP: ON" or "ESP: OFF"
    if not espEnabled then
        for model in pairs(espData) do
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
    refreshESP()
end)

teamModeBtn.MouseButton1Click:Connect(function()
    teamModeEnabled = not teamModeEnabled
    teamModeBtn.Text = teamModeEnabled and "Team Mode: ON" or "Team Mode: OFF"
    refreshESP()
end)

-- Track Players
local function trackPlayer(player)
    player.CharacterAdded:Connect(function(character)
        character:WaitForChild("Humanoid", 5)
        character:WaitForChild("HumanoidRootPart", 5)
        if espEnabled then
            local color = getTeamColor(player)
            addESP(character, player.Name, color)
        end
    end)
    player.CharacterRemoving:Connect(function(character)
        clearESP(character)
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        trackPlayer(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        trackPlayer(player)
    end
end)

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightShift then
        menuVisible = not menuVisible
        gui.Enabled = menuVisible
    end
end)

RunService.Heartbeat:Connect(function(deltaTime)
    if espEnabled then
        refreshInterval = refreshInterval - deltaTime
        if refreshInterval <= 0 then
            refreshESP()
            refreshInterval = 5
        end
    end
end)

refreshESP()
