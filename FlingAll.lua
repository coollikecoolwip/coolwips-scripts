-- Script by Coollikecoolwip
-- Enjoy!
-- Reliability rebuild: serialized jobs, cancellation, cleanup, and a searchable UI.
-- Credits and original target examples preserved from the supplied script.

local Targets = {"All"} -- "All", "Target Name", "arian_was_here"

local Config = {
    ToggleKey = Enum.KeyCode.RightControl,
    StartVisible = false,
    SecondsPerTarget = 2,
    BetweenTargets = 0.12,
    BetweenPasses = 1,
    LaunchSpeed = 500, -- A speed threshold, not proof of a successful fling.
    PredictionSeconds = 0.06,
    MaxPredictionDistance = 12,
    SkipSeatedTargets = true,
    ReturnToStart = true,
    LowerDestroyHeight = true, -- Best effort; some environments deny this property.
    LinearVelocity = Vector3.new(9e7, 9e8, 9e7),
    AngularVelocity = Vector3.new(9e8, 9e8, 9e8),
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local Player = Players.LocalPlayer
if not Player then
    warn("[Coollikecoolwip] Run this on the client after joining a game.")
    return
end
local PlayerGui = Player:FindFirstChildOfClass("PlayerGui") or Player:WaitForChild("PlayerGui", 10)
if not PlayerGui then
    warn("[Coollikecoolwip] PlayerGui did not become available.")
    return
end

local Shared = _G
if type(getgenv) == "function" then
    local ok, environment = pcall(getgenv)
    if ok and type(environment) == "table" then
        Shared = environment
    end
end
local SESSION_KEY = "Coollikecoolwip_FlingAll_Session"
local GUI_NAME = "Coollikecoolwip_FlingAll"
local previous = Shared[SESSION_KEY]
if type(previous) == "table" and type(previous.Shutdown) == "function" then
    previous.Shutdown()
end
local previousGui = PlayerGui:FindFirstChild(GUI_NAME)
if previousGui then
    previousGui:Destroy()
end

local State = {
    Alive = true,
    Busy = false,
    Loop = false,
    Generation = 0,
    Connections = {},
    Rows = {},
    Excluded = {[Player.UserId] = true},
    Run = nil,
}
Shared[SESSION_KEY] = State

local function finite(n)
    return type(n) == "number" and n == n and n > -math.huge and n < math.huge
end
local function finiteVector(v)
    return finite(v.X) and finite(v.Y) and finite(v.Z)
end
local function finiteCFrame(cf)
    for _, value in ipairs({cf:GetComponents()}) do
        if not finite(value) then
            return false
        end
    end
    return true
end
local function bounded(value, default, minimum, maximum)
    return finite(value) and math.clamp(value, minimum, maximum) or default
end
Config.SecondsPerTarget = bounded(Config.SecondsPerTarget, 2, 0.1, 10)
Config.BetweenTargets = bounded(Config.BetweenTargets, 0.12, 0, 5)
Config.BetweenPasses = bounded(Config.BetweenPasses, 1, 0.1, 30)
Config.LaunchSpeed = bounded(Config.LaunchSpeed, 500, 50, 10000)
Config.PredictionSeconds = bounded(Config.PredictionSeconds, 0.06, 0, 0.2)
Config.MaxPredictionDistance = bounded(Config.MaxPredictionDistance, 12, 0, 30)
if typeof(Config.LinearVelocity) ~= "Vector3" or not finiteVector(Config.LinearVelocity)
    or Config.LinearVelocity.Magnitude > 1e9 then
    Config.LinearVelocity = Vector3.new(9e7, 9e8, 9e7)
end
if typeof(Config.AngularVelocity) ~= "Vector3" or not finiteVector(Config.AngularVelocity)
    or Config.AngularVelocity.Magnitude > 2e9 then
    Config.AngularVelocity = Vector3.new(9e8, 9e8, 9e8)
end

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(State.Connections, connection)
    return connection
end
local function notify(text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Script by Coollikecoolwip",
            Text = text,
            Duration = 5,
        })
    end)
end
local function traceback(message)
    return debug.traceback(tostring(message), 2)
end
local function getRig(player)
    local character = player.Character
    if not character or not character:IsDescendantOf(Workspace) then
        return nil
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = humanoid and humanoid.RootPart
    if not root then
        root = character:FindFirstChild("HumanoidRootPart")
    end
    if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
        return nil
    end
    return character, humanoid, root
end
local function eligible(player)
    return player ~= Player and player.Parent == Players and not State.Excluded[player.UserId]
end
local function chooseTargets()
    local candidates, selected, seen = {}, {}, {}
    for _, player in ipairs(Players:GetPlayers()) do
        if eligible(player) then
            table.insert(candidates, player)
        end
    end
    table.sort(candidates, function(a, b)
        return a.Name:lower() < b.Name:lower()
    end)
    local function add(player)
        if player and not seen[player.UserId] then
            seen[player.UserId] = true
            table.insert(selected, player)
        end
    end
    for _, selector in ipairs(Targets) do
        if type(selector) == "string" then
            local name = selector:match("^%s*(.-)%s*$"):lower()
            if name == "all" or name == "others" then
                for _, candidate in ipairs(candidates) do
                    add(candidate)
                end
            elseif name == "random" then
                if #candidates > 0 then
                    add(candidates[math.random(1, #candidates)])
                end
            elseif name ~= "" then
                -- Exact usernames take priority; prefixes are literal, never Lua patterns.
                local exact
                for _, candidate in ipairs(candidates) do
                    if candidate.Name:lower() == name then
                        exact = candidate
                        break
                    end
                end
                if exact then
                    add(exact)
                else
                    for _, candidate in ipairs(candidates) do
                        if candidate.Name:lower():sub(1, #name) == name
                            or candidate.DisplayName:lower():sub(1, #name) == name then
                            add(candidate)
                            break
                        end
                    end
                end
            end
        end
    end
    return selected
end

-- UI: the small launcher remains available when the main panel is hidden.
local Colors = {
    Panel = Color3.fromRGB(25, 28, 36),
    Row = Color3.fromRGB(36, 41, 53),
    Button = Color3.fromRGB(49, 57, 74),
    Text = Color3.fromRGB(239, 242, 250),
    Muted = Color3.fromRGB(170, 182, 204),
    Accent = Color3.fromRGB(73, 115, 221),
    Excluded = Color3.fromRGB(130, 55, 68),
}
local function create(class, properties, parent)
    local object = Instance.new(class)
    for key, value in pairs(properties) do
        object[key] = value
    end
    object.Parent = parent
    return object
end
local function round(object, radius)
    create("UICorner", {CornerRadius = UDim.new(0, radius or 7)}, object)
end
local function label(parent, text, position, size, muted)
    return create("TextLabel", {
        BackgroundTransparency = 1,
        Position = position,
        Size = size,
        Text = text,
        TextColor3 = muted and Colors.Muted or Colors.Text,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, parent)
end
local function button(parent, text, position, size, color)
    local object = create("TextButton", {
        Position = position,
        Size = size,
        BackgroundColor3 = color or Colors.Button,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = Colors.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        AutoButtonColor = true,
    }, parent)
    round(object)
    return object
end
local screen = create("ScreenGui", {
    Name = GUI_NAME,
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 100,
}, PlayerGui)
local canvas = create("Frame", {
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),
}, screen)
local panel = create("Frame", {
    Name = "Panel",
    Size = UDim2.fromOffset(440, 520),
    Position = UDim2.new(1, -452, 0, 12),
    BackgroundColor3 = Colors.Panel,
    BorderSizePixel = 0,
    Visible = Config.StartVisible,
}, canvas)
round(panel, 11)
local scale = create("UIScale", {Scale = 1}, panel)
local title = label(panel, "Fling All", UDim2.fromOffset(14, 10), UDim2.fromOffset(320, 27))
title.TextSize = 21
title.Font = Enum.Font.GothamBold
label(panel, "Script by Coollikecoolwip", UDim2.fromOffset(14, 39), UDim2.fromOffset(340, 18), true)
local hideButton = button(panel, "-", UDim2.fromOffset(354, 12), UDim2.fromOffset(32, 27))
local closeButton = button(panel, "X", UDim2.fromOffset(394, 12), UDim2.fromOffset(32, 27), Colors.Excluded)
local search = create("TextBox", {
    Position = UDim2.fromOffset(14, 66),
    Size = UDim2.fromOffset(412, 32),
    BackgroundColor3 = Colors.Row,
    BorderSizePixel = 0,
    Text = "",
    PlaceholderText = "Search display name or @username...",
    PlaceholderColor3 = Colors.Muted,
    TextColor3 = Colors.Text,
    TextSize = 13,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false,
}, panel)
round(search)
create("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, search)
local countLabel = label(panel, "Players", UDim2.fromOffset(14, 105), UDim2.fromOffset(412, 20), true)
local playerList = create("ScrollingFrame", {
    Position = UDim2.fromOffset(14, 132),
    Size = UDim2.fromOffset(412, 240),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = Colors.Muted,
    CanvasSize = UDim2.fromOffset(0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y,
}, panel)
create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5)}, playerList)
local allButton = button(panel, "Fling All", UDim2.fromOffset(14, 384), UDim2.fromOffset(202, 34), Colors.Accent)
local loopButton = button(panel, "Loop Fling All", UDim2.fromOffset(224, 384), UDim2.fromOffset(202, 34))
local refreshButton = button(panel, "Refresh", UDim2.fromOffset(14, 426), UDim2.fromOffset(92, 30))
local clearButton = button(panel, "Clear Blacklist", UDim2.fromOffset(114, 426), UDim2.fromOffset(154, 30))
local stopButton = button(panel, "Stop + Return", UDim2.fromOffset(276, 426), UDim2.fromOffset(150, 30), Colors.Excluded)
local statusLabel = label(panel, "Ready", UDim2.fromOffset(14, 464), UDim2.fromOffset(412, 22))
label(panel, "Right Ctrl: show/hide  |  Drag title  |  X: unload", UDim2.fromOffset(14, 493), UDim2.fromOffset(412, 18), true)
local launcher = button(canvas, "Fling", UDim2.new(0, 12, 1, -44), UDim2.fromOffset(70, 32), Colors.Accent)

local function status(text)
    if State.Alive then
        statusLabel.Text = text
    end
end
local function updateControls()
    if not State.Alive then
        return
    end
    loopButton.Text = State.Loop and "Stop Loop" or "Loop Fling All"
    loopButton.BackgroundColor3 = State.Loop and Colors.Excluded or Colors.Button
    allButton.Text = State.Busy and "Running..." or "Fling All"
end
local function cancelled(run)
    return not State.Alive or State.Run ~= run or State.Generation ~= run.Generation
        or Player.Character ~= run.Character or not run.Character:IsDescendantOf(Workspace)
        or run.Humanoid.Health <= 0 or not run.Root:IsDescendantOf(run.Character)
end
local function pause(run, seconds)
    local deadline = os.clock() + seconds
    while not cancelled(run) and os.clock() < deadline do
        RunService.Heartbeat:Wait()
    end
    return not cancelled(run)
end
local function zeroVelocity(character)
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                part.AssemblyLinearVelocity = Vector3.zero
                part.AssemblyAngularVelocity = Vector3.zero
            end)
        end
    end
end
local function releaseAttempt(run)
    -- No yields: cancellation and re-execution can call this immediately.
    if run.Restored then
        return -- A cancelled worker must not touch a newer session's character.
    end
    for _, object in ipairs(run.Temporary) do
        pcall(function() object:Destroy() end)
    end
    run.Temporary = {}
    pcall(function()
        run.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, run.SeatedEnabled)
        run.Humanoid.AutoRotate = run.AutoRotate
    end)
    if Player.Character == run.Character then
        zeroVelocity(run.Character)
    end
end
local function restore(run)
    if run.Restored then
        return
    end
    releaseAttempt(run)
    run.Restored = true
    if Player.Character == run.Character and run.Character:IsDescendantOf(Workspace)
        and run.Humanoid.Health > 0 then
        if Config.ReturnToStart then
            pcall(function() run.Character:PivotTo(run.Home) end)
        end
        zeroVelocity(run.Character)
        pcall(function()
            if not run.Humanoid.Sit then
                run.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end)
    end
    if run.ChangedDestroyHeight then
        pcall(function() Workspace.FallenPartsDestroyHeight = run.DestroyHeight end)
    end
    pcall(function()
        local camera = Workspace.CurrentCamera
        if camera then
            local _, humanoid = getRig(Player)
            local subject = run.CameraSubject
            if subject and subject.Parent then
                camera.CameraSubject = subject
            elseif humanoid then
                camera.CameraSubject = humanoid
            end
        end
    end)
end
local function stop(reason)
    State.Generation = State.Generation + 1
    State.Loop = false
    if State.Run then
        restore(State.Run)
    end
    status(reason or "Stopped")
    updateControls()
end
function State.Shutdown()
    if not State.Alive then
        return
    end
    stop("Unloaded")
    State.Alive = false
    for _, connection in ipairs(State.Connections) do
        connection:Disconnect()
    end
    for _, row in pairs(State.Rows) do
        for _, connection in ipairs(row.Connections) do
            connection:Disconnect()
        end
    end
    if Shared[SESSION_KEY] == State then
        Shared[SESSION_KEY] = nil
    end
    screen:Destroy()
end

local offsets = {
    Vector3.new(0, 1.5, 0), Vector3.new(0, -1.5, 0),
    Vector3.new(2.25, 1.5, -2.25), Vector3.new(-2.25, -1.5, 2.25),
    Vector3.new(0, 1.5, 0), Vector3.new(0, -1.5, 0),
}
local function targetPart(character, root)
    local head = character:FindFirstChild("Head")
    if head and head:IsA("BasePart") and (root.Position - head.Position).Magnitude > 5 then
        return head
    end
    return root
end
local function attempt(run, target)
    if cancelled(run) or not eligible(target) then
        return "skipped"
    end
    local character, humanoid, root = getRig(target)
    if not character or (Config.SkipSeatedTargets and humanoid.Sit) then
        return "skipped"
    end
    local part = targetPart(character, root)
    if part.Anchored or (part.AssemblyRootPart and part.AssemblyRootPart.Anchored)
        or not finiteVector(part.Position) or not finiteVector(part.AssemblyLinearVelocity) then
        return "skipped"
    end
    if part.AssemblyLinearVelocity.Magnitude >= Config.LaunchSpeed then
        return "skipped"
    end
    status("Target: " .. target.DisplayName .. " (@" .. target.Name .. ")")
    local result = "attempted"
    local ok, message = xpcall(function()
        run.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
        run.Humanoid.AutoRotate = false
        local camera = Workspace.CurrentCamera
        if camera then
            camera.CameraSubject = humanoid
        end
        local attachment = Instance.new("Attachment")
        table.insert(run.Temporary, attachment)
        attachment.Name = "Coollikecoolwip_FlingAttachment"
        attachment.Parent = run.Root
        local velocity = Instance.new("LinearVelocity")
        table.insert(run.Temporary, velocity)
        velocity.Name = "EpixVel" -- Original mover name preserved.
        velocity.Attachment0 = attachment
        velocity.RelativeTo = Enum.ActuatorRelativeTo.World
        velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
        velocity.ForceLimitsEnabled = false
        velocity.VectorVelocity = Config.LinearVelocity
        velocity.Parent = run.Root

        local started, step = os.clock(), 0
        while not cancelled(run) and os.clock() - started < Config.SecondsPerTarget do
            -- Resume before physics, and re-check every reference after the yield.
            RunService.PreSimulation:Wait()
            if cancelled(run) or os.clock() - started >= Config.SecondsPerTarget
                or not eligible(target) or target.Character ~= character
                or not character:IsDescendantOf(Workspace) or humanoid.Health <= 0
                or not part:IsDescendantOf(character) or not root:IsDescendantOf(character)
                or (Config.SkipSeatedTargets and humanoid.Sit) or run.Root.Anchored
                or part.Anchored or (part.AssemblyRootPart and part.AssemblyRootPart.Anchored) then
                break
            end
            local motion = part.AssemblyLinearVelocity
            if not finiteVector(part.Position) or not finiteVector(motion) then
                break
            end
            if motion.Magnitude >= Config.LaunchSpeed then
                result = "threshold"
                break
            end
            if part.Position.Y <= Workspace.FallenPartsDestroyHeight + 6 then
                break
            end
            step = step + 1
            local prediction = motion * Config.PredictionSeconds
            if prediction.Magnitude > Config.MaxPredictionDistance then
                prediction = prediction.Unit * Config.MaxPredictionDistance
            end
            local offset = offsets[(step - 1) % #offsets + 1]
            if motion.Magnitude >= 50 then
                local distance = math.min(motion.Magnitude / 1.25, 16)
                offset = Vector3.new(0, step % 2 == 0 and -1.5 or 1.5,
                    step % 2 == 0 and -distance or distance)
            end
            local desiredRoot = CFrame.new(part.Position + prediction + offset)
                * CFrame.Angles(math.rad((step * 100) % 360), 0, 0)
            run.Character:PivotTo(desiredRoot * run.RootToPivot)
            run.Root.AssemblyLinearVelocity = Config.LinearVelocity
            run.Root.AssemblyAngularVelocity = Config.AngularVelocity
        end
    end, traceback)
    releaseAttempt(run)
    if not ok then
        warn("[Coollikecoolwip] Target attempt failed: " .. tostring(message))
        return "error"
    end
    return result
end
local function start(singleTarget, looping)
    if not State.Alive then
        return
    end
    if State.Busy then
        status("A job is running. Press Stop before starting another.")
        return
    end
    if singleTarget and not eligible(singleTarget) then
        status("That player is excluded or has left.")
        return
    end
    local character, humanoid, root = getRig(Player)
    if not character then
        status("Wait for your character to finish spawning.")
        return
    end
    if root.Anchored or humanoid.Sit then
        status("Stand up and wait until your character can move.")
        return
    end
    local home = character:GetPivot()
    if not finiteCFrame(home) or not finiteCFrame(root.CFrame) then
        status("Your character has an invalid position. Respawn first.")
        return
    end
    State.Generation = State.Generation + 1
    local camera = Workspace.CurrentCamera
    local run = {
        Generation = State.Generation,
        Character = character,
        Humanoid = humanoid,
        Root = root,
        Home = home,
        RootToPivot = root.CFrame:ToObjectSpace(home),
        SeatedEnabled = humanoid:GetStateEnabled(Enum.HumanoidStateType.Seated),
        AutoRotate = humanoid.AutoRotate,
        CameraSubject = camera and camera.CameraSubject,
        DestroyHeight = Workspace.FallenPartsDestroyHeight,
        Temporary = {},
        Restored = false,
    }
    State.Run = run
    State.Busy = true
    State.Loop = looping == true
    if Config.LowerDestroyHeight and finite(run.DestroyHeight) and run.DestroyHeight > -50000 then
        local ok = pcall(function() Workspace.FallenPartsDestroyHeight = -50000 end)
        run.ChangedDestroyHeight = ok
    end
    updateControls()
    task.spawn(function()
        local attempted, skipped, thresholds, errors = 0, 0, 0, 0
        local ok, message = xpcall(function()
            repeat
                local targets = singleTarget and {singleTarget} or chooseTargets()
                if #targets == 0 then
                    status(State.Loop and "No eligible targets; waiting..." or "No eligible targets.")
                end
                for _, target in ipairs(targets) do
                    if cancelled(run) then
                        break
                    end
                    local result = attempt(run, target)
                    if result == "skipped" then
                        skipped = skipped + 1
                    else
                        attempted = attempted + 1
                        if result == "threshold" then thresholds = thresholds + 1 end
                        if result == "error" then errors = errors + 1 end
                    end
                    if not pause(run, Config.BetweenTargets) then
                        break
                    end
                end
                if not State.Loop or cancelled(run) then
                    break
                end
            until not pause(run, Config.BetweenPasses)
        end, traceback)
        local wasCancelled = cancelled(run)
        restore(run)
        if State.Run == run then
            State.Run = nil
            State.Busy = false
            State.Loop = false
            updateControls()
            if not ok then
                status("Job stopped after an error. See the console.")
            elseif not wasCancelled then
                status(string.format("Done: %d tried, %d skipped, %d fast, %d errors",
                    attempted, skipped, thresholds, errors))
            end
        end
        if not ok then
            warn("[Coollikecoolwip] Job failed: " .. tostring(message))
        end
    end)
end

local function updateRows()
    local query = search.Text:lower():match("^%s*(.-)%s*$"):gsub("^@", "")
    local ordered = {}
    for _, row in pairs(State.Rows) do
        table.insert(ordered, row)
    end
    table.sort(ordered, function(a, b) return a.Player.Name:lower() < b.Player.Name:lower() end)
    local included, others, shown = 0, 0, 0
    for index, row in ipairs(ordered) do
        local player = row.Player
        local isSelf = player == Player
        local excluded = isSelf or State.Excluded[player.UserId] == true
        row.Frame.LayoutOrder = index
        row.Name.Text = player.DisplayName
        row.Username.Text = "@" .. player.Name
        row.Exclude.Text = isSelf and "You" or (excluded and "Excluded" or "Included")
        row.Exclude.BackgroundColor3 = excluded and Colors.Excluded or Colors.Button
        row.Exclude.Active = not isSelf
        row.Fling.Active = not excluded
        row.Fling.AutoButtonColor = not excluded
        row.Fling.BackgroundColor3 = excluded and Colors.Button or Colors.Accent
        row.Fling.TextTransparency = excluded and 0.55 or 0
        row.Frame.Visible = query == "" or player.Name:lower():find(query, 1, true) ~= nil
            or player.DisplayName:lower():find(query, 1, true) ~= nil
        if row.Frame.Visible then shown = shown + 1 end
        if not isSelf then
            others = others + 1
            if not excluded then included = included + 1 end
        end
    end
    countLabel.Text = string.format("%d / %d included  |  %d shown  |  Click to exclude", included, others, shown)
end
local function removeRow(player)
    local row = State.Rows[player.UserId]
    if row then
        for _, connection in ipairs(row.Connections) do
            connection:Disconnect()
        end
        row.Frame:Destroy()
        State.Rows[player.UserId] = nil
    end
end
local function addRow(player)
    if State.Rows[player.UserId] or not State.Alive then
        return
    end
    local frame = create("Frame", {
        Name = tostring(player.UserId),
        Size = UDim2.new(1, -8, 0, 44),
        BackgroundColor3 = Colors.Row,
        BorderSizePixel = 0,
    }, playerList)
    round(frame)
    local name = label(frame, "", UDim2.fromOffset(8, 3), UDim2.new(1, -193, 0, 20))
    local username = label(frame, "", UDim2.fromOffset(8, 23), UDim2.new(1, -193, 0, 16), true)
    username.TextSize = 11
    local exclude = button(frame, "", UDim2.new(1, -181, 0, 7), UDim2.fromOffset(100, 30))
    local fling = button(frame, "Fling", UDim2.new(1, -73, 0, 7), UDim2.fromOffset(65, 30), Colors.Accent)
    local row = {Player = player, Frame = frame, Name = name, Username = username,
        Exclude = exclude, Fling = fling, Connections = {}}
    State.Rows[player.UserId] = row
    table.insert(row.Connections, exclude.Activated:Connect(function()
        if player ~= Player then
            State.Excluded[player.UserId] = not State.Excluded[player.UserId] or nil
            updateRows()
        end
    end))
    table.insert(row.Connections, fling.Activated:Connect(function() start(player, false) end))
    table.insert(row.Connections, player:GetPropertyChangedSignal("DisplayName"):Connect(updateRows))
end
local function refreshRows()
    local present = {}
    for _, player in ipairs(Players:GetPlayers()) do
        present[player.UserId] = true
        addRow(player)
    end
    local departed = {}
    for userId, row in pairs(State.Rows) do
        if not present[userId] then table.insert(departed, row.Player) end
    end
    for _, player in ipairs(departed) do removeRow(player) end
    updateRows()
end

connect(allButton.Activated, function() start(nil, false) end)
connect(loopButton.Activated, function()
    if State.Loop then stop("Loop stopped") else start(nil, true) end
end)
connect(stopButton.Activated, function() stop("Stopped") end)
connect(refreshButton.Activated, refreshRows)
connect(clearButton.Activated, function()
    State.Excluded = {[Player.UserId] = true}
    updateRows()
end)
connect(search:GetPropertyChangedSignal("Text"), updateRows)
connect(Players.PlayerAdded, function(player) addRow(player); updateRows() end)
connect(Players.PlayerRemoving, function(player) removeRow(player); updateRows() end)
connect(Player.CharacterRemoving, function() stop("Character changed; job stopped") end)
connect(Player.CharacterAdded, function() status("Character spawning. Ready when loaded.") end)
connect(closeButton.Activated, State.Shutdown)
connect(screen.Destroying, State.Shutdown)
local function togglePanel() panel.Visible = not panel.Visible end
connect(launcher.Activated, togglePanel)
connect(hideButton.Activated, togglePanel)
connect(UserInputService.InputBegan, function(input, processed)
    if not processed and not UserInputService:GetFocusedTextBox() and input.KeyCode == Config.ToggleKey then
        togglePanel()
    end
end)

-- Drag only the title area; scrolling and player buttons do not move the panel.
local drag
title.Active = true
connect(title.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        drag = {Input = input, Start = input.Position, Position = panel.AbsolutePosition - canvas.AbsolutePosition}
    end
end)
local function clampPanel(x, y)
    local available = canvas.AbsoluteSize
    local size = panel.AbsoluteSize
    panel.Position = UDim2.fromOffset(math.clamp(x, 0, math.max(0, available.X - size.X)),
        math.clamp(y, 0, math.max(0, available.Y - size.Y)))
end
connect(UserInputService.InputChanged, function(input)
    if drag and (input == drag.Input or (drag.Input.UserInputType == Enum.UserInputType.MouseButton1
        and input.UserInputType == Enum.UserInputType.MouseMovement)) then
        local delta = input.Position - drag.Start
        clampPanel(drag.Position.X + delta.X, drag.Position.Y + delta.Y)
    end
end)
connect(UserInputService.InputEnded, function(input)
    if drag and input == drag.Input then drag = nil end
end)
local function resize()
    local available = canvas.AbsoluteSize
    if available.X <= 0 or available.Y <= 0 then return end
    scale.Scale = math.max(0.1, math.min(1, (available.X - 24) / 440, (available.Y - 56) / 520))
    local position = panel.AbsolutePosition - canvas.AbsolutePosition
    clampPanel(position.X, position.Y)
end
connect(canvas:GetPropertyChangedSignal("AbsoluteSize"), resize)
refreshRows()
task.defer(function() if State.Alive then resize() end end)
if not Shared.Welcome then notify("Enjoy! Right Ctrl or the Fling button opens the panel.") end
Shared.Welcome = true
