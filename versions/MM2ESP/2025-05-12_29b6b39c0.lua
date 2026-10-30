-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local ESP = {}

-- Create function for drawing an outline around the player or object
local function createOutline(part, color)
    local outline = Instance.new("Highlight")
    outline.Parent = part
    outline.FillTransparency = 1
    outline.OutlineTransparency = 0
    outline.OutlineColor = color
    outline.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    return outline
end

-- Function to reset all ESP elements
local function resetESP()
    for _, espElement in pairs(ESP) do
        espElement:Destroy()
    end
    ESP = {}
end

-- Function to handle player's role change
local function updateESPForPlayer(player)
    local char = player.Character
    if not char or not player.Character:FindFirstChild("HumanoidRootPart") then return end

    local hrp = char.HumanoidRootPart
    local role = player:FindFirstChild("PlayerData") and player.PlayerData:FindFirstChild("Role")

    if role then
        local color
        if role.Value == "Murderer" then
            color = Color3.fromRGB(255, 0, 0)  -- Red for murderer
        elseif role.Value == "Sheriff" then
            color = Color3.fromRGB(0, 0, 255)  -- Blue for sheriff
        elseif role.Value == "Innocent" then
            color = Color3.fromRGB(169, 169, 169)  -- Gray for innocent
        end

        if color then
            -- Create an outline around the character
            ESP[player] = createOutline(hrp, color)
        end
    end
end

-- Function to handle dropped gun
local function updateDroppedGunESP()
    for _, item in pairs(Workspace:GetChildren()) do
        if item:IsA("Tool") and item.Name == "Gun" then
            local gunPosition = item.Handle
            if gunPosition then
                -- Create green outline for the dropped gun
                createOutline(gunPosition, Color3.fromRGB(0, 255, 0))
            end
        end
    end
end

-- Main loop for checking and updating ESP
RunService.RenderStepped:Connect(function()
    -- Reset ESP if new round starts or player is teleported
    if LocalPlayer.Character.Humanoid.Health == 0 or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        resetESP()
    end

    -- Update ESP for all players
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            updateESPForPlayer(player)
        end
    end

    -- Update ESP for dropped guns
    updateDroppedGunESP()
end)

-- Ensure ESP resets when the player spawns or teleports
LocalPlayer.CharacterAdded:Connect(function()
    resetESP()
end)
