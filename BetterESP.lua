-- Better ESP 4.4 | Standalone client / executor edition
-- P: menu. Use the on-screen button on touch devices. Unload stops everything.
-- Optional gethui/getgenv support; no remote loader or external dependencies.
-- Only replicated/streamed instances are visible to this client.

local Config = {
    UpdateInterval = 0.2,
    TeamCacheSeconds = 1.5,
    MaxDistance = 2000, -- studs; math.huge removes the distance filter
    MaxVisible = 128, -- tracking is unlimited; rendering is bounded
    ShowNPCs = true,
    ShowPlayers = true,
    ShowHealth = false,
    ShowDistance = true,
    ShowNames = true,
    LabelHeight = 1, -- clearance above the head/model top, in studs
    LabelWidth = 140,
    NameTextSize = 10,
    ShowUsernames = false,
    FilledChams = true,
    FillTransparency = 0.65,
    ShowDead = false,
    TeamMode = "Off", -- Off / Colors / Enemies only
    ShowTeamSource = false,
    Occluded = false, -- true respects walls
    PlayerColor = Color3.fromRGB(255, 170, 70),
    NPCColor = Color3.fromRGB(255, 90, 110),
    AllyColor = Color3.fromRGB(80, 220, 160),
    EnemyColor = Color3.fromRGB(255, 100, 100),
    NPCTags = {"NPC", "Enemy", "Enemies", "Monster", "Mob", "Bot", "Creature"},
    -- In your own game, tagging non-Humanoid NPC models is the most reliable option.
    DetectAnimationControllers = true, -- can include animated props; toggle in menu
    MetadataDepth = 2,
    MetadataNodeLimit = 64,
    AncestorDepth = 4,
    -- Optional game-specific adapters. Return nil to use automatic detection.
    -- IsNPC(model) -> boolean?  (false explicitly excludes a model)
    IsNPC = nil,
    -- ResolveTeam(playerOrNil, modelOrNil) -> {key="faction", value="red",
    --     color=Color3.fromRGB(255,0,0), source="custom"}?
    -- Use the SAME key and comparable value for local player and targets.
    ResolveTeam = nil,
}

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Input = game:GetService("UserInputService")
local Tags = game:GetService("CollectionService")
local LocalPlayer = Players.LocalPlayer
local deadline = os.clock() + 15
while not LocalPlayer and os.clock() < deadline do
    task.wait(0.1)
    LocalPlayer = Players.LocalPlayer
end
assert(LocalPlayer, "ESP requires a running Roblox client")
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 15)
assert(PlayerGui, "PlayerGui did not become available; retry after joining")

-- Optional APIs are guarded. Standard client APIs are sufficient as fallback.
local environment = _G
if type(getgenv) == "function" then
    local ok, value = pcall(getgenv)
    if ok and type(value) == "table" then environment = value end
end
local registryKey = "__UniversalESP4_Runtime"
local oldRuntime = environment[registryKey]
if type(oldRuntime) == "table" and type(oldRuntime.Stop) == "function" then
    pcall(oldRuntime.Stop)
end
local runtime
local rootGui = Instance.new("ScreenGui")
rootGui.ResetOnSpawn = false
rootGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
rootGui.DisplayOrder = 100
local guiParent = PlayerGui
if type(gethui) == "function" then
    local ok, candidate = pcall(gethui)
    if ok and typeof(candidate) == "Instance" then
        local parented = pcall(function() rootGui.Parent = candidate end)
        if parented and rootGui.Parent == candidate then guiParent = candidate end
    end
end
if rootGui.Parent ~= guiParent then rootGui.Parent = guiParent end

-- Clean up a prior copy even if it used a different UI parent.
local function stopPrevious(parent)
    local previous = parent:FindFirstChild("UniversalESP4")
    if previous and previous ~= rootGui then
        local stop = previous:FindFirstChild("Unload")
        if stop and stop:IsA("BindableEvent") then pcall(function() stop:Fire() end) end
        previous:Destroy()
    end
end
stopPrevious(PlayerGui)
if guiParent ~= PlayerGui then stopPrevious(guiParent) end
rootGui.Name = "UniversalESP4"

local alive, enabled, elapsed = true, true, 0
local connections, playerConnections, characters = {}, {}, {}
local retiredCharacters = setmetatable({}, {__mode = "k"})
local entities, dirty = {}, {}
local entitySerial = 0
local controllerHints = {}
local flushScheduled = false
local teamMemo = setmetatable({}, {__mode = "k"})
local unloadEvent = Instance.new("BindableEvent")
unloadEvent.Name = "Unload"
unloadEvent.Parent = rootGui
local visuals = Instance.new("Folder")
visuals.Name = "BetterESP_Visuals"
visuals.Parent = workspace

local function connect(signal, callback, list)
    local c = signal:Connect(callback)
    table.insert(list or connections, c)
    return c
end
local function disconnect(list)
    for _, c in ipairs(list) do c:Disconnect() end
    table.clear(list)
end
local function dropVisual(d)
    if d.highlight then d.highlight:Destroy(); d.highlight = nil end
    if d.tag then d.tag:Destroy(); d.tag = nil; d.label = nil end
    d.text, d.color, d.depth = nil, nil, nil
    d.fill, d.labelAnchor, d.labelLift, d.namesVisible = nil, nil, nil, nil
end
local function remove(model)
    local d = entities[model]
    if d then dropVisual(d); entities[model] = nil end
    teamMemo[model] = nil
end
local function normalize(s)
    return string.lower(tostring(s)):gsub("[%s_%-]", "")
end

-- Only explicit affiliation fields qualify. Generic "Color", skin colors,
-- display names, and arbitrary folder names are deliberately not team evidence.
local fieldOrder = {
    "team", "teamid", "teamname", "faction", "factionid", "factionname",
    "allegiance", "squad", "squadid", "squadname", "coalition",
    "organization", "organizationid", "clan", "clanid",
    "owneruserid", "ownerid", "owner", "teamcolor", "factioncolor",
}
local fieldRank, fieldGroup = {}, {}
for i, field in ipairs(fieldOrder) do
    fieldRank[field] = i
    local group = field:gsub("userid$", ""):gsub("id$", ""):gsub("name$", "")
    -- IDs and names cannot safely be compared without a game's mapping table.
    if group ~= "owner" and field:match("id$") then group = group .. "id" end
    fieldGroup[field] = group
end
local function token(value)
    local t = typeof(value)
    if t == "string" then
        local s = normalize(value)
        if s == "" or s == "none" or s == "neutral" or s == "nil" then return nil end
        return s
    elseif t == "number" then
        return tostring(value)
    elseif t == "BrickColor" then
        return tostring(value.Number)
    elseif t == "Color3" then
        return string.format("%d,%d,%d", math.round(value.R*255), math.round(value.G*255), math.round(value.B*255))
    elseif t == "Instance" then
        if value:IsA("Player") then return tostring(value.UserId) end
        if value:IsA("Team") then return normalize(value.Name) end
        return "instance:" .. value:GetFullName()
    end
    return nil
end
local function asColor(value)
    if typeof(value) == "Color3" then return value end
    if typeof(value) == "BrickColor" then return value.Color end
    if typeof(value) == "Instance" and value:IsA("Team") then return value.TeamColor.Color end
    return nil
end

local function readMetadata(container, shallow)
    local best, bestRank
    local nodes = {{container, 0}}
    local index, examined = 1, 0
    local function consider(name, value, source)
        local field = normalize(name)
        local rank = fieldRank[field]
        local v = rank and token(value)
        if v and (not bestRank or rank < bestRank) then
            bestRank = rank
            best = {key=fieldGroup[field], value=v, color=asColor(value), source=source .. "." .. name}
        end
    end
    while index <= #nodes and examined < Config.MetadataNodeLimit do
        local item = nodes[index]
        index = index + 1
        examined = examined + 1
        local node, depth = item[1], item[2]
        -- Do not inspect other characters or large model trees as metadata.
        for name, value in pairs(node:GetAttributes()) do consider(name, value, node.Name) end
        if node:IsA("ValueBase") then consider(node.Name, node.Value, container.Name) end
        if depth < (shallow and 1 or Config.MetadataDepth) then
            for _, child in ipairs(node:GetChildren()) do
                if #nodes >= Config.MetadataNodeLimit then break end
                if child:IsA("ValueBase") or (not shallow and (child:IsA("Folder") or child:IsA("Configuration"))) then
                    table.insert(nodes, {child, depth + 1})
                end
            end
        end
    end
    return best
end

local function resolveTeam(player, model, now)
    local subject = player or model
    if not subject then return nil end
    local memo = teamMemo[subject]
    if memo and now < memo.expires and memo.model == model then return memo.info end
    local info
    if Config.ResolveTeam then
        local ok, result = pcall(Config.ResolveTeam, player, model)
        if ok and type(result) == "table" and result.key and result.value ~= nil then
            local v = token(result.value)
            if v then
                info = {key=normalize(result.key), value=v, color=asColor(result.color), source=result.source or "custom"}
            end
        end
    end
    -- Explicit custom metadata takes precedence over built-in Roblox Teams.
    info = info or (player and readMetadata(player)) or (model and readMetadata(model))
    if not info and model then
        local parent = model.Parent
        for _ = 1, Config.AncestorDepth do
            if not parent or parent == workspace or parent == game then break end
            info = readMetadata(parent, true)
            -- Explicit named affiliation containers, e.g. Workspace.Factions.Red.NPC.
            -- Arbitrary folders such as "Enemies" are not proof of an affiliation.
            if not info and parent.Parent then
                local groups = {teams="team", factions="faction", squads="squad", clans="clan", coalitions="coalition"}
                local group = groups[normalize(parent.Parent.Name)]
                if group then
                    info = {key=group, value=normalize(parent.Name), source=parent.Parent.Name .. "." .. parent.Name}
                end
            end
            if info then break end
            parent = parent.Parent
        end
    end
    if not info and player and not player.Neutral and player.Team then
        info = {key="team", value=normalize(player.Team.Name), color=player.TeamColor.Color, source="Player.Team"}
    end
    teamMemo[subject] = {expires=now + Config.TeamCacheSeconds, info=info, model=model}
    return info
end

local function relation(a, b)
    if b and b.key == "owner" and b.value == tostring(LocalPlayer.UserId) then return "Ally" end
    if not a or not b or a.key ~= b.key then return "Unknown" end
    return a.value == b.value and "Ally" or "Enemy"
end
local function hasNPCTag(model)
    for _, tag in ipairs(Config.NPCTags) do if Tags:HasTag(model, tag) then return true end end
    return model:GetAttribute("IsNPC") == true or model:GetAttribute("NPC") == true
end
local function getOwner(model)
    local node = model
    while node and node ~= workspace do
        if characters[node] then return characters[node], node end
        -- A despawning player rig must not become an NPC between events.
        if retiredCharacters[node] then return LocalPlayer, node end
        node = node.Parent
    end
    return nil, nil
end
local function chooseRoot(model)
    for _, name in ipairs({"HumanoidRootPart", "Head", "RootPart", "Torso", "UpperTorso"}) do
        local part = model:FindFirstChild(name)
        if part and part:IsA("BasePart") then return part end
    end
    if model.PrimaryPart and model.PrimaryPart:IsDescendantOf(model) then return model.PrimaryPart end
    return model:FindFirstChildWhichIsA("BasePart", true)
end
local function reconcile(model)
    if not model:IsDescendantOf(workspace) then controllerHints[model] = nil; remove(model); return end
    local player, character = getOwner(model)
    if player and (player == LocalPlayer or character ~= model) then remove(model); return end
    local hints = controllerHints[model]
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum and hints and hints.hum and hints.hum:IsDescendantOf(model)
        and hints.hum:FindFirstAncestorWhichIsA("Model") == model then hum = hints.hum end
    local controller = model:FindFirstChildOfClass("AnimationController")
    if not controller and hints and hints.animation and hints.animation:IsDescendantOf(model)
        and hints.animation:FindFirstAncestorWhichIsA("Model") == model then controller = hints.animation end
    if not Config.DetectAnimationControllers then controller = nil end
    local isNPC = hum ~= nil or controller ~= nil or hasNPCTag(model)
    if not player and Config.IsNPC then
        local ok, result = pcall(Config.IsNPC, model)
        if ok and result ~= nil then isNPC = result == true end
    end
    if not player and not isNPC then remove(model); return end
    local root = chooseRoot(model)
    if not root then remove(model); return end
    local d = entities[model]
    if not d then
        entitySerial = entitySerial + 1
        d = {model=model, serial=entitySerial}
        entities[model] = d
    end
    d.player, d.hum, d.root = player, hum, root
    local head = model:FindFirstChild("Head")
    d.anchor = head and head:IsA("BasePart") and head or root
    d.anchorIsHead = d.anchor == head
    d.labelTop = 2.5
    if not d.anchorIsHead then
        -- Headless rigs: calculate their world-space top on structural changes.
        -- No per-frame bounding-box scans are needed for ordinary characters.
        local ok, cf, size = pcall(function() return model:GetBoundingBox() end)
        if ok then
            local halfY = (math.abs(cf.RightVector.Y) * size.X + math.abs(cf.UpVector.Y) * size.Y
                + math.abs(cf.LookVector.Y) * size.Z) * 0.5
            d.labelTop = math.max(0, cf.Position.Y + halfY - root.Position.Y)
        end
    end
    d.labelAnchor = nil
    teamMemo[model] = nil
end
local function mark(model)
    if not alive or not model or not model:IsA("Model") then return end
    dirty[model] = true
    if flushScheduled then return end
    flushScheduled = true
    task.defer(function()
        if not alive then return end
        flushScheduled = false
        local batch = dirty
        dirty = {}
        local count = 0
        for m in pairs(batch) do
            if not alive then return end
            reconcile(m)
            count = count + 1
            if count % 100 == 0 then task.wait() end
        end
    end)
end
local function markAncestors(obj)
    local node = obj
    -- Only model ancestry is visited; never recursively scan Workspace per event.
    while node and node ~= workspace and node ~= game do
        if node:IsA("Model") then mark(node) end
        node = node.Parent
    end
end
local function relevant(obj)
    return obj:IsA("Model") or obj:IsA("BasePart") or obj:IsA("Humanoid") or obj:IsA("AnimationController")
end
local function observeController(obj, removing)
    local kind = obj:IsA("Humanoid") and "hum" or obj:IsA("AnimationController") and "animation" or nil
    if not kind then return end
    local model = obj:FindFirstAncestorWhichIsA("Model")
    if not model then return end
    local hints = controllerHints[model]
    if not hints and not removing then hints = {}; controllerHints[model] = hints end
    if hints then
        if not removing then hints[kind] = obj elseif hints[kind] == obj then hints[kind] = nil end
    end
end
connect(workspace.DescendantAdded, function(obj)
    if relevant(obj) and not obj:IsDescendantOf(visuals) then observeController(obj, false); markAncestors(obj) end
end)
connect(workspace.DescendantRemoving, function(obj)
    if relevant(obj) and not obj:IsDescendantOf(visuals) then observeController(obj, true); markAncestors(obj) end
end)
local function bindPlayer(player)
    local list = {}
    playerConnections[player] = list
    local function added(character)
        retiredCharacters[character] = nil
        characters[character] = player
        teamMemo[player] = nil
        mark(character)
        -- Existing nested NPC-like rigs must no longer be treated as NPCs.
        for model in pairs(entities) do if model:IsDescendantOf(character) then mark(model) end end
    end
    connect(player.CharacterAdded, added, list)
    connect(player.CharacterRemoving, function(character)
        retiredCharacters[character] = true
        characters[character] = nil
        remove(character)
        teamMemo[player] = nil
    end, list)
    connect(player:GetPropertyChangedSignal("Team"), function() teamMemo[player] = nil end, list)
    if player.Character then added(player.Character) end
end
connect(Players.PlayerAdded, bindPlayer)
connect(Players.PlayerRemoving, function(player)
    if player.Character then
        retiredCharacters[player.Character] = true
        characters[player.Character] = nil
        remove(player.Character)
    end
    if playerConnections[player] then disconnect(playerConnections[player]); playerConnections[player] = nil end
    teamMemo[player] = nil
end)
for _, player in ipairs(Players:GetPlayers()) do bindPlayer(player) end
for _, tag in ipairs(Config.NPCTags) do
    connect(Tags:GetInstanceAddedSignal(tag), markAncestors)
    connect(Tags:GetInstanceRemovedSignal(tag), markAncestors)
end

local function createVisual(d)
    local hl = Instance.new("Highlight")
    hl.Adornee = d.model
    hl.FillTransparency = Config.FilledChams and Config.FillTransparency or 1
    hl.OutlineTransparency = 0
    hl.Parent = visuals
    local tag = Instance.new("BillboardGui")
    tag.Name = "EntityLabel"
    tag.Adornee = d.anchor
    d.labelWidth, d.labelHeight = Config.LabelWidth, Config.NameTextSize*2+6
    tag.Size = UDim2.fromOffset(d.labelWidth, d.labelHeight)
    -- Bottom-center anchoring keeps every text line above the attachment point,
    -- including when the character becomes small in the distance.
    tag.SizeOffset = Vector2.new(0, 0.5)
    tag.LightInfluence = 0
    tag.Parent = rootGui
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium
    label.TextSize = Config.NameTextSize
    label.TextStrokeTransparency = 0.25
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.TextWrapped = false
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.TextYAlignment = Enum.TextYAlignment.Bottom
    label.RichText = false
    label.Parent = tag
    d.highlight, d.tag, d.label = hl, tag, label
end

local function positionLabel(d)
    local lift = Config.LabelHeight + (d.anchorIsHead and 0 or d.labelTop)
    if d.labelAnchor ~= d.anchor then
        d.tag.Adornee = d.anchor
        d.tag.ExtentsOffsetWorldSpace = Vector3.new(0, d.anchorIsHead and 1 or 0, 0)
        d.labelAnchor = d.anchor
    end
    if d.labelLift ~= lift then
        d.tag.StudsOffsetWorldSpace = Vector3.new(0, lift, 0)
        d.labelLift = lift
    end
    if d.namesVisible ~= Config.ShowNames then
        d.tag.Enabled = Config.ShowNames
        d.namesVisible = Config.ShowNames
    end
end

local status, refreshUI
local function update()
    if not alive then return end
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local candidates, count = {}, 0
    local now = os.clock()
    local localTeam = Config.TeamMode ~= "Off" and resolveTeam(LocalPlayer, character, now) or nil
    local limitSq = Config.MaxDistance * Config.MaxDistance
    for model, d in pairs(entities) do
        count = count + 1
        if not model:IsDescendantOf(workspace) or not d.root:IsDescendantOf(model)
            or not d.anchor:IsDescendantOf(model) then
            dropVisual(d)
            mark(model)
        elseif enabled and root and (d.player and Config.ShowPlayers or not d.player and Config.ShowNPCs)
            and (Config.ShowDead or not d.hum or d.hum.Health > 0) then
            local offset = root.Position - d.root.Position
            local distanceSq = offset:Dot(offset)
            if distanceSq <= limitSq then
                local team = Config.TeamMode ~= "Off" and resolveTeam(d.player, model, now) or nil
                local rel = relation(localTeam, team)
                if Config.TeamMode ~= "Enemies only" or rel ~= "Ally" then
                    d.distanceSq, d.team, d.relation = distanceSq, team, rel
                    table.insert(candidates, d)
                end
            end
        end
    end
    if #candidates > Config.MaxVisible then
        table.sort(candidates, function(a, b)
            if a.distanceSq == b.distanceSq then return a.serial < b.serial end
            return a.distanceSq < b.distanceSq
        end)
    end
    local selected, visible = {}, math.min(#candidates, Config.MaxVisible)
    for i = 1, visible do
        local d = candidates[i]
        selected[d] = true
        if d.highlight and (not d.highlight.Parent or not d.tag or not d.tag.Parent
            or not d.label or not d.label.Parent) then dropVisual(d) end
        if not d.highlight then createVisual(d) end
        positionLabel(d)
        local fill = Config.FilledChams and Config.FillTransparency or 1
        if d.fill ~= fill then d.highlight.FillTransparency = fill; d.fill = fill end
        local color = d.player and Config.PlayerColor or Config.NPCColor
        if Config.TeamMode ~= "Off" then
            color = (d.team and d.team.color) or (d.relation == "Ally" and Config.AllyColor)
                or (d.relation == "Enemy" and Config.EnemyColor) or color
        end
        if d.label.TextSize ~= Config.NameTextSize then
            d.label.TextSize = Config.NameTextSize
            d.text = nil
        end
        local name = d.player and d.player.DisplayName or d.model.Name
        if Config.ShowUsernames and d.player and d.player.DisplayName ~= d.player.Name then name = name .. " (@" .. d.player.Name .. ")" end
        local fields = {}
        if Config.ShowHealth and d.hum then
            table.insert(fields, string.format("%d/%d HP", math.ceil(d.hum.Health), math.ceil(d.hum.MaxHealth)))
        end
        if Config.ShowDistance then table.insert(fields, tostring(math.floor(math.sqrt(d.distanceSq) + 0.5)) .. " studs") end
        if Config.TeamMode ~= "Off" then table.insert(fields, d.relation) end
        local text = name .. (#fields > 0 and "\n" .. table.concat(fields, " · ") or "")
        if Config.ShowTeamSource and d.team then text = text .. "\n" .. d.team.source end
        if text ~= d.text then
            d.label.Text = text
            d.text = text
            local _, breaks = text:gsub("\n", "")
            local height = (breaks+1)*(Config.NameTextSize+2)+2
            if d.labelHeight ~= height then
                d.labelHeight = height
                d.tag.Size = UDim2.fromOffset(d.labelWidth,height)
            end
        end
        if color ~= d.color then
            d.highlight.OutlineColor = color
            d.highlight.FillColor = color
            d.label.TextColor3 = color
            d.color = color
        end
        if d.depth ~= Config.Occluded then
            d.highlight.DepthMode = Config.Occluded and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop
            d.tag.AlwaysOnTop = not Config.Occluded
            d.depth = Config.Occluded
        end
    end
    for _, d in pairs(entities) do if not selected[d] then dropVisual(d) end end
    if status then
        local text = string.format("%d tracked · %d chams%s", count, visible, not root and " · respawning" or "")
        if status.Text ~= text then status.Text = text end
    end
end

local function unload()
    if not alive then return end
    alive = false
    pcall(function()
        if environment[registryKey] == runtime then environment[registryKey] = nil end
    end)
    disconnect(connections)
    for _, list in pairs(playerConnections) do disconnect(list) end
    table.clear(playerConnections)
    for _, d in pairs(entities) do dropVisual(d) end
    table.clear(entities)
    table.clear(dirty)
    table.clear(characters)
    table.clear(retiredCharacters)
    table.clear(controllerHints)
    table.clear(teamMemo)
    visuals:Destroy()
    rootGui:Destroy()
end
connect(unloadEvent.Event, unload)
connect(rootGui.Destroying, unload)
runtime = {Stop=unload}
pcall(function() environment[registryKey] = runtime end)

-- Compact, scrollable UI. Menu visibility does not control marker visibility.
local accent = Color3.fromRGB(99, 179, 255)
local function corner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = obj
end
local function button(parent, text)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 34)
    b.BackgroundColor3 = Color3.fromRGB(34, 41, 54)
    b.TextColor3 = Color3.fromRGB(230, 237, 247)
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 13
    b.Text = text
    b.BorderSizePixel = 0
    b.Parent = parent
    corner(b, 7)
    return b
end
local menuButton = button(rootGui, "Better ESP · P")
menuButton.Size = UDim2.fromOffset(140, 34)
menuButton.Position = UDim2.fromOffset(14, 14)
local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 304, 0.78, 0)
panel.Position = UDim2.fromOffset(14, 58)
panel.BackgroundColor3 = Color3.fromRGB(19, 24, 34)
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = rootGui
corner(panel, 12)
local constraint = Instance.new("UISizeConstraint")
constraint.MaxSize = Vector2.new(304, 650)
constraint.Parent = panel
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -24, 0, 38)
title.Position = UDim2.fromOffset(12, 4)
title.BackgroundTransparency = 1
title.Text = "BETTER ESP  /  4.4"
title.TextColor3 = accent
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.Active = true
title.Parent = panel
status = title:Clone()
status.Position = UDim2.fromOffset(12, 36)
status.Size = UDim2.new(1, -24, 0, 30)
status.TextSize = 11
status.TextColor3 = Color3.fromRGB(156, 173, 197)
status.Text = "Indexing loaded entities…"
status.Parent = panel
local scroll = Instance.new("ScrollingFrame")
scroll.Position = UDim2.fromOffset(12, 72)
scroll.Size = UDim2.new(1, -24, 1, -84)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.CanvasSize = UDim2.new()
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = panel
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll
local redraw, order = {}, 0
local function control(label, get, click)
    order = order + 1
    local b = button(scroll, "")
    b.LayoutOrder = order
    table.insert(redraw, function() b.Text = label .. ": " .. tostring(get()) end)
    connect(b.Activated, function()
        click()
        refreshUI()
        update()
    end)
end
refreshUI = function() for _, draw in ipairs(redraw) do draw() end end
local function toggle(label, key)
    control(label, function() return Config[key] and "ON" or "OFF" end, function() Config[key] = not Config[key] end)
end
control("ESP", function() return enabled and "ON" or "OFF" end, function() enabled = not enabled end)
toggle("Players", "ShowPlayers")
toggle("NPCs", "ShowNPCs")
toggle("Health", "ShowHealth")
toggle("Distance (studs)", "ShowDistance")
toggle("Names above characters", "ShowNames")
toggle("Show usernames", "ShowUsernames")
toggle("Filled chams", "FilledChams")
toggle("Show dead", "ShowDead")
control("Team mode", function() return Config.TeamMode end, function()
    Config.TeamMode = Config.TeamMode == "Off" and "Colors" or Config.TeamMode == "Colors" and "Enemies only" or "Off"
    table.clear(teamMemo)
end)
toggle("Show team source", "ShowTeamSource")
toggle("Respect walls", "Occluded")
control("Animation-only NPCs", function() return Config.DetectAnimationControllers and "ON" or "OFF" end, function()
    Config.DetectAnimationControllers = not Config.DetectAnimationControllers
    -- One explicit rescan is required when changing recognition rules.
    task.spawn(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if not alive then return end
            if obj:IsA("AnimationController") then markAncestors(obj) end
        end
    end)
end)
local function cycle(label, key, values, display)
    control(label, function() return display and display(Config[key]) or Config[key] end, function()
        local index = table.find(values, Config[key]) or 0
        Config[key] = values[index % #values + 1]
    end)
end
cycle("Range", "MaxDistance", {250, 500, 1000, 2000, math.huge}, function(v) return v == math.huge and "Unlimited" or v .. " studs" end)
cycle("Marker budget", "MaxVisible", {32, 64, 128, 200})
cycle("Name height", "LabelHeight", {0.5, 1, 1.5, 2.5, 4}, function(v) return v .. " studs" end)
cycle("Name text size", "NameTextSize", {8, 9, 10, 11, 12})
cycle("Update interval", "UpdateInterval", {0.1, 0.2, 0.5, 1}, function(v) return v .. "s" end)
local palette = {
    {"Orange", Color3.fromRGB(255,170,70)}, {"Rose", Color3.fromRGB(255,90,110)},
    {"Blue", Color3.fromRGB(99,179,255)}, {"Green", Color3.fromRGB(80,220,160)},
    {"Purple", Color3.fromRGB(190,140,255)}, {"White", Color3.fromRGB(235,240,255)},
}
local function colorControl(label, key, index)
    control(label, function() return palette[index][1] end, function()
        index = index % #palette + 1
        Config[key] = palette[index][2]
    end)
end
colorControl("Player color", "PlayerColor", 1)
colorControl("NPC color", "NPCColor", 2)
order = order + 1
local stopButton = button(scroll, "Unload ESP")
stopButton.LayoutOrder = order
stopButton.TextColor3 = Color3.fromRGB(255, 130, 140)
connect(stopButton.Activated, unload)
connect(menuButton.Activated, function() panel.Visible = not panel.Visible end)
-- Drag from the title only; controls remain easy to tap and scroll.
local dragInput, dragStart, panelStart
connect(title.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragInput, dragStart, panelStart = input, input.Position, panel.Position
    end
end)
connect(Input.InputChanged, function(input)
    if not dragInput then return end
    local mouse = dragInput.UserInputType == Enum.UserInputType.MouseButton1
    if (mouse and input.UserInputType == Enum.UserInputType.MouseMovement) or input == dragInput then
        local delta = input.Position - dragStart
        local camera = workspace.CurrentCamera
        local size = camera and camera.ViewportSize or Vector2.new(800, 600)
        panel.Position = UDim2.fromOffset(
            math.clamp(panelStart.X.Offset + delta.X, 0, math.max(0, size.X - panel.AbsoluteSize.X)),
            math.clamp(panelStart.Y.Offset + delta.Y, 0, math.max(0, size.Y - panel.AbsoluteSize.Y - 40))
        )
    end
end)
connect(Input.InputEnded, function(input) if input == dragInput then dragInput = nil end end)
connect(Input.InputBegan, function(input, processed)
    if not processed and not Input:GetFocusedTextBox() and input.KeyCode == Enum.KeyCode.P then
        panel.Visible = not panel.Visible
    end
end)
refreshUI()
connect(RunService.Heartbeat, function(dt)
    elapsed = elapsed + dt
    if elapsed >= Config.UpdateInterval then
        elapsed = elapsed % Config.UpdateInterval
        update()
    end
end)

-- Subscribe first, scan once, and yield in batches so initial loading stays responsive.
task.spawn(function()
    local snapshot = workspace:GetDescendants()
    for i, obj in ipairs(snapshot) do
        if not alive then return end
        if obj:IsA("Humanoid") or obj:IsA("AnimationController") then observeController(obj, false); markAncestors(obj) end
        if obj:IsA("Model") and (hasNPCTag(obj) or Config.IsNPC) then mark(obj) end
        if i % 1000 == 0 then task.wait() end
    end
    if alive then update() end
end)
