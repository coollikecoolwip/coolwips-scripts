--// Compact Anti-AFK + Random Walk (Universal LocalScript)

-- SERVICES
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- PLAYER
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")

--==============================
-- SETTINGS
--==============================
local homePosition = root.Position
local radius = 20
local walkTime = 2
local running = false
local uiVisible = true

--==============================
-- VISUALS
--==============================
local homePart = Instance.new("Part")
homePart.Anchored = true
homePart.CanCollide = false
homePart.Shape = Enum.PartType.Ball
homePart.Size = Vector3.new(1,1,1)
homePart.Material = Enum.Material.Neon
homePart.Color = Color3.fromRGB(0,255,0)
homePart.Transparency = 0.25
homePart.Parent = workspace

local radiusPart = Instance.new("Part")
radiusPart.Anchored = true
radiusPart.CanCollide = false
radiusPart.Shape = Enum.PartType.Ball
radiusPart.Material = Enum.Material.Neon
radiusPart.Color = Color3.fromRGB(0,170,255)
radiusPart.Transparency = 0.85
radiusPart.Parent = workspace

local function updateVisuals()
	homePart.Position = homePosition
	radiusPart.Position = homePosition
	radiusPart.Size = Vector3.new(radius * 2, radius * 2, radius * 2)
end

updateVisuals()

--==============================
-- MOVEMENT
--==============================
local function randomPoint()
	local angle = math.random() * math.pi * 2
	local dist = math.random() * radius
	return homePosition + Vector3.new(
		math.cos(angle) * dist,
		0,
		math.sin(angle) * dist
	)
end

task.spawn(function()
	while true do
		if running and humanoid.Health > 0 then
			humanoid:MoveTo(randomPoint())
			humanoid.MoveToFinished:Wait(walkTime)

			if (root.Position - homePosition).Magnitude > radius then
				humanoid:MoveTo(homePosition)
				humanoid.MoveToFinished:Wait(1)
			end
		end
		task.wait(0.25)
	end
end)

--==============================
-- UI
--==============================
local gui = Instance.new("ScreenGui")
gui.Name = "AntiAFK_UI"
gui.ResetOnSpawn = false
gui.Enabled = true
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Parent = gui
frame.Size = UDim2.fromOffset(220, 170)
frame.Position = UDim2.fromScale(0.05, 0.35)
frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

Instance.new("UICorner", frame).CornerRadius = UDim.new(0,10)

--==============================
-- UI HELPERS
--==============================
local function label(text, y)
	local l = Instance.new("TextLabel")
	l.Parent = frame
	l.Size = UDim2.new(1, -16, 0, 18)
	l.Position = UDim2.fromOffset(8, y)
	l.BackgroundTransparency = 1
	l.Text = text
	l.Font = Enum.Font.GothamMedium
	l.TextSize = 12
	l.TextScaled = false
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Center
	l.TextColor3 = Color3.fromRGB(220,220,220)
	return l
end

local function numberBox(initialText, placeholderText, y)
	local container = Instance.new("Frame")
	container.Parent = frame
	container.Size = UDim2.new(1, -16, 0, 24)
	container.Position = UDim2.fromOffset(8, y)
	container.BackgroundTransparency = 1
	container.LayoutOrder = 0 -- For potential future use if we add more complex layouts

	local prefixLabel = label(placeholderText .. ": ", 0)
	prefixLabel.Parent = container
	prefixLabel.Size = UDim2.new(0, 80, 1, 0) -- Fixed size for the label
	prefixLabel.TextXAlignment = Enum.TextXAlignment.Right
	prefixLabel.TextColor3 = Color3.fromRGB(180,180,180) -- Slightly dimmer for prefix

	local b = Instance.new("TextBox")
	b.Parent = container
	b.Size = UDim2.new(1, -88, 1, 0) -- Takes remaining space minus prefix width + padding
	b.Position = UDim2.new(0, 88, 0, 0) -- Positioned next to the prefix label
	b.Text = initialText
	b.Font = Enum.Font.Gotham
	b.TextSize = 12
	b.TextScaled = false
	b.BackgroundColor3 = Color3.fromRGB(30,30,30)
	b.TextColor3 = Color3.new(1,1,1)
	b.BorderSizePixel = 0
	b.ClearTextOnFocus = false
	Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
	return b, container -- Return both the textbox and its container
end

local function button(text, y)
	local b = Instance.new("TextButton")
	b.Parent = frame
	b.Size = UDim2.new(1, -16, 0, 26)
	b.Position = UDim2.fromOffset(8, y)
	b.Text = text
	b.Font = Enum.Font.GothamBold
	b.TextSize = 12
	b.TextScaled = false
	b.BackgroundColor3 = Color3.fromRGB(45,45,45)
	b.TextColor3 = Color3.new(1,1,1)
	b.BorderSizePixel = 0
	Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
	return b
end

--==============================
-- UI ELEMENTS
--==============================
label("Anti‑AFK Walker", 6)

local radiusBox, radiusBoxContainer = numberBox("20", "Radius", 28)
local timeBox, timeBoxContainer = numberBox("2", "Walk Time", 58)

local homeBtn = button("Set Home", 92)
local startBtn = button("Start", 122)

--==============================
-- UI LOGIC
--==============================
local function sanitizeNumberInput(textbox, defaultValue)
	textbox.FocusLost:Connect(function()
		local currentText = textbox.Text
		local num = tonumber(currentText)

		if num == nil or num <= 0 then
			textbox.Text = defaultValue
			num = defaultValue
		else
			textbox.Text = tostring(num) -- Ensure it's just the number
		end
		return num
	end)
	return defaultValue -- Return default value if initial logic fails
end

-- Apply sanitization to input boxes
local currentRadius = sanitizeNumberInput(radiusBox, radius)
local currentWalkTime = sanitizeNumberInput(timeBox, walkTime)

radiusBox.FocusLost:Connect(function()
	local val = tonumber(radiusBox.Text)
	if val and val > 0 then
		radius = val
		updateVisuals()
	else
		radiusBox.Text = tostring(radius) -- Reset to current valid radius
	end
end)

timeBox.FocusLost:Connect(function()
	local val = tonumber(timeBox.Text)
	if val and val > 0 then
		walkTime = val
	else
		timeBox.Text = tostring(walkTime) -- Reset to current valid walk time
	end
end)

homeBtn.MouseButton1Click:Connect(function()
	homePosition = root.Position
	updateVisuals()
end)

startBtn.MouseButton1Click:Connect(function()
	running = not running
	startBtn.Text = running and "Stop" or "Start"
end)

--==============================
-- UI TOGGLE (L KEY)
--==============================
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end -- Ignore gamepad input
	if input.KeyCode == Enum.KeyCode.L then
		uiVisible = not uiVisible
		gui.Enabled = uiVisible
	end
end)

--==============================
-- ANTI AFK
--==============================
player.Idled:Connect(function()
	humanoid:Move(Vector3.zero)
end)
