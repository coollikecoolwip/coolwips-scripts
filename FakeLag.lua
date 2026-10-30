local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local rng = Random.new()

local CONFIG = {
	FreezeMin = 0.4,
	FreezeMax = 1.8,
	CooldownMin = 3,
	CooldownMax = 7,

	JumpEnabled = true,
	JumpMin = 3,
	JumpMax = 14,

	ToggleKey = Enum.KeyCode.F6,
}

local GUI_NAME = "FakeLagSimulator"

-- Re-running this script cleans up the previous instance.
local playerGui = player:WaitForChild("PlayerGui")
local previousGui = playerGui:FindFirstChild(GUI_NAME)
if previousGui then
	previousGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = GUI_NAME
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local button = Instance.new("TextButton")
button.Name = "Toggle"
button.AnchorPoint = Vector2.new(1, 1)
button.Position = UDim2.new(1, -20, 1, -24)
button.Size = UDim2.fromOffset(210, 48)
button.BackgroundColor3 = Color3.fromRGB(45, 48, 58)
button.TextColor3 = Color3.new(1, 1, 1)
button.Font = Enum.Font.GothamSemibold
button.TextSize = 15
button.AutoButtonColor = true
button.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = button

local enabled = false
local destroyed = false
local active = nil
local nextFreeze = 0
local connections = {}

local function updateButton()
	if not enabled then
		button.Text = "Fake Lag: OFF • F6"
		button.BackgroundColor3 = Color3.fromRGB(45, 48, 58)
	elseif active then
		button.Text = "Fake Lag: FROZEN"
		button.BackgroundColor3 = Color3.fromRGB(175, 95, 35)
	else
		button.Text = "Fake Lag: ON • F6"
		button.BackgroundColor3 = Color3.fromRGB(35, 125, 90)
	end
end

local function scheduleNext()
	nextFreeze = os.clock()
		+ rng:NextNumber(CONFIG.CooldownMin, CONFIG.CooldownMax)
end

local function getCharacter()
	local character = player.Character
	if not character or not character.Parent then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not root or not root:IsA("BasePart") then
		return
	end

	if humanoid.Health <= 0 then
		return
	end

	return character, humanoid, root
end

local function getJumpOffset(state)
	if not CONFIG.JumpEnabled then
		return Vector3.zero
	end

	local root = state.root
	local humanoid = state.humanoid

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { state.character }
	params.RespectCanCollide = true
	params.CollisionGroup = root.CollisionGroup

	-- Try a few directions; stay in place if none is suitable.
	for _ = 1, 6 do
		local angle = rng:NextNumber(0, math.pi * 2)
		local distance = rng:NextNumber(CONFIG.JumpMin, CONFIG.JumpMax)
		local offset = Vector3.new(
			math.cos(angle) * distance,
			0,
			math.sin(angle) * distance
		)

		local obstruction = workspace:Blockcast(
			root.CFrame,
			root.Size + Vector3.new(1, 0, 1),
			offset,
			params
		)

		if not obstruction then
			local destination = root.Position + offset
			local footDistance = humanoid.HipHeight + root.Size.Y / 2

			local ground = workspace:Raycast(
				destination,
				Vector3.new(0, -(footDistance + 2), 0),
				params
			)

			if ground and ground.Normal.Y >= 0.7 then
				return offset
			end
		end
	end

	return Vector3.zero
end

local function releaseFreeze(allowJump)
	local state = active
	active = nil

	if not state then
		return
	end

	-- Always restore anchoring, even if movement checks fail.
	local success, message = pcall(function()
		local stillValid =
			state.character == player.Character
			and state.character.Parent ~= nil
			and state.root:IsDescendantOf(state.character)
			and state.humanoid.Health > 0

		if allowJump and stillValid then
			local offset = getJumpOffset(state)
			if offset.Magnitude > 0 then
				state.character:PivotTo(
					state.character:GetPivot() + offset
				)
			end
		end
	end)

	if state.root.Parent then
		state.root.Anchored = state.wasAnchored

		-- Prevent stored momentum from flinging the character.
		if not state.wasAnchored then
			state.root.AssemblyLinearVelocity = Vector3.zero
			state.root.AssemblyAngularVelocity = Vector3.zero
		end
	end

	if not success then
		warn("Fake lag movement skipped:", message)
	end
end

local function toggle()
	if destroyed then
		return
	end

	enabled = not enabled

	if enabled then
		scheduleNext()
	else
		releaseFreeze(false)
	end

	updateButton()
end

table.insert(connections, button.Activated:Connect(toggle))

table.insert(connections, UserInputService.InputBegan:Connect(
	function(input, processed)
		if processed or UserInputService:GetFocusedTextBox() then
			return
		end

		if input.KeyCode == CONFIG.ToggleKey then
			toggle()
		end
	end
))

table.insert(connections, player.CharacterRemoving:Connect(function()
	releaseFreeze(false)
	scheduleNext()
	updateButton()
end))

table.insert(connections, RunService.Heartbeat:Connect(function()
	if destroyed or not enabled then
		return
	end

	local now = os.clock()

	if active then
		local invalid =
			player.Character ~= active.character
			or not active.root:IsDescendantOf(workspace)
			or active.humanoid.Health <= 0
			or active.humanoid.SeatPart ~= nil

		if invalid or now >= active.endsAt then
			releaseFreeze(not invalid)
			scheduleNext()
			updateButton()
		end

		return
	end

	if now < nextFreeze then
		return
	end

	local character, humanoid, root = getCharacter()
	if not character then
		return
	end

	-- Avoid interfering with seats, existing anchors, or airborne movement.
	if root.Anchored
		or humanoid.SeatPart
		or humanoid.FloorMaterial == Enum.Material.Air
	then
		return
	end

	active = {
		character = character,
		humanoid = humanoid,
		root = root,
		wasAnchored = root.Anchored,
		endsAt = now + rng:NextNumber(CONFIG.FreezeMin, CONFIG.FreezeMax),
	}

	root.Anchored = true
	updateButton()
end))

local function cleanup()
	if destroyed then
		return
	end

	destroyed = true
	enabled = false
	releaseFreeze(false)

	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
end

gui.Destroying:Connect(cleanup)
script.Destroying:Connect(function()
	cleanup()
	if gui.Parent then
		gui:Destroy()
	end
end)

updateButton()
