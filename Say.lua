-- Say Command Script
-- Trigger: !s message

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local player = Players.LocalPlayer

-- Make sure game uses new chat
if TextChatService.ChatVersion ~= Enum.ChatVersion.TextChatService then
    warn("Game is not using the new TextChatService chat.")
    return
end

-- Get the public channel
local generalChannel = TextChatService.TextChannels:WaitForChild("RBXGeneral")

TextChatService.MessageReceived:Connect(function(message)
    -- Ignore your own messages to prevent loops
    if not message.TextSource or message.TextSource.UserId == player.UserId then
        return
    end

    local text = message.Text

    -- Check for !s command
    if text:sub(1, 3) == "!s " then
        local sayText = text:sub(4)

        if sayText ~= "" then
            pcall(function()
                generalChannel:SendAsync(sayText)
            end)
        end
    end
end)
