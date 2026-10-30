local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Role-based sizes
local HITBOX_SIZES = {
    Murderer = Vector3.new(9, 9, 9),
    Sheriff = Vector3.new(9, 9, 9),
    Innocent = Vector3.new(6, 6, 6),
}

-- Track applied ESP to avoid duplicates
local appliedHitboxes = {}

-- Determine your own role
local function getMyRole()
    if LocalPlayer.Backpack:FindFirstChild("Knife") or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Knife")) then
        return "Murderer"
    elseif LocalPlayer.Backpack:FindFirstChild("Gun") or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Gun")) then
        return "Sheriff"
    else
        return "Innocent"
    end
end

-- Determine a player's role
local function getPlayerRole(player)
    if player.Backpack:FindFirstChild("Knife") or (player.Character and player.Character:FindFirstChild("Knife")) then
        return "Murderer"
    elseif player.Backpack:FindFirstChild("Gun") or (player.Character and player.Character:FindFirstChild("Gun")) then
        return "Sheriff"
    else
        return "Innocent"
    end
end

-- Expand the hitbox and apply green highlight
local function applyHitbox(player, size)
    local char = player.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp or appliedHitboxes[player] then return end

    hrp.Size = size
    hrp.CanCollide = false
    hrp.Transparency = 0.75
    hrp.Material = Enum.Material.ForceField

    local highlight = Instance.new("Highlight")
    highlight.Name = "HitboxESP"
    highlight.Adornee = hrp
    highlight.FillColor = Color3.fromRGB(0, 255, 0)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = hrp

    appliedHitboxes[player] = true
end

-- Reset on character spawn
LocalPlayer.CharacterAdded:Connect(function()
    appliedHitboxes = {}
end)

-- Main loop
RunService.RenderStepped:Connect(function()
    local myRole = getMyRole()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local role = getPlayerRole(player)

            -- Only expand based on your role
            if myRole == "Murderer" and role == "Sheriff" then
                applyHitbox(player, HITBOX_SIZES.Sheriff)
            elseif myRole == "Murderer" and role == "Innocent" then
                applyHitbox(player, HITBOX_SIZES.Innocent)
            elseif myRole == "Sheriff" and role == "Murderer" then
                applyHitbox(player, HITBOX_SIZES.Murderer)
            end
        end
    end
end)
