local Players = game:GetService("Players")
local player = Players.LocalPlayer
local gun = player.Character and player.Character:FindFirstChild("Gun") or player.Backpack:FindFirstChild("Gun")

if gun then
    for _, v in pairs(getgc(true)) do
        if typeof(v) == "function" and islclosure(v) and debug.getinfo(v).name == "fireBullet" then
            print("Found gun fire function, trying to call it...")
            pcall(v)
        end
    end
else
    warn("Gun not found in backpack or character.")
end
