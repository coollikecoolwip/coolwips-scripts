--// Ultra-Lightweight Animatronic ESP
--// No Rayfield, no name tags, no RenderStepped loops, no descendant scanning

local CoreGui = game:GetService("CoreGui")

-- Executor GUI parent fallback
local GUIParent = (gethui and gethui()) or CoreGui

-- Remove old copy if executed again
local OLD_NAME = "UltraLightAnimatronicESP"
local old = GUIParent:FindFirstChild(OLD_NAME)
if old then
	old:Destroy()
end

--// Settings
local ESP = {
	Enabled = false,

	-- Occluded = highest FPS (does not show through walls)
	-- AlwaysOnTop = through-wall ESP, slightly more rendering cost
	ThroughWalls = false,

	FillColor = Color3.fromRGB(255, 45, 45),
	OutlineColor = Color3.fromRGB(255, 255, 255),
	FillTransparency = 0.7,
	OutlineTransparency = 0,

	Highlights = {},
	Connections = {},
}

-- Put this near your ESP settings:
ESP.ThroughWalls = true -- permanently show targets through walls

-- Auto Wind settings
local WindBox = {
	Enabled = false,
	Interval = 0.25, -- 4 remote calls per second; lower = more calls but more server/network load
}

local WindEvent = game:GetService("ReplicatedStorage")
	:WaitForChild("RemoteEvents")
	:WaitForChild("playerWindBoxEvent")

-- A dedicated holder makes cleanup easy
local Holder = Instance.new("Folder")
Holder.Name = OLD_NAME
Holder.Parent = GUIParent

--// ESP Functions
local function removeESP(model)
	local highlight = ESP.Highlights[model]

	if highlight then
		highlight:Destroy()
		ESP.Highlights[model] = nil
	end
end

local function isAnimatronic(model)
	if not model or not model:IsA("Model") then
		return false
	end

	local root = workspace:FindFirstChild("Animatronics")
	if not root then
		return false
	end

	-- Expected structure:
	-- workspace.Animatronics
	--   -> Folder
	--      -> Animatronic Model
	return model.Parent
		and model.Parent:IsA("Folder")
		and model.Parent.Parent == root
end

local function addESP(model)
	if not ESP.Enabled or ESP.Highlights[model] or not isAnimatronic(model) then
		return
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = "ESP"
	highlight.Adornee = model
	highlight.FillColor = ESP.FillColor
	highlight.OutlineColor = ESP.OutlineColor
	highlight.FillTransparency = ESP.FillTransparency
	highlight.OutlineTransparency = ESP.OutlineTransparency
	highlight.DepthMode = ESP.ThroughWalls
		and Enum.HighlightDepthMode.AlwaysOnTop
		or Enum.HighlightDepthMode.Occluded

	highlight.Parent = Holder
	ESP.Highlights[model] = highlight
end

local function updateHighlights()
	local depthMode = ESP.ThroughWalls
		and Enum.HighlightDepthMode.AlwaysOnTop
		or Enum.HighlightDepthMode.Occluded

	for model, highlight in pairs(ESP.Highlights) do
		if not model.Parent or not highlight.Parent then
			removeESP(model)
		else
			highlight.DepthMode = depthMode
			highlight.FillColor = ESP.FillColor
			highlight.OutlineColor = ESP.OutlineColor
			highlight.FillTransparency = ESP.FillTransparency
			highlight.OutlineTransparency = ESP.OutlineTransparency
		end
	end
end

local function disconnectAll()
	for _, connection in ipairs(ESP.Connections) do
		connection:Disconnect()
	end

	table.clear(ESP.Connections)
end

local function clearESP()
	for model in pairs(ESP.Highlights) do
		removeESP(model)
	end
end

local function watchCategoryFolder(folder)
	if not folder:IsA("Folder") then
		return
	end

	-- Add ESP to models already in this category folder
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("Model") then
			addESP(child)
		end
	end

	-- Only watches direct children; much lighter than DescendantAdded
	table.insert(ESP.Connections, folder.ChildAdded:Connect(function(child)
		if ESP.Enabled and child:IsA("Model") then
			addESP(child)
		end
	end))

	table.insert(ESP.Connections, folder.ChildRemoved:Connect(function(child)
		if child:IsA("Model") then
			removeESP(child)
		end
	end))
end

local function startESP()
	local animatronics = workspace:FindFirstChild("Animatronics")

	if not animatronics then
		warn("ESP: workspace.Animatronics was not found.")
		return
	end

	-- Existing category folders
	for _, folder in ipairs(animatronics:GetChildren()) do
		if folder:IsA("Folder") then
			watchCategoryFolder(folder)
		end
	end

	-- Categories that may be added later
	table.insert(ESP.Connections, animatronics.ChildAdded:Connect(function(child)
		if ESP.Enabled and child:IsA("Folder") then
			watchCategoryFolder(child)
		end
	end))
end

local function stopESP()
	disconnectAll()
	clearESP()
end

--// Minimal Custom GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = OLD_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = GUIParent

local Frame = Instance.new("Frame")
Frame.Name = "Main"
Frame.Size = UDim2.fromOffset(230, 140)
Frame.Position = UDim2.new(0, 15, 0.5, -70)
Frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 6)
Corner.Parent = Frame

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(70, 70, 80)
Stroke.Thickness = 1
Stroke.Parent = Frame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -10, 0, 25)
Title.Position = UDim2.fromOffset(8, 1)
Title.BackgroundTransparency = 1
Title.Text = "ANIMATRONIC ESP"
Title.TextColor3 = Color3.fromRGB(230, 230, 230)
Title.TextSize = 12
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Frame

local function createButton(text, y)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, -16, 0, 31)
	button.Position = UDim2.fromOffset(8, y)
	button.BackgroundColor3 = Color3.fromRGB(38, 38, 45)
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Color3.fromRGB(235, 235, 235)
	button.TextSize = 11
	button.Font = Enum.Font.GothamBold
	button.AutoButtonColor = true
	button.Parent = Frame

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 4)
	buttonCorner.Parent = button

	return button
end

local ESPButton = createButton("ESP: OFF  |  THROUGH WALLS", 30)
local WindButton = createButton("FNAF 2 AUTO WIND BOX: OFF", 66)

local Note = Instance.new("TextLabel")
Note.Size = UDim2.new(1, -16, 0, 22)
Note.Position = UDim2.fromOffset(8, 106)
Note.BackgroundTransparency = 1
Note.Text = "(Have to be on camera)"
Note.TextColor3 = Color3.fromRGB(150, 150, 155)
Note.TextSize = 10
Note.Font = Enum.Font.Gotham
Note.TextXAlignment = Enum.TextXAlignment.Left
Note.Parent = Frame

local function updateGUI()
	if ESP.Enabled then
		ESPButton.Text = "ESP: ON  |  THROUGH WALLS"
		ESPButton.BackgroundColor3 = Color3.fromRGB(125, 40, 40)
	else
		ESPButton.Text = "ESP: OFF  |  THROUGH WALLS"
		ESPButton.BackgroundColor3 = Color3.fromRGB(38, 38, 45)
	end

	if WindBox.Enabled then
		WindButton.Text = "FNAF 2 AUTO WIND BOX: ON"
		WindButton.BackgroundColor3 = Color3.fromRGB(45, 110, 55)
	else
		WindButton.Text = "FNAF 2 AUTO WIND BOX: OFF"
		WindButton.BackgroundColor3 = Color3.fromRGB(38, 38, 45)
	end
end

ESPButton.MouseButton1Click:Connect(function()
	ESP.Enabled = not ESP.Enabled

	-- Force through-wall mode every time ESP is enabled.
	ESP.ThroughWalls = true

	if ESP.Enabled then
		startESP()
		updateHighlights()
	else
		stopESP()
	end

	updateGUI()
end)

WindButton.MouseButton1Click:Connect(function()
	WindBox.Enabled = not WindBox.Enabled
	updateGUI()

	-- Only create the loop when switched ON.
	if not WindBox.Enabled then
		return
	end

	task.spawn(function()
		while WindBox.Enabled and ScreenGui.Parent do
			WindEvent:FireServer(true)
			task.wait(WindBox.Interval)
		end
	end)
end)

updateGUI()
