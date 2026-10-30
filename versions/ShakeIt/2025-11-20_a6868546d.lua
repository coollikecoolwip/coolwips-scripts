local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

local self = {} -- encapsulation of variables

self.originalRot = nil
self.char = nil
self.hrp = nil
self.currentTrack = nil
self.isPlaying = false
self.toggleButton = nil
self.refreshButton = nil

local function loadAnimation(character)
    local humanoid = character:WaitForChild("Humanoid")
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://136720812089001"
    return animator:LoadAnimation(anim)
end

local function rotateCharacter(character, degrees)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(degrees), 0)
    end
end

local function startAnimation()
    if self.char and self.currentTrack and not self.currentTrack.IsPlaying then
        self.currentTrack.Looped = true
        self.currentTrack.Priority = Enum.AnimationPriority.Action
        self.currentTrack:Play(0, 99)
        self.currentTrack:AdjustSpeed(1)
        rotateCharacter(self.char, 180)
        self.isPlaying = true
        if self.toggleButton then
            self.toggleButton.Text = "Stop Animation" -- Corrected
            self.toggleButton.BackgroundColor3 = Color3.fromRGB(255, 70, 70) -- Corrected
        end
        print("Animation Started")
    end
end

local function stopAnimation()
    if self.currentTrack and self.currentTrack.IsPlaying then
        self.currentTrack:Stop()
        self.isPlaying = false
        if self.toggleButton then
            self.toggleButton.Text = "Start Animation" -- Corrected
            self.toggleButton.BackgroundColor3 = Color3.fromRGB(70, 200, 70) -- Corrected
        end
        print("Animation Stopped")
    end
end

local function refreshAnimation()
    print("Refreshing animation system...")
    stopAnimation()
    if self.char then
        self.currentTrack = loadAnimation(self.char)
    end
    self.isPlaying = false
    print("Animation system refreshed. Ready to start again.")
end

local function resetAnimationSystem()
    stopAnimation()
    self.char = player.Character
    if self.char then
        self.hrp = self.char:FindFirstChild("HumanoidRootPart")
        if self.hrp then
            self.originalRot = self.hrp.CFrame - self.hrp.Position
        end
        self.currentTrack = loadAnimation(self.char)
    end
    self.isPlaying = false
end

-- UI Setup (Create Buttons Once)
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = playerGui:WaitForChild("ScreenGui") or Instance.new("ScreenGui", playerGui)
screenGui.IgnoreGuiInset = true -- Allow GUI to overlap the top bar

-- Wait for the screenGui to be fully loaded

self.toggleButton = Instance.new("TextButton")
self.toggleButton.Size = UDim2.new(0, 140, 0, 40)
self.toggleButton.AnchorPoint = Vector2.new(1, 0) -- Anchor to right
self.toggleButton.Position = UDim2.new(1, -150, 0, 10)
self.toggleButton.Text = "Start Animation"
self.toggleButton.BackgroundColor3 = Color3.fromRGB(70, 200, 70)
self.toggleButton.TextColor3 = Color3.new(1, 1, 1)
self.toggleButton.Parent = screenGui

self.refreshButton = Instance.new("TextButton")
self.refreshButton.Size = UDim2.new(0, 140, 0, 40)
self.refreshButton.AnchorPoint = Vector2.new(1, 0) -- Anchor to right
self.refreshButton.Position = UDim2.new(1, -150, 0, 60)
self.refreshButton.Text = "Refresh Animation"
self.refreshButton.BackgroundColor3 = Color3.fromRGB(70, 70, 200)
self.refreshButton.TextColor3 = Color3.new(1, 1, 1)
self.refreshButton.Parent = screenGui

self.toggleButton.MouseButton1Click:Connect(function()
    if self.isPlaying then
        stopAnimation()
    else
        startAnimation()
    end
end)

self.refreshButton.MouseButton1Click:Connect(function()
    refreshAnimation()
end)

-- Keybinds
local function handleInput(input, gameProcessedEvent)
    if gameProcessedEvent then return end

    if input.KeyCode == Enum.KeyCode.Z then  -- Change 'Z' to your desired key
        if self.isPlaying then
            stopAnimation()
        else
            startAnimation()
        end
    elseif input.KeyCode == Enum.KeyCode.X then  -- Change 'X' to your desired key
        refreshAnimation()
    end
end

UserInputService.InputBegan:Connect(handleInput)

-- Character Added Event
local function onCharacterAdded(character)
    resetAnimationSystem()
end

-- Initial Setup and Respawn Handling
player.CharacterAdded:Connect(onCharacterAdded)

-- Initialize the animation when the character first spawns
resetAnimationSystem()
