local RS = game:GetService("ReplicatedStorage")
local EventsBefore = {}

for _, v in pairs(RS:GetDescendants()) do
	if v:IsA("RemoteEvent") then
		EventsBefore[v] = true
	end
end

print("Now shoot once with your gun.")

-- Wait for user to shoot manually
task.wait(5)

for _, v in pairs(RS:GetDescendants()) do
	if v:IsA("RemoteEvent") and not EventsBefore[v] then
		print("New RemoteEvent Detected:", v:GetFullName())
	end
end
