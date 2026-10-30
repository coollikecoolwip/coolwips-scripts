local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Colors for roles
local ROLE_COLORS = {
	Murderer = Color3.fromRGB(255, 0, 0),
	Sheriff = Color3.fromRGB(0, 170, 255),
	Innocent = Color3.fromRGB(150, 150, 150),
	Gun = Color3.fromRGB(0, 255, 0),
}

-- Track ESP objects
local espObjects = {}

local function getRole(player)
	if player.Backpack:FindFirstChild("Knife") or (player.Character and player.Character:FindFirstChild("Knife")) then
		return "Murderer"
	elseif player.Backpack:FindFirstChild("Gun") or (player.Character and player.Character:FindFirstChild("Gun")) then
		return "Sheriff"
	else
		return "Innocent"
	end
end

local function addESP(player)
	if espObjects[player] then return end
	if not player.Character or not player.Character:FindFirstChild("Head") then return end

	local char = player.Character

	-- Highlight
	local highlight = Instance.new("Highlight")
	highlight.Name = "MM2ESP"
	highlight.Adornee = char
	highlight.FillTransparency = 0.75
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = game:GetService("CoreGui")
	espObjects[player] = highlight

	-- Name label
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "RoleLabel"
	billboard.Size = UDim2.new(0, 200, 0, 40)
	billboard.AlwaysOnTop = true
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.Parent = char.Head

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.Text = role
	label.Parent = billboard
end

local function removeESP(player)
	if espObjects[player] then
		espObjects[player]:Destroy()
		espObjects[player] = nil
	end

	if player.Character and player.Character:FindFirstChild("Head") then
		local old = player.Character.Head:FindFirstChild("RoleLabel")
		if old then old:Destroy() end
	end
end

local function updateESP()
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			addESP(player)
			local role = getRole(player)
			local esp = espObjects[player]
			if esp then
				esp.Adornee = player.Character
				esp.FillColor = ROLE_COLORS[role]
				esp.OutlineColor = ROLE_COLORS[role]
			end
		else
			removeESP(player)
		end
	end
end

local function showDroppedGun()
	for _, item in ipairs(workspace:GetDescendants()) do
		if item:IsA("Tool") and item.Name == "GunDrop" and not item:FindFirstChild("ESP") then
			local part = item:FindFirstChildWhichIsA("BasePart")
			if part then
				-- Outline
				local hl = Instance.new("Highlight")
				hl.Name = "ESP"
				hl.Adornee = part
				hl.FillColor = ROLE_COLORS.Gun
				hl.FillTransparency = 0.5
				hl.OutlineTransparency = 0
				hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				hl.Parent = item

				-- Label
				local billboard = Instance.new("BillboardGui")
				billboard.Name = "GunLabel"
				billboard.Size = UDim2.new(0, 100, 0, 40)
				billboard.StudsOffset = Vector3.new(0, 2, 0)
				billboard.AlwaysOnTop = true
				billboard.Parent = part

				local label = Instance.new("TextLabel")
				label.Size = UDim2.new(1, 0, 1, 0)
				label.BackgroundTransparency = 1
				label.TextColor3 = ROLE_COLORS.Gun
				label.TextStrokeTransparency = 0
				label.TextScaled = true
				label.Text = "Gun"
				label.Font = Enum.Font.SourceSansBold
				label.Parent = billboard
			end
		end
	end
end

-- Reset ESP when teleporting
LocalPlayer.CharacterAdded:Connect(function()
	for player, esp in pairs(espObjects) do
		if esp then esp:Destroy() end
	end
	espObjects = {}
end)

-- Continuous update
RunService.RenderStepped:Connect(function()
	updateESP()
	showDroppedGun()
end)
