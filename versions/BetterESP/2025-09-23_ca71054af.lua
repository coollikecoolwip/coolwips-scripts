local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local espEnabled = true
local processed = {}
local queue = {}

--// GUI Setup
local gui = Instance.new("ScreenGui", CoreGui)
gui.Name = "UniversalESP"

local toggleBtn = Instance.new("TextButton", gui)
toggleBtn.Size = UDim2.new(0, 150, 0, 30)
toggleBtn.Position = UDim2.new(0, 10, 0, 10)
toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.Text = "ESP: ON"

local refreshBtn = Instance.new("TextButton", gui)
refreshBtn.Size = UDim2.new(0, 150, 0, 30)
refreshBtn.Position = UDim2.new(0, 10, 0, 50)
refreshBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
refreshBtn.TextColor3 = Color3.new(1, 1, 1)
refreshBtn.Text = "Refresh ESP"

--// Functions
local function clearESP()
	for model, _ in pairs(processed) do
		if model and model.Parent then
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

local function refreshESP()
	if not espEnabled then return end

	clearESP()

	local myChar = LocalPlayer.Character
	if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end
	local myPos = myChar.HumanoidRootPart.Position

	-- Players
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			addESP(player.Character, player.Name, Color3.fromRGB(255, 165, 0)) -- orange
		end
	end

	-- NPCs
	for _, model in ipairs(workspace:GetChildren()) do
		if model:IsA("Model") and model:FindFirstChild("Humanoid") and model:FindFirstChild("HumanoidRootPart") then
			if not Players:GetPlayerFromCharacter(model) then
				local dist = (myPos - model.HumanoidRootPart.Position).Magnitude
				if dist < 500 then
					addESP(model, model.Name, Color3.fromRGB(255, 0, 0)) -- red
				end
			end
		end
	end
end

--// Connections
toggleBtn.MouseButton1Click:Connect(function()
	espEnabled = not espEnabled
	toggleBtn.Text = espEnabled and "ESP: ON" or "ESP: OFF"
	if not espEnabled then
		clearESP()
	else
		refreshESP()
	end
end)

refreshBtn.MouseButton1Click:Connect(function()
	refreshESP()
end)

RunService.RenderStepped:Connect(function()
	if #queue > 0 then
		local add = table.remove(queue, 1)
		pcall(add)
	end
end)

-- Initial load
refreshESP()
