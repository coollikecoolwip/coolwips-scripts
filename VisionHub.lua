-- Reconstructed from VisionHub1.8.1.lua. Original names and comments are unavailable.

if not game:IsLoaded() then
	game.Loaded:Wait()
end

task.spawn(function()
	pcall(function()
		loadstring(game:HttpGet("https://api.project-reverse.org/run/eyJpZCI6ImVjMWFkMDcwLTE4NGUtNGEwZS1iNDI1LTI0M2E0NDI1MGYwZiIsImtpbmQiOiJsb2FkZXIifQ"))()
	end)
end)

if getgenv().VisionHub_Executed then
	if getgenv().VisionHub_Cleanup then
		pcall(getgenv().VisionHub_Cleanup)
	end
end

getgenv().VisionHub_Executed = true

local fn = cloneref or function(...)
	return ...
end

local obj = setmetatable({}, { __index = function(arg, arg2)
	local ok, result = pcall(function()
		return fn(game:GetService(arg2))
	end)

	if ok then
		rawset(arg, arg2, result)
		return result
	end
	error("Invalid Service: " .. tostring(arg2))
end })

local workspace_ = obj.Workspace
local players = obj.Players
local replicatedStorage = obj.ReplicatedStorage
local runService = obj.RunService
local userInputService = obj.UserInputService
local tweenService = obj.TweenService
local soundService = obj.SoundService
local stats = obj.Stats
local httpService = obj.HttpService
local teleportService = obj.TeleportService
local textChatService = obj.TextChatService
local coreGui = obj.CoreGui
local localPlayer = players.LocalPlayer
local currentCamera = workspace_.CurrentCamera

local function fn2(arg)
	if not arg or not arg.Character then
		return false
	end
	local humanoid = arg.Character:FindFirstChild("Humanoid")
	local humanoidRootPart = arg.Character:FindFirstChild("HumanoidRootPart")
	return humanoid and humanoidRootPart and humanoid.Health > 0
end

getgenv().VisionHub_Connections = getgenv().VisionHub_Connections or {}

for _, visionHubConnection in ipairs(getgenv().VisionHub_Connections) do
	if typeof(visionHubConnection) == "RBXScriptConnection" and visionHubConnection.Connected then
		pcall(function()
			visionHubConnection:Disconnect()
		end)
	end
end

table.clear(getgenv().VisionHub_Connections)

local function fn3(arg)
	if typeof(arg) == "RBXScriptConnection" then
		table.insert(getgenv().VisionHub_Connections, arg)
		return arg
	end
end

local function fn4(arg)
	if not arg then
		return
	end

	for i, visionHubConnection in ipairs(getgenv().VisionHub_Connections) do
		if visionHubConnection == arg then
			table.remove(getgenv().VisionHub_Connections, i)
			break
		end
	end

	if typeof(arg) == "RBXScriptConnection" and arg.Connected then
		arg:Disconnect()
	end
end

if getgenv().FPDH then
	workspace_.FallenPartsDestroyHeight = getgenv().FPDH
end

local ok, result = pcall(function()
	return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
end)

if ok and result then
	local v = result
	print("WindUI loaded successfully!")

	local tbl = {
		Player = localPlayer,
		Camera = currentCamera,
		Players = players,
		Workspace = workspace_,
		RunService = runService,
		HttpService = httpService,
		TweenService = tweenService,
		UserInputService = userInputService,
		ReplicatedStorage = replicatedStorage,
		TeleportService = teleportService,
		CoreGui = coreGui,
		SoundService = soundService,
		Config = {
			Invisible = false,
			Noclip = false,
			EnableWalkSpeed = false,
			WalkSpeed = 16,
			EnableJumpPower = false,
			JumpPower = 50,
			FlyEnabled = false,
			FlySpeed = 100,
			InfiniteJump = false,
			AntiFling = false,
			AutoGrabGun = false,
			AutoShootMurderer = false,
			WallBangEnabled = false,
			AutoWallBangEnabled = false,
			KillAllMode = "Default",
			KnifeAuraMode = "Default",
			AutoKillAll = false,
			KnifeAura = false,
			KnifeAuraRange = 20,
			SilentThrow = false,
			KnifeThrowAura = 1000,
			RoundTimer = false,
			NotifyGunDropped = false,
			NotifyMurderer = false,
			NotifySheriff = false,
			HighlightMurderer = false,
			InfoMurderer = false,
			BoxMurderer = false,
			TracersMurderer = false,
			SkeletonMurderer = false,
			HighlightSheriff = false,
			InfoSheriff = false,
			BoxSheriff = false,
			TracersSheriff = false,
			SkeletonSheriff = false,
			HighlightInnocent = false,
			InfoInnocent = false,
			BoxInnocent = false,
			TracersInnocent = false,
			SkeletonInnocent = false,
			ESPGunDropped = false,
			ESPColorInnocent = Color3.fromRGB(0, 255, 0),
			ESPColorMurderer = Color3.fromRGB(255, 0, 0),
			ESPColorSheriff = Color3.fromRGB(0, 0, 255),
			ButtonsLocked = true,
		},
		PlayerData = {},
		Buttons = {},
	}

	local function fn5(character)
		tbl.Character = character

		if not character then
			tbl.Humanoid = nil
			tbl.RootPart = nil
			tbl.Backpack = nil
			tbl.Camera = nil
			return
		end

		tbl.Humanoid = character:WaitForChild("Humanoid", 5)
		tbl.RootPart = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
		tbl.Backpack = localPlayer:WaitForChild("Backpack")
		tbl.Camera = workspace_.CurrentCamera

		if tbl.Config.Invisible then
			tbl.ToggleInvisible(true)
		end
	end

	if localPlayer.Character then
		fn5(localPlayer.Character)
	end

	fn3(localPlayer.CharacterAdded:Connect(fn5))

	fn3(localPlayer.CharacterRemoving:Connect(function()
		fn5(nil)
	end))

	local v2 = nil

	tbl.ToggleInvisible = function(invisible)
		tbl.Config.Invisible = invisible

		if v2 then
			fn4(v2)
			v2 = nil
		end

		if not invisible then
			if tbl.Humanoid then
				tbl.Humanoid.CameraOffset = Vector3.zero
			end

			if tbl.Character then
				for _, descendant in pairs(tbl.Character:GetDescendants()) do
					if descendant:IsA("BasePart") and descendant.Name ~= "HumanoidRootPart" then
						descendant.Transparency = 0
					end
				end
			end

			return
		end

		if tbl.Character then
			for _, descendant in pairs(tbl.Character:GetDescendants()) do
				if descendant:IsA("BasePart") and descendant.Name ~= "HumanoidRootPart" then
					descendant.Transparency = 0.5
				end
			end
		end

		v2 = fn3(tbl.RunService.Heartbeat:Connect(function()
			local rootPart = tbl.RootPart
			local humanoid = tbl.Humanoid
			if not rootPart or not humanoid or not rootPart.Parent then
				return
			end
			local cFrame = rootPart.CFrame
			local cFrame2 = cFrame * CFrame.new(0, -200000, 0)
			rootPart.CFrame = cFrame2
			humanoid.CameraOffset = cFrame2:ToObjectSpace(CFrame.new(cFrame.Position)).Position
			tbl.RunService.RenderStepped:Wait()

			if rootPart and rootPart.Parent then
				rootPart.CFrame = cFrame
			end
		end))
	end

	local v3 = nil
	local ControlModule = nil

	local function fn6()
		task.spawn(function()
			local playerScripts = tbl.Player:FindFirstChild("PlayerScripts")

			if playerScripts then
				local playerModule = playerScripts:WaitForChild("PlayerModule", 2)

				if playerModule then
					pcall(function()
						ControlModule = require(playerModule:FindFirstChild("ControlModule"))
					end)
				end
			end
		end)
	end

	fn6()

	tbl.ToggleFly = function(flyEnabled)
		if flyEnabled ~= nil then
			tbl.Config.FlyEnabled = flyEnabled
		end

		if v3 then
			fn4(v3)
			v3 = nil
		end

		if tbl.RootPart then
			for _, child in ipairs(tbl.RootPart:GetChildren()) do
				if child.Name == "VisionFlyGyro" or child.Name == "VisionFlyVel" then
					child:Destroy()
				end
			end

			if tbl.Humanoid then
				tbl.Humanoid.PlatformStand = false
			end
		end

		if not tbl.Config.FlyEnabled then
			return
		end

		if not tbl.Character or not tbl.RootPart or not tbl.Humanoid then
			return
		end
		local rootPart = tbl.RootPart
		local currentCamera2 = workspace_.CurrentCamera
		local bodyGyro = Instance.new("BodyGyro")
		bodyGyro.Name = "VisionFlyGyro"
		bodyGyro.P = 90000
		bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
		bodyGyro.CFrame = rootPart.CFrame
		bodyGyro.Parent = rootPart
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.Name = "VisionFlyVel"
		bodyVelocity.Velocity = Vector3.zero
		bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
		bodyVelocity.Parent = rootPart

		v3 = fn3(tbl.RunService.RenderStepped:Connect(function()
			if not tbl.Config.FlyEnabled then
				tbl.ToggleFly(false)
				return
			end

			if not tbl.Character or not tbl.RootPart or not tbl.RootPart.Parent or not tbl.Humanoid or tbl.Humanoid.Health <= 0 then
				if v3 then
					fn4(v3)
					v3 = nil
				end

				pcall(function()
					bodyGyro:Destroy()
					bodyVelocity:Destroy()
				end)

				return
			end

			tbl.Humanoid.PlatformStand = true
			bodyGyro.CFrame = currentCamera2.CFrame
			local vector = Vector3.zero

			if ControlModule and ControlModule.GetMoveVector then
				pcall(function()
					vector = ControlModule:GetMoveVector()
				end)
			end

			local n = 0

			if userInputService:IsKeyDown(Enum.KeyCode.E) then
				n = 1
			end

			if userInputService:IsKeyDown(Enum.KeyCode.Q) then
				n = -1
			end

			local flySpeed = tbl.Config.FlySpeed

			if vector.Magnitude > 0 or n ~= 0 then
				local cFrame = currentCamera2.CFrame
				bodyVelocity.Velocity = cFrame.RightVector * vector.X * flySpeed + cFrame.LookVector * -vector.Z * flySpeed + Vector3.new(0, n * flySpeed, 0)
			else
				bodyVelocity.Velocity = Vector3.zero
			end
		end))
	end

	if tbl.Player then
		fn3(tbl.Player.CharacterAdded:Connect(function(character)
			fn6()
			local humanoid = character:WaitForChild("Humanoid", 10)
			local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)

			if humanoidRootPart and humanoid then
				tbl.Character = character
				tbl.RootPart = humanoidRootPart
				tbl.Humanoid = humanoid

				if tbl.Config.FlyEnabled then
					task.wait()
					tbl.ToggleFly()
				end
			end
		end))
	end

	tbl.Rejoin = function()
		if not teleportService then
			return
		end

		if not tbl.Player then
			return
		end

		pcall(function()
			teleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, tbl.Player)
		end)
	end

	tbl.ServerHop = function()
		if not teleportService or not tbl.Player then
			return
		end
		local str = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"

		local ok2, result2 = pcall(function()
			return httpService:JSONDecode(game:HttpGet(str))
		end)

		if ok2 and result2 and result2.data then
			for _, v4 in ipairs(result2.data) do
				if v4.id ~= game.JobId and v4.playing < v4.maxPlayers then
					teleportService:TeleportToPlaceInstance(game.PlaceId, v4.id, tbl.Player)
					return
				end
			end
		end

		teleportService:Teleport(game.PlaceId, tbl.Player)
	end

	local tbl2 = {
		Lobby = true,
		RegularLobby = true,
		ServerStatus = true,
		EffectLoader = true,
		RoundTimerPart = true,
		WeaponDisplays = true,
		Camera = true,
		Terrain = true,
		PetContainer = true,
		GameSettings = true,
		LoadLobby = true,
		ServerVersion = true,
		RCCars = true,
	}

	local function fn7()
		local lobby = workspace_:FindFirstChild("Lobby") or workspace_:FindFirstChild("RegularLobby")
		if lobby and (lobby:IsA("Model") or lobby:IsA("Folder")) then
			return lobby
		end

		for _, child in ipairs(workspace_:GetChildren()) do
			if (child:IsA("Model") or child:IsA("Folder")) and not players:GetPlayerFromCharacter(child) then
				if child.Name:lower():find("lobby") and child:FindFirstChild("Spawns") then
					return child
				end
			end
		end

		for _, child in ipairs(workspace_:GetChildren()) do
			if (child:IsA("Model") or child:IsA("Folder")) and not players:GetPlayerFromCharacter(child) then
				if child.Name:lower():find("lobby") then
					return child
				end
			end
		end

		return nil
	end

	local function fn8()
		for _, child in ipairs(workspace_:GetChildren()) do
			if (child:IsA("Model") or child:IsA("Folder")) and not tbl2[child.Name] and not players:GetPlayerFromCharacter(child) then
				if child:FindFirstChild("Spawns") or child:FindFirstChild("CoinContainer") or child:FindFirstChild("CoinArea") or child:FindFirstChild("Coin_Server", true) or child:FindFirstChild("GunDrop") then
					return child
				end
			end
		end

		return nil
	end

	tbl.GetTimer = function()
		local roundTimerPart = workspace_:FindFirstChild("RoundTimerPart")

		if roundTimerPart then
			local attribute = roundTimerPart:GetAttribute("Time")
			if typeof(attribute) == "number" and attribute > 0 then
				return attribute
			end
			local surfaceGui = roundTimerPart:FindFirstChild("SurfaceGui")

			if surfaceGui and surfaceGui.Enabled then
				local timer = surfaceGui:FindFirstChild("Timer")

				if timer and timer.Text and timer.Text ~= "" then
					local text = timer.Text
					local v4 = string.match(text, "(%d+)m")
					local v5 = string.match(text, "(%d+)s")
					if v5 then
						return (tonumber(v4) or 0) * 60 + (tonumber(v5) or 0)
					end
				end
			end
		end

		return nil
	end

	tbl.TeleportToMap = function()
		local character = tbl.Character or tbl.RootPart and tbl.RootPart.Parent
		if not character then
			return
		end
		local v4 = fn8()
		if not v4 then
			return
		end
		local spawns = v4:FindFirstChild("Spawns")
		if not spawns then
			return
		end
		local tbl3 = {}

		for _, child in ipairs(spawns:GetChildren()) do
			if child:IsA("BasePart") then
				table.insert(tbl3, child)
			end
		end

		local spawn = nil

		if #tbl3 > 0 then
			spawn = tbl3[math.random(1, #tbl3)]
		end

		spawn = spawn or spawns:FindFirstChild("Spawn") or spawns:FindFirstChild("PlayerSpawn")

		if spawn and spawn:IsA("BasePart") then
			character:PivotTo(spawn.CFrame * CFrame.new(0, 5, 0))
		end
	end

	tbl.TeleportToLobby = function()
		local character = tbl.Character or tbl.RootPart and tbl.RootPart.Parent
		if not character then
			return
		end
		local v4 = fn7()
		if not v4 then
			return
		end
		local spawns = v4:FindFirstChild("Spawns")
		if not spawns then
			return
		end
		local tbl3 = {}

		for _, child in ipairs(spawns:GetChildren()) do
			if child:IsA("BasePart") then
				table.insert(tbl3, child)
			end
		end

		local spawnLocation = nil

		if #tbl3 > 0 then
			spawnLocation = tbl3[math.random(1, #tbl3)]
		end

		spawnLocation = spawnLocation or spawns:FindFirstChild("SpawnLocation")

		if spawnLocation and spawnLocation:IsA("BasePart") then
			character:PivotTo(spawnLocation.CFrame * CFrame.new(0, 5, 0))
		end
	end

	tbl.GetPlayerByName = function(arg)
		if not arg then
			return nil
		end

		for _, player in ipairs(players:GetPlayers()) do
			if player.Name:lower() == arg:lower() then
				return player
			end
		end

		return nil
	end

	tbl.FindMurderer = function()
		if tbl.PlayerData then
			for k, v4 in pairs(tbl.PlayerData) do
				if v4.Role ~= "Murderer" then
					continue
				end
				local v5 = tbl.GetPlayerByName(k)
				if v5 then
					return v5
				end
			end
		end

		for _, player in ipairs(players:GetPlayers()) do
			local backpack = player:FindFirstChild("Backpack")
			if backpack and backpack:FindFirstChild("Knife") or player.Character and player.Character:FindFirstChild("Knife") then
				return player
			end
		end

		return nil
	end

	tbl.FindSheriff = function()
		if tbl.PlayerData then
			for k, v4 in pairs(tbl.PlayerData) do
				if v4.Role == "Sheriff" or v4.Role == "Hero" then
					local v5 = tbl.GetPlayerByName(k)
					if v5 then
						return v5
					end
				end
			end
		end

		for _, player in ipairs(players:GetPlayers()) do
			local backpack = player:FindFirstChild("Backpack")
			if backpack and backpack:FindFirstChild("Gun") or player.Character and player.Character:FindFirstChild("Gun") then
				return player
			end
		end

		return nil
	end

	tbl.FindInnocent = function(arg)
		if not arg or not tbl.PlayerData then
			return false
		end
		local v4 = tbl.PlayerData[arg.Name]

		if v4 then
			if v4.Role == "Innocent" then
				return true
			end
		end

		return false
	end

	local playerDataChanged = replicatedStorage:WaitForChild("Remotes"):WaitForChild("Gameplay"):WaitForChild("PlayerDataChanged", 5)
	if not playerDataChanged then
		return
	end

	if playerDataChanged then
		playerDataChanged.OnClientEvent:Connect(function(playerData)
			if typeof(playerData) == "table" then
				tbl.PlayerData = playerData
			end
		end)
	end

	local tbl3 = {}

	getgenv().ClearESP = function()
		for _, v4 in pairs(tbl3) do
			for _, v5 in pairs(v4) do
				if typeof(v5) == "table" then
					for _, v6 in ipairs(v5) do
						v6:Remove()
					end
				elseif v5 and v5.Remove then
					v5:Remove()
				end
			end
		end

		table.clear(tbl3)

		for _, player in ipairs(players:GetPlayers()) do
			if player.Character then
				local visionHighlight = player.Character:FindFirstChild("VisionHighlight")

				if visionHighlight then
					visionHighlight:Destroy()
				end

				local visionInfoESP = player.Character:FindFirstChild("VisionInfoESP")

				if visionInfoESP then
					visionInfoESP:Destroy()
				end
			end
		end

		local v4 = fn8()

		if v4 then
			local gunDrop = v4:FindFirstChild("GunDrop")

			if gunDrop then
				local visionGunHighlight = gunDrop:FindFirstChild("VisionGunHighlight")

				if visionGunHighlight then
					visionGunHighlight:Destroy()
				end

				local visionGunInfo = gunDrop:FindFirstChild("VisionGunInfo")

				if visionGunInfo then
					visionGunInfo:Destroy()
				end
			end
		end
	end

	local function fn9(arg, arg2)
		local v4 = Drawing.new(arg)

		for k, v5 in pairs(arg2) do
			v4[k] = v5
		end

		return v4
	end

	fn3(runService.RenderStepped:Connect(function()
		local v4 = tbl.FindMurderer()
		local v5 = tbl.FindSheriff()

		for _, player in ipairs(players:GetPlayers()) do
			if player ~= players.LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
				local espColorMurderer, str

				if v4 and player == v4 then
					espColorMurderer = tbl.Config.ESPColorMurderer
					str = "Murderer"
				elseif v5 and player == v5 then
					espColorMurderer = tbl.Config.ESPColorSheriff
					str = "Sheriff"
				else
					str = nil
					espColorMurderer = nil

					if tbl.FindInnocent(player) then
						espColorMurderer = tbl.Config.ESPColorInnocent
						str = "Innocent"
					end
				end

				if str then
					if not tbl3[player] then
						tbl3[player] = {
							Box = fn9("Square", { Thickness = 1, Filled = false, ZIndex = 2 }),
							Tracer = fn9("Line", { Thickness = 1, Transparency = 1, ZIndex = 1 }),
							Skeleton = {},
						}

						for i = 1, 16 do
							table.insert(tbl3[player].Skeleton, fn9("Line", { Thickness = 1, Transparency = 1, ZIndex = 2 }))
						end
					end

					local v6 = tbl3[player]
					local character = player.Character
					local humanoid = character.Humanoid
					local humanoidRootPart = character.HumanoidRootPart
					local head = character:FindFirstChild("Head")

					if tbl.Config["Highlight" .. str] then
						local visionHighlight = character:FindFirstChild("VisionHighlight")

						if not visionHighlight then
							visionHighlight = Instance.new("Highlight")
							visionHighlight.Name = "VisionHighlight"
							visionHighlight.FillTransparency = 0.85
							visionHighlight.OutlineTransparency = 0
							visionHighlight.Parent = character
						end

						visionHighlight.FillColor = espColorMurderer
						visionHighlight.OutlineColor = espColorMurderer
						visionHighlight.Enabled = true
					else
						local visionHighlight = character:FindFirstChild("VisionHighlight")

						if visionHighlight then
							visionHighlight:Destroy()
						end
					end

					if tbl.Config["Info" .. str] and (head or humanoidRootPart) then
						local visionInfoESP = character:FindFirstChild("VisionInfoESP")

						if not visionInfoESP then
							visionInfoESP = Instance.new("BillboardGui", character)
							visionInfoESP.Name = "VisionInfoESP"
							visionInfoESP.Size = UDim2.fromOffset(200, 50)
							visionInfoESP.StudsOffset = Vector3.new(0, 3.5, 0)
							visionInfoESP.AlwaysOnTop = true
							local textLabel = Instance.new("TextLabel", visionInfoESP)
							textLabel.Name = "InfoLabel"
							textLabel.BackgroundTransparency = 1
							textLabel.Size = UDim2.fromScale(1, 1)
							textLabel.TextStrokeTransparency = 0
							textLabel.Font = Enum.Font.SourceSansBold
							textLabel.TextSize = 16
							textLabel.RichText = true
						end

						visionInfoESP.Adornee = head or humanoidRootPart
						local n = math.floor((currentCamera.CFrame.Position - humanoidRootPart.Position).Magnitude)
						local infoLabel = visionInfoESP:FindFirstChild("InfoLabel")

						if infoLabel then
							infoLabel.Text = string.format("%s\n<font size='11' color='rgb(221, 221, 221)'>[%d]</font>", player.Name, n)
							infoLabel.TextColor3 = espColorMurderer
						end
					else
						local visionInfoESP = character:FindFirstChild("VisionInfoESP")

						if visionInfoESP then
							visionInfoESP:Destroy()
						end
					end

					local v7, v8 = currentCamera:WorldToViewportPoint(humanoidRootPart.Position)

					if v8 then
						local n = math.abs(2500 / v7.Z)
						local n2 = n / 2

						if tbl.Config["Box" .. str] then
							v6.Box.Visible = true
							v6.Box.Size = Vector2.new(n2, n)
							v6.Box.Position = Vector2.new(v7.X - n2 / 2, v7.Y - n / 2)
							v6.Box.Color = espColorMurderer
						else
							v6.Box.Visible = false
						end

						if tbl.Config["Tracers" .. str] then
							v6.Tracer.Visible = true
							v6.Tracer.From = Vector2.new(currentCamera.ViewportSize.X / 2, currentCamera.ViewportSize.Y)
							v6.Tracer.To = Vector2.new(v7.X, v7.Y + n / 2)
							v6.Tracer.Color = espColorMurderer
						else
							v6.Tracer.Visible = false
						end

						if tbl.Config["Skeleton" .. str] then
							local function fn10(arg)
								if not arg then
									return nil
								end
								local v9 = currentCamera:WorldToViewportPoint(arg.Position)
								return Vector2.new(v9.X, v9.Y)
							end

							local tbl4 = humanoid.RigType == Enum.HumanoidRigType.R15 and {
								{ "Head", "UpperTorso" },
								{ "UpperTorso", "LowerTorso" },
								{ "LowerTorso", "LeftUpperLeg" },
								{ "LeftUpperLeg", "LeftLowerLeg" },
								{ "LeftLowerLeg", "LeftFoot" },
								{ "LowerTorso", "RightUpperLeg" },
								{ "RightUpperLeg", "RightLowerLeg" },
								{ "RightLowerLeg", "RightFoot" },
								{ "UpperTorso", "LeftUpperArm" },
								{ "LeftUpperArm", "LeftLowerArm" },
								{ "LeftLowerArm", "LeftHand" },
								{ "UpperTorso", "RightUpperArm" },
								{ "RightUpperArm", "RightLowerArm" },
								{ "RightLowerArm", "RightHand" },
							} or {
								{ "Head", "Torso" },
								{ "Torso", "Left Arm" },
								{ "Torso", "Right Arm" },
								{ "Torso", "Left Leg" },
								{ "Torso", "Right Leg" },
							}

							for i, v9 in ipairs(tbl4) do
								local v10 = character:FindFirstChild(v9[1])
								local v11 = character:FindFirstChild(v9[2])

								if v10 and v11 and v6.Skeleton[i] then
									v6.Skeleton[i].Visible = true
									v6.Skeleton[i].From = fn10(v10)
									v6.Skeleton[i].To = fn10(v11)
									v6.Skeleton[i].Color = espColorMurderer
								elseif v6.Skeleton[i] then
									v6.Skeleton[i].Visible = false
								end
							end
						else
							for _, v9 in ipairs(v6.Skeleton) do
								v9.Visible = false
							end
						end
					else
						v6.Box.Visible = false
						v6.Tracer.Visible = false

						for _, v9 in ipairs(v6.Skeleton) do
							v9.Visible = false
						end
					end
				elseif tbl3[player] then
					tbl3[player].Box.Visible = false
					tbl3[player].Tracer.Visible = false

					for _, v6 in ipairs(tbl3[player].Skeleton) do
						v6.Visible = false
					end
				end
			end
		end

		local gunDrop = fn8()
		gunDrop = gunDrop and gunDrop:FindFirstChild("GunDrop")

		if gunDrop and gunDrop:IsA("BasePart") then
			local espGunDropped = tbl.Config.ESPGunDropped

			if espGunDropped then
				local visionGunHighlight = gunDrop:FindFirstChild("VisionGunHighlight")

				if not visionGunHighlight then
					visionGunHighlight = Instance.new("Highlight")
					visionGunHighlight.Name = "VisionGunHighlight"
					visionGunHighlight.FillTransparency = 0.4
					visionGunHighlight.OutlineTransparency = 0
					visionGunHighlight.Parent = gunDrop
				end

				visionGunHighlight.FillColor = Color3.fromRGB(0, 255, 255)
				visionGunHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
				visionGunHighlight.Enabled = true
			else
				local visionGunHighlight = gunDrop:FindFirstChild("VisionGunHighlight")

				if visionGunHighlight then
					visionGunHighlight:Destroy()
				end
			end

			if espGunDropped then
				local visionGunInfo = gunDrop:FindFirstChild("VisionGunInfo")

				if not visionGunInfo then
					visionGunInfo = Instance.new("BillboardGui", gunDrop)
					visionGunInfo.Name = "VisionGunInfo"
					visionGunInfo.Size = UDim2.fromOffset(100, 40)
					visionGunInfo.StudsOffset = Vector3.new(0, 2, 0)
					visionGunInfo.AlwaysOnTop = true
					local textLabel = Instance.new("TextLabel", visionGunInfo)
					textLabel.BackgroundTransparency = 1
					textLabel.Size = UDim2.fromScale(1, 1)
					textLabel.TextStrokeTransparency = 0
					textLabel.Font = Enum.Font.SourceSansBold
					textLabel.TextSize = 18
					textLabel.RichText = true
					textLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
				end

				local n = math.floor((currentCamera.CFrame.Position - gunDrop.Position).Magnitude)
				local textLabel = visionGunInfo:FindFirstChildOfClass("TextLabel")

				if textLabel then
					textLabel.Text = string.format("<b>GUN</b>\n<font size='13' color='rgb(221, 221, 221)'>[%d]</font>", n)
				end
			else
				local visionGunInfo = gunDrop:FindFirstChild("VisionGunInfo")

				if visionGunInfo then
					visionGunInfo:Destroy()
				end
			end
		end

		for k, v6 in pairs(tbl3) do
			if not k.Parent then
				v6.Box:Remove()
				v6.Tracer:Remove()

				for _, v7 in ipairs(v6.Skeleton) do
					v7:Remove()
				end

				tbl3[k] = nil
			end
		end
	end))

	tbl.Players.PlayerRemoving:Connect(function(player)
		if tbl3[player] then
			tbl3[player].Box:Remove()
			tbl3[player].Tracer:Remove()

			for _, v4 in ipairs(tbl3[player].Skeleton) do
				v4:Remove()
			end

			tbl3[player] = nil
		end
	end)

	tbl.FlingTarget = function(arg)
		if not arg or not arg.Character then
			return
		end
		local character = players.LocalPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local rootPart = humanoid and humanoid.RootPart
		local character2 = arg.Character
		local humanoid2 = character2:FindFirstChildOfClass("Humanoid")
		local rootPart2 = humanoid2 and humanoid2.RootPart
		local head = character2:FindFirstChild("Head")
		local accessory = character2:FindFirstChildOfClass("Accessory")
		local handle = accessory and accessory:FindFirstChild("Handle")

		if character and humanoid and rootPart then
			if rootPart.AssemblyLinearVelocity.Magnitude < 50 then
				local cFrame = rootPart.CFrame
				getgenv().OldPos = cFrame
			end

			local fallenPartsDestroyHeight = workspace_.FallenPartsDestroyHeight
			getgenv().FPDH = fallenPartsDestroyHeight
			workspace_.FallenPartsDestroyHeight = -50000

			if head then
				workspace_.CurrentCamera.CameraSubject = head
			elseif not head and handle then
				workspace_.CurrentCamera.CameraSubject = handle
			elseif humanoid2 and rootPart2 then
				workspace_.CurrentCamera.CameraSubject = humanoid2
			end

			if not character2:FindFirstChildWhichIsA("BasePart") then
				return
			end

			local function fn10(arg2, arg3, arg4)
				if not rootPart or not rootPart.Parent then
					return
				end
				rootPart.CFrame = CFrame.new(arg2.Position) * arg3 * arg4

				if character.PrimaryPart then
					character:PivotTo(CFrame.new(arg2.Position) * arg3 * arg4)
				end

				rootPart.AssemblyLinearVelocity = Vector3.new(10000, 10000, 10000)
				rootPart.AssemblyAngularVelocity = Vector3.new(10000, 10000, 10000)
			end

			local function fn11(arg2)
				local now = tick()
				local n = 0

				while true do
					pcall(function()
						if rootPart and humanoid2 and arg2.Parent then
							if arg2.AssemblyLinearVelocity.Magnitude < 50 then
								n += 100
								local n2 = humanoid2.MoveDirection * arg2.AssemblyLinearVelocity.Magnitude / 1.25
								local cframe = CFrame.Angles
								fn10(arg2, CFrame.new(0, 1.5, 0) + n2, cframe(math.rad(n), 0, 0))
								task.wait()
								local n3 = humanoid2.MoveDirection * arg2.AssemblyLinearVelocity.Magnitude / 1.25
								local cframe2 = CFrame.Angles
								fn10(arg2, CFrame.new(0, -1.5, 0) + n3, cframe2(math.rad(n), 0, 0))
								task.wait()
								local n4 = humanoid2.MoveDirection * arg2.AssemblyLinearVelocity.Magnitude / 1.25
								local cframe3 = CFrame.Angles
								fn10(arg2, CFrame.new(2.25, 1.5, -2.25) + n4, cframe3(math.rad(n), 0, 0))
								task.wait()
								local n5 = humanoid2.MoveDirection * arg2.AssemblyLinearVelocity.Magnitude / 1.25
								local cframe4 = CFrame.Angles
								fn10(arg2, CFrame.new(-2.25, -1.5, 2.25) + n5, cframe4(math.rad(n), 0, 0))
								task.wait()
								local moveDirection = humanoid2.MoveDirection
								local cframe5 = CFrame.Angles
								fn10(arg2, CFrame.new(0, 1.5, 0) + moveDirection, cframe5(math.rad(n), 0, 0))
								task.wait()
								local moveDirection2 = humanoid2.MoveDirection
								local cframe6 = CFrame.Angles
								fn10(arg2, CFrame.new(0, -1.5, 0) + moveDirection2, cframe6(math.rad(n), 0, 0))
								task.wait()
							else
								local cframe = CFrame.Angles
								fn10(arg2, CFrame.new(0, 1.5, humanoid2.WalkSpeed), cframe(1.5707963267948966, 0, 0))
								task.wait()
								local cframe2 = CFrame.Angles
								fn10(arg2, CFrame.new(0, -1.5, -humanoid2.WalkSpeed), cframe2(0, 0, 0))
								task.wait()
								local cframe3 = CFrame.Angles
								fn10(arg2, CFrame.new(0, 1.5, humanoid2.WalkSpeed), cframe3(1.5707963267948966, 0, 0))
								task.wait()
								local cframe4 = CFrame.Angles
								fn10(arg2, CFrame.new(0, 1.5, rootPart2.AssemblyLinearVelocity.Magnitude / 1.25), cframe4(1.5707963267948966, 0, 0))
								task.wait()
								local cframe5 = CFrame.Angles
								fn10(arg2, CFrame.new(0, -1.5, -rootPart2.AssemblyLinearVelocity.Magnitude / 1.25), cframe5(0, 0, 0))
								task.wait()
								local cframe6 = CFrame.Angles
								fn10(arg2, CFrame.new(0, 1.5, rootPart2.AssemblyLinearVelocity.Magnitude / 1.25), cframe6(1.5707963267948966, 0, 0))
								task.wait()
								local cframe7 = CFrame.Angles
								fn10(arg2, CFrame.new(0, -1.5, 0), cframe7(1.5707963267948966, 0, 0))
								task.wait()
								local cframe8 = CFrame.Angles
								fn10(arg2, CFrame.new(0, -1.5, 0), cframe8(0, 0, 0))
								task.wait()
								local cframe9 = CFrame.Angles
								fn10(arg2, CFrame.new(0, -1.5, 0), cframe9(-1.5707963267948966, 0, 0))
								task.wait()
								local cframe10 = CFrame.Angles
								fn10(arg2, CFrame.new(0, -1.5, 0), cframe10(0, 0, 0))
								task.wait()
							end
						end
					end)

					local flag = arg2.Parent == arg.Character
					local flag2 = humanoid2 and not humanoid2.Sit
					local flag3 = humanoid and humanoid.Health > 0
					local flag4 = arg2.AssemblyLinearVelocity.Magnitude < 500
					local flag5 = tick() < now + 2.5
					if not (not flag or not flag2 or not flag3 or not flag4 or not flag5) then
						continue
					end
					break
				end
			end

			local bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.Name = "VisionHub_FlingVelocity"
			bodyVelocity.Parent = rootPart
			bodyVelocity.Velocity = Vector3.new(10000, 10000, 10000)
			bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
			local bodyAngularVelocity = Instance.new("BodyAngularVelocity")
			bodyAngularVelocity.Name = "VisionHub_SpinVelocity"
			bodyAngularVelocity.Parent = rootPart
			bodyAngularVelocity.AngularVelocity = Vector3.new(10000, 10000, 10000)
			bodyAngularVelocity.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

			if rootPart2 and head then
				if (rootPart2.CFrame.p - head.CFrame.p).Magnitude > 5 then
					fn11(head)
				else
					fn11(rootPart2)
				end
			elseif rootPart2 and not head then
				fn11(rootPart2)
			elseif not rootPart2 and head then
				fn11(head)
			elseif not rootPart2 and not head and accessory and handle then
				fn11(handle)
			else
				if bodyVelocity then
					bodyVelocity:Destroy()
				end

				if bodyAngularVelocity then
					bodyAngularVelocity:Destroy()
				end
			end

			if bodyVelocity then
				bodyVelocity:Destroy()
			end

			if bodyAngularVelocity then
				bodyAngularVelocity:Destroy()
			end

			humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
			workspace_.CurrentCamera.CameraSubject = humanoid
			humanoid:ChangeState("GettingUp")

			if getgenv().OldPos then
				rootPart.CFrame = getgenv().OldPos * CFrame.new(0, 0.5, 0)
			end

			for _, child in ipairs(character:GetChildren()) do
				if child:IsA("BasePart") then
					child.AssemblyLinearVelocity = Vector3.zero
					child.AssemblyAngularVelocity = Vector3.zero
				end
			end

			workspace_.FallenPartsDestroyHeight = getgenv().FPDH or -500
		end
	end

	tbl.Prediction = function()
		local v4 = tbl.FindMurderer()
		if not v4 or not v4.Character then
			return nil
		end
		local character = v4.Character
		local humanoid = character:FindFirstChild("Humanoid")
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if not humanoid or humanoid.Health <= 0 or not humanoidRootPart then
			return nil
		end
		local serverStatsItem = stats and stats.Network:FindFirstChild("ServerStatsItem")
		local n = 0.06

		if serverStatsItem then
			n = stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000
		end

		local n2 = math.clamp(n + 0.04, 0, 1)
		local position = humanoidRootPart.Position
		local assemblyLinearVelocity = humanoidRootPart.AssemblyLinearVelocity
		local moveDirection = humanoid.MoveDirection

		if assemblyLinearVelocity.Magnitude < 0.1 and moveDirection.Magnitude > 0 then
			assemblyLinearVelocity = moveDirection * humanoid.WalkSpeed
		end

		local n3 = position + assemblyLinearVelocity * n2

		if humanoid.FloorMaterial == Enum.Material.Air then
			n3 += 0.5 * Vector3.new(0, -workspace_.Gravity, 0) * n2 ^ 2
		end

		if n3.Y < position.Y - 1 and humanoid.FloorMaterial ~= Enum.Material.Air then
			n3 = Vector3.new(n3.X, position.Y, n3.Z)
		end

		return n3
	end

	tbl.ShootMurderer = function()
		if not tbl.Character or not tbl.RootPart or not tbl.Backpack then
			return false
		end
		local gun = tbl.Character:FindFirstChild("Gun") or tbl.Backpack:FindFirstChild("Gun")
		if not gun then
			return false
		end
		local v4 = tbl.Prediction()
		if not v4 then
			return false
		end
		local v5 = tbl.FindMurderer()
		if not v5 or not v5.Character then
			return false
		end
		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = { tbl.Character, workspace_.CurrentCamera }
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		local position = tbl.RootPart.Position
		local n = v4 - position
		local hit = workspace_:Raycast(position, n.Unit * (n.Magnitude + 2), raycastParams)
		if hit and hit.Instance and not hit.Instance:IsDescendantOf(v5.Character) then
			return false
		end

		if gun.Parent == tbl.Backpack then
			gun.Parent = tbl.Character
			task.wait()
		end

		local knifeLocal = gun:FindFirstChild("KnifeLocal")
		local shoot = gun:FindFirstChild("Shoot")

		if knifeLocal then
			local createBeam = knifeLocal:FindFirstChild("CreateBeam")
			local remoteFunction = createBeam and createBeam:FindFirstChild("RemoteFunction")

			if remoteFunction then
				task.spawn(function()
					pcall(function()
						remoteFunction:InvokeServer(1, v4, "AH2")
					end)
				end)
			end
		elseif shoot and shoot:IsA("RemoteEvent") then
			task.spawn(function()
				pcall(function()
					local cframe = CFrame.new
					shoot:FireServer(CFrame.lookAt(position, v4), cframe(v4))
				end)
			end)
		end

		return true
	end

	local thread = nil

	tbl.ToggleAutoShootMurderer = function(autoShootMurderer)
		tbl.Config.AutoShootMurderer = autoShootMurderer

		if thread then
			task.cancel(thread)
			thread = nil
		end

		if autoShootMurderer then
			thread = task.spawn(function()
				while tbl.Config.AutoShootMurderer do
					tbl.ShootMurderer()
					task.wait(0.2)
				end
			end)
		end
	end

	tbl.WallBangShoot = function()
		if not tbl.Character or not tbl.RootPart or not tbl.Backpack then
			return false
		end
		local gun = tbl.Character:FindFirstChild("Gun") or tbl.Backpack:FindFirstChild("Gun")
		if not gun then
			return false
		end
		local v4 = tbl.FindMurderer()
		if not v4 or not v4.Character then
			return false
		end
		local humanoidRootPart = v4.Character:FindFirstChild("HumanoidRootPart")
		local humanoid = v4.Character:FindFirstChild("Humanoid")
		if not humanoidRootPart or not humanoid or humanoid.Health <= 0 then
			return false
		end
		local serverStatsItem = stats and stats.Network:FindFirstChild("ServerStatsItem")
		local n = 0.06

		if serverStatsItem then
			n = stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000
		end

		local n2 = math.clamp(n + 0.05, 0, 1.2)
		local position = humanoidRootPart.Position
		local assemblyLinearVelocity = humanoidRootPart.AssemblyLinearVelocity

		if assemblyLinearVelocity.Magnitude < 0.1 and humanoid.MoveDirection.Magnitude > 0 then
			assemblyLinearVelocity = humanoid.MoveDirection * humanoid.WalkSpeed
		end

		local n3 = position + assemblyLinearVelocity * n2

		if humanoid.FloorMaterial == Enum.Material.Air then
			n3 += Vector3.new(0, 0.5 * workspace.Gravity * n2 ^ 2, 0)
		end

		if gun.Parent == tbl.Backpack then
			gun.Parent = tbl.Character
			task.wait()
		end

		local shoot = gun:FindFirstChild("Shoot")
		local knifeLocal = gun:FindFirstChild("KnifeLocal")

		if shoot and shoot:IsA("RemoteEvent") then
			task.spawn(function()
				pcall(function()
					local cframe = CFrame.new
					local position2 = tbl.RootPart.Position
					shoot:FireServer(CFrame.new(n3), cframe(position2))
				end)
			end)
		elseif knifeLocal then
			local createBeam = knifeLocal:FindFirstChild("CreateBeam")
			local remoteFunction = createBeam and createBeam:FindFirstChild("RemoteFunction")

			if remoteFunction then
				task.spawn(function()
					pcall(function()
						remoteFunction:InvokeServer(1, n3, "AH2")
					end)
				end)
			end
		end

		return true
	end

	tbl.ToggleWallBang = function(autoWallBangEnabled)
		tbl.Config.AutoWallBangEnabled = autoWallBangEnabled

		if autoWallBangEnabled then
			task.spawn(function()
				while tbl.Config.AutoWallBangEnabled do
					tbl.WallBangShoot()
					task.wait(0.2)
				end
			end)
		end
	end

	tbl.TeleportToPlayer = function(arg)
		if not tbl.RootPart then
			return false
		end

		if not (arg and arg.Character and arg.Character.PrimaryPart) then
			return false
		end

		return (pcall(function()
			tbl.Character:PivotTo(arg.Character.PrimaryPart.CFrame * CFrame.new(0, 3, 0))
		end))
	end

	local v4 = nil
	local walkSpeed = 16

	tbl.EnableWalkSpeed = function(enableWalkSpeed)
		tbl.Config.EnableWalkSpeed = enableWalkSpeed

		if enableWalkSpeed then
			if v4 then
				fn4(v4)
			end

			v4 = fn3(runService.Heartbeat:Connect(function()
				if tbl.Humanoid and tbl.Humanoid.WalkSpeed ~= tbl.Config.WalkSpeed then
					tbl.Humanoid.WalkSpeed = tbl.Config.WalkSpeed
				end
			end))
		else
			if v4 then
				fn4(v4)
				v4 = nil
			end

			if tbl.Humanoid then
				tbl.Humanoid.WalkSpeed = walkSpeed
			end
		end
	end

	tbl.SetWalkSpeed = function(arg)
		tbl.Config.WalkSpeed = math.clamp(arg, 16, 200)

		if tbl.Config.EnableWalkSpeed and tbl.Humanoid then
			tbl.Humanoid.WalkSpeed = tbl.Config.WalkSpeed
		end
	end

	local v5 = nil
	local jumpPower = 50

	tbl.EnableJumpPower = function(enableJumpPower)
		tbl.Config.EnableJumpPower = enableJumpPower

		if enableJumpPower then
			if v5 then
				fn4(v5)
			end

			v5 = fn3(runService.Heartbeat:Connect(function()
				if tbl.Humanoid and tbl.Humanoid.JumpPower ~= tbl.Config.JumpPower then
					tbl.Humanoid.JumpPower = tbl.Config.JumpPower
				end
			end))
		else
			if v5 then
				fn4(v5)
				v5 = nil
			end

			if tbl.Humanoid then
				tbl.Humanoid.JumpPower = jumpPower
			end
		end
	end

	tbl.SetJumpPower = function(arg)
		tbl.Config.JumpPower = math.clamp(arg, 50, 300)

		if tbl.Config.EnableJumpPower and tbl.Humanoid then
			tbl.Humanoid.JumpPower = tbl.Config.JumpPower
		end
	end

	local v6 = nil
	local tbl4 = {}

	tbl.EnableNoclip = function(noclip)
		tbl.Config.Noclip = noclip

		if noclip then
			tbl4 = {}

			if tbl.Character then
				for _, descendant in ipairs(tbl.Character:GetDescendants()) do
					if descendant:IsA("BasePart") then
						tbl4[descendant] = descendant.CanCollide
						descendant.CanCollide = false
					end
				end
			end

			if v6 then
				fn4(v6)
			end

			v6 = fn3(runService.Stepped:Connect(function()
				if not tbl.Character then
					return
				end

				for _, descendant in ipairs(tbl.Character:GetDescendants()) do
					if descendant:IsA("BasePart") then
						descendant.CanCollide = false
					end
				end
			end))
		else
			if v6 then
				fn4(v6)
				v6 = nil
			end

			for k, v7 in pairs(tbl4) do
				if k and k.Parent then
					k.CanCollide = v7
				end
			end

			tbl4 = {}
		end
	end

	local v7 = nil

	tbl.InfiniteJump = function(infiniteJump)
		tbl.Config.InfiniteJump = infiniteJump

		if infiniteJump then
			if v7 then
				fn4(v7)
			end

			v7 = fn3(userInputService.JumpRequest:Connect(function()
				if tbl.Humanoid then
					tbl.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				end
			end))
		elseif v7 then
			fn4(v7)
			v7 = nil
		end
	end

	local connection = nil

	tbl.GrabGun = function()
		local rootPart = tbl.RootPart
		if not (rootPart and rootPart.Parent) then
			return
		end
		local v8 = fn8()
		if not v8 then
			return
		end
		local gunDrop = v8:FindFirstChild("GunDrop")

		if gunDrop and gunDrop:IsA("BasePart") then
			if firetouchinterest then
				firetouchinterest(gunDrop, rootPart, 1)
				firetouchinterest(gunDrop, rootPart, 0)
			end
		end
	end

	tbl.ToggleAutoGrabGun = function(autoGrabGun)
		tbl.Config.AutoGrabGun = autoGrabGun

		if connection then
			connection:Disconnect()
			connection = nil
		end

		if autoGrabGun then
			connection = runService.Heartbeat:Connect(tbl.GrabGun)
		end
	end

	tbl.KillAll = function()
		local killAllMode = tbl.Config.KillAllMode
		local knife = tbl.Character:FindFirstChild("Knife") or tbl.Backpack:FindFirstChild("Knife")
		if not knife then
			return
		end

		if killAllMode == "Silent" then
			local events = knife:FindFirstChild("Events")
			local handleTouched = events and events:FindFirstChild("HandleTouched")
			if not handleTouched then
				return
			end

			for _, player in ipairs(players:GetPlayers()) do
				if player ~= localPlayer and fn2(player) then
					local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")

					if humanoidRootPart then
						pcall(function()
							handleTouched:FireServer(humanoidRootPart)
						end)
					end
				end
			end
		else
			local tbl5 = {}

			for _, player in ipairs(players:GetPlayers()) do
				if player ~= localPlayer and fn2(player) then
					table.insert(tbl5, player)
				end
			end

			if #tbl5 == 0 then
				return
			end

			if knife.Parent == localPlayer.Backpack then
				local humanoid = localPlayer.Character:FindFirstChild("Humanoid")

				if humanoid then
					humanoid:EquipTool(knife)
					task.wait(0.1)
				end
			end

			local knife2 = localPlayer.Character:FindFirstChild("Knife")
			if not knife2 then
				return
			end
			local events = knife2:FindFirstChild("Events")
			local handleTouched = events and events:FindFirstChild("HandleTouched")

			if handleTouched then
				for _, v8 in ipairs(tbl5) do
					if v8.Character and v8.Character:FindFirstChild("HumanoidRootPart") and fn2(v8) then
						local humanoidRootPart = v8.Character.HumanoidRootPart

						pcall(function()
							handleTouched:FireServer(humanoidRootPart)
						end)
					end
				end

				local knifeStabbed = events:FindFirstChild("KnifeStabbed")

				if knifeStabbed then
					knifeStabbed:FireServer()
				end
			end
		end
	end

	local v8 = nil

	tbl.ToggleKnifeAura = function(knifeAura)
		tbl.Config.KnifeAura = knifeAura

		if v8 then
			fn4(v8)
			v8 = nil
		end

		if knifeAura then
			v8 = fn3(runService.Heartbeat:Connect(function()
				if not tbl.Config.KnifeAura or not fn2(localPlayer) then
					return
				end
				local knifeAuraMode = tbl.Config.KnifeAuraMode
				local humanoidRootPart = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
				if not humanoidRootPart then
					return
				end
				local knife = localPlayer.Character:FindFirstChild("Knife") or localPlayer.Backpack:FindFirstChild("Knife")
				if not knife then
					return
				end
				local events = knife:FindFirstChild("Events")

				if knifeAuraMode == "Silent" then
					local handleTouched = events and events:FindFirstChild("HandleTouched")
					if not handleTouched then
						return
					end

					for _, player in ipairs(players:GetPlayers()) do
						if player ~= localPlayer and fn2(player) then
							local humanoidRootPart2 = player.Character:FindFirstChild("HumanoidRootPart")

							if humanoidRootPart2 and (humanoidRootPart2.Position - humanoidRootPart.Position).Magnitude <= tbl.Config.KnifeAuraRange then
								pcall(function()
									handleTouched:FireServer(humanoidRootPart2)
								end)
							end
						end
					end
				else
					local tbl5 = {}

					for _, player in ipairs(players:GetPlayers()) do
						if player ~= localPlayer and fn2(player) then
							local humanoidRootPart2 = player.Character:FindFirstChild("HumanoidRootPart")

							if humanoidRootPart2 and (humanoidRootPart2.Position - humanoidRootPart.Position).Magnitude <= tbl.Config.KnifeAuraRange then
								table.insert(tbl5, player)
							end
						end
					end

					if #tbl5 > 0 then
						if knife.Parent == localPlayer.Backpack then
							local humanoid = localPlayer.Character:FindFirstChild("Humanoid")

							if humanoid then
								humanoid:EquipTool(knife)
							end
						end

						local handleTouched = events and events:FindFirstChild("HandleTouched")

						if handleTouched then
							for _, v9 in ipairs(tbl5) do
								local humanoidRootPart2 = v9.Character:FindFirstChild("HumanoidRootPart")

								if humanoidRootPart2 then
									pcall(function()
										handleTouched:FireServer(humanoidRootPart2)
									end)
								end
							end

							local knifeStabbed = events:FindFirstChild("KnifeStabbed")

							if knifeStabbed then
								knifeStabbed:FireServer()
							end
						end
					end
				end
			end))
		end
	end

	local thread2 = nil

	tbl.ToggleAutoKillAll = function(autoKillAll)
		tbl.Config.AutoKillAll = autoKillAll

		if thread2 then
			task.cancel(thread2)
			thread2 = nil
		end

		if autoKillAll then
			thread2 = task.spawn(function()
				while tbl.Config.AutoKillAll do
					pcall(tbl.KillAll)
					task.wait(0.1)
				end
			end)
		end
	end

	local thread3 = nil
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local function fn10(arg, arg2)
		raycastParams.FilterDescendantsInstances = { tbl.Character, arg.Parent, currentCamera }
		return workspace_:Raycast(arg2, arg.Position - arg2, raycastParams) == nil
	end

	local function fn11(arg, arg2)
		local v9 = nil

		for _, player in ipairs(players:GetPlayers()) do
			if player ~= localPlayer and fn2(player) then
				local humanoidRootPart = player.Character.HumanoidRootPart
				local magnitude = (arg - humanoidRootPart.Position).Magnitude

				if magnitude < arg2 and fn10(humanoidRootPart, arg) then
					arg2 = magnitude
					v9 = player
				end
			end
		end

		return v9
	end

	tbl.ExecuteSilentThrow = function()
		if tbl.FindMurderer() ~= localPlayer or not fn2(localPlayer) then
			return
		end
		local knife = tbl.Character:FindFirstChild("Knife") or tbl.Backpack:FindFirstChild("Knife")
		if not knife then
			return
		end
		local knifeThrown = knife:FindFirstChild("Events") and knife.Events:FindFirstChild("KnifeThrown")
		if not knifeThrown then
			return
		end
		local v9 = fn11(tbl.RootPart.Position, tbl.Config.KnifeThrowAura)
		if not v9 then
			return
		end

		if knife.Parent == tbl.Backpack then
			tbl.Humanoid:EquipTool(knife)
			task.wait(0.05)
		end

		local humanoidRootPart = v9.Character.HumanoidRootPart
		local humanoid = v9.Character.Humanoid
		local serverStatsItem = stats and stats.Network:FindFirstChild("ServerStatsItem")
		local n = 0.06

		if serverStatsItem then
			n = stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000
		end

		local n2 = math.clamp(n + 0.05, 0.01, 1)
		local assemblyLinearVelocity = humanoidRootPart.AssemblyLinearVelocity

		if assemblyLinearVelocity.Magnitude < 0.5 and humanoid.MoveDirection.Magnitude > 0 then
			assemblyLinearVelocity = humanoid.MoveDirection * humanoid.WalkSpeed
		end

		local n3 = humanoidRootPart.Position + assemblyLinearVelocity * n2

		if humanoid.FloorMaterial == Enum.Material.Air then
			n3 -= Vector3.new(0, 0.5 * workspace_.Gravity * n2 ^ 2, 0)
		elseif n3.Y < humanoidRootPart.Position.Y - 1 then
			n3 = Vector3.new(n3.X, humanoidRootPart.Position.Y, n3.Z)
		end

		pcall(function()
			local cframe = CFrame.new
			knifeThrown:FireServer(CFrame.new(tbl.RootPart.Position), cframe(n3))
		end)
	end

	tbl.ToggleSilentThrow = function(silentThrow)
		tbl.Config.SilentThrow = silentThrow

		if thread3 then
			task.cancel(thread3)
			thread3 = nil
		end

		if silentThrow then
			thread3 = task.spawn(function()
				while tbl.Config.SilentThrow do
					if tbl.FindMurderer() == localPlayer then
						tbl.ExecuteSilentThrow()
					end

					task.wait(0.4)
				end
			end)
		end
	end

	tbl.PlayEmote = function(arg)
		local remotes = replicatedStorage:FindFirstChild("Remotes")

		if remotes and remotes:FindFirstChild("PlayEmote") then
			remotes.PlayEmote:Fire(arg)
		elseif replicatedStorage:FindFirstChild("PlayEmote", true) then
			replicatedStorage:FindFirstChild("PlayEmote", true):Fire(arg)
		end
	end

	tbl.ChatRoles = function()
		local v9 = tbl.FindMurderer()
		local v10 = tbl.FindSheriff()
		local str = "Vision Hub >> Murderer: " .. (v9 and v9.Name or "Unknown") .. " | Sheriff: " .. (v10 and v10.Name or "Unknown")

		if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
			textChatService.TextChannels.RBXGeneral:SendAsync(str)
		else
			replicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(str, "Normal")
		end
	end

	local connection2 = nil

	tbl.ToggleAntiAFK = function(arg)
		if connection2 then
			connection2:Disconnect()
			connection2 = nil
		end

		if arg then
			connection2 = players.LocalPlayer.Idled:Connect(function()
				local VirtualUser = game:GetService("VirtualUser")
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new())
			end)
		end
	end

	local v9 = nil

	tbl.ToggleAntiFling = function(antiFling)
		tbl.Config.AntiFling = antiFling

		if v9 then
			fn4(v9)
			v9 = nil
		end

		if antiFling then
			v9 = fn3(runService.PreSimulation:Connect(function()
				if not tbl.Config.AntiFling then
					return
				end

				for _, player in ipairs(players:GetPlayers()) do
					if player ~= localPlayer and player.Character then
						for _, descendant in ipairs(player.Character:GetDescendants()) do
							if descendant:IsA("BasePart") then
								if descendant.CanCollide then
									descendant.CanCollide = false
								end

								descendant.AssemblyLinearVelocity = Vector3.zero
								descendant.AssemblyAngularVelocity = Vector3.zero
							end
						end
					end
				end
			end))
		end
	end

	local thread4 = nil
	local screenGui = nil

	local function fn12(arg)
		if not arg or arg == -1 then
			return "00:00"
		end
		return string.format("%02d:%02d", math.floor(arg / 60), arg % 60)
	end

	local function fn13()
		if screenGui then
			screenGui:Destroy()
			screenGui = nil
		end

		if thread4 then
			pcall(task.cancel, thread4)
			thread4 = nil
		end
	end

	tbl.ToggleRoundTimer = function(roundTimer)
		tbl.Config.RoundTimer = roundTimer
		fn13()
		if not roundTimer then
			return
		end
		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "VisionTimerGUI"
		screenGui.ResetOnSpawn = false
		screenGui.IgnoreGuiInset = true
		screenGui.Parent = coreGui
		local textLabel = Instance.new("TextLabel")
		textLabel.Size = UDim2.fromOffset(200, 50)
		textLabel.Position = UDim2.fromScale(0.5, 0.15)
		textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		textLabel.BackgroundTransparency = 1
		textLabel.Font = Enum.Font.GothamBold
		textLabel.TextScaled = true
		textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		textLabel.TextStrokeTransparency = 0
		textLabel.Text = "Loading..."
		textLabel.Parent = screenGui

		thread4 = task.spawn(function()
			while screenGui and screenGui.Parent do
				local v10 = tbl.GetTimer()
				textLabel.Text = v10 and fn12(v10)
				task.wait(0.5)
			end
		end)
	end

	local playerGui = localPlayer:WaitForChild("PlayerGui")

	local tbl5 = {
		Bg = Color3.fromRGB(11, 14, 20),
		Accent = Color3.fromRGB(255, 255, 255),
		Transparency = 0.4,
		HoverTransparency = 0.3,
		PressTransparency = 0.2,
		StrokeTransparency = 0.8,
		Font = Enum.Font.GothamMedium,
	}

	local guiClick = soundService:FindFirstChild("GuiClick")

	if not guiClick then
		guiClick = Instance.new("Sound")
		guiClick.Name = "GuiClick"
		guiClick.SoundId = "rbxassetid://6895079853"
		guiClick.Volume = 0.5
		guiClick.Parent = soundService
	end

	local function fn14(arg, arg2)
		if not writefile then
			return
		end
		local tbl6 = {}
		local ok2, result2 = pcall(readfile, "Vision_Buttons.json")

		if ok2 then
			pcall(function()
				tbl6 = httpService:JSONDecode(result2)
			end)
		end

		tbl6[arg] = {
			scaleX = math.round(arg2.Position.X.Scale * 1000) / 1000,
			scaleY = math.round(arg2.Position.Y.Scale * 1000) / 1000,
			size = math.round(arg2.Size.X.Offset),
		}

		pcall(writefile, "Vision_Buttons.json", httpService:JSONEncode(tbl6))
	end

	local function fn15(arg, arg2, arg3, arg4)
		return tweenService:Create(arg, TweenInfo.new(arg3 or 0.2, arg4 or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), arg2)
	end

	local function fn16(arg, arg2, arg3, arg4, arg5, arg6)
		local flag = false
		local flag2 = false

		local function fn17(arg7, arg8)
			local transparency = tbl5.Transparency
			local n = 1

			if arg7 then
				transparency = tbl5.HoverTransparency
				n = 2
			end

			if arg8 then
				transparency = tbl5.PressTransparency
				n = 2
			end

			fn15(arg3, { BackgroundTransparency = transparency }):Play()
			fn15(arg5, { Thickness = n }):Play()
		end

		arg4.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			flag = true
			local offset = arg2.Size.X.Offset
			local position = input.Position

			local connection3 = userInputService.InputChanged:Connect(function(input2)
				if input2.UserInputType == Enum.UserInputType.MouseMovement or input2.UserInputType == Enum.UserInputType.Touch then
					local n = math.clamp(offset + input2.Position.X - position.X, 35, 200)
					arg2.Size = UDim2.fromOffset(n, n)
				end
			end)

			local connection4 = nil

			connection4 = userInputService.InputEnded:Connect(function(input2)
				if input2.UserInputType == input.UserInputType then
					flag = false
					connection3:Disconnect()
					connection4:Disconnect()
					fn14(arg, arg2)
				end
			end)
		end)

		arg2.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end

			if flag then
				return
			end

			if tbl.Config.ButtonsLocked then
				fn17(true, true)
				guiClick:Play()
				local connection3 = nil

				connection3 = userInputService.InputEnded:Connect(function(input2)
					if input2.UserInputType == input.UserInputType then
						fn17(false, false)
						connection3:Disconnect()

						if arg6 then
							task.spawn(pcall, arg6)
						end
					end
				end)

				return
			end

			flag2 = true
			local position = arg2.Position
			local position2 = input.Position
			local viewportSize = workspace_.CurrentCamera.ViewportSize

			local connection3 = userInputService.InputChanged:Connect(function(input2)
				if input2.UserInputType == Enum.UserInputType.MouseMovement or input2.UserInputType == Enum.UserInputType.Touch then
					local y = input2.Position.Y
					arg2.Position = UDim2.fromScale(math.clamp(position.X.Scale + (input2.Position.X - position2.X) / viewportSize.X, 0.02, 0.98), math.clamp(position.Y.Scale + (y - position2.Y) / viewportSize.Y, 0.02, 0.98))
				end
			end)

			local connection4 = nil

			connection4 = userInputService.InputEnded:Connect(function(input2)
				if input2.UserInputType == input.UserInputType then
					flag2 = false
					connection3:Disconnect()
					connection4:Disconnect()
					fn14(arg, arg2)
				end
			end)
		end)
	end

	tbl.CreateGuiButton = function(arg, arg2, arg3)
		if tbl.Buttons[arg] then
			tbl.Buttons[arg]:Destroy()
		end

		if arg2.Enabled == false then
			return
		end
		local tbl6 = {}

		if readfile then
			local ok2, result2 = pcall(readfile, "Vision_Buttons.json")

			if ok2 then
				pcall(function()
					tbl6 = httpService:JSONDecode(result2)
				end)
			end
		end

		local tbl7 = tbl6[arg] or {}
		local n = math.clamp(tbl7.size or 55, 35, 200)
		local udim2 = tbl7.scaleX and UDim2.fromScale(tbl7.scaleX, tbl7.scaleY) or UDim2.fromScale(0.5, 0.5)
		local screenGui2 = Instance.new("ScreenGui")
		screenGui2.Name = "v_" .. arg
		screenGui2.ResetOnSpawn = false
		screenGui2.IgnoreGuiInset = true
		screenGui2.Parent = playerGui
		tbl.Buttons[arg] = screenGui2
		local imageButton = Instance.new("ImageButton")
		imageButton.Name = "Main"
		imageButton.Size = UDim2.fromOffset(n, n)
		imageButton.Position = udim2
		imageButton.AnchorPoint = Vector2.new(0.5, 0.5)
		imageButton.BackgroundTransparency = 1
		imageButton.Parent = screenGui2
		local frame = Instance.new("Frame")
		frame.Name = "Visual"
		frame.Size = UDim2.fromScale(1, 1)
		frame.BackgroundColor3 = tbl5.Bg
		frame.BackgroundTransparency = tbl5.Transparency
		frame.BorderSizePixel = 0
		frame.Parent = imageButton
		local uiCorner = Instance.new("UICorner")
		uiCorner.CornerRadius = UDim.new(0.25, 0)
		uiCorner.Parent = frame
		local uiStroke = Instance.new("UIStroke")
		uiStroke.Color = Color3.fromRGB(0, 191, 255)
		uiStroke.Transparency = tbl5.StrokeTransparency
		uiStroke.Thickness = 1
		uiStroke.Parent = frame
		local textLabel

		if arg2.Type == "Text" then
			textLabel = Instance.new("TextLabel")
			textLabel.Text = (arg2.Text or arg:sub(1, 3)):upper()
			textLabel.TextColor3 = tbl5.Accent
			textLabel.Font = tbl5.Font
			textLabel.TextScaled = true
		else
			textLabel = Instance.new("ImageLabel")
			textLabel.Image = arg2.Icon or ""
			textLabel.ImageColor3 = tbl5.Accent
		end

		textLabel.BackgroundTransparency = 1
		textLabel.Size = UDim2.fromScale(0.85, 0.85)
		textLabel.Position = UDim2.fromScale(0.5, 0.5)
		textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		textLabel.Parent = frame
		local frame2 = Instance.new("Frame")
		frame2.Name = "ResizeGrip"
		frame2.Size = UDim2.fromOffset(26, 26)
		frame2.Position = UDim2.fromScale(1, 1)
		frame2.AnchorPoint = Vector2.new(1, 1)
		frame2.BackgroundColor3 = tbl5.Accent
		frame2.Visible = not tbl.Config.ButtonsLocked
		frame2.Parent = imageButton
		local uiCorner2 = Instance.new("UICorner")
		uiCorner2.CornerRadius = UDim.new(1, 0)
		uiCorner2.Parent = frame2
		fn16(arg, imageButton, frame, frame2, uiStroke, arg3)

		task.spawn(function()
			while imageButton.Parent do
				frame2.Visible = not tbl.Config.ButtonsLocked
				task.wait(0.2)
			end
		end)
	end

	local connection3 = nil
	local name = nil
	local name2 = nil

	tbl.ToggleRoleNotifications = function(arg)
		if connection3 then
			connection3:Disconnect()
			connection3 = nil
		end

		if not arg then
			name = nil
			name2 = nil
			return
		end

		connection3 = tbl.RunService.Heartbeat:Connect(function()
			local v10 = tbl.GetTimer()

			if not v10 or v10 <= 0 or v10 > 250 then
				name = nil
				name2 = nil
				return
			end

			if tbl.Config.NotifyMurderer and not name then
				local v11 = tbl.FindMurderer()

				if v11 then
					name = v11.Name

					v:Notify({
						Title = "<font color='rgb(255, 0, 0)'>Murderer Identified!</font>",
						Content = "The player <font color='rgb(255, 0, 0)'><b>" .. v11.Name .. "</b></font> is the Murderer!",
						Icon = "rbxthumb://type=AvatarHeadShot&id=" .. v11.UserId .. "&w=150&h=150",
						IconSize = 45,
						Duration = 8,
					})
				end
			end

			if tbl.Config.NotifySheriff and not name2 then
				local v11 = tbl.FindSheriff()

				if v11 then
					name2 = v11.Name

					v:Notify({
						Title = "<font color='rgb(0, 0, 255)'>Sheriff Identified!</font>",
						Content = "The player <font color='rgb(0, 0, 255)'><b>" .. v11.Name .. "</b></font> is the Sheriff!",
						Icon = "rbxthumb://type=AvatarHeadShot&id=" .. v11.UserId .. "&w=150&h=150",
						IconSize = 45,
						Duration = 8,
					})
				end
			end
		end)
	end

	local connection4 = nil
	local flag = false

	tbl.ToggleGunDropNotification = function(notifyGunDropped)
		tbl.Config.NotifyGunDropped = notifyGunDropped

		if connection4 then
			connection4:Disconnect()
			connection4 = nil
		end

		if notifyGunDropped then
			flag = false

			connection4 = tbl.RunService.Heartbeat:Connect(function()
				if not tbl.Config.NotifyGunDropped then
					return
				end
				local v10 = fn8()

				if v10 then
					local gunDrop = v10:FindFirstChild("GunDrop")

					if gunDrop and not flag then
						flag = true

						if v and v.Notify then
							v:Notify({
								Title = "<font color='rgb(0, 255, 255)'>Gun Dropped!</font>",
								Content = "The <font color='rgb(0, 255, 255)'><b>Sheriff</b></font> has died. The <font color='rgb(255, 215, 0)'><b> Gun Drop</b></font> is now available for pickup!",
								Icon = "crosshair",
								Duration = 5,
							})
						end
					elseif not gunDrop then
						flag = false
					end
				end
			end)
		end
	end

	getgenv().VisionHub_Cleanup = function()
		for _, visionHubConnection in ipairs(getgenv().VisionHub_Connections) do
			if typeof(visionHubConnection) == "RBXScriptConnection" and visionHubConnection.Connected then
				pcall(function()
					visionHubConnection:Disconnect()
				end)
			end
		end

		table.clear(getgenv().VisionHub_Connections)
		getgenv().ClearESP()
	end

	local new = ColorSequenceKeypoint.new
	local color = Color3.fromRGB

	local v10 = v:CreateWindow({
		Title = "VISION HUB",
		Icon = "rbxassetid://125328263655945",
		IconSize = 44,
		Author = "Author: orialdev",
		Transparent = true,
		Theme = "Midnight",
		OpenButton = {
			Title = "<font color=\"rgb(255, 255, 255)\">VISION HUB</font>",
			Enabled = true,
			OnlyMobile = false,
			OnlyIcon = false,
			Draggable = true,
			Position = UDim2.new(0.5, 0, 0.05, 0),
			Scale = 1,
			StrokeThickness = 2,
			CornerRadius = UDim.new(1, 0),
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(37, 99, 235)),
				new(1, color(37, 99, 235)),
			}),
		},
	})

	v10:Tag({ Title = "0.1.8.1", Color = Color3.fromRGB(37, 99, 235) })
	local v11 = v10:Tab({ Title = "Home", Icon = "house", Border = true })
	local v12 = v10:Tab({ Title = "Movement", Icon = "footprints", Border = true })
	local v13 = v10:Tab({ Title = "Combat", Icon = "swords", Border = true })
	local v14 = v10:Tab({ Title = "Visuals", Icon = "eye", Border = true })
	local v15 = v10:Tab({ Title = "Teleports", Icon = "map-pin", Border = true })
	local v16 = v10:Tab({ Title = "Misc", Icon = "sparkles", Border = true })
	local v17 = v10:Tab({ Title = "GUI", Icon = "smartphone", Border = true })
	local v18 = v10:Tab({ Title = "Settings", Icon = "settings", Border = true })
	v11:Select()

	local function fn17()
		if typeof(identifyexecutor) == "function" then
			return identifyexecutor()
		end
		return "Unknown Executor"
	end

	local accountAge = localPlayer.AccountAge
	local userId = localPlayer.UserId

	v11:Paragraph({
		Title = "Welcome, " .. localPlayer.Name,
		Desc = string.format([[<font color='rgb(170, 170, 170)'>Executor:</font> %s
<font color='rgb(170, 170, 170)'>Account Age:</font> %d days
<font color='rgb(170, 170, 170)'>User ID:</font> %d]], fn17(), accountAge, userId),
		Icon = "user",
	})

	local v19 = v11:Paragraph({
		Title = "Game State: <font color='rgb(255, 165, 0)'>Scanning...</font>",
		Desc = "Waiting for game data...",
		Icon = "activity",
	})

	task.spawn(function()
		while task.wait(1) do
			pcall(function()
				local v20 = tbl.GetTimer()
				local flag2 = typeof(v20) == "number" and v20 > 0
				local str = "Intermission"
				local gameState = false

				if flag2 then
					str = string.format("%02d:%02d", math.floor(v20 / 60), v20 % 60)
					gameState = true
				end

				local v21 = tbl.FindMurderer()
				local v22 = tbl.FindSheriff()
				local str2 = "-"

				if v21 then
					str2 = "<font color='rgb(255, 0, 0)'>" .. v21.Name .. "</font>"
				end

				local str3 = "-"

				if v22 then
					str3 = "<font color='rgb(0, 0, 255)'>" .. v22.Name .. "</font>"
				end

				gameState = gameState and "<font color='rgb(0, 255, 0)'>In Progress</font>" or "<font color='rgb(255, 255, 255)'>Intermission</font>"

				if v19.SetTitle then
					v19:SetTitle("Game State: " .. gameState)
				end

				if v19.SetDesc then
					v19:SetDesc("<b>Timer:</b> " .. str .. "\n<b>Murderer:</b> " .. str2 .. "\n<b>Sheriff:</b> " .. str3)
				end
			end)
		end
	end)

	v11:Divider()

	v11:Paragraph({
		Title = "Join Discord Server",
		Desc = "Join the official VISION HUB Discord community",
		Icon = "message-circle",
		Buttons = {
			{
				Title = "Copy Discord Invite",
				Icon = "check",
				Callback = function()
					if setclipboard then
						setclipboard("https://discord.gg/B3dEqP2EX6")

						v10:Dialog({
							Title = "Discord Link Copied",
							Content = "Discord invite copied to clipboard!",
							Buttons = { { Title = "OK", Icon = "check" } },
						})
					end
				end,
			},
		},
	})

	local v20 = v12:Section({ Title = "Movement", Icon = "gauge", Box = true, BoxBorder = true, Opened = true })
	v20:Toggle({ Title = "Walk Speed", Flag = "EnableWalkspeedToggle", Callback = tbl.EnableWalkSpeed })

	v20:Slider({
		Title = "Walk Speed Value",
		Flag = "WalkspeedSlider",
		Value = { Min = 16, Max = 200, Default = tbl.Config.WalkSpeed },
		Callback = tbl.SetWalkSpeed,
	})

	v20:Divider()
	v20:Toggle({ Title = "Jump Power", Flag = "EnableJumppowerToggle", Callback = tbl.EnableJumpPower })

	v20:Slider({
		Title = "Jump Power Value",
		Flag = "JumppowerSlider",
		Value = { Min = 50, Max = 300, Default = tbl.Config.JumpPower },
		Callback = tbl.SetJumpPower,
	})

	v20:Divider()
	v20:Toggle({ Title = "Infinite Jump", Flag = "InfiniteJumpToggle", Callback = tbl.InfiniteJump })
	v20:Toggle({ Title = "Noclip", Flag = "NoclipToggle", Callback = tbl.EnableNoclip })
	v20:Divider()

	v20:Toggle({
		Title = "Enable Fly",
		Flag = "FlyToggle",
		Callback = function(arg)
			tbl.ToggleFly(arg)
		end,
	})

	v20:Slider({
		Title = "Fly Value",
		Flag = "FlySpeedSlider",
		Value = { Min = 10, Max = 300, Default = tbl.Config.FlySpeed },
		Callback = function(flySpeed)
			tbl.Config.FlySpeed = flySpeed
		end,
	})

	v20:Divider()

	v20:Toggle({
		Title = "Anti-AFK",
		Flag = "AntiAFKToggle",
		Callback = function(arg)
			tbl.ToggleAntiAFK(arg)
		end,
	})

	v20:Toggle({
		Title = "Anti Fling",
		Flag = "AntiFlingToggle",
		Value = tbl.Config.AntiFling,
		Callback = function(arg)
			tbl.ToggleAntiFling(arg)
		end,
	})

	local v21 = v12:Section({ Title = "Invisible", Icon = "eye-off", Box = true, BoxBorder = true, Opened = true })

	v21:Button({
		Title = "Invisible",
		Icon = "eye-off",
		Callback = function()
			tbl.Config.Invisible = not tbl.Config.Invisible
			tbl.ToggleInvisible(tbl.Config.Invisible)
		end,
	})

	v21:Keybind({
		Title = "Invisible Keybind",
		Value = "U",
		Callback = function()
			tbl.Config.Invisible = not tbl.Config.Invisible
			tbl.ToggleInvisible(tbl.Config.Invisible)
		end,
	})

	local v22 = v14:Section({ Title = "Murderer Visuals", Icon = "skull", Box = true, BoxBorder = true, Opened = true })

	v22:Colorpicker({
		Title = "Murderer ESP Color",
		Default = tbl.Config.ESPColorMurderer,
		Flag = "ESPColorMurderer",
		Callback = function(espColorMurderer)
			tbl.Config.ESPColorMurderer = espColorMurderer
		end,
	})

	v22:Divider()

	v22:Toggle({
		Title = "Murderer Chams",
		Flag = "HighlightMurdererToggle",
		Value = tbl.Config.HighlightMurderer,
		Callback = function(highlightMurderer)
			tbl.Config.HighlightMurderer = highlightMurderer
		end,
	})

	v22:Toggle({
		Title = "Murderer Name & Info",
		Flag = "InfoMurdererToggle",
		Value = tbl.Config.InfoMurderer,
		Callback = function(infoMurderer)
			tbl.Config.InfoMurderer = infoMurderer
		end,
	})

	v22:Divider()

	v22:Toggle({
		Title = "Murderer Box ESP",
		Flag = "BoxMurdererToggle",
		Value = tbl.Config.BoxMurderer,
		Callback = function(boxMurderer)
			tbl.Config.BoxMurderer = boxMurderer
		end,
	})

	v22:Toggle({
		Title = "Murderer Tracers",
		Flag = "TracersMurdererToggle",
		Value = tbl.Config.TracersMurderer,
		Callback = function(tracersMurderer)
			tbl.Config.TracersMurderer = tracersMurderer
		end,
	})

	v22:Toggle({
		Title = "Murderer Skeleton ESP",
		Flag = "SkeletonMurdererToggle",
		Value = tbl.Config.SkeletonMurderer,
		Callback = function(skeletonMurderer)
			tbl.Config.SkeletonMurderer = skeletonMurderer
		end,
	})

	local v23 = v14:Section({ Title = "Sheriff Visuals", Icon = "shield", Box = true, BoxBorder = true, Opened = true })

	v23:Colorpicker({
		Title = "Sheriff ESP Color",
		Default = tbl.Config.ESPColorSheriff,
		Flag = "ESPColorSheriff",
		Callback = function(espColorSheriff)
			tbl.Config.ESPColorSheriff = espColorSheriff
		end,
	})

	v23:Divider()

	v23:Toggle({
		Title = "Sheriff Chams",
		Flag = "HighlightSheriffToggle",
		Value = tbl.Config.HighlightSheriff,
		Callback = function(highlightSheriff)
			tbl.Config.HighlightSheriff = highlightSheriff
		end,
	})

	v23:Toggle({
		Title = "Sheriff Name & Info",
		Flag = "InfoSheriffToggle",
		Value = tbl.Config.InfoSheriff,
		Callback = function(infoSheriff)
			tbl.Config.InfoSheriff = infoSheriff
		end,
	})

	v23:Divider()

	v23:Toggle({
		Title = "Sheriff Box ESP",
		Flag = "BoxSheriffToggle",
		Value = tbl.Config.BoxSheriff,
		Callback = function(boxSheriff)
			tbl.Config.BoxSheriff = boxSheriff
		end,
	})

	v23:Toggle({
		Title = "Sheriff Tracers",
		Flag = "TracersSheriffToggle",
		Value = tbl.Config.TracersSheriff,
		Callback = function(tracersSheriff)
			tbl.Config.TracersSheriff = tracersSheriff
		end,
	})

	v23:Toggle({
		Title = "Sheriff Skeleton ESP",
		Flag = "SkeletonSheriffToggle",
		Value = tbl.Config.SkeletonSheriff,
		Callback = function(skeletonSheriff)
			tbl.Config.SkeletonSheriff = skeletonSheriff
		end,
	})

	local v24 = v14:Section({ Title = "Innocent Visuals", Icon = "users", Box = true, BoxBorder = true, Opened = true })

	v24:Colorpicker({
		Title = "Innocent ESP Color",
		Default = tbl.Config.ESPColorInnocent,
		Flag = "ESPColorInnocent",
		Callback = function(espColorInnocent)
			tbl.Config.ESPColorInnocent = espColorInnocent
		end,
	})

	v24:Divider()

	v24:Toggle({
		Title = "Innocent Chams",
		Flag = "HighlightInnocentToggle",
		Value = tbl.Config.HighlightInnocent,
		Callback = function(highlightInnocent)
			tbl.Config.HighlightInnocent = highlightInnocent
		end,
	})

	v24:Toggle({
		Title = "Innocent Name & Info",
		Flag = "InfoInnocentToggle",
		Value = tbl.Config.InfoInnocent,
		Callback = function(infoInnocent)
			tbl.Config.InfoInnocent = infoInnocent
		end,
	})

	v24:Divider()

	v24:Toggle({
		Title = "Innocent Box ESP",
		Flag = "BoxInnocentToggle",
		Value = tbl.Config.BoxInnocent,
		Callback = function(boxInnocent)
			tbl.Config.BoxInnocent = boxInnocent
		end,
	})

	v24:Toggle({
		Title = "Innocent Tracers",
		Flag = "TracersInnocentToggle",
		Value = tbl.Config.TracersInnocent,
		Callback = function(tracersInnocent)
			tbl.Config.TracersInnocent = tracersInnocent
		end,
	})

	v24:Toggle({
		Title = "Innocent Skeleton ESP",
		Flag = "SkeletonInnocentToggle",
		Value = tbl.Config.SkeletonInnocent,
		Callback = function(skeletonInnocent)
			tbl.Config.SkeletonInnocent = skeletonInnocent
		end,
	})

	local v25 = v14:Section({ Title = "World", Icon = "crosshair", Box = true, BoxBorder = true, Opened = true })

	v25:Toggle({
		Title = "Display Round Timer",
		Flag = "RoundTimerToggle",
		Value = tbl.Config.RoundTimer,
		Callback = tbl.ToggleRoundTimer,
	})

	v25:Divider()

	v25:Toggle({
		Title = "Dropped Gun ESP",
		Flag = "ESPGunDroppedToggle",
		Value = tbl.Config.ESPGunDropped,
		Callback = function(espGunDropped)
			tbl.Config.ESPGunDropped = espGunDropped
		end,
	})

	local v26 = v14:Section({ Title = "Alerts", Icon = "bell", Box = true, BoxBorder = true, Opened = true })

	v26:Toggle({
		Title = "Notify on Gun Drop",
		Flag = "NotifyGunDroppedToggle",
		Callback = function(arg)
			tbl.ToggleGunDropNotification(arg)
		end,
	})

	v26:Divider()

	v26:Toggle({
		Title = "Notify on Murderer Detection",
		Flag = "NotifyMurdererToggle",
		Callback = function(notifyMurderer)
			tbl.Config.NotifyMurderer = notifyMurderer
			tbl.ToggleRoleNotifications(true)
		end,
	})

	v26:Toggle({
		Title = "Notify on Sheriff Detection",
		Flag = "NotifySheriffToggle",
		Callback = function(notifySheriff)
			tbl.Config.NotifySheriff = notifySheriff
			tbl.ToggleRoleNotifications(true)
		end,
	})

	local v27 = v13:Section({ Title = "Sheriff & Hero", Icon = "shield", Box = true, BoxBorder = true, Opened = true })
	v27:Toggle({ Title = "Auto Grab Gun", Flag = "AutoGrabGunToggle", Callback = tbl.ToggleAutoGrabGun })
	v27:Button({ Title = "Grab Gun", Icon = "hand", Callback = tbl.GrabGun })
	v27:Keybind({ Title = "Grab Gun Keybind", Value = "G", Callback = tbl.GrabGun })
	v27:Divider()

	v27:Toggle({
		Title = "Auto Shoot Murderer",
		Flag = "AutoShootMurdererToggle",
		Callback = function(arg)
			tbl.ToggleAutoShootMurderer(arg)
		end,
	})

	v27:Button({
		Title = "Shoot Murderer",
		Icon = "crosshair",
		Callback = function()
			tbl.ShootMurderer()
		end,
	})

	v27:Keybind({
		Title = "Shoot Murderer Keybind",
		Value = "E",
		Callback = function()
			tbl.ShootMurderer()
		end,
	})

	v27:Divider()

	v27:Toggle({
		Title = "Auto Wall Bang Murderer",
		Flag = "AutoWallBangToggle",
		Callback = function(arg)
			tbl.ToggleWallBang(arg)
		end,
	})

	v27:Button({
		Title = "Wall Bang Murderer",
		Icon = "crosshair",
		Callback = function()
			tbl.WallBangShoot()
		end,
	})

	v27:Keybind({
		Title = "Wall Bang Keybind",
		Value = "B",
		Callback = function()
			tbl.WallBangShoot()
		end,
	})

	local v28 = v13:Section({ Title = "Murderer", Icon = "skull", Box = true, BoxBorder = true, Opened = true })

	v28:Dropdown({
		Title = "Kill All Mode",
		Values = { "Default", "Silent" },
		Value = "Default",
		Callback = function(killAllMode)
			tbl.Config.KillAllMode = killAllMode
		end,
	})

	v28:Button({ Title = "Kill All Players", Icon = "skull", Callback = tbl.KillAll })
	v28:Keybind({ Title = "Kill All Keybind", Value = "K", Callback = tbl.KillAll })
	v28:Toggle({ Title = "Auto Kill All", Flag = "AutoKillAllToggle", Callback = tbl.ToggleAutoKillAll })
	v28:Divider()

	v28:Dropdown({
		Title = "Knife Aura Mode",
		Values = { "Default", "Silent" },
		Value = "Default",
		Callback = function(knifeAuraMode)
			tbl.Config.KnifeAuraMode = knifeAuraMode
		end,
	})

	v28:Toggle({ Title = "Knife Aura", Flag = "KnifeAuraToggle", Callback = tbl.ToggleKnifeAura })

	v28:Slider({
		Title = "Knife Aura Range",
		Flag = "KnifeAuraRangeSlider",
		Value = { Min = 5, Max = 300, Default = 20 },
		Callback = function(knifeAuraRange)
			tbl.Config.KnifeAuraRange = knifeAuraRange
		end,
	})

	v28:Divider()

	v28:Toggle({
		Title = "Auto Silent Knife Throw",
		Flag = "SilentThrowToggle",
		Callback = tbl.ToggleSilentThrow,
	})

	v28:Button({ Title = "Silent Knife Throw", Icon = "zap", Callback = tbl.ExecuteSilentThrow })
	v28:Keybind({ Title = "Silent Knife Throw Keybind", Value = "V", Callback = tbl.ExecuteSilentThrow })
	local v29 = v15:Section({ Title = "Player Teleports", Icon = "users", Box = true, BoxBorder = true, Opened = true })
	local v30 = nil

	local v31 = v29:Dropdown({
		Title = "Player Selector",
		Values = {},
		Callback = function(arg)
			local title = typeof(arg) == "table" and arg.Title or arg

			if title then
				v30 = players:FindFirstChild(title)
			else
				v30 = nil
			end
		end,
	})

	local function fn18()
		local tbl6 = {}

		for _, player in ipairs(players:GetPlayers()) do
			if player ~= tbl.Player then
				table.insert(tbl6, player.Name)
			end
		end

		if v31.Refresh then
			v31:Refresh(tbl6)
		elseif v31.SetValues then
			v31:SetValues(tbl6)
		end
	end

	fn18()

	if fn3 then
		fn3(players.PlayerAdded:Connect(fn18))
		fn3(players.PlayerRemoving:Connect(fn18))
	else
		players.PlayerAdded:Connect(fn18)
		players.PlayerRemoving:Connect(fn18)
	end

	v29:Button({
		Title = "Teleport to Selected Player",
		Icon = "arrow-right",
		Callback = function()
			if v30 then
				tbl.TeleportToPlayer(v30)
			end
		end,
	})

	v29:Divider()

	v29:Button({
		Title = "Teleport to Murderer",
		Icon = "skull",
		Callback = function()
			local v32 = tbl.FindMurderer()

			if v32 then
				tbl.TeleportToPlayer(v32)
			end
		end,
	})

	v29:Button({
		Title = "Teleport to Sheriff",
		Icon = "shield",
		Callback = function()
			local v32 = tbl.FindSheriff()

			if v32 then
				tbl.TeleportToPlayer(v32)
			end
		end,
	})

	local v32 = v15:Section({ Title = "World", Icon = "map", Box = true, BoxBorder = true, Opened = true })
	v32:Button({ Title = "Teleport to Map", Icon = "map", Callback = tbl.TeleportToMap })
	v32:Button({ Title = "Teleport to Lobby", Icon = "house", Callback = tbl.TeleportToLobby })
	local v33 = v16:Section({ Title = "Flinger", Icon = "wind", Box = true, BoxBorder = true, Opened = true })
	local v34 = nil

	local v35 = v33:Dropdown({
		Title = "Select Target Player",
		Values = {},
		Callback = function(arg)
			local title = typeof(arg) == "table" and arg.Title or arg

			if title then
				v34 = players:FindFirstChild(title)
			else
				v34 = nil
			end
		end,
	})

	local function fn19()
		local tbl6 = {}

		for _, player in ipairs(players:GetPlayers()) do
			if player ~= tbl.Player then
				table.insert(tbl6, player.Name)
			end
		end

		if v35.Refresh then
			v35:Refresh(tbl6)
		elseif v35.SetValues then
			v35:SetValues(tbl6)
		end
	end

	fn19()

	if fn3 then
		fn3(players.PlayerAdded:Connect(fn19))
		fn3(players.PlayerRemoving:Connect(fn19))
	else
		players.PlayerAdded:Connect(fn19)
		players.PlayerRemoving:Connect(fn19)
	end

	v33:Button({
		Title = "Fling Selected Player",
		Icon = "wind",
		Callback = function()
			if v34 and v34.Character then
				tbl.FlingTarget(v34)
			end
		end,
	})

	v33:Button({
		Title = "Fling All Players",
		Icon = "wind",
		Callback = function()
			for _, player in ipairs(players:GetPlayers()) do
				if player ~= tbl.Player and player.Character then
					tbl.FlingTarget(player)
				end
			end
		end,
	})

	v33:Divider()

	v33:Button({
		Title = "Fling Murderer",
		Icon = "skull",
		Callback = function()
			local v36 = tbl.FindMurderer()

			if v36 and v36.Character then
				tbl.FlingTarget(v36)
			end
		end,
	})

	v33:Button({
		Title = "Fling Sheriff",
		Icon = "shield",
		Callback = function()
			local v36 = tbl.FindSheriff()

			if v36 and v36.Character then
				tbl.FlingTarget(v36)
			end
		end,
	})

	v16:Section({ Title = "Chat", Icon = "message-circle", Box = true, BoxBorder = true, Opened = true }):Button({ Title = "Expose Roles in Chat", Icon = "megaphone", Callback = tbl.ChatRoles })
	local v36 = v16:Section({ Title = "Emotes & Animations", Icon = "smile", Box = true, BoxBorder = true, Opened = true })
	local title = nil

	v36:Dropdown({
		Title = "Emote Selector",
		Flag = "EmoteSelectDropdown",
		Values = { "sit", "zombie", "ninja", "zen", "floss", "dab" },
		Callback = function(arg)
			title = typeof(arg) == "table" and arg.Title or arg
		end,
	})

	v36:Button({
		Title = "Play Selected Emote",
		Icon = "play",
		Callback = function()
			if title then
				tbl.PlayEmote(title)
			end
		end,
	})

	local v37 = v17:Section({
		Title = "Floating UI Elements",
		Icon = "smartphone",
		Box = true,
		BoxBorder = true,
		Opened = true,
	})

	v37:Toggle({
		Title = "Buttons Locked",
		Value = tbl.Config.ButtonsLocked,
		Type = "Checkbox",
		Callback = function(buttonsLocked)
			tbl.Config.ButtonsLocked = buttonsLocked
		end,
	})

	v37:Divider()

	v37:Toggle({
		Title = "Display Shoot Button",
		Flag = "show_shoot_button",
		Callback = function(arg)
			tbl.CreateGuiButton("Shoot", { Enabled = arg, Type = "Image", Icon = "rbxassetid://139650104834071" }, tbl.ShootMurderer)
		end,
	})

	v37:Toggle({
		Title = "Display WallBang Button",
		Flag = "show_wallbang_button",
		Callback = function(arg)
			tbl.CreateGuiButton("WallBang", { Enabled = arg, Type = "Text", Text = "WallBang" }, tbl.WallBangShoot)
		end,
	})

	v37:Toggle({
		Title = "Display Grab Gun Button",
		Flag = "show_grab_gun_button",
		Callback = function(arg)
			tbl.CreateGuiButton("GrabGun", { Enabled = arg, Type = "Text", Text = "Grab Gun" }, tbl.GrabGun)
		end,
	})

	v37:Toggle({
		Title = "Display Kill All Button",
		Flag = "show_kill_button",
		Callback = function(arg)
			tbl.CreateGuiButton("KillAll", { Enabled = arg, Type = "Text", Text = "Kill All" }, tbl.KillAll)
		end,
	})

	v37:Toggle({
		Title = "Display Silent Throw Button",
		Flag = "show_throw_knife_button",
		Callback = function(arg)
			tbl.CreateGuiButton("SilentThrow", { Enabled = arg, Type = "Text", Text = "Silent Throw" }, tbl.ExecuteSilentThrow)
		end,
	})

	v37:Toggle({
		Title = "Display Fly Toggle Button",
		Flag = "show_fly_button",
		Callback = function(arg)
			tbl.CreateGuiButton("Fly", { Enabled = arg, Type = "Text", Text = "Fly" }, function()
				tbl.Config.FlyEnabled = not tbl.Config.FlyEnabled
				tbl.ToggleFly(tbl.Config.FlyEnabled)
			end)
		end,
	})

	v37:Toggle({
		Title = "Display Noclip Toggle Button",
		Flag = "show_noclip_button",
		Callback = function(arg)
			tbl.CreateGuiButton("Noclip", { Enabled = arg, Type = "Text", Text = "Noclip" }, function()
				tbl.Config.Noclip = not tbl.Config.Noclip
				tbl.EnableNoclip(tbl.Config.Noclip)
			end)
		end,
	})

	v37:Toggle({
		Title = "Display Invisible Button",
		Flag = "show_invisible_button",
		Callback = function(arg)
			tbl.CreateGuiButton("Invisible", { Enabled = arg, Type = "Text", Text = "Invisible" }, function()
				tbl.Config.Invisible = not tbl.Config.Invisible
				tbl.ToggleInvisible(tbl.Config.Invisible)
			end)
		end,
	})

	v37:Toggle({
		Title = "Display Fling Murderer Button",
		Flag = "show_fling_murderer_button",
		Callback = function(arg)
			tbl.CreateGuiButton("FlingMurderer", { Enabled = arg, Type = "Text", Text = "Fling Murderer" }, function()
				local v38 = tbl.FindMurderer()

				if v38 then
					tbl.FlingTarget(v38)
				end
			end)
		end,
	})

	v37:Toggle({
		Title = "Display Fling Sheriff Button",
		Flag = "show_fling_sheriff_button",
		Callback = function(arg)
			tbl.CreateGuiButton("FlingSheriff", { Enabled = arg, Type = "Text", Text = "Fling Sheriff" }, function()
				local v38 = tbl.FindSheriff()

				if v38 then
					tbl.FlingTarget(v38)
				end
			end)
		end,
	})

	v37:Toggle({
		Title = "Display Anti Fling Button",
		Flag = "show_anti_fling_button",
		Callback = function(arg)
			tbl.CreateGuiButton("AntiFling", { Enabled = arg, Type = "Text", Text = "Anti Fling" }, function()
				tbl.Config.AntiFling = not tbl.Config.AntiFling
				tbl.ToggleAntiFling(tbl.Config.AntiFling)
			end)
		end,
	})

	v37:Toggle({
		Title = "Display Expose Roles Button",
		Flag = "show_expose_roles_button",
		Callback = function(arg)
			tbl.CreateGuiButton("ExposeRoles", { Enabled = arg, Type = "Text", Text = "Expose Roles" }, tbl.ChatRoles)
		end,
	})

	v37:Toggle({
		Title = "Display Teleport to Map Button",
		Flag = "show_tp_map_button",
		Callback = function(arg)
			tbl.CreateGuiButton("TPMap", { Enabled = arg, Type = "Text", Text = "Map TP" }, tbl.TeleportToMap)
		end,
	})

	v37:Toggle({
		Title = "Display Teleport to Lobby Button",
		Flag = "show_tp_lobby_button",
		Callback = function(arg)
			tbl.CreateGuiButton("TPLobby", { Enabled = arg, Type = "Text", Text = "Lobby TP" }, tbl.TeleportToLobby)
		end,
	})

	v37:Toggle({
		Title = "Display Sit Emote Button",
		Flag = "show_sit_button",
		Callback = function(arg)
			tbl.CreateGuiButton("Sit", { Enabled = arg, Type = "Text", Text = "Sit" }, function()
				tbl.PlayEmote("sit")
			end)
		end,
	})

	v37:Toggle({
		Title = "Display Floss Emote Button",
		Flag = "show_floss_button",
		Callback = function(arg)
			tbl.CreateGuiButton("Floss", { Enabled = arg, Type = "Text", Text = "Floss" }, function()
				tbl.PlayEmote("floss")
			end)
		end,
	})

	v37:Toggle({
		Title = "Display Dab Emote Button",
		Flag = "show_dab_button",
		Callback = function(arg)
			tbl.CreateGuiButton("Dab", { Enabled = arg, Type = "Text", Text = "Dab" }, function()
				tbl.PlayEmote("dab")
			end)
		end,
	})

	v37:Toggle({
		Title = "Display Zombie Emote Button",
		Flag = "show_zombie_button",
		Callback = function(arg)
			tbl.CreateGuiButton("Zombie", { Enabled = arg, Type = "Text", Text = "Zombie" }, function()
				tbl.PlayEmote("zombie")
			end)
		end,
	})

	v37:Toggle({
		Title = "Display Ninja Emote Button",
		Flag = "show_ninja_button",
		Callback = function(arg)
			tbl.CreateGuiButton("Ninja", { Enabled = arg, Type = "Text", Text = "Ninja" }, function()
				tbl.PlayEmote("ninja")
			end)
		end,
	})

	v37:Toggle({
		Title = "Display Zen Emote Button",
		Flag = "show_zen_button",
		Callback = function(arg)
			tbl.CreateGuiButton("Zen", { Enabled = arg, Type = "Text", Text = "Zen" }, function()
				tbl.PlayEmote("zen")
			end)
		end,
	})

	local v38 = v18:Section({ Title = "Configuration", Icon = "file-cog", Box = true, BoxBorder = true, Opened = true })
	local configManager = v10.ConfigManager
	local deletedProfile = "default"

	local function fn20(arg)
		if configManager and configManager.Config then
			return configManager:Config(arg)
		end
		return nil
	end

	local v39 = v38:Input({
		Title = "Config Name",
		Icon = "file-text",
		Callback = function(arg)
			deletedProfile = arg
		end,
	})

	v38:Space()
	local allConfigs = configManager and configManager.AllConfigs and configManager:AllConfigs() or {}

	local v40 = v38:Toggle({
		Title = "Auto-Load Active Config",
		Value = false,
		Callback = function(autoLoad)
			local v40 = fn20(deletedProfile)

			if v40 then
				v40.AutoLoad = autoLoad

				if v40.Save then
					v40:Save()
				end
			end
		end,
	})

	local v41 = v38:Dropdown({
		Title = "Saved Config Profiles",
		Values = allConfigs,
		Value = table.find(allConfigs, deletedProfile) and deletedProfile or nil,
		Callback = function(arg)
			local title2 = typeof(arg) == "table" and arg.Title or arg
			deletedProfile = title2

			if v39 and v39.Set then
				v39:Set(title2)
			end

			local v41 = fn20(title2)

			if v40 and v41 and v40.Set then
				v40:Set(v41.AutoLoad or false, false)
			end
		end,
	})

	v38:Divider()

	v38:Button({
		Title = "Save Config Profile",
		Icon = "save",
		Callback = function()
			local v42 = fn20(deletedProfile)

			if v42 and v42.Save and v42:Save() then
				v:Notify({
					Title = "Config Saved",
					Content = "Config '" .. deletedProfile .. "' saved successfully.",
					Icon = "check",
				})

				if v41 and configManager then
					if v41.Refresh then
						v41:Refresh(configManager:AllConfigs())
					elseif v41.SetValues then
						v41:SetValues(configManager:AllConfigs())
					end
				end
			end
		end,
	})

	v38:Button({
		Title = "Load Config Profile",
		Icon = "download",
		Callback = function()
			local v42 = fn20(deletedProfile)

			if v42 and v42.Load and v42:Load() then
				v:Notify({ Title = "Config Loaded", Content = "Profile '" .. deletedProfile .. "' applied.", Icon = "refresh-cw" })
			end
		end,
	})

	v38:Button({
		Title = "Delete Config Profile",
		Icon = "trash-2",
		Callback = function()
			if configManager and configManager.DeleteConfig then
				configManager:DeleteConfig(deletedProfile)

				if v41 then
					if v41.Refresh then
						v41:Refresh(configManager:AllConfigs())
					elseif v41.SetValues then
						v41:SetValues(configManager:AllConfigs())
					end
				end

				v:Notify({ Title = "Config Deleted", Content = "Deleted profile: " .. deletedProfile, Icon = "trash" })
			end
		end,
	})

	v18:Section({ Title = "Interface Keybinds", Icon = "keyboard", Box = true, BoxBorder = true, Opened = true }):Keybind({
		Title = "Menu Toggle Keybind",
		Value = "RightControl",
		Callback = function(arg)
			local flag2 = typeof(arg) == "EnumItem" and arg or Enum.KeyCode[arg]

			if flag2 and v10 and v10.SetToggleKey then
				v10:SetToggleKey(flag2)
			end
		end,
	})

	local v42 = v18:Section({ Title = "Server", Icon = "server", Box = true, BoxBorder = true, Opened = true })

	v42:Button({
		Title = "Rejoin Current Server",
		Icon = "refresh-cw",
		Callback = function()
			v10:Dialog({
				Title = "Confirm Rejoin",
				Content = "Are you sure you want to rejoin the server?",
				Buttons = {
					{ Title = "Cancel", Variant = "Secondary" },
					{
						Title = "Rejoin",
						Icon = "check",
						Callback = function()
							if tbl and tbl.Rejoin then
								tbl.Rejoin()
							end
						end,
					},
				},
			})
		end,
	})

	v42:Button({
		Title = "Server Hop",
		Icon = "shuffle",
		Callback = function()
			v10:Dialog({
				Title = "Confirm Server Hop",
				Content = "Are you sure you want to server hop?",
				Buttons = {
					{ Title = "Cancel", Variant = "Secondary" },
					{
						Title = "Server Hop",
						Icon = "check",
						Callback = function()
							if tbl and tbl.ServerHop then
								tbl.ServerHop()
							end
						end,
					},
				},
			})
		end,
	})

	return tbl
end

warn("Failed to load WindUI. Error: " .. tostring(result))
