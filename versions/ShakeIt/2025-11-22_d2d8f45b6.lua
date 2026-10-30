-- Roblox Animation Controller - Universal + Styled UI

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

-- State table
local state = {
    char = nil,
    hrp = nil,
    currentTrack = nil,
    isPlaying = false,
    toggleButton = nil,
    refreshButton = nil,
}

-------------------------
-- Utility Functions

-------------------------

local function loadAnimation(character)
    local humanoid = character:WaitForChild("Humanoid")
    local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://136720812089001" -- Replace with your animation ID
    return animator:LoadAnimation(anim)
end

local function rotateCharacter(character, degrees)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(degrees), 0)
    end
end

-------------------------
-- Animation Controls

-------------------------

local function startAnimation()
    if state.char and state.currentTrack and not state.currentTrack.IsPlaying then
        state.currentTrack.Looped = true
        state.currentTrack.Priority = Enum.AnimationPriority.Action
        state.currentTrack:Play(0, 99)
        state.currentTrack:AdjustSpeed(1)
        rotateCharacter(state.char, 180)
        state.isPlaying = true
        if state.toggleButton then
            state.toggleButton.Text = "⏹ Stop Animation"
            state.toggleButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
        end
        print("Animation Started")
    end
end

local function stopAnimation()
    if state.currentTrack and state.currentTrack.IsPlaying then
        state.currentTrack:Stop()
        state.isPlaying = false
        if state.toggleButton then
            state.toggleButton.Text = "▶ Start Animation"
            state.toggleButton.BackgroundColor3 = Color3.fromRGB(70, 200, 70)
        end
        print("Animation Stopped")
    end
end

local function refreshAnimation()
    print("Refreshing animation system...")
    stopAnimation()
    if state.char then
        state.currentTrack = loadAnimation(state.char)
    end
    state.isPlaying = false
end

local function resetAnimationSystem()
    stopAnimation()
    state.char = player.Character or player.CharacterAdded:Wait()
    state.hrp = state.char:FindFirstChild("HumanoidRootPart")
    state.currentTrack = loadAnimation(state.char)
end

-------------------------
-- UI Creation

-------------------------

local function createUI()
    local playerGui = player:WaitForChild("PlayerGui")

    -- Remove old UI if exists
    local existing = playerGui:FindFirstChild("AnimationControllerGUI")
    if existing then existing:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AnimationControllerGUI"
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = playerGui

    local function createButton(text, posY, color)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 160, 0, 50)
        btn.Position = UDim2.new(1, -180, 0, posY)
        btn.AnchorPoint = Vector2.new(1, 0)
        btn.BackgroundColor3 = color
        btn.Text = text
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 16

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = btn

        local shadow = Instance.new("UIStroke")
        shadow.Thickness = 2
        shadow.Color = Color3.fromRGB(20, 20, 20)
        shadow.Parent = btn

        btn.Parent = screenGui

        return btn
    end

    state.toggleButton = createButton("▶ Start Animation", 10, Color3.fromRGB(70, 200, 70))
    state.refreshButton = createButton("🔄 Refresh Animation", 65, Color3.fromRGB(70, 70, 200))

    state.toggleButton.MouseButton1Click:Connect(function()
        if state.isPlaying then
            stopAnimation()
        else
            startAnimation()
        end
    end)

    state.refreshButton.MouseButton1Click:Connect(function()
        refreshAnimation()
    end)
end

-------------------------
-- Keybinds

-------------------------

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Z then
        if state.isPlaying then stopAnimation() else startAnimation() end
    elseif input.KeyCode == Enum.KeyCode.X then
        refreshAnimation()
    end
end)

-------------------------
-- Character Handling

-------------------------

player.CharacterAdded:Connect(function()
    resetAnimationSystem()
    createUI()
end)

-- Initial setup
resetAnimationSystem()
createUI()
