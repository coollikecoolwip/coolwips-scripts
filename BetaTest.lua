--// Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Teams = game:GetService("Teams")
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

--// Settings
local aimbotFOV = 300

--// States
local firstPersonAimbotEnabled = false
local thirdPersonAimbotEnabled = false
local triggerbotEnabled = false
local aimbotMode = "closest" -- "closest" | "constant"
local currentTarget = nil

--// Blacklists
local blacklisted = {}
local blacklistedTeams = {}
local lastVisibleTargets = {}

--// GUI Root
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "UniversalAimbotGUI"
ScreenGui.ResetOnSpawn = false

--// Main Control Frame
local frame = Instance.new("Frame", ScreenGui)
frame.Size = UDim2.new(0, 220, 0, 200)
frame.Position = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.BorderSizePixel = 0
frame.Active, frame.Draggable = true, true

--// Toggle Button Creator
local function createToggle(text, y, getter, setter)
    local b = Instance.new("TextButton", frame)
    b.Size = UDim2.new(0,200,0,30)
    b.Position = UDim2.new(0,10,0,y)
    b.Font = Enum.Font.SourceSansBold
    b.TextScaled = true
    b.TextColor3 = Color3.new(1,1,1)

    local function refresh()
        local on = getter()
        b.Text = text .. (on and ": ON" or ": OFF")
        b.BackgroundColor3 = on and Color3.fromRGB(50,200,50) or Color3.fromRGB(150,50,50)
    end

    b.MouseButton1Click:Connect(function()
        setter(not getter())
        refresh()
    end)

    refresh()
    return refresh
end

local update1P = createToggle("1P Aimbot", 10, function() return firstPersonAimbotEnabled end, function(v) firstPersonAimbotEnabled=v end)
local updateTrig = createToggle("Triggerbot (Y)", 50, function() return triggerbotEnabled end, function(v) triggerbotEnabled=v end)
local update3P = createToggle("3P Aimbot", 90, function() return thirdPersonAimbotEnabled end, function(v) thirdPersonAimbotEnabled=v end)

--// Mode Button
local modeBtn = Instance.new("TextButton", frame)
modeBtn.Size = UDim2.new(0,200,0,30)
modeBtn.Position = UDim2.new(0,10,0,130)
modeBtn.Font = Enum.Font.SourceSansBold
modeBtn.TextScaled = true
modeBtn.TextColor3 = Color3.new(1,1,1)
modeBtn.BackgroundColor3 = Color3.fromRGB(70,150,200)

local function updateModeText()
    modeBtn.Text = "Mode: " .. (aimbotMode == "constant" and "Constant" or "Closest")
end

modeBtn.MouseButton1Click:Connect(function()
    aimbotMode = (aimbotMode == "closest") and "constant" or "closest"
    currentTarget = nil
    updateModeText()
end)
updateModeText()

--// Refresh Button
local refreshBtn = Instance.new("TextButton", frame)
refreshBtn.Size = UDim2.new(0,200,0,30)
refreshBtn.Position = UDim2.new(0,10,0,170)
refreshBtn.Text = "Refresh Blacklist"
refreshBtn.Font = Enum.Font.SourceSansBold
refreshBtn.TextScaled = true
refreshBtn.TextColor3 = Color3.new(1,1,1)
refreshBtn.BackgroundColor3 = Color3.fromRGB(50,150,200)

--// Blacklist Window
local bb = Instance.new("Frame", ScreenGui)
bb.Size = UDim2.new(0,440,0,250)
bb.Position = UDim2.new(0.5,100,0.5,-125)
bb.BackgroundColor3 = Color3.fromRGB(40,40,40)
bb.BorderSizePixel = 0
bb.Active, bb.Draggable = true, true

--// List Builders
local function makeList(parent, posX, titleText)
    local title = Instance.new("TextLabel", parent)
    title.Size = UDim2.new(0.5,0,0,30)
    title.Position = UDim2.new(posX,0,0,0)
    title.Text = titleText
    title.Font = Enum.Font.SourceSansBold
    title.TextScaled = true
    title.TextColor3 = Color3.new(1,1,1)
    title.BackgroundTransparency = 1

    local list = Instance.new("ScrollingFrame", parent)
    list.Size = UDim2.new(0.5,-10,1,-40)
    list.Position = UDim2.new(posX,5,0,35)
    list.ScrollBarThickness = 6
    list.BackgroundTransparency = 1

    local layout = Instance.new("UIListLayout", list)
    layout.Padding = UDim.new(0,4)

    return list
end

local playerList = makeList(bb, 0, "Blacklist Players")
local teamList = makeList(bb, 0.5, "Blacklist Teams")

--// Refresh Blacklist UI
local function refreshBlacklistUI()
    for _,v in ipairs(playerList:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer then
            local b = Instance.new("TextButton", playerList)
            b.Size = UDim2.new(1,0,0,30)
            b.Font = Enum.Font.SourceSans
            b.TextScaled = true
            b.TextColor3 = Color3.new(1,1,1)
            b.AutoButtonColor = false
            b.BackgroundColor3 = blacklisted[pl.Name] and Color3.fromRGB(255,50,50) or Color3.fromRGB(70,70,70)
            b.Text = (blacklisted[pl.Name] and "[X] " or "[ ] ") .. pl.Name
            b.MouseButton1Click:Connect(function()
                blacklisted[pl.Name] = not blacklisted[pl.Name]
                refreshBlacklistUI()
            end)
        end
    end

    for _,v in ipairs(teamList:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    for _,team in ipairs(Teams:GetTeams()) do
        local b = Instance.new("TextButton", teamList)
        b.Size = UDim2.new(1,0,0,30)
        b.Font = Enum.Font.SourceSans
        b.TextScaled = true
        b.TextColor3 = Color3.new(1,1,1)
        b.AutoButtonColor = false
        b.BackgroundColor3 = blacklistedTeams[team.Name] and Color3.fromRGB(255,50,50) or Color3.fromRGB(70,70,70)
        b.Text = (blacklistedTeams[team.Name] and "[X] " or "[ ] ") .. team.Name
        b.MouseButton1Click:Connect(function()
            blacklistedTeams[team.Name] = not blacklistedTeams[team.Name]
            refreshBlacklistUI()
        end)
    end
end

refreshBtn.MouseButton1Click:Connect(refreshBlacklistUI)
Players.PlayerAdded:Connect(refreshBlacklistUI)

task.spawn(function()
    while true do
        refreshBlacklistUI()
        task.wait(1)
    end
end)

--// Hotkeys
UserInputService.InputBegan:Connect(function(i,gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.Y then triggerbotEnabled = not triggerbotEnabled updateTrig()
    elseif i.KeyCode == Enum.KeyCode.M then
        aimbotMode = (aimbotMode=="closest") and "constant" or "closest"
        currentTarget = nil
        updateModeText()
    end
end)

--// Visibility Scan
task.spawn(function()
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    while true do
        lastVisibleTargets = {}
        params.FilterDescendantsInstances = {LocalPlayer.Character}
        for _,pl in ipairs(Players:GetPlayers()) do
            if pl ~= LocalPlayer and pl.Character and not blacklisted[pl.Name] then
                if not (pl.Team and blacklistedTeams[pl.Team.Name]) then
                    local hrp = pl.Character:FindFirstChild("HumanoidRootPart")
                    local hum = pl.Character:FindFirstChild("Humanoid")
                    if hrp and hum and hum.Health > 0 then
                        local ray = workspace:Raycast(Camera.CFrame.Position, hrp.Position-Camera.CFrame.Position, params)
                        if ray and ray.Instance:IsDescendantOf(pl.Character) then
                            local sp,on = Camera:WorldToViewportPoint(hrp.Position)
                            if on then
                                local d = (Vector2.new(sp.X,sp.Y)-UserInputService:GetMouseLocation()).Magnitude
                                if d < aimbotFOV then
                                    lastVisibleTargets[pl] = {part=hrp, dist=d}
                                end
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.25)
    end
end)

--// Target Selector
local function getTarget()
    if aimbotMode=="constant" and currentTarget and lastVisibleTargets[currentTarget] then
        return currentTarget, lastVisibleTargets[currentTarget].part
    end

    local best, dist = nil, math.huge
    for pl,data in pairs(lastVisibleTargets) do
        if data.dist < dist then
            best, dist = pl, data.dist
        end
    end

    if aimbotMode=="constant" then currentTarget = best end
    return best, best and lastVisibleTargets[best].part
end

--// Aimbots
RunService.RenderStepped:Connect(function()
    local t,p = getTarget()
    if t and p then
        if firstPersonAimbotEnabled then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, p.Position)
        end
        if thirdPersonAimbotEnabled and _G.mousemoverel then
            local sp = Camera:WorldToViewportPoint(p.Position)
            local mv = Vector2.new(sp.X,sp.Y)-UserInputService:GetMouseLocation()
            _G.mousemoverel(mv.X,mv.Y)
        end
    end
end)

--// Init
refreshBlacklistUI()
