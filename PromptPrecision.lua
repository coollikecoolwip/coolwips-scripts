-- Prompt Precision v2
-- Client-side ProximityPrompt automation. No remote downloads or dependencies.
-- Matches ActionText exactly after trimming whitespace and lowercasing.
-- Right Shift: show/hide panel. X: stop, release input, and unload.
-- Uses each prompt's normal range and hold duration. Game/server rules still apply.

local CONFIG = {
    Cooldown = 0.35,          -- Seconds AFTER releasing a prompt before retrying it.
    RangeLimit = nil,        -- Optional distance cap; nil uses MaxActivationDistance.
    TickInterval = 0.05,
    TargetActions = {},      -- Optional starting values, e.g. { "Open Door", "Collect" }.
}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local PPS = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

assert(RunService:IsClient(), "[Prompt Precision] Run this on the Roblox client.")
local player = Players.LocalPlayer
assert(player, "[Prompt Precision] LocalPlayer is not available yet; retry after loading.")
local playerGui = player:WaitForChild("PlayerGui", 15)
assert(playerGui, "[Prompt Precision] PlayerGui did not load; retry after loading.")

-- Keep a cleanup function so re-executing replaces the previous instance.
local environment = _G
if type(getgenv) == "function" then
    local ok, result = pcall(getgenv)
    if ok and type(result) == "table" then environment = result end
end
local REGISTRY_KEY = "__PromptPrecisionV2"
local previous = environment[REGISTRY_KEY]
if type(previous) == "table" and type(previous.Destroy) == "function" then
    pcall(previous.Destroy)
end

local controller = {}
local alive, running = true, false
local connections = {}
local records, targets, targetOrder = {}, {}, {}
local active = nil
local confirmed = 0
local nextStart = 0
local notice, noticeUntil = "", 0
local screen, toggle, status, list, input, cooldownBox
local destroy, refreshList

local function trim(value)
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function normalize(value)
    return string.lower(trim(value))
end

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(connections, connection)
    return connection
end

local function tell(message)
    notice, noticeUntil = message, os.clock() + 3
end

local function characterRoot()
    local character = player.Character
    if not character or not character:IsDescendantOf(Workspace) then return nil end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
        return nil
    end
    return root, character
end

local function promptPosition(prompt)
    local parent = prompt.Parent
    if not parent then return nil end
    if parent:IsA("Attachment") then return parent.WorldPosition end
    if parent:IsA("BasePart") then return parent.Position end
    if parent:IsA("Model") and parent.PrimaryPart then
        return parent.PrimaryPart.Position
    end
    return nil
end

local function track(instance)
    if not instance:IsA("ProximityPrompt") or records[instance] then return end
    if instance:IsDescendantOf(Workspace) then
        records[instance] = { readyAt = 0, lastAttempt = -math.huge }
    end
end

local function distanceTo(prompt, record, root, character, requireTarget)
    if not PPS.Enabled or not prompt:IsDescendantOf(Workspace) or not prompt.Enabled then
        return nil
    end
    if record.shown == false then return nil end
    if requireTarget and not targets[normalize(prompt.ActionText)] then return nil end
    local position = promptPosition(prompt)
    if not position then return nil end
    local distance = (root.Position - position).Magnitude
    local limit = prompt.MaxActivationDistance
    if CONFIG.RangeLimit then limit = math.min(limit, CONFIG.RangeLimit) end
    if distance > limit then return nil end

    -- PromptShown/Hidden tracks engine visibility and exclusivity. For prompts
    -- already visible when this script loads, estimate line of sight until the
    -- first visibility event arrives. Never change the prompt's properties.
    if record.shown == nil and prompt.RequiresLineOfSight then
        local camera = Workspace.CurrentCamera
        if not camera then return nil end
        local ignoredParent = prompt.Parent
        if ignoredParent:IsA("Attachment") then
            ignoredParent = ignoredParent:FindFirstAncestorWhichIsA("BasePart")
        end
        local ignored = { character }
        if ignoredParent then table.insert(ignored, ignoredParent) end
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = ignored
        local origin = camera.CFrame.Position
        if Workspace:Raycast(origin, position - origin, params) then return nil end
    end
    return distance
end

local function releaseActive()
    local holding = active
    if not holding then return end
    active = nil -- Clear first: InputHoldEnd can itself cause prompt events.
    local now = os.clock()
    local record = records[holding.prompt]
    if record then record.readyAt = now + CONFIG.Cooldown end
    nextStart = now + CONFIG.TickInterval
    -- Always attempt release, including when a prompt is disabled or removed.
    pcall(function() holding.prompt:InputHoldEnd() end)
end

local function setRunning(value)
    if value and #targetOrder == 0 then
        tell("Add at least one action first.")
        return
    end
    running = value
    if not running then releaseActive() end
    toggle.Text = running and "STOP" or "START"
    toggle.BackgroundColor3 = running and Color3.fromRGB(169, 58, 65)
        or Color3.fromRGB(39, 133, 103)
end

local function addTarget(text)
    local display = trim(text)
    local key = normalize(text)
    if key == "" then tell("Enter action text first."); return end
    if #display > 160 then tell("Action text is too long (maximum 160 bytes)."); return end
    if targets[key] then tell("That action is already in the list."); return end
    targets[key] = display
    table.insert(targetOrder, key)
    if refreshList then refreshList() end
    tell("Added: " .. display)
end

local function removeTarget(key)
    targets[key] = nil
    for index, value in ipairs(targetOrder) do
        if value == key then table.remove(targetOrder, index); break end
    end
    if active and normalize(active.prompt.ActionText) == key then releaseActive() end
    if #targetOrder == 0 then setRunning(false) end
    refreshList()
end

local function create(className, properties, parent)
    local instance = Instance.new(className)
    for key, value in pairs(properties) do instance[key] = value end
    instance.Parent = parent
    return instance
end

local colors = {
    panel = Color3.fromRGB(24, 28, 37),
    field = Color3.fromRGB(38, 44, 57),
    text = Color3.fromRGB(238, 242, 250),
    muted = Color3.fromRGB(170, 183, 204),
}

local function round(instance, radius)
    create("UICorner", { CornerRadius = UDim.new(0, radius or 7) }, instance)
    return instance
end

local function label(parent, text, x, y, width, height, muted)
    return create("TextLabel", {
        Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(width, height),
        BackgroundTransparency = 1, Text = text, TextSize = 13,
        Font = Enum.Font.Gotham, TextColor3 = muted and colors.muted or colors.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, parent)
end

local function button(parent, text, x, y, width, height)
    return round(create("TextButton", {
        Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(width, height),
        BackgroundColor3 = colors.field, BorderSizePixel = 0,
        Text = text, TextSize = 13, Font = Enum.Font.GothamMedium,
        TextColor3 = colors.text, AutoButtonColor = true,
    }, parent))
end

local function textbox(parent, placeholder, x, y, width)
    local box = round(create("TextBox", {
        Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(width, 34),
        BackgroundColor3 = colors.field, BorderSizePixel = 0,
        Text = "", PlaceholderText = placeholder, ClearTextOnFocus = false,
        TextColor3 = colors.text, PlaceholderColor3 = colors.muted,
        TextSize = 13, Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, parent))
    create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, box)
    return box
end

screen = create("ScreenGui", {
    Name = "PromptPrecisionV2", ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 20,
}, playerGui)
local panel = round(create("Frame", {
    Size = UDim2.fromOffset(330, 472), Position = UDim2.fromOffset(24, 70),
    BackgroundColor3 = colors.panel, BorderSizePixel = 0, Active = true,
}, screen), 10)
local scale = create("UIScale", { Scale = 1 }, panel)
local title = label(panel, "Prompt Precision  /  v2", 14, 8, 270, 32)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Active = true
local close = button(panel, "X", 290, 10, 28, 28)
status = label(panel, "Paused", 14, 48, 302, 34, true)
status.TextWrapped = true
status.TextTruncate = Enum.TextTruncate.None
toggle = button(panel, "START", 14, 91, 302, 36)
toggle.BackgroundColor3 = Color3.fromRGB(39, 133, 103)
input = textbox(panel, "Exact action text, e.g. Open Door", 14, 139, 302)
local add = button(panel, "Add action", 14, 182, 146, 32)
local nearest = button(panel, "Add nearest", 170, 182, 146, 32)
label(panel, "Target actions", 14, 221, 200, 20, true)
local clear = button(panel, "Clear", 252, 219, 64, 24)
list = round(create("ScrollingFrame", {
    Position = UDim2.fromOffset(14, 249), Size = UDim2.fromOffset(302, 138),
    BackgroundColor3 = colors.field, BorderSizePixel = 0,
    CanvasSize = UDim2.fromOffset(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollBarThickness = 5, ScrollingDirection = Enum.ScrollingDirection.Y,
}, panel))
create("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, list)
create("UIPadding", {
    PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 8),
    PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6),
}, list)
label(panel, "Repeat cooldown (seconds)", 14, 400, 205, 28, true)
cooldownBox = textbox(panel, "0.35", 232, 397, 84)
cooldownBox.Text = tostring(CONFIG.Cooldown)
label(panel, "Drag title to move | Right Shift: show/hide", 14, 442, 302, 18, true)

refreshList = function()
    for _, child in ipairs(list:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
    end
    if #targetOrder == 0 then
        local empty = label(list, "No actions added yet.", 0, 0, 268, 30, true)
        empty.LayoutOrder = 1
        return
    end
    for index, key in ipairs(targetOrder) do
        local row = create("Frame", {
            Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, LayoutOrder = index,
        }, list)
        local text = label(row, targets[key], 3, 0, 228, 30)
        text.TextSize = 12
        local remove = button(row, "X", 242, 2, 28, 26)
        -- Connections on destroyed rows are released by Roblox, not retained globally.
        remove.Activated:Connect(function() removeTarget(key) end)
    end
end

destroy = function()
    if not alive then return end
    alive, running = false, false
    releaseActive()
    for _, connection in ipairs(connections) do connection:Disconnect() end
    connections = {}
    records, targets, targetOrder = {}, {}, {}
    if environment[REGISTRY_KEY] == controller then environment[REGISTRY_KEY] = nil end
    if screen then screen:Destroy() end
end
controller.Destroy = destroy
environment[REGISTRY_KEY] = controller

connect(screen.Destroying, destroy)
connect(close.Activated, destroy)
connect(toggle.Activated, function() setRunning(not running) end)
local function submitAction()
    addTarget(input.Text)
    input.Text = ""
end
connect(add.Activated, submitAction)
connect(input.FocusLost, function(enterPressed) if enterPressed then submitAction() end end)
connect(clear.Activated, function()
    setRunning(false)
    targets, targetOrder = {}, {}
    refreshList()
    tell("All target actions cleared.")
end)
connect(cooldownBox.FocusLost, function()
    local value = tonumber(trim(cooldownBox.Text))
    if value and value == value and value >= 0.1 and value <= 60 then
        CONFIG.Cooldown = value
        tell("Cooldown updated.")
    else
        tell("Cooldown must be between 0.1 and 60 seconds.")
    end
    cooldownBox.Text = tostring(CONFIG.Cooldown)
end)
connect(nearest.Activated, function()
    local root, character = characterRoot()
    if not root then tell("Waiting for a living character."); return end
    local best, bestDistance = nil, math.huge
    for prompt, record in pairs(records) do
        local distance = distanceTo(prompt, record, root, character, false)
        if distance and distance < bestDistance and normalize(prompt.ActionText) ~= "" then
            best, bestDistance = prompt, distance
        end
    end
    if best then addTarget(best.ActionText) else tell("No usable prompt nearby.") end
end)

-- Mouse and touch dragging without the deprecated Frame.Draggable property.
local dragging, dragStart, dragPosition, dragTouch
local function fitPanel()
    local camera = Workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
    local width, height = math.max(1, viewport.X - 12), math.max(1, viewport.Y - 60)
    scale.Scale = math.min(1, width / 330, height / 472)
    local position = panel.Position
    panel.Position = UDim2.fromOffset(
        math.clamp(position.X.Offset, 0, math.max(0, width - 330 * scale.Scale)),
        math.clamp(position.Y.Offset, 0, math.max(0, height - 472 * scale.Scale))
    )
end
connect(title.InputBegan, function(event)
    if event.UserInputType == Enum.UserInputType.MouseButton1
        or event.UserInputType == Enum.UserInputType.Touch then
        dragging, dragStart, dragPosition = true, event.Position, panel.Position
        dragTouch = event.UserInputType == Enum.UserInputType.Touch and event or nil
    end
end)
connect(UIS.InputChanged, function(event)
    if not dragging then return end
    if (dragTouch and event == dragTouch)
        or (not dragTouch and event.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = event.Position - dragStart
        panel.Position = UDim2.fromOffset(dragPosition.X.Offset + delta.X, dragPosition.Y.Offset + delta.Y)
        fitPanel()
    end
end)
connect(UIS.InputEnded, function(event)
    if event == dragTouch or event.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging, dragTouch = false, nil
    end
end)
connect(UIS.WindowFocusReleased, function() dragging, dragTouch = false, nil end)
connect(UIS.InputBegan, function(event, processed)
    if not processed and not UIS:GetFocusedTextBox() and event.KeyCode == Enum.KeyCode.RightShift then
        screen.Enabled = not screen.Enabled
    end
end)

-- Register before the initial scan so streamed-in prompts cannot fall through a gap.
connect(Workspace.DescendantAdded, track)
connect(Workspace.DescendantRemoving, function(instance)
    if records[instance] then
        if active and active.prompt == instance then releaseActive() end
        records[instance] = nil
    end
end)
connect(PPS.PromptShown, function(prompt)
    track(prompt)
    if records[prompt] then records[prompt].shown = true end
end)
connect(PPS.PromptHidden, function(prompt)
    if records[prompt] then records[prompt].shown = false end
    if active and active.prompt == prompt then releaseActive() end
end)
connect(PPS.PromptTriggered, function(prompt, who)
    if who == player and active and active.prompt == prompt and not active.triggered then
        active.triggered = true
        confirmed = confirmed + 1
    end
end)
connect(player.CharacterRemoving, function() releaseActive() end)
for _, instance in ipairs(Workspace:GetDescendants()) do track(instance) end
for _, action in ipairs(CONFIG.TargetActions) do addTarget(action) end
refreshList()
fitPanel()

local function tickAutomation(now)
    if not running then return end
    local root, character = characterRoot()
    if not root then releaseActive(); return end
    if active then
        local record = records[active.prompt]
        if active.triggered or now >= active.releaseAt or not record
            or not distanceTo(active.prompt, record, root, character, true) then
            releaseActive()
        end
        return
    end
    -- Avoid automating an interaction while the player types in any text box.
    if now < nextStart or UIS:GetFocusedTextBox() then return end
    local best, bestRecord, bestDistance
    for prompt, record in pairs(records) do
        if now >= record.readyAt then
            local distance = distanceTo(prompt, record, root, character, true)
            if distance and (not bestRecord or record.lastAttempt < bestRecord.lastAttempt
                or (record.lastAttempt == bestRecord.lastAttempt and distance < bestDistance)) then
                best, bestRecord, bestDistance = prompt, record, distance
            end
        end
    end
    if not best then return end
    bestRecord.lastAttempt = now
    active = {
        prompt = best, triggered = false,
        releaseAt = now + math.max(0.05, best.HoldDuration + 0.08),
    }
    local ok, message = pcall(function() best:InputHoldBegin() end)
    if not ok then
        releaseActive()
        -- Back off this prompt on API failure; do not flood the console.
        bestRecord.readyAt = now + math.max(2, CONFIG.Cooldown)
        tell("Input unavailable; retrying shortly.")
        warn("[Prompt Precision] InputHoldBegin failed: " .. tostring(message))
    end
end

local tickElapsed, uiElapsed = 0, 0
connect(RunService.Heartbeat, function(delta)
    if not alive then return end
    tickElapsed, uiElapsed = tickElapsed + delta, uiElapsed + delta
    local now = os.clock()
    if tickElapsed >= CONFIG.TickInterval then
        tickElapsed = 0
        local ok, message = pcall(tickAutomation, now)
        if not ok then
            setRunning(false)
            tell("Stopped after an error. See console for details.")
            warn("[Prompt Precision] " .. tostring(message))
        end
    end
    if uiElapsed >= 0.25 then
        uiElapsed = 0
        fitPanel()
        local state = running and "Running" or "Paused"
        if running and not characterRoot() then state = "Waiting for character"
        elseif running and UIS:GetFocusedTextBox() then state = "Waiting for typing"
        elseif active then state = "Holding: " .. active.prompt.ActionText end
        status.Text = now < noticeUntil and notice
            or string.format("%s | %d targets | %d triggered", state, #targetOrder, confirmed)
    end
end)

print("[Prompt Precision v2] Ready. Add an action, then press START. X unloads.")
