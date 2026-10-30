--[[
    COOLWIPS  /  AFK WALKER NEON UNIVERSAL  /  v4.1
    Self-contained client-side Luau: no HTTP calls, external GUI libraries,
    loadstring dependencies, filesystem requirements or special permissions.

    Executor APIs are OPTIONAL, guarded by pcall, and selected at runtime.
    Walk follows validated paths using Humanoid:MoveTo; no root teleporting.
    Compatibility: gethui/CoreGui/protect_gui, file APIs, shared globals,
    PlayerModule and virtual input are optional. A permitted Roblox client
    environment with working engine APIs is required.

    USAGE: Stand on safe ground, SET HOME, choose Walk/Hybrid, then START.
    STOP cancels movement and pulses. L hides/shows. WASD/arrows pause.
    Style > UNLOAD removes the script. Closing the window only hides it.
    Home survives respawns in this server; returning from a remote spawn may
    cross the roaming radius. Routes reject missing floor and unsafe detours.
    Timing controls are maximum route budgets; arrivals may finish sooner.
    Ground safety is mandatory. Input API success does not prove idle reset.
    Pulse/Hybrid try several optional virtual-input mechanisms and display
    a useful message if the host blocks them. No executor is guaranteed.

    This script cannot guarantee avoiding Roblox or experience-specific idle
    checks and does not teleport, alter the server or bypass security.
]]

-- SERVICES & INSTANCE SAFETY --------------------------------------------------
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
assert(player, "Run this script on a Roblox client")

-- Collect whichever script-global tables this executor actually shares.
-- Neither getgenv nor shared is required; _G is a normal fallback.
local envs = {}
local function addEnv(candidate)
    if type(candidate) ~= "table" then return end
    for _, item in ipairs(envs) do
        if item == candidate then return end
    end
    table.insert(envs, candidate)
end
if type(getgenv) == "function" then
    local ok, candidate = pcall(getgenv)
    if ok then addEnv(candidate) end
end
addEnv(_G)
pcall(function() addEnv(shared) end)
local env = envs[1] or {}

-- Clean up previous versions if we can see their execution environments.
local calledCleanup = {}
for _, space in ipairs(envs) do
    for _, name in ipairs({"__CoolWipsUniversalCleanup", "__CoolWipsNeonCleanup", "__CoolWipsAFKWalkerStop"}) do
        local cleanup = space[name]
        if type(cleanup) == "function" and not calledCleanup[cleanup] then
            calledCleanup[cleanup] = true
            pcall(cleanup)
        end
    end
end

-- Even when the previous script used isolated globals, its old render-step
-- movement hook may still exist and cancel Humanoid:MoveTo() every frame.
-- Remove that named hook before installing the original movement logic.
pcall(function() RunService:UnbindFromRenderStep("CW_NeonWalker_MovementMotor") end)

-- Some executors deliberately isolate globals. Remove abandoned old GUIs
-- independently of getgenv (their background loops cannot be controlled
-- if the executor prevents access to their cleanup function).
local uiNames = {
    CoolWipsWalkerNeonV3 = true,
    CoolWipsWalkerNeonUniversal = true,
    CoolWipsWalkerNeonUniversalV32 = true,
    CoolWipsWalkerNeonUniversalV33 = true,
    CoolWipsWalkerNeonUniversalV34 = true,
    CoolWipsWalkerNeonUniversalV35 = true,
    CoolWipsWalkerNeonUniversalV36 = true,
    CoolWipsWalkerNeonUniversalV40 = true,
    CoolWipsWalkerNeonUniversalV41 = true,
}
-- A prior version may have lost access to its own cleanup callback, e.g.
-- after a fresh injection environment. Clear its visuals as well as its GUI.
pcall(function()
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Folder") and (obj.Name == "CW_Neon_LocalMarkers" or
            obj.Name == "CW_Neon_LocalMarkers_V32" or
            obj.Name == "CW_Neon_LocalMarkers_V33" or
            obj.Name == "CW_Neon_LocalMarkers_V34" or
            obj.Name == "CW_Neon_LocalMarkers_V35" or
            obj.Name == "CW_Neon_LocalMarkers_V36" or
            obj.Name == "CW_Neon_LocalMarkers_V40" or
            obj.Name == "CW_Neon_LocalMarkers_V41") then
            obj:Destroy()
        end
    end
end)
local function clearNamedGui(parent)
    if not parent then return end
    pcall(function()
        for _, child in ipairs(parent:GetChildren()) do
            if uiNames[child.Name] and child:IsA("ScreenGui") then
                child:Destroy()
            end
        end
    end)
end
local oldPlayerGui = player:FindFirstChildOfClass("PlayerGui")
clearNamedGui(oldPlayerGui)
local canCore, oldCore = pcall(function() return game:GetService("CoreGui") end)
if canCore then clearNamedGui(oldCore) end
if type(gethui) == "function" then
    local ok, hiddenRoot = pcall(gethui)
    if ok then clearNamedGui(hiddenRoot) end
end

local function optionalService(name)
    local ok, service = pcall(function() return game:GetService(name) end)
    return ok and service or nil
end
local VirtualUser = optionalService("VirtualUser")
local VirtualInputManager = optionalService("VirtualInputManager")
local virtualInput = nil
local pulseBackend = "NOT TESTED"
local lastPulseError = "No attempt yet"
local function getVirtualInput()
    if virtualInput then return virtualInput end
    -- CreateVirtualInput is not part of the regular UserInputService API.
    -- Some hosts expose an object; probe it carefully and otherwise skip.
    local ok, instance = pcall(function() return UIS.CreateVirtualInput end)
    if ok and type(instance) == "function" then
        local good, value = pcall(instance, UIS)
        if good then virtualInput = value end
    end
    return virtualInput
end

-- Reject NaN, infinity and implausible coordinates before navigation or drawing.
local function finite(n)
    return type(n) == "number" and n == n and math.abs(n) < math.huge
end
local function validPosition(v)
    return typeof(v) == "Vector3" and finite(v.X) and finite(v.Y) and finite(v.Z)
        and math.abs(v.X) <= 1000000 and math.abs(v.Y) <= 1000000
        and math.abs(v.Z) <= 1000000 and v.Y > workspace.FallenPartsDestroyHeight + 8
end
local CONFIG_FILE = "CoolWips_AFK_Walker_Neon_Settings.json"
local defaults = {
    mode = "Hybrid", radius = 24, minWalk = 4, maxWalk = 9, fixedWalk = 6,
    walkPause = 3,
    randomWalk = true, pingInterval = 55, pingOnIdle = true,
    resumeAfterRespawn = true, autoRecover = true,
    showWorldVisuals = true, showTarget = true, allowJump = true,
    uiScale = 1.0, accent = "Cyan",
    safeGround = true, showTrail = true, returnRetry = 5,
}
local settings = {}
local storageStatus = "MEMORY ONLY"
local loadedFromDisk = false
for k, v in pairs(defaults) do settings[k] = v end
-- Executor-local disk settings are optional; in-memory preferences also work.
if type(readfile) == "function" then
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CONFIG_FILE)) end)
    if ok and type(data) == "table" then
        loadedFromDisk = true
        for k in pairs(defaults) do
            if data[k] ~= nil then settings[k] = data[k] end
        end
    end
end
if type(env.__CoolWipsNeonPrefs) == "table" then
    for k in pairs(defaults) do
        if env.__CoolWipsNeonPrefs[k] ~= nil then settings[k] = env.__CoolWipsNeonPrefs[k] end
    end
end
-- Import matching options from the older v2 walker on a first v3 run.
if not loadedFromDisk and type(env.__CoolWipsNeonPrefs) ~= "table" and
    type(env.__CoolWipsAFKWalkerPrefs) == "table" then
    local prior = env.__CoolWipsAFKWalkerPrefs
    local names = {
        radius = "radius", minWalkTime = "minWalk", maxWalkTime = "maxWalk",
        fixedWalkTime = "fixedWalk", pingInterval = "pingInterval",
        randomTiming = "randomWalk",
        showVisuals = "showWorldVisuals",
    }
    for old, new in pairs(names) do
        if prior[old] ~= nil then settings[new] = prior[old] end
    end
    if prior.mode == "Ping" then settings.mode = "Pulse"
    elseif prior.mode == "Walk" or prior.mode == "Hybrid" then
        settings.mode = prior.mode
    end
end
local function bounded(x, default, low, high, step)
    local n = tonumber(x)
    if not n or n ~= n or n == math.huge or n == -math.huge then n = default end
    n = math.clamp(n, low, high)
    if step then n = math.clamp(math.floor(n / step + 0.5) * step, low, high) end
    return n
end
local validModes = {Walk = true, Pulse = true, Hybrid = true}
local palettes = {
    Cyan = Color3.fromRGB(60, 206, 255),
    Violet = Color3.fromRGB(165, 119, 255),
    Lime = Color3.fromRGB(103, 240, 162),
    Rose = Color3.fromRGB(255, 104, 157),
    Amber = Color3.fromRGB(255, 192, 94),
}
if not validModes[settings.mode] then settings.mode = "Hybrid" end
if not palettes[settings.accent] then settings.accent = "Cyan" end
settings.radius = bounded(settings.radius, 24, 10, 100, 1)
settings.walkPause = bounded(settings.walkPause, 3, 3, 30, 1)
settings.minWalk = bounded(settings.minWalk, 4, 2, 20, 1)
settings.maxWalk = bounded(settings.maxWalk, 9, settings.minWalk, 30, 1)
settings.fixedWalk = bounded(settings.fixedWalk, 6, 2, 30, 1)
settings.pingInterval = bounded(settings.pingInterval, 55, 30, 120, 1)
settings.returnRetry = bounded(settings.returnRetry, 5, 3, 20, 1)
settings.uiScale = bounded(settings.uiScale, 1, 0.75, 1.15, 0.05)
for _, name in ipairs({"randomWalk", "pingOnIdle", "resumeAfterRespawn",
    "autoRecover",
    "showWorldVisuals", "showTarget", "allowJump", "safeGround", "showTrail"}) do
    if type(settings[name]) ~= "boolean" then settings[name] = defaults[name] end
end
local saveSerial = 0
local function flushSettings()
    if type(writefile) ~= "function" then return end
    local copy = {}
    for key in pairs(defaults) do copy[key] = settings[key] end
    local ok = pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(copy))
    end)
    storageStatus = ok and "FILE + MEMORY" or "MEMORY (FILE WRITE BLOCKED)"
end
local function saveSettings(immediate)
    local copy = {}
    for key in pairs(defaults) do copy[key] = settings[key] end
    for _, space in ipairs(envs) do
        pcall(function() space.__CoolWipsNeonPrefs = copy end)
    end
    saveSerial = saveSerial + 1
    local thisSave = saveSerial
    if immediate == true then
        flushSettings()
    elseif type(writefile) == "function" then
        -- Coalesce multiple slider updates; no rapid filesystem spam.
        task.delay(0.85, function()
            if saveSerial == thisSave then flushSettings() end
        end)
    end
end
saveSettings()

-- Source-of-truth for home is a scoped session record, never the spawn point.
local placeKey = tostring(game.PlaceId) .. ":" .. tostring(game.JobId)
local alive, running, token = true, false, 0
local releaseInput = nil
local activePathConnection = nil
local teardownMotor = function() end
local ownedHum, ownedRoot, movementId
local controls, controlsOwned = nil, false
-- PlayerModule's default controller can cancel MoveTo every frame. Suspend it
-- only while a route owns movement, and restore its previous enabled state.
task.spawn(function()
    local scripts = player:WaitForChild("PlayerScripts", 10)
    local module = scripts and scripts:WaitForChild("PlayerModule", 10)
    if not module then return end
    local ok, value = pcall(function() return require(module):GetControls() end)
    if alive and ok and type(value) == "table" and type(value.Disable) == "function"
        and type(value.Enable) == "function" then controls = value end
end)
local function releaseControls()
    if controlsOwned then
        controlsOwned = false
        pcall(function() controls:Enable() end)
    end
end
local function stopOwnedMovement(id)
    if id ~= nil and movementId ~= id then return end
    teardownMotor()
    local h, r = ownedHum, ownedRoot
    ownedHum, ownedRoot, movementId = nil, nil, nil
    if h and r and h.Parent and r.Parent and validPosition(r.Position) then
        pcall(function() h:MoveTo(r.Position) end)
    end
    releaseControls()
end
local character, hum, root, home, deathConn
local savedHome = nil
for _, space in ipairs(envs) do
    local record = space.__CoolWipsSessionHome
    if type(record) == "table" and record.key == placeKey and
       validPosition(record.pos) then
        savedHome = record.pos
        break
    end
end
home = savedHome
-- The selected home survives every death and teleport. Only SET HOME changes
-- it after the first character initializes the default home position.
local mustReturnHome = false
local status = "READY TO GO"
local note, noteUntil = "", 0
local target, walkStart, walkEnd, nextWalkAt
local sessionSince, pastSeconds = nil, 0
local nextPulseAt = 0
-- The only movement method is the original Humanoid:MoveTo.
local motor = {goal = nil, token = nil, renderBound = false,
    available = false, backend = "MOVE-TO / INITIALIZING"}
local assistRenderName = "CW_NeonWalker_MovementMotor"
local assistRenderBound = false
local assistHeartbeat
teardownMotor = function()
    if assistRenderBound then
        pcall(function() RunService:UnbindFromRenderStep(assistRenderName) end)
        assistRenderBound = false
    end
    if assistHeartbeat then assistHeartbeat:Disconnect(); assistHeartbeat = nil end
end
local lastPulseAt = -math.huge
local pulseBusy = false
local stats = {routes = 0, arrivals = 0, recoveries = 0,
    pulses = 0, pulseFailures = 0, distance = 0, pathPlans = 0,
    pathFailures = 0, stuck = 0}
local lastPos, lastPosAt
local recentErrors, lastFailure = {}, "None"
local activityLog = {}
local lastRouteOutcome, lastRouteDuration, lastTargetDistance = "NOT STARTED", 0, 0
local routePhase, currentWaypoint, totalWaypoints = "IDLE", 0, 0
local function logEvent(message)
    local stamp = os.date("%H:%M:%S")
    table.insert(activityLog, 1, stamp .. "  " .. tostring(message):sub(1, 135))
    if #activityLog > 12 then table.remove(activityLog) end
end
local rng = Random.new()
local conns = {}
local gui, panel, visuals
local refreshControls = function() end
local updateWorld = function() end
local applyScale = function() end
local function connect(signal, callback)
    local c = signal:Connect(callback)
    table.insert(conns, c)
    return c
end
local function recordError(where, message)
    local line = tostring(where) .. ": " .. tostring(message):sub(1, 135)
    lastFailure = line
    logEvent("ERROR " .. line)
    table.insert(recentErrors, 1, line)
    if #recentErrors > 8 then table.remove(recentErrors, #recentErrors) end
    warn("[CW WALKER V4.1] " .. line)
end
local function inform(message)
    note, noteUntil = message, os.clock() + 2.7
end
local function setStatus(message)
    if alive then status = message end
end
local function persistHome()
    if not validPosition(home) then return end
    for _, space in ipairs(envs) do
        pcall(function() space.__CoolWipsSessionHome = {key = placeKey, pos = home} end)
    end
end
local function horizontalDistance(a, b)
    local dx, dz = a.X - b.X, a.Z - b.Z
    return math.sqrt(dx * dx + dz * dz)
end
local function isCharacterReady()
    return character and hum and root and hum.Parent and root.Parent
        and character == player.Character and hum.Health > 0 and hum.SeatPart == nil
        and not hum.PlatformStand and validPosition(root.Position)
end
local function mayWalk(id)
    return alive and running and id == token and settings.mode ~= "Pulse"
        and isCharacterReady() and home ~= nil
end
local function haltMovement()
    token = token + 1
    stopOwnedMovement()
    if releaseInput then pcall(releaseInput); releaseInput = nil end
    if activePathConnection then activePathConnection:Disconnect(); activePathConnection = nil end
    target, walkStart, walkEnd, nextWalkAt = nil, nil, nil, nil
    motor.goal, motor.token = nil, nil
    routePhase, currentWaypoint, totalWaypoints = "IDLE", 0, 0

end
local function waitWhile(seconds, id)
    local untilTime = os.clock() + seconds
    while alive and token == id do
        local finish = nextWalkAt or untilTime
        if not running then return false end
        if os.clock() >= finish then break end
        task.wait(math.min(0.16, finish - os.clock()))
    end
    return alive and token == id and running
end
local function setRunning(on)
    if not alive or on == running then return end
    running = on
    if not on and releaseInput then pcall(releaseInput); releaseInput = nil end
    haltMovement()
    if on then
        logEvent("WALKER STARTED · " .. settings.mode)
        sessionSince = os.clock()
        nextPulseAt = os.clock() + settings.pingInterval
        if settings.mode == "Pulse" then nextWalkAt = nil else nextWalkAt = os.clock() end
        setStatus(isCharacterReady() and (settings.mode == "Pulse" and "PULSE MONITORING" or "ROUTE STARTING")
            or "WAITING FOR CHARACTER")
        inform("System enabled")
    else
        logEvent("WALKER PAUSED")
        if sessionSince then pastSeconds = pastSeconds + os.clock() - sessionSince end
        sessionSince = nil
        setStatus("PAUSED")
        inform("Movement and pulses paused")
    end
    refreshControls()
end
local function unload()
    if not alive then return end
    setRunning(false)
    alive = false
    if releaseInput then pcall(releaseInput); releaseInput = nil end
    token = token + 1
    if deathConn then deathConn:Disconnect(); deathConn = nil end
    pcall(function() RunService:UnbindFromRenderStep(assistRenderName) end)
    assistRenderBound = false
    saveSerial = saveSerial + 1
    saveSettings(true)
    persistHome()
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    if visuals then visuals:Destroy(); visuals = nil end
    if gui then gui:Destroy(); gui = nil end
    for _, space in ipairs(envs) do
        pcall(function()
            if space.__CoolWipsNeonCleanup == unload then space.__CoolWipsNeonCleanup = nil end
            if space.__CoolWipsUniversalCleanup == unload then space.__CoolWipsUniversalCleanup = nil end
        end)
    end
end
for _, space in ipairs(envs) do
    pcall(function()
        space.__CoolWipsNeonCleanup = unload
        space.__CoolWipsUniversalCleanup = unload
    end)
end

-- Single movement owner: stale routes cannot stop a replacement character.
motor.stop = function(id)
    stopOwnedMovement(id)
    if id == nil or id == token then motor.goal, motor.token = nil, nil end
end
motor.start = function(point, id)
    if not mayWalk(id) or not validPosition(point) then return false end
    if controls and not controlsOwned and controls.controlsEnabled == true then
        local ok = pcall(function() controls:Disable() end)
        controlsOwned = ok
    end
    ownedHum, ownedRoot, movementId = hum, root, id
    motor.goal, motor.token = point, id
    -- Some hosts block require(PlayerModule). Run MoveTo after Roblox's input
    -- controller in that case; this repeats a walking goal, never a teleport.
    if not controlsOwned and not assistRenderBound and not assistHeartbeat
        and (not controls or controls.controlsEnabled ~= false) then
        local h, r = hum, root
        local observed = r.Position
        local function assist()
            local p = motor.goal
            if not mayWalk(id) or hum ~= h or root ~= r or not validPosition(p) then
                stopOwnedMovement(id); return
            end
            if not validPosition(r.Position) or (r.Position - observed).Magnitude > 12
                or (not mustReturnHome and horizontalDistance(r.Position, home) >= settings.radius - 0.5) then
                stopOwnedMovement(id); return
            end
            observed = r.Position
            local ok = pcall(function() h:MoveTo(p) end)
            if not ok then stopOwnedMovement(id) end
        end
        local bound = pcall(function()
            RunService:BindToRenderStep(assistRenderName, Enum.RenderPriority.Input.Value + 1, assist)
        end)
        if bound then
            assistRenderBound = true
            motor.backend = "MOVE-TO / FRAME ASSIST"
        else
            local ok, c = pcall(function() return RunService.Heartbeat:Connect(assist) end)
            if ok then assistHeartbeat = c end
            motor.backend = ok and "MOVE-TO / HEARTBEAT ASSIST" or "MOVE-TO / TIMED RETRY"
        end
    elseif controlsOwned then
        motor.backend = "MOVE-TO / PLAYER CONTROLS"
    end
    local ok, err = pcall(function() hum:MoveTo(point) end)
    if not ok then recordError("MoveTo", err); stopOwnedMovement(id) end
    return ok
end

-- CHARACTER / RESPAWN ---------------------------------------------------------
local bindSerial = 0
local function bindCharacter(char)
    if not alive or player.Character ~= char then return end
    bindSerial = bindSerial + 1
    local myBind = bindSerial
    if not alive then return end
    haltMovement()
    if deathConn then deathConn:Disconnect(); deathConn = nil end
    character, hum, root = nil, nil, nil
    setStatus("SPAWNING")
    local newHum = char:WaitForChild("Humanoid", 15)
    local newRoot = char:WaitForChild("HumanoidRootPart", 15)
    if not alive or myBind ~= bindSerial or player.Character ~= char or not newHum or not newRoot
        or not newHum:IsA("Humanoid") or not newRoot:IsA("BasePart") then return end
    character, hum, root = char, newHum, newRoot
    if not home and validPosition(newRoot.Position) then
        -- Only the first spawn defines the initial home automatically.
        home = newRoot.Position
        persistHome()
        mustReturnHome = false
    elseif home then
        -- After death, NEVER replace home with the respawn location.
        -- Force a pathfinding return even if the new spawn happens to fall
        -- within the ordinary random-walk radius.
        mustReturnHome = true
        logEvent("RESPAWN: returning to saved home")
        if running then nextWalkAt = os.clock() end
    end
    lastPos, lastPosAt = newRoot.Position, os.clock()
    deathConn = newHum.Died:Connect(function()
        if not alive or myBind ~= bindSerial or character ~= char then return end
        haltMovement()
        if home then mustReturnHome = true end
        logEvent("CHARACTER DIED: home preserved")
        setStatus("RESPAWNING - HOME IS PRESERVED")
        if running and not settings.resumeAfterRespawn then setRunning(false) end
    end)
    updateWorld()
    setStatus(running and (mustReturnHome and "RESPAWNED - ROUTING TO HOME" or "READY TO RESUME")
        or "READY TO GO")
end
connect(player.CharacterAdded, function(char) task.spawn(bindCharacter, char) end)
connect(player.CharacterRemoving, function(char)
    if char == character then
        bindSerial = bindSerial + 1
        if running and not settings.resumeAfterRespawn then setRunning(false) end
        if deathConn then deathConn:Disconnect(); deathConn = nil end
        haltMovement()
        character, hum, root = nil, nil, nil
        lastPos, lastPosAt = nil, nil
        setStatus("WAITING FOR RESPAWN")
    end
end)
if player.Character then task.spawn(bindCharacter, player.Character) end

-- LOCAL WORLD GUIDES ----------------------------------------------------------
visuals = Instance.new("Folder")
visuals.Name = "CW_Neon_LocalMarkers_V41"
visuals.Parent = settings.showWorldVisuals and workspace or nil
local function neonPart(name, size, transparency)
    local p = Instance.new("Part")
    p.Name, p.Size, p.Transparency = name, size, transparency
    p.Shape = Enum.PartType.Ball
    p.Material = Enum.Material.Neon
    p.Color = palettes[settings.accent]
    p.Anchored = true
    p.CanCollide, p.CanTouch, p.CanQuery = false, false, false
    p.Parent = visuals
    return p
end
local homeDot = neonPart("Home", Vector3.new(1.35, 1.35, 1.35), 0.1)
local targetDot = neonPart("Destination", Vector3.new(0.78, 0.78, 0.78), 1)
local trail = {}
for i = 1, 8 do
    local p = neonPart("RouteTrail_" .. i, Vector3.new(0.23, 0.23, 0.23), 1)
    p.Shape = Enum.PartType.Ball
    trail[i] = p
end
local ring = {}
for i = 1, 36 do
    local p = neonPart("Boundary_" .. i, Vector3.new(0.12, 0.12, 1), 0.5)
    p.Shape = Enum.PartType.Block
    ring[i] = p
end
updateWorld = function()
    if not alive or not visuals then return end
    visuals.Parent = settings.showWorldVisuals and workspace or nil
    if not home then return end
    local accent = palettes[settings.accent]
    homeDot.Position = home
    homeDot.Color = accent
    targetDot.Color = Color3.fromRGB(255, 194, 109)
    targetDot.Transparency = (settings.showTarget and target) and 0.15 or 1
    if target then targetDot.Position = target end
    for i, part in ipairs(trail) do
        local canDisplay = settings.showTrail and settings.showTarget and target ~= nil
            and root ~= nil and root.Parent ~= nil
        part.Transparency = canDisplay and 0.45 or 1
        part.Color = accent
        if canDisplay then
            local fraction = i / (#trail + 1)
            part.Position = root.Position:Lerp(target, fraction)
        end
    end
    for i, piece in ipairs(ring) do
        piece.Color = accent
        local a1, a2 = (i - 1) * math.pi * 2 / #ring, i * math.pi * 2 / #ring
        local py = home.Y - 2.65
        local a = Vector3.new(home.X + math.cos(a1) * settings.radius, py,
            home.Z + math.sin(a1) * settings.radius)
        local b = Vector3.new(home.X + math.cos(a2) * settings.radius, py,
            home.Z + math.sin(a2) * settings.radius)
        piece.Size = Vector3.new(0.12, 0.12, (b - a).Magnitude + 0.03)
        piece.CFrame = CFrame.lookAt((a + b) / 2, b)
    end
end
updateWorld()

-- SAFE NAVIGATION ------------------------------------------------------------
-- Radius constrains roaming routes, including every detour waypoint. Returning
-- from a remote respawn is an explicit exception, with a finite route budget.
local HOME_ARRIVAL_DISTANCE = 2.5
local RETURN_HOME_BUDGET = 105
local pathQueries = 0
local function reached(a, b, tolerance)
    return validPosition(a) and validPosition(b)
        and horizontalDistance(a, b) <= (tolerance or 1.4)
        and math.abs(a.Y - b.Y) <= 4
end
local function rayParams()
    local p = RaycastParams.new()
    p.FilterType = Enum.RaycastFilterType.Exclude
    p.FilterDescendantsInstances = character and {character, visuals} or {visuals}
    p.IgnoreWater = false
    p.RespectCanCollide = true
    return p
end
local function groundAt(point)
    if not validPosition(point) then return nil end
    local ok, hit = pcall(function()
        return workspace:Raycast(point + Vector3.new(0, 6, 0), Vector3.new(0, -20, 0), rayParams())
    end)
    if not ok or not hit or hit.Material == Enum.Material.Water or hit.Normal.Y < 0.7 then return nil end
    return hit.Position
end
local function rootHeight()
    -- R6 uses leg height in addition to HipHeight.
    return math.max(2, hum.HipHeight + root.Size.Y / 2
        + (hum.RigType == Enum.HumanoidRigType.R6 and 2 or 0))
end
local function getRandomPoint()
    for _ = 1, 24 do
        local angle = rng:NextNumber(0, math.pi * 2)
        local d = math.sqrt(rng:NextNumber()) * math.max(1, settings.radius - 3)
        local p = home + Vector3.new(math.cos(angle) * d, 0, math.sin(angle) * d)
        local floor = groundAt(p)
        if floor then
            p = Vector3.new(p.X, floor.Y + rootHeight(), p.Z)
            if validPosition(p) and math.abs(p.Y - home.Y) <= 8
                and horizontalDistance(root.Position, p) >= 4 then return p end
        end
    end
    return nil -- Missing ground is a failure, never permission to walk into void.
end
local function chooseTime()
    return settings.randomWalk and rng:NextInteger(settings.minWalk, settings.maxWalk)
        or settings.fixedWalk
end
local function segmentSafe(a, b, roaming)
    if not validPosition(a) or not validPosition(b) then return false end
    if roaming and horizontalDistance(b, home) > settings.radius - 1 then return false end
    if math.abs(a.Y - b.Y) > 8 then return false end
    -- Scan short intervals for missing floor; never use unchecked direct fallback.
    local count = math.max(1, math.ceil((b - a).Magnitude / 2))
    if count > 1024 then return false end
    for i = 0, count do
        local p = a:Lerp(b, i / count)
        local floor = groundAt(p)
        if not floor or math.abs(p.Y - floor.Y - rootHeight()) > 6 then return false end
    end
    return true
end
local function walkDirect(point, id, deadline, returning, blocked)
    if not mayWalk(id) or not validPosition(point) then return "cancelled" end
    local h, r = hum, root
    if not segmentSafe(r.Position, point, not returning) then return "unsafe_segment" end
    if not motor.start(point, id) then return "move_to_error" end
    local best = (r.Position - point).Magnitude
    local progressAt, issueAt, jumped = os.clock(), os.clock(), false
    local previous = r.Position
    local outcome = "timeout"
    while mayWalk(id) and hum == h and root == r and os.clock() < deadline do
        local now, pos = os.clock(), r.Position
        if (pos - previous).Magnitude > math.max(12, h.WalkSpeed * 0.8) then
            outcome = "position_discontinuity"; break
        end
        previous = pos
        if blocked and blocked() then outcome = "route_blocked"; break end
        if reached(pos, point) then outcome = "arrived"; break end
        if not returning and horizontalDistance(pos, home) >= settings.radius - 0.5 then
            outcome = "boundary"; break
        end
        if r.Anchored or h.WalkSpeed <= 0 then outcome = "movement_blocked"; break end
        -- Inspect the next few studs continuously, including return routes.
        local delta = point - pos
        local ahead = pos + delta.Unit * math.min(3, delta.Magnitude)
        if not segmentSafe(pos, ahead, not returning) then outcome = "unsafe_ground"; break end
        local d = delta.Magnitude
        if d < best - 0.2 then best, progressAt = d, now end
        if now - progressAt >= 2 and settings.allowJump and not jumped then
            h.Jump = true; jumped = true
        end
        if now - progressAt >= 4 then stats.stuck = stats.stuck + 1; outcome = "stuck"; break end
        if now - issueAt >= 1.5 then
            if not motor.start(point, id) then outcome = "move_to_error"; break end
            issueAt = now
        end
        task.wait(0.1)
    end
    motor.stop(id)
    if not mayWalk(id) then return "cancelled" end
    return outcome
end
local function navigate(goal, id, deadline, returning)
    if not mayWalk(id) or not validPosition(goal) then return "invalid_goal" end
    local h, r = hum, root
    for _ = 1, 4 do
        if not mayWalk(id) or hum ~= h or root ~= r then return "cancelled" end
        if reached(r.Position, goal, HOME_ARRIVAL_DISTANCE) then return "arrived" end
        if os.clock() >= deadline then return "timeout" end
        if pathQueries > 0 then return "path_query_busy" end
        routePhase = "COMPUTING ROUTE"
        stats.pathPlans = stats.pathPlans + 1
        local path = PathfindingService:CreatePath({AgentRadius = 2, AgentHeight = 5,
            AgentCanJump = settings.allowJump, AgentCanClimb = false, WaypointSpacing = 3})
        local done, ok, expired = false, false, false
        local origin = r.Position
        pathQueries = pathQueries + 1
        task.spawn(function()
            ok = pcall(function() path:ComputeAsync(origin, goal) end)
            pathQueries = pathQueries - 1
            done = true
            if expired then path:Destroy() end
        end)
        local limit = math.min(deadline, os.clock() + 8)
        while not done and mayWalk(id) and os.clock() < limit do task.wait(0.1) end
        if not done then expired = true; return mayWalk(id) and "path_timeout" or "cancelled" end
        if not mayWalk(id) then path:Destroy(); return "cancelled" end
        if (r.Position - origin).Magnitude > 6 then path:Destroy(); return "origin_changed" end
        if not ok or path.Status ~= Enum.PathStatus.Success then
            stats.pathFailures = stats.pathFailures + 1
            path:Destroy()
            return "no_path" -- Never walk blindly through an obstacle after path failure.
        end
        local waypoints = path:GetWaypoints()
        local safe = #waypoints >= 2
        for _, wp in ipairs(waypoints) do
            if not validPosition(wp.Position) or (not returning
                and horizontalDistance(wp.Position, home) > settings.radius - 2) then safe = false; break end
            if wp.Action == Enum.PathWaypointAction.Jump and not settings.allowJump then safe = false; break end
        end
        if not safe then path:Destroy(); return "route_outside_safe_area" end
        totalWaypoints = #waypoints
        local index, blockedAhead = 2, false
        local connection = path.Blocked:Connect(function(n)
            if n >= index then blockedAhead = true end
        end)
        activePathConnection = connection
        local outcome = "path_ended"
        for i = 2, #waypoints do
            index, currentWaypoint = i, i
            if not mayWalk(id) then outcome = "cancelled"; break end
            routePhase = returning and "RETURNING HOME" or "FOLLOWING ROAM PATH"
            local wp = waypoints[i]
            -- Navmesh waypoints are floor coordinates, MoveTo can accept them;
            -- use the rig's root height for consistent arrival and floor checks.
            local floor = groundAt(wp.Position)
            if not floor then outcome = "unsafe_ground"; break end
            local point = Vector3.new(wp.Position.X, floor.Y + rootHeight(), wp.Position.Z)
            if wp.Action == Enum.PathWaypointAction.Jump then h.Jump = true end
            local budget = math.clamp((r.Position - point).Magnitude / math.max(1, h.WalkSpeed) + 3, 3, 12)
            outcome = walkDirect(point, id, math.min(deadline, os.clock() + budget), returning,
                function() return blockedAhead end)
            if outcome ~= "arrived" then break end
        end
        connection:Disconnect()
        if activePathConnection == connection then activePathConnection = nil end
        path:Destroy()
        if not mayWalk(id) then return "cancelled" end
        if reached(r.Position, goal, HOME_ARRIVAL_DISTANCE) then return "arrived" end
        if not settings.autoRecover or outcome == "boundary" or outcome == "unsafe_ground"
            or outcome == "unsafe_segment" or outcome == "position_discontinuity" then return outcome end
        stats.recoveries = stats.recoveries + 1
        task.wait(0.3)
    end
    return "replan_limit"
end
local failures = 0
local function scheduleNext(seconds, message)
    walkStart, walkEnd, target = nil, nil, nil
    routePhase = mustReturnHome and "RETURN HOME RETRY" or "NEXT WALK COUNTDOWN"
    currentWaypoint, totalWaypoints = 0, 0
    nextWalkAt = os.clock() + seconds
    setStatus(message or "WAITING FOR NEXT WALK")
    updateWorld()
end
local function movementStep()
    if not running or settings.mode == "Pulse" then task.wait(0.15); return end
    if not isCharacterReady() then setStatus("WAITING FOR LIVE, UNSEATED CHARACTER"); task.wait(0.3); return end
    if root.Anchored or hum.WalkSpeed <= 0 then setStatus("MOVEMENT BLOCKED BY GAME"); task.wait(0.5); return end
    if not home then home = root.Position; persistHome(); updateWorld() end
    local id = token
    if nextWalkAt and os.clock() < nextWalkAt then task.wait(0.1); return end
    nextWalkAt = nil
    if mustReturnHome and reached(root.Position, home, HOME_ARRIVAL_DISTANCE) then mustReturnHome = false end
    local returning = mustReturnHome or horizontalDistance(root.Position, home) > settings.radius - 1
        or math.abs(root.Position.Y - home.Y) > 8
    if returning then mustReturnHome = true end
    local duration = returning and RETURN_HOME_BUDGET or chooseTime()
    walkStart, walkEnd = os.clock(), os.clock() + duration
    target = returning and home or getRandomPoint()
    if not target then
        lastFailure = "No safe ground destination"
        if not settings.autoRecover then setRunning(false); setStatus(lastFailure)
        else scheduleNext(settings.walkPause, "NO SAFE GROUND TARGET - RETRYING") end
        return
    end
    stats.routes = stats.routes + 1
    updateWorld()
    setStatus(returning and "PATHFINDING TO SAVED HOME" or "WALKING SAFE ROUTE")
    local started = os.clock()
    local outcome = navigate(target, id, walkEnd, returning)
    -- Cancellation owns all state changes: stale work never schedules a new walk.
    if id ~= token or not alive or not running then return end
    motor.stop(id)
    lastRouteOutcome, lastRouteDuration = outcome, os.clock() - started
    logEvent((returning and "HOME " or "WALK ") .. string.upper(outcome))
    if outcome == "arrived" then
        failures = 0
        if returning then mustReturnHome = false end
        stats.arrivals = stats.arrivals + 1
        lastFailure = "None"
        scheduleNext(settings.walkPause, returning and "BACK AT SAVED HOME" or "ARRIVED")
    elseif outcome == "cancelled" then
        scheduleNext(settings.walkPause, "MOVEMENT INTERRUPTED")
    else
        failures = failures + 1
        lastFailure = "Navigation: " .. outcome
        if outcome == "boundary" then mustReturnHome = true end
        if not settings.autoRecover then setRunning(false); setStatus(lastFailure); return end
        -- Bounded retries and backoff prevent tight loops on unreachable homes.
        local base = returning and settings.returnRetry or settings.walkPause
        scheduleNext(math.min(30, base * math.min(4, failures)), "RETRY: " .. outcome)
    end
end
task.spawn(function()
    while alive do
        local id = token
        local ok, err = xpcall(movementStep, function(e) return tostring(e) end)
        if not ok and alive and id == token then
            motor.stop(id)
            if activePathConnection then activePathConnection:Disconnect(); activePathConnection = nil end
            recordError("Movement", err)
            if running and settings.autoRecover then scheduleNext(settings.walkPause, "NAVIGATION ERROR - RETRYING")
            else setRunning(false) end
        end
        task.wait(0.05)
    end
end)

-- ACTIVITY PULSE: CAPABILITY-BASED BACKENDS -----------------------------------
-- Each method is optional. A successful API call does NOT establish that the
-- experience registered an input or that Roblox's idle detection was reset.
local function pulseWithVirtualUser()
    if not VirtualUser then return false end
    local camera = workspace.CurrentCamera
    local cf = camera and camera.CFrame or CFrame.new()
    pcall(function() VirtualUser:CaptureController() end)
    local okDown = pcall(function()
        VirtualUser:Button2Down(Vector2.new(0, 0), cf)
    end)
    if not okDown then return false end
    local release = function() VirtualUser:Button2Up(Vector2.new(0, 0), cf) end
    releaseInput = release
    task.wait(0.08)
    local okUp = pcall(release)
    if releaseInput == release then releaseInput = nil end
    return okUp
end

local function pulseWithVirtualInput()
    local vi = getVirtualInput()
    if not vi then return false end
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(900, 600)
    local pos = Vector2.new(math.floor(viewport.X * 0.5), math.floor(viewport.Y * 0.5))
    local down = pcall(function()
        vi:SendMouseButton(pos, Enum.UserInputType.MouseButton2, true, 0)
    end)
    if not down then return false end
    local release = function() vi:SendMouseButton(pos, Enum.UserInputType.MouseButton2, false, 0) end
    releaseInput = release
    task.wait(0.08)
    local up = pcall(release)
    if releaseInput == release then releaseInput = nil end
    return up
end

local function pulseWithVIM()
    if not VirtualInputManager then return false end
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(900, 600)
    local x, y = math.floor(viewport.X * 0.5), math.floor(viewport.Y * 0.5)
    -- RobloxScriptSecurity often makes these methods inaccessible.
    local down = pcall(function()
        VirtualInputManager:SendMouseButtonEvent(x, y, 1, true, game, 0)
    end)
    if not down then return false end
    local release = function() VirtualInputManager:SendMouseButtonEvent(x, y, 1, false, game, 0) end
    releaseInput = release
    task.wait(0.08)
    local up = pcall(release)
    if releaseInput == release then releaseInput = nil end
    return up
end

local pulseBackends = {
    {"VIRTUAL USER", pulseWithVirtualUser},
    {"VIRTUAL INPUT", pulseWithVirtualInput},
    {"INPUT MANAGER", pulseWithVIM},

}
local function canPulse()
    return alive and running and (settings.mode == "Hybrid" or settings.mode == "Pulse")
end
local function pulse(force)
    if (not force and not canPulse()) or not alive or pulseBusy then return end
    if not force and os.clock() - lastPulseAt < 8 then return end
    pulseBusy = true
    local pulseToken = token
    lastPulseAt = os.clock()
    nextPulseAt = os.clock() + settings.pingInterval
    local success = false
    for _, backend in ipairs(pulseBackends) do
        if not alive or pulseToken ~= token or (not force and not canPulse()) then break end
        local ok, result = pcall(backend[2])
        if ok and result == true then
            success = true
            pulseBackend = backend[1]
            break
        end
    end
    if alive and pulseToken == token and (force or canPulse()) then
        if success then
            stats.pulses = stats.pulses + 1
            lastPulseError = "Call succeeded (not a guarantee of idle reset)"
            if settings.mode == "Pulse" and running then setStatus("PULSE API CALLED") end
            if force then inform("Input API accepted: " .. pulseBackend) end
        else
            stats.pulseFailures = stats.pulseFailures + 1
            pulseBackend = "UNAVAILABLE"
            lastPulseError = "No virtual-input method was permitted"
            if running then setStatus("INPUT BLOCKED BY EXECUTOR") end
            if force then inform("Input unavailable; use Walk mode") end
        end
    end
    pulseBusy = false
end
connect(player.Idled, function()
    if settings.pingOnIdle and canPulse() then task.spawn(pulse, false) end
end)
task.spawn(function()
    while alive do
        local ok, err = pcall(function()
            if canPulse() and os.clock() >= nextPulseAt then pulse(false) end
        end)
        if not ok then recordError("Pulse", err); pulseBusy = false end
        task.wait(0.3)
    end
end)
-- Sample movement even while paused so resuming does not interpret the entire
-- paused period as one giant teleport; count only plausible short increments.
task.spawn(function()
    while alive do
        local ok, err = pcall(function()
            if root and root.Parent and hum and hum.Health > 0 and validPosition(root.Position) then
                local pos, now = root.Position, os.clock()
                if lastPos and lastPosAt then
                    local dt = math.max(0.05, now - lastPosAt)
                    local d = (pos - lastPos).Magnitude
                    local hugeJump = d > math.max(85, settings.radius * 3, hum.WalkSpeed * dt * 7)
                    if running and settings.mode ~= "Pulse" and hugeJump then
                        haltMovement()
                        -- A teleport does not imply permission to redefine home.
                        -- Preserve the same home and plan a route back.
                        if home then mustReturnHome = true end
                        logEvent("TELEPORT: saved home unchanged")
                        nextWalkAt = os.clock() + 0.25
                        setStatus("TELEPORT DETECTED - RETURNING TO SAVED HOME")
                    elseif running and d < 12 and settings.mode ~= "Pulse" then
                        stats.distance = stats.distance + d
                    end
                end
                lastPos, lastPosAt = pos, now
                if target and settings.showTrail then
                    for i, dot in ipairs(trail) do
                        dot.Position = pos:Lerp(target, i / (#trail + 1))
                    end
                end
            end
        end)
        if not ok then recordError("Position watcher", err) end
        task.wait(0.3)
    end
end)

local function buildInterface()
-- UI KIT ----------------------------------------------------------------------
local C = {
    bg = Color3.fromRGB(9, 13, 26),
    panel = Color3.fromRGB(16, 22, 40),
    card = Color3.fromRGB(23, 32, 52),
    card2 = Color3.fromRGB(29, 39, 62),
    line = Color3.fromRGB(49, 65, 91),
    white = Color3.fromRGB(241, 246, 255),
    soft = Color3.fromRGB(151, 170, 197),
    faint = Color3.fromRGB(105, 123, 150),
    good = Color3.fromRGB(106, 240, 174),
    bad = Color3.fromRGB(255, 106, 132),
}
local accent = palettes[settings.accent]
local function el(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do obj[k] = v end
    if parent then obj.Parent = parent end
    return obj
end
local function corner(obj, r)
    el("UICorner", {CornerRadius = UDim.new(0, r or 10)}, obj)
end
local function outline(obj, color, transparency)
    return el("UIStroke", {Color = color or C.line, Thickness = 1,
        Transparency = transparency or 0.25}, obj)
end
local function textLabel(parent, content, fontSize, bold, color)
    return el("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, fontSize + 8),
        Text = content or "", Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextSize = fontSize, TextColor3 = color or C.white,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
    }, parent)
end
local function button(parent, txt, background)
    local b = el("TextButton", {
        BackgroundColor3 = background or C.card2,
        BorderSizePixel = 0, AutoButtonColor = false,
        Text = txt, TextSize = 12, Font = Enum.Font.GothamBold,
        TextColor3 = C.white,
    }, parent)
    corner(b, 10)
    connect(b.MouseEnter, function()
        if alive then TweenService:Create(b, TweenInfo.new(0.16),
            {BackgroundTransparency = 0.12}):Play() end
    end)
    connect(b.MouseLeave, function()
        if alive then TweenService:Create(b, TweenInfo.new(0.16),
            {BackgroundTransparency = 0}):Play() end
    end)
    return b
end
local function framed(parent, pos, size, color, radius)
    local f = el("Frame", {Position = pos, Size = size, BackgroundColor3 = color or C.card,
        BorderSizePixel = 0}, parent)
    corner(f, radius or 12)
    outline(f)
    return f
end
local function hline(parent, y)
    return el("Frame", {Position = UDim2.new(0, 0, 0, y),
        Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.line,
        BackgroundTransparency = 0.65, BorderSizePixel = 0}, parent)
end
local function formatTime(sec)
    local s = math.max(0, math.floor(sec))
    return string.format("%02d:%02d:%02d", math.floor(s / 3600),
        math.floor(s / 60) % 60, s % 60)
end

-- ROOT WINDOW -----------------------------------------------------------------
-- Executor UI isolation is optional: gethui -> PlayerGui -> CoreGui.
-- Never make the script depend on gethui/protect_gui/syn APIs.
local uiParent
if type(gethui) == "function" then
    local ok, parent = pcall(gethui)
    if ok and typeof(parent) == "Instance" then uiParent = parent end
end
if not uiParent then
    uiParent = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui", 10)
end
if not uiParent then uiParent = oldCore end
assert(uiParent, "Unable to find a GUI parent on this client")
gui = el("ScreenGui", {Name = "CoolWipsWalkerNeonUniversalV41", ResetOnSpawn = false,
    IgnoreGuiInset = true, DisplayOrder = 800, ZIndexBehavior = Enum.ZIndexBehavior.Sibling})
local attached = pcall(function() gui.Parent = uiParent end)
if not attached and oldCore then attached = pcall(function() gui.Parent = oldCore end) end
if not attached then
    local pg = player:FindFirstChildOfClass("PlayerGui")
    if pg then attached = pcall(function() gui.Parent = pg end) end
end
assert(attached, "This executor blocks GUI attachment")
connect(gui.Destroying, unload)
connect(gui.AncestryChanged, function(_, parent) if parent == nil and alive then unload() end end)
if type(protect_gui) == "function" then pcall(protect_gui, gui)
elseif type(syn) == "table" and type(syn.protect_gui) == "function" then pcall(syn.protect_gui, gui) end
panel = framed(gui, UDim2.new(0, 34, 0.12, 0), UDim2.fromOffset(472, 648), C.bg, 18)
panel.Active = true
panel.ClipsDescendants = true
local panelGradient = el("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 26, 47)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(9, 13, 27)),
    }), Rotation = 95,
}, panel)
local uiScale = el("UIScale", {Scale = settings.uiScale}, panel)
local topAccent = el("Frame", {Size = UDim2.new(1, 0, 0, 4),
    BackgroundColor3 = accent, BorderSizePixel = 0, ZIndex = 4}, panel)
local topGradient = el("UIGradient", {Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, accent),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(98, 103, 243))})}, topAccent)

local header = el("Frame", {Size = UDim2.new(1, 0, 0, 79),
    BackgroundTransparency = 1, Active = true}, panel)
local brand = framed(header, UDim2.fromOffset(17, 19), UDim2.fromOffset(43, 43), C.card2, 12)
local brandText = textLabel(brand, "CW", 18, true, accent)
brandText.Size = UDim2.fromScale(1, 1)
brandText.TextXAlignment = Enum.TextXAlignment.Center
local title = textLabel(header, "COOLWIPS", 17, true)
title.Position, title.Size = UDim2.fromOffset(71, 16), UDim2.fromOffset(210, 25)
local subTitle = textLabel(header, "AFK WALKER  /  NEON NAVIGATOR", 10, true, C.soft)
subTitle.Position, subTitle.Size = UDim2.fromOffset(72, 42), UDim2.fromOffset(268, 18)
local version = textLabel(header, "V4.1", 9, true, accent)
version.Position, version.Size = UDim2.fromOffset(313, 22), UDim2.fromOffset(36, 16)
local minimize = button(header, "—", C.card2)
minimize.Position, minimize.Size = UDim2.fromOffset(385, 22), UDim2.fromOffset(32, 30)
local close = button(header, "×", Color3.fromRGB(78, 37, 62))
close.Position, close.Size = UDim2.fromOffset(426, 22), UDim2.fromOffset(29, 30)
hline(header, 78)

local body = el("Frame", {Position = UDim2.fromOffset(0, 79),
    Size = UDim2.new(1, 0, 1, -79), BackgroundTransparency = 1}, panel)
local hero = framed(body, UDim2.fromOffset(15, 12), UDim2.new(1, -30, 0, 96), C.panel, 13)
local indicator = el("Frame", {Position = UDim2.fromOffset(16, 22),
    Size = UDim2.fromOffset(11, 11), BackgroundColor3 = C.faint,
    BorderSizePixel = 0}, hero)
corner(indicator, 8)
local heroStatus = textLabel(hero, "SYSTEM STANDBY", 16, true)
heroStatus.Position, heroStatus.Size = UDim2.fromOffset(36, 13), UDim2.new(1, -50, 0, 29)
local heroDetail = textLabel(hero, "Waiting for your command", 11, false, C.soft)
heroDetail.Position, heroDetail.Size = UDim2.fromOffset(17, 42), UDim2.new(1, -30, 0, 23)
local heroSession = textLabel(hero, "SESSION  00:00:00", 11, true, C.soft)
heroSession.Position, heroSession.Size = UDim2.fromOffset(17, 68), UDim2.new(0.48, -17, 0, 17)
settings.nextWalkHero = textLabel(hero, "NEXT WALK: --", 12, true, accent)
settings.nextWalkHero.Position = UDim2.new(0.47, 0, 0, 68)
settings.nextWalkHero.Size = UDim2.new(0.52, -8, 0, 19)
settings.nextWalkHero.TextXAlignment = Enum.TextXAlignment.Right
local start = button(body, "START WALKER", accent)
start.Position, start.Size = UDim2.fromOffset(15, 120), UDim2.new(1, -112, 0, 45)
start.TextSize = 15
local homeBtn = button(body, "SET HOME", C.card2)
homeBtn.Position, homeBtn.Size = UDim2.new(1, -88, 0, 120), UDim2.fromOffset(73, 45)
local modeBar = framed(body, UDim2.fromOffset(15, 177), UDim2.new(1, -30, 0, 40), C.panel, 10)
local modeButtons = {}
for i, mode in ipairs({"Walk", "Pulse", "Hybrid"}) do
    local b = button(modeBar, string.upper(mode), C.card2)
    b.Position = UDim2.new((i - 1) / 3, 4, 0, 4)
    b.Size = UDim2.new(1 / 3, -8, 1, -8)
    b.TextSize = 11
    modeButtons[mode] = b
    connect(b.MouseButton1Click, function()
        if settings.mode == mode then return end
        settings.mode = mode
        haltMovement()
        nextPulseAt = os.clock() + settings.pingInterval
        nextWalkAt = running and mode ~= "Pulse" and os.clock() or nil
        setStatus(running and (mode == "Pulse" and "PULSE MODE - WALKING IS OFF" or "STARTING WALK") or "READY TO GO")
        saveSettings()
        inform("Mode changed to " .. mode)
        refreshControls()
    end)
end
local tabs = framed(body, UDim2.fromOffset(15, 229), UDim2.new(1, -30, 0, 40), C.panel, 10)
local pages, tabBtns = {}, {}
local activeTab = "Overview"
local tabNames = {"Overview", "Movement", "Navigate", "Activity", "Style"}
local viewport = el("Frame", {Position = UDim2.fromOffset(15, 281),
    Size = UDim2.new(1, -30, 0, 244), BackgroundTransparency = 1,
    ClipsDescendants = true}, body)
for i, name in ipairs(tabNames) do
    local b = button(tabs, string.upper(name), C.panel)
    b.Position = UDim2.new((i - 1) / 5, 2, 0, 4)
    b.Size = UDim2.new(1 / 5, -4, 1, -8)
    b.TextSize = 10
    tabBtns[name] = b
    local page = el("ScrollingFrame", {
        Name = name, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        BorderSizePixel = 0, ScrollBarThickness = 3,
        ScrollBarImageColor3 = accent, ScrollingDirection = Enum.ScrollingDirection.Y,
        AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.fromOffset(0, 0),
        Visible = name == activeTab,
    }, viewport)
    el("UIPadding", {PaddingTop = UDim.new(0, 1), PaddingBottom = UDim.new(0, 9),
        PaddingRight = UDim.new(0, 5)}, page)
    el("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, page)
    pages[name] = page
    connect(b.MouseButton1Click, function()
        activeTab = name
        for n, p in pairs(pages) do p.Visible = n == name end
        refreshControls()
    end)
end
local footer = framed(body, UDim2.new(0, 15, 1, -40), UDim2.new(1, -30, 0, 31), C.panel, 9)
local progressBase = el("Frame", {Position = UDim2.fromOffset(8, 6),
    Size = UDim2.new(1, -16, 0, 3), BackgroundColor3 = C.line,
    BorderSizePixel = 0}, footer)
corner(progressBase, 2)
local progressFill = el("Frame", {Size = UDim2.new(0, 0, 1, 0),
    BackgroundColor3 = accent, BorderSizePixel = 0}, progressBase)
corner(progressFill, 2)
local footerInfo = textLabel(footer, "L = HIDE   |   DRAG HEADER TO MOVE", 10, true, C.faint)
footerInfo.Position, footerInfo.Size = UDim2.fromOffset(10, 11), UDim2.new(1, -20, 0, 16)

-- Hide restores using a small always-visible pill, including on touch devices.
local launcher = button(gui, "CW   OPEN WALKER", C.card)
launcher.Position, launcher.Size = UDim2.new(0, 18, 1, -63), UDim2.fromOffset(153, 40)
launcher.Visible = false
outline(launcher, accent, 0)
local hidden, minimized = false, false
local function showWindow(show)
    hidden = not show
    panel.Visible = show
    launcher.Visible = not show
end
connect(launcher.MouseButton1Click, function() showWindow(true) end)
connect(minimize.MouseButton1Click, function()
    minimized = not minimized
    body.Visible = not minimized
    minimize.Text = minimized and "+" or "—"
    panel.Size = minimized and UDim2.fromOffset(472, 79) or UDim2.fromOffset(472, 648)
    applyScale()
end)
connect(close.MouseButton1Click, function() showWindow(false) end)
connect(start.MouseButton1Click, function() setRunning(not running) end)
connect(homeBtn.MouseButton1Click, function()
    if not isCharacterReady() or not groundAt(root.Position) then
        inform("Stand on safe ground before setting home"); return
    end
    home = root.Position
    persistHome()
    logEvent("MANUAL HOME SET")
    mustReturnHome = false
    haltMovement()
    if running and settings.mode ~= "Pulse" then nextWalkAt = os.clock() end
    updateWorld()
    inform("Saved home changed manually")
end)

-- UI PAGES --------------------------------------------------------------------
local function sectionHeading(parent, heading, desc)
    local f = el("Frame", {Size = UDim2.new(1, 0, 0, 45), BackgroundTransparency = 1}, parent)
    local t = textLabel(f, heading, 14, true)
    t.Position = UDim2.fromOffset(3, 0)
    local s = textLabel(f, desc, 10, false, C.soft)
    s.Position = UDim2.fromOffset(3, 22)
    return f
end
local function statCard(parent, name)
    local box = framed(parent, UDim2.new(), UDim2.new(), C.panel, 11)
    local val = textLabel(box, "0", 23, true, accent)
    val.Position, val.Size = UDim2.fromOffset(12, 11), UDim2.new(1, -24, 0, 31)
    local titleText = textLabel(box, string.upper(name), 10, true, C.soft)
    titleText.Position, titleText.Size = UDim2.fromOffset(13, 48), UDim2.new(1, -20, 0, 19)
    return box, val
end
sectionHeading(pages.Overview, "LIVE TELEMETRY", "A real-time look at your session")
local metricsFrame = el("Frame", {Size = UDim2.new(1, 0, 0, 174), BackgroundTransparency = 1}, pages.Overview)
local metricCards = {}
for i, item in ipairs({"Routes", "Arrivals", "Recoveries", "Pulses"}) do
    local card, value = statCard(metricsFrame, item)
    local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
    card.Position = UDim2.new(col / 2, col == 0 and 0 or 4, 0, row * 89)
    card.Size = UDim2.new(0.5, -4, 0, 82)
    metricCards[item] = value
end
local overviewInfo = framed(pages.Overview, UDim2.new(), UDim2.new(1, 0, 0, 125), C.panel, 11)
local distanceLabel = textLabel(overviewInfo, "Distance walked: 0 studs", 11, true)
distanceLabel.Position, distanceLabel.Size = UDim2.fromOffset(13, 10), UDim2.new(1, -22, 0, 21)
local homeLabel = textLabel(overviewInfo, "Home: waiting for character", 10, false, C.soft)
homeLabel.Position, homeLabel.Size = UDim2.fromOffset(13, 33), UDim2.new(1, -22, 0, 21)
local helpLabel = textLabel(overviewInfo, "WALK/HYBRID = MOVES  |  PULSE = NO WALKING", 10, false, C.soft)
helpLabel.Position, helpLabel.Size = UDim2.fromOffset(13, 59), UDim2.new(1, -22, 0, 22)
settings.movementBackendLabel = textLabel(overviewInfo, "Movement: initializing", 11, true, accent)
settings.movementBackendLabel.Position, settings.movementBackendLabel.Size = UDim2.fromOffset(13, 85), UDim2.new(1, -22, 0, 23)
sectionHeading(pages.Movement, "MOVEMENT ENGINE", "Bounded path routes with MoveTo movement")
sectionHeading(pages.Navigate, "SMART NAVIGATOR", "Saved home and interruptible path recovery")
sectionHeading(pages.Activity, "ACTIVITY ENGINE", "Input pulses and respawn behavior")
sectionHeading(pages.Style, "PERSONALIZE", "Colors, world markers and display")

local controlRefreshers = {}
local function registerRefresh(fn)
    table.insert(controlRefreshers, fn)
    fn()
end
local function changeSetting(key, value, impact)
    if defaults[key] == nil then return end
    if type(defaults[key]) == "boolean" and type(value) ~= "boolean" then return end
    if type(defaults[key]) == "number" and not finite(value) then return end
    settings[key] = value
    if settings.maxWalk < settings.minWalk then
        if key == "maxWalk" then settings.minWalk = settings.maxWalk
        else settings.maxWalk = settings.minWalk end
    end
    if impact == "move" then
        haltMovement()
        if running and settings.mode ~= "Pulse" then nextWalkAt = os.clock() end
    end
    if impact == "pulse" then nextPulseAt = os.clock() + settings.pingInterval end
    if impact == "world" or key == "radius" then updateWorld() end
    if key == "walkPause" and nextWalkAt then
        nextWalkAt = os.clock() + settings.walkPause
    end
    if impact == "scale" then applyScale() end
    saveSettings()
    refreshControls()
end
local function toggleRow(parent, labelText, desc, key, impact)
    local row = framed(parent, UDim2.new(), UDim2.new(1, 0, 0, 65), C.panel, 10)
    local t = textLabel(row, labelText, 12, true)
    t.Position, t.Size = UDim2.fromOffset(12, 7), UDim2.new(1, -96, 0, 25)
    local s = textLabel(row, desc, 10, false, C.soft)
    s.Position, s.Size = UDim2.fromOffset(12, 31), UDim2.new(1, -96, 0, 20)
    local switch = button(row, "", C.card2)
    switch.Position, switch.Size = UDim2.new(1, -72, 0, 17), UDim2.fromOffset(57, 30)
    local knob = el("Frame", {Position = UDim2.fromOffset(4, 4),
        Size = UDim2.fromOffset(22, 22), BackgroundColor3 = C.white,
        BorderSizePixel = 0}, switch)
    corner(knob, 11)
    registerRefresh(function()
        switch.BackgroundColor3 = settings[key] and accent or C.card2
        knob.Position = UDim2.fromOffset(settings[key] and 31 or 4, 4)
    end)
    connect(switch.MouseButton1Click, function()
        changeSetting(key, not settings[key], impact)
    end)
    return row
end
local function sliderRow(parent, labelText, desc, key, minValue, maxValue, step, impact)
    local row = framed(parent, UDim2.new(), UDim2.new(1, 0, 0, 91), C.panel, 10)
    local t = textLabel(row, labelText, 12, true)
    t.Position, t.Size = UDim2.fromOffset(12, 7), UDim2.new(1, -108, 0, 22)
    local sub = textLabel(row, desc, 10, false, C.soft)
    sub.Position, sub.Size = UDim2.fromOffset(12, 28), UDim2.new(1, -24, 0, 17)
    local exact = el("TextBox", {
        Position = UDim2.new(1, -75, 0, 8), Size = UDim2.fromOffset(61, 27),
        BackgroundColor3 = C.card2, BorderSizePixel = 0,
        TextColor3 = C.white, Font = Enum.Font.GothamBold,
        TextSize = 12, ClearTextOnFocus = false,
        Text = tostring(settings[key]),
    }, row)
    corner(exact, 7)
    outline(exact)
    local track = el("TextButton", {
        Position = UDim2.new(0, 13, 1, -24), Size = UDim2.new(1, -26, 0, 8),
        BackgroundColor3 = C.line, BorderSizePixel = 0,
        Text = "", AutoButtonColor = false,
    }, row)
    corner(track, 5)
    local filled = el("Frame", {Size = UDim2.new(0, 0, 1, 0),
        BorderSizePixel = 0, BackgroundColor3 = accent}, track)
    corner(filled, 5)
    local dot = el("Frame", {Size = UDim2.fromOffset(16, 16),
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = C.white, BorderSizePixel = 0}, track)
    corner(dot, 9)
    local function redraw()
        local ratio = (settings[key] - minValue) / (maxValue - minValue)
        filled.Size = UDim2.new(ratio, 0, 1, 0)
        filled.BackgroundColor3 = accent
        dot.Position = UDim2.new(ratio, 0, 0.5, 0)
        if not exact:IsFocused() then exact.Text = tostring(settings[key]) end
    end
    registerRefresh(redraw)
    local dragging = false
    local touchObject = nil
    local function fromX(x)
        local fraction = math.clamp((x - track.AbsolutePosition.X) /
            math.max(1, track.AbsoluteSize.X), 0, 1)
        local value = bounded(minValue + (maxValue - minValue) * fraction,
            settings[key], minValue, maxValue, step)
        if settings[key] ~= value then changeSetting(key, value, impact) end
    end
    connect(track.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            touchObject = input.UserInputType == Enum.UserInputType.Touch and input or nil
            fromX(input.Position.X)
        end
    end)
    connect(UIS.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or (input.UserInputType == Enum.UserInputType.Touch and input == touchObject)) then
            fromX(input.Position.X)
        end
    end)
    connect(UIS.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or (input.UserInputType == Enum.UserInputType.Touch and input == touchObject) then
            dragging, touchObject = false, nil
        end
    end)
    connect(exact.FocusLost, function()
        local value = bounded(exact.Text, settings[key], minValue, maxValue, step)
        changeSetting(key, value, impact)
        exact.Text = tostring(settings[key])
    end)
    return row
end

sliderRow(pages.Movement, "HOME RADIUS", "Live boundary updates as you adjust it", "radius", 10, 100, 1, "move")
sliderRow(pages.Movement, "PAUSE BETWEEN WALKS", "Wait 3-30 seconds after each completed walk", "walkPause", 3, 30, 1, "pause")
toggleRow(pages.Movement, "RANDOM WALK TIME", "Randomize each route time budget", "randomWalk", "move")
sliderRow(pages.Movement, "MIN WALK TIME", "Shortest route budget (seconds)", "minWalk", 2, 20, 1, "move")
sliderRow(pages.Movement, "MAX WALK TIME", "Longest route budget (seconds)", "maxWalk", 2, 30, 1, "move")
sliderRow(pages.Movement, "FIXED WALK TIME", "Route budget with random OFF", "fixedWalk", 2, 30, 1, "move")
toggleRow(pages.Movement, "AUTOMATIC RECOVERY", "Retry after a blocked or failed walk", "autoRecover", "move")
toggleRow(pages.Movement, "ALLOW JUMP", "Jump if stuck or when returning home", "allowJump", "move")
-- Floor safety is mandatory; old safeGround preferences cannot disable it.
settings.safeGround = true
settings.motorSwitch = button(pages.Movement, "WALK NOW (SAFE PATH)", C.card2)
settings.motorSwitch.Size = UDim2.new(1, 0, 0, 38)
connect(settings.motorSwitch.MouseButton1Click, function()
    if settings.mode == "Pulse" then settings.mode = "Walk"; saveSettings() end
    if running then
        haltMovement()
        nextWalkAt = os.clock()
    else
        setRunning(true)
    end
    inform("Safe walking route requested")
    refreshControls()
end)

do
-- Navigation dashboard. Shows why a route is working, failing or paused.
local navDetail = framed(pages.Navigate, UDim2.new(), UDim2.new(1, 0, 0, 158), C.panel, 11)
local navTitle = textLabel(navDetail, "NAVIGATION LIVE", 13, true, accent)
navTitle.Position, navTitle.Size = UDim2.fromOffset(13, 9), UDim2.new(1, -24, 0, 24)
local navPhase = textLabel(navDetail, "PHASE: IDLE", 11, true, C.white)
navPhase.Position, navPhase.Size = UDim2.fromOffset(13, 41), UDim2.new(1, -24, 0, 19)
local navDistance = textLabel(navDetail, "HOME DISTANCE: --", 11, false, C.soft)
navDistance.Position, navDistance.Size = UDim2.fromOffset(13, 63), UDim2.new(1, -24, 0, 19)
local navWaypoint = textLabel(navDetail, "WAYPOINT: --", 11, false, C.soft)
navWaypoint.Position, navWaypoint.Size = UDim2.fromOffset(13, 85), UDim2.new(1, -24, 0, 19)
local navOutcome = textLabel(navDetail, "LAST ROUTE: --", 11, false, C.soft)
navOutcome.Position, navOutcome.Size = UDim2.fromOffset(13, 107), UDim2.new(1, -24, 0, 40)
navOutcome.TextWrapped = true
local navTools = framed(pages.Navigate, UDim2.new(), UDim2.new(1, 0, 0, 96), C.panel, 11)
local homeNow = button(navTools, "RETURN HOME NOW", C.card2)
homeNow.Position, homeNow.Size = UDim2.fromOffset(12, 10), UDim2.new(0.50, -18, 0, 33)
local walkNow = button(navTools, "WALK NOW", C.card2)
walkNow.Position, walkNow.Size = UDim2.new(0.50, 6, 0, 10), UDim2.new(0.50, -18, 0, 33)
local navHint = textLabel(navTools, "No teleporting; navigation uses Humanoid:MoveTo.", 10, false, C.soft)
navHint.Position, navHint.Size = UDim2.fromOffset(12, 54), UDim2.new(1, -24, 0, 33)
navHint.TextWrapped = true
connect(homeNow.MouseButton1Click, function()
    if not home then inform("Set home first"); return end
    mustReturnHome = true
    if settings.mode == "Pulse" then settings.mode = "Walk"; saveSettings() end
    if not running then setRunning(true) end
    haltMovement()
    nextWalkAt = os.clock()
    logEvent("MANUAL RETURN HOME REQUESTED")
    refreshControls()
end)
connect(walkNow.MouseButton1Click, function()
    if settings.mode == "Pulse" then settings.mode = "Walk"; saveSettings() end
    if not running then setRunning(true) else haltMovement(); nextWalkAt = os.clock() end
    logEvent("MANUAL WALK REQUESTED")
    refreshControls()
end)
sliderRow(pages.Navigate, "RETURN RETRY PAUSE", "3-20 seconds between failed home routes", "returnRetry", 3, 20, 1, "pause")
toggleRow(pages.Navigate, "SHOW ROUTE TRAIL", "Draw a dotted guide to the next target", "showTrail", "world")
-- Compact live radar: positions relative to the locked home and radius.
local radarPanel = framed(pages.Navigate, UDim2.new(), UDim2.new(1, 0, 0, 141), C.panel, 11)
local radarDisk = framed(radarPanel, UDim2.fromOffset(15, 13), UDim2.fromOffset(112, 112), C.card, 56)
local radarEdge = outline(radarDisk, accent, 0.15)
local radarLine1 = el("Frame", {Position=UDim2.fromOffset(54,6), Size=UDim2.fromOffset(1,100),
    BackgroundColor3=C.line, BackgroundTransparency=0.6, BorderSizePixel=0}, radarDisk)
local radarLine2 = el("Frame", {Position=UDim2.fromOffset(6,55), Size=UDim2.fromOffset(100,1),
    BackgroundColor3=C.line, BackgroundTransparency=0.6, BorderSizePixel=0}, radarDisk)
local function radarDot(text, color, z)
    local dot = el("TextLabel", {Size=UDim2.fromOffset(19,19), Position=UDim2.fromOffset(56,56),
        AnchorPoint=Vector2.new(0.5,0.5), BackgroundColor3=color,
        Text=text, Font=Enum.Font.GothamBold, TextColor3=C.bg, TextSize=10,
        BorderSizePixel=0, ZIndex=z or 5}, radarDisk)
    corner(dot, 10)
    return dot
end
local radarHome = radarDot("H", C.good, 5)
local radarGoal = radarDot("T", Color3.fromRGB(255,194,109), 6)
local radarPlayer = radarDot("P", C.white, 7)
local radarTitle = textLabel(radarPanel, "HOME RADAR", 13, true, accent)
radarTitle.Position, radarTitle.Size = UDim2.fromOffset(145, 18), UDim2.new(1,-155,0,24)
local radarReadout = textLabel(radarPanel, "P = PLAYER    H = HOME", 10, false, C.soft)
radarReadout.Position, radarReadout.Size = UDim2.fromOffset(145, 47), UDim2.new(1,-155,0,55)
radarReadout.TextWrapped = true
radarReadout.TextYAlignment = Enum.TextYAlignment.Top
local radarLegend = textLabel(radarPanel, "T = TARGET", 10, false, C.soft)
radarLegend.Position, radarLegend.Size = UDim2.fromOffset(145,105), UDim2.new(1,-155,0,20)
local navLogBox = framed(pages.Navigate, UDim2.new(), UDim2.new(1, 0, 0, 184), C.panel, 11)
local navLogTitle = textLabel(navLogBox, "RECENT ACTIVITY", 12, true, accent)
navLogTitle.Position, navLogTitle.Size = UDim2.fromOffset(12, 8), UDim2.new(1, -24, 0, 23)
local navLog = textLabel(navLogBox, "No navigation events yet", 10, false, C.soft)
navLog.Position, navLog.Size = UDim2.fromOffset(12, 34), UDim2.new(1, -24, 0, 145)
navLog.TextWrapped = true
navLog.TextYAlignment = Enum.TextYAlignment.Top

settings.navUI = {navTitle=navTitle, navPhase=navPhase, navDistance=navDistance,
  navWaypoint=navWaypoint, navOutcome=navOutcome, navLog=navLog,
  navLogTitle=navLogTitle, navHint=navHint, radarPanel=radarPanel,
  radarEdge=radarEdge, radarHome=radarHome, radarGoal=radarGoal,
  radarPlayer=radarPlayer, radarTitle=radarTitle, radarReadout=radarReadout}
end
sliderRow(pages.Activity, "PULSE INTERVAL", "Virtual input every 30-120 seconds", "pingInterval", 30, 120, 1, "pulse")
toggleRow(pages.Activity, "RESPOND TO IDLE EVENT", "Attempt a pulse if Roblox signals idle", "pingOnIdle", nil)
toggleRow(pages.Activity, "RESUME AFTER RESPAWN", "Continue the selected mode after death", "resumeAfterRespawn", nil)
local homePolicy = framed(pages.Activity, UDim2.new(), UDim2.new(1, 0, 0, 65), C.panel, 10)
local policyTitle = textLabel(homePolicy, "HOME LOCKED AFTER DEATH", 12, true, accent)
policyTitle.Position, policyTitle.Size = UDim2.fromOffset(12, 7), UDim2.new(1, -24, 0, 25)
local policyInfo = textLabel(homePolicy,
    "Death/teleports keep home. Only SET HOME changes it.", 10, false, C.soft)
policyInfo.Position, policyInfo.Size = UDim2.fromOffset(12, 31), UDim2.new(1, -24, 0, 25)
policyInfo.TextWrapped = true
local inputCheck = framed(pages.Activity, UDim2.new(), UDim2.new(1, 0, 0, 77), C.panel, 10)
local inputLabel = textLabel(inputCheck, "INPUT BACKEND: NOT TESTED", 11, true, accent)
inputLabel.Position, inputLabel.Size = UDim2.fromOffset(11, 6), UDim2.new(1, -24, 0, 19)
local inputStatus = textLabel(inputCheck, "Tests API access only; server idle reset is not guaranteed", 10, false, C.soft)
inputStatus.Position, inputStatus.Size = UDim2.fromOffset(11, 26), UDim2.new(1, -24, 0, 17)
local testInput = button(inputCheck, "TEST INPUT", C.card2)
testInput.Position, testInput.Size = UDim2.fromOffset(11, 47), UDim2.fromOffset(130, 23)
connect(testInput.MouseButton1Click, function()
    task.spawn(pulse, true)
end)
local diagnosticBox = framed(pages.Activity, UDim2.new(),
    UDim2.new(1, 0, 0, 91), C.panel, 10)
local diagnosticHeading = textLabel(diagnosticBox, "DIAGNOSTICS / LAST ERROR", 11, true, accent)
diagnosticHeading.Position, diagnosticHeading.Size = UDim2.fromOffset(11, 8), UDim2.new(1, -22, 0, 20)
local diagnosticText = textLabel(diagnosticBox, "No internal errors recorded", 10, false, C.soft)
diagnosticText.Position, diagnosticText.Size = UDim2.fromOffset(11, 30), UDim2.new(1, -22, 0, 45)
diagnosticText.TextWrapped = true
diagnosticText.TextYAlignment = Enum.TextYAlignment.Top
local unloadButton = button(pages.Style, "UNLOAD WALKER", C.card2)
unloadButton.Size = UDim2.new(1, 0, 0, 38)
connect(unloadButton.MouseButton1Click, unload)
local resetStats = button(diagnosticBox, "RESET STATS", C.card2)
resetStats.Position, resetStats.Size = UDim2.new(1, -115, 0, 6), UDim2.fromOffset(104, 24)
connect(resetStats.MouseButton1Click, function()
    for k in pairs(stats) do stats[k] = 0 end
    inform("Statistics reset")
end)
local noteBox = framed(pages.Activity, UDim2.new(), UDim2.new(1, 0, 0, 60), C.panel, 10)
local noteT = textLabel(noteBox, "INPUT LIMITATIONS", 11, true, accent)
noteT.Position, noteT.Size = UDim2.fromOffset(11, 6), UDim2.new(1, -22, 0, 22)
local noteB = textLabel(noteBox, "Executor support varies; pulses cannot guarantee", 10, false, C.soft)
noteB.Position, noteB.Size = UDim2.fromOffset(11, 28), UDim2.new(1, -18, 0, 19)
local noteC = textLabel(noteBox, "avoidance of Roblox or game-specific idle checks.", 10, false, C.soft)
noteC.Position, noteC.Size = UDim2.fromOffset(11, 43), UDim2.new(1, -18, 0, 16)

local swatches = framed(pages.Style, UDim2.new(), UDim2.new(1, 0, 0, 77), C.panel, 10)
local swatchLabel = textLabel(swatches, "ACCENT COLOR", 11, true)
swatchLabel.Position, swatchLabel.Size = UDim2.fromOffset(12, 6), UDim2.new(1, -20, 0, 20)
local swatchBtns = {}
for i, name in ipairs({"Cyan", "Violet", "Lime", "Rose", "Amber"}) do
    local b = button(swatches, "", palettes[name])
    b.Position = UDim2.new((i - 1) / 5, 9, 0, 33)
    b.Size = UDim2.new(1 / 5, -18, 0, 31)
    local edge = outline(b, C.white, 1)
    swatchBtns[name] = edge
    connect(b.MouseButton1Click, function()
        settings.accent = name
        accent = palettes[name]
        saveSettings()
        updateWorld()
        refreshControls()
        inform("Theme: " .. name)
    end)
end
toggleRow(pages.Style, "WORLD RADIUS RING", "Display the boundary and your home", "showWorldVisuals", "world")
toggleRow(pages.Style, "DESTINATION MARKER", "Show the current navigation goal", "showTarget", "world")
sliderRow(pages.Style, "INTERFACE SCALE", "Resize the dashboard for your screen", "uiScale", 0.75, 1.15, 0.05, "scale")
local unloadButton = button(pages.Style, "STOP & UNLOAD SCRIPT", Color3.fromRGB(80, 35, 54))
unloadButton.Size = UDim2.new(1, 0, 0, 36)
connect(unloadButton.MouseButton1Click, unload)
local helpBox = framed(pages.Style, UDim2.new(), UDim2.new(1, 0, 0, 80), C.panel, 10)
local h1 = textLabel(helpBox, "HOTKEY  L: HIDE / SHOW  |  X: HIDE", 11, true)
h1.Position, h1.Size = UDim2.fromOffset(12, 7), UDim2.new(1, -22, 0, 24)
local h2 = textLabel(helpBox, "Drag the title bar to reposition.", 10, false, C.soft)
h2.Position, h2.Size = UDim2.fromOffset(12, 31), UDim2.new(1, -22, 0, 19)
local h3 = textLabel(helpBox, "Settings save when your executor supports files.", 10, false, C.soft)
h3.Position, h3.Size = UDim2.fromOffset(12, 49), UDim2.new(1, -22, 0, 19)

refreshControls = function()
    if not alive or not panel then return end
    accent = palettes[settings.accent]
    topAccent.BackgroundColor3 = accent
    topGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, accent),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(98, 103, 243))})
    brandText.TextColor3 = accent
    version.TextColor3 = accent
    noteT.TextColor3 = accent
    diagnosticHeading.TextColor3 = accent
    start.Text = running and "STOP WALKER" or "START WALKER"
    start.BackgroundColor3 = running and C.bad or accent
    progressFill.BackgroundColor3 = accent
    settings.motorSwitch.Text = "WALK NOW (SAFE PATH)"
    settings.navUI.navHint.TextColor3 = palettes[settings.accent]
    for name, b in pairs(modeButtons) do
        local selected = name == settings.mode
        b.BackgroundColor3 = selected and accent or C.card2
        b.TextColor3 = selected and C.bg or C.white
    end
    for name, b in pairs(tabBtns) do
        b.BackgroundColor3 = activeTab == name and C.card2 or C.panel
        b.TextColor3 = activeTab == name and accent or C.soft
    end
    for name, edge in pairs(swatchBtns) do
        edge.Transparency = name == settings.accent and 0 or 1
    end
    for _, fn in ipairs(controlRefreshers) do fn() end
    for _, p in pairs(pages) do p.ScrollBarImageColor3 = accent end
end
refreshControls()

-- WINDOW DRAGGING & RESPONSIVE SCALING ----------------------------------------
local dragging, dragStart, panelStart = false, nil, nil
connect(header.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        -- Ignore top-right window controls.
        if input.Position.X - header.AbsolutePosition.X > header.AbsoluteSize.X - 94 then return end
        dragging = true
        dragStart, panelStart = input.Position, panel.AbsolutePosition
    end
end)
connect(UIS.InputChanged, function(input)
    if not dragging or not dragStart or not panelStart then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then return end
    local delta = input.Position - dragStart
    local proposedX = panelStart.X + delta.X
    local proposedY = panelStart.Y + delta.Y
    local cam = workspace.CurrentCamera
    local size = cam and cam.ViewportSize or Vector2.new(1920, 1080)
    local w, h = 472 * uiScale.Scale, (minimized and 79 or 648) * uiScale.Scale
    local x = math.clamp(proposedX, 0, math.max(0, size.X - w))
    local y = math.clamp(proposedY, 0, math.max(0, size.Y - h))
    panel.Position = UDim2.fromOffset(x, y)
end)
connect(UIS.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)
connect(UIS.InputBegan, function(input, handled)
    if handled or UIS:GetFocusedTextBox() then return end
    if input.KeyCode == Enum.KeyCode.L then showWindow(hidden) end
    if running and (input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.A
        or input.KeyCode == Enum.KeyCode.S or input.KeyCode == Enum.KeyCode.D
        or input.KeyCode == Enum.KeyCode.Up or input.KeyCode == Enum.KeyCode.Down
        or input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.Right) then
        setRunning(false)
        inform("Paused for manual movement")
    end
end)
applyScale = function()
    if not panel or not alive then return end
    local camera = workspace.CurrentCamera
    local viewportSize = camera and camera.ViewportSize or Vector2.new(1920, 1080)
    local maxW = (viewportSize.X - 16) / 472
    local maxH = (viewportSize.Y - 20) / 648
    uiScale.Scale = math.max(0.1, math.min(settings.uiScale, maxW, maxH))
    local pos = panel.AbsolutePosition
    panel.Position = UDim2.fromOffset(
        math.clamp(pos.X, 0, math.max(0, viewportSize.X - 472 * uiScale.Scale)),
        math.clamp(pos.Y, 0, math.max(0, viewportSize.Y - (minimized and 79 or 648) * uiScale.Scale)))
end
applyScale()

-- SINGLE LIGHTWEIGHT DASHBOARD UPDATE ----------------------------------------
task.spawn(function()
    local previousViewport = Vector2.new(0, 0)
    while alive do
        if gui and gui.Parent then
            local camera = workspace.CurrentCamera
            if camera and camera.ViewportSize ~= previousViewport then
                previousViewport = camera.ViewportSize
                applyScale()
            end
            local seconds = pastSeconds + (sessionSince and os.clock() - sessionSince or 0)
            heroSession.Text = "SESSION  " .. formatTime(seconds)
            indicator.BackgroundColor3 = running and C.good or C.faint
            heroStatus.Text = running and "SYSTEM ACTIVE" or "SYSTEM STANDBY"
            heroStatus.TextColor3 = running and C.good or C.white
            heroDetail.Text = status
            settings.movementBackendLabel.Text = "ENGINE: " .. motor.backend ..
                (root and root.Parent and string.format("  ·  %.0f studs/s", root.AssemblyLinearVelocity.Magnitude) or "")
            settings.movementBackendLabel.TextColor3 = palettes[settings.accent]
            if not running then
                settings.nextWalkHero.Text = "NEXT WALK: PAUSED"
            elseif settings.mode == "Pulse" then
                settings.nextWalkHero.Text = "WALKING OFF (PULSE)"
            elseif mustReturnHome and nextWalkAt then
                settings.nextWalkHero.Text = string.format("RETURN IN %ds",
                    math.max(0, math.ceil(nextWalkAt - os.clock())))
            elseif mustReturnHome then
                settings.nextWalkHero.Text = "PATHFINDING HOME"
            elseif nextWalkAt then
                settings.nextWalkHero.Text = string.format("NEXT WALK IN %ds",
                    math.max(0, math.ceil(nextWalkAt - os.clock())))
            elseif walkStart then
                settings.nextWalkHero.Text = "WALKING NOW"
            else
                settings.nextWalkHero.Text = "STARTING WALK..."
            end
            settings.nextWalkHero.TextColor3 = palettes[settings.accent]
            metricCards.Routes.Text = tostring(stats.routes)
            metricCards.Arrivals.Text = tostring(stats.arrivals)
            metricCards.Recoveries.Text = tostring(stats.recoveries)
            metricCards.Pulses.Text = tostring(stats.pulses)
            inputLabel.Text = "INPUT BACKEND: " .. pulseBackend
            inputLabel.TextColor3 = pulseBackend == "UNAVAILABLE" and C.bad or palettes[settings.accent]
            inputStatus.Text = lastPulseError
            diagnosticText.Text = (lastFailure == "None" and "No internal errors recorded" or lastFailure)
                .. "\nSETTINGS: " .. storageStatus
            settings.navUI.navTitle.TextColor3 = palettes[settings.accent]
            settings.navUI.navLogTitle.TextColor3 = palettes[settings.accent]
            settings.navUI.navPhase.Text = "PHASE: " .. routePhase
            settings.navUI.navDistance.Text = home and root and root.Parent
                and string.format("HOME DISTANCE: %.0f studs", horizontalDistance(root.Position, home))
                or "HOME DISTANCE: --"
            settings.navUI.navWaypoint.Text = totalWaypoints > 0 and string.format(
                "WAYPOINT: %d / %d   |   PATH PLANS: %d", currentWaypoint,
                totalWaypoints, stats.pathPlans) or string.format("PATH PLANS: %d", stats.pathPlans)
            settings.navUI.navOutcome.Text = string.format("LAST ROUTE: %s  (%.1fs)", lastRouteOutcome, lastRouteDuration)
            settings.navUI.radarEdge.Color = palettes[settings.accent]
            settings.navUI.radarTitle.TextColor3 = palettes[settings.accent]
            if home and root and root.Parent then
                local p = root.Position - home
                local divisor = math.max(1, settings.radius)
                local px = math.clamp(p.X / divisor, -1, 1)
                local pz = math.clamp(p.Z / divisor, -1, 1)
                settings.navUI.radarPlayer.Position = UDim2.fromOffset(56 + 48*px, 56 + 48*pz)
                settings.navUI.radarGoal.Visible = target ~= nil
                if target then
                    local t = target - home
                    local tx = math.clamp(t.X / divisor, -1, 1)
                    local tz = math.clamp(t.Z / divisor, -1, 1)
                    settings.navUI.radarGoal.Position = UDim2.fromOffset(56 + 48*tx,56 + 48*tz)
                end
                settings.navUI.radarReadout.Text = string.format(
                    "HOME RADIUS: %d studs\nPLAYER: %.0f studs away",
                    settings.radius, horizontalDistance(root.Position, home))
            else
                settings.navUI.radarGoal.Visible = false
                settings.navUI.radarReadout.Text = "Waiting for character / home"
            end
            settings.navUI.navLog.Text = #activityLog == 0 and "No navigation events yet" or
                table.concat(activityLog, "\n", 1, math.min(#activityLog, 7))
            for _, v in pairs(metricCards) do v.TextColor3 = palettes[settings.accent] end
            distanceLabel.Text = string.format("Distance walked: %.0f studs", stats.distance)
            if home then
                homeLabel.Text = string.format("SAVED HOME: %.0f, %.0f, %.0f   |   Radius: %d",
                    home.X, home.Y, home.Z, settings.radius)
            else
                homeLabel.Text = "Home: waiting for character"
            end
            if running and nextWalkAt and settings.mode ~= "Pulse" then
                footerInfo.Text = string.format("%s IN %ds   |   L = HIDE",
                    mustReturnHome and "RETURN HOME" or "NEXT WALK",
                    math.max(0, math.ceil(nextWalkAt - os.clock())))
            elseif noteUntil > os.clock() then
                footerInfo.Text = note
            elseif running and settings.mode ~= "Walk" then
                footerInfo.Text = string.format("NEXT PULSE IN %ds   |   L = HIDE",
                    math.max(0, math.ceil(nextPulseAt - os.clock())))
            else
                footerInfo.Text = "L = HIDE   |   DRAG HEADER TO MOVE"
            end
            local fraction = 0
            if running and nextWalkAt then
                fraction = math.clamp(1 - (nextWalkAt - os.clock()) /
                    math.max(1, settings.walkPause), 0, 1)
            elseif running and settings.mode ~= "Pulse" and walkStart and walkEnd then
                fraction = math.clamp((os.clock() - walkStart) /
                    math.max(0.1, walkEnd - walkStart), 0, 1)
            elseif running and settings.mode ~= "Walk" then
                fraction = math.clamp(1 - (nextPulseAt - os.clock()) /
                    settings.pingInterval, 0, 1)
            end
            progressFill.Size = UDim2.new(fraction, 0, 1, 0)
            if target then
                targetDot.Transparency = settings.showTarget and 0.15 or 1
                targetDot.Position = target
            else
                targetDot.Transparency = 1
            end
        end
        task.wait(0.22)
    end
end)

print("[CW NEON UNIVERSAL V4.1] Nav engine loaded | L = show/hide")

end -- buildInterface
local built, buildError = xpcall(buildInterface, function(e) return tostring(e) end)
if not built then unload(); error("Walker UI: " .. buildError) end
