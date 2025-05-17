--// SERVICES local Players = game:GetService("Players") local RunService = game:GetService("RunService") local UserInputService = game:GetService("UserInputService")

--// VARIABLES local LocalPlayer = Players.LocalPlayer local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait() local Humanoid = Character:WaitForChild("Humanoid") local HRP = Character:WaitForChild("HumanoidRootPart")

local lastGroundedTime = tick() local jumpRequestTime = 0 local canCoyoteJump = false local spaceHeld = false local lastPositions = {}

--// SETTINGS local COYOTE_TIME = 0.2 local WALL_CLIP_SPAM_TIME = 2 local CLIP_DISTANCE = 1.2

--// FUNCTIONS local function getFootPosition() local rayOrigin = HRP.Position local rayDirection = Vector3.new(0, -3, 0) local raycastParams = RaycastParams.new() raycastParams.FilterDescendantsInstances = {Character} raycastParams.FilterType = Enum.RaycastFilterType.Blacklist local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams) return result and result.Position or nil end

local function simulateJumpLanding() local gravity = workspace.Gravity local velocity = HRP.Velocity local position = HRP.Position for i = 1, 100 do velocity = velocity + Vector3.new(0, -gravity * 0.016, 0) position = position + velocity * 0.016 local ray = RaycastParams.new() ray.FilterDescendantsInstances = {Character} ray.FilterType = Enum.RaycastFilterType.Blacklist local hit = workspace:Raycast(position, Vector3.new(0, -2, 0), ray) if hit then return position end end return nil end

local function createInvisiblePlatform(pos) local part = Instance.new("Part") part.Anchored = true part.CanCollide = true part.Transparency = 1 part.Size = Vector3.new(1.5, 0.2, 1.5) part.Position = pos + Vector3.new(0, 0.5, 0) part.Parent = workspace game.Debris:AddItem(part, 0.75) end

local function createTrussClone(original) local truss = Instance.new("TrussPart") truss.Anchored = true truss.CanCollide = true truss.Transparency = 1 truss.Size = original.Size + Vector3.new(0.5, 0.5, 0.5) truss.Position = original.Position truss.Parent = workspace game.Debris:AddItem(truss, 1) end

local function checkWallhop() local footPos = getFootPosition() if not footPos then return end local verticalVel = HRP.Velocity.Y if verticalVel < 0 then local deltaRot = math.abs(HRP.Orientation.Y - Character.PrimaryPart.Orientation.Y) if deltaRot > 15 then if spaceHeld then wait(0.05) Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) elseif tick() - jumpRequestTime < 0.1 then Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end end end

local function checkCoyoteJump() if tick() - lastGroundedTime < COYOTE_TIME and tick() - jumpRequestTime < 0.1 then Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end end

local function checkMissedLanding() local predicted = simulateJumpLanding() if predicted then local ray = RaycastParams.new() ray.FilterDescendantsInstances = {Character} ray.FilterType = Enum.RaycastFilterType.Blacklist local hit = workspace:Raycast(predicted, Vector3.new(0, -2, 0), ray) if not hit then createInvisiblePlatform(predicted) end end end

local function checkTrussSave() for _, v in pairs(workspace:GetDescendants()) do if v:IsA("TrussPart") and (v.Position - HRP.Position).Magnitude < 5 then if HRP.Position.Y > v.Position.Y + v.Size.Y / 2 then createTrussClone(v) end end end end

local function checkSpamClip() table.insert(lastPositions, HRP.Position) if #lastPositions > 60 then table.remove(lastPositions, 1) end local moved = false for i = 2, #lastPositions do if (lastPositions[i] - lastPositions[i - 1]).Magnitude > 0.25 then moved = true break end end if not moved and spaceHeld then local deltaRot = math.abs(HRP.Orientation.Y - Character.PrimaryPart.Orientation.Y) if deltaRot > 25 then local rayParams = RaycastParams.new() rayParams.FilterDescendantsInstances = {Character} rayParams.FilterType = Enum.RaycastFilterType.Blacklist local ray = workspace:Raycast(HRP.Position, HRP.CFrame.LookVector * CLIP_DISTANCE, rayParams) if ray then HRP.CFrame = HRP.CFrame + HRP.CFrame.LookVector * (CLIP_DISTANCE + 0.1) end end end end

--// INPUT HANDLERS UserInputService.InputBegan:Connect(function(input, processed) if processed then return end if input.KeyCode == Enum.KeyCode.Space then spaceHeld = true jumpRequestTime = tick() end end)

UserInputService.InputEnded:Connect(function(input) if input.KeyCode == Enum.KeyCode.Space then spaceHeld = false end end)

--// MAIN LOOP RunService.RenderStepped:Connect(function() if Humanoid.FloorMaterial ~= Enum.Material.Air then lastGroundedTime = tick() end checkCoyoteJump() checkWallhop() checkMissedLanding() checkTrussSave() checkSpamClip() end)

Character:WaitForChild("Humanoid").StateChanged:Connect(function(old, new) if new == Enum.HumanoidStateType.Jumping then jumpRequestTime = 0 end end)

LocalPlayer.CharacterAdded:Connect(function(char) Character = char Humanoid = char:WaitForChild("Humanoid") HRP = char:WaitForChild("HumanoidRootPart") end)

