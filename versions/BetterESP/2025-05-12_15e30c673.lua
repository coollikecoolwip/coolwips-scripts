local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Create or update ESP for a character
local function applyESP(character, name)
	local head = character:FindFirstChild("Head")
	if not head then return end

	-- Create or update Highlight
	local highlight = character:FindFirstChild("ESP_Highlight") or Instance.new("Highlight")
	highlight.Name = "ESP_Highlight"
	highlight.Adornee = character
	highlight.FillTransparency = 0.5
	highlight.OutlineTransparency = 0
	highlight.Parent = character

	-- Create Billboard for name
	local tag = head:FindFirstChild("NameTag")
	if not tag then
		tag = Instance.new("BillboardGui")
		tag.Name = "NameTag"
		tag.Adornee = head
		tag.Size = UDim2.new(0, 100, 0, 20)
		tag.StudsOffset = Vector3.new(0, 2, 0)
		tag.AlwaysOnTop = true
		tag.Parent = head

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextStrokeTransparency = 0
		label.Font = Enum.Font.SourceSansBold
		label.TextScaled = true
		label.Text = name
		label.Parent = tag
	end
end

-- Get the TeamColor of a character (NPC or player)
local function getCharacterTeamColor(character)
	local player = Players:GetPlayerFromCharacter(character)
	if player and player.Team then
		return player.Team.TeamColor.Color
	end

	-- For NPCs with StringValue "Team"
	local teamTag = character:FindFirstChild("Team")
	if teamTag and typeof(teamTag.Value) == "string" then
		local teamObj = Teams:FindFirstChild(teamTag.Value)
		if teamObj then
			return teamObj.TeamColor.Color
		end
	end

	return Color3.fromRGB(200, 200, 200)
end

-- Update loop
RunService.RenderStepped:Connect(function()
	for _, model in Workspace:GetDescendants() do
		if model:IsA("Model") and model:FindFirstChild("Humanoid") and model:FindFirstChild("HumanoidRootPart") then
			local player = Players:GetPlayerFromCharacter(model)
			local name = model.Name
			applyESP(model, name)

			local color = getCharacterTeamColor(model)
			local highlight = model:FindFirstChild("ESP_Highlight")
			if highlight then
				highlight.FillColor = color
				highlight.OutlineColor = Color3.new(1, 1, 1)
			end
		end
	end
end)
