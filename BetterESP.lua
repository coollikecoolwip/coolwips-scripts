local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- Toggles
local espEnabled = true
local healthEnabled = false

local processed = {}
local queue = {}

-- GUI Setup
local gui = Instance.new("ScreenGui")
gui.Name = "UniversalESP"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Container for dragging buttons
local container = Instance.new("Frame", gui)
container.BackgroundTransparency = 1
container.Size = UDim2.new(0, 200, 0, 90)
container.Position = UDim2.new(0, 10, 0, 10)
container.Active = true
container.Draggable = true

local toggleBtn = Instance.new("TextButton", container)
toggleBtn.Size = UDim2.new(0, 150, 0, 30)
toggleBtn.Position = UDim2.new(0, 0, 0, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.Text = "ESP: ON"

local refreshBtn = Instance.new("TextButton", container)
refreshBtn.Size = UDim2.new(0, 150, 0, 30)
refreshBtn.Position = UDim2.new(0, 0, 0, 35)
refreshBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
refreshBtn.TextColor3 = Color3.new(1, 1, 1)
refreshBtn.Font = Enum.Font.SourceSansBold
refreshBtn.Text = "Refresh ESP"

local healthBtn = Instance.new("TextButton", container)
healthBtn.Size = UDim2.new(0, 150, 0, 30)
healthBtn.Position = UDim2.new(0, 0, 0, 70)
healthBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
healthBtn.TextColor3 = Color3.new(1, 1, 1)
healthBtn.Font = Enum.Font.SourceSansBold
healthBtn.Text = "Health: OFF"

-- Clear ESP for all
local function clearESP()
	for model, _ in pairs(processed) do
		if model then
			if model:FindFirstChild("ESP_Highlight") then
				model.ESP_Highlight:Destroy()
			end
			if model:FindFirstChild("ESP_Name") then
				model.ESP_Name:Destroy()
			end
		end
	end
	processed = {}
end

-- Add ESP
local function addESP(model, nameText, color)
	if not model or not model:IsA("Model") or processed[model] then return end

	local head = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
	local humanoid = model:FindFirstChild("Humanoid")
	if not head then return end

	-- Highlight
	local highlight = Instance.new("Highlight")
	highlight.Name = "ESP_Highlight"
	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 0
	highlight.OutlineColor = color
	highlight.Adornee = model
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = model

	-- Billboard GUI name tag
	local tag = Instance.new("BillboardGui")
	tag.Name = "ESP_Name"
	tag.Adornee = head
	tag.Size = UDim2.new(0, 120, 0, 20)
	tag.StudsOffset = Vector3.new(0, 2.5, 0)
	tag.AlwaysOnTop = true

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = color
	label.Font = Enum.Font.Arial
	label.TextSize = 14
	label.Text = nameText .. (healthEnabled and humanoid and (" | ".. math.floor(humanoid.Health)) or "")
	label.Parent = tag

	if humanoid and healthEnabled then
		humanoid.HealthChanged:Connect(function(hp)
			if espEnabled then
				label.Text = nameText .. " | ".. math.floor(hp)
			end
		end)
	end

	tag.Parent = model
	processed[model] = true
end

-- Refresh ESP
local function refreshESP()
	if not espEnabled then return end
	clearESP()

	local myChar = LocalPlayer.Character
	if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end
	local myPos = myChar.HumanoidRootPart.Position

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			addESP(player.Character, player.Name, Color3.fromRGB(255, 165, 0))
		end
	end

	for _, model in ipairs(workspace:GetChildren()) do
		if model:IsA("Model") and model:FindFirstChild("Humanoid") and model:FindFirstChild("HumanoidRootPart") then
			if not Players:GetPlayerFromCharacter(model) then
				local dist = (myPos - model.HumanoidRootPart.Position).Magnitude
				if dist < 500 then
					addESP(model, model.Name, Color3.fromRGB(255, 0, 0))
				end
			end
		end
	end
end

-- Button Events
toggleBtn.MouseButton1Click:Connect(function()
	espEnabled = not espEnabled
	toggleBtn.Text = espEnabled and "ESP: ON" or "ESP: OFF"
	if not espEnabled then
		clearESP()
	else
		refreshESP()
	end
end)

refreshBtn.MouseButton1Click:Connect(refreshESP)

healthBtn.MouseButton1Click:Connect(function()
	healthEnabled = not healthEnabled
	healthBtn.Text = healthEnabled and "Health: ON" or "Health: OFF"
	if espEnabled then
		refreshESP()
	end
end)

-- Track Players
local function trackPlayer(player)
	player.CharacterAdded:Connect(function(character)
		if espEnabled then
			addESP(character, player.Name, Color3.fromRGB(255, 165, 0))
		end
		local humanoid = character:WaitForChild("Humanoid", 5)
		if humanoid then
			humanoid.Died:Connect(function()
				clearESP()
				if espEnabled then refreshESP() end
			end)
		end
	end)

	if player.Character and espEnabled then
		addESP(player.Character, player.Name, Color3.fromRGB(255, 165, 0))
	end
end

for _, plr in ipairs(Players:GetPlayers()) do
	if plr ~= LocalPlayer then
		trackPlayer(plr)
	end
end

Players.PlayerAdded:Connect(trackPlayer)
Players.PlayerRemoving:Connect(function(player)
	clearESP()
end)

-- Ensure no leftover ESP after toggle off
RunService.Heartbeat:Connect(function()
	if not espEnabled then
		clearESP()
	end
end)

-- Initial ESP
refreshESP()
