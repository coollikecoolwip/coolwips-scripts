local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Root = Character:WaitForChild("HumanoidRootPart")

local holdingJump = false
local wasOnGround = true
local jumpBufferTime = 0.2
local jumpTime = 0

-- Coyote Frames
local function canCoyoteJump()
	return tick() - jumpTime <= jumpBufferTime
end

-- Predict landing point
local function getLandingPosition()
	local velocity = Root.Velocity
	local time = (velocity.Y < 0) and (math.abs(Root.Position.Y) / math.abs(velocity.Y)) or 0.5
	local projectedPosition = Root.Position + (velocity * time)
	return projectedPosition
end

-- Check if underfoot is a ledge and close to landing
local function ledgeCheck()
	local ray = RaycastParams.new()
	ray.FilterType = Enum.RaycastFilterType.Blacklist
	ray.FilterDescendantsInstances = {Character}
	local result = workspace:Raycast(Root.Position, Vector3.new(0, -3, 0), ray)
	return result
end

-- Check wall proximity
local function isNearWall()
	local ray = RaycastParams.new()
	ray.FilterType = Enum.RaycastFilterType.Blacklist
	ray.FilterDescendantsInstances = {Character}
	local forward = Root.CFrame.LookVector * 1.2
	local result = workspace:Raycast(Root.Position, forward, ray)
	return result
end

-- Fake jump by setting velocity
local function fakeJump()
	Root.Velocity = Vector3.new(Root.Velocity.X, 50, Root.Velocity.Z)
end

-- Add invisible landing platform
local function createGhostPlatform(pos)
	local part = Instance.new("Part")
	part.Size = Vector3.new(5, 0.1, 5)
	part.Anchored = true
	part.CanCollide = true
	part.Transparency = 1
	part.Position = pos + Vector3.new(0, 0.5, 0)
	part.Name = "GhostPlatform"
	part.Parent = workspace
	game.Debris:AddItem(part, 2)
end

-- Detect spam jumping and clip through wall
local jumpHistory = {}
local function detectSpamClip()
	table.insert(jumpHistory, tick())
	if #jumpHistory > 10 then table.remove(jumpHistory, 1) end

	local spam = 0
	for i = 2, #jumpHistory do
		if jumpHistory[i] - jumpHistory[i - 1] < 0.3 then
			spam += 1
		end
	end

	if spam >= 5 and isNearWall() then
		print("Wall Clipping Triggered")
		Root.CFrame = Root.CFrame + Root.CFrame.LookVector * 1.5
	end
end

-- Input handler
UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Space then
		if wasOnGround then
			jumpTime = tick()
		else
			if canCoyoteJump() then
				print("Coyote jump!")
				fakeJump()
			else
				print("Jump attempted in air.")
				fakeJump()
			end
		end
		holdingJump = true
		detectSpamClip()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Space then
		holdingJump = false
	end
end)

RunService.RenderStepped:Connect(function()
	if Humanoid.FloorMaterial ~= Enum.Material.Air then
		wasOnGround = true
	else
		wasOnGround = false
	end

	if holdingJump then
		local result = ledgeCheck()
		if result and result.Position.Y - Root.Position.Y <= -2.5 then
			print("Near ledge, faking jump")
			fakeJump()
		end

		local projected = getLandingPosition()
		local result = workspace:Raycast(projected, Vector3.new(0, -3, 0))
		if not result then
			print("About to miss ledge, placing ghost platform")
			createGhostPlatform(projected)
		end
	end
end)
