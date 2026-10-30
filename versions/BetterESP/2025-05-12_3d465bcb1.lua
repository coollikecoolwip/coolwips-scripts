local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Function to create ESP with outline
local function createESP(target, color, name, isNPC)
    if target:FindFirstChild("Head") and not target.Head:FindFirstChild("ESP") then
        -- Billboard GUI for the name label
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESP"
        billboard.AlwaysOnTop = true
        billboard.Size = UDim2.new(0, 100, 0, 40)
        billboard.StudsOffset = Vector3.new(0, 2, 0)
        billboard.Adornee = target.Head
        billboard.Parent = target.Head

        -- Background Frame to simulate outline
        local outlineFrame = Instance.new("Frame")
        outlineFrame.Size = UDim2.new(1, 10, 1, 10)
        outlineFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- Black outline
        outlineFrame.BackgroundTransparency = 0.6
        outlineFrame.Position = UDim2.new(0, -5, 0, -5)
        outlineFrame.BorderSizePixel = 0
        outlineFrame.Parent = billboard

        -- Label to display name
        local label = Instance.new("TextLabel", billboard)
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = color
        label.TextStrokeTransparency = 0
        label.Text = name
        label.Font = Enum.Font.SourceSansBold
        label.TextSize = 14

        -- Add "NPC" tag to NPCs
        if isNPC then
            label.Text = "NPC - " .. label.Text
        end
    end
end

-- Function to get team color for players
local function getTeamColor(player)
    if player.Team and player.Team.TeamColor then
        return player.Team.TeamColor.Color
    end
    return Color3.new(1, 1, 1)  -- Default to white if no team is assigned
end

-- Main loop to create ESP for Players and NPCs
RunService.RenderStepped:Connect(function()
    -- ESP for players
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (LocalPlayer.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
            if dist <= 1000 then
                createESP(player.Character, getTeamColor(player), player.Name, false)
            end
        end
    end

    -- ESP for NPCs
    for _, npc in pairs(workspace:GetDescendants()) do
        if npc:IsA("Model") and not Players:GetPlayerFromCharacter(npc) and npc:FindFirstChild("Humanoid") and npc:FindFirstChild("HumanoidRootPart") then
            local dist = (LocalPlayer.Character.HumanoidRootPart.Position - npc.HumanoidRootPart.Position).Magnitude
            if dist <= 1000 then
                createESP(npc, Color3.new(1, 0.5, 0), npc.Name, true) -- Orange color for NPCs
            end
        end
    end
end)
