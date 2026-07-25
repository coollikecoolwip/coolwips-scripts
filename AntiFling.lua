-- Anti-Fling (Everyone) + draggable top-right GUI
-- Xeno-compatible GUI parenting fallback.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local ENABLED = true
local CONNECTIONS = {}

-- === Anti-Fling Function ===
local function applyAntiFling(character)
	if not ENABLED or not character then
		return
	end

	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.AssemblyLinearVelocity = Vector3.zero
			part.AssemblyAngularVelocity = Vector3.zero
		end
	end
end

-- === Reset Collisions Function ===
local function resetAllCollisions()
	for _, plr in ipairs(Players:GetPlayers()) do
		local character = plr.Character
		if character then
			for _, part in ipairs(character:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = true
				end
			end
		end
	end
end

-- === Setup Player ===
local function setupPlayer(player)
	if player.Character then
		applyAntiFling(player.Character)
	end

	local connection = player.CharacterAdded:Connect(function(character)
		task.wait(0.3)
		applyAntiFling(character)
	end)

	table.insert(CONNECTIONS, connection)
end

-- Existing players
for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

-- New players
Players.PlayerAdded:Connect(setupPlayer)

-- === 5-second safety check ===
task.spawn(function()
	while task.wait(5) do
		if not ENABLED then
			-- Skip the rest of the loop iteration if disabled
			continue
		end
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr.Character then
				applyAntiFling(plr.Character)
			end
		end
	end
end)

-- === GUI ===
-- Prefer gethui() for Xeno; fall back to CoreGui if unavailable.
local guiParent = game:GetService("CoreGui")
if typeof(gethui) == "function" then
	local success, hui = pcall(gethui)
	if success and hui then
		guiParent = hui
	end
end

-- Remove any existing GUI to prevent duplicates
local oldGui = guiParent:FindFirstChild("AntiFlingGUI")
if oldGui then
	oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "AntiFlingGUI"
gui.ResetOnSpawn = false -- Important: Don't reset GUI on respawn
gui.IgnoreGuiInset = true -- This ensures the GUI is placed relative to the screen's top-left corner, not considering any in-game UI insets.
gui.Parent = guiParent

local frame = Instance.new("Frame")
frame.Name = "MainFrame"
frame.Size = UDim2.fromOffset(190, 110)
frame.AnchorPoint = Vector2.new(1, 0) -- Anchor to the top-right of the frame itself
frame.Position = UDim2.new(1, -20, 0, 20) -- Position the anchored point to the top-right of the screen (100% width, 0% height, with a small offset)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Active = true -- Makes the frame clickable and interactable
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

-- Manual dragging works consistently across executors and supports touch.
local dragging = false
local dragStart
local startPosition
local dragInput

frame.InputBegan:Connect(function(input)
	-- Check for left mouse button click or touch input
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position -- Record the initial input position
		startPosition = frame.Position -- Record the initial frame position

		-- Listen for the input to end
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

-- Store the input that is currently being used for dragging
frame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

-- Update the frame's position based on mouse/touch movement
UserInputService.InputChanged:Connect(function(input)
	if dragging and input == dragInput then
		local delta = input.Position - dragStart -- Calculate the difference in position
		frame.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)
	end
end)

-- === Toggle Button ===
local toggle = Instance.new("TextButton", frame)
toggle.Size = UDim2.new(1, -10, 0.5, -8) -- Occupies the top half with some padding
toggle.Position = UDim2.fromOffset(5, 5)
toggle.TextScaled = true
toggle.Font = Enum.Font.SourceSansBold
toggle.TextColor3 = Color3.new(1, 1, 1) -- White text
toggle.BorderSizePixel = 0
toggle.Parent = frame

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 6)
toggleCorner.Parent = toggle

local function updateToggleButton()
	toggle.Text = ENABLED and "Anti-Fling: ON" or "Anti-Fling: OFF"
	toggle.BackgroundColor3 = ENABLED
		and Color3.fromRGB(50, 170, 70) -- Green when ON
		or Color3.fromRGB(170, 50, 50) -- Red when OFF
end

toggle.MouseButton1Click:Connect(function()
	ENABLED = not ENABLED
	updateToggleButton()

	-- Apply current state immediately if turning ON
	if ENABLED then
		for _, player in ipairs(Players:GetPlayers()) do
			if player.Character then
				applyAntiFling(player.Character)
			end
		end
	end
end)

-- === Reset Button ===
local resetButton = Instance.new("TextButton", frame)
resetButton.Size = UDim2.new(1, -10, 0.5, -8) -- Occupies the bottom half with some padding
resetButton.Position = UDim2.new(0, 5, 0.5, 3)
resetButton.Text = "Reset Collisions"
resetButton.TextScaled = true
resetButton.Font = Enum.Font.SourceSansBold
resetButton.TextColor3 = Color3.new(1, 1, 1) -- White text
resetButton.BackgroundColor3 = Color3.fromRGB(80, 100, 170) -- Blueish color
resetButton.BorderSizePixel = 0
resetButton.Parent = frame

local resetCorner = Instance.new("UICorner")
resetCorner.CornerRadius = UDim.new(0, 6)
resetCorner.Parent = resetButton

resetButton.MouseButton1Click:Connect(function()
	resetAllCollisions() -- Call the function to reset collisions
	-- Optionally, re-enable anti-fling after reset if it was off
	-- This would mean uncommenting the lines below and ensuring `ENABLED` is correctly managed.
	-- ENABLED = true
	-- updateToggleButton()
end)

updateToggleButton() -- Initialize the button text and color
