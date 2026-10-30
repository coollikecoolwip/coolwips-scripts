local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local ROLE_SIZES = {
    Murderer = Vector3.new(2.5, 2.5, 2.5),
    Sheriff = Vector3.new(2.5, 2.5, 2.5),
    Innocent = Vector3.new(1.5, 1.5, 1.5),
}

local function getMyRole()
    if LocalPlayer.Backpack:FindFirstChild("Knife") or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Knife")) then
        return "Murderer"
    elseif LocalPlayer.Backpack:FindFirstChild("Gun") or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Gun")) then
        return "Sheriff"
    else
        return "Innocent"
    end
end

local function getTargetRole(player)
    if player.Backpack:FindFirstChild("Knife") or (player.Character and player.Character:FindFirstChild("Knife")) then
        return "Murderer"
    elseif player.Backpack:FindFirstChild("Gun") or (player.Character and player.Character:FindFirstChild("Gun")) then
        return "Sheriff"
    else
        return "Innocent"
    end
end

local function expandHitbox(player, size)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
    local part = player.Character.HumanoidRootPart

    part.Size = size
    part.Transparency = 0.75
    part.Material = Enum.Material.ForceField
    part.CanCollide = false

    if not part:FindFirstChild("HitboxESP") then
        local hl = Instance.new("Highlight")
        hl.Name = "HitboxESP"
        hl.Adornee = part
        hl.FillColor = Color3.fromRGB(0, 255, 0)
        hl.FillTransparency = 0.5 -- 50% transparent
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = part
    end
end

-- Cleanup on round restart
LocalPlayer.CharacterAdded:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local part = player.Character.HumanoidRootPart
            part.Size = Vector3.new(2, 2, 1)
            part.Transparency = 1
            part.Material = Enum.Material.Plastic
            local old = part:FindFirstChild("HitboxESP")
            if old then old:Destroy() end
        end
    end
end)

-- Role-based hitbox logic
RunService.RenderStepped:Connect(function()
    local myRole = getMyRole()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local role = getTargetRole(player)

            if myRole == "Murderer" and role == "Innocent" then
                expandHitbox(player, ROLE_SIZES.Innocent)
            elseif myRole == "Murderer" and role == "Sheriff" then
                expandHitbox(player, ROLE_SIZES.Sheriff)
            elseif myRole == "Sheriff" and role == "Murderer" then
                expandHitbox(player, ROLE_SIZES.Murderer)
            end
        end
    end
end)
