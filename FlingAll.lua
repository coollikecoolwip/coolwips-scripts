local Targets = {"All"} -- "All", "Target Name", "arian_was_here"

local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local AllBool = false

local GetPlayer = function(Name)
    Name = Name:lower()
    if Name == "all" or Name == "others" then
        AllBool = true
        return
    elseif Name == "random" then
        local GetPlayers = Players:GetPlayers()
        if table.find(GetPlayers,Player) then table.remove(GetPlayers,table.find(GetPlayers,Player)) end
        return GetPlayers[math.random(#GetPlayers)]
    elseif Name ~= "random" and Name ~= "all" and Name ~= "others" then
        for _,x in next, Players:GetPlayers() do
            if x ~= Player then
                if x.Name:lower():match("^"..Name) then
                    return x;
                elseif x.DisplayName:lower():match("^"..Name) then
                    return x;
                end
            end
        end
    else
        return
    end
end

local Message = function(_Title, _Text, Time)
    game:GetService("StarterGui"):SetCore("SendNotification", {Title = _Title, Text = _Text, Duration = Time})
end

local SkidFling = function(TargetPlayer)
    local Character = Player.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart

    local TCharacter = TargetPlayer.Character
    local THumanoid
    local TRootPart
    local THead
    local Accessory
    local Handle

    if TCharacter:FindFirstChildOfClass("Humanoid") then
        THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    end
    if THumanoid and THumanoid.RootPart then
        TRootPart = THumanoid.RootPart
    end
    if TCharacter:FindFirstChild("Head") then
        THead = TCharacter.Head
    end
    if TCharacter:FindFirstChildOfClass("Accessory") then
        Accessory = TCharacter:FindFirstChildOfClass("Accessory")
    end
    if Accessory and Accessory:FindFirstChild("Handle") then
        Handle = Accessory.Handle
    end

    if Character and Humanoid and RootPart then
        if RootPart.Velocity.Magnitude < 50 then
            getgenv().OldPos = RootPart.CFrame
        end
        if THumanoid and THumanoid.Sit and not AllBool then
            return Message("Error Occurred", "Targeting is sitting", 5) -- u can remove dis part if u want lol
        end
        if THead then
            workspace.CurrentCamera.CameraSubject = THead
        elseif not THead and Handle then
            workspace.CurrentCamera.CameraSubject = Handle
        elseif THumanoid and TRootPart then
            workspace.CurrentCamera.CameraSubject = THumanoid
        end
        if not TCharacter:FindFirstChildWhichIsA("BasePart") then
            return
        end
        
        local FPos = function(BasePart, Pos, Ang)
            RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
            Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
            RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
            RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
        end
        
        local SFBasePart = function(BasePart)
            local TimeToWait = 2
            local Time = tick()
            local Angle = 0

            repeat
                if RootPart and THumanoid then
                    if BasePart.Velocity.Magnitude < 50 then
                        Angle = Angle + 100

                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(2.25, 1.5, -2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(-2.25, -1.5, 2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection,CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection,CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                    else
                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        
                        FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, -1.5, -TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(0, 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, -1.5 ,0), CFrame.Angles(math.rad(-90), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                        task.wait()
                    end
                else
                    break
                end
            until BasePart.Velocity.Magnitude > 500 or BasePart.Parent ~= TargetPlayer.Character or TargetPlayer.Parent ~= Players or not TargetPlayer.Character == TCharacter or THumanoid.Sit or Humanoid.Health <= 0 or tick() > Time + TimeToWait
        end
        
        workspace.FallenPartsDestroyHeight = 0/0
        
        local BV = Instance.new("BodyVelocity")
        BV.Name = "EpixVel"
        BV.Parent = RootPart
        BV.Velocity = Vector3.new(9e8, 9e8, 9e8)
        BV.MaxForce = Vector3.new(1/0, 1/0, 1/0)
        
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
        
        if TRootPart and THead then
            if (TRootPart.CFrame.p - THead.CFrame.p).Magnitude > 5 then
                SFBasePart(THead)
            else
                SFBasePart(TRootPart)
            end
        elseif TRootPart and not THead then
            SFBasePart(TRootPart)
        elseif not TRootPart and THead then
            SFBasePart(THead)
        elseif not TRootPart and not THead and Accessory and Handle then
            SFBasePart(Handle)
        else
            return Message("Error Occurred", "Target is missing everything", 5)
        end
        
        BV:Destroy()
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        workspace.CurrentCamera.CameraSubject = Humanoid
        
    else
        return Message("Error Occurred", "Random error", 5)
    end
end

if not Welcome then Message("Script by Coollikecoolwip", "Enjoy!", 5) end
getgenv().Welcome = true
if Targets[1] then for _,x in next, Targets do GetPlayer(x) end else return end

--GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MyGui"
screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false -- Keep GUI on respawn
screenGui.Enabled = false --GUI is default toggled off

local guiFrame = Instance.new("Frame")
guiFrame.Size = UDim2.new(0, 375, 0, 400) --Pops up in the top right corner -- increased size
guiFrame.Position = UDim2.new(1, -385, 0, 10) --Pops up in the top right corner -- increased size
guiFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
guiFrame.BorderSizePixel = 0
guiFrame.Active = true -- Allow dragging
guiFrame.Draggable = true
guiFrame.Parent = screenGui

-- // Blacklist Player List Label
local blacklistPlayerListLabel = Instance.new("TextLabel")
blacklistPlayerListLabel.Size = UDim2.new(0, 200, 0, 20)
blacklistPlayerListLabel.Position = UDim2.new(0.5, -100, 0, 10) -- Adjusted position
blacklistPlayerListLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
blacklistPlayerListLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
blacklistPlayerListLabel.Text = "Select Players to Blacklist:"
blacklistPlayerListLabel.BorderSizePixel = 0
blacklistPlayerListLabel.Parent = guiFrame

-- // Scrolling Frame for Player List
local playerListFrame = Instance.new("ScrollingFrame")
playerListFrame.Size = UDim2.new(0, 355, 0, 250) -- Adjusted size -- increased size
playerListFrame.Position = UDim2.new(0.5, -177.5, 0, 40) -- Adjusted position -- increased size
playerListFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
playerListFrame.BorderSizePixel = 0
playerListFrame.ScrollBarThickness = 12
playerListFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Initialized CanvasSize
playerListFrame.Parent = guiFrame

-- // UIListLayout for Player List
local playerListLayout = Instance.new("UIListLayout")
playerListLayout.SortOrder = Enum.SortOrder.Name
playerListLayout.Padding = UDim.new(0, 2)
playerListLayout.Parent = playerListFrame

-- // Refresh Button
local refreshButton = Instance.new("TextButton")
refreshButton.Size = UDim2.new(0, 75, 0, 30)
refreshButton.Position = UDim2.new(0.5, -117.5, 0, 300) -- Adjusted position
refreshButton.Text = "Refresh"
refreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
refreshButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
refreshButton.BorderSizePixel = 0
refreshButton.Parent = guiFrame

-- // Fling All Button
local flingAllButton = Instance.new("TextButton")
flingAllButton.Size = UDim2.new(0, 75, 0, 30)
flingAllButton.Position = UDim2.new(0.5, 42.5, 0, 300) -- Adjusted position
flingAllButton.Text = "Fling All"
flingAllButton.TextColor3 = Color3.fromRGB(255, 255, 255)
flingAllButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
flingAllButton.BorderSizePixel = 0
flingAllButton.Parent = guiFrame

-- Loop Fling All Button (continuous fling)
local loopFlingAllButton = Instance.new("TextButton")
loopFlingAllButton.Name = "LoopFlingAllButton"
loopFlingAllButton.Parent = guiFrame
loopFlingAllButton.Size = UDim2.new(0, 75, 0, 30)
loopFlingAllButton.Position = UDim2.new(0.5, -42.5, 0, 340) -- Adjusted position below Fling All
loopFlingAllButton.Text = "Loop Fling All"
loopFlingAllButton.TextColor3 = Color3.fromRGB(255, 255, 255)
loopFlingAllButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
loopFlingAllButton.BorderSizePixel = 0

local BlacklistedUserIds = {} -- Initialize the blacklist table

local function UpdatePlayerList()
    table.insert(BlacklistedUserIds, Player.UserId)
	-- Clear existing buttons/checkboxes in playerListFrame
    for _, child in ipairs(playerListFrame:GetChildren()) do
        if child:IsA("Frame") then -- Changed to Frame since each player entry will now be a Frame
            child:Destroy()
        end
    end

    local Players = game:GetService("Players"):GetPlayers()
    for _, player in ipairs(Players) do
       -- Create a frame for each player entry
        local playerFrame = Instance.new("Frame")
        playerFrame.Size = UDim2.new(1, 0, 0, 25)
        playerFrame.BackgroundColor3 = Color3.fromRGB(80,80,80)
        playerFrame.BorderSizePixel = 0
        playerFrame.Parent = playerListFrame

        -- Create the player button
        local playerButton = Instance.new("TextButton")
        playerButton.Size = UDim2.new(0.5, 0, 1, 0) -- Takes up 50% of the frame
        playerButton.Position = UDim2.new(0,0,0,0)
        playerButton.Text = player.DisplayName .. " (@" .. player.Name .. ")"
        playerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        playerButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        playerButton.BorderSizePixel = 0
        playerButton.Parent = playerFrame
        playerButton.TextXAlignment = Enum.TextXAlignment.Left
        playerButton.TextScaled = true -- Auto resize player names

        local function UpdateButtonColor()
            if table.find(BlacklistedUserIds, player.UserId) then
                playerButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Red for blacklisted
            else
                playerButton.BackgroundColor3 = Color3.fromRGB(0, 100, 0) -- Dark green for flingable
            end
        end

        UpdateButtonColor() --Set initial color

        playerButton.MouseButton1Click:Connect(function()
            local userId = player.UserId
            if table.find(BlacklistedUserIds, userId) then
                -- Remove from blacklist
                for i, v in ipairs(BlacklistedUserIds) do
                    if v == userId then
                        table.remove(BlacklistedUserIds, i)
                        break
                    end
                end
            else
                -- Add to blacklist
                table.insert(BlacklistedUserIds, userId)
            end
            UpdateButtonColor()
        end)

        -- Create the "Fling One" button
        local flingOneButton = Instance.new("TextButton")
        flingOneButton.Size = UDim2.new(0.4, 0, 0.8, 0)  -- Takes up 40% of the frame, 80% height
        flingOneButton.Position = UDim2.new(0.55, 0, 0.1, 0)  -- Centered Horizontally
        flingOneButton.Text = "Fling"
        flingOneButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        flingOneButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        flingOneButton.BorderSizePixel = 0
        flingOneButton.Parent = playerFrame
        flingOneButton.TextScaled = true -- Make the text scale

        flingOneButton.MouseButton1Click:Connect(function()
            if not table.find(BlacklistedUserIds, player.UserId) then
                SkidFling(player)
            else
                Message("Error Occurred", "This user is blacklisted!", 5)
            end
        end)
    end

    -- Update CanvasSize of the scrolling frame
    playerListFrame.CanvasSize = UDim2.new(0, 0, 0, (#Players-1) * 27) --Adjust the value 27 according to the height of each button + padding
end

refreshButton.MouseButton1Click:Connect(UpdatePlayerList) -- Connect refresh button

flingAllButton.MouseButton1Click:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Player and not table.find(BlacklistedUserIds, player.UserId) then
            SkidFling(player)
        end
    end
end)

-- Loop Fling Functionality
local FlingAllLoopEnabled = false

loopFlingAllButton.MouseButton1Click:Connect(function()
    FlingAllLoopEnabled = not FlingAllLoopEnabled
    if FlingAllLoopEnabled then
        loopFlingAllButton.Text = "Stop Loop Fling"
        loopFlingAllButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)

        task.spawn(function()
            while FlingAllLoopEnabled do
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= Player and not table.find(BlacklistedUserIds, player.UserId) then
                        SkidFling(player)
                    end
                    task.wait(0.1) -- Short delay to prevent rate limits
                end
                task.wait(1) -- Delay between loops
            end
            loopFlingAllButton.Text = "Loop Fling All"
            loopFlingAllButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        end)
    else
        loopFlingAllButton.Text = "Loop Fling All"
        loopFlingAllButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)

        -- Return to original position only when loop is stopped
        local Character = Player.Character
        local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
        local RootPart = Humanoid and Humanoid.RootPart

        if RootPart then
            RootPart.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
            Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, .5, 0))
            Humanoid:ChangeState("GettingUp")
            table.foreach(Character:GetChildren(), function(_, x)
                if x:IsA("BasePart") then
                    x.Velocity, x.RotVelocity = Vector3.new(), Vector3.new()
                end
            end)
            task.wait()
        end
    end
end)

-- Modify the SkidFling loop to remove the original target functionality:


UpdatePlayerList() -- Initial population of the player list

-- Make the GUI draggable
guiFrame.Active = true
guiFrame.Draggable = true

-- GUI Toggle Functionality
local UserInputService = game:GetService("UserInputService")

local function ToggleGUI()
    screenGui.Enabled = not screenGui.Enabled
end

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if input.KeyCode == Enum.KeyCode.RightControl then
        ToggleGUI()
    end
end)

-- Auto-refresh every second
while true do
    task.wait(1)
    UpdatePlayerList()
end
