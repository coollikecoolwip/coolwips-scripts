-- Desktop Roblox aim assistant. Executor input APIs are optional and nonstandard.
-- T: camera aim | U: mouse aim | Y: trigger | H: menu | F8: calibrate
-- Z/X: radius | C/V: response | End: unload
-- All features start disabled. No Drawing API, remote loaders, or network calls.
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")
local GuiService = game:GetService("GuiService")
local LP = Players.LocalPlayer
assert(LP, "Run on the client after joining a game")
local PG = LP:WaitForChild("PlayerGui")

local Config = {
    Radius = 300,                 -- pixels, not degrees
    Response = 0.10,              -- fraction of error corrected at 60 FPS
    MouseGain = Vector2.new(1, 1), -- tune for executor/game mouse sensitivity
    MaxMouseStep = 80,
    Deadzone = 0.75,
    MaxDistance = 1500,           -- studs
    RequireRightMouse = false,
    TeamCheck = true,
    RespectForceFields = true,
    ClickInterval = 0.12,
    Anchor = "Auto",             -- Auto, Center, Mouse, Calibrated
    Offset = Vector2.new(0, 0),
    CrosshairPath = nil,          -- e.g. {"WeaponHUD", "Crosshair"}, from PlayerGui
    Parts = {"Head", "UpperTorso", "Torso", "HumanoidRootPart"},
    SwitchRatio = 0.80,           -- switch only for a noticeably closer target
}

local env = _G
if type(getgenv) == "function" then
    local ok, value = pcall(getgenv)
    if ok and type(value) == "table" then env = value end
end
local KEY = "__ViewportAimAssistantV1"
local previous = env[KEY]
if type(previous) == "table" and type(previous.Stop) == "function" then
    pcall(previous.Stop)
end
local function capability(name, direct)
    if type(direct) == "function" then return direct end
    if type(env[name]) == "function" then return env[name] end
    if type(_G[name]) == "function" then return _G[name] end
end
local moveMouse = capability("mousemoverel", mousemoverel)
local clickMouse = capability("mouse1click", mouse1click)
local alive, mode, trigger = true, "Off", false
local connections, rows = {}, {}
local excludedPlayers, excludedTeams = {}, {}
local targetPlayer, targetPart, detected, calibrated
local nextScan, nextClick, nextStatus = 0, 0, 0
local notice, noticeUntil = "", 0
local windowFocused, dragging = true, false
local dragOrigin, frameOrigin
local gui, panel, status, refreshControls
local function connect(signal, fn)
    local c = signal:Connect(fn)
    connections[#connections + 1] = c
    return c
end
local function say(message)
    notice, noticeUntil = message, os.clock() + 5
    warn("[Aim assistant] " .. message)
end
local function stop()
    if not alive then return end
    alive = false
    for _, c in ipairs(connections) do c:Disconnect() end
    for _, row in pairs(rows) do row.connection:Disconnect() end
    if gui then gui:Destroy() end
    if env[KEY] and env[KEY].Stop == stop then env[KEY] = nil end
end
env[KEY] = {Stop = stop, Config = Config}

gui = Instance.new("ScreenGui")
gui.Name = "ViewportAimAssistant"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 10000
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
-- Try optional executor UI root, then CoreGui, then ordinary PlayerGui.
local roots = {}
local getUI = capability("gethui", gethui)
if getUI then
    local ok, root = pcall(getUI)
    if ok and typeof(root) == "Instance" then roots[#roots + 1] = root end
end
local okCore, core = pcall(function() return game:GetService("CoreGui") end)
if okCore then roots[#roots + 1] = core end
roots[#roots + 1] = PG
for _, root in ipairs(roots) do
    local ok = pcall(function() gui.Parent = root end)
    if ok and gui.Parent == root then break end
end
if not gui.Parent then stop(); error("Unable to create interface") end

local function make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do obj[k] = v end
    obj.Parent = parent
    return obj
end
local zero = make("Frame", {Size = UDim2.fromOffset(0, 0),
    BackgroundTransparency = 1}, gui)
local ring = make("Frame", {AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1, Visible = false}, gui)
make("UICorner", {CornerRadius = UDim.new(1, 0)}, ring)
make("UIStroke", {Thickness = 1, Color = Color3.fromRGB(120, 210, 255)}, ring)
local dot = make("Frame", {Size = UDim2.fromOffset(5, 5),
    AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(255, 210, 70),
    BorderSizePixel = 0, Visible = false}, gui)
panel = make("Frame", {Size = UDim2.fromOffset(310, 510),
    Position = UDim2.fromOffset(20, 70), BackgroundColor3 = Color3.fromRGB(27, 29, 35),
    BorderSizePixel = 0, Active = true}, gui)
make("UICorner", {CornerRadius = UDim.new(0, 8)}, panel)
local function label(text, y, height)
    return make("TextLabel", {Text = text, Size = UDim2.new(1, -20, 0, height or 22),
        Position = UDim2.fromOffset(10, y), BackgroundTransparency = 1,
        TextColor3 = Color3.fromRGB(225, 230, 240), Font = Enum.Font.SourceSans,
        TextSize = 16, TextWrapped = true}, panel)
end
local function button(text, y, fn)
    local b = make("TextButton", {Text = text, Size = UDim2.new(1, -20, 0, 29),
        Position = UDim2.fromOffset(10, y), BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(48, 54, 65), TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.SourceSans, TextSize = 16}, panel)
    connect(b.Activated, fn)
    return b
end
local title = label("AIM ASSISTANT  •  drag here", 5, 28)
title.Active = true
connect(title.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging, dragOrigin, frameOrigin = true, input.Position, panel.Position
    end
end)
connect(UIS.InputChanged, function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragOrigin
        panel.Position = UDim2.fromOffset(frameOrigin.X.Offset + delta.X, frameOrigin.Y.Offset + delta.Y)
    end
end)
connect(UIS.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
local function setMode(value)
    if value == "Mouse" and not moveMouse then say("mousemoverel unavailable; mouse aim disabled"); return end
    mode = mode == value and "Off" or value
    targetPlayer, targetPart = nil, nil
    if refreshControls then refreshControls() end
end
local function toggleTrigger()
    if not clickMouse then say("mouse1click unavailable; trigger disabled"); return end
    trigger = not trigger
    if refreshControls then refreshControls() end
end
local cameraButton = button("", 38, function() setMode("Camera") end)
local mouseButton = button("", 72, function() setMode("Mouse") end)
local triggerButton = button("", 106, toggleTrigger)
local anchors = {"Auto", "Center", "Mouse", "Calibrated"}
local anchorButton = button("", 140, function()
    local index = table.find(anchors, Config.Anchor) or 1
    Config.Anchor = anchors[index % #anchors + 1]
    refreshControls()
end)
local holdButton = button("", 174, function()
    Config.RequireRightMouse = not Config.RequireRightMouse
    refreshControls()
end)
local settingsLabel = label("", 208, 35)
label("F8: calibrate at cursor | H: hide menu", 247)
status = label("", 272, 48)
label("Excluded players / teams (click to toggle)", 325)
local list = make("ScrollingFrame", {Position = UDim2.fromOffset(10, 352),
    Size = UDim2.new(1, -20, 0, 110), BackgroundTransparency = 1,
    BorderSizePixel = 0, ScrollBarThickness = 5, CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y}, panel)
make("UIListLayout", {Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.Name}, list)
button("Unload [End]", 473, stop)
refreshControls = function()
    cameraButton.Text = "[T] Camera aim: " .. (mode == "Camera" and "ON" or "OFF")
    mouseButton.Text = "[U] Mouse aim: " .. (not moveMouse and "UNAVAILABLE" or mode == "Mouse" and "ON" or "OFF")
    triggerButton.Text = "[Y] Trigger: " .. (not clickMouse and "UNAVAILABLE" or trigger and "ON" or "OFF")
    anchorButton.Text = "Alignment: " .. Config.Anchor .. " (click to change)"
    holdButton.Text = "Require right mouse: " .. (Config.RequireRightMouse and "YES" or "NO")
    settingsLabel.Text = string.format("Radius [Z/X]: %d px\nResponse [C/V]: %.2f", Config.Radius, Config.Response)
end
refreshControls()
local function addRow(obj, isTeam)
    if obj == LP or rows[obj] then return end
    local bucket = isTeam and excludedTeams or excludedPlayers
    local key = isTeam and obj or obj.UserId
    local b = make("TextButton", {Name = (isTeam and "B" or "A") .. obj.Name,
        Size = UDim2.new(1, -8, 0, 25), BorderSizePixel = 0,
        TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.SourceSans, TextSize = 15}, list)
    local function update()
        b.Text = (bucket[key] and "[X] " or "[ ] ") .. (isTeam and "Team: " or "") .. obj.Name
        b.BackgroundColor3 = bucket[key] and Color3.fromRGB(135, 55, 55) or Color3.fromRGB(48, 54, 65)
    end
    rows[obj] = {button = b, connection = b.Activated:Connect(function()
        bucket[key] = not bucket[key]
        update()
    end)}
    update()
end
local function removeRow(obj)
    local row = rows[obj]
    if row then row.connection:Disconnect(); row.button:Destroy(); rows[obj] = nil end
    excludedTeams[obj] = nil
    if targetPlayer == obj then targetPlayer, targetPart = nil, nil end
end
connect(Players.PlayerAdded, function(p) addRow(p, false) end)
connect(Players.PlayerRemoving, removeRow)
connect(Teams.ChildAdded, function(t) if t:IsA("Team") then addRow(t, true) end end)
connect(Teams.ChildRemoved, removeRow)
for _, p in ipairs(Players:GetPlayers()) do addRow(p, false) end
for _, t in ipairs(Teams:GetTeams()) do addRow(t, true) end

local function visibleUI(obj)
    if not obj or not obj:IsA("GuiObject") or not obj:IsDescendantOf(PG) then return false end
    local node = obj
    while node and node ~= PG do
        if node:IsA("GuiObject") and not node.Visible then return false end
        if node:IsA("ScreenGui") and not node.Enabled then return false end
        node = node.Parent
    end
    return obj.AbsoluteSize.X > 0 and obj.AbsoluteSize.Y > 0
end
local function guiCenter(obj)
    -- Relative AbsolutePosition cancels the GUI origin/inset shared with our overlay.
    return obj.AbsolutePosition + obj.AbsoluteSize * 0.5 - zero.AbsolutePosition
end
local crosshairNames = {crosshair = true, reticle = true, aimpoint = true, crosshaircenter = true}
local function scanCrosshair(camera)
    if Config.CrosshairPath then
        local obj = PG
        for _, name in ipairs(Config.CrosshairPath) do obj = obj and obj:FindFirstChild(name) end
        detected = visibleUI(obj) and obj or nil
        return
    end
    local best, bestScore
    local center = camera.ViewportSize * 0.5
    for _, obj in ipairs(PG:GetDescendants()) do
        if obj ~= gui and not obj:IsDescendantOf(gui) and obj:IsA("GuiObject") then
            local name = string.lower(obj.Name):gsub("[%s_%-]", "")
            if crosshairNames[name] and visibleUI(obj) then
                local size = obj.AbsoluteSize
                local distance = (guiCenter(obj) - center).Magnitude
                if size.X <= 160 and size.Y <= 160 and distance < math.min(center.X, center.Y) then
                    local score = distance + (size.X + size.Y) * 0.05
                    if not bestScore or score < bestScore then best, bestScore = obj, score end
                end
            end
        end
    end
    detected = best
end
local function anchor(camera)
    local size = camera.ViewportSize
    local point, source
    if Config.Anchor == "Mouse" then point, source = UIS:GetMouseLocation(), "cursor"
    elseif Config.Anchor == "Calibrated" and calibrated then
        point, source = Vector2.new(calibrated.X * size.X, calibrated.Y * size.Y), "calibrated"
    elseif Config.Anchor == "Auto" and visibleUI(detected) then
        point, source = guiCenter(detected), "GUI: " .. detected.Name
    elseif Config.Anchor == "Auto" and UIS.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
        point, source = UIS:GetMouseLocation(), "cursor fallback"
    else point, source = size * 0.5, "screen center" end
    return point + Config.Offset, source
end
local function eligible(player)
    if player == LP or player.Parent ~= Players or excludedPlayers[player.UserId] then return nil end
    if player.Team and excludedTeams[player.Team] then return nil end
    if Config.TeamCheck and not LP.Neutral and not player.Neutral and LP.Team and LP.Team == player.Team then return nil end
    local character = player.Character
    local hum = character and character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return nil end
    if Config.RespectForceFields and character:FindFirstChildOfClass("ForceField") then return nil end
    return character
end
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.IgnoreWater = true
local function clearSight(camera, character, part)
    local delta = part.Position - camera.CFrame.Position
    if delta.Magnitude < 0.001 or delta.Magnitude > Config.MaxDistance then return false end
    local result = workspace:Raycast(camera.CFrame.Position, delta, params)
    return result == nil or result.Instance:IsDescendantOf(character)
end
local function evaluate(camera, point, player)
    local character = eligible(player)
    if not character then return nil end
    -- Prefer the head; use another body part only when the preferred one is unavailable/blocked.
    for _, name in ipairs(Config.Parts) do
        local part = character:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            local projected, onScreen = camera:WorldToViewportPoint(part.Position)
            local distance = (Vector2.new(projected.X, projected.Y) - point).Magnitude
            if onScreen and projected.Z > 0 and distance <= Config.Radius and clearSight(camera, character, part) then
                return part, distance
            end
        end
    end
end
local function chooseTarget(camera, point)
    local heldPart, heldDistance
    if targetPlayer then heldPart, heldDistance = evaluate(camera, point, targetPlayer) end
    local bestPlayer, bestPart, bestDistance = nil, nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        local part, distance
        if player == targetPlayer then part, distance = heldPart, heldDistance
        else part, distance = evaluate(camera, point, player) end
        if part and distance < bestDistance then bestPlayer, bestPart, bestDistance = player, part, distance end
    end
    if heldPart and (bestPlayer == targetPlayer or bestDistance >= heldDistance * Config.SwitchRatio) then
        return targetPlayer, heldPart
    end
    return bestPlayer, bestPart
end
local function blockedInput()
    if not windowFocused or dragging or UIS:GetFocusedTextBox() then return true end
    if GuiService.MenuIsOpen then return true end
    if Config.RequireRightMouse and not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return true end
    if panel.Visible then
        local mouse = UIS:GetMouseLocation()
        local p, s = panel.AbsolutePosition - zero.AbsolutePosition, panel.AbsoluteSize
        if mouse.X >= p.X and mouse.X <= p.X + s.X and mouse.Y >= p.Y and mouse.Y <= p.Y + s.Y then return true end
    end
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return not hum or hum.Health <= 0
end
local function triggerAt(camera, point, now)
    if not trigger or not clickMouse or now < nextClick then return end
    local ray = camera:ViewportPointToRay(point.X, point.Y)
    local result = workspace:Raycast(ray.Origin, ray.Direction * Config.MaxDistance, params)
    if not result then return end
    -- Ascend through nested accessory/weapon Models to the actual character.
    local node = result.Instance
    while node and node ~= workspace do
        if node:IsA("Model") then
            local player = Players:GetPlayerFromCharacter(node)
            if player and eligible(player) == node then
                nextClick = now + math.max(0.03, Config.ClickInterval)
                local ok, err = pcall(clickMouse)
                if not ok then trigger = false; say("Click API failed: " .. tostring(err)); refreshControls() end
                return
            end
        end
        node = node.Parent
    end
end
connect(UIS.WindowFocusReleased, function() windowFocused, dragging = false, false end)
connect(UIS.WindowFocused, function() windowFocused = true end)
connect(UIS.InputBegan, function(input, processed)
    if processed or UIS:GetFocusedTextBox() then return end
    local key = input.KeyCode
    if key == Enum.KeyCode.End then stop(); return
    elseif key == Enum.KeyCode.T then setMode("Camera")
    elseif key == Enum.KeyCode.U then setMode("Mouse")
    elseif key == Enum.KeyCode.Y then toggleTrigger()
    elseif key == Enum.KeyCode.H then panel.Visible = not panel.Visible
    elseif key == Enum.KeyCode.Z then Config.Radius = math.max(20, Config.Radius - 10)
    elseif key == Enum.KeyCode.X then Config.Radius = math.min(1000, Config.Radius + 10)
    elseif key == Enum.KeyCode.C then Config.Response = math.max(0.01, Config.Response - 0.01)
    elseif key == Enum.KeyCode.V then Config.Response = math.min(1, Config.Response + 0.01)
    elseif key == Enum.KeyCode.F8 then
        local camera = workspace.CurrentCamera
        if camera and camera.ViewportSize.X > 0 and camera.ViewportSize.Y > 0 then
            local mouse, size = UIS:GetMouseLocation(), camera.ViewportSize
            calibrated = Vector2.new(mouse.X / size.X, mouse.Y / size.Y)
            Config.Anchor = "Calibrated"
            say("Alignment saved. The yellow dot marks the saved crosshair position.")
        end
    end
    refreshControls()
end)

local function step(dt)
    if not alive then return end
    local camera = workspace.CurrentCamera
    if not camera or camera.ViewportSize.X <= 0 then ring.Visible, dot.Visible = false, false; return end
    local now = os.clock()
    if now >= nextScan and (panel.Visible or mode ~= "Off" or trigger) then
        nextScan = now + 1
        if Config.Anchor == "Auto" then scanCrosshair(camera) end
    end
    local point, source = anchor(camera)
    ring.Position, dot.Position = UDim2.fromOffset(point.X, point.Y), UDim2.fromOffset(point.X, point.Y)
    ring.Size = UDim2.fromOffset(Config.Radius * 2, Config.Radius * 2)
    ring.Visible, dot.Visible = mode ~= "Off", panel.Visible or mode ~= "Off" or trigger
    local paused = blockedInput()
    params.FilterDescendantsInstances = LP.Character and {LP.Character} or {}
    if paused or mode == "Off" then targetPlayer, targetPart = nil, nil
    else
        targetPlayer, targetPart = chooseTarget(camera, point)
        if targetPart then
            local alpha = 1 - (1 - math.clamp(Config.Response, 0.01, 1)) ^ (math.clamp(dt, 0, 0.1) * 60)
            if mode == "Mouse" then
                local projected = camera:WorldToViewportPoint(targetPart.Position)
                local errorPixels = Vector2.new(projected.X, projected.Y) - point
                if errorPixels.Magnitude > Config.Deadzone then
                    local movement = Vector2.new(errorPixels.X * Config.MouseGain.X, errorPixels.Y * Config.MouseGain.Y) * alpha
                    if movement.Magnitude > Config.MaxMouseStep then movement = movement.Unit * Config.MaxMouseStep end
                    local ok, err = pcall(moveMouse, movement.X, movement.Y)
                    if not ok then mode = "Off"; moveMouse = nil; say("Mouse API failed: " .. tostring(err)); refreshControls() end
                end
            elseif mode == "Camera" then
                -- Rotate the ray THROUGH the chosen crosshair, including off-center crosshairs.
                local from = camera:ViewportPointToRay(point.X, point.Y).Direction.Unit
                local to = (targetPart.Position - camera.CFrame.Position).Unit
                local axis = from:Cross(to)
                local angle = math.acos(math.clamp(from:Dot(to), -1, 1))
                if axis.Magnitude > 0.000001 then
                    camera.CFrame = CFrame.new(camera.CFrame.Position) * CFrame.fromAxisAngle(axis.Unit, angle * alpha) * camera.CFrame.Rotation
                end
            end
        end
    end
    if not paused then triggerAt(camera, point, now) end
    if now >= nextStatus then
        nextStatus = now + 0.15
        status.Text = now < noticeUntil and notice or ("Alignment: " .. source .. "\n" .. (paused and "Paused (input/menu/character)" or targetPlayer and "Target: " .. targetPlayer.Name or "No selected target"))
    end
end
-- Run after Roblox's normal camera update; unique name allows deterministic cleanup.
local binding = "ViewportAimAssistant_" .. tostring(LP.UserId)
local failures = 0
local function guardedStep(dt)
    local ok, err = pcall(step, dt)
    if ok then failures = 0
    else
        failures = failures + 1
        if failures == 1 then say("Update failed: " .. tostring(err)) end
        if failures >= 3 then say("Stopped after repeated update errors"); stop() end
    end
end
local bound = pcall(function()
    RunService:BindToRenderStep(binding, Enum.RenderPriority.Camera.Value + 1, guardedStep)
end)
if bound then
    -- Track binding through the same disconnect protocol as event connections.
    connections[#connections + 1] = {Disconnect = function() RunService:UnbindFromRenderStep(binding) end}
else connect(RunService.RenderStepped, guardedStep) end
connect(gui.Destroying, stop)
