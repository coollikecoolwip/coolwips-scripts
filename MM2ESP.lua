local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local roleColors = {
    Murderer = Color3.fromRGB(255, 0, 0),
    Sheriff = Color3.fromRGB(0, 170, 255),
    Innocent = Color3.fromRGB(120, 120, 120)
}

local roleTracker = {}

local function clearESP(player)
    if player.Character then
        for _, part in pairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                local esp = part:FindFirstChild("ESPBox")
                if esp then esp:Destroy() end
            end
        end
    end
end

local function createESP(player, color)
    if not player.Character then return end
    for _, part in pairs(player.Character:GetDescendants()) do
        if part:IsA("BasePart") and not part:IsDescendantOf(player.Character:FindFirstChildOfClass("Tool")) then
            if not part:FindFirstChild("ESPBox") then
                local box = Instance.new("BoxHandleAdornment")
                box.Name = "ESPBox"
                box.Adornee = part
                box.AlwaysOnTop = true
                box.ZIndex = 10
                box.Size = part.Size
                box.Transparency = 0.6
                box.Color3 = color
                box.Parent = part
            end
        end
    end
end

local function detectRoles()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local tool = player.Character:FindFirstChildOfClass("Tool")
            if tool then
                local name = tool.Name:lower()
                if name:find("knife") then
                    roleTracker[player] = "Murderer"
                elseif name:find("gun") then
                    roleTracker[player] = "Sheriff"
                end
            end
        end
    end
end

local function updateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local role = roleTracker[player] or "Innocent"
            createESP(player, roleColors[role])
        end
    end
end

local function onCharacterAdded(player)
    task.delay(1, function()
        clearESP(player)
        roleTracker[player] = nil
    end)
end

local function setupPlayer(player)
    player.CharacterAdded:Connect(function()
        onCharacterAdded(player)
    end)
    if player.Character then
        onCharacterAdded(player)
    end
end

Players.PlayerAdded:Connect(setupPlayer)
for _, player in ipairs(Players:GetPlayers()) do
    setupPlayer(player)
end

Workspace:GetPropertyChangedSignal("DistributedGameTime"):Connect(function()
    roleTracker = {}
    for _, p in ipairs(Players:GetPlayers()) do
        clearESP(p)
    end
end)

RunService.RenderStepped:Connect(function()
    detectRoles()
    updateESP()
end)
