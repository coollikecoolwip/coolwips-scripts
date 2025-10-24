local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

local following = false
local selectedPlayer = nil
local mimicConnection = nil
local followDistance = 5
local speedMode = false

local gui = Instance.new("ScreenGui")
gui.Name = "MimicGUI"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 240, 0, 480)
frame.Position = UDim2.new(0, 20, 0.5, -240)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 40)
title.Text = "Follow Script"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.SourceSansBold
title.TextScaled = true
title.BackgroundTransparency = 1

local distanceBox = Instance.new("TextBox", frame)
distanceBox.Size = UDim2.new(0.9, 0, 0, 30)
distanceBox.Position = UDim2.new(0.05, 0, 0, 45)
distanceBox.PlaceholderText = "Follow Distance"
distanceBox.Text = tostring(followDistance)
distanceBox.Font = Enum.Font.SourceSans
distanceBox.TextScaled = true
distanceBox.TextColor3 = Color3.new(1, 1, 1)
distanceBox.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
distanceBox.BorderSizePixel = 0

local speedBtn = Instance.new("TextButton", frame)
speedBtn.Size = UDim2.new(0.9, 0, 0, 30)
speedBtn.Position = UDim2.new(0.05, 0, 0, 85)
speedBtn.Text = "Speed Mode: OFF"
speedBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
speedBtn.TextColor3 = Color3.new(1, 1, 1)
speedBtn.Font = Enum.Font.SourceSansBold
speedBtn.TextScaled = true
speedBtn.BorderSizePixel = 0

local toggleBtn = Instance.new("TextButton", frame)
toggleBtn.Size = UDim2.new(0.9, 0, 0, 30)
toggleBtn.Position = UDim2.new(0.05, 0, 0, 125)
toggleBtn.Text = "START"
toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.TextScaled = true
toggleBtn.BorderSizePixel = 0

local scrollingFrame = Instance.new("ScrollingFrame", frame)
scrollingFrame.Size = UDim2.new(1, -10, 0, 300)
scrollingFrame.Position = UDim2.new(0, 5, 0, 165)
scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollingFrame.ScrollBarThickness = 6
scrollingFrame.BackgroundTransparency = 1

speedBtn.MouseButton1Click:Connect(function()
	speedMode = not speedMode
	speedBtn.Text = "Speed Mode: " .. (speedMode and "ON" or "OFF")
	speedBtn.BackgroundColor3 = speedMode and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(100, 100, 100)
end)

local function stopMimic()
	following = false
	if mimicConnection then mimicConnection:Disconnect() end
	local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
	if hum then hum:Move(Vector3.zero) end
	toggleBtn.Text = "START"
	toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
end

local function startMimic(target)
	if not target or not target.Character then return end
	local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then return end

	mimicConnection = RunService.RenderStepped:Connect(function()
		if not following or not target.Character or not LocalPlayer.Character then return end

		local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")

		if myRoot and targetRoot then
			local offsetVec = (targetRoot.Position - myRoot.Position)
			local dist = offsetVec.Magnitude

			if dist > followDistance then
				local speedBoost = speedMode and math.clamp(math.floor(dist / 5), 0, 100) or 0
				humanoid.WalkSpeed = 16 + speedBoost
				humanoid:Move(offsetVec.Unit, false)
			else
				humanoid:Move(Vector3.zero)
			end
		end
	end)

	toggleBtn.Text = "STOP"
	toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
end

local function teleportToPlayer(player)
	if player and player.Character then
		local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
		local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if targetRoot and myRoot then
			myRoot.CFrame = targetRoot.CFrame + Vector3.new(0, 3, 0)
		end
	end
end

local function createButtons()
	scrollingFrame:ClearAllChildren()
	local yOffset = 0

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local playerFrame = Instance.new("Frame", scrollingFrame)
			playerFrame.Size = UDim2.new(1, -10, 0, 45)
			playerFrame.Position = UDim2.new(0, 0, 0, yOffset)
			playerFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

			local nameBtn = Instance.new("TextButton", playerFrame)
			nameBtn.Size = UDim2.new(0.6, -5, 1, -5)
			nameBtn.Position = UDim2.new(0, 5, 0, 2)
			nameBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
			nameBtn.Text = player.Name
			nameBtn.TextColor3 = Color3.new(1, 1, 1)
			nameBtn.Font = Enum.Font.SourceSansBold
			nameBtn.TextScaled = true
			nameBtn.BorderSizePixel = 0

			local gotoBtn = Instance.new("TextButton", playerFrame)
			gotoBtn.Size = UDim2.new(0.35, -5, 1, -5)
			gotoBtn.Position = UDim2.new(0.62, 0, 0, 2)
			gotoBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
			gotoBtn.Text = "Goto"
			gotoBtn.TextColor3 = Color3.new(1, 1, 1)
			gotoBtn.Font = Enum.Font.SourceSansBold
			gotoBtn.TextScaled = true
			gotoBtn.BorderSizePixel = 0

			nameBtn.MouseButton1Click:Connect(function()
				local val = tonumber(distanceBox.Text)
				if val and val > 0 then followDistance = val end

				stopMimic()
				selectedPlayer = player
				following = true
				startMimic(player)
			end)

			gotoBtn.MouseButton1Click:Connect(function()
				teleportToPlayer(player)
			end)

			yOffset = yOffset + 50
		end
	end

	scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

toggleBtn.MouseButton1Click:Connect(function()
	if following then
		stopMimic()
	elseif selectedPlayer then
		local val = tonumber(distanceBox.Text)
		if val and val > 0 then followDistance = val end

		following = true
		startMimic(selectedPlayer)
	end
end)

createButtons()
Players.PlayerAdded:Connect(function() task.wait(1); createButtons() end)
Players.PlayerRemoving:Connect(createButtons)

local toggleFrame = Instance.new("Frame")
toggleFrame.Size = UDim2.new(0, 100, 0, 40)
toggleFrame.Position = UDim2.new(0, 10, 0, 10)
toggleFrame.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
toggleFrame.BorderSizePixel = 0
toggleFrame.Active = true
toggleFrame.Draggable = true
toggleFrame.Parent = gui

local toggleGuiBtn = Instance.new("TextButton")
toggleGuiBtn.Size = UDim2.new(1, 0, 1, 0)
toggleGuiBtn.Position = UDim2.new(0, 0, 0, 0)
toggleGuiBtn.Text = "Toggle GUI"
toggleGuiBtn.BackgroundTransparency = 1
toggleGuiBtn.TextColor3 = Color3.new(1, 1, 1)
toggleGuiBtn.Font = Enum.Font.SourceSansBold
toggleGuiBtn.TextScaled = true
toggleGuiBtn.BorderSizePixel = 0
toggleGuiBtn.Parent = toggleFrame

local guiVisible = true
toggleGuiBtn.MouseButton1Click:Connect(function()
	guiVisible = not guiVisible
	frame.Visible = guiVisible
end)
