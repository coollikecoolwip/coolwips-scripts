-- Lightweight MM2 ESP
-- ONLY for private/testing use. Does NOT change hitboxes.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Workspace = workspace
local LocalPlayer = Players.LocalPlayer

-- Config (tweak)
local ROLE_COLORS = {
	Murderer = Color3.fromRGB(255, 0, 0),
	Sheriff  = Color3.fromRGB(0, 170, 255),
	Innocent = Color3.fromRGB(150, 150, 150),
	Gun      = Color3.fromRGB(0, 255, 0),
}
local LABEL_SIZE = UDim2.new(0, 140, 0, 26)
local BILLBOARD_OFFSET = Vector3.new(0, 2.5, 0)
local REFRESH_INTERVAL = 0.1 -- Adjust this value (seconds)

-- Internal tables
local playerESP = {} -- player -> { highlight, billboard, label, role, conns = { ... } }
local gunESP = {}    -- toolInstance -> { highlight, billboard, label }

-- Helpers
local function safeDestroy(obj)
	if obj and obj.Parent then
		pcall(function() obj:Destroy() end)
	end
end

local function findAdornmentPart(model)
	if not model then return nil end
	local head = model:FindFirstChild("Head")
	if head and head:IsA("BasePart") then return head end
	local hrp = model:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then return hrp end
	for _, v in ipairs(model:GetChildren()) do
		if v:IsA("BasePart") then return v end
	end
	return nil
end

local function getRole(player)
	local ok, res = pcall(function()
		if player.Backpack:FindFirstChild("Knife") or (player.Character and player.Character:FindFirstChild("Knife")) then
			return "Murderer"
		elseif player.Backpack:FindFirstChild("Gun") or (player.Character and player.Character:FindFirstChild("Gun")) then
			return "Sheriff"
		else
			return "Innocent"
		end
	end)
	if ok then return res end
	return "Innocent"
end

local function createPlayerESP(player)
	if playerESP[player] then return end

	local char = player.Character
	if not (char and char.Parent) then return end

	local part = findAdornmentPart(char)
	if not part then return end

	local hl = Instance.new("Highlight")
	hl.Name = "MM2_Highlight"
	hl.Adornee = char
	hl.FillTransparency = 0.6
	hl.OutlineTransparency = 0
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Parent = CoreGui

	local bb = Instance.new("BillboardGui")
	bb.Name = "MM2_Label"
	bb.Size = LABEL_SIZE
	bb.StudsOffset = BILLBOARD_OFFSET
	bb.AlwaysOnTop = true
	bb.Parent = part

	local txt = Instance.new("TextLabel", bb)
	txt.BackgroundTransparency = 1
	txt.Size = UDim2.new(1, 0, 1, 0)
	txt.Font = Enum.Font.SourceSansBold
	txt.TextScaled = true
	txt.Text = ""
	txt.TextColor3 = Color3.new(1, 1, 1)

	local role = getRole(player)
	local color = ROLE_COLORS[role] or ROLE_COLORS.Innocent

	hl.FillColor = color
	hl.OutlineColor = color
	txt.Text = role
	txt.TextColor3 = color

	playerESP[player] = {
		highlight = hl,
		billboard = bb,
		label = txt,
		role = role,
		conns = {},
	}
end

local function removePlayerESP(player)
	local data = playerESP[player]
	if not data then
		return
	end

	safeDestroy(data.highlight)
	safeDestroy(data.billboard)

	for _, conn in ipairs(data.conns) do
		pcall(function()
			conn:Disconnect()
		end)
	end

	playerESP[player] = nil
end

local function updatePlayerRole(player)
	local data = playerESP[player]
	if not data then
		createPlayerESP(player)
		data = playerESP[player]
		if not data then return end
	end

	local role = getRole(player)
	if data.role == role then return end -- Only update if the role has changed

	local color = ROLE_COLORS[role] or ROLE_COLORS.Innocent
	data.highlight.FillColor = color
	data.highlight.OutlineColor = color
	data.label.Text = role
	data.label.TextColor3 = color
	data.role = role
end

local function setupPlayerListeners(player)
	if playerESP[player] and next(playerESP[player].conns) then return end

	local function onCharAdded(char)
		task.delay(0.05, function()
			createPlayerESP(player)
			updatePlayerRole(player)
		end)
	end

	local function onBackpackChanged()
		updatePlayerRole(player)
	end

	local charConn = player.CharacterAdded:Connect(onCharAdded)
	local backpackConn = player.Backpack.ChildAdded:Connect(onBackpackChanged)
    local backpackRemoveConn = player.Backpack.ChildRemoved:Connect(onBackpackChanged) -- Added for item removal

	playerESP[player] = playerESP[player] or {}
	playerESP[player].conns = {charConn, backpackConn, backpackRemoveConn}
end

-- Gun ESP Functions
local function createGunESP(tool)
	if gunESP[tool] then return end

	local part = tool:FindFirstChildWhichIsA("BasePart", true)
	if not part then return end

	local hl = Instance.new("Highlight")
	hl.Name = "MM2_Gun_HL"
	hl.Adornee = part
	hl.FillColor = ROLE_COLORS.Gun
	hl.FillTransparency = 0.5
	hl.OutlineTransparency = 0
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Parent = CoreGui

	local bb = Instance.new("BillboardGui")
	bb.Name = "MM2_Gun_Label"
	bb.Size = UDim2.new(0, 100, 0, 30)
	bb.StudsOffset = Vector3.new(0, 1.8, 0)
	bb.AlwaysOnTop = true
	bb.Parent = part

	local lbl = Instance.new("TextLabel", bb)
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.SourceSansBold
	lbl.TextScaled = true
	lbl.Text = "Gun"
	lbl.TextColor3 = ROLE_COLORS.Gun

	gunESP[tool] = { highlight = hl, billboard = bb }

	tool.Destroying:Connect(function()
		if gunESP[tool] then
			safeDestroy(gunESP[tool].highlight)
			safeDestroy(gunESP[tool].billboard)
			gunESP[tool] = nil
		end
	end)
end

-- Event Handling
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		createPlayerESP(player)
		updatePlayerRole(player)
		setupPlayerListeners(player)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	removePlayerESP(player)
end)

Workspace.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("Tool") and descendant.Name == "GunDrop" then
		task.delay(0.03, function()
			if descendant.Parent then
				createGunESP(descendant)
			end
		end)
	end
end)

Workspace.DescendantRemoving:Connect(function(descendant)
	if descendant:IsA("Tool") and descendant.Name == "GunDrop" then
		if gunESP[descendant] then
			safeDestroy(gunESP[descendant].highlight)
			safeDestroy(gunESP[descendant].billboard)
			gunESP[descendant] = nil
		end
	end
end)

-- Initial Setup
for _, player in ipairs(Players:GetPlayers()) do
	if player ~= LocalPlayer and player.Character then
		createPlayerESP(player)
		updatePlayerRole(player)
		setupPlayerListeners(player)
	end
end

for _, tool in ipairs(Workspace:GetDescendants()) do
	if tool:IsA("Tool") and tool.Name == "GunDrop" then
		createGunESP(tool)
	end
end

-- Periodic Refresh (Less Frequent)
local function refreshESP()
	for player, data in pairs(playerESP) do
		if player.Character then
			updatePlayerRole(player)
		else
			removePlayerESP(player)
		end
	end
end

while true do
	task.wait(REFRESH_INTERVAL)
	refreshESP()
end
