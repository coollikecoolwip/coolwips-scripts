-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- Silent Aim Target
local targetPlayer = nil

-- Identify Murderer
local function getMurderer()
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			if player.Character and (player.Backpack:FindFirstChild("Knife") or player.Character:FindFirstChild("Knife")) then
				return player
			end
		end
	end
	return nil
end

-- Hook target position
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
	local args = {...}
	local method = getnamecallmethod()
	
	-- Detect when gun fires
	if method == "FireServer" and tostring(self):lower():find("shoot") then
		local murderer = getMurderer()
		if murderer and murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart") then
			args[1] = murderer.Character.HumanoidRootPart.Position
			return oldNamecall(self, unpack(args))
		end
	end
	
	return oldNamecall(self, ...)
end)

print("Silent Aim loaded — shoot anywhere and it’ll auto hit the murderer.")
