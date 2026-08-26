-- Role ESP using server PlayerDataChanged role data
-- Visuals: Highlight + BillboardGui label
-- Optional item-based detection is only used while server role data is unavailable.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Server role-data event from the first script
local PlayerDataChanged = ReplicatedStorage
	:WaitForChild("Remotes")
	:WaitForChild("Gameplay")
	:WaitForChild("PlayerDataChanged")

-- Configuration
local ROLE_COLORS = {
	Murderer = Color3.fromRGB(255, 0, 0),
	Sheriff = Color3.fromRGB(0, 170, 255),
	Innocent = Color3.fromRGB(150, 150, 150),
}

local PLAYER_LABEL_SIZE = UDim2.new(0, 140, 0, 26)
local PLAYER_BILLBOARD_OFFSET = Vector3.new(0, 2.5, 0)
local REFRESH_INTERVAL = 0.1

local SHOW_LOCAL_PLAYER = false
local USE_ITEM_FALLBACK = true

-- player -> server role data
local PlayerData = {}

-- player -> {highlight, billboard, label, role}
local playerESP = {}

-- player -> connections
local playerConnections = {}

local function safeDestroy(instance)
	if instance then
		pcall(function()
			instance:Destroy()
		end)
	end
end

local function findAdornmentPart(character)
	if not character then
		return nil
	end

	local head = character:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		return head
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end

	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("BasePart") then
			return child
		end
	end

	return nil
end

-- Fallback only: used if the server's PlayerData has not arrived yet.
local function getPlayerRoleFromItems(player)
	local character = player.Character
	local backpack = player:FindFirstChildOfClass("Backpack")

	local hasKnife =
		(backpack and backpack:FindFirstChild("Knife"))
		or (character and character:FindFirstChild("Knife"))

	if hasKnife then
		return "Murderer"
	end

	local hasGun =
		(backpack and backpack:FindFirstChild("Gun"))
		or (character and character:FindFirstChild("Gun"))

	if hasGun then
		return "Sheriff"
	end

	return "Innocent"
end

-- Main role lookup: server data first, item fallback second.
local function getPlayerRole(player)
	local data = PlayerData[player.Name]

	if data and data.Role then
		return data.Role
	end

	if USE_ITEM_FALLBACK then
		return getPlayerRoleFromItems(player)
	end

	return nil
end

local function removePlayerESP(player)
	local data = playerESP[player]
	if not data then
		return
	end

	safeDestroy(data.highlight)
	safeDestroy(data.billboard)

	playerESP[player] = nil
end

local function createPlayerESP(player)
	if not SHOW_LOCAL_PLAYER and player == LocalPlayer then
		return
	end

	local character = player.Character
	if not character or not character.Parent then
		return
	end

	local part = findAdornmentPart(character)
	if not part then
		return
	end

	-- Remove old ESP if it belongs to an older character/respawn.
	local oldData = playerESP[player]
	if oldData then
		local validHighlight =
			oldData.highlight
			and oldData.highlight.Parent == character
			and oldData.highlight.Adornee == character

		if validHighlight then
			return
		end

		removePlayerESP(player)
	end

	local role = getPlayerRole(player)
	if not role then
		return
	end

	local color = ROLE_COLORS[role] or ROLE_COLORS.Innocent

	local highlight = Instance.new("Highlight")
	highlight.Name = "RoleESP_Highlight"
	highlight.Adornee = character
	highlight.FillColor = color
	highlight.OutlineColor = color
	highlight.FillTransparency = 0.6
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = character

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "RoleESP_Label"
	billboard.Adornee = part
	billboard.Size = PLAYER_LABEL_SIZE
	billboard.StudsOffset = PLAYER_BILLBOARD_OFFSET
	billboard.AlwaysOnTop = true
	billboard.Parent = part

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.SourceSansBold
	label.TextScaled = true
	label.TextStrokeTransparency = 0.4
	label.TextColor3 = color
	label.Text = role
	label.Parent = billboard

	playerESP[player] = {
		highlight = highlight,
		billboard = billboard,
		label = label,
		role = role,
	}
end

local function updatePlayerESP(player)
	if not SHOW_LOCAL_PLAYER and player == LocalPlayer then
		removePlayerESP(player)
		return
	end

	if not player.Character or not player.Character.Parent then
		removePlayerESP(player)
		return
	end

	if not playerESP[player] then
		createPlayerESP(player)
	end

	local data = playerESP[player]
	if not data then
		return
	end

	local role = getPlayerRole(player)
	if not role then
		removePlayerESP(player)
		return
	end

	local color = ROLE_COLORS[role] or ROLE_COLORS.Innocent

	-- Update only when the detected role changes.
	if data.role ~= role then
		data.highlight.FillColor = color
		data.highlight.OutlineColor = color
		data.label.Text = role
		data.label.TextColor3 = color
		data.role = role
	end
end

local function disconnectPlayerListeners(player)
	local connections = playerConnections[player]
	if not connections then
		return
	end

	for _, connection in ipairs(connections) do
		pcall(function()
			connection:Disconnect()
		end)
	end

	playerConnections[player] = nil
end

local function setupPlayer(player)
	if playerConnections[player] then
		return
	end

	local connections = {}

	table.insert(connections, player.CharacterAdded:Connect(function()
		task.wait(0.1)
		updatePlayerESP(player)
	end))

	table.insert(connections, player.CharacterRemoving:Connect(function()
		removePlayerESP(player)
	end))

	-- These matter only while waiting for server PlayerData;
	-- they keep the fallback result current.
	local backpack = player:WaitForChild("Backpack", 5)
	if backpack then
		table.insert(connections, backpack.ChildAdded:Connect(function()
			updatePlayerESP(player)
		end))

		table.insert(connections, backpack.ChildRemoved:Connect(function()
			updatePlayerESP(player)
		end))
	end

	playerConnections[player] = connections

	if player.Character then
		updatePlayerESP(player)
	end
end

-- Receive authoritative role information from the server.
PlayerDataChanged.OnClientEvent:Connect(function(data)
	PlayerData = data or {}

	-- Update immediately instead of waiting for the periodic refresh.
	for _, player in ipairs(Players:GetPlayers()) do
		updatePlayerESP(player)
	end
end)

-- Existing players
for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

Players.PlayerAdded:Connect(setupPlayer)

Players.PlayerRemoving:Connect(function(player)
	removePlayerESP(player)
	disconnectPlayerListeners(player)
end)

-- Periodic safety refresh for respawns, delayed replication, etc.
task.spawn(function()
	while true do
		for _, player in ipairs(Players:GetPlayers()) do
			updatePlayerESP(player)
		end

		task.wait(REFRESH_INTERVAL)
	end
end)
