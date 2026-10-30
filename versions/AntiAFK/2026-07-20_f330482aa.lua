--// Advanced Anti-AFK Walker
--// Persistent + Death Safe + Random Walk Control

--========================================
-- SERVICES
--========================================
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")

--========================================
-- PLAYER
--========================================
local player = Players.LocalPlayer

local character
local humanoid
local root

local function setupCharacter(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
	root = char:WaitForChild("HumanoidRootPart")
end

setupCharacter(player.Character or player.CharacterAdded:Wait())

player.CharacterAdded:Connect(function(char)
	task.wait(1)
	setupCharacter(char)
end)

--========================================
-- SETTINGS
--========================================
local running = false
local mode = "Hybrid"

local radius = 20
local homePosition = root.Position

-- Random walk settings
local randomWalk = true
local minWalkTime = 2
local maxWalkTime = 8

-- If random walk disabled
local fixedWalkTime = 5

local pingInterval = 55
local pingCooldown = pingInterval

--========================================
-- HOME VISUALS
--========================================
local homePart = Instance.new("Part")
homePart.Anchored = true
homePart.CanCollide = false
homePart.Shape = Enum.PartType.Ball
homePart.Material = Enum.Material.Neon
homePart.Color = Color3.fromRGB(0,170,255) -- Blue
homePart.Transparency = 0.88
homePart.Parent = workspace

local centerPart = Instance.new("Part")
centerPart.Anchored = true
centerPart.CanCollide = false
centerPart.Shape = Enum.PartType.Ball
centerPart.Material = Enum.Material.Neon
centerPart.Color = Color3.fromRGB(0,255,0) -- Green
centerPart.Size = Vector3.new(1,1,1)
centerPart.Parent = workspace

local function updateVisuals()
	homePart.Position = homePosition
	centerPart.Position = homePosition
	homePart.Size = Vector3.new(radius*2,radius*2,radius*2)
end

updateVisuals()

--========================================
-- RANDOM POINT
--========================================
local function getRandomPoint()
	local angle = math.random() * math.pi * 2
	local dist = math.random() * radius

	return homePosition + Vector3.new(
		math.cos(angle) * dist,
		0,
		math.sin(angle) * dist
	)
end

--========================================
-- PATHFINDING
--========================================
local function pathfindTo(target)

	if not humanoid or humanoid.Health <= 0 then
		return
	end

	local path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = true
	})

	local success = pcall(function()
		path:ComputeAsync(root.Position, target)
	end)

	if success and path.Status == Enum.PathStatus.Success then

		for _, waypoint in ipairs(path:GetWaypoints()) do

			if not running then
				return
			end

			if humanoid.Health <= 0 then
				return
			end

			humanoid:MoveTo(waypoint.Position)

			if waypoint.Action == Enum.PathWaypointAction.Jump then
				humanoid.Jump = true
			end

			humanoid.MoveToFinished:Wait(2)
		end

	else
		humanoid:MoveTo(target)
	end
end

--========================================
-- GUI
--========================================
local gui = Instance.new("ScreenGui")
gui.Parent = player.PlayerGui
gui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Parent = gui
frame.Size = UDim2.fromOffset(250,390)
frame.Position = UDim2.fromScale(0.03,0.25)
frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
frame.Active = true
frame.Draggable = true

Instance.new("UICorner", frame)

--========================================
-- TIMER BAR
--========================================
local timerBarBG = Instance.new("Frame")
timerBarBG.Parent = frame
timerBarBG.Size = UDim2.new(1,-16,0,18)
timerBarBG.Position = UDim2.fromOffset(8,340)
timerBarBG.BackgroundColor3 = Color3.fromRGB(40,40,40)

Instance.new("UICorner", timerBarBG)

local timerBar = Instance.new("Frame")
timerBar.Parent = timerBarBG
timerBar.Size = UDim2.new(0,0,1,0)
timerBar.BackgroundColor3 = Color3.fromRGB(0,255,100)

Instance.new("UICorner", timerBar)

local timerText = Instance.new("TextLabel")
timerText.Parent = frame
timerText.Size = UDim2.new(1,-16,0,20)
timerText.Position = UDim2.fromOffset(8,360)
timerText.BackgroundTransparency = 1
timerText.TextColor3 = Color3.new(1,1,1)
timerText.Font = Enum.Font.GothamBold
timerText.TextSize = 12
timerText.Text = "Walk Timer: --s"

--========================================
-- BUTTONS
--========================================
local function createButton(text,y)

	local b = Instance.new("TextButton")
	b.Parent = frame
	b.Size = UDim2.new(1,-16,0,30)
	b.Position = UDim2.fromOffset(8,y)
	b.BackgroundColor3 = Color3.fromRGB(35,35,35)
	b.TextColor3 = Color3.new(1,1,1)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 12
	b.Text = text

	Instance.new("UICorner", b)

	return b
end

local startBtn = createButton("Start",20)
local homeBtn = createButton("Set Home",58)
local modeBtn = createButton("Mode: Hybrid",96)
local randomBtn = createButton("Random Walk: ON",134)

--========================================
-- INPUT BOXES
--========================================
local function createBox(labelText,default,y)

	local label = Instance.new("TextLabel")
	label.Parent = frame
	label.Size = UDim2.new(1,-16,0,18)
	label.Position = UDim2.fromOffset(8,y)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1,1,1)
	label.Font = Enum.Font.Gotham
	label.TextSize = 12
	label.Text = labelText

	local box = Instance.new("TextBox")
	box.Parent = frame
	box.Size = UDim2.new(1,-16,0,24)
	box.Position = UDim2.fromOffset(8,y+18)
	box.BackgroundColor3 = Color3.fromRGB(30,30,30)
	box.TextColor3 = Color3.new(1,1,1)
	box.Font = Enum.Font.Gotham
	box.TextSize = 12
	box.Text = tostring(default)

	Instance.new("UICorner", box)

	return box
end

local radiusBox = createBox("Home Radius (studs)",radius,172)
local minBox = createBox("Min Walk Time (sec)",minWalkTime,218)
local maxBox = createBox("Max Walk Time (sec)",maxWalkTime,264)
local fixedBox = createBox("Fixed Walk Time (sec)",fixedWalkTime,310)

--========================================
-- INPUT VALIDATION
--========================================
local function numberOnly(box,fallback,callback)

	box.FocusLost:Connect(function()

		local n = tonumber(box.Text)

		if not n then
			n = fallback
		end

		box.Text = tostring(n)

		callback(n)
	end)
end

numberOnly(radiusBox,20,function(v)
	radius = math.max(5,v)
	updateVisuals()
end)

numberOnly(minBox,2,function(v)
	minWalkTime = math.max(1,v)
end)

numberOnly(maxBox,8,function(v)
	maxWalkTime = math.max(minWalkTime,v)
end)

numberOnly(fixedBox,5,function(v)
	fixedWalkTime = math.max(1,v)
end)

--========================================
-- WALK LOOP
--========================================
task.spawn(function()

	while true do

		if running and humanoid and humanoid.Health > 0 and mode ~= "Ping" then

			-- Return home if outside radius
			if (root.Position - homePosition).Magnitude > radius then

				pathfindTo(homePosition)

			else

				local walkDuration

				if randomWalk then
					walkDuration = math.random(minWalkTime,maxWalkTime)
				else
					walkDuration = fixedWalkTime
				end

				timerBar.Size = UDim2.new(0,0,1,0)

				local tween = TweenService:Create(
					timerBar,
					TweenInfo.new(walkDuration,Enum.EasingStyle.Linear),
					{Size = UDim2.new(1,0,1,0)}
				)

				tween:Play()

				timerText.Text = "Walking: "..walkDuration.."s"

				local target = getRandomPoint()

				humanoid:MoveTo(target)

				local startTime = tick()

				while tick() - startTime < walkDuration do

					if not running then
						break
					end

					if humanoid.Health <= 0 then
						break
					end

					-- Re-issue movement if interrupted
					if humanoid.MoveDirection.Magnitude == 0 then
						humanoid:MoveTo(target)
					end

					task.wait(0.25)
				end

				tween:Cancel()
			end

		else

			timerBar.Size = UDim2.new(0,0,1,0)
			timerText.Text = "Walk Timer: --s"

		end

		task.wait(0.2)
	end
end)

--========================================
-- ANTI AFK
--========================================
player.Idled:Connect(function()

	if running or mode == "Ping" or mode == "Hybrid" then

		VirtualUser:Button2Down(
			Vector2.new(0,0),
			workspace.CurrentCamera.CFrame
		)

		task.wait(0.1)

		VirtualUser:Button2Up(
			Vector2.new(0,0),
			workspace.CurrentCamera.CFrame
		)
	end

end)

RunService.Heartbeat:Connect(function(dt)

	if mode ~= "Ping" and mode ~= "Hybrid" then
		return
	end

	if not humanoid or humanoid.Health <= 0 then
		return
	end

	pingCooldown -= dt

	if pingCooldown > 0 then
		return
	end

	pingCooldown = pingInterval

	-- Virtual click
	pcall(function()

		VirtualUser:Button2Down(
			Vector2.new(0,0),
			workspace.CurrentCamera.CFrame
		)

		task.wait(0.05)

		VirtualUser:Button2Up(
			Vector2.new(0,0),
			workspace.CurrentCamera.CFrame
		)

	end)

	-- Camera nudge
	pcall(function()

		local cam = workspace.CurrentCamera
		local cf = cam.CFrame

		cam.CFrame = cf * CFrame.Angles(0,0.0001,0)

		task.wait(0.03)

		cam.CFrame = cf

	end)

	-- Fake keypress
	pcall(function()

		VirtualUser:KeyDown(string.char(0))

		task.wait(0.05)

		VirtualUser:KeyUp(string.char(0))

	end)

end)

--========================================
-- BUTTONS
--========================================
startBtn.MouseButton1Click:Connect(function()

	running = not running

	startBtn.Text = running and "Stop" or "Start"

end)

homeBtn.MouseButton1Click:Connect(function()

	if root then
		homePosition = root.Position
		updateVisuals()
	end

end)

modeBtn.MouseButton1Click:Connect(function()

	if mode == "Walk" then
		mode = "Ping"

	elseif mode == "Ping" then
		mode = "Hybrid"

	else
		mode = "Walk"
	end

	modeBtn.Text = "Mode: "..mode

end)

randomBtn.MouseButton1Click:Connect(function()

	randomWalk = not randomWalk

	randomBtn.Text =
		randomWalk
		and "Random Walk: ON"
		or "Random Walk: OFF"

end)

--========================================
-- UI TOGGLE
--========================================
UserInputService.InputBegan:Connect(function(input,gp)

	if gp then
		return
	end

	if input.KeyCode == Enum.KeyCode.L then
		gui.Enabled = not gui.Enabled
	end

end)

print("Advanced Anti-AFK Walker Loaded")
