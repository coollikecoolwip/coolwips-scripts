local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local function isMurderer(player)
    return player:FindFirstChild("Backpack") and player.Backpack:FindFirstChild("Knife") 
        or player.Character and player.Character:FindFirstChild("Knife")
end

local function expandHitbox(player)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
    local part = player.Character.HumanoidRootPart

    -- Expand hitbox
    part.Size = Vector3.new(15, 15, 15)
    part.Transparency = 0.75
    part.Material = Enum.Material.ForceField
    part.CanCollide = false

    -- Add green highlight if not already added
    if not part:FindFirstChild("HitboxESP") then
        local hl = Instance.new("Highlight")
        hl.Name = "HitboxESP"
        hl.Adornee = part
        hl.FillColor = Color3.fromRGB(0, 255, 0)
        hl.FillTransparency = 0.25
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = part
    end
end

-- Reset on new character
LocalPlayer.CharacterAdded:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if hrp and hrp:FindFirstChild("HitboxESP") then
                hrp.HitboxESP:Destroy()
                hrp.Size = Vector3.new(2, 2, 1)
                hrp.Transparency = 1
                hrp.Material = Enum.Material.Plastic
            end
        end
    end
end)

-- Update each frame
RunService.RenderStepped:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isMurderer(player) then
            expandHitbox(player)
        end
    end
end)
