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

local function canCoyoteJump()
	return tick() - jumpTime <= jumpBufferTime
end

local function getLandingPosition()
	local velocity = Root.Velocity
	local time = (velocity.Y < 0) and (math.abs(Root.Position.Y) / math.abs(velocity.Y)) or 0.5
	local projectedPosition = Root.Position + (velocity * time)
	return projectedPosition
end

local function ledgeCheck()
	local ray = RaycastParams.new()
	ray.FilterType = Enum.RaycastFilterType.Blacklist
	ray.FilterDescendantsInstances = {Character}
	local result = workspace:Raycast(Root.Position, Vector3.new(0, -3, 0), ray)
	return result
end

local function isNearWall()
	local ray = RaycastParams.new()
	ray.FilterType = Enum.RaycastFilterType.Blacklist
	ray.FilterDescendantsInstances = {Character}
	local forward = Root.CFrame.LookVector * 1.2
	local result = workspace:Raycast(Root.Position, forward, ray)
	return result
end

local function fakeJump()
	Root.Velocity = Vector3.new(Root.Velocity.X, 50, Root.Velocity.Z)
end

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
		Root.CFrame = Root.CFrame + Root.CFrame.LookVector * 1.5
	end
end

UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Space then
		if wasOnGround then
			jumpTime = tick()
		else
			if canCoyoteJump() then
				fakeJump()
			else
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
			fakeJump()
		end
		local projected = getLandingPosition()
		local result = workspace:Raycast(projected, Vector3.new(0, -3, 0))
		if not result then
			createGhostPlatform(projected)
		end
	end
end)
