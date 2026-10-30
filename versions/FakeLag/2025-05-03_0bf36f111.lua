local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")

local lagging = false
local lastUpdate = 0
local minLagTime = 3
local maxLagTime = 8
local minCooldown = 3
local maxCooldown = 7
local minDist = 20
local maxDist = 80

local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "RealisticFakeLag"

local toggleBtn = Instance.new("TextButton", gui)
toggleBtn.Size = UDim2.new(0, 120, 0, 40)
toggleBtn.Position = UDim2.new(1, -130, 1, -50)
toggleBtn.Text = "Fake Lag: OFF"
toggleBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

toggleBtn.MouseButton1Click:Connect(function()
	lagging = not lagging
	toggleBtn.Text = "Fake Lag: " .. (lagging and "ON" or "OFF")
end)

RunService.RenderStepped:Connect(function()
	if not lagging then return end
	local now = tick()

	local cooldown = math.random() * (maxCooldown - minCooldown) + minCooldown
	if now - lastUpdate >= cooldown then
		lastUpdate = now

		local lagTime = math.random() * (maxLagTime - minLagTime) + minLagTime
		local lagPercent = (lagTime - minLagTime) / (maxLagTime - minLagTime)
		local teleportDist = minDist + lagPercent * (maxDist - minDist)

		local originalCF = hrp.CFrame
		hrp.Anchored = true

		task.delay(lagTime, function()
			if not hrp or not hrp.Parent then return end

			local angle = math.rad(math.random(0, 360))
			local offset = Vector3.new(
				math.cos(angle) * teleportDist,
				0,
				math.sin(angle) * teleportDist
			)

			local newPos = originalCF.Position + offset
			hrp.CFrame = CFrame.new(newPos, newPos + originalCF.LookVector)
			hrp.Anchored = false
		end)
	end
end)
