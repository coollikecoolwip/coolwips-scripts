--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService") -- Service for input handling

local LocalPlayer = Players.LocalPlayer

--// ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MiniMap"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

--// Minimap Settings
local INITIAL_SIZE = 200 -- Starting size of the minimap
local MIN_SIZE = 80   -- Minimum size
local MAX_SIZE = 500   -- Maximum size

local mapSize = INITIAL_SIZE
local zoom = 0.2
local zoomStep = 0.08
local sizeStep = 40

--// Dragging Variables
local dragging = false
local dragOffset = Vector2.zero

--// Frame
local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(mapSize, mapSize)
frame.Position = UDim2.fromOffset(20, 20) -- Initial position
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35) -- Darker background for better contrast
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 0
frame.ClipsDescendants = true
frame.Parent = screenGui

-- Rounded corners for a softer UI look
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 16) -- Adjust corner radius as needed
corner.Parent = frame

--// Player Arrow
local arrow = Instance.new("ImageLabel")
arrow.Name = "Arrow"
-- Modified size for a longer arrow
arrow.Size = UDim2.fromOffset(30, 30) -- Increased size to make it longer [AI KNOWLEDGE]({})
arrow.Position = UDim2.fromScale(0.5, 0.5) -- Centered
arrow.AnchorPoint = Vector2.new(0.5, 0.5) -- Anchor to center for rotation
arrow.BackgroundTransparency = 1
arrow.Image = "rbxassetid://6031090990" -- Default arrow image
arrow.ImageColor3 = Color3.fromRGB(0, 255, 0) -- Green color for player
arrow.ZIndex = 2
arrow.Parent = frame

--// Resize Functions
local function ApplyResize()
	frame.Size = UDim2.fromOffset(mapSize, mapSize)
end

local function Enlarge()
	if mapSize < MAX_SIZE then
		mapSize = math.min(mapSize + sizeStep, MAX_SIZE)
		zoom = math.max(zoom - zoomStep, 0.05) -- Zoom out as map gets larger
		ApplyResize()
	end
end

local function Shrink()
	if mapSize > MIN_SIZE then
		mapSize = math.max(mapSize - sizeStep, MIN_SIZE)
		zoom = math.min(zoom + zoomStep, 0.9) -- Zoom in as map gets smaller
		ApplyResize()
	end
end

--// Input Handling
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end -- Ignore input if it's already processed by Roblox UI

	-- Minimap Toggling and Resizing
	if input.KeyCode == Enum.KeyCode.M then
		screenGui.Enabled = not screenGui.Enabled -- Toggle minimap visibility
	elseif input.KeyCode == Enum.KeyCode.Equals then
		Enlarge() -- Increase size with '=' key
	elseif input.KeyCode == Enum.KeyCode.Minus then
		Shrink() -- Decrease size with '-' key
	end

	-- Start dragging the minimap
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local mousePos = input.Position
		local absPos = frame.AbsolutePosition
		local absSize = frame.AbsoluteSize

		-- Check if the click is within the minimap's bounds
		if mousePos.X >= absPos.X and mousePos.X <= absPos.X + absSize.X
		and mousePos.Y >= absPos.Y and mousePos.Y <= absPos.Y + absSize.Y then
			dragging = true
			dragOffset = mousePos - absPos -- Calculate the offset from the mouse click to the frame's top-left corner
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false -- Stop dragging when the mouse button is released
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		-- Update the frame's position based on mouse movement and the initial drag offset
		frame.Position = UDim2.fromOffset(
			input.Position.X - dragOffset.X,
			input.Position.Y - dragOffset.Y
		)
	end
end)

--// Render Loop for Dynamic Updates
RunService.RenderStepped:Connect(function()
	-- Clear previous player dots to prevent overlap and performance issues
	for _, child in ipairs(frame:GetChildren()) do
		if child:IsA("Frame") and child.Name == "Dot" then
			child:Destroy()
		end
	end

	-- Get local player's character and HumanoidRootPart
	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end -- Exit if character or HRP is not found [T0](1)

	local myPos = hrp.Position
	local lookVector = hrp.CFrame.LookVector
	-- Calculate yaw (rotation around the Y-axis) in degrees [T0](1)
	local yaw = math.deg(math.atan2(lookVector.X, lookVector.Z))

	-- Reverted to original rotation logic as per request
	arrow.Rotation = yaw -- This is the original rotation logic from [T1](2)

	-- Draw dots for other players
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local pos = player.Character.HumanoidRootPart.Position
			-- Calculate the offset relative to the local player, scaled by zoom
			local offset = (pos - myPos) * zoom
			-- Convert 3D world offset to 2D minimap coordinates
			local x = mapSize / 2 + offset.X
			local y = mapSize / 2 - offset.Z -- Z-axis in Roblox often maps to Y on 2D screens [T1](2)

			-- Only draw dots that are within the minimap bounds
			if x >= 0 and x <= mapSize and y >= 0 and y <= mapSize then
				local dot = Instance.new("Frame")
				dot.Name = "Dot"
				dot.Size = UDim2.fromOffset(5, 5) -- Small size for player dots
				-- Position the dot, offsetting by -2 to center it on the calculated coordinates
				dot.Position = UDim2.fromOffset(x - 2, y - 2)
				dot.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Red color for other players [T1](2)
				dot.BorderSizePixel = 0
				dot.Parent = frame
			end
		end
	end
end)
