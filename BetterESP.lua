local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- Determine correct GUI parent
local CoreGui = game:GetService("CoreGui")
local guiParent = CoreGui:FindFirstChildOfClass("ScreenGui") and CoreGui or LocalPlayer:WaitForChild("PlayerGui")

local espEnabled = true
local processed = {}
local queue = {}

-- GUI Setup
local gui = Instance.new("ScreenGui")
gui.Name = "UniversalESP"
gui.ResetOnSpawn = false
gui.Parent = guiParent

local toggleBtn = Instance.new("TextButton", gui)
toggleBtn.Size = UDim2.new(0, 150, 0, 30)
toggleBtn.Position = UDim2.new(0, 10, 0, 10)
toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.Text = "ESP: ON"

local refreshBtn = Instance.new("TextButton", gui)
refreshBtn.Size = UDim2.new(0, 150, 0, 30)
refreshBtn.Position = UDim2.new(0, 10, 0, 50)
refreshBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
refreshBtn.TextColor3 = Color3.new(1, 1, 1)
refreshBtn.Font = Enum.Font.SourceSansBold
refreshBtn.Text = "Refresh ESP"

-- Clear ESP function
local function clearESP(model)
	if model and processed[model] then
		if model:FindFirstChild("ESP_Highlight") then model.ESP_Highlight:Destroy() end
		if model:FindFirstChild("ESP_Name") then model.ESP_Name:Destroy() end
		processed[model] = nil
	else
		for mdl, _ in pairs(processed) do
			if mdl and mdl.Parent then
				if mdl:FindFirstChild("ESP_Highlight") then mdl.ESP_Highlight:Destroy() end
				if mdl:FindFirstChild("ESP_Name") then mdl.ESP_Name:Destroy() end
			end
		end
		processed = {}
	end
end

-- Add ESP function
local function addESP(model, nameText, color)
	if not model or not model:IsA("Model") or processed[model] then return end

	local root = model:FindFirstChild("HumanoidRootPart")
	local head = model:FindFirstChild("Head") or root
	if not head then return end

	local highlight = Instance.new("Highlight")
	highlight.Name = "ESP_Highlight"
	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 0
	highlight.OutlineColor = color
	highlight.Adornee = model
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = model

	table.insert(queue, function()
		local tag = Instance.new("BillboardGui")
		tag.Name = "ESP_Name"
		tag.Adornee = head
		tag.Size = UDim2.new(0, 80, 0, 20)
		tag.StudsOffset = Vector3.new(0, 2.5, 0)
		tag.AlwaysOnTop = true

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = nameText
		label.TextColor3 = color
		label.Font = Enum.Font.Arial
		label.TextSize = 14
		label.Parent = tag

		tag.Parent = model
	end)

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

-- Buttons
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

-- Render loop
RunService.RenderStepped:Connect(function()
	if #queue > 0 then
		local addFunc = table.remove(queue, 1)
		pcall(addFunc)
	end
end)

-- Handle ESP persistence after death
local function trackPlayer(player)
	player.CharacterAdded:Connect(function(character)
		refreshESP()
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Died:Connect(function()
				clearESP(character)
			end)
		end
	end)
end

for _, plr in ipairs(Players:GetPlayers()) do
	if plr ~= LocalPlayer then
		trackPlayer(plr)
	end
end

Players.PlayerAdded:Connect(trackPlayer)
Players.PlayerRemoving:Connect(function(player)
	clearESP(player.Character)
end)

-- Initial ESP
refreshESP()
