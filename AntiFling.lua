-- Anti-Fling v2 | client-side, executor-friendly Luau
-- Run this file again to replace the previous v2 instance cleanly.
-- Local protection only. No remote calls, hidden physics properties, or HTTP code.
-- Tuning: raise thresholds for games with fast movement/launch pads/vehicles.
local CONFIG = {
    Enabled = true,
    Recovery = true,
    Radius = 100,                  -- studs; nearby character collision isolation
    ReleaseRadius = 140,           -- hysteresis prevents boundary churn
    ScanInterval = 0.15,
    ConstraintsPerFrame = 160,     -- bounded creation work
    MaxConstraints = 8000,         -- HUD reports incomplete coverage at this cap
    SpawnGrace = 1.5,
    RecoveryCooldown = 0.65,
    SettleTime = 0.18,
    HorizontalSpeed = 180,
    AngularSpeed = 90,             -- radians/sec
    ExtremeSpeed = 550,
    ExtremeAngularSpeed = 180,
    HorizontalAcceleration = 1400,
    ThreatRadius = 24,
    ThreatSpeed = 110,
    ThreatAngularSpeed = 45,
    SafeHorizontalSpeed = 70,
    SafeAngularSpeed = 10,
    SnapshotLifetime = 4,
    MaxRollbackDistance = 250,
    TeleportDistance = 80,
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local localPlayer = Players.LocalPlayer
assert(localPlayer, "Anti-Fling must run on the client")

local KEY = "__AntiFlingV2"
local env = _G
if type(getgenv) == "function" then
    local ok, value = pcall(getgenv)
    if ok and type(value) == "table" then env = value end
end
local previous = env[KEY]
if type(previous) == "table" and type(previous.Destroy) == "function" then
    pcall(previous.Destroy)
end
local runtimeName = "_AntiFlingV2_" .. localPlayer.UserId
local orphan = Workspace:FindFirstChild(runtimeName)
if orphan then
    local shutdown = orphan:FindFirstChild("Shutdown")
    if shutdown and shutdown:IsA("BindableFunction") then
        pcall(function() shutdown:Invoke() end)
    end
    orphan:Destroy()
end

local controller = { Config = CONFIG }
local connections, records = {}, {}
local runtime, gui
local alive = true
local constraintCount, blockedCount, recoveryCount = 0, 0, 0
local capped, pending = false, false
local lastReason = "Ready"
local localRecord
local snapshot, lastPosition, lastVelocity, lastSampleTime
local graceUntil, settleUntil, lastRecovery = 0, 0, -math.huge
local stableSince

local function disconnectAll(list)
    for _, connection in ipairs(list) do connection:Disconnect() end
    table.clear(list)
end
local function connect(signal, callback, list)
    local connection = signal:Connect(callback)
    table.insert(list or connections, connection)
    return connection
end
local function clearHistory(grace)
    snapshot, lastPosition, lastVelocity, lastSampleTime, stableSince = nil, nil, nil, nil, nil
    settleUntil = 0
    graceUntil = os.clock() + (grace or 0)
end
local function clearPairs(record)
    for _, row in pairs(record.pairs) do
        for _, constraint in pairs(row) do
            constraint:Destroy()
            constraintCount = constraintCount - 1
        end
    end
    table.clear(record.pairs)
end
local function clearAllPairs()
    for _, record in pairs(records) do
        clearPairs(record)
        record.active = false
    end
    blockedCount, capped, pending = 0, false, false
end
function controller.Destroy()
    if not alive then return end
    alive = false
    disconnectAll(connections)
    for _, record in pairs(records) do
        disconnectAll(record.connections)
        disconnectAll(record.characterConnections)
        clearPairs(record)
    end
    table.clear(records)
    if gui then gui:Destroy() end
    if runtime then runtime:Destroy() end
    if env[KEY] == controller then env[KEY] = nil end
end
function controller.SetEnabled(enabled)
    CONFIG.Enabled = enabled == true
    clearAllPairs()
    clearHistory(CONFIG.Enabled and 0.4 or 0)
    lastReason = CONFIG.Enabled and "Protection enabled" or "Protection paused"
end
env[KEY] = controller

local function finite(n)
    return n == n and n > -math.huge and n < math.huge
end
local function finiteVector(v)
    return finite(v.X) and finite(v.Y) and finite(v.Z)
end
local function finiteCFrame(cf)
    for _, n in ipairs({cf:GetComponents()}) do
        if not finite(n) then return false end
    end
    return true
end
local function horizontal(v)
    return Vector3.new(v.X, 0, v.Z).Magnitude
end
local function rootOf(record)
    local character = record and record.character
    if not character or not character:IsDescendantOf(Workspace) then return nil end
    local root = character:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then return root end
end

local function start()
    -- Try each parent by actually parenting, since CoreGui may be inaccessible.
    gui = Instance.new("ScreenGui")
    gui.Name = "AntiFlingGUI_v2"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = false
    gui.DisplayOrder = 100
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local parents = {}
    if type(gethui) == "function" then
        local ok, parent = pcall(gethui)
        if ok and typeof(parent) == "Instance" then table.insert(parents, parent) end
    end
    local okCore, core = pcall(function() return game:GetService("CoreGui") end)
    if okCore then table.insert(parents, core) end
    table.insert(parents, localPlayer:WaitForChild("PlayerGui", 10))
    local parented = false
    for _, parent in ipairs(parents) do
        if pcall(function() gui.Parent = parent end) then parented = true; break end
    end
    assert(parented, "No accessible GUI parent")

    runtime = Instance.new("Folder")
    runtime.Name = runtimeName
    runtime.Parent = Workspace
    local shutdown = Instance.new("BindableFunction")
    shutdown.Name = "Shutdown"
    shutdown.OnInvoke = controller.Destroy
    shutdown.Parent = runtime

    local function removePart(record, part)
        record.parts[part] = nil
        if record == localRecord then
            for _, other in pairs(records) do
                local row = other.pairs[part]
                if row then
                    for _, constraint in pairs(row) do
                        constraint:Destroy()
                        constraintCount = constraintCount - 1
                    end
                    other.pairs[part] = nil
                end
            end
        else
            for _, row in pairs(record.pairs) do
                if row[part] then
                    row[part]:Destroy()
                    row[part] = nil
                    constraintCount = constraintCount - 1
                end
            end
        end
    end
    local function detachCharacter(record)
        disconnectAll(record.characterConnections)
        if record == localRecord then clearAllPairs(); clearHistory(CONFIG.SpawnGrace)
        else clearPairs(record) end
        table.clear(record.parts)
        record.character, record.active = nil, false
    end
    local function attachCharacter(record, character)
        if record.character == character then return end
        detachCharacter(record)
        record.character = character
        connect(character.DescendantAdded, function(item)
            if item:IsA("BasePart") then record.parts[item] = true end
        end, record.characterConnections)
        connect(character.DescendantRemoving, function(item)
            if record.parts[item] then removePart(record, item) end
        end, record.characterConnections)
        for _, item in ipairs(character:GetDescendants()) do
            if item:IsA("BasePart") then record.parts[item] = true end
        end
    end
    local function addPlayer(player)
        if records[player] then return end
        local record = { parts = {}, pairs = {}, connections = {}, characterConnections = {} }
        records[player] = record
        if player == localPlayer then localRecord = record end
        connect(player.CharacterAdded, function(character) attachCharacter(record, character) end, record.connections)
        connect(player.CharacterRemoving, function(character)
            if record.character == character then detachCharacter(record) end
        end, record.connections)
        if player.Character then attachCharacter(record, player.Character) end
    end
    connect(Players.PlayerAdded, addPlayer)
    connect(Players.PlayerRemoving, function(player)
        local record = records[player]
        if record then
            detachCharacter(record)
            disconnectAll(record.connections)
            records[player] = nil
        end
    end)
    addPlayer(localPlayer)
    for _, player in ipairs(Players:GetPlayers()) do addPlayer(player) end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.RespectCanCollide = true
    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Exclude
    overlapParams.RespectCanCollide = true
    overlapParams.MaxParts = 1
    local candidates, threats = {}, {}
    local function scan()
        table.clear(candidates)
        table.clear(threats)
        local excluded = {runtime}
        for _, record in pairs(records) do
            if record.character then table.insert(excluded, record.character) end
        end
        rayParams.FilterDescendantsInstances = excluded
        overlapParams.FilterDescendantsInstances = excluded
        local root = rootOf(localRecord)
        blockedCount = 0
        for _, record in pairs(records) do
            if record ~= localRecord then
                local otherRoot = rootOf(record)
                local distance = root and otherRoot and (root.Position - otherRoot.Position).Magnitude or math.huge
                local radius = record.active and CONFIG.ReleaseRadius or CONFIG.Radius
                if CONFIG.Enabled and finite(distance) and distance <= radius then
                    record.active = true
                    table.insert(candidates, {record = record, distance = distance})
                    table.insert(threats, otherRoot)
                    blockedCount = blockedCount + 1
                else
                    record.active = false
                    clearPairs(record)
                end
            end
        end
        table.sort(candidates, function(a, b) return a.distance < b.distance end)
    end
    local function buildPairs()
        capped, pending = false, false
        if not CONFIG.Enabled or not localRecord or not rootOf(localRecord) then return end
        local budget = CONFIG.ConstraintsPerFrame
        for _, candidate in ipairs(candidates) do
            local record = candidate.record
            if record.active and rootOf(record) then
                for localPart in pairs(localRecord.parts) do
                    if localPart:IsDescendantOf(Workspace) then
                        local row = record.pairs[localPart]
                        if not row then row = {}; record.pairs[localPart] = row end
                        for remotePart in pairs(record.parts) do
                            if remotePart:IsDescendantOf(Workspace) then
                                local existing = row[remotePart]
                                -- Rebuild locally deleted constraints on the next physics step.
                                if existing and existing.Parent ~= runtime then
                                    existing:Destroy(); row[remotePart] = nil
                                    constraintCount = constraintCount - 1
                                end
                                if not row[remotePart] then
                                    if constraintCount >= CONFIG.MaxConstraints then capped = true; return end
                                    if budget <= 0 then pending = true; return end
                                    local constraint = Instance.new("NoCollisionConstraint")
                                    constraint.Part0, constraint.Part1 = localPart, remotePart
                                    constraint.Parent = runtime
                                    row[remotePart] = constraint
                                    constraintCount = constraintCount + 1
                                    budget = budget - 1
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    local function nearThreat(root)
        for _, other in ipairs(threats) do
            if other.Parent and (other.Position - root.Position).Magnitude <= CONFIG.ThreatRadius then
                local linear, angular = other.AssemblyLinearVelocity, other.AssemblyAngularVelocity
                if not finiteVector(linear) or not finiteVector(angular)
                    or linear.Magnitude >= CONFIG.ThreatSpeed or angular.Magnitude >= CONFIG.ThreatAngularSpeed then
                    return true
                end
            end
        end
        return false
    end
    local function stopMotion()
        -- Only modify unanchored assemblies entirely within our character.
        local seen = {}
        for part in pairs(localRecord.parts) do
            if part:IsDescendantOf(Workspace) then
                local assembly = part.AssemblyRootPart or part
                if not assembly.Anchored and assembly:IsDescendantOf(localRecord.character) and not seen[assembly] then
                    seen[assembly] = true
                    assembly.AssemblyLinearVelocity = Vector3.zero
                    assembly.AssemblyAngularVelocity = Vector3.zero
                end
            end
        end
    end
    local function grounded(root, humanoid, cf)
        return Workspace:Raycast(cf.Position, Vector3.new(0, -(humanoid.HipHeight + root.Size.Y / 2 + 2), 0), rayParams)
    end
    local function recover(root, humanoid, now, reason)
        stopMotion()
        local destination
        if snapshot and now - snapshot.time <= CONFIG.SnapshotLifetime then
            destination = snapshot.cf
            if snapshot.ground and snapshot.ground:IsDescendantOf(Workspace) then
                local moved = snapshot.ground.CFrame * snapshot.relative
                if finiteCFrame(moved) and (moved.Position - destination.Position).Magnitude < 50 then
                    destination = moved
                end
            end
            if not finiteCFrame(destination)
                or not finiteVector(root.Position)
                or (destination.Position - root.Position).Magnitude > CONFIG.MaxRollbackDistance
                or not grounded(root, humanoid, destination)
                or #Workspace:GetPartBoundsInBox(destination, root.Size * 0.8, overlapParams) > 0 then
                destination = nil
            end
        end
        if destination then
            -- Preserve the rig's pivot offset when restoring the root transform.
            local offset = root.CFrame:ToObjectSpace(localRecord.character:GetPivot())
            if finiteCFrame(offset) then localRecord.character:PivotTo(destination * offset) end
        end
        snapshot, stableSince = nil, nil
        lastRecovery, settleUntil = now, now + CONFIG.SettleTime
        recoveryCount = recoveryCount + 1
        lastReason = reason .. (destination and " / restored" or " / motion stopped")
        lastPosition, lastVelocity, lastSampleTime = root.Position, Vector3.zero, now
    end
    local function watchMotion()
        if not CONFIG.Enabled or not CONFIG.Recovery then return end
        local root = rootOf(localRecord)
        local humanoid = localRecord and localRecord.character and localRecord.character:FindFirstChildOfClass("Humanoid")
        if not root or not humanoid then return end
        local now = os.clock()
        local state = humanoid:GetState()
        if humanoid.Health <= 0 or root.Anchored or humanoid.SeatPart or humanoid.Sit
            or state == Enum.HumanoidStateType.Swimming or state == Enum.HumanoidStateType.Climbing then
            clearHistory(0.4)
            return
        end
        local velocity, angular = root.AssemblyLinearVelocity, root.AssemblyAngularVelocity
        if now < graceUntil then
            lastPosition, lastVelocity, lastSampleTime = root.Position, velocity, now
            return
        end
        if now < settleUntil then stopMotion(); return end
        if not finiteVector(velocity) or not finiteVector(angular) or not finiteCFrame(root.CFrame) then
            if now - lastRecovery >= CONFIG.RecoveryCooldown then recover(root, humanoid, now, "Invalid physics") end
            return
        end
        local speed, spin = horizontal(velocity), angular.Magnitude
        local dt = lastSampleTime and now - lastSampleTime or 0
        local acceleration = lastVelocity and finiteVector(lastVelocity) and dt > 0.001
            and horizontal(velocity - lastVelocity) / dt or 0
        -- Quiet, large position changes are usually game teleports. Discard stale history.
        if lastPosition and finiteVector(lastPosition) and (root.Position - lastPosition).Magnitude > CONFIG.TeleportDistance
            and speed < CONFIG.SafeHorizontalSpeed and spin < CONFIG.SafeAngularSpeed then
            clearHistory(0.6)
            lastReason = "Teleport detected / history cleared"
            return
        end
        local threat = nearThreat(root)
        local extreme = speed >= CONFIG.ExtremeSpeed or spin >= CONFIG.ExtremeAngularSpeed
        local suspicious = speed >= CONFIG.HorizontalSpeed or spin >= CONFIG.AngularSpeed
        local impulse = threat and acceleration >= CONFIG.HorizontalAcceleration and speed > CONFIG.SafeHorizontalSpeed
        -- Require player evidence for moderate motion; allow extreme motion to trigger independently.
        if (extreme or (threat and suspicious) or impulse) and now - lastRecovery >= CONFIG.RecoveryCooldown then
            recover(root, humanoid, now, extreme and "Extreme motion" or "Nearby fling impulse")
            return
        end
        if not suspicious and not impulse and speed < CONFIG.SafeHorizontalSpeed and spin < CONFIG.SafeAngularSpeed
            and math.abs(velocity.Y) < 15 and humanoid.FloorMaterial ~= Enum.Material.Air and not threat then
            local hit = grounded(root, humanoid, root.CFrame)
            if hit and hit.Normal.Y > 0.55 then
                stableSince = stableSince or now
                if now - stableSince >= 0.25 then
                    snapshot = {cf = root.CFrame, time = now}
                    if hit.Instance:IsA("BasePart") then
                        snapshot.ground = hit.Instance
                        snapshot.relative = hit.Instance.CFrame:ToObjectSpace(root.CFrame)
                    end
                end
            else stableSince = nil end
        else stableSince = nil end
        lastPosition, lastVelocity, lastSampleTime = root.Position, velocity, now
    end

    -- GUI: header-only dragging, touch support, clamped to the usable screen.
    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromOffset(260, 230)
    frame.Position = UDim2.new(1, -278, 0, 18)
    frame.BackgroundColor3 = Color3.fromRGB(24, 27, 35)
    frame.BorderSizePixel = 0
    frame.Parent = gui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
    local function label(text, y, height)
        local item = Instance.new("TextLabel")
        item.BackgroundTransparency = 1
        item.Position = UDim2.fromOffset(12, y)
        item.Size = UDim2.new(1, -24, 0, height)
        item.Font = Enum.Font.Gotham
        item.TextSize = 13
        item.TextColor3 = Color3.fromRGB(225, 230, 240)
        item.TextXAlignment = Enum.TextXAlignment.Left
        item.Text = text
        item.Parent = frame
        return item
    end
    local header = label("ANTI-FLING  /  v2", 0, 38)
    header.Active = true
    header.Size = UDim2.new(1, -50, 0, 38)
    local function button(text, y, callback)
        local item = Instance.new("TextButton")
        item.Position = UDim2.fromOffset(12, y)
        item.Size = UDim2.new(1, -24, 0, 32)
        item.BackgroundColor3 = Color3.fromRGB(52, 62, 82)
        item.BorderSizePixel = 0
        item.Font = Enum.Font.GothamMedium
        item.TextSize = 13
        item.TextColor3 = Color3.new(1, 1, 1)
        item.Text = text
        item.Parent = frame
        Instance.new("UICorner", item).CornerRadius = UDim.new(0, 6)
        connect(item.Activated, callback)
        return item
    end
    local enableButton = button("", 42, function() controller.SetEnabled(not CONFIG.Enabled); scan() end)
    local recoveryButton = button("", 80, function()
        CONFIG.Recovery = not CONFIG.Recovery
        clearHistory(0.4)
        lastReason = CONFIG.Recovery and "Recovery enabled" or "Collision protection only"
    end)
    button("Clear saved recovery position", 118, function()
        clearHistory(0.5)
        lastReason = "Saved position cleared"
    end)
    local status = label("", 160, 28)
    local detail = label("", 191, 30)
    detail.TextSize = 11
    detail.TextWrapped = true
    local close = Instance.new("TextButton")
    close.Size = UDim2.fromOffset(32, 30)
    close.Position = UDim2.new(1, -36, 0, 4)
    close.BackgroundTransparency = 1
    close.Text = "X"
    close.TextSize = 16
    close.TextColor3 = Color3.fromRGB(230, 150, 150)
    close.Parent = frame
    connect(close.Activated, controller.Destroy)

    local dragging, dragOrigin, frameOrigin, touchInput
    local function clampPosition(position)
        local size = gui.AbsoluteSize
        local x = math.clamp(position.X, 0, math.max(0, size.X - frame.AbsoluteSize.X))
        local y = math.clamp(position.Y, 0, math.max(0, size.Y - frame.AbsoluteSize.Y))
        frame.Position = UDim2.fromOffset(x, y)
    end
    connect(header.InputBegan, function(input)
        if dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            touchInput = input.UserInputType == Enum.UserInputType.Touch and input or nil
            dragOrigin = Vector2.new(input.Position.X, input.Position.Y)
            frameOrigin = Vector2.new(frame.Position.X.Scale * gui.AbsoluteSize.X + frame.Position.X.Offset,
                frame.Position.Y.Scale * gui.AbsoluteSize.Y + frame.Position.Y.Offset)
        end
    end)
    connect(UIS.InputChanged, function(input)
        if dragging and ((touchInput and input == touchInput) or (not touchInput and input.UserInputType == Enum.UserInputType.MouseMovement)) then
            clampPosition(frameOrigin + Vector2.new(input.Position.X, input.Position.Y) - dragOrigin)
        end
    end)
    connect(UIS.InputEnded, function(input)
        if input == touchInput or (not touchInput and input.UserInputType == Enum.UserInputType.MouseButton1) then dragging = false end
    end)
    connect(UIS.WindowFocusReleased, function() dragging = false end)
    connect(gui:GetPropertyChangedSignal("AbsoluteSize"), function()
        dragging = false
        clampPosition(Vector2.new(frame.Position.X.Scale * gui.AbsoluteSize.X + frame.Position.X.Offset,
            frame.Position.Y.Scale * gui.AbsoluteSize.Y + frame.Position.Y.Offset))
    end)

    local function updateHUD()
        enableButton.Text = CONFIG.Enabled and "Protection: ON" or "Protection: OFF"
        enableButton.BackgroundColor3 = CONFIG.Enabled and Color3.fromRGB(37, 125, 85) or Color3.fromRGB(120, 58, 58)
        recoveryButton.Text = CONFIG.Recovery and "Motion recovery: ON" or "Motion recovery: OFF"
        status.Text = string.format("Nearby: %d   Pairs: %d   Saves: %d", blockedCount, constraintCount, recoveryCount)
        detail.Text = capped and "Constraint limit reached / partial coverage"
            or pending and "Building collision protection..." or lastReason
    end
    scan()
    updateHUD()
    local nextScan, nextHUD = 0, 0
    local failed = false
    local function guarded(callback)
        return function()
            if not alive or failed then return end
            local ok, err = xpcall(callback, debug.traceback)
            if not ok then
                failed = true
                controller.Destroy()
                warn("[Anti-Fling] Stopped and cleaned up after an error:\n" .. tostring(err))
            end
        end
    end
    connect(RunService.PreSimulation, guarded(function()
        local now = os.clock()
        if now >= nextScan then scan(); nextScan = now + CONFIG.ScanInterval end
        buildPairs()
        if CONFIG.Enabled and CONFIG.Recovery and now < settleUntil then stopMotion() end
    end))
    connect(RunService.PostSimulation, guarded(watchMotion))
    connect(RunService.Heartbeat, guarded(function()
        if os.clock() >= nextHUD then updateHUD(); nextHUD = os.clock() + 0.2 end
    end))
    -- External GUI deletion also shuts down physics listeners.
    connect(gui.Destroying, controller.Destroy)
end

local ok, err = xpcall(start, debug.traceback)
if not ok then
    controller.Destroy()
    warn("[Anti-Fling] Could not start:\n" .. tostring(err))
end
