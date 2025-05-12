local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local function addHighlight(model, color, label)
	if not model:FindFirstChild("HumanoidRootPart") then return end

	if not model:FindFirstChild("ESP_Highlight") then
		local highlight = Instance.new("Highlight")
		highlight.Name = "ESP_Highlight"
		highlight.FillTransparency = 1
		highlight.OutlineTransparency = 0
		highlight.OutlineColor = color
		highlight.Adornee = model
		highlight.Parent = model
	end

	if label and model:FindFirstChild("Head") and not model.Head:FindFirstChild("ESP_Name") then
		local tag = Instance.new("BillboardGui")
		tag.Name = "ESP_Name"
		tag.AlwaysOnTop = true
		tag.Size = UDim2.new(0, 100, 0, 20)
		tag.StudsOffset = Vector3.new(0, 2.5, 0)
		tag.Adornee = model.Head
		tag.Parent = model.Head

		local text = Instance.new("TextLabel")
		text.Size = UDim2.new(1, 0, 1, 0)
		text.BackgroundTransparency = 1
		text.Text = label
		text.TextColor3 = color
		text.TextStrokeTransparency = 0
		text.TextScaled = true
		text.Font = Enum.Font.SourceSansBold
		text.Parent = tag
	end
end

RunService.RenderStepped:Connect(function()
	local myChar = LocalPlayer.Character
	if not (myChar and myChar:FindFirstChild("HumanoidRootPart")) then return end
	local myPos = myChar.HumanoidRootPart.Position

	-- Players
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			if (player.Character.HumanoidRootPart.Position - myPos).Magnitude < 1000 then
				addHighlight(player.Character, Color3.fromRGB(255, 165, 0)) -- Orange for players
			end
		end
	end

	-- NPCs
	for _, model in ipairs(workspace:GetDescendants()) do
		if model:IsA("Model") and not Players:GetPlayerFromCharacter(model) then
			if model:FindFirstChild("Humanoid") and model:FindFirstChild("HumanoidRootPart") then
				if not model:FindFirstChild("ESP_Highlight") and 
				   (model.HumanoidRootPart.Position - myPos).Magnitude < 1000 then
					addHighlight(model, Color3.fromRGB(255, 0, 0), "NPC: " .. model.Name)
				end
			end
		end
	end
end)
