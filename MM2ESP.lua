local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Colors
local ROLE_COLORS = {
	Murderer = Color3.fromRGB(255, 0, 0),
	Sheriff = Color3.fromRGB(0, 170, 255),
	Innocent = Color3.fromRGB(150, 150, 150),
	Gun = Color3.fromRGB(0, 255, 0),
}

-- Store ESP boxes
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
	local box = Instance.new("Highlight")
	box.Name = "MM2ESP"
	box.Adornee = player.Character
	box.FillTransparency = 0.75
	box.OutlineTransparency = 0
	box.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	box.Parent = game:GetService("CoreGui")
	espObjects[player] = box

	local nameBillboard = Instance.new("BillboardGui")
	nameBillboard.Name = "NameDisplay"
	nameBillboard.Size = UDim2.new(0, 200, 0, 50)
	nameBillboard.AlwaysOnTop = true
	nameBillboard.StudsOffset = Vector3.new(0, 3, 0)
	nameBillboard.Parent = player.Character:WaitForChild("Head")

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextScaled = true
	nameLabel.Text = player.Name
	nameLabel.Font = Enum.Font.SourceSansBold
	nameLabel.Parent = nameBillboard
end

local function removeESP(player)
	if espObjects[player] then
		espObjects[player]:Destroy()
		espObjects[player] = nil
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

-- Show dropped gun
local function showDroppedGun()
	for _, v in pairs(workspace:GetDescendants()) do
		if v:IsA("Tool") and v.Name == "GunDrop" and not v:FindFirstChild("ESP") then
			local part = v:FindFirstChildWhichIsA("BasePart")
			if part then
				local hl = Instance.new("Highlight")
				hl.Name = "ESP"
				hl.Adornee = part
				hl.FillColor = ROLE_COLORS.Gun
				hl.FillTransparency = 0.5
				hl.OutlineTransparency = 0
				hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				hl.Parent = v
			end
		end
	end
end

-- Reset on teleport (next round)
LocalPlayer.CharacterAdded:Connect(function()
	for player, esp in pairs(espObjects) do
		if esp then esp:Destroy() end
	end
	espObjects = {}
end)

RunService.RenderStepped:Connect(function()
	updateESP()
	showDroppedGun()
end)
