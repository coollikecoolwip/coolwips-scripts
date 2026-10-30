local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local roleColors = {
    Murderer = Color3.fromRGB(255, 0, 0), -- Red
    Sheriff = Color3.fromRGB(0, 170, 255), -- Blue
    Innocent = Color3.fromRGB(120, 120, 120) -- Gray
}

local roleTracker = {}

function createESP(player, color)
    if player.Character then
        for _, part in pairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") and not part:FindFirstChild("ESPBox") then
                local box = Instance.new("BoxHandleAdornment")
                box.Name = "ESPBox"
                box.Adornee = part
                box.AlwaysOnTop = true
                box.ZIndex = 10
                box.Size = part.Size
                box.Transparency = 0.7
                box.Color3 = color
                box.Parent = part
            end
        end
    end
end

function updateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local tool = player.Character:FindFirstChildOfClass("Tool")
            if tool then
                if tool.Name:lower():find("knife") then
                    roleTracker[player] = "Murderer"
                elseif tool.Name:lower():find("gun") then
                    roleTracker[player] = "Sheriff"
                end
            end

            local role = roleTracker[player] or "Innocent"
            createESP(player, roleColors[role])
        end
    end
end

RunService.RenderStepped:Connect(updateESP)
