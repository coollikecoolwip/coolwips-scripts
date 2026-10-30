local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer and LocalPlayer:GetMouse()
local Teams = game:GetService("Teams")

local aimbotFOV = 300
local firstPersonAimbotEnabled = false
local triggerbotEnabled = false
local thirdPersonAimbotEnabled = false
local aimbotMode = "closest" -- Default mode: "closest" or "constant" [AI KNOWLEDGE]({})
local currentTarget = nil -- Stores the player for 'constant' mode [AI KNOWLEDGE]({})

local blacklisted = {}
local lastVisibleTargets = {}
local blacklistedTeams = {}

-- GUI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UniversalAimbotGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.CoreGui

local frame = Instance.new("Frame", ScreenGui)
frame.Size = UDim2.new(0, 220, 0, 200) -- Increased height for new buttons
frame.Position = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30) -- Darker background for main frame [AI KNOWLEDGE]({})
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

-- Function to create toggle buttons
local function createToggle(text, yOffset, getState, callback)
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 200, 0, 30)
    btn.Position = UDim2.new(0, 10, 0, yOffset)
    btn.BackgroundColor3 = Color3.fromRGB(150, 50, 50) -- Default OFF color [T0](1)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextScaled = true
    local function update()
        local state = getState()
        btn.BackgroundColor3 = state and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(150, 50, 50) -- ON/OFF color [T0](1)
        btn.Text = text .. (state and ": ON" or ": OFF")
    end
    btn.MouseButton1Click:Connect(function()
        callback(not getState())
        update()
    end)
    update()
    return btn, update
end

-- Aimbot Toggles [T0](1) [T1](2)
local firstPersonToggle, update1P = createToggle("1P Aimbot (Hard Lock)", 10, function() return firstPersonAimbotEnabled end, function(v) firstPersonAimbotEnabled = v end)
local triggerbotToggle, updateTrig = createToggle("Triggerbot (Hotkey Y)", 50, function() return triggerbotEnabled end, function(v) triggerbotEnabled = v end)
local thirdPersonToggle, update3P = createToggle("3P Aimbot (Free Cam)", 90, function() return thirdPersonAimbotEnabled end, function(v) thirdPersonAimbotEnabled = v end)

-- Mode Switch Button [AI KNOWLEDGE]({})
local modeSwitchBtn = Instance.new("TextButton", frame)
modeSwitchBtn.Size = UDim2.new(0, 200, 0, 30)
modeSwitchBtn.Position = UDim2.new(0, 10, 0, 130) -- Positioned below other toggles
modeSwitchBtn.BackgroundColor3 = Color3.fromRGB(70, 150, 200) -- Distinct color for mode switch [AI KNOWLEDGE]({})
modeSwitchBtn.TextColor3 = Color3.new(1, 1, 1)
modeSwitchBtn.Font = Enum.Font.SourceSansBold
modeSwitchBtn.TextScaled = true
local function updateModeBtnText()
    modeSwitchBtn.Text = "Mode: " .. (aimbotMode == "constant" and "Constant" or "Closest")
end
modeSwitchBtn.MouseButton1Click:Connect(function()
    if aimbotMode == "closest" then
        aimbotMode = "constant"
        print("Aimbot Mode: Constant")
    else
        aimbotMode = "closest"
        print("Aimbot Mode: Closest")
    end
    currentTarget = nil -- Reset current target when changing mode [AI KNOWLEDGE]({})
    updateModeBtnText()
end)
updateModeBtnText() -- Initialize button text

-- Blacklist UI Setup [T1](2) [T2](3)
local bb = Instance.new("Frame", ScreenGui)
bb.Size = UDim2.new(0, 440, 0, 250)
bb.Position = UDim2.new(0.5, 100, 0.5, -125)
bb.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
bb.BorderSizePixel = 0
bb.Active = true
bb.Draggable = true

-- Player Blacklist (Left Side) [T2](3)
local title = Instance.new("TextLabel", bb)
title.Size = UDim2.new(0.5, 0, 0, 30)
title.Position = UDim2.new(0, 0, 0, 0)
title.Text = "Blacklist Players"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.SourceSansBold
title.TextScaled = true
title.BackgroundTransparency = 1

local listFrame = Instance.new("ScrollingFrame", bb)
listFrame.Size = UDim2.new(0.5, -10, 1, -40)
listFrame.Position = UDim2.new(0, 5, 0, 35)
listFrame.BackgroundTransparency = 1
listFrame.ScrollBarThickness = 6

local UIList = Instance.new("UIListLayout", listFrame)
UIList.Padding = UDim.new(0, 4)
UIList.SortOrder = Enum.SortOrder.LayoutOrder

-- Team Blacklist (Right Side) [T2](3) [T3](4)
local teamTitle = Instance.new("TextLabel", bb)
teamTitle.Size = UDim2.new(0.5, 0, 0, 30)
teamTitle.Position = UDim2.new(0.5, 0, 0, 0)
teamTitle.Text = "Blacklist Teams"
teamTitle.TextColor3 = Color3.new(1, 1, 1)
teamTitle.Font = Enum.Font.SourceSansBold
teamTitle.TextScaled = true
teamTitle.BackgroundTransparency = 1

local teamListFrame = Instance.new("ScrollingFrame", bb)
teamListFrame.Size = UDim2.new(0.5, -10, 1, -40)
teamListFrame.Position = UDim2.new(0.5, 5, 0, 35)
teamListFrame.BackgroundTransparency = 1
teamListFrame.ScrollBarThickness = 6

local teamUIList = Instance.new("UIListLayout", teamListFrame)
teamUIList.Padding = UDim.new(0, 4)
teamUIList.SortOrder = Enum.SortOrder.LayoutOrder

-- Function to refresh Blacklist UI [T3](4) [T4](5)
local function refreshBlacklistUI()
    -- Player Blacklist Refresh
    for _, child in ipairs(listFrame:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end
    -- Ensure all players are considered by iterating through Players service directly [AI KNOWLEDGE]({})
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer then
            local btn = Instance.new("TextButton", listFrame)
            btn.Size = UDim2.new(1, 0, 0, 30)
            btn.BackgroundColor3 = blacklisted[pl.Name] and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(70, 70, 70)
            btn.Text = (blacklisted[pl.Name] and "[X] " or "[ ] ") .. pl.Name
            btn.Font = Enum.Font.SourceSans
            btn.TextScaled = true
            btn.TextColor3 = Color3.new(1, 1, 1)
            btn.AutoButtonColor = false
            btn.MouseButton1Click:Connect(function()
                blacklisted[pl.Name] = not blacklisted[pl.Name]
                refreshBlacklistUI() -- Re-call to update button colors immediately [AI KNOWLEDGE]({})
            end)
        end
    end

    -- Team Blacklist Refresh
    for _, child in ipairs(teamListFrame:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end
    for _, team in ipairs(Teams:GetTeams()) do
        local btn = Instance.new("TextButton", teamListFrame)
        btn.Size = UDim2.new(1, 0, 0, 30)
        btn.BackgroundColor3 = blacklistedTeams[team.Name] and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(70, 70, 70)
        btn.Text = (blacklistedTeams[team.Name] and "[X] " or "[ ] ") .. team.Name
        btn.Font = Enum.Font.SourceSans
        btn.TextScaled = true
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.AutoButtonColor = false
        btn.MouseButton1Click:Connect(function()
            blacklistedTeams[team.Name] = not blacklistedTeams[team.Name]
            refreshBlacklistUI() -- Re-call to update button colors immediately [AI KNOWLEDGE]({})
        end)
    end
end

-- Auto-refresh blacklist UI (kept for background updates) [T4](5)
task.spawn(function()
    while true do
        refreshBlacklistUI() -- This will now also update the button colors if they changed by manual click [AI KNOWLEDGE]({})
        task.wait(1)
    end
end)

-- Manual Refresh Blacklist Button [AI KNOWLEDGE]({})
local refreshBlacklistBtn = Instance.new("TextButton", frame)
refreshBlacklistBtn.Size = UDim2.new(0, 200, 0, 30)
refreshBlacklistBtn.Position = UDim2.new(0, 10, 0, 170) -- Positioned at the bottom of the main frame
refreshBlacklistBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 200)
refreshBlacklistBtn.TextColor3 = Color3.new(1, 1, 1)
refreshBlacklistBtn.Font = Enum.Font.SourceSansBold
refreshBlacklistBtn.TextScaled = true
refreshBlacklistBtn.Text = "Refresh Blacklist"
refreshBlacklistBtn.MouseButton1Click:Connect(function()
    refreshBlacklistUI() -- Directly call refresh function on click [AI KNOWLEDGE]({})
end)

-- Implement Players.PlayerAdded event listener [AI KNOWLEDGE]({})
Players.PlayerAdded:Connect(function(player)
    -- This will call the refresh function every time a player joins, ensuring they appear on the blacklist UI.
    refreshBlacklistUI() -- Refresh the UI when a new player joins [AI KNOWLEDGE]({})
end)

-- Hotkeys [T5](6)
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.T then
        firstPersonAimbotEnabled = not firstPersonAimbotEnabled
        update1P()
    elseif input.KeyCode == Enum.KeyCode.Y then
        triggerbotEnabled = not triggerbotEnabled
        updateTrig()
    elseif input.KeyCode == Enum.KeyCode.U then
        thirdPersonAimbotEnabled = not thirdPersonAimbotEnabled
        update3P()
    elseif input.KeyCode == Enum.KeyCode.M then -- Keybind for mode switching [AI KNOWLEDGE]({})
        if aimbotMode == "closest" then
            aimbotMode = "constant"
            print("Aimbot Mode: Constant")
        else
            aimbotMode = "closest"
            print("Aimbot Mode: Closest")
        end
        currentTarget = nil -- Reset current target when changing mode [AI KNOWLEDGE]({})
        updateModeBtnText() -- Update the mode button's text
    end
end)

-- Safe Raycast [T5](6)
local function safeRaycast(origin, direction, params)
    local ok, result = pcall(function()
        return workspace:Raycast(origin, direction, params)
    end)
    if ok then return result end
    return nil
end

-- Visibility Loop [T5](6)
task.spawn(function()
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.IgnoreWater = true
    while true do
        lastVisibleTargets = {}
        Camera = workspace.CurrentCamera or Camera
        local localChar = LocalPlayer and LocalPlayer.Character
        local origin = (Camera and Camera.CFrame) and Camera.CFrame.Position or nil
        if origin and localChar then
            rayParams.FilterDescendantsInstances = {localChar}
            for _, pl in ipairs(Players:GetPlayers()) do
                 if pl.Team and blacklistedTeams[pl.Team.Name] then
                    continue -- Skip this player
                end
                if pl ~= LocalPlayer and not blacklisted[pl.Name] and pl.Character then
                    local hum = pl.Character:FindFirstChild("Humanoid")
                    if hum and hum.Health > 0 then
                        if not LocalPlayer.Team or LocalPlayer.Team ~= pl.Team then
                            local bestPart, bestDist
                            for _, partName in ipairs({"Head", "HumanoidRootPart", "UpperTorso"}) do
                                local part = pl.Character:FindFirstChild(partName)
                                if part and part:IsA("BasePart") then
                                    local direction = (part.Position - origin)
                                    local result = safeRaycast(origin, direction.Unit * 500, rayParams)
                                    if result and result.Instance and result.Instance:IsDescendantOf(pl.Character) then
                                        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                                        if onScreen then
                                            local mousePos = UserInputService:GetMouseLocation()
                                            local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                                            if dist < aimbotFOV and (not bestDist or dist < bestDist) then
                                                bestPart, bestDist = part, dist
                                            end
                                        end
                                    end
                                end
                            end
                            if bestPart then
                                lastVisibleTargets[pl] = { part = bestPart, dist = bestDist }
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.25)
    end
end)

-- Target Selection Function with Modes [T6](7) [AI KNOWLEDGE]({})
local function getClosestTarget()
    local closest, part, dist = nil, nil, math.huge
    local targetToAimAt = nil -- This will be the player to aim at

    -- Constant Mode Logic: Maintain target if valid and visible [AI KNOWLEDGE]({})
    if aimbotMode == "constant" and currentTarget and currentTarget.Character and currentTarget.Character:FindFirstChild("Humanoid") and currentTarget.Character.Humanoid.Health > 0 then
        local data = lastVisibleTargets[currentTarget]
        if data then -- If the current target is still in the visible list
            targetToAimAt = currentTarget
            part = data.part
            dist = data.dist
        else
            currentTarget = nil -- Lost sight of the constant target, reset [AI KNOWLEDGE]({})
            print("Lost target in constant mode.") -- Optional feedback
        end
    end

    -- Closest Mode Logic (or if constant target lost) [AI KNOWLEDGE]({})
    if not targetToAimAt then
        for pl, data in pairs(lastVisibleTargets) do
             if pl.Team and blacklistedTeams[pl.Team.Name] then
                continue -- Skip this player
            end
            if pl and data and data.dist and not blacklisted[pl.Name] then
                local hum = pl.Character and pl.Character:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 then
                    if not LocalPlayer.Team or LocalPlayer.Team ~= pl.Team then
                        if data.dist < dist then
                            targetToAimAt = pl
                            part = data.part
                            dist = data.dist
                        end
                    end
                end
            end
        end
        -- If in constant mode and found a new closest target, set it as currentTarget [AI KNOWLEDGE]({})
        if aimbotMode == "constant" and targetToAimAt and currentTarget ~= targetToAimAt then
            print("New target acquired in constant mode.") -- Optional feedback
            currentTarget = targetToAimAt
        end
    end
    
    -- If in closest mode, update currentTarget for constant mode's next check if needed
    if aimbotMode == "closest" then
        currentTarget = targetToAimAt
    end

    return targetToAimAt, part
end

-- Aimbots [T7](8)
local function firstPersonAimbot()
    if not firstPersonAimbotEnabled then return end
    local t, pt = getClosestTarget()
    if t and pt and Camera and pt.Parent then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, pt.Position)
    end
end

local function thirdPersonAimbot()
    if not thirdPersonAimbotEnabled then return end
    local t, pt = getClosestTarget()
    if t and pt and Camera and pt.Parent then
        local screenPos = Camera:WorldToViewportPoint(pt.Position)
        local moveVec = Vector2.new(screenPos.X, screenPos.Y) - UserInputService:GetMouseLocation()
        if moveVec.Magnitude > 1 then
            -- Assuming mousemoverel is a globally defined function or needs implementation
            if _G.mousemoverel then _G.mousemoverel(moveVec.X, moveVec.Y) end
        end
    end
end

-- Triggerbot Check [T8](9)
local function isAimingAtEnemy()
    local lpChar = LocalPlayer and LocalPlayer.Character
    if not lpChar then return false end
    local ray = Camera:ScreenPointToRay(Mouse and Mouse.X or 0, Mouse and Mouse.Y or 0)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {lpChar}
    rayParams.IgnoreWater = true
    local ok, result = pcall(function()
        return workspace:Raycast(ray.Origin, ray.Direction * 9999, rayParams)
    end)
    if not ok or not result or not result.Instance then return false end
    local model = result.Instance:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChild("Humanoid") then
        local pl = Players:GetPlayerFromCharacter(model)
        if pl and pl ~= LocalPlayer and not blacklisted[pl.Name] then
            local hum = pl.Character and pl.Character:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                if not LocalPlayer.Team or LocalPlayer.Team ~= pl.Team then
                    return true
                end
            end
        end
    end
    return false
end

-- Main Render Loop [T8](9)
RunService.RenderStepped:Connect(function()
    -- Update current target for 'closest' mode or if 'constant' mode needs it
    if aimbotMode == "closest" then
        local target, _ = getClosestTarget()
        if target ~= currentTarget then
            currentTarget = target
        end
    end

    firstPersonAimbot()
    thirdPersonAimbot()
    
    if triggerbotEnabled and isAimingAtEnemy() then
        pcall(function() mouse1click() end) -- Assuming mouse1click is a globally defined function
    end
end)

-- Initial refresh of blacklist UI to populate it on script start
refreshBlacklistUI()
