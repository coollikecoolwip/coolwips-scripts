--// Universal ESP v3.4 (Distance Toggle Added)
--// Menu Toggle Key: P
--// Player ESP + NPC ESP (NPC cache, no workspace scanning)
--// Cool draggable UI retained, now with distance toggle

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
local SHOW_DISTANCE = false
local TEAM_MODE     = false
local SHOW_NPCS     = false
local MAX_DISTANCE  = 10000
local UPDATE_RATE   = 0.5

--==============================
-- Color Presets (EXPANDED)
--==============================
local PLAYER_COLORS = {
    {name="Red",color=Color3.fromRGB(255,70,70)},
    {name="Blue",color=Color3.fromRGB(80,170,255)},
    {name="Green",color=Color3.fromRGB(70,255,70)},
    {name="Yellow",color=Color3.fromRGB(255,255,70)},
    {name="Orange",color=Color3.fromRGB(255,170,0)},
    {name="Purple",color=Color3.fromRGB(170,70,255)},
    {name="Pink",color=Color3.fromRGB(255,170,255)},
    {name="Brown",color=Color3.fromRGB(139,69,19)},
    {name="Gray",color=Color3.fromRGB(128,128,128)},
    {name="Beige",color=Color3.fromRGB(245,245,220)},
    {name="Silver",color=Color3.fromRGB(192,192,192)},
    {name="Gold",color=Color3.fromRGB(255,215,0)},
    {name="Cyan",color=Color3.fromRGB(0,255,255)},
    {name="Magenta",color=Color3.fromRGB(255,0,255)},
    {name="Teal",color=Color3.fromRGB(0,128,128)},
    {name="Navy",color=Color3.fromRGB(0,0,128)},
    {name="Lavender",color=Color3.fromRGB(230,230,250)},
    {name="Maroon",color=Color3.fromRGB(128,0,0)},
}

local NPC_COLORS = PLAYER_COLORS

local playerColorIndex = 5
local npcColorIndex = 1

local PLAYER_COLOR = PLAYER_COLORS[playerColorIndex].color
local NPC_COLOR = NPC_COLORS[npcColorIndex].color

--==============================
-- State
--==============================
local ESP_CACHE = {}
local npcCache = {}
local timeAcc = 0
local menuVisible = false

--==============================
-- GUI SETUP
--==============================
local gui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
gui.Name = "UniversalESP"
gui.ResetOnSpawn = false
gui.Enabled = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromOffset(240, 420)
frame.Position = UDim2.fromScale(0.5,0.5) - UDim2.fromOffset(120,210)
frame.BackgroundColor3 = Color3.fromRGB(22,22,22)
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,12)

local function makeButton(y,text)
    local b = Instance.new("TextButton", frame)
    b.Size = UDim2.fromOffset(200,34)
    b.Position = UDim2.fromOffset(20,y)
    b.BackgroundColor3 = Color3.fromRGB(40,40,40)
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 14
    b.Text = text
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
    return b
end

local espBtn  = makeButton(15,"ESP: ON")
local hpBtn   = makeButton(55,"Health: OFF")
local distBtn = makeButton(95,"Distance: ON") -- New button for distance toggle
local teamBtn = makeButton(135,"Team Mode: OFF")
local npcBtn  = makeButton(175,"NPCs: OFF")
local pColBtn = makeButton(215,"Player Color: "..PLAYER_COLORS[1].name)
local nColBtn = makeButton(255,"NPC Color: "..NPC_COLORS[1].name)
local refBtn  = makeButton(295,"Refresh ESP")

--==============================
-- Utility
--==============================
-- Modified to accept and display distance conditionally
local function formatText(name, hum, distance)
    local text = name
    if SHOW_HEALTH and hum then
        text = text .. " | " .. math.floor(hum.Health)
    end
    if SHOW_DISTANCE and distance then -- Conditionally add distance
        text = text .. " | " .. math.floor(distance) .. "m"
    end
    return text
end

local function getPlayerColor(player)
    if TEAM_MODE and player.Team then
        return player.TeamColor.Color
    end
    return PLAYER_COLOR
end

--==============================
-- ESP Core
--==============================
local function clearESP(model)
    local d = ESP_CACHE[model]
    if not d then return end
    if d.hl then d.hl:Destroy() end
    if d.tag then d.tag:Destroy() end
    if d.conn then d.conn:Disconnect() end
    ESP_CACHE[model] = nil
end

-- Modified to accept and pass distance to formatText
local function createESP(model, name, color, distance)
    local hum = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head")
    if not hum or not root then return end

    local hl = Instance.new("Highlight", model)
    hl.FillTransparency = 1
    hl.OutlineColor = color
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = model

    local tag = Instance.new("BillboardGui", model)
    tag.Adornee = root
    tag.Size = UDim2.fromOffset(150,28)
    tag.StudsOffset = Vector3.new(0,2.8,0)
    tag.AlwaysOnTop = true

    local lbl = Instance.new("TextLabel", tag)
    lbl.Size = UDim2.fromScale(1,1)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 16
    lbl.TextColor3 = color
    lbl.Text = formatText(name, hum, distance) -- Use new formatText with distance

    local conn = hum.HealthChanged:Connect(function()
        if ESP_CACHE[model] then
            -- Distance is fixed for this entity, only health might change
            lbl.Text = formatText(name, hum, distance)
        end
    end)

    ESP_CACHE[model] = {hl=hl, tag=tag, lbl=lbl, hum=hum, conn=conn}
end

-- Modified to accept and pass distance to formatText
local function updateESP(model, name, color, distance) -- Added distance parameter
    local d = ESP_CACHE[model]
    if not d then return end
    d.lbl.Text = formatText(name, d.hum, distance) -- Use new formatText with distance
    d.lbl.TextColor3 = color
    d.hl.OutlineColor = color
end

--==============================
-- NPC Cache
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

for _, obj in ipairs(workspace:GetDescendants()) do
    tryAddNPC(obj)
end
workspace.DescendantAdded:Connect(tryAddNPC)
workspace.DescendantRemoving:Connect(function(m)
    npcCache[m] = nil
    clearESP(m)
end)

--==============================
-- Refresh Logic
--==============================
local function refreshESP()
    if not ESP_ENABLED then
        for m in pairs(ESP_CACHE) do clearESP(m) end
        return
    end

    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local pos = root.Position
    local seen = {}

    -- Players
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local r = plr.Character:FindFirstChild("HumanoidRootPart")
            if r then
                local distanceToPlayer = (pos - r.Position).Magnitude
                if distanceToPlayer <= MAX_DISTANCE then -- Filter by MAX_DISTANCE
                    seen[plr.Character] = true
                    local c = getPlayerColor(plr)
                    if ESP_CACHE[plr.Character] then
                        updateESP(plr.Character, plr.Name, c, distanceToPlayer) -- Pass distance
                    else
                        createESP(plr.Character, plr.Name, c, distanceToPlayer) -- Pass distance
                    end
                end
            end
        end
    end

    -- NPCs
    if SHOW_NPCS then
        for model, data in pairs(npcCache) do
            local distanceToNPC = (pos - data.root.Position).Magnitude
            if distanceToNPC <= MAX_DISTANCE then -- Filter by MAX_DISTANCE
                seen[model] = true
                if ESP_CACHE[model] then
                    updateESP(model, data.name, NPC_COLOR, distanceToNPC) -- Pass distance
                else
                    createESP(model, data.name, NPC_COLOR, distanceToNPC) -- Pass distance
                end
            end
        end
    end

    -- Cleanup entities outside of range or no longer relevant
    for m in pairs(ESP_CACHE) do
        if not seen[m] then clearESP(m) end
    end
end

--==============================
-- Buttons
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

distBtn.MouseButton1Click:Connect(function() -- New button logic for distance toggle
    SHOW_DISTANCE = not SHOW_DISTANCE
    distBtn.Text = SHOW_DISTANCE and "Distance: ON" or "Distance: OFF"
    refreshESP() -- Refresh to update text immediately
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

pColBtn.MouseButton1Click:Connect(function()
    playerColorIndex = playerColorIndex % #PLAYER_COLORS + 1
    PLAYER_COLOR = PLAYER_COLORS[playerColorIndex].color
    pColBtn.Text = "Player Color: "..PLAYER_COLORS[playerColorIndex].name
    refreshESP()
end)

nColBtn.MouseButton1Click:Connect(function()
    npcColorIndex = npcColorIndex % #NPC_COLORS + 1
    NPC_COLOR = NPC_COLORS[npcColorIndex].color
    nColBtn.Text = "NPC Color: "..NPC_COLORS[npcColorIndex].name
    refreshESP()
end)

refBtn.MouseButton1Click:Connect(refreshESP)

--==============================
-- Menu Toggle
--==============================
UserInputService.InputBegan:Connect(function(i,gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.P then
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
