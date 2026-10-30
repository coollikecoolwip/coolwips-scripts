local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local roleColors = {
    Murderer = Color3.fromRGB(255, 0, 0),    -- Red
    Sheriff = Color3.fromRGB(0, 170, 255),   -- Blue
    Innocent = Color3.fromRGB(120, 120, 120) -- Gray
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

local function resetAll()
    roleTracker = {}
    for _, p in ipairs(Players:GetPlayers()) do
        clearESP(p)
    end
end

local function createESP(player, color)
    if player.Character then
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

Workspace:GetPropertyChangedSignal("DistributedGameTime"):Connect(function()
    resetAll()
end)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        wait(1)
        roleTracker[player] = nil
        clearESP(player)
    end)
end)

for _, player in ipairs(Players:GetPlayers()) do
    player.CharacterAdded:Connect(function()
        wait(1)
        roleTracker[player] = nil
        clearESP(player)
    end)
end

RunService.RenderStepped:Connect(function()
    detectRoles()
    updateESP()
end)
