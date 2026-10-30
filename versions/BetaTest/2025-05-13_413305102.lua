local gun = game.Players.LocalPlayer.Character:FindFirstChild("Gun") or game.Players.LocalPlayer.Backpack:FindFirstChild("Gun")

if gun then
	for _, obj in pairs(gun:GetDescendants()) do
		if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
			print("Found Remote:", obj:GetFullName())
		end
	end
else
	warn("Gun not found!")
end
