-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local ESP = {}

-- Helper function to create an outline around players and dropped guns
local function createOutline(part, color)
    local highlight = Instance.new("Highlight")
    highlight.Parent = part
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = color
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    return highlight
end

-- Function to reset ESP when teleporting or round change
local function resetESP()
    for _, espElement in pairs(ESP) do
        espElement:Destroy()
    end
    ESP = {}
end

-- Function to update ESP for players
local function updatePlayerESP(player)
    local char = player.Character
    if char and player.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = char.HumanoidRootPart
        local role = player:FindFirstChild("PlayerData") and player.PlayerData:FindFirstChild("Role")
        
        -- Ensure the role exists
        if role then
            local color
            if role.Value == "Murderer" then
                color = Color3.fromRGB(255, 0, 0)  -- Red outline for Murderer
            elseif role.Value == "Sheriff" then
                color = Color3.fromRGB(0, 0, 255)  -- Blue outline for Sheriff
            elseif role.Value == "Innocent" then
                color = Color3.fromRGB(169, 169, 169)  -- Gray outline for Innocents
            end
            
            if color then
                -- Create an outline for the player's character
                ESP[player] = createOutline(hrp, color)
            end
        end
    end
end

-- Function to update ESP for dropped guns
local function updateDroppedGunESP()
    for _, item in pairs(Workspace:GetChildren()) do
        if item:IsA("Tool") and item.Name == "Gun" then
            local gunHandle = item:FindFirstChild("Handle")
            if gunHandle then
                -- Create green outline for dropped gun
                createOutline(gunHandle, Color3.fromRGB(0, 255, 0))
            end
        end
    end
end

-- Main loop to update ESP
RunService.RenderStepped:Connect(function()
    -- Reset ESP if player is respawned or teleported
    if LocalPlayer.Character.Humanoid.Health == 0 or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        resetESP()
    end

    -- Update ESP for all players
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            updatePlayerESP(player)
        end
    end

    -- Update ESP for dropped guns
    updateDroppedGunESP()
end)

-- Reset ESP when the player spawns or teleports
LocalPlayer.CharacterAdded:Connect(function()
    resetESP()
end)
