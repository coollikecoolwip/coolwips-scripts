--// Universal ESP v3.0 (MAX NPC OPTIMIZED)
--// Menu Toggle Key: P
--// Player ESP + NPC ESP (NPC cache, no workspace scanning)
--// Cool draggable UI retained

--==============================
-- Services
--==============================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

--==============================
-- Settings / Toggles
--==============================
local ESP_ENABLED   = true
local SHOW_HEALTH   = false
local TEAM_MODE     = false
local SHOW_NPCS     = false -- ✅ OFF by default to prevent lag
local MAX_DISTANCE  = 10000
local UPDATE_RATE   = 0.5   -- ✅ Lower refresh rate = less CPU

-- Colors
local PLAYER_COLOR = Color3.fromRGB(255, 170, 0)
local NPC_COLOR    = Color3.fromRGB(255, 70, 70)

-- State
local ESP_CACHE = {}
local npcCache = {}
local timeAcc = 0
local menuVisible = false

--==============================
-- GUI SETUP (Cool Menu)
--==============================
local gui = Instance.new("ScreenGui")
gui.Name = "UniversalESP"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
gui.Enabled = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromOffset(240, 250)
frame.Position = UDim2.fromScale(0.5, 0.5) - UDim2.fromOffset(120, 125)
frame.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local function makeButton(y, text)
	local b = Instance.new("TextButton", frame)
	b.Size = UDim2.fromOffset(200, 34)
	b.Position = UDim2.fromOffset(20, y)
	b.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	b.TextColor3 = Color3.new(1,1,1)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 14
	b.Text = text
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	return b
end

local espBtn  = makeButton(15,  "ESP: ON")
local hpBtn   = makeButton(55,  "Health: OFF")
local teamBtn = makeButton(95,  "Team Mode: OFF")
local npcBtn  = makeButton(135, "NPCs: OFF")
local refBtn  = makeButton(175, "Refresh ESP")

--==============================
-- Utility
--==============================
local function formatText(name, hum)
	if SHOW_HEALTH and hum then
		return name .. " | " .. math.floor(hum.Health)
	end
	return name
end

local function getPlayerColor(player)
	if TEAM_MODE and player.Team then
		return player.TeamColor.Color
	end
	return PLAYER_COLOR
end

--==============================
-- ESP CORE
--==============================
local function clearESP(model)
	local d = ESP_CACHE[model]
	if not d then return end
	if d.hl then d.hl:Destroy() end
	if d.tag then d.tag:Destroy() end
	if d.conn then d.conn:Disconnect() end
	ESP_CACHE[model] = nil
end

local function createESP(model, name, color)
	local hum = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head")
	if not hum or not root then return end

	local hl = Instance.new("Highlight")
	hl.FillTransparency = 1
	hl.OutlineTransparency = 0
	hl.OutlineColor = color
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Adornee = model
	hl.Parent = model

	local tag = Instance.new("BillboardGui")
	tag.Adornee = root
	tag.Size = UDim2.fromOffset(150, 28)
	tag.StudsOffset = Vector3.new(0, 2.8, 0)
	tag.AlwaysOnTop = true
	tag.Parent = model

	local lbl = Instance.new("TextLabel", tag)
	lbl.Size = UDim2.fromScale(1,1)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 16
	lbl.TextColor3 = color
	lbl.Text = formatText(name, hum)

	local conn = hum.HealthChanged:Connect(function()
		if ESP_CACHE[model] then
			lbl.Text = formatText(name, hum)
		end
	end)

	ESP_CACHE[model] = {hl=hl, tag=tag, lbl=lbl, hum=hum, conn=conn}
end

local function updateESP(model, name, color)
	local d = ESP_CACHE[model]
	if not d then return end
	d.lbl.Text = formatText(name, d.hum)
	d.lbl.TextColor3 = color
	d.hl.OutlineColor = color
end

--==============================
-- NPC CACHE (ZERO SCANS)
--==============================
local function tryAddNPC(model)
	if model:IsA("Model") and not Players:GetPlayerFromCharacter(model) then
		local hum = model:FindFirstChildOfClass("Humanoid")
		local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head")
		if hum and root then
			npcCache[model] = {hum=hum, root=root, name=model.Name}
		end
	end
end

local function removeNPC(model)
	npcCache[model] = nil
	clearESP(model)
end

for _, obj in ipairs(workspace:GetDescendants()) do
	tryAddNPC(obj)
end

workspace.DescendantAdded:Connect(tryAddNPC)
workspace.DescendantRemoving:Connect(removeNPC)

--==============================
-- Refresh Logic
--==============================
local function refreshESP()
	if not ESP_ENABLED then
		for m in pairs(ESP_CACHE) do clearESP(m) end
		return
	end

	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local pos = root.Position
	local seen = {}

	-- Players
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character then
			local r = plr.Character:FindFirstChild("HumanoidRootPart")
			if r and (pos - r.Position).Magnitude <= MAX_DISTANCE then
				seen[plr.Character] = true
				local c = getPlayerColor(plr)
				if ESP_CACHE[plr.Character] then
					updateESP(plr.Character, plr.Name, c)
				else
					createESP(plr.Character, plr.Name, c)
				end
			end
		end
	end

	-- NPCs (EXTREMELY LIGHT)
	if SHOW_NPCS then
		for model, data in pairs(npcCache) do
			if (pos - data.root.Position).Magnitude <= MAX_DISTANCE then
				seen[model] = true
				if ESP_CACHE[model] then
					updateESP(model, data.name, NPC_COLOR)
				else
					createESP(model, data.name, NPC_COLOR)
				end
			end
		end
	end

	for m in pairs(ESP_CACHE) do
		if not seen[m] then clearESP(m) end
	end
end

--==============================
-- GUI Buttons
--==============================
espBtn.MouseButton1Click:Connect(function()
	ESP_ENABLED = not ESP_ENABLED
	espBtn.Text = ESP_ENABLED and "ESP: ON" or "ESP: OFF"
	refreshESP()
end)

hpBtn.MouseButton1Click:Connect(function()
	SHOW_HEALTH = not SHOW_HEALTH
	hpBtn.Text = SHOW_HEALTH and "Health: ON" or "Health: OFF"
	refreshESP()
end)

teamBtn.MouseButton1Click:Connect(function()
	TEAM_MODE = not TEAM_MODE
	teamBtn.Text = TEAM_MODE and "Team Mode: ON" or "Team Mode: OFF"
	refreshESP()
end)

npcBtn.MouseButton1Click:Connect(function()
	SHOW_NPCS = not SHOW_NPCS
	npcBtn.Text = SHOW_NPCS and "NPCs: ON" or "NPCs: OFF"
	refreshESP()
end)

refBtn.MouseButton1Click:Connect(refreshESP)

--==============================
-- Menu Toggle (P)
--==============================
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.P then
		menuVisible = not menuVisible
		gui.Enabled = menuVisible
	end
end)

--==============================
-- Update Loop
--==============================
RunService.Heartbeat:Connect(function(dt)
	if not ESP_ENABLED then return end
	timeAcc += dt
	if timeAcc >= UPDATE_RATE then
		timeAcc = 0
		refreshESP()
	end
end)

refreshESP()
