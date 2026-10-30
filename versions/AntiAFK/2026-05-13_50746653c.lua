--// Compact Anti-AFK + Random Walk + Ping (Universal LocalScript)
--// Modes: Walk / Ping / Hybrid
--// Prevents idle kick using VirtualUser (mouse, key, camera)

--==============================
-- SERVICES
--==============================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")

--==============================
-- PLAYER
--==============================
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

-- Modes: "Walk", "Ping", "Hybrid"
local mode = "Hybrid"

-- Random walk timing
local randomWalkMode = true
local minWalkTime = 1
local maxWalkTime = 10

-- Ping (anti-idle) system
local pingInterval = 55
local pingCooldown = pingInterval
local totalPings = 0

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
		if running and humanoid.Health > 0 and mode ~= "Ping" then
			humanoid:MoveTo(randomPoint())

			local waitTime = walkTime
			if randomWalkMode then
				waitTime = math.random(minWalkTime, maxWalkTime)
			end
			humanoid.MoveToFinished:Wait(waitTime)

			if (root.Position - homePosition).Magnitude > radius then
				humanoid:MoveTo(homePosition)
				humanoid.MoveToFinished:Wait(1)
			end
		end
		task.wait(0.25)
	end
end)

--==============================
-- TRUE ANTI-AFK (IDLE EVENT)
--==============================
player.Idled:Connect(function()
	VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
	task.wait(0.1)
	VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

--==============================
-- HEARTBEAT PING LOOP (Ping / Hybrid)
--==============================
RunService.Heartbeat:Connect(function(dt)
	if mode == "Walk" then return end

	pingCooldown -= dt
	if pingCooldown > 0 then return end
	pingCooldown = pingInterval

	pcall(function()
		-- Mouse click
		VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
		task.wait(0.05)
		VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)

		-- Fake key press
		VirtualUser:KeyDown(string.char(0))
		task.wait(0.05)
		VirtualUser:KeyUp(string.char(0))

		-- Camera nudge
		local cam = workspace.CurrentCamera
		local cf = cam.CFrame
		cam.CFrame = cf * CFrame.Angles(0, 0.0001, 0)
		task.wait(0.03)
		cam.CFrame = cf
	end)

	totalPings += 1
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
frame.Size = UDim2.fromOffset(220, 200)
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
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Center
	l.TextColor3 = Color3.fromRGB(220,220,220)
	return l
end

local function numberBox(initialText, labelText, y)
	local container = Instance.new("Frame")
	container.Parent = frame
	container.Size = UDim2.new(1, -16, 0, 24)
	container.Position = UDim2.fromOffset(8, y)
	container.BackgroundTransparency = 1

	local l = Instance.new("TextLabel")
	l.Parent = container
	l.Size = UDim2.new(0, 80, 1, 0)
	l.BackgroundTransparency = 1
	l.Text = labelText .. ":"
	l.Font = Enum.Font.Gotham
	l.TextSize = 12
	l.TextXAlignment = Enum.TextXAlignment.Right
	l.TextColor3 = Color3.fromRGB(180,180,180)

	local b = Instance.new("TextBox")
	b.Parent = container
	b.Position = UDim2.fromOffset(88, 0)
	b.Size = UDim2.new(1, -88, 1, 0)
	b.Text = initialText
	b.Font = Enum.Font.Gotham
	b.TextSize = 12
	b.BackgroundColor3 = Color3.fromRGB(30,30,30)
	b.TextColor3 = Color3.new(1,1,1)
	b.BorderSizePixel = 0
	b.ClearTextOnFocus = false
	Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
	return b
end

local function button(text, y)
	local b = Instance.new("TextButton")
	b.Parent = frame
	b.Size = UDim2.new(1, -16, 0, 26)
	b.Position = UDim2.fromOffset(8, y)
	b.Text = text
	b.Font = Enum.Font.GothamBold
	b.TextSize = 12
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

local radiusBox = numberBox("20", "Radius", 28)
local timeBox = numberBox("2", "Walk Time", 58)

local homeBtn = button("Set Home", 92)
local startBtn = button("Start", 122)
local modeBtn = button("Mode: Hybrid", 152)

--==============================
-- UI LOGIC
--==============================
local function sanitize(textbox, fallback)
	textbox.FocusLost:Connect(function()
		local v = tonumber(textbox.Text)
		if not v or v <= 0 then
			textbox.Text = tostring(fallback)
		else
			textbox.Text = tostring(v)
		end
	end)
end

sanitize(radiusBox, radius)
sanitize(timeBox, walkTime)

radiusBox.FocusLost:Connect(function()
	local v = tonumber(radiusBox.Text)
	if v and v > 0 then
		radius = v
		updateVisuals()
	end
end)

timeBox.FocusLost:Connect(function()
	local v = tonumber(timeBox.Text)
	if v and v > 0 then
		walkTime = v
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

modeBtn.MouseButton1Click:Connect(function()
	if mode == "Walk" then
		mode = "Ping"
	elseif mode == "Ping" then
		mode = "Hybrid"
	else
		mode = "Walk"
	end
	modeBtn.Text = "Mode: " .. mode
end)

--==============================
-- UI TOGGLE (L KEY)
--==============================
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.L then
		uiVisible = not uiVisible
		gui.Enabled = uiVisible
	end
end)
