local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MiniMap"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local mapSize = 200
local zoom = 0.2

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, mapSize, 0, mapSize)
frame.Position = UDim2.new(0, 20, 0, 20)
frame.BackgroundTransparency = 0.3
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame.BorderSizePixel = 0
frame.ClipsDescendants = true
frame.Parent = screenGui

local arrow = Instance.new("ImageLabel")
arrow.Name = "SelfArrow"
arrow.Size = UDim2.new(0, 20, 0, 20)
arrow.Position = UDim2.new(0.5, -10, 0.5, -10)
arrow.Image = "rbxassetid://6031090990"
arrow.ImageColor3 = Color3.fromRGB(0, 255, 0)
arrow.BackgroundTransparency = 1
arrow.ZIndex = 2
arrow.Parent = frame

RunService.RenderStepped:Connect(function()
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

	arrow.Rotation = yaw

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local pos = player.Character.HumanoidRootPart.Position
			local offset = (pos - myPos) * zoom
			local x = mapSize / 2 + offset.X
			local y = mapSize / 2 - offset.Z

			if x >= 0 and x <= mapSize and y >= 0 and y <= mapSize then
				local dot = Instance.new("Frame")
				dot.Name = "Dot"
				dot.Size = UDim2.new(0, 5, 0, 5)
				dot.Position = UDim2.new(0, x - 2, 0, y - 2)
				dot.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
				dot.BorderSizePixel = 0
				dot.Parent = frame
			end
		end
	end
end)
