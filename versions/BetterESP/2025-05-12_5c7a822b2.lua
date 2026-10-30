local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local function createNameTag(model, text, color)
	if model:FindFirstChild("ESP_NameTag") then return end
	local head = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
	if not head then return end
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ESP_NameTag"
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.Adornee = head
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = text
	textLabel.TextColor3 = color
	textLabel.TextStrokeTransparency = 0.4
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.SourceSansBold
	textLabel.Parent = billboard
	billboard.Parent = model
end

local function createHighlight(model, color)
	if model:FindFirstChild("ESP_Highlight") then return end
	local highlight = Instance.new("Highlight")
	highlight.Name = "ESP_Highlight"
	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 0
	highlight.OutlineColor = color
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Adornee = model
	highlight.Parent = model
end

RunService.RenderStepped:Connect(function()
	local myChar = LocalPlayer.Character
	if not (myChar and myChar:FindFirstChild("HumanoidRootPart")) then return end
	local myPos = myChar.HumanoidRootPart.Position
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local dist = (player.Character.HumanoidRootPart.Position - myPos).Magnitude
			if dist < 1500 then
				createHighlight(player.Character, Color3.fromRGB(255, 165, 0))
				createNameTag(player.Character, player.Name, Color3.fromRGB(255, 165, 0))
			end
		end
	end
	for _, model in ipairs(workspace:GetDescendants()) do
		if model:IsA("Model") and model:FindFirstChild("Humanoid") and model:FindFirstChild("HumanoidRootPart") then
			if not Players:GetPlayerFromCharacter(model) then
				local dist = (model.HumanoidRootPart.Position - myPos).Magnitude
				if dist < 1500 then
					createHighlight(model, Color3.fromRGB(255, 0, 0))
					createNameTag(model, model.Name, Color3.fromRGB(255, 0, 0))
				end
			end
		end
	end
end)
