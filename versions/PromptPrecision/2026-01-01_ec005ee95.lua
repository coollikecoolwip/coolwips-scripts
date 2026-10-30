-- ROBLOX UNIVERSAL PROMPT ACTIVATOR (EXACT MATCH & TRIM)
-- Prompt Precision GUI Build

---------------------------------------------------------------------
-- ENVIRONMENT SETUP

---------------------------------------------------------------------
local game = _G.game or Game

if not game then
    error("[Prompt Precision]: 'game' object not found. This script requires a compatible executor (like Xeno).")
    return
end

local CoreGui = game:GetService("CoreGui")
local PPS = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
if not player then
    player = Players.PlayerAdded:Wait()
    print("[Prompt Precision]: Player joined late. Waiting for character...")
end

local char = player.Character or player.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart")

---------------------------------------------------------------------
-- SETTINGS

---------------------------------------------------------------------
local RUNNING = false
local DEBOUNCE = 0.2
local ACTIVATION_RANGE = 12
local RESCAN_INTERVAL = 10  -- Rescan for prompts every 10 seconds

-- Target Prompt Names
local TARGET_PROMPT_NAMES = {}

-- Default Activation Range (Used if no prompts are found)
local detectedActivationRange = ACTIVATION_RANGE -- setting the default to 12

---------------------------------------------------------------------
-- GUI CREATION

---------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Prompt PrecisionXenoPromptGUI"
ScreenGui.Parent = CoreGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 250, 0, 360)  -- Increased height
Frame.Position = UDim2.new(0.05, 0, 0.3, 0)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 25)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Title.Text = "Prompt Precision Auto-Prompt"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextScaled = true
Title.Parent = Frame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, -20, 0, 35)
ToggleBtn.Position = UDim2.new(0, 10, 0, 35)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
ToggleBtn.TextColor3 = Color3.new(1, 1, 1)
ToggleBtn.TextScaled = true
ToggleBtn.Text = "START"
ToggleBtn.Parent = Frame

-- Text Box for Prompt Names
local PromptNameBox = Instance.new("TextBox")
PromptNameBox.Size = UDim2.new(1, -20, 0, 35)
PromptNameBox.Position = UDim2.new(0, 10, 0, 80)
PromptNameBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
PromptNameBox.TextColor3 = Color3.new(1, 1, 1)
PromptNameBox.TextScaled = true
PromptNameBox.PlaceholderText = "Enter PROMPT NAME (e.g., Open Door)"
PromptNameBox.Parent = Frame

-- Add Prompt Name Button
local AddPromptNameBtn = Instance.new("TextButton")
AddPromptNameBtn.Size = UDim2.new(1, -20, 0, 30)
AddPromptNameBtn.Position = UDim2.new(0, 10, 0, 120)
AddPromptNameBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
AddPromptNameBtn.TextColor3 = Color3.new(1, 1, 1)
AddPromptNameBtn.TextScaled = true
AddPromptNameBtn.Text = "Add PROMPT Name"
AddPromptNameBtn.Parent = Frame

-- ScrollingFrame for the list
local ScrollingFrame = Instance.new("ScrollingFrame")
ScrollingFrame.Size = UDim2.new(1, -20, 0, 180)
ScrollingFrame.Position = UDim2.new(0, 10, 0, 160)
ScrollingFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)  -- Initial canvas size
ScrollingFrame.ScrollBarThickness = 12
ScrollingFrame.Parent = Frame

---------------------------------------------------------------------
-- GUI FUNCTIONS

---------------------------------------------------------------------
ToggleBtn.MouseButton1Click:Connect(function()
    RUNNING = not RUNNING
    ToggleBtn.Text = RUNNING and "STOP" or "START"
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0) or Color3.fromRGB(60, 60, 60)
    print("[Prompt Precision]: Script toggled to: " .. tostring(RUNNING))
end)

-- Function to update the prompt list in the GUI
local function updatePromptList()
    -- Clear existing list items
    for _, item in ipairs(ScrollingFrame:GetChildren()) do
        if item:IsA("Frame") then
            item:Destroy()
        end
    end

    -- Calculate canvas size
    local itemCount = #TARGET_PROMPT_NAMES
    ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, itemCount * 30)

    -- Add new list items
    for i, promptName in ipairs(TARGET_PROMPT_NAMES) do
        local listItem = Instance.new("Frame")
        listItem.Size = UDim2.new(1, 0, 0, 30)
        listItem.Position = UDim2.new(0, 0, 0, (i - 1) * 30)
        listItem.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        listItem.Parent = ScrollingFrame

        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(0.7, 0, 1, 0)
        textLabel.Position = UDim2.new(0, 0, 0, 0)
        textLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        textLabel.TextColor3 = Color3.new(1, 1, 1)
        textLabel.TextScaled = true
        textLabel.Text = promptName
        textLabel.Parent = listItem

        local removeButton = Instance.new("TextButton")
        removeButton.Size = UDim2.new(0.3, 0, 1, 0)
        removeButton.Position = UDim2.new(0.7, 0, 0, 0)
        removeButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
        removeButton.TextColor3 = Color3.new(1, 1, 1)
        removeButton.TextScaled = true
        removeButton.Text = "Remove"
        removeButton.Parent = listItem

        -- Remove Button functionality
        removeButton.MouseButton1Click:Connect(function()
            table.remove(TARGET_PROMPT_NAMES, i)
            updatePromptList()
            print("[Prompt Precision]: Removed target PROMPT NAME: " .. promptName)
        end)
    end
end

AddPromptNameBtn.MouseButton1Click:Connect(function()
    local promptName = string.lower(PromptNameBox.Text)
    if promptName ~= "" then
        table.insert(TARGET_PROMPT_NAMES, promptName)
        print("[Prompt Precision]: Added TARGET PROMPT NAME: " .. promptName)
        PromptNameBox.Text = ""
        updatePromptList()  -- Update the list after adding a prompt
    end
end)

---------------------------------------------------------------------
-- ACTIVATION FUNCTIONS

---------------------------------------------------------------------
local lastPrompt = nil
local lastTime = 0

local function activatePrompt(prompt)
    -- **NEW: Check if prompt is valid**
    if not prompt or not prompt.Parent then
        print("[Prompt Precision]: ERROR! Prompt is NIL or has no Parent! Aborting activation.")
        return
    end

    -- Check Debounce Time
    if prompt == lastPrompt and os.clock() - lastTime < DEBOUNCE then
        print("[Prompt Precision]: Debounce: too soon to reactivate '" .. prompt.ActionText .. "'.")
        return
    end

    -- Check if the Prompt is Enabled
    if not prompt.Enabled then
        print("[Prompt Precision]: Prompt '" .. prompt.ActionText .. "' is disabled. Skipping.")
        return
    end

    -- Try to Activate the Prompt
    print("[Prompt Precision]: Attempting to ACTIVATE prompt: " .. prompt.ActionText)

    if prompt.HoldDuration > 0 then
        print("[Prompt Precision]: Prompt has HoldDuration: " .. prompt.HoldDuration)
        task.spawn(function()
            local success, err = pcall(function()
                prompt:InputHoldBegin()
                task.wait(prompt.HoldDuration)
                prompt:InputHoldEnd()
            end)
            if success then
                print("[Prompt Precision]: Hold activation complete for: " .. prompt.ActionText)
            else
                print("[Prompt Precision]: ERROR during Hold activation: " .. err)
            end
        end)
    else
        print("[Prompt Precision]: No HoldDuration. Activating...")
        local success, err = pcall(function()
            prompt:InputHoldBegin()
            task.wait(0.05)
            prompt:InputHoldEnd()
        end)
        if success then
            print("[Prompt Precision]: Immediate activation complete for: " .. prompt.ActionText)
        else
            print("[Prompt Precision]: ERROR during Immediate activation: " .. err)
        end
    end

    -- Update Last Activation Time
    lastPrompt = prompt
    lastTime = os.clock()
end

---------------------------------------------------------------------
-- PROMPT SCANNING FUNCTIONS

---------------------------------------------------------------------

-- Helper function to trim whitespace from a string
local function trim(s)
  return string.gsub(s, "^%s*(.-)%s*$", "%1")
end

-- Table to store prompts and their positions
local prompts = {}

-- Function to find all ProximityPrompt objects and update the 'prompts' table
local function rescanPrompts()
    print("[Prompt Precision]: Rescanning for ProximityPrompts...")
    -- Clear the existing 'prompts' table
    prompts = {}

    local foundAnyPrompts = false  -- Track if we found any prompts during this scan

    -- Find all ProximityPrompt objects in the game
    for _, obj in ipairs(game:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            -- Find The Activation Range
            local detectedActivationRange_local = obj.RequiresLineOfSight and 12 or 24
            -- Get The Postion
            local pos
            if obj.Parent:IsA("BasePart") then
                pos = obj.Parent.Position
            elseif obj.Parent:IsA("Attachment") then
                pos = obj.Parent.WorldPosition
            else
                warn("Unsupported prompt parent: " .. obj:GetFullName())
                continue
            end

            -- Store the Prompts with Position and name
            local promptName = string.lower(trim(obj.ActionText))  -- **TRIM & LOWERCASE**
            prompts[obj] = {
                position = pos,
                name = promptName
            }
            print("[Prompt Precision]: Found prompt '" .. obj.ActionText .. "' at position: " .. tostring(pos))
            foundAnyPrompts = true  -- We found at least one prompt!
        end
    end

    -- **NEW:** If we didn't find any prompts, use the default activation range
    if not foundAnyPrompts then
        print("[Prompt Precision]: WARNING: No prompts found during rescan. Using default activation range.")
        detectedActivationRange = ACTIVATION_RANGE -- the hard coded Activation Range of 12
    end

    print("[Prompt Precision]: Rescan complete. Found " .. #prompts .. " prompts.")
end

---------------------------------------------------------------------
-- MAIN LOOP

---------------------------------------------------------------------
task.spawn(function()
    -- Perform initial prompt scan
    rescanPrompts()

    local lastRescanTime = 0

    while true do
        task.wait(0.1)

        if not RUNNING then
            continue
        end

        --ADDED
        if not player or not player.Character then
            print("[Prompt Precision]: Waiting for character...")
            char = player.CharacterAdded:Wait()
        else
            char = player.Character
        end

        --ADDED
        if not char or not char:FindFirstChild("HumanoidRootPart") then
            print("[Prompt Precision]: Waiting for root part...")
            root = char:WaitForChild("HumanoidRootPart")
            continue
        end
        root = char:WaitForChild("HumanoidRootPart")

		-- ADD THIS IN AND SEE IF WORKS
		if not char or char.Name ~= player.Name then
			warn("[Prompt Precision]: Invalid character model found. Skipping prompts.")
			continue
		end

        -- Check distance to stored prompts
        for prompt, data in pairs(prompts) do
			-- **LOGGING: Log TARGET_PROMPT_NAMES and PROMPT Name**
            print("[Prompt Precision]: TARGET_PROMPT_NAMES = " .. #TARGET_PROMPT_NAMES .. ", Prompt Name = " .. tostring(data.name))
            -- Check if the prompt is still valid!
            if not prompt or not prompt.Parent then
                print("[Prompt Precision]: WARNING! Prompt '" .. (data.name or "Unknown") .. "' is no longer valid. Skipping.")
                -- In future updates this can be added back
                -- prompts[prompt] = nil
                continue -- Skip to the next prompt
            end

            -- Check if the prompt name matches the target names
            local matchesTarget = false

            -- ONLY IF TARGET NAMES EXIST
            if #TARGET_PROMPT_NAMES > 0 then
                -- EXACT MATCH & TRIM
                for _, targetName in ipairs(TARGET_PROMPT_NAMES) do
                    local trimmedTargetName = string.lower(trim(targetName))
                    -- THE PROBLEM IF STRING.LOWER()
                    if data.name == targetName then -- ONLY MATCH FOR EXACT
                        matchesTarget = true
                        break
                    end
                end
            end

            if matchesTarget then
                local dist = (root.Position - data.position).Magnitude

                -- **NEW:  Check if detectedActivationRange is nil before comparing**
                 if detectedActivationRange == nil then
                    print("[Prompt Precision]: CRITICAL ERROR: detectedActivationRange is nil! Using default: " .. ACTIVATION_RANGE)
                    detectedActivationRange = ACTIVATION_RANGE
                end

                if dist <= detectedActivationRange then
                    activatePrompt(prompt)
                end
			else
				print("[Prompt Precision]: No Target Names Specified, and Name Mis-Match Skipping")
			end
        end

        -- Periodically rescan for prompts
        if os.clock() - lastRescanTime >= RESCAN_INTERVAL then
            lastRescanTime = os.clock()
            rescanPrompts()
        end
    end
end)
