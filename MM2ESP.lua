-- Lightweight MM2 ESP (event-driven, pooled, max FPS)
-- ONLY for private/testing use. Does NOT change hitboxes.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local Workspace = workspace

-- Config (tweak)
local ROLE_COLORS = {
	Murderer = Color3.fromRGB(255, 0, 0),
	Sheriff  = Color3.fromRGB(0, 170, 255),
	Innocent = Color3.fromRGB(150, 150, 150),
	Gun      = Color3.fromRGB(0, 255, 0),
}
local LABEL_SIZE = UDim2.new(0, 140, 0, 26)
local BILLBOARD_OFFSET = Vector3.new(0, 2.5, 0)

-- Internal tables
local playerESP = {}   -- player -> { highlight, billboard, label, conns = { ... } }
local gunESP = {}      -- toolInstance -> { highlight, billboard, label }

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
	-- fallback: any first BasePart
	for _, v in ipairs(model:GetChildren()) do
		if v:IsA("BasePart") then return v end
	end
	return nil
end

local function getRole(player)
	-- Lightweight: check Backpack and Character for Knife/Gun
	-- pcall wrap to be safe if Backpack/Character nil
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

-- Create and attach ESP for a player character (only once)
local function createPlayerESP(player)
	if playerESP[player] then return end
	-- wait for character & head
	local char = player.Character
	if not (char and char.Parent) then
		-- will be handled by CharacterAdded handler
		return
	end
	local part = findAdornmentPart(char)
	if not part then return end

	-- Highlight: parent to CoreGui for local-only overlay
	local hl = Instance.new("Highlight")
	hl.Name = "MM2_Highlight"
	hl.Adornee = char
	hl.FillTransparency = 0.6
	hl.OutlineTransparency = 0
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Parent = CoreGui

	-- Billboard label parented to a part (Head preferred)
	local bb = Instance.new("BillboardGui")
	bb.Name = "MM2_Label"
	bb.Size = LABEL_SIZE
	bb.StudsOffset = BILLBOARD_OFFSET
	bb.AlwaysOnTop = true
	-- parent to the adornment part so it follows automatically
	bb.Parent = part

	local txt = Instance.new("TextLabel", bb)
	txt.BackgroundTransparency = 1
	txt.Size = UDim2.new(1,0,1,0)
	txt.Font = Enum.Font.SourceSansBold
	txt.TextScaled = true
	txt.Text = ""
	txt.TextColor3 = Color3.new(1,1,1)

	playerESP[player] = {
		highlight = hl,
		billboard = bb,
		label = txt,
		conns = {}
	}

	-- initial role update
	local role = getRole(player)
	local color = ROLE_COLORS[role] or ROLE_COLORS.Innocent
	hl.FillColor = color
	hl.OutlineColor = color
	txt.Text = role
	txt.TextColor3 = color
end

local function removePlayerESP(player)
	local data = playerESP[player]
	if not data then return end
	safeDestroy(data.highlight)
	safeDestroy(data.billboard)
	for _, c in ipairs(data.conns) do
		pcall(function() c:Disconnect() end)
	end
	playerESP[player] = nil
end

-- Update role colors/text for a single player (called when tools/backpack/character changes)
local function updatePlayerRole(player)
	local data = playerESP[player]
	if not data then
		-- create if not present
		createPlayerESP(player)
		data = playerESP[player]
		if not data then return end
	end
	local role = getRole(player)
	local color = ROLE_COLORS[role] or ROLE_COLORS.Innocent
	-- apply colors/text
	pcall(function()
		data.highlight.FillColor = color
		data.highlight.OutlineColor = color
		data.label.Text = role
		data.label.TextColor3 = color
	end)
end

-- Wire up per-player listeners (Backpack & Character changes)
local function setupPlayerListeners(player)
	-- avoid double-wiring
	if playerESP[player] and next(playerESP[player].conns) then return end

	local function onCharAdded(char)
		-- small delay to let parts spawn
		task.spawn(function()
			task.wait(0.05)
			createPlayerESP(player)
			updatePlayerRole(player)
		end)
	end

	local function onBackpackChanged()
		updatePlayerRole(player)
	end

	-- connect
	local charConn = nil
	if player.Character then
		onCharAdded(player.Character)
	end
	charConn = player.CharacterAdded:Connect(onCharAdded)
	local bp = player:FindFirstChild("Backpack")
	local backpackConn
	if bp then
		backpackConn = bp.ChildAdded:Connect(onBackpackChanged)
		-- also removals
		backpackConn = bp.ChildAdded:Connect(function() updatePlayerRole(player) end)
	end

	-- watch character child added/removed for Knife/Gun
	local charChildConn
	charChildConn = player.CharacterAdded:Connect(function(char)
		-- child added/removed handlers
		local addedConn = char.ChildAdded:Connect(function(child)
			if child.Name == "Knife" or child.Name == "Gun" then
				updatePlayerRole(player)
			end
		end)
		local removedConn = char.ChildRemoved:Connect(function(child)
			if child.Name == "Knife" or child.Name == "Gun" then
				updatePlayerRole(player)
			end
		end)
		-- store and cleanup when character removed
		table.insert(playerESP[player].conns, addedConn)
		table.insert(playerESP[player].conns, removedConn)
	end)

	-- store connections so they can be disconnected later
	playerESP[player] = playerESP[player] or {}
	playerESP[player].conns = playerESP[player].conns or {}
	table.insert(playerESP[player].conns, charConn)
	if backpackConn then table.insert(playerESP[player].conns, backpackConn) end
	table.insert(playerESP[player].conns, charChildConn)
end

-- Player handlers
Players.PlayerAdded:Connect(function(pl)
	-- create ESP and listeners when character spawns
	pl.CharacterAdded:Connect(function()
		createPlayerESP(pl)
		updatePlayerRole(pl)
		setupPlayerListeners(pl)
	end)
end)

Players.PlayerRemoving:Connect(function(pl)
	removePlayerESP(pl)
end)

-- Initialize existing players
for _, pl in ipairs(Players:GetPlayers()) do
	if pl ~= LocalPlayer then
		if pl.Character then
			createPlayerESP(pl)
			updatePlayerRole(pl)
		end
		setupPlayerListeners(pl)
	end
end

-- ---- Dropped gun handling (event-driven) ----
local function createGunESP(tool)
	if gunESP[tool] then return end
	local part = tool:FindFirstChildWhichIsA("BasePart", true) -- search descendants
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
	lbl.Size = UDim2.new(1,0,1,0)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.SourceSansBold
	lbl.TextScaled = true
	lbl.Text = "Gun"
	lbl.TextColor3 = ROLE_COLORS.Gun

	gunESP[tool] = { highlight = hl, billboard = bb }

	-- cleanup when tool removed/parented elsewhere
	local function cleanup()
		local g = gunESP[tool]
		if g then
			safeDestroy(g.highlight)
			safeDestroy(g.billboard)
			gunESP[tool] = nil
		end
	end

	tool.AncestryChanged:Connect(function(_, parent)
		if not tool.Parent then
			cleanup()
		end
	end)
	tool.Destroying:Connect(cleanup)
end

-- initial scan for existing dropped guns (one-time)
for _, inst in ipairs(Workspace:GetDescendants()) do
	if inst:IsA("Tool") and inst.Name == "GunDrop" then
		createGunESP(inst)
	end
end

-- listen to future tools appearing
Workspace.DescendantAdded:Connect(function(inst)
	if inst:IsA("Tool") and inst.Name == "GunDrop" then
		-- slight delay to allow parts to exist
		task.spawn(function()
			task.wait(0.03)
			if inst.Parent then createGunESP(inst) end
		end)
	end
end)

-- Also guard for tools being parented into workspace later
Workspace.DescendantRemoving:Connect(function(inst)
	if inst:IsA("Tool") and inst.Name == "GunDrop" then
		local g = gunESP[inst]
		if g then
			safeDestroy(g.highlight)
			safeDestroy(g.billboard)
			gunESP[inst] = nil
		end
	end
end)

-- Optional: brief cleanup on local respawn so duplicates don't linger
LocalPlayer.CharacterAdded:Connect(function()
	-- small delay then refresh player ESP (labels/colours will update via listeners)
	task.wait(0.05)
	for pl, _ in pairs(playerESP) do
		-- ensure highlight adornee still valid; recreate if necessary
		if pl.Character then
			updatePlayerRole(pl)
		else
			removePlayerESP(pl)
		end
	end
end)

-- Done. No RenderStepped scanning, event-driven only.
