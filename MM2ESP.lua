-- MM2 Role-Based ESP (Stable Version)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local espFolder = Instance.new("Folder", Workspace)
espFolder.Name = "MM2_ESP"

local knownRoles = {}

local function clearESP()
	for _, v in pairs(espFolder:GetChildren()) do
		v:Destroy()
	end
end

local function createHighlight(character, color)
	local highlight = Instance.new("Highlight")
	highlight.Name = "ESPHighlight"
	highlight.Adornee = character
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillColor = color
	highlight.FillTransparency = 0.5
	highlight.OutlineTransparency = 1
	highlight.Parent = espFolder
end

local function createBillboard(part, text, color)
	local billboard = Instance.new("BillboardGui")
	billboard.Adornee = part
	billboard.Size = UDim2.new(0, 100, 0, 30)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.AlwaysOnTop = true
	billboard.Name = "ESPBillboard"
	billboard.Parent = espFolder

	local label = Instance.new("TextLabel", billboard)
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
end

local function getRole(player)
	if player.Backpack:FindFirstChild("Gun") or (player.Character and player.Character:FindFirstChild("Gun")) then
		return "Sheriff"
	elseif player.Backpack:FindFirstChild("Knife") or (player.Character and player.Character:FindFirstChild("Knife")) then
		return "Murderer"
	else
		return "Innocent"
	end
end

local roleColors = {
	Sheriff = Color3.fromRGB(0, 170, 255),
	Murderer = Color3.fromRGB(255, 0, 0),
	Innocent = Color3.fromRGB(128, 128, 128)
}

local function updateESP()
	clearESP()

	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local role = getRole(player)
			if knownRoles[player] ~= role then
				knownRoles[player] = role
			end

			local color = roleColors[knownRoles[player] or "Innocent"]
			createHighlight(player.Character, color)
			createBillboard(player.Character:FindFirstChild("HumanoidRootPart"), knownRoles[player], color)
		end
	end

	-- Dropped gun
	local droppedGun = Workspace:FindFirstChild("GunDrop")
	if droppedGun then
		createHighlight(droppedGun, Color3.fromRGB(0, 255, 0))
		createBillboard(droppedGun, "Dropped Gun", Color3.fromRGB(0, 255, 0))
	end
end

-- Scan every 1.5 seconds to prevent blinking
while true do
	updateESP()
	task.wait(1.5)
end
