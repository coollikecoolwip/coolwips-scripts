-- Anti-Fling (Everyone) + GUI with Reset Button
-- Executor-agnostic LocalScript

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local ENABLED = true
local CONNECTIONS = {}

-- === Anti-Fling Function ===
local function applyAntiFling(character)
	if not ENABLED or not character then return end

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
		if plr.Character then
			for _, part in ipairs(plr.Character:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = true -- Re-enable collision
				end
			end
		end
	end
end

-- === Setup Player ===
local function setupPlayer(player)
	-- Apply immediately on join/setup
	if player.Character then
		applyAntiFling(player.Character)
	end

	-- Re-apply on respawn
	local conn = player.CharacterAdded:Connect(function(char)
		task.wait(0.3)
		applyAntiFling(char)
	end)

	table.insert(CONNECTIONS, conn)
end

-- Existing players
for _, plr in ipairs(Players:GetPlayers()) do
	setupPlayer(plr)
end

-- New players
Players.PlayerAdded:Connect(setupPlayer)

-- === 5-second safety check ===
task.spawn(function()
	while task.wait(5) do
		if not ENABLED then continue end
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr.Character then
				applyAntiFling(plr.Character)
			end
		end
	end
end)

-- === GUI ===
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "AntiFlingGUI"
gui.ResetOnSpawn = false -- Important: Don't reset GUI on respawn

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 170, 0, 100) -- Slightly larger frame
frame.Position = UDim2.fromOffset(20, 200)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Active = true
frame.Draggable = true

-- === Toggle Button ===
local toggle = Instance.new("TextButton", frame)
toggle.Size = UDim2.new(1, 0, 0.5, 0) -- Takes top half of the frame
toggle.Position = UDim2.new(0, 0, 0, 0)
toggle.TextScaled = true
toggle.Font = Enum.Font.SourceSansBold

local function updateToggleButton()
	toggle.Text = ENABLED and "Anti-Fling: ON" or "Anti-Fling: OFF"
	toggle.BackgroundColor3 = ENABLED and Color3.fromRGB(50, 170, 70)
		or Color3.fromRGB(170, 50, 50)
end

toggle.MouseButton1Click:Connect(function()
	ENABLED = not ENABLED
	updateToggleButton()
	-- Apply current state immediately to self and others if turning ON
	if ENABLED then
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr.Character then
				applyAntiFling(plr.Character)
			end
		end
	end
end)

-- === Reset Button ===
local resetButton = Instance.new("TextButton", frame)
resetButton.Size = UDim2.new(1, 0, 0.5, 0) -- Takes bottom half of the frame
resetButton.Position = UDim2.new(0, 0, 0.5, 0)
resetButton.Text = "Reset Collisions"
resetButton.TextScaled = true
resetButton.Font = Enum.Font.SourceSansBold
resetButton.BackgroundColor3 = Color3.fromRGB(80, 100, 170)

resetButton.MouseButton1Click:Connect(function()
	resetAllCollisions()
	-- Optionally, re-enable anti-fling after reset if it was off
	-- ENABLED = true
	-- updateToggleButton()
end)

updateToggleButton() -- Initialize button text
