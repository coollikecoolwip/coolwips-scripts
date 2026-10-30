-- Advanced Movement Assist Script (Wallhops, Coyote Frames, Jump Prediction, Ledge Rescue, Clip)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HRP = Character:WaitForChild("HumanoidRootPart")

local lastGroundTime = tick()
local lastJumpAttempt = 0
local coyoteTime = 0.2
local grounded = true
local wallClipCooldown = 0
local spamJumpData = {}

local function isGrounded()
	local ray = RaycastParams.new()
	ray.FilterType = Enum.RaycastFilterType.Blacklist
	ray.FilterDescendantsInstances = {Character}
	local result = workspace:Raycast(HRP.Position, Vector3.new(0, -3, 0), ray)
	return result and result.Position
end

local function simulateJumpVelocity()
	local gravity = workspace.Gravity
	local jumpPower = Humanoid.JumpPower
	local velocityY = jumpPower
	return Vector3.new(HRP.Velocity.X, velocityY, HRP.Velocity.Z)
end

local function predictLanding(velocity)
	local simPos = HRP.Position
	local simVel = velocity
	local dt = 0.05
	for i = 1, 60 do
		simVel = simVel + Vector3.new(0, -workspace.Gravity * dt, 0)
		simPos = simPos + simVel * dt
		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = {Character}
		rayParams.FilterType = Enum.RaycastFilterType.Blacklist
		local result = workspace:Raycast(simPos, Vector3.new(0, -2, 0), rayParams)
		if result then
			return result.Position
		end
	end
end

local function placeSafetyPlatform(pos)
	local platform = Instance.new("Part")
	platform.Size = Vector3.new(2.5, 0.2, 2.5)
	platform.Anchored = true
	platform.CanCollide = true
	platform.Transparency = 1
	platform.CFrame = CFrame.new(pos + Vector3.new(0, 0.1, 0))
	platform.Parent = workspace

	task.delay(1.5, function()
		platform:Destroy()
	end)
end

local function tryPlaceLedgeGrab()
	local ray = RaycastParams.new()
	ray.FilterDescendantsInstances = {Character}
	ray.FilterType = Enum.RaycastFilterType.Blacklist
	local result = workspace:Raycast(HRP.Position, Vector3.new(0, -5, 0), ray)
	if result and result.Instance and result.Instance:IsA("TrussPart") then
		local ghostTruss = result.Instance:Clone()
		ghostTruss.Transparency = 1
		ghostTruss.Parent = workspace
		ghostTruss.CFrame = result.Instance.CFrame

		task.spawn(function()
			for i = 1, 20 do
				ghostTruss.Size = ghostTruss.Size - Vector3.new(0.1, 0, 0.1)
				task.wait(0.05)
			end
			ghostTruss:Destroy()
		end)
	end
end

local function checkWallClip()
	if tick() - wallClipCooldown < 2 then return end
	local recent = spamJumpData
	if #recent < 15 then return end
	local movement = (HRP.Position - recent[1]).Magnitude
	if movement < 3 then
		local delta = math.abs(HRP.CFrame.LookVector.X) + math.abs(HRP.CFrame.LookVector.Z)
		if delta > 1.5 then
			local ray = RaycastParams.new()
			ray.FilterDescendantsInstances = {Character}
			ray.FilterType = Enum.RaycastFilterType.Blacklist
			local result = workspace:Raycast(HRP.Position, HRP.CFrame.LookVector * 2, ray)
			if result and result.Instance then
				local offset = HRP.CFrame.LookVector * 1.3
				HRP.CFrame = HRP.CFrame + offset
				wallClipCooldown = tick()
			end
		end
	end
end

UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Space then
		lastJumpAttempt = tick()

		if not grounded and tick() - lastGroundTime < coyoteTime then
			Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		else
			-- Precise wallhop: instant jump
			Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
end)

RunService.RenderStepped:Connect(function()
	if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end

	-- Record spam jump position
	table.insert(spamJumpData, HRP.Position)
	if #spamJumpData > 40 then
		table.remove(spamJumpData, 1)
	end

	-- Coyote check
	if isGrounded() then
		lastGroundTime = tick()
		grounded = true
	else
		grounded = false
	end

	-- Predict missed jumps
	local predicted = predictLanding(simulateJumpVelocity())
	if predicted then
		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = {Character}
		rayParams.FilterType = Enum.RaycastFilterType.Blacklist
		local check = workspace:Raycast(predicted + Vector3.new(0, 2, 0), Vector3.new(0, -4, 0), rayParams)
		if not check then
			placeSafetyPlatform(predicted)
		end
	end

	tryPlaceLedgeGrab()
	checkWallClip()
end)
