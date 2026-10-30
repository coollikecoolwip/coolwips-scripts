-- SPECTRA | client-side player spectator
-- Paste the entire file into a client executor, or use a LocalScript in
-- StarterPlayerScripts in your own experience. No remote scripts or UI libraries.
-- L: start/stop | N: next | M: previous | R: refresh | RightShift: minimize
-- X in the header unloads the script and restores the camera.
-- Only characters replicated to this client can be viewed.

local CONFIG = {
    ToggleKey = Enum.KeyCode.L,
    NextKey = Enum.KeyCode.N,
    PreviousKey = Enum.KeyCode.M,
    RefreshKey = Enum.KeyCode.R,
    MinimizeKey = Enum.KeyCode.RightShift,
    AutoStart = false,
}

local Players = game:GetService("Players")
local Input = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    warn("SPECTRA must run on the client.")
    return
end

-- Optional executor functions are feature-detected; PlayerGui is the fallback.
local environment = _G
pcall(function()
    if type(getgenv) == "function" then environment = getgenv() end
end)
local SINGLETON = "__SPECTRA_CLIENT_V1"
local previous = environment[SINGLETON]
if type(previous) == "table" and type(previous.Destroy) == "function" then
    pcall(previous.Destroy)
end

local playerGui = LocalPlayer:WaitForChild("PlayerGui", 10)
if not playerGui then
    warn("SPECTRA: PlayerGui was not available. Try again after loading.")
    return
end
local guiParent = playerGui
pcall(function()
    if type(gethui) == "function" then
        local container = gethui()
        if typeof(container) == "Instance" then guiParent = container end
    end
end)
-- Also catches reruns in executors that do not preserve their global table.
for _, container in ipairs({playerGui, guiParent}) do
    for _, child in ipairs(container:GetChildren()) do
        if child.Name == "SpectraClientGui" and child:IsA("ScreenGui") then
            child:Destroy()
        end
    end
end

local C = {
    Background = Color3.fromRGB(15, 18, 28),
    Surface = Color3.fromRGB(24, 29, 43),
    Raised = Color3.fromRGB(33, 40, 57),
    Hover = Color3.fromRGB(44, 53, 73),
    Line = Color3.fromRGB(52, 63, 85),
    Text = Color3.fromRGB(240, 246, 255),
    Muted = Color3.fromRGB(145, 159, 183),
    Accent = Color3.fromRGB(86, 224, 208),
    Violet = Color3.fromRGB(139, 143, 245),
    Red = Color3.fromRGB(255, 116, 139),
    Amber = Color3.fromRGB(245, 199, 111),
}

local connections, rowConnections, tweens = {}, {}, {}
local destroyed, active, minimized = false, false, false
local roster, rows, target = {}, {}, nil
local cameraSnapshots = {}
local restorePending = false
local thumbCache, thumbRequests = {}, {}
local renderName = "Spectra_" .. HttpService:GenerateGUID(false)
local destroy, selectTarget, refresh, toggle, cycle, paint, renderRows

local function connect(signal, callback, bucket)
    local connection = signal:Connect(callback)
    table.insert(bucket or connections, connection)
    return connection
end

local function disconnectAll(bucket)
    for _, connection in ipairs(bucket) do connection:Disconnect() end
    table.clear(bucket)
end

local function create(class, parent, properties)
    local object = Instance.new(class)
    for key, value in pairs(properties or {}) do object[key] = value end
    object.Parent = parent
    return object
end

local function corner(object, radius)
    create("UICorner", object, {CornerRadius = UDim.new(0, radius or 10)})
end

local function stroke(object, color, transparency)
    return create("UIStroke", object, {
        Color = color or C.Line, Thickness = 1,
        Transparency = transparency or 0.4,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end

local function animate(object, properties, duration)
    if destroyed or not object.Parent then return end
    if tweens[object] then tweens[object]:Cancel() end
    local tween = TweenService:Create(object,
        TweenInfo.new(duration or 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        properties)
    tweens[object] = tween
    tween:Play()
end

local function text(parent, value, position, size, fontSize, color, bold)
    return create("TextLabel", parent, {
        BackgroundTransparency = 1, Position = position, Size = size,
        Text = value, TextColor3 = color or C.Text, TextSize = fontSize or 14,
        Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
end

local function button(parent, value, position, size, background)
    local base = background or C.Raised
    local object = create("TextButton", parent, {
        BackgroundColor3 = base, BorderSizePixel = 0,
        Position = position, Size = size, Text = value, TextColor3 = C.Text,
        TextSize = 13, Font = Enum.Font.GothamBold,
        AutoButtonColor = false, Selectable = true,
    })
    corner(object, 9)
    connect(object.MouseEnter, function()
        animate(object, {BackgroundColor3 = base:Lerp(C.Text, 0.09)})
    end)
    connect(object.MouseLeave, function()
        animate(object, {BackgroundColor3 = base})
    end)
    return object
end

local gui = create("ScreenGui", nil, {
    Name = "SpectraClientGui", ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 1000, IgnoreGuiInset = false,
})
-- Respect Roblox's top bar and device cutouts where supported.
pcall(function() gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets end)
local root = create("Frame", gui, {
    Name = "Root", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
})
local panel = create("Frame", root, {
    Name = "Panel", Size = UDim2.fromOffset(380, 574),
    BackgroundColor3 = C.Background, BorderSizePixel = 0,
    ClipsDescendants = true,
})
corner(panel, 16)
stroke(panel, C.Line, 0.15)
create("UIGradient", panel, {
    Color = ColorSequence.new(C.Background, Color3.fromRGB(22, 25, 41)),
    Rotation = 40,
})
local scale = create("UIScale", panel, {Scale = 1})
local header = create("Frame", panel, {
    Name = "DragHeader", Size = UDim2.fromOffset(282, 64),
    BackgroundTransparency = 1, Active = true,
})
local emblem = create("Frame", header, {
    Position = UDim2.fromOffset(18, 19), Size = UDim2.fromOffset(28, 28),
    BackgroundColor3 = C.Accent, BorderSizePixel = 0,
})
corner(emblem, 9)
local emblemText = text(emblem, "S", UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1), 18, C.Background, true)
emblemText.TextXAlignment = Enum.TextXAlignment.Center
text(header, "SPECTRA", UDim2.fromOffset(57, 14), UDim2.fromOffset(185, 23), 17, C.Text, true)
local headerStatus = text(header, "PLAYER SPECTATOR", UDim2.fromOffset(58, 37), UDim2.fromOffset(212, 14), 9, C.Muted, true)
local minimize = button(panel, "-", UDim2.fromOffset(288, 18), UDim2.fromOffset(32, 30))
local close = button(panel, "X", UDim2.fromOffset(328, 18), UDim2.fromOffset(32, 30))
close.TextColor3 = C.Red
create("Frame", panel, {
    Position = UDim2.fromOffset(18, 64), Size = UDim2.fromOffset(344, 1),
    BackgroundColor3 = C.Line, BackgroundTransparency = 0.5, BorderSizePixel = 0,
})
local body = create("Frame", panel, {
    Name = "Body", Position = UDim2.fromOffset(0, 64),
    Size = UDim2.fromOffset(380, 510), BackgroundTransparency = 1,
})
local card = create("Frame", body, {
    Position = UDim2.fromOffset(18, 16), Size = UDim2.fromOffset(344, 104),
    BackgroundColor3 = C.Surface, BorderSizePixel = 0,
})
corner(card, 12)
stroke(card, C.Accent, 0.75)
local avatar = create("ImageLabel", card, {
    Position = UDim2.fromOffset(14, 22), Size = UDim2.fromOffset(60, 60),
    BackgroundColor3 = C.Raised, BorderSizePixel = 0, Image = "",
})
corner(avatar, 14)
local avatarFallback = text(avatar, "?", UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1), 24, C.Muted, true)
avatarFallback.TextXAlignment = Enum.TextXAlignment.Center
local modeLabel = text(card, "SELECT A PLAYER", UDim2.fromOffset(88, 12), UDim2.fromOffset(240, 14), 9, C.Accent, true)
local displayName = text(card, "Ready when you are", UDim2.fromOffset(88, 29), UDim2.fromOffset(240, 24), 17, C.Text, true)
local username = text(card, "Choose someone below", UDim2.fromOffset(88, 55), UDim2.fromOffset(240, 16), 11, C.Muted)
local healthTrack = create("Frame", card, {
    Position = UDim2.fromOffset(88, 83), Size = UDim2.fromOffset(165, 4),
    BackgroundColor3 = C.Raised, BorderSizePixel = 0,
})
corner(healthTrack, 3)
local healthFill = create("Frame", healthTrack, {
    Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.Accent, BorderSizePixel = 0,
})
corner(healthFill, 3)
local healthText = text(card, "-- HP", UDim2.fromOffset(260, 76), UDim2.fromOffset(69, 16), 10, C.Muted)
healthText.TextXAlignment = Enum.TextXAlignment.Right

local prevButton = button(body, "<  PREV", UDim2.fromOffset(18, 132), UDim2.fromOffset(98, 40))
local refreshButton = button(body, "REFRESH", UDim2.fromOffset(124, 132), UDim2.fromOffset(132, 40))
local nextButton = button(body, "NEXT  >", UDim2.fromOffset(264, 132), UDim2.fromOffset(98, 40))
local search = create("TextBox", body, {
    Position = UDim2.fromOffset(18, 186), Size = UDim2.fromOffset(344, 38),
    BackgroundColor3 = C.Surface, BorderSizePixel = 0,
    Text = "", PlaceholderText = "Search display name or @username...",
    PlaceholderColor3 = C.Muted, TextColor3 = C.Text, TextSize = 12,
    Font = Enum.Font.Gotham, ClearTextOnFocus = false,
    TextXAlignment = Enum.TextXAlignment.Left,
})
corner(search, 9)
stroke(search, C.Line, 0.6)
create("UIPadding", search, {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)})
local list = create("ScrollingFrame", body, {
    Name = "Players", Position = UDim2.fromOffset(18, 236),
    Size = UDim2.fromOffset(344, 174), BackgroundTransparency = 1,
    BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = C.Accent,
    CanvasSize = UDim2.fromOffset(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y,
})
create("UIListLayout", list, {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder})
create("UIPadding", list, {PaddingRight = UDim.new(0, 7), PaddingBottom = UDim.new(0, 3)})
local empty = text(body, "No other players in this server.", UDim2.fromOffset(26, 280), UDim2.fromOffset(328, 70), 13, C.Muted)
empty.TextXAlignment = Enum.TextXAlignment.Center
empty.TextWrapped = true
local action = button(body, "START SPECTATING", UDim2.fromOffset(18, 424), UDim2.fromOffset(344, 44), C.Accent)
action.TextColor3 = C.Background
local footer = text(body, "L toggle   /   N next   /   M prev   /   R refresh", UDim2.fromOffset(18, 480), UDim2.fromOffset(344, 17), 10, C.Muted)
footer.TextXAlignment = Enum.TextXAlignment.Center
if Input.TouchEnabled and not Input.KeyboardEnabled then footer.Text = "Drag the header to move  /  - to minimize  /  X to unload" end

local panelPosition = nil
local function reflow()
    if destroyed then return end
    local viewport = root.AbsoluteSize
    if viewport.X < 1 or viewport.Y < 1 then return end
    scale.Scale = math.max(0.15, math.min(1, (viewport.X - 24) / 380, (viewport.Y - 24) / 574))
    local width, height = 380 * scale.Scale, (minimized and 64 or 574) * scale.Scale
    if not panelPosition then
        panelPosition = Vector2.new((viewport.X - width) / 2, (viewport.Y - height) / 2)
    end
    panelPosition = Vector2.new(
        math.clamp(panelPosition.X, 8, math.max(8, viewport.X - width - 8)),
        math.clamp(panelPosition.Y, 8, math.max(8, viewport.Y - height - 8)))
    panel.Position = UDim2.fromOffset(panelPosition.X, panelPosition.Y)
end
local function setMinimized(value)
    minimized = value
    body.Visible = not value
    panel.Size = UDim2.fromOffset(380, value and 64 or 574)
    minimize.Text = value and "+" or "-"
    reflow()
end
local dragInput, dragStart, dragOrigin
connect(header.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragInput, dragStart, dragOrigin = input, input.Position, panelPosition
    end
end)
connect(Input.InputChanged, function(input)
    if not dragInput or not dragOrigin then return end
    local isMouse = dragInput.UserInputType == Enum.UserInputType.MouseButton1
        and input.UserInputType == Enum.UserInputType.MouseMovement
    if isMouse or input == dragInput then
        local delta = input.Position - dragStart
        panelPosition = dragOrigin + Vector2.new(delta.X, delta.Y)
        reflow()
    end
end)
connect(Input.InputEnded, function(input)
    if input == dragInput or input.UserInputType == Enum.UserInputType.MouseButton1 then dragInput = nil end
end)
connect(root:GetPropertyChangedSignal("AbsoluteSize"), reflow)

local function validPlayer(player)
    return player and player ~= LocalPlayer and player.Parent == Players
end
local function humanoidFor(player, aliveOnly)
    if not player then return nil end
    local character = player.Character
    if not character or not character:IsDescendantOf(workspace) then return nil end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or (aliveOnly and humanoid.Health <= 0) then return nil end
    return humanoid
end

local function snapshot(camera)
    if cameraSnapshots[camera] then return end
    local subject = camera.CameraSubject
    local character = LocalPlayer.Character
    cameraSnapshots[camera] = {
        Subject = subject, Type = camera.CameraType,
        CFrame = camera.CFrame, Focus = camera.Focus,
        WasLocal = subject == nil or (character and subject:IsDescendantOf(character)),
    }
end

local function restoreCamera()
    -- If no target was ever ready, we never took control of the camera.
    if next(cameraSnapshots) == nil then return end
    local camera = workspace.CurrentCamera
    if not camera then restorePending = true return end
    local saved = cameraSnapshots[camera]
    -- A replacement camera that we never controlled belongs to the game.
    if not saved then table.clear(cameraSnapshots) return end
    restorePending = false
    local own = humanoidFor(LocalPlayer, false)
    local subject = saved and saved.Subject
    if saved and not saved.WasLocal and subject and subject:IsDescendantOf(workspace) then
        camera.CameraSubject = subject
    elseif own then
        camera.CameraSubject = own
    else
        restorePending = true
    end
    camera.CameraType = saved and saved.Type or Enum.CameraType.Custom
    if saved and saved.Type == Enum.CameraType.Scriptable then
        camera.CFrame, camera.Focus = saved.CFrame, saved.Focus
        restorePending = false
    end
    table.clear(cameraSnapshots)
end

local function applyCamera()
    if destroyed or not active then return end
    local camera = workspace.CurrentCamera
    local humanoid = validPlayer(target) and humanoidFor(target, true)
    if not camera then return end
    if not humanoid then
        -- Do not keep watching an old target while the selected one respawns.
        -- Keep the session snapshot so Stop can still restore a custom camera.
        if cameraSnapshots[camera] then
            local own = humanoidFor(LocalPlayer, true)
            if own then
                if camera.CameraType ~= Enum.CameraType.Custom then camera.CameraType = Enum.CameraType.Custom end
                if camera.CameraSubject ~= own then camera.CameraSubject = own end
            end
        end
        return
    end
    snapshot(camera)
    if camera.CameraType ~= Enum.CameraType.Custom then camera.CameraType = Enum.CameraType.Custom end
    if camera.CameraSubject ~= humanoid then camera.CameraSubject = humanoid end
end

local function requestAvatar(player)
    if not player then avatar.Image = "" avatarFallback.Visible = true return end
    local cached = thumbCache[player.UserId]
    avatar.Image = cached or ""
    avatarFallback.Visible = not cached
    if cached or thumbRequests[player.UserId] then return end
    thumbRequests[player.UserId] = true
    task.spawn(function()
        local ok, image, ready = pcall(function()
            return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        end)
        thumbRequests[player.UserId] = nil
        if destroyed then return end
        if ok and ready and type(image) == "string" and image ~= "" then
            thumbCache[player.UserId] = image
            if target == player then avatar.Image = image avatarFallback.Visible = false end
        end
    end)
end

paint = function()
    if destroyed then return end
    local humanoid = validPlayer(target) and humanoidFor(target, false)
    local alive = humanoid and humanoid.Health > 0
    local camera = workspace.CurrentCamera
    if target then
        displayName.Text, username.Text = target.DisplayName, "@" .. target.Name
        modeLabel.Text = active and (alive and camera and "NOW SPECTATING" or "WAITING FOR CHARACTER") or "SELECTED PLAYER"
    else
        displayName.Text = #roster > 0 and "Choose your view" or "Just you for now"
        username.Text = #roster > 0 and "Select a player from the list" or "Players appear here when they join"
        modeLabel.Text = active and "WAITING FOR PLAYERS" or "PLAYER SPECTATOR"
    end
    headerStatus.Text = (active and "LIVE" or "READY") .. "  /  " .. tostring(#roster) .. " PLAYERS"
    headerStatus.TextColor3 = active and C.Accent or C.Muted
    action.Text = active and "STOP SPECTATING" or "START SPECTATING"
    action.TextTransparency = not active and #roster == 0 and 0.4 or 0
    local fraction = humanoid and math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1) or 0
    local healthColor = fraction > 0.5 and C.Accent or (fraction > 0.25 and C.Amber or C.Red)
    healthFill.BackgroundColor3 = healthColor
    animate(healthFill, {Size = UDim2.fromScale(fraction, 1)}, 0.18)
    healthText.Text = humanoid and (tostring(math.ceil(math.max(0, humanoid.Health))) .. " HP") or "-- HP"
    for player, row in pairs(rows) do
        local ready = humanoidFor(player, true) ~= nil
        local selected = player == target
        row.Button.BackgroundColor3 = selected and C.Raised or C.Surface
        row.Stroke.Transparency = selected and 0.15 or 1
        row.Status.Text = selected and (active and "LIVE" or "READY") or (ready and "READY" or "WAIT")
        row.Status.TextColor3 = selected and C.Accent or (ready and C.Muted or C.Amber)
        row.Dot.BackgroundColor3 = ready and C.Accent or C.Amber
    end
end

selectTarget = function(player, start)
    if destroyed or not validPlayer(player) then return end
    local changed = target ~= player
    target = player
    if start then active = true restorePending = false end
    if changed then requestAvatar(player) end
    applyCamera()
    paint()
end

renderRows = function()
    disconnectAll(rowConnections)
    for _, row in pairs(rows) do row.Button:Destroy() end
    table.clear(rows)
    local query = string.lower(search.Text):match("^%s*(.-)%s*$") or ""
    if query:sub(1, 1) == "@" then query = query:sub(2) end
    local visibleCount = 0
    for index, player in ipairs(roster) do
        local haystack = string.lower(player.DisplayName .. " " .. player.Name)
        if query == "" or string.find(haystack, query, 1, true) then
            visibleCount = visibleCount + 1
            local row = create("TextButton", list, {
                Name = "Player_" .. player.UserId, Size = UDim2.new(1, 0, 0, 52),
                BackgroundColor3 = C.Surface, BorderSizePixel = 0,
                Text = "", AutoButtonColor = false, LayoutOrder = index,
                Selectable = true,
            })
            corner(row, 9)
            local outline = stroke(row, C.Accent, 1)
            local dot = create("Frame", row, {
                Position = UDim2.fromOffset(12, 23), Size = UDim2.fromOffset(6, 6),
                BackgroundColor3 = C.Accent, BorderSizePixel = 0,
            })
            corner(dot, 6)
            text(row, player.DisplayName, UDim2.fromOffset(28, 8), UDim2.new(1, -100, 0, 18), 12, C.Text, true)
            text(row, "@" .. player.Name, UDim2.fromOffset(28, 29), UDim2.new(1, -100, 0, 14), 10, C.Muted)
            local status = text(row, "READY", UDim2.new(1, -65, 0, 17), UDim2.fromOffset(52, 16), 9, C.Muted, true)
            status.TextXAlignment = Enum.TextXAlignment.Right
            rows[player] = {Button = row, Stroke = outline, Status = status, Dot = dot}
            connect(row.Activated, function() selectTarget(player, true) end, rowConnections)
        end
    end
    empty.Visible = visibleCount == 0
    empty.Text = #roster == 0 and "No other players in this server.\nThis list updates automatically." or "No players match your search."
    paint()
end

refresh = function(excluded)
    if destroyed then return end
    local oldTarget, oldIndex = target, 1
    for index, player in ipairs(roster) do if player == target then oldIndex = index break end end
    roster = {}
    for _, player in ipairs(Players:GetPlayers()) do
        -- PlayerRemoving fires before the player is removed from GetPlayers().
        if player ~= excluded and validPlayer(player) then table.insert(roster, player) end
    end
    table.sort(roster, function(a, b)
        local an, bn = string.lower(a.DisplayName), string.lower(b.DisplayName)
        if an == bn then return a.UserId < b.UserId end
        return an < bn
    end)
    if not table.find(roster, target) then
        target = roster[math.min(oldIndex, #roster)]
        if active and target and not humanoidFor(target, true) then
            for _, player in ipairs(roster) do
                if humanoidFor(player, true) then target = player break end
            end
        end
    end
    if target ~= oldTarget then requestAvatar(target) end
    if active then
        if target then applyCamera() else restoreCamera() end
    end
    renderRows()
end

cycle = function(direction)
    if destroyed then return end
    -- Refresh preserves the selected identity, even when alphabetical order changes.
    refresh()
    if #roster == 0 then return end
    local index = table.find(roster, target) or (direction > 0 and 0 or 1)
    -- One bounded pass: never recurse through missing/dead characters.
    for offset = 1, #roster do
        local candidate = roster[((index - 1 + direction * offset) % #roster) + 1]
        if humanoidFor(candidate, true) then selectTarget(candidate, true) return end
    end
    -- If everyone is respawning, keep a selection and wait safely for it.
    selectTarget(roster[((index - 1 + direction) % #roster) + 1], true)
end

toggle = function()
    if destroyed then return end
    if active then
        active = false
        restoreCamera()
        paint()
    else
        refresh()
        if #roster == 0 then return end
        local candidate = target or roster[1]
        if not humanoidFor(candidate, true) then
            for _, player in ipairs(roster) do
                if humanoidFor(player, true) then candidate = player break end
            end
        end
        selectTarget(candidate, true)
    end
end

local controller = {}
destroy = function(fromGui)
    if destroyed then return end
    destroyed = true
    RunService:UnbindFromRenderStep(renderName)
    if active then active = false restoreCamera() end
    disconnectAll(rowConnections)
    disconnectAll(connections)
    for _, tween in pairs(tweens) do tween:Cancel() end
    table.clear(tweens)
    if environment[SINGLETON] == controller then environment[SINGLETON] = nil end
    if not fromGui then gui:Destroy() end
end
controller.Destroy = function() destroy(false) end
environment[SINGLETON] = controller
connect(gui.Destroying, function() destroy(true) end)
connect(close.Activated, function() destroy(false) end)
connect(minimize.Activated, function() setMinimized(not minimized) end)
connect(action.Activated, toggle)
connect(nextButton.Activated, function() cycle(1) end)
connect(prevButton.Activated, function() cycle(-1) end)
connect(refreshButton.Activated, function() refresh() end)
connect(search:GetPropertyChangedSignal("Text"), function()
    list.CanvasPosition = Vector2.new(0, 0)
    renderRows()
end)
connect(Input.InputBegan, function(input, processed)
    if processed or Input:GetFocusedTextBox() then return end
    if input.KeyCode == CONFIG.ToggleKey then toggle()
    elseif input.KeyCode == CONFIG.NextKey then cycle(1)
    elseif input.KeyCode == CONFIG.PreviousKey then cycle(-1)
    elseif input.KeyCode == CONFIG.RefreshKey then refresh()
    elseif input.KeyCode == CONFIG.MinimizeKey then setMinimized(not minimized) end
end)
connect(Players.PlayerAdded, function() refresh() end)
connect(Players.PlayerRemoving, function(player)
    thumbCache[player.UserId] = nil
    refresh(player)
end)
connect(workspace:GetPropertyChangedSignal("CurrentCamera"), function()
    if active then applyCamera() end
    reflow()
end)
-- Reassert the camera before Roblox's camera update; only write on changes.
-- This also catches local/target respawns, late Humanoids and streaming in.
RunService:BindToRenderStep(renderName, Enum.RenderPriority.Camera.Value - 1, applyCamera)
local elapsed = 0
connect(RunService.Heartbeat, function(dt)
    if restorePending and not active then
        local camera, own = workspace.CurrentCamera, humanoidFor(LocalPlayer, false)
        if camera and own then
            camera.CameraSubject = own
            restorePending = false
        end
    end
    elapsed = elapsed + dt
    if elapsed >= 0.2 then elapsed = 0 paint() end
end)

local ok = pcall(function() gui.Parent = guiParent end)
if not ok then
    ok = pcall(function() gui.Parent = playerGui end)
end
if not ok then
    destroy(false)
    warn("SPECTRA: unable to attach the interface.")
    return
end
refresh()
reflow()
task.defer(function() if not destroyed then reflow() end end)
if CONFIG.AutoStart then toggle() end
