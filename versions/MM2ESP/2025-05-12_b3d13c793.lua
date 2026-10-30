local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local espStorage = {}

-- Simulated role getter (you'll need a real one for MM2, this is a placeholder)
local function getRole(player)
    -- REPLACE this logic with actual detection if possible
    if player.Name == "KnownMurderer" then
        return "Murderer"
    elseif player.Name == "KnownSheriff" then
        return "Sheriff"
    else
        return "Innocent"
    end
end

local function createESP(player, role)
    if espStorage[player] then espStorage[player]:Destroy() end

    local color = role == "Murderer" and Color3.fromRGB(255, 0, 0) or
                  role == "Sheriff" and Color3.fromRGB(0, 140, 255) or
                  Color3.fromRGB(100, 100, 100)

    local highlight = Instance.new("Highlight")
    highlight.Name = "MM2ESP"
    highlight.FillColor = color
    highlight.FillTransparency = 0.7
    highlight.OutlineColor = Color3.new(0, 0, 0)
    highlight.OutlineTransparency = 0
    highlight.Adornee = player.Character
    highlight.Parent = player.Character
    espStorage[player] = highlight

    local tag = Instance.new("BillboardGui")
    tag.Name = "NameTag"
    tag.Size = UDim2.new(0, 100, 0, 20)
    tag.AlwaysOnTop = true
    tag.StudsOffset = Vector3.new(0, 3, 0)
    tag.Adornee = player.Character:WaitForChild("Head", 5)
    tag.Parent = player.Character

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = color
    label.Text = player.Name .. " (" .. role .. ")"
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansBold
    label.Parent = tag
end

local function updateESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local role = getRole(player)
            createESP(player, role)
        end
    end
end

RunService.RenderStepped:Connect(updateESP)

Players.PlayerRemoving:Connect(function(player)
    if espStorage[player] then
        espStorage[player]:Destroy()
        espStorage[player] = nil
    end
end)
