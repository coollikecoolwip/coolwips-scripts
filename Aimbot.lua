-- Services and Globals
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer and LocalPlayer:GetMouse()

local aimbotFOV = 300
local firstPersonAimbotEnabled = false
local triggerbotEnabled = false
local thirdPersonAimbotEnabled = false
local blacklisted = {}
local lastVisibleTargets = {}

-- GUI Setup (make persistent across respawns)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UniversalAimbotGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.CoreGui -- keeping your original parent

-- Main Frame
local frame = Instance.new("Frame", ScreenGui)
frame.Size = UDim2.new(0, 220, 0, 140)
frame.Position = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

-- Toggle Utility
local function createToggle(text, yOffset, getState, callback)
	local btn = Instance.new("TextButton", frame)
	btn.Size = UDim2.new(0, 200, 0, 30)
	btn.Position = UDim2.new(0, 10, 0, yOffset)
	btn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.SourceSansBold
	btn.TextScaled = true
	btn.Text = text .. ": OFF"

	local function update()
		local state = getState()
		btn.BackgroundColor3 = state and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(150, 50, 50)
		btn.Text = text .. (state and ": ON" or ": OFF")
	end

	btn.MouseButton1Click:Connect(function()
		local new = not getState()
		callback(new)
		update()
	end)

	update()
	return btn, update
end

-- Create toggles
local firstPersonToggle, update1P = createToggle("1P Aimbot (Hard Lock)", 10,
	function() return firstPersonAimbotEnabled end,
	function(v) firstPersonAimbotEnabled = v end
)

local triggerbotToggle, updateTrig = createToggle("Triggerbot (Hotkey Y)", 50,
	function() return triggerbotEnabled end,
	function(v) triggerbotEnabled = v end
)

local thirdPersonToggle, update3P = createToggle("3P Aimbot (Free Cam)", 90,
	function() return thirdPersonAimbotEnabled end,
	function(v) thirdPersonAimbotEnabled = v end
)

-- Blacklist GUI (draggable)
local bb = Instance.new("Frame", ScreenGui)
bb.Size = UDim2.new(0, 220, 0, 250)
bb.Position = UDim2.new(0.5, 100, 0.5, -125)
bb.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
bb.BorderSizePixel = 0
bb.Active = true
bb.Draggable = true

local title = Instance.new("TextLabel", bb)
title.Size = UDim2.new(1, 0, 0, 30)
title.Text = "Blacklist Players"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.SourceSansBold
title.TextScaled = true
title.BackgroundTransparency = 1

local listFrame = Instance.new("ScrollingFrame", bb)
listFrame.Size = UDim2.new(1, -10, 1, -40)
listFrame.Position = UDim2.new(0, 5, 0, 35)
listFrame.BackgroundTransparency = 1
listFrame.ScrollBarThickness = 6

local UIList = Instance.new("UIListLayout", listFrame)
UIList.Padding = UDim.new(0, 4)
UIList.SortOrder = Enum.SortOrder.LayoutOrder

local function refreshBlacklistUI()
    -- remove previous buttons (keep UIList)
    for _, child in ipairs(listFrame:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end

    -- re-add players
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
                refreshBlacklistUI()
            end)
        end
    end
end

-- initial UI
Players.PlayerAdded:Connect(refreshBlacklistUI)
Players.PlayerRemoving:Connect(refreshBlacklistUI)
refreshBlacklistUI()

-- Hotkeys
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
	end
end)

-- Helper: safe raycast wrapper
local function safeRaycast(origin, direction, params)
	-- pcall to avoid runtime errors stopping the loop
	local ok, result = pcall(function()
		return workspace:Raycast(origin, direction, params)
	end)
	if ok then
		return result
	end
	return nil
end

-- Visibility Caching Loop (throttled)
task.spawn(function()
	-- Pre-allocate a RaycastParams object to reuse
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Blacklist
	rayParams.IgnoreWater = true

	while true do
		lastVisibleTargets = {}
		-- ensure Camera and LocalPlayer.Character exist
		Camera = workspace.CurrentCamera or Camera
		local localChar = LocalPlayer and LocalPlayer.Character
		local origin = (Camera and Camera.CFrame) and Camera.CFrame.Position or nil
		if origin and localChar then
			-- set blacklist filter to current character reference
			rayParams.FilterDescendantsInstances = {localChar}

			for _, pl in ipairs(Players:GetPlayers()) do
				-- basic guards
				if pl ~= LocalPlayer and not blacklisted[pl.Name] and pl.Character then
					local bestPart, bestDist
					-- check common target parts
					for _, partName in ipairs({"Head", "HumanoidRootPart", "UpperTorso"}) do
						local part = pl.Character:FindFirstChild(partName)
						if part and part:IsA("BasePart") then
							local direction = (part.Position - origin)
							-- do a safe raycast
							local result = safeRaycast(origin, direction.Unit * 500, rayParams)
							if result and result.Instance and result.Instance:IsDescendantOf(pl.Character) then
								local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
								if onScreen then
									-- use UserInputService mouse location (more consistent)
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
		task.wait(0.25)
	end
end)

-- Target Resolver
local function getClosestTarget()
	local closest, part, dist = nil, nil, math.huge
	for pl, data in pairs(lastVisibleTargets) do
		-- guard in case player left or changed name
		if pl and data and data.dist and not blacklisted[pl.Name] then
			if data.dist < dist then
				closest, part, dist = pl, data.part, data.dist
			end
		end
	end
	return closest, part
end

-- Aimbots
local function firstPersonAimbot()
	if not firstPersonAimbotEnabled then return end
	local t, pt = getClosestTarget()
	if t and pt and Camera then
		-- ensure target part still exists
		if pt.Parent then
			Camera.CFrame = CFrame.new(Camera.CFrame.Position, pt.Position)
		end
	end
end

local function thirdPersonAimbot()
	if not thirdPersonAimbotEnabled then return end
	local t, pt = getClosestTarget()
	if t and pt and Camera then
		if pt.Parent then
			local screenPos = Camera:WorldToViewportPoint(pt.Position)
			local moveVec = Vector2.new(screenPos.X, screenPos.Y) - UserInputService:GetMouseLocation()
			-- only move if significant to avoid micro jitter
			if moveVec.Magnitude > 1 then
				mousemoverel(moveVec.X, moveVec.Y)
			end
		end
	end
end

local function isAimingAtEnemy()
	-- ensure LocalPlayer.Character exists
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
	if not ok or not result or not result.Instance then
		return false
	end

	local model = result.Instance:FindFirstAncestorOfClass("Model")
	if model and model:FindFirstChild("Humanoid") then
		local pl = Players:GetPlayerFromCharacter(model)
		if not pl or (pl ~= LocalPlayer and not blacklisted[pl.Name]) then
			return true
		end
	end
	return false
end

-- Main Loop
RunService.RenderStepped:Connect(function()
	firstPersonAimbot()
	thirdPersonAimbot()
	if triggerbotEnabled and isAimingAtEnemy() then
		-- safe pcall to avoid errors if mouse1click isn't available
		pcall(function() mouse1click() end)
	end
end)
