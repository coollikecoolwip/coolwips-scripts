--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

--// ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MiniMap"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

--// Minimap Settings
local INITIAL_SIZE = 200
local MIN_SIZE = 120
local MAX_SIZE = 420

local mapSize = INITIAL_SIZE
local zoom = 0.2
local zoomStep = 0.08
local sizeStep = 40

--// Dragging
local dragging = false
local dragOffset = Vector2.zero

--// Frame
local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(mapSize, mapSize)
frame.Position = UDim2.fromOffset(20, 20)
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 0
frame.ClipsDescendants = true
frame.Parent = screenGui

-- Rounded corners
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 16)
corner.Parent = frame

--// Player Arrow
local arrow = Instance.new("ImageLabel")
arrow.Name = "Arrow"
arrow.Size = UDim2.fromOffset(22, 22)
arrow.Position = UDim2.fromScale(0.5, 0.5)
arrow.AnchorPoint = Vector2.new(0.5, 0.5)
arrow.BackgroundTransparency = 1
arrow.Image = "rbxassetid://6031090990" -- Default arrow image
arrow.ImageColor3 = Color3.fromRGB(0, 255, 0)
arrow.ZIndex = 2
arrow.Parent = frame

--// Resize Helpers
local function ApplyResize()
	frame.Size = UDim2.fromOffset(mapSize, mapSize)
end

local function Enlarge()
	if mapSize < MAX_SIZE then
		mapSize = math.min(mapSize + sizeStep, MAX_SIZE)
		zoom = math.max(zoom - zoomStep, 0.05)
		ApplyResize()
	end
end

local function Shrink()
	if mapSize > MIN_SIZE then
		mapSize = math.max(mapSize - sizeStep, MIN_SIZE)
		zoom = math.min(zoom + zoomStep, 0.9)
		ApplyResize()
	end
end

--// Input Handling
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end

	if input.KeyCode == Enum.KeyCode.Equals then
		Enlarge()
	elseif input.KeyCode == Enum.KeyCode.Minus then
		Shrink()
	elseif input.KeyCode == Enum.KeyCode.M then
		screenGui.Enabled = not screenGui.Enabled
	end

	-- Start dragging
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local mousePos = input.Position
		local absPos = frame.AbsolutePosition
		local absSize = frame.AbsoluteSize

		if mousePos.X >= absPos.X and mousePos.X <= absPos.X + absSize.X
		and mousePos.Y >= absPos.Y and mousePos.Y <= absPos.Y + absSize.Y then
			dragging = true
			dragOffset = mousePos - absPos
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		frame.Position = UDim2.fromOffset(
			input.Position.X - dragOffset.X,
			input.Position.Y - dragOffset.Y
		)
	end
end)

--// Render Loop
RunService.RenderStepped:Connect(function()
	-- Clear old dots
	for _, child in ipairs(frame:GetChildren()) do
		if child:IsA("Frame") and child.Name == "Dot" then
			child:Destroy()
		end
	end

	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local myPos = hrp.Position
	local lookVector = hrp.CFrame.LookVector
	local yaw = math.deg(math.atan2(lookVector.X, lookVector.Z))

	-- Corrected rotation: Invert yaw to align visual rotation with player turning [AI KNOWLEDGE]({})
	arrow.Rotation = -yaw -- [AI KNOWLEDGE]({})

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer
			and player.Character
			and player.Character:FindFirstChild("HumanoidRootPart") then

			local pos = player.Character.HumanoidRootPart.Position
			local offset = (pos - myPos) * zoom

			local x = mapSize / 2 + offset.X
			local y = mapSize / 2 - offset.Z

			if x >= 0 and x <= mapSize and y >= 0 and y <= mapSize then
				local dot = Instance.new("Frame")
				dot.Name = "Dot"
				dot.Size = UDim2.fromOffset(5, 5)
				dot.Position = UDim2.fromOffset(x - 2, y - 2)
				dot.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
				dot.BorderSizePixel = 0
				dot.Parent = frame
			end
		end
	end
end)
