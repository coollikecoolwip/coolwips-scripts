-- Repaired for syntax/runtime safety; review the notes at the end before use.
-- The original was obfuscated; MM2-specific behavior could not be validated offline.
local spilledValues1 = {}
local capturedValues1 = {}




local v515 = game:IsLoaded()
if (not v515) then
    game.Loaded:Wait()
end
local v511 = cloneref or function(arg34_1)
    return arg34_1
end
local v516 = {}
capturedValues1.value1 = v511
v511 = setmetatable
local v521 = function(arg17_1, arg17_2)
    local v181, v183, v184
    local v180 = arg17_1
    local up2 = arg17_2
    local v182 = function()
        local v321 = game
        local v323 = v321.GetService
        return capturedValues1.value1(v323(v321, up2))
    end
    v181, v184 = pcall(v182)
    if v181 then
        rawset(v180, up2, v184)
        return v184
    else
        warn(("Invalid Service: " .. (tostring(up2))))
        v183 = nil
        return v183
    end
end
v515 = v511(v516, {["__index"] = v521})
v511 = v515.Workspace
capturedValues1.value2 = v511
v511 = v515.Players
capturedValues1.value3 = v511
v511 = v515.ReplicatedStorage
capturedValues1.value4 = v511
v511 = v515.ReplicatedFirst
v521 = v515.RunService
capturedValues1.value5 = v521
v521 = v515.Lighting
local v519 = v515.CoreGui
local v541 = v515.CorePackages
local v520 = v515.TweenService
capturedValues1.value6 = v520
v520 = v515.Debris
local v527 = v515.HttpService
local v528 = v515.TeleportService
local v531 = v515.PathfindingService
local v530 = v515.CollectionService
local v534 = v515.ProximityPromptService
local v532 = v515.PhysicsService
local v533 = v515.ContentProvider
local v537 = v515.LogService
local v536 = v515.Stats
local v539 = v515.ScriptContext
local v546 = v515.UserInputService
local v547 = v515.ContextActionService
local v548 = v515.GuiService
local v549 = v515.TextChatService
local v550 = v515.Chat
local v551 = v515.VirtualInputManager
local v552 = v515.VirtualUser
capturedValues1.value7 = v552
v552 = v515.VRService
local v553 = v515.StarterGui
local v554 = v515.StarterPack
local v555 = v515.StarterPlayer
local v556 = v515.Teams
local v557 = v515.SoundService
local v558 = v515.MaterialService
local v559 = v515.MarketplaceService
local v560 = v515.BadgeService
local v561 = capturedValues1.value3.LocalPlayer
capturedValues1.value8 = v561
if (not capturedValues1.value8) then
    capturedValues1.value3:GetPropertyChangedSignal("LocalPlayer"):Wait()
    capturedValues1.value8 = capturedValues1.value3.LocalPlayer
end
local v564 = capturedValues1.value5.PreSimulation
local v562 = v564
if not (v564) then
    v562 = capturedValues1.value5.Stepped
end
local v565 = capturedValues1.value5.PostSimulation
local v563 = v565
if not (v565) then
    v563 = capturedValues1.value5.Heartbeat
end
capturedValues1.value9 = v563
capturedValues1.value10 = false
capturedValues1.value11 = {}
capturedValues1.value12 = false
capturedValues1.value13 = {["EnableAutoFarm"] = false, ["AutoFarmSpeed"] = 28, ["AutoFarmOffset"] = 1, ["AutoFarmDelay"] = .1, ["AutoResetOnFull"] = false, ["AutoEndRound"] = false, ["AntiAfk"] = false, ["AntiFling"] = false, ["AutoFarmMode"] = "Nearest"}
capturedValues1.value13.DiagnosticMode = false
capturedValues1.value30 = {lastMessage = "", lastReport = 0}
capturedValues1.value31 = {lastSelectedAt = nil, lastTarget = nil}
capturedValues1.value13.TimingLogs = true
local timingLogState = {last = {}, entries = {}, lastPickupAt = nil}
local function farmTiming(key, message, interval)
    if not capturedValues1.value13.TimingLogs then return end
    local now = os.clock()
    if interval and timingLogState.last[key] and now - timingLogState.last[key] < interval then return end
    timingLogState.last[key] = now
    local entry = string.format("[VISION TIMING %.3f] %s", now, message)
    table.insert(timingLogState.entries, entry)
    if #timingLogState.entries > 150 then table.remove(timingLogState.entries, 1) end
    print(entry)
end

task.spawn(function()
    while true do
        task.wait(0.1)
        if capturedValues1.value13.DiagnosticMode then
            local workspaceRoot = capturedValues1.value2
            local candidates, coinParts, root = 0, 0, nil
            local sample = {}
            for _, item in ipairs(workspaceRoot:GetDescendants()) do
                if item.Name == "CoinContainer" or item.Name == "CandyContainer"
                    or item.Name == "CounContainer" or item.Name:lower() == "barn" then
                    root = root or item
                end
                if item:IsA("BasePart") and item.Name:lower() == "coin_server" then
                    coinParts += 1
                    candidates += 1
                    if #sample < 5 then table.insert(sample, item:GetFullName()) end
                elseif item:IsA("BasePart") then
                    local name = item.Name:lower()
                    if name:find("candy") or name:find("coin") then
                        candidates += 1
                    end
                end
            end
            local character = capturedValues1.value8.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local roundOk, activeRound = pcall(capturedValues1.value23)
            local report = string.format("Workspace scan: %d candidate(s), %d Coin_Server part(s), root=%s; roundActive=%s; farm=%s; alive=%s; sample=%s",
                candidates, coinParts, root and root:GetFullName() or "missing",
                tostring(roundOk and activeRound), tostring(capturedValues1.value13.EnableAutoFarm),
                tostring(humanoid and humanoid.Health > 0), #sample > 0 and table.concat(sample, " | ") or "none")
            if report ~= capturedValues1.value30.lastMessage then
                print("[VISION HUB] " .. report)
                capturedValues1.value30.lastMessage = report
            end
        end
    end
end)
capturedValues1.value14 = {["RoundStart"] = false, ["VictoryScreen"] = false}
capturedValues1.value15 = {["RegularLobby"] = true, ["ServerStatus"] = true, ["EffectLoader"] = true, ["RoundTimerPart"] = true, ["WeaponDisplays"] = true, ["Camera"] = true, ["Terrain"] = true, ["PetContainer"] = true, ["GameSettings"] = true, ["LoadLobby"] = true, ["ServerVersion"] = true}
local v573 = capturedValues1.value4:WaitForChild("Remotes", 5)
v563 = v573
if v573 then
    v563 = (capturedValues1.value4.Remotes:WaitForChild("Gameplay", 5))
end
capturedValues1.value16 = v563
local v575 = capturedValues1.value16
v573 = v575
if v575 then
    v573 = (capturedValues1.value16:WaitForChild("CoinsStarted", 5))
end
v563 = (v573 or nil)
local v576 = capturedValues1.value16
local v574 = v576
if v576 then
    v574 = (capturedValues1.value16:WaitForChild("CoinCollected", 5))
end
local v572 = (v574 or nil)
local v577 = capturedValues1.value16
v575 = v577
if v577 then
    v575 = (capturedValues1.value16:WaitForChild("RoleSelect", 5))
end
v573 = (v575 or nil)
local v578 = capturedValues1.value16
v576 = v578
if v578 then
    v576 = (capturedValues1.value16:WaitForChild("RoundStart", 5))
end
local v579 = capturedValues1.value16
v574 = (v576 or nil)
v577 = v579
if v579 then
    v577 = (capturedValues1.value16:WaitForChild("VictoryScreen", 5))
end
v575 = (v577 or nil)
local v580 = capturedValues1.value16
v578 = v580
if v580 then
    v578 = (capturedValues1.value16:WaitForChild("GameOver", 5))
end
v576 = (v578 or nil)
local v581 = capturedValues1.value16
local getCoinRemote = nil
if v581 then
    getCoinRemote = v581:WaitForChild("GetCoin", 5)
end
capturedValues1.value17 = getCoinRemote
local v585 = function()
    local v382, v385, v386, v387, v388, v389, v390, v391, v392, v393, v394, v395, v396, v397, v398, v400
    v382, v386, v387 = ipairs(capturedValues1.value3:GetPlayers())
    local v384 = v382
    while true do
        v387, v385 = v384(v386, v387)
        if not v387 then
            break
        end
        v390 = (v385 ~= capturedValues1.value8) and v385.Character
        if v390 then
            v388 = v385.Character:FindFirstChild("Knife")
            v390 = v388
            if not (v388) then
                v391 = v385:FindFirstChild("Backpack")
                v389 = v391
                if v391 then
                    v389 = (v385.Backpack:FindFirstChild("Knife"))
                end
                v390 = v389
            end
            if v390 then
                return v385
            end
        end
    end
    v387 = capturedValues1.value16
    v386 = v387
    if v387 then
        v386 = (capturedValues1.value16:FindFirstChild("GetCurrentPlayerData"))
    end
    local up8 = v386
    v384 = up8
    v386 = v384
    if v384 then
        v386 = (up8:IsA("RemoteFunction"))
    end
    if v386 then
        v397 = function()
            return up8:InvokeServer()
        end
        v386, v384 = pcall(v397)
        v397 = v386
        if v386 then
            v397 = ((type(v384)) == "table")
        end
        if v397 then
            for v390, v388 in pairs(v384) do
                v389 = v390
                v391 = ((typeof(v389)) == "Instance") and v389.Name or (tostring(v389))
                v392 = capturedValues1.value3:FindFirstChild(v391)
                v393 = v392 and (v392 ~= capturedValues1.value8)
                if v393 then
                    v394 = ((type(v388)) == "table")
                    v393 = v394
                    if v394 then
                        v396 = (v388.Role == "Murderer")
                        v394 = v396
                        if not (v396) then
                            v394 = (v388.role == "Murderer")
                        end
                        v393 = v394
                    end
                    if v393 then
                        return v392
                    else
                        v394 = tostring(v388)
                        if (v394 == "Murderer") then
                            return v392
                        end
                    end
                end
            end
        end
    end
    v397 = capturedValues1.value4:FindFirstChild("GetPlayerData")
    v386 = v397
    if not (v397) then
        v390 = capturedValues1.value4:FindFirstChild("Extras")
        v384 = v390
        if v390 then
            v384 = (capturedValues1.value4.Extras:FindFirstChild("GetPlayerData"))
        end
        v386 = v384
    end
    local up9 = v386
    v397 = up9
    v386 = v397
    if v397 then
        v386 = (up9:IsA("RemoteFunction"))
    end
    if v386 then
        v386, v397 = pcall(function()
            return up9:InvokeServer()
        end)
        v385 = v386
        if v386 then
            v385 = ((type(v397)) == "table")
        end
        if v385 then
            for v389, v391 in pairs(v397) do
                v388 = v389
                v392 = ((typeof(v388)) == "Instance") and v388.Name or (tostring(v388))
                v393 = capturedValues1.value3:FindFirstChild(v392)
                v394 = v393 and (v393 ~= capturedValues1.value8)
                if v394 then
                    v398 = ((type(v391)) == "table")
                    v395 = v398
                    if v398 then
                        v400 = (v391.Role == "Murderer")
                        v398 = v400
                        if not (v400) then
                            v398 = (v391.role == "Murderer")
                        end
                        v395 = v398
                    end
                    v394 = v395
                    if not (v395) then
                        v394 = ((tostring(v391)) == "Murderer")
                    end
                    if v394 then
                        return v393
                    end
                end
            end
        end
    end
    return nil
end
capturedValues1.value17 = (v579 or nil)
local v586 = function(arg43_1)
    local v412, v418, v419
    local v406 = arg43_1
    local v411 = capturedValues1.value8.Character
    local v408 = v411 and (v411:FindFirstChildOfClass("Humanoid"))
    local v407 = v408 and v408.RootPart
    local up10 = v407
    local v410 = v406.Character
    v407 = v410
    if v410 then
        v407 = (v410:FindFirstChild("HumanoidRootPart"))
    end
    local up11 = v407
    v407 = v411
    if v411 then
        v407 = up10 and up11
    end
    if v407 then
        v412 = up10.AssemblyLinearVelocity
        local up12 = v412
        v412 = up10.AssemblyAngularVelocity
        local up13 = v412
        v407 = Instance.new("Attachment")
        local up14 = v407
        v412 = up14
        v412.Name = "FlingAttachment"
        v412 = up14
        v412.Parent = up10
        v407 = Instance.new("AngularVelocity")
        local up15 = v407
        v412 = up15
        v412.Attachment0 = up14
        v412 = up15
        v418 = Enum.ActuatorRelativeTo.World
        v412.RelativeTo = v418
        v412 = up15
        v418 = math.huge
        v412.MaxTorque = v418
        v412 = up15
        v419 = Vector3.new(0, 99999, 0)
        v412.AngularVelocity = v419
        v412 = up15
        v412.Parent = up10
        v407 = Instance.new("LinearVelocity")
        local up16 = v407
        v412 = up16
        v412.Attachment0 = up14
        v412 = up16
        v419 = Enum.ActuatorRelativeTo .World
        v412.RelativeTo = v419
        v412 = up16
        v419 = math.huge
        v412.MaxForce = v419
        v412 = up16
        v419 = Vector3.zero
        v412.VectorVelocity = v419
        v412 = up16
        v412.Parent = up10
        task.spawn(function()
            local v337, v338, v341
            local v336 = (os.clock())
            while true do
                v338 = (((os.clock()) - v336) < 1.5)
                v337 = v338
                if v338 then
                    v337 = up10 and up11
                end
                if v337 then
                    capturedValues1.value9:Wait()
                    v337 = up10 and up11
                    if v337 then
                        v341 = up10
                        v338 = (up11.CFrame * (CFrame.new(0, 0, 0.5)))
                        v341.CFrame = v338
                    end
                else
                    break
                end
            end
            up15:Destroy()
            up16:Destroy()
            up14:Destroy()
            if up10 then
                v341 = up10
                v341.AssemblyLinearVelocity = up12
                v341 = up10
                v338 = up13
                v341.AssemblyAngularVelocity = v338
            end
            return
        end)
    end
    return
end
capturedValues1.value18 = nil
capturedValues1.value19 = nil
local v583 = function()
    -- Barn can be a Model or Folder, depending on the map loader.
    for _, item in ipairs(capturedValues1.value2:GetDescendants()) do
        if item.Name:lower() == "barn" and (item:IsA("Model") or item:IsA("Folder")) then
            return item
        end
    end
    local v428, v429, v431, v434
    local v426 = capturedValues1.value18
    local v427 = v426
    if v426 then
        v427 = (capturedValues1.value18.Parent == capturedValues1.value2)
    end
    if v427 then
        v434 = capturedValues1.value18
        return v434
    else
        v427 = ipairs
        for v428, v429 in v427(capturedValues1.value2:GetChildren()) do
            v431 = v429:IsA("Model")
            v427 = v431
            if v431 then
                v427 = (not capturedValues1.value15[v429.Name]) and (not (capturedValues1.value3:GetPlayerFromCharacter(v429)))
            end
            if v427 then
                return v429
            end
        end
        return nil
    end
end
capturedValues1.value20 = nil
capturedValues1.value21 = nil
local v589 = function()
    local v444, v447
    if capturedValues1.value19 then
        v444 = function()
            capturedValues1.value19:Destroy()
            return
        end
        pcall(v444)        capturedValues1.value19 = nil
    end
    if capturedValues1.value20 then
        v447 = function()
            capturedValues1.value20:Destroy()
            return
        end
        pcall(v447)
        capturedValues1.value20 = nil
    end
    if capturedValues1.value21 then
        pcall(function()
            capturedValues1.value21:Destroy()
            return
        end)
        capturedValues1.value21 = nil
    end
    return
end
local v588 = function(arg46_1)
    local v450, v451, v452, v453, v454, v456, v458, v459
    local v449 = arg46_1
    if (not v449) then
        v450 = nil
        return v450, nil, nil
    else
        v451 = capturedValues1.value19
        v452 = v451
        if v451 then
            v459 = (capturedValues1.value19.Parent == v449)
            v451 = v459
            if v459 then
                v453 = capturedValues1.value20
                v459 = v453
                if v453 then
                    v454 = (capturedValues1.value20.Parent == v449)
                    v453 = v454
                    if v454 then
                        v456 = capturedValues1.value21
                        v454 = v456
                        if v456 then
                            v454 = (capturedValues1.value21.Parent == v449)
                        end
                        v453 = v454
                    end
                    v459 = v453
                end
                v451 = v459
            end
            v452 = v451
        end
        if v452 then
            v450 = capturedValues1.value19
            v452 = capturedValues1.value20
            v451 = capturedValues1.value21
            return v450, v452, v451
        else
            if capturedValues1.value19 then
                v451 = function()
                    capturedValues1.value19:Destroy()
                    return
                end
                pcall(v451)
            end
            if capturedValues1.value20 then
                v451 = function()
                    capturedValues1.value20:Destroy()
                    return
                end
                pcall(v451)
            end
            if capturedValues1.value21 then
                v451 = function()
                    capturedValues1.value21:Destroy()
                    return
                end
                pcall(v451)
            end
            capturedValues1.value19 = (Instance.new("Attachment"))
            v450 = capturedValues1.value19
            v450.Name = "FarmPoint"
            v450 = capturedValues1.value19
            v450.Parent = v449
            capturedValues1.value20 = (Instance.new("AlignPosition"))
            v450 = capturedValues1.value20
            v459 = Enum.PositionAlignmentMode.OneAttachment
            v450.Mode = v459
            v450 = capturedValues1.value20
            v450.RigidityEnabled = false
            v450.MaxVelocity = 28
            v450.MaxForce = 10000
            v450.Responsiveness = 15
            v450 = capturedValues1.value20
            v450.ApplyAtCenterOfMass = true
            v450 = capturedValues1.value20
            v450.Attachment0 = capturedValues1.value19
            v450 = capturedValues1.value20
            v459 = v449.Position
            v450.Position = v459
            v450 = capturedValues1.value20
            v450.Parent = v449
            capturedValues1.value21 = (Instance.new("AlignOrientation"))
            v450 = capturedValues1.value21
            v458 = Enum.OrientationAlignmentMode.OneAttachment
            v450.Mode = v458
            v450 = capturedValues1.value21
            v450.RigidityEnabled = true
            v450 = capturedValues1.value21
            v450.Attachment0 = capturedValues1.value19
            v450 = capturedValues1.value21
            v453 = CFrame.Angles((math.rad(90)), 0, 0)
            v450.CFrame = v453
            v450 = capturedValues1.value21
            v450.Parent = v449
            v450 = capturedValues1.value19
            v459 = capturedValues1.value20
            v458 = capturedValues1.value21
            return v450, v459, v458
        end
    end
end
capturedValues1.value22 = v583
local v584 = function()
    local v467, v468, v469, v470, v471, v473, v475
    -- Trust the active collectible hierarchy before checking version-specific timer UI.
    for _, collectible in ipairs(capturedValues1.value2:GetDescendants()) do
        if collectible:IsA("BasePart") and collectible.Name == "Coin_Server" then
            local parent = collectible.Parent
            while parent and parent ~= capturedValues1.value2 do
                local containerName = parent.Name:lower()
                if containerName == "coincontainer" or containerName == "candycontainer"
                    or containerName == "councontainer" or containerName == "coinarea"
                    or containerName == "barn" then
                    return true
                end
                parent = parent.Parent
            end
        end
    end
    local v472 = (capturedValues1.value2:FindFirstChild("RoundTimerPart"))
    if v472 then
        v468 = (v472:FindFirstChildOfClass("SurfaceGui"))
        v471 = v468
        if v468 then
            v471 = (v468:FindFirstChildOfClass("Frame"))
        end
        v469 = v471
        v470 = v469 and (v469:FindFirstChild("Timer"))
        v471 = v470
        if v470 then
            v475 = (v470.Text ~= "")
            v473 = v475
            if v475 then
                v473 = (v470.Text ~= "0s")
            end
            v471 = v473
        end
        if v471 then
            v467 = true
            return v467
        end
    end
    v468 = capturedValues1.value14.RoundStart
    v471 = v468
    if v468 then
        v471 = (not capturedValues1.value14.VictoryScreen)
    end
    return v471
end
local v587 = function()
    capturedValues1.value11 = {}
    capturedValues1.value10 = false
    capturedValues1.value12 = false
    return
end
capturedValues1.value23 = v584
capturedValues1.value24 = v585
capturedValues1.value25 = v586
capturedValues1.value26 = v587
capturedValues1.value27 = v588
capturedValues1.value28 = v589
if v573 then
    v589 = v573.OnClientEvent
    spilledValues1.value1 = function()
        capturedValues1.value14.RoundStart = true
        capturedValues1.value14.VictoryScreen = false
        capturedValues1.value26()
        return
    end
    v589:Connect(spilledValues1.value1)
end
if v574 then
    spilledValues1.value1 = function()
        capturedValues1.value14.RoundStart = true
        capturedValues1.value14.VictoryScreen = false
        capturedValues1.value26()
        return
    end
    v574.OnClientEvent:Connect(spilledValues1.value1)
end
if v575 then
    v589 = v575.OnClientEvent
    spilledValues1.value1 = function()
        capturedValues1.value14.RoundStart = false
        capturedValues1.value14.VictoryScreen = true
        capturedValues1.value26()
        capturedValues1.value28()
        return
    end
    v589:Connect(spilledValues1.value1)
end
if v576 then
    spilledValues1.value1 = function()
        capturedValues1.value14.RoundStart = false
        capturedValues1.value14.VictoryScreen = false
        capturedValues1.value26()
        capturedValues1.value28()
        return
    end
    v576.OnClientEvent:Connect(spilledValues1.value1)
end
v589 = capturedValues1.value8.CharacterAdded
spilledValues1.value1 = function()
    capturedValues1.value26()
    capturedValues1.value28()
    return
end
v589:Connect(spilledValues1.value1)
v562:Connect(function()
    local v77, v80, v81, v82, v83, v84, v85, v86
    local v79 = capturedValues1.value8.Character
    local v76 = capturedValues1.value13
    local v78 = v79
    local v74 = (v76.EnableAutoFarm and v78)
    if v74 then
        v80 = v78.GetDescendants
        for v76, v81 in ipairs(v80(v78)) do
            v82 = (v81:IsA("BasePart")) and v81.CanCollide
            if v82 then
                v81.CanCollide = false
            end
        end
    end
    local v75 = capturedValues1.value13
    if v75.AntiFling then
        v79 = ipairs
        v80 = capturedValues1.value3
        v82 = v80.GetPlayers
        for v77, v81 in v79(v82(v80)) do
            v86 = capturedValues1.value8
            v82 = (v81 ~= v86) and v81.Character
            if v82 then
                v79 = ipairs
                v83 = v81.Character
                v85 = v83.GetDescendants
                for v86, v84 in v79(v85(v83)) do
                    v85 = (v84:IsA("BasePart")) and v84.CanCollide
                    if v85 then
                        v84.CanCollide = false
                    end
                end
            end
        end
    end
    return
end)
local v590 = function()
    local v97 = capturedValues1.value8.Character
    local v94 = v97 and (v97:FindFirstChildOfClass("Humanoid"))
    local v95 = capturedValues1.value13.AutoResetOnFull
    local v93 = v95
    if v95 then
        v93 = v94 and (v94.Health > 0)
    end
    if v93 then
        v94.Health = 0
    end
    v93 = capturedValues1.value13
    if v93["AutoEndRound"] then
        local up1 = (capturedValues1.value24())
        if up1 then
            task.spawn(function()
                local v493 = capturedValues1.value8.Character
                local v494 = v493
                if not (v493) then
                    v494 = (capturedValues1.value8.CharacterAdded:Wait())
                end
                local v495 = v494:WaitForChild("Humanoid")
                if (v495.Health <= 0) then
                    capturedValues1.value8.CharacterAdded:Wait()
                end
                task.wait(.3)
                local v489 = function()
                    capturedValues1.value25(up1)
                    return
                end
                pcall(v489)

                return
            end)
        end
    end
    return
end
capturedValues1.value29 = v590
if v563 and v563:IsA("RemoteEvent") then
    v563.OnClientEvent:Connect(function(arg21_1)
        local v216, v220, v224, v225
        local v213 = false
        capturedValues1.value11 = {}
        for v218, v219 in pairs(type(arg21_1) == "table" and arg21_1 or {}) do
            if type(v219) ~= "table" then continue end
            v220 = v218
            v224 = tonumber(v219.CollectedAmount) or 0
            v225 = tonumber(v219.CollectionLimit)
            v216 = v225
            if not (v225) then
                v216 = math.huge
            end
            v225 = (v224 >= v216)
            v216 = capturedValues1.value11
            v216[v220] = v225
            if v225 then
                v213 = true
            end
        end
        local v215 = v213 and (not capturedValues1.value12)
        capturedValues1.value10 = v213
        capturedValues1.value12 = v213
        if v215 then
            capturedValues1.value29()
        end
        return
    end)
end
if v572 then
    v590 = v572.OnClientEvent
    spilledValues1.value2 = function(arg38_1, arg38_2, arg38_3, arg38_4)
        local v329, v332, v333, v334
        local v324 = arg38_1
        local v325 = arg38_2
        local v326 = (not v324)
        local v327 = arg38_3
        if v326 then
            return
        else
            if type(v325) ~= "number" or type(v327) ~= "number" then return end
            capturedValues1.value11[v324] = (v325 >= v327)
            v329 = false
            for v333, v334 in pairs(capturedValues1.value11) do
                if v334 then
                    v329 = true
                else
                    continue
                end
                break
            end
            v332 = v329 and (not capturedValues1.value12)
            capturedValues1.value10 = v329
            if v332 then
                capturedValues1.value29()
            end
            return
        end
    end
    v590:Connect(spilledValues1.value2)
end
v590 = task.spawn
spilledValues1.value2 = function()
    local v270, v271, v275, v276, v277
    local cachedCollectibleContainers = {}
    local candidates = {}
    local touchSeen = setmetatable({}, {__mode = "k"})
    local nextContainerRefresh = 0
    local activeTarget, queuedTarget
    local queuedPolicy, queuedMode
    local hybridCount, hybridInterval = 0, math.random(8, 12)
    local hybridMode = capturedValues1.value13.AutoFarmMode
    local activeHybridRandom = false
    local function selectionPolicy(ahead)
        local mode = capturedValues1.value13.AutoFarmMode
        if mode ~= hybridMode then
            hybridMode = mode
            hybridCount, hybridInterval = 0, math.random(8, 12)
        end
        if mode == "Random" then return "Random" end
        if mode == "Hybrid" then
            local count = hybridCount
            if ahead then count = activeHybridRandom and 0 or count + 1 end
            if count >= hybridInterval then return "Random" end
        end
        return "Nearest"
    end
    local continueImmediately = false
    local function isPickupPart(part)
        if not part:IsA("BasePart") then return false end
        local name = part.Name:lower()
        -- Animated CoinVisual children are decoration, not separate pickups.
        if name:find("visual", 1, true) then return false end
        local ancestor = part.Parent
        while ancestor and ancestor ~= capturedValues1.value2 do
            if ancestor.Name:lower() == "coin_server" then return false end
            ancestor = ancestor.Parent
        end
        if name == "coin_server" then return true end
        local named = name:find("coin", 1, true) or name:find("candy", 1, true)
            or name:find("sweet", 1, true) or name:find("treat", 1, true)
        return named ~= nil and part:FindFirstChild("TouchInterest") ~= nil
    end
    local function available(part)
        return part and isPickupPart(part)
            and part:IsDescendantOf(capturedValues1.value2)
            and (not touchSeen[part] or part:FindFirstChild("TouchInterest") ~= nil)
    end
    local function selectNext(origin, exclude, policy)
        local best, bestDistance, count = nil, math.huge, 0
        for _, part in ipairs(candidates) do
            if part ~= exclude and available(part) then
                if policy == "Random" then
                    count += 1
                    if math.random(count) == 1 then best = part end
                else
                    local delta = part.Position - origin
                    local distance = delta:Dot(delta)
                    if distance < bestDistance then best, bestDistance = part, distance end
                end
            end
        end
        return best
    end
    local function queueNext()
        local policy = selectionPolicy(true)
        local mode = capturedValues1.value13.AutoFarmMode
        -- Hold a random choice steady while moving; refresh it only if unavailable.
        if policy ~= "Random" or queuedPolicy ~= policy or queuedMode ~= mode
            or not available(queuedTarget) or queuedTarget == activeTarget then
            queuedTarget = selectNext(activeTarget.Position, activeTarget, policy)
        end
        queuedPolicy, queuedMode = policy, mode
    end
    -- Refresh independently while movement or pickup confirmation is waiting.
    task.spawn(function()
        while true do
            if capturedValues1.value13.EnableAutoFarm then
                local scanStartedAt = os.clock()
                local ok, err = pcall(function()
                    if os.clock() >= nextContainerRefresh then
                        cachedCollectibleContainers = {}
                        for _, item in ipairs(capturedValues1.value2:GetDescendants()) do
                            local name = item.Name:lower()
                            if name == "coincontainer" or name == "candycontainer"
                                or name == "councontainer" or name == "coinarea"
                                or (name == "barn" and (item:IsA("Model") or item:IsA("Folder"))) then
                                table.insert(cachedCollectibleContainers, item)
                            end
                        end
                        nextContainerRefresh = os.clock() + 1
                    end
                    local fresh, seen = {}, {}
                    local ignoredVisuals = 0
                    for _, container in ipairs(cachedCollectibleContainers) do
                        if container.Parent then
                            for _, part in ipairs(container:GetDescendants()) do
                                if part:IsA("BasePart") and not seen[part] then
                                    seen[part] = true
                                    if isPickupPart(part) then
                                        if part:FindFirstChild("TouchInterest") then touchSeen[part] = true end
                                        if available(part) then table.insert(fresh, part) end
                                    elseif part.Name:lower():find("visual", 1, true) then
                                        ignoredVisuals += 1
                                    end
                                end
                            end
                        end
                    end
                    candidates = fresh
                    farmTiming("scan", string.format("SCAN containers=%d pickup_parts=%d ignored_visuals=%d duration=%.1fms",
                        #cachedCollectibleContainers, #fresh, ignoredVisuals, (os.clock() - scanStartedAt) * 1000), 2)
                    if activeTarget and activeTarget.Parent then
                        queueNext()
                    end
                end)
                if not ok then
                    farmTiming("scan_error", "SCAN ERROR " .. tostring(err), 2)
                end
            else
                queuedTarget = nil
                nextContainerRefresh = 0
            end
            task.wait(0.15)
        end
    end)
    while true do
        if continueImmediately then
            continueImmediately = false
        else
            task.wait(math.max(tonumber(capturedValues1.value13.AutoFarmDelay) or 0, 0.001))
        end
        v271 = function()
            local v237, v239, v240, v241, v242, v243, v244, v245, v246, v247, v248, v249, v250, v251, v252
            local v254, v257, v259
            local v233 = capturedValues1.value8.Character
            local v230 = v233 and (v233:FindFirstChildOfClass("Humanoid"))
            local v229 = v233 and (v233:FindFirstChild("HumanoidRootPart"))
            local up3 = v229
            local roundActive = capturedValues1.value23()
            local v232 = capturedValues1.value22()
            local v229 = roundActive or (v232 ~= nil)
            local v234 = capturedValues1.value8
            local v235 = v229
            local v236 = (v234:GetAttribute("Alive"))
            if (v236 == nil) then
                v236 = true
            end
            local v238 = (not capturedValues1.value13.EnableAutoFarm)
            v229 = v238
            if not (v238) then
                v240 = (not v233)
                v238 = v240
                if not (v240) then
                    v241 = (not v230)
                    v240 = v241
                    if not (v241) then
                        v243 = (v230.Health <= 0)
                        v241 = v243
                        if not (v243) then
                            v248 = (not up3)
                            v243 = v248
                            if not (v248) then
                                v246 = (not v235)
                                v248 = v246
                                if not (v246) then
                                    v248 = (not v236) or capturedValues1.value10
                                end
                                v243 = v248
                            end
                            v241 = v243
                        end
                        v240 = v241
                    end
                    v238 = v240
                end
                v229 = v238
            end
            if v229 then
                if capturedValues1.value13.EnableAutoFarm then
                    local reason = not v233 and "character missing"
                        or not v230 and "humanoid missing"
                        or v230.Health <= 0 and "character dead"
                        or not up3 and "root part missing"
                        or not v235 and "round/map not ready"
                        or not v236 and "Alive attribute false"
                        or capturedValues1.value10 and "bag full" or "state gate"
                    farmTiming("idle", "WAIT reason=" .. reason, 2)
                end
                capturedValues1.value28()
                if v230 then
                    v230.PlatformStand = false
                end
            else
                if v232 or capturedValues1.value13.DiagnosticMode or capturedValues1.value13.EnableAutoFarm then
                    v238 = candidates
                    if ((#v238) > 0) and roundActive and capturedValues1.value13.EnableAutoFarm then
                        local selectionStartedAt = os.clock()
                        local policy = selectionPolicy(false)
                        local mode = capturedValues1.value13.AutoFarmMode
                        local usedQueue = available(queuedTarget) and queuedPolicy == policy and queuedMode == mode or false
                        local up4 = usedQueue and queuedTarget or selectNext(up3.Position, nil, policy)
                        activeHybridRandom = mode == "Hybrid" and policy == "Random"
                        if mode == "Hybrid" then
                            farmTiming("hybrid", string.format("HYBRID choice=%s nearest_pickups=%d random_after=%d", policy, hybridCount, hybridInterval))
                        end
                        if not up4 then farmTiming("stale", "WAIT cached candidates have no available candy; waiting for refresh", 2) end
                        queuedTarget = nil
                        activeTarget = up4
                        if up4 then queueNext() end
                        v242 = up4
                        v244 = v242
                        if v242 then
                            v244 = up4.Parent
                        end
                        if v244 then
                            local selectedAt = os.clock()
                            farmTiming("select", string.format("SELECT target=%s source=%s search=%.1fms handoff=%s distance=%.2f",
                                up4:GetFullName(), usedQueue and "queued" or "cache",
                                (selectedAt - selectionStartedAt) * 1000,
                                timingLogState.lastPickupAt and string.format("%.1fms", (selectedAt - timingLogState.lastPickupAt) * 1000) or "first target",
                                (up3.Position - up4.Position).Magnitude))
                            timingLogState.lastPickupAt = nil
                            if capturedValues1.value13.DiagnosticMode then
                                local gapMs = capturedValues1.value31.lastSelectedAt
                                    and (selectedAt - capturedValues1.value31.lastSelectedAt) * 1000 or 0
                                print(string.format("[VISION HUB TIMING] selected=%s gap_since_previous_selection=%.1fms candidates=%d",
                                    up4:GetFullName(), gapMs, #v238))
                            end
                            capturedValues1.value31.lastSelectedAt = selectedAt
                            capturedValues1.value31.lastTarget = up4:GetFullName()
                            if capturedValues1.value13.DiagnosticMode then
                                print(string.format("[VISION HUB] Targeting %s at %.1f studs; TouchInterest=%s",
                                    up4:GetFullName(), (up3.Position - up4.Position).Magnitude,
                                    tostring(up4:FindFirstChild("TouchInterest") ~= nil)))
                            end
                            v249 = up3
                            v241, v242, v243 = capturedValues1.value27(v249)
                            v244 = v241 and (v242 and v243)
                            if v244 then
                                v244 = (up4.Position + (Vector3.new(0, math.max(capturedValues1.value13.AutoFarmOffset, 1), 0)))
                                v249 = (up3.Position - v244).Magnitude
                                v245 = math.clamp(tonumber(capturedValues1.value13.AutoFarmSpeed) or 28, 1, 28)
                                v242.MaxVelocity = v245
                                v242.Position = up3.Position
                                v246 = math.max(v249 / v245, 0.1)
                                local hadTouchMarker = up4:FindFirstChild("TouchInterest") ~= nil
                                local function targetRemains()
                                    return up4:IsDescendantOf(capturedValues1.value2)
                                        and (not hadTouchMarker or up4:FindFirstChild("TouchInterest") ~= nil)
                                end
                                local tweenStartedAt = os.clock()
                                farmTiming("move_start", string.format("MOVE START distance=%.2f speed=%.1f planned=%.1fms", v249, v245, v246 * 1000))
                                v248 = capturedValues1.value6
                                v251 = TweenInfo.new(v246, Enum.EasingStyle.Linear)
                                v247 = v248:Create(v242, v251, {["Position"] = v244})
                                local up5 = v247
                                -- Allow the movement constraint to maintain its bounded velocity.
                                -- Clearing velocity every frame fights the constraint and slows travel.
                                local up6
                                local up7
                                up7 = (capturedValues1.value5.Heartbeat:Connect(function()
                                    local v208
                                    local v200 = not targetRemains()
                                    local v201 = v200
                                    if not (v200) then
                                        v208 = (not up4.Parent)
                                        v200 = v208
                                        v201 = v200
                                    end
                                    if v201 or not capturedValues1.value13.EnableAutoFarm
                                        or capturedValues1.value8.Character ~= v233
                                        or v230.Health <= 0 or not capturedValues1.value23() then
                                        up5:Cancel()
                                        if up7 then
                                            up7:Disconnect()
                                            up7 = nil
                                        end
                                    end
                                    return
                                end))
                                up5:Play()
                                local completedState = up5.Completed:Wait()
                                local remainingDistance = up3.Parent and (up3.Position - v244).Magnitude or -1
                                farmTiming("move_end", string.format("MOVE END state=%s elapsed=%.1fms remaining_to_goal=%.2f pickup_marker=%s",
                                    tostring(completedState), (os.clock() - tweenStartedAt) * 1000,
                                    remainingDistance, tostring(targetRemains())))
                                if capturedValues1.value13.DiagnosticMode then
                                    print(string.format("[VISION HUB TIMING] target=%s tween_result=%s tween_elapsed=%.1fms",
                                        capturedValues1.value31.lastTarget or "unknown", tostring(completedState),
                                        (os.clock() - tweenStartedAt) * 1000))
                                end
                                if completedState == Enum.PlaybackState.Cancelled and targetRemains() then
                                    up5:Destroy()
                                    if up6 then up6:Disconnect() end
                                    if up7 then up7:Disconnect() end
                                    capturedValues1.value28()
                                    return
                                end
                                up5:Destroy()
                                if up7 then
                                    up7:Disconnect()
                                    up7 = nil
                                end
                                -- Keep this target until its replicated pickup marker disappears.
                                -- On timeout, stop farming instead of silently skipping it.
                                local pickupStartedAt = os.clock()
                                local pickupDeadline = pickupStartedAt + 5
                                local nextPickupReport = pickupStartedAt + 0.5
                                while targetRemains() and os.clock() < pickupDeadline do
                                    if not capturedValues1.value13.EnableAutoFarm
                                        or capturedValues1.value8.Character ~= v233
                                        or not up3.Parent or v230.Health <= 0
                                        or not capturedValues1.value23() or capturedValues1.value10 then
                                        capturedValues1.value28()
                                        return
                                    end
                                    if os.clock() >= nextPickupReport then
                                        farmTiming("pickup_wait", string.format("PICKUP WAIT elapsed=%.1fms distance=%.2f marker_at_start=%s next_queued=%s",
                                            (os.clock() - pickupStartedAt) * 1000,
                                            (up3.Position - up4.Position).Magnitude,
                                            tostring(hadTouchMarker), tostring(available(queuedTarget) and true or false)))
                                        nextPickupReport = os.clock() + 1
                                    end
                                    capturedValues1.value5.Heartbeat:Wait()
                                end
                                if targetRemains() then
                                    farmTiming("pickup_timeout", "PICKUP TIMEOUT after 5s; stopping because collection was not confirmed")
                                    capturedValues1.value13.EnableAutoFarm = false
                                    capturedValues1.value28()
                                    if spilledValues1.value3 and spilledValues1.value3.EnableAutoFarm then
                                        spilledValues1.value3.EnableAutoFarm:SetValue(false)
                                    end
                                    warn("[VISION HUB] Pickup was not confirmed within 5 seconds; farming stopped at this target.")
                                    return
                                end
                                if mode == "Hybrid" and capturedValues1.value13.AutoFarmMode == mode then
                                    if activeHybridRandom then
                                        hybridCount, hybridInterval = 0, math.random(8, 12)
                                    else
                                        hybridCount += 1
                                    end
                                end
                                activeHybridRandom = false
                                timingLogState.lastPickupAt = os.clock()
                                farmTiming("pickup_done", string.format("PICKUP TARGET CLEARED confirmation_wait=%.1fms total_target=%.1fms next_queued=%s",
                                    (os.clock() - pickupStartedAt) * 1000, (os.clock() - selectedAt) * 1000,
                                    tostring(available(queuedTarget) and true or false)))
                                activeTarget = nil
                                -- The next candidate was selected during travel; skip the idle delay.
                                continueImmediately = true

                            end
                        end
                    else
                        farmTiming("no_candidates", string.format("WAIT reason=%s candidates=%d",
                            not roundActive and "round inactive" or "no candy found", #v238), 2)
                        capturedValues1.value28()
                        if v230 then
                            v230.PlatformStand = false
                        end
                    end
                end
            end
            return
        end
        v270 = pcall
        v275 = {v270(v271)}
        v276 = v275[2]
        if (not v275[1]) then
            farmTiming("loop_error", "LOOP ERROR " .. tostring(v276), 2)
            if capturedValues1.value13.DiagnosticMode then
                warn("[VISION HUB TIMING] farm_loop_error=" .. tostring(v276))
            end
            capturedValues1.value28()
        end
    end
end
v590(spilledValues1.value2)
v590 = capturedValues1.value8.Idled
spilledValues1.value2 = function()
    local v283
    local v279 = capturedValues1.value13
    if v279["AntiAfk"] then
        v283 = function()
            local v285 = capturedValues1.value7
            local v286 = Vector2.new(0, 0)
            v285:Button2Down(v286, capturedValues1.value2.CurrentCamera .CFrame)
            task.wait(0.5)
            v285 = capturedValues1.value7
            v286 = Vector2.new(0, 0)
            v285:Button2Up(v286, capturedValues1.value2.CurrentCamera.CFrame)

            return
        end
        pcall(v283)
    end
    return
end
v590:Connect(spilledValues1.value2)
local function loadRemoteModule(url)
    if type(game.HttpGet) ~= "function" or type(loadstring) ~= "function" then
        return nil, "HTTP or loadstring unavailable"
    end
    local requestOk, source = pcall(function() return game:HttpGet(url) end)
    if not requestOk or type(source) ~= "string" then return nil, "HTTP request failed" end
    local compileOk, chunk = pcall(loadstring, source)
    if not compileOk or type(chunk) ~= "function" then return nil, "module did not compile" end
    local runOk, module = pcall(chunk)
    if not runOk then return nil, "module initialization failed" end
    return module
end

local v590, libraryError = loadRemoteModule("https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/Library.lua")
if type(v590) ~= "table" then
    warn("VISION HUB: UI library unavailable: " .. tostring(libraryError))
    return
else
    local saveManager, saveError = loadRemoteModule("https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/addons/SaveManager.lua")
    local themeManager, themeError = loadRemoteModule("https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/addons/ThemeManager.lua")
    if type(saveManager) ~= "table" or type(themeManager) ~= "table" then
        warn("VISION HUB: save/theme add-on unavailable: " .. tostring(saveError or themeError))
        return
    end
    spilledValues1.value1 = saveManager
    spilledValues1.value2 = themeManager
    spilledValues1.value3 = v590.Options
    local up69 = spilledValues1.value3
    spilledValues1.value3 = v590.Toggles
    spilledValues1.value4 = game.PlaceId
    spilledValues1.value5 = game.JobId
    if (not ({[142823291] = true, [335132309] = true, [636649648] = true})[spilledValues1.value4]) then
        spilledValues1.value7 = {["Title"] = "VISION HUB", ["Description"] = "Unsupported Game", ["Time"] = 5}
        v590:Notify(spilledValues1.value7)
        return
    else
        local executorName = (type(identifyexecutor) == "function" and identifyexecutor()) or "Unknown Executor"
        spilledValues1.value11 = "Created by: orialdev | " .. tostring(executorName)
        spilledValues1.value15 = UDim2.fromOffset(50, 50)
        spilledValues1.value16 = Enum.Font.Gotham
        spilledValues1.value19 = UDim2.fromOffset(100, 100)
        spilledValues1.value21 = UDim2.fromOffset (500, 500)
        spilledValues1.value22 = Enum.KeyCode.RightShift
        spilledValues1.value23 = UDim2.fromScale (1, 1)
        spilledValues1.value6 = v590.CreateWindow
        spilledValues1.value24 = {["ToggleWindow"] = true, ["TabSwitch"] = true, ["Groupbox"] = true, ["Dropdown"] = true, ["KeyPicker"] = true}
        spilledValues1.value6 = spilledValues1.value6(v590, {["Title"] = "VISION HUB", ["Footer"] = spilledValues1.value11, ["Icon"] = "rbxassetid://125328263655945", ["IconSize"] = spilledValues1.value15, ["BackgroundImage"] = nil, ["Font"] = spilledValues1.value16, ["CornerRadius"] = 4, ["Position"] = spilledValues1.value19, ["Size"] = spilledValues1.value21, ["Center"] = true, ["AutoShow"] = true, ["Resizable"] = true, ["UnlockMouseWhileOpen"] = true, ["ToggleKeybind"] = spilledValues1.value22, ["NotifySide"] = "Right", ["ShowCustomCursor"] = false, ["ShowMobileButtons"] = true, ["MobileButtonsSide"] = "Left", ["DisableSearch"] = false, ["SearchbarSize"] = spilledValues1.value23, ["GlobalSearch"] = false, ["EnableSidebarResize"] = true, ["EnableCompacting"] = true, ["DisableCompactingSnap"] = false, ["SidebarCompacted"] = true, ["MinContainerWidth"] = 256, ["MinSidebarWidth"] = 128, ["SidebarCompactWidth"] = 48, ["SidebarCollapseThreshold"] = 0.5, ["CompactWidthActivation"] = 128, ["Animations"] = spilledValues1.value24, ["TabTransitionTime"] = .22, ["TabSwipeOffset"] = 26, ["TabSwipeFrom"] = "bottom"})
        spilledValues1.value9 = spilledValues1.value6:AddTab({["Name"] = "Auto Farm", ["Icon"] = "coins"})
        spilledValues1.value11 = spilledValues1.value6:AddTab({["Name"] = "Settings", ["Icon"] = "settings"})
        spilledValues1.value7 = {["AutoFarm"] = spilledValues1.value9, ["Settings"] = spilledValues1.value11}
        spilledValues1.value9 = spilledValues1.value7.AutoFarm:AddLeftGroupbox("Auto Farm", "coins")
        spilledValues1.value10 = spilledValues1.value7.AutoFarm:AddRightGroupbox("Utilities", "shield")
        spilledValues1.value8 = spilledValues1.value9.AddToggle
        spilledValues1.value15 = capturedValues1.value13.EnableAutoFarm
        spilledValues1.value8(spilledValues1.value9, "EnableAutoFarm", {["Text"] = "Enable Auto Farm", ["Default"] = spilledValues1.value15})
        spilledValues1.value8 = spilledValues1.value3.EnableAutoFarm
        spilledValues1.value12 = function(arg6_1)
            capturedValues1.value13.EnableAutoFarm = arg6_1
            if arg6_1 then
                capturedValues1.value26()
            end
            return
        end
        spilledValues1.value8:OnChanged(spilledValues1.value12)
        spilledValues1.value8 = spilledValues1.value9.AddDropdown
        spilledValues1.value15 = {"Nearest", "Random", "Hybrid"}
        spilledValues1.value8(spilledValues1.value9, "AutoFarmMode", {["Text"] = "Farm Mode", ["Values"] = spilledValues1.value15, ["Default"] = 1, ["Multi"] = false})
        up69.AutoFarmMode:OnChanged(function()
            capturedValues1.value13.AutoFarmMode = up69.AutoFarmMode.Value
            return
        end)
        spilledValues1.value17 = capturedValues1.value13.AutoFarmSpeed
        spilledValues1.value9:AddSlider("AutoFarmSpeed", {["Text"] = "Farm Speed", ["Min"] = 1, ["Max"] = 28, ["Default"] = spilledValues1.value17, ["Rounding"] = 0})
        up69.AutoFarmSpeed:OnChanged(function(arg8_1)
            capturedValues1.value13.AutoFarmSpeed = math.clamp(tonumber(arg8_1) or 28, 1, 28)
            return
        end)
        spilledValues1.value17 = capturedValues1.value13.AutoFarmOffset
        spilledValues1.value9:AddSlider("AutoFarmOffset", {["Text"] = "Y Offset", ["Min"] = -6, ["Max"] = 6, ["Default"] = spilledValues1.value17, ["Rounding"] = 1})
        spilledValues1.value8 = up69.AutoFarmOffset
        spilledValues1.value12 = function(arg9_1)
            capturedValues1.value13.AutoFarmOffset = arg9_1
            return
        end
        spilledValues1.value8:OnChanged(spilledValues1.value12)
        spilledValues1.value17 = capturedValues1.value13.AutoFarmDelay
        spilledValues1.value9:AddSlider("AutoFarmDelay", {["Text"] = "Farm Delay", ["Min"] = 0, ["Max"] = 0.1, ["Default"] = spilledValues1.value17, ["Rounding"] = 2})
        spilledValues1.value8 = up69.AutoFarmDelay
        spilledValues1.value12 = function(arg10_1)
            capturedValues1.value13.AutoFarmDelay = arg10_1
            return
        end
        spilledValues1.value8:OnChanged(spilledValues1.value12)
        spilledValues1.value10:AddToggle("TimingLogs", {Text = "Candy Timing Logs", Default = true})
        spilledValues1.value3.TimingLogs:OnChanged(function(enabled)
            capturedValues1.value13.TimingLogs = enabled
            if enabled then farmTiming("enabled", "Timing logs enabled: SCAN, SELECT, MOVE, PICKUP and WAIT show where time is spent") end
        end)
        spilledValues1.value10:AddButton("Print Recent Timing Logs", function()
            print("[VISION TIMING] Recent log entries:")
            for _, entry in ipairs(timingLogState.entries) do print(entry) end
        end)
        spilledValues1.value10:AddToggle("DiagnosticMode", {Text = "Candy Diagnostics", Default = false})
        spilledValues1.value3.DiagnosticMode:OnChanged(function(enabled)
            capturedValues1.value13.DiagnosticMode = enabled
            capturedValues1.value30.lastMessage = ""
            if enabled then
                print("[VISION HUB] Candy diagnostics enabled. Check the executor/Roblox console for status.")
            end
        end)
        spilledValues1.value15 = capturedValues1.value13.AutoResetOnFull
        spilledValues1.value10:AddToggle("AutoResetOnFull", {["Text"] = "Auto Reset on Full Bag", ["Default"] = spilledValues1.value15})
        spilledValues1.value3.AutoResetOnFull:OnChanged(function(arg11_1)
            capturedValues1.value13.AutoResetOnFull = arg11_1
            return
        end)
        spilledValues1.value8 = spilledValues1.value10.AddToggle
        spilledValues1.value15 = capturedValues1.value13.AutoEndRound
        spilledValues1.value8(spilledValues1.value10, "AutoEndRound", {["Text"] = "Auto End Round", ["Default"] = spilledValues1.value15})
        spilledValues1.value12 = function(arg12_1)
            capturedValues1.value13.AutoEndRound = arg12_1
            return
        end
        spilledValues1.value3.AutoEndRound:OnChanged(spilledValues1.value12)
        spilledValues1.value15 = capturedValues1.value13.AntiAfk
        spilledValues1.value10:AddToggle("AntiAfk", {["Text"] = "Anti AFK", ["Default"] = spilledValues1.value15})
        spilledValues1.value8 = spilledValues1.value3.AntiAfk
        spilledValues1.value12 = function(arg13_1)
            capturedValues1.value13.AntiAfk = arg13_1
            return
        end
        spilledValues1.value8:OnChanged(spilledValues1.value12)
        spilledValues1.value8 = spilledValues1.value10.AddToggle
        spilledValues1.value15 = capturedValues1.value13.AntiFling
        spilledValues1.value8(spilledValues1.value10, "AntiFling", {["Text"] = "Anti Fling", ["Default"] = spilledValues1.value15})
        spilledValues1.value12 = function(arg14_1)
            capturedValues1.value13.AntiFling = arg14_1
            return
        end
        spilledValues1.value3.AntiFling:OnChanged(spilledValues1.value12)
        spilledValues1.value2:SetLibrary(v590)
        spilledValues1.value1:SetLibrary(v590)
        spilledValues1.value13 = Color3.fromRGB(255, 255, 255)
        spilledValues1.value15 = Color3.fromRGB(15, 15, 25)
        spilledValues1.value14 = Color3.fromRGB(45, 110, 255)
        spilledValues1.value17 = Color3.fromRGB(10, 10, 15)
        spilledValues1.value20 = Color3.fromRGB(35, 35, 45)
        spilledValues1.value19 = Enum.Font
        spilledValues1.value8 = spilledValues1.value2.SetDefaultTheme
        spilledValues1.value18 = spilledValues1.value19.Gotham
        spilledValues1.value8(spilledValues1.value2, {["FontColor"] = spilledValues1.value13, ["MainColor"] = spilledValues1.value15, ["AccentColor"] = spilledValues1.value14, ["BackgroundColor"] = spilledValues1.value17, ["OutlineColor"] = spilledValues1.value20, ["FontFace"] = spilledValues1.value18})
        spilledValues1.value1:IgnoreThemeSettings()
        spilledValues1.value1:SetIgnoreIndexes({"MenuKeybind"})
        spilledValues1.value2:SetFolder("Autofarm")
        spilledValues1.value1:SetFolder("Autofarm/MM2")
        spilledValues1.value1:BuildConfigSection(spilledValues1.value7.Settings)
        spilledValues1.value11 = spilledValues1.value7.Settings
        spilledValues1.value2:ApplyToTab(spilledValues1.value11)
        pcall(function() spilledValues1.value1:LoadAutoloadConfig() end)
        return
    end
end
-- Assumptions and dependencies:
-- * This is a client-side executor script, not a Roblox Studio LocalScript. It uses executor-only APIs
--   such as loadstring, game:HttpGet, identifyexecutor, and (in original code) VirtualUser.
-- * MM2 place IDs, remote names, event payload shapes, map container names, and coin TouchInterest
--   behavior are inferred from the original script and are not verified against a live game.
-- * Obsidian Library.lua, SaveManager.lua, and ThemeManager.lua are fetched from GitHub at runtime;
--   network access, executor HTTP permissions, and compatibility with the current versions are required.
-- * Coin collection now relies on the character physically touching coins. No GetCoin/FireServer
--   remote invocation or executor-only synthetic touch is used.
