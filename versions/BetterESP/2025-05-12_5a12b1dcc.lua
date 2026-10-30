local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local function addOutline(model, color, name)
	if model:FindFirstChild("HumanoidRootPart") and not model:FindFirstChild("ESP_Outline") then
		local box = Instance.new("SelectionBox")
		box.Name = "ESP_Outline"
		box.Adornee = model
		box.LineThickness = 0.05
		box.Color3 = color
		box.Parent = model
	end

	if name and model:FindFirstChild("Head") and not model.Head:FindFirstChild("ESP_Name") then
		local gui = Instance.new("BillboardGui")
		gui.Name = "ESP_Name"
		gui.AlwaysOnTop = true
		gui.Size = UDim2.new(0, 100, 0, 20)
		gui.StudsOffset = Vector3.new(0, 2, 0)
		gui.Adornee = model.Head
		gui.Parent = model.Head

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = name
		label.TextColor3 = color
		label.TextStrokeTransparency = 0
		label.TextScaled = true
		label.Font = Enum.Font.SourceSansBold
		label.Parent = gui
	end
end

RunService.RenderStepped:Connect(function()
	local char = LocalPlayer.Character
	if not (char and char:FindFirstChild("HumanoidRootPart")) then return end
	local pos = char.HumanoidRootPart.Position

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			if (player.Character.HumanoidRootPart.Position - pos).Magnitude < 800 then
				addOutline(player.Character, Color3.fromRGB(255, 165, 0)) -- orange for players
			end
		end
	end

	for _, model in ipairs(workspace:GetDescendants()) do
		if model:IsA("Model") and not Players:GetPlayerFromCharacter(model) then
			if model:FindFirstChild("Humanoid") and model:FindFirstChild("HumanoidRootPart") then
				if (model.HumanoidRootPart.Position - pos).Magnitude < 800 then
					addOutline(model, Color3.fromRGB(255, 0, 0), "NPC: " .. (model.Name or "Unknown")) -- red for NPCs + nametag
				end
			end
		end
	end
end)
