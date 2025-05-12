local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local function createNameTag(model, nameText, color)
	if model:FindFirstChild("ESP_NameTag") then return end

	local head = model:FindFirstChild("Head")
	if not head then return end

	local tag = Instance.new("BillboardGui")
	tag.Name = "ESP_NameTag"
	tag.Adornee = head
	tag.Size = UDim2.new(0, 200, 0, 30)
	tag.StudsOffset = Vector3.new(0, 2.5, 0)
	tag.AlwaysOnTop = true

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = nameText
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.5
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.Parent = tag

	tag.Parent = model
end

local function applyHighlight(model, color)
	if model:FindFirstChild("ESP_Highlight") then return end

	local highlight = Instance.new("Highlight")
	highlight.Name = "ESP_Highlight"
	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 0
	highlight.OutlineColor = color
	highlight.Adornee = model
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- Visible through walls
	highlight.Parent = model
end

RunService.RenderStepped:Connect(function()
	local char = LocalPlayer.Character
	if not (char and char:FindFirstChild("HumanoidRootPart")) then return end
	local pos = char.HumanoidRootPart.Position

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local dist = (player.Character.HumanoidRootPart.Position - pos).Magnitude
			if dist < 1500 then
				applyHighlight(player.Character, Color3.fromRGB(255, 165, 0)) -- Orange
				createNameTag(player.Character, player.Name, Color3.fromRGB(255, 165, 0))
			end
		end
	end

	for _, model in ipairs(workspace:GetDescendants()) do
		if model:IsA("Model") and model:FindFirstChild("Humanoid") and model:FindFirstChild("HumanoidRootPart") then
			if not Players:GetPlayerFromCharacter(model) then
				local dist = (model.HumanoidRootPart.Position - pos).Magnitude
				if dist < 1500 then
					applyHighlight(model, Color3.fromRGB(255, 0, 0)) -- Red
					createNameTag(model, model.Name, Color3.fromRGB(255, 0, 0))
				end
			end
		end
	end
end)
