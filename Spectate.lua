-- Simple Roblox Spectate Script with GUI, Refresh, and No Self-Spectate
-- Toggle Spectate: L
-- Next Player: N
-- Previous Player: M
-- Refresh Player List: R

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

-- Configuration
local TOGGLE_KEY = Enum.KeyCode.L
local NEXT_KEY = Enum.KeyCode.N
local PREVIOUS_KEY = Enum.KeyCode.M
local REFRESH_KEY = Enum.KeyCode.R

-- State Variables
local spectating = false
local playerIndex = 1
local spectateList = {}
local spectateGUI = nil
local prevButton = nil
local nextButton = nil
local refreshButton = nil
local spectatingCamSubject = nil -- To store the original camera subject

-- GUI Creation Function
local function createSpectateGUI()
	if spectateGUI then return end

	spectateGUI = Instance.new("ScreenGui")
	spectateGUI.Name = "SpectateGUI"
	spectateGUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local spectateFrame = Instance.new("Frame")
	spectateFrame.Name = "SpectateFrame"
	spectateFrame.Size = UDim2.new(0, 270, 0, 50)
	spectateFrame.Position = UDim2.new(0.5, -135, 0.1, 0)
	spectateFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	spectateFrame.BorderSizePixel = 2
	spectateFrame.BorderColor3 = Color3.fromRGB(200, 200, 200)
	spectateFrame.Visible = true
	spectateGUI.Parent = StarterGui

	-- Previous Button
	prevButton = Instance.new("TextButton")
	prevButton.Name = "PrevButton"
	prevButton.Size = UDim2.new(0, 80, 1, 0)
	prevButton.Position = UDim2.new(0, 0, 0, 0)
	prevButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	prevButton.BorderSizePixel = 1
	prevButton.BorderColor3 = Color3.fromRGB(150, 150, 150)
	prevButton.Text = "< Previous"
	prevButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	prevButton.Font = Enum.Font.SourceSansBold
	prevButton.TextSize = 16
	prevButton.Parent = spectateFrame

	-- Refresh Button
	refreshButton = Instance.new("TextButton")
	refreshButton.Name = "RefreshButton"
	refreshButton.Size = UDim2.new(0, 50, 1, 0)
	refreshButton.Position = UDim2.new(0, 80, 0, 0)
	refreshButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	refreshButton.BorderSizePixel = 1
	refreshButton.BorderColor3 = Color3.fromRGB(150, 150, 150)
	refreshButton.Text = "R"
	refreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	refreshButton.Font = Enum.Font.SourceSansBold
	refreshButton.TextSize = 16
	refreshButton.Parent = spectateFrame

	-- Next Button
	nextButton = Instance.new("TextButton")
	nextButton.Name = "NextButton"
	nextButton.Size = UDim2.new(0, 80, 1, 0)
	nextButton.Position = UDim2.new(0, 130, 0, 0)
	nextButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	nextButton.BorderSizePixel = 1
	nextButton.BorderColor3 = Color3.fromRGB(150, 150, 150)
	nextButton.Text = "Next >"
	nextButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	nextButton.Font = Enum.Font.SourceSansBold
	nextButton.TextSize = 16
	nextButton.Parent = spectateFrame

	-- Button Click Connections
	prevButton.MouseButton1Click:Connect(function()
		previousPlayer()
	end)
	nextButton.MouseButton1Click:Connect(function()
		nextPlayer()
	end)
	refreshButton.MouseButton1Click:Connect(function()
		refreshPlayerList()
	end)
end

-- Remove GUI Function
local function removeSpectateGUI()
	if spectateGUI then
		spectateGUI:Destroy()
		spectateGUI = nil
		prevButton = nil
		nextButton = nil
		refreshButton = nil
	end
end

-- Update the list of players to spectate, EXCLUDING LocalPlayer
local function updatePlayerList()
	spectateList = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			table.insert(spectateList, plr)
		end
	end
	-- Ensure playerIndex is valid after list update
	if #spectateList == 0 then
		playerIndex = 1 -- Reset if list is empty
	elseif playerIndex > #spectateList then
		playerIndex = 1 -- Wrap to beginning if index is out of bounds
	elseif playerIndex < 1 then
		playerIndex = #spectateList -- Wrap to end if index is out of bounds (shouldn't happen with +=1 or -=1)
	end
end

-- Manually refresh the player list
local function refreshPlayerList()
	local oldPlayerList = spectateList
	updatePlayerList()

	-- If spectating, try to re-align to the current player index or restart if list is empty
	if spectating then
		if #spectateList > 0 then
			-- If the current player was removed, playerIndex is updated to the next valid one by updatePlayerList.
			-- We need to ensure we attempt to spectate the player at the current index.
			-- If playerIndex became invalid (e.g. was pointing to last player who left, and list shrunk)
			-- then it's corrected by updatePlayerList.
			if playerIndex > #spectateList then playerIndex = 1 end -- Re-ensure index validity
			spectatePlayer(spectateList[playerIndex])
		else
			warn("No players left after refresh, stopping spectate.")
			stopSpectating()
			removeSpectateGUI()
		end
	end
	-- print("Player list refreshed. Found", #spectateList, "players.") -- Optional feedback
end


-- Function to set the camera to spectate a player
local function spectatePlayer(plr)
	if not plr then
		warn("Attempted to spectate a nil player.")
		return
	end
	-- Ensure player is valid and has a character with a Humanoid
	if not plr.Character or not plr.Character:FindFirstChildOfClass("Humanoid") then
		warn("Player's character or Humanoid not found for:", plr.Name, "- attempting to switch to next player.")
		-- If character isn't ready, automatically try to move to the next player
		nextPlayer()
		return
	end

	-- Store original camera subject if not already stored
	if spectatingCamSubject == nil then
		spectatingCamSubject = Camera.CameraSubject
	end

	-- Set camera subject
	Camera.CameraSubject = plr.Character.Humanoid
	spectating = true
	if spectateGUI then spectateGUI.Enabled = true end
end

-- Function to stop spectating and return camera to normal
local function stopSpectating()
	spectating = false
	if spectateGUI then spectateGUI.Enabled = false end

	-- Restore original camera subject if it was changed
	if spectatingCamSubject then
		Camera.CameraSubject = spectatingCamSubject
		spectatingCamSubject = nil -- Reset for next spectate session
	elseif LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
		-- Fallback: if we didn't store, try to revert to local player's humanoid
		Camera.CameraSubject = LocalPlayer.Character.Humanoid
	end
end

-- Move to the next player in the list
local function nextPlayer()
	if #spectateList == 0 then
		warn("No players available to spectate.")
		return
	end

	playerIndex += 1
	if playerIndex > #spectateList then
		playerIndex = 1 -- Wrap around to the beginning
	end

	local targetPlayer = spectateList[playerIndex]
	if targetPlayer then
		spectatePlayer(targetPlayer)
	else
		warn("Could not find player at index:", playerIndex, "- refreshing list and trying again.")
		refreshPlayerList() -- Refresh and try to spectate again
	end
end

-- Move to the previous player in the list
local function previousPlayer()
	if #spectateList == 0 then
		warn("No players available to spectate.")
		return
	end

	playerIndex -= 1
	if playerIndex < 1 then
		playerIndex = #spectateList -- Wrap around to the end
	end

	local targetPlayer = spectateList[playerIndex]
	if targetPlayer then
		spectatePlayer(targetPlayer)
	else
		warn("Could not find player at index:", playerIndex, "- refreshing list and trying again.")
		refreshPlayerList() -- Refresh and try to spectate again
	end
end

-- Main input handling function
local function handleInput(input, gpe)
	-- Ignore if input was processed by a game GUI or executor GUI
	if gpe then return end

	-- Toggle Spectate
	if input.KeyCode == TOGGLE_KEY then
		spectating = not spectating
		if spectating then
			refreshPlayerList() -- Always refresh when starting to spectate
			if #spectateList > 0 then
				createSpectateGUI() -- Create GUI only when starting to spectate
				-- Ensure playerIndex is valid *after* refresh and before spectating
				if playerIndex > #spectateList then playerIndex = 1 end
				spectatePlayer(spectateList[playerIndex])
			else
				warn("No players to spectate!")
				spectating = false -- Turn off if no players available
				removeSpectateGUI()
			end
		else
			stopSpectating()
			removeSpectateGUI() -- Remove GUI when stopping
		end
		return -- Important: prevent further processing of this keypress
	end

	-- Refresh Player List (via key)
	if input.KeyCode == REFRESH_KEY then
		refreshPlayerList()
		return -- Important: prevent further processing of this keypress
	end

	-- Spectate Navigation (only if spectating)
	if spectating then
		if input.KeyCode == NEXT_KEY then
			nextPlayer()
		elseif input.KeyCode == PREVIOUS_KEY then
			previousPlayer()
		end
	end
end

-- Connection for input
UserInputService.InputBegan:Connect(handleInput)

-- Listen for player changes to update the list
local function onPlayerAdded(plr)
	updatePlayerList()
	-- If spectating and the player list changes, ensure current spectate index is valid.
	if spectating and #spectateList > 0 then
		if playerIndex > #spectateList then playerIndex = 1 end -- Ensure index is valid after add
		-- No need to automatically spectate someone new if someone was just added,
		-- unless the current spectated player was removed. The logic in onPlayerRemoving handles that.
	end
end

local function onPlayerRemoving(plr)
	local wasSpectatingTarget = false
	-- Check if the player leaving is the one we're currently spectating
	if spectating and spectateList[playerIndex] == plr then
		wasSpectatingTarget = true
	end

	updatePlayerList() -- Update the list *after* checking

	-- If the player we were spectating left, move to the next one
	if spectating and wasSpectatingTarget then
		if #spectateList > 0 then
			-- playerIndex is already updated by updatePlayerList to point to the next valid player if needed
			spectatePlayer(spectateList[playerIndex])
		else
			warn("Last player removed, stopping spectate.")
			stopSpectating()
			removeSpectateGUI()
		end
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Handle local player character changes (e.g., death/respawn)
LocalPlayer.CharacterAdded:Connect(function(char)
	if spectating then
		-- If the camera subject reverted to our local player's character, try to re-spectate.
		-- This is a safeguard. `spectatePlayer` will ensure we don't spectate ourselves.
		if Camera.CameraSubject ~= nil and Camera.CameraSubject:IsA("Humanoid") and Camera.CameraSubject.Parent == char then
			task.wait(0.1) -- Give things a moment to settle
			refreshPlayerList() -- Ensure list is fresh
			if #spectateList > 0 then
				-- We need to ensure the playerIndex is valid before calling spectatePlayer
				if playerIndex > #spectateList then playerIndex = 1 end
				spectatePlayer(spectateList[playerIndex])
			else
				stopSpectating() -- If no one to spectate, stop.
			end
		end
	end
end)

-- Clean up when the script is removed or game ends
game.Destroying:Connect(function()
	stopSpectating()
	removeSpectateGUI()
end)
