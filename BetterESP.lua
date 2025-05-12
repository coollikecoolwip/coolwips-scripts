local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local function applyHighlight(model, color)
	if not model:FindFirstChild("HumanoidRootPart") then return end
	if model:FindFirstChild("ESP_Highlight") then return end

	local highlight = Instance.new("Highlight")
	highlight.Name = "ESP_Highlight"
	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 0
	highlight.OutlineColor = color
	highlight.Adornee = model
	highlight.Parent = model
end

RunService.RenderStepped:Connect(function()
	local char = LocalPlayer.Character
	if not (char and char:FindFirstChild("HumanoidRootPart")) then return end
	local pos = char.HumanoidRootPart.Position

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			if (player.Character.HumanoidRootPart.Position - pos).Magnitude < 1000 then
				applyHighlight(player.Character, Color3.fromRGB(255, 165, 0)) -- Orange
			end
		end
	end

	for _, model in ipairs(workspace:GetDescendants()) do
		if model:IsA("Model") and model:FindFirstChild("Humanoid") and model:FindFirstChild("HumanoidRootPart") then
			if not Players:GetPlayerFromCharacter(model) then
				if (model.HumanoidRootPart.Position - pos).Magnitude < 1000 then
					applyHighlight(model, Color3.fromRGB(255, 0, 0)) -- Red
				end
			end
		end
	end
end)
