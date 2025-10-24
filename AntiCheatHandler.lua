local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WebhookUrl = "" -- DONT SHARE!
local GameName = game.Name
local GameID = game.GameId

local AntiCheatRemote = ReplicatedStorage:FindFirstChild("Remotes"):FindFirstChild("AntiCheat")


local RateLimiter = {
	lastSendTime = 0,
	cooldown = 5,
	maxCooldown = 30,
	queue = {},
	isProcessing = false,
	errorCount = 0
}

local function createAntiCheatEmbed(player, cheatType, details)
	return {
		title = "Anti-Cheat Alert",
		description = "Potential cheating detected in the game",
		color = 16711680,
		fields = {
			{name = "Player", value = player.Name, inline = true},
			{name = "User ID", value = tostring(player.UserId), inline = true},
			{name = "Cheat Type", value = cheatType, inline = true},
			{name = "Details", value = details, inline = false},
			{name = "Game", value = GameName, inline = true},
			{name = "Server ID", value = game.JobId, inline = true}
		},
		timestamp = DateTime.now():ToIsoDate(),
		footer = {text = "Anti-Cheat System"}
	}
end

local function processQueue()
	if RateLimiter.isProcessing or #RateLimiter.queue == 0 then return end
	RateLimiter.isProcessing = true

	while #RateLimiter.queue > 0 do
		local now = os.time()
		if now - RateLimiter.lastSendTime >= RateLimiter.cooldown then
			local success, err = pcall(function()
				HttpService:PostAsync(
					WebhookUrl,
					HttpService:JSONEncode({
						embeds = {RateLimiter.queue[1]},
						username = "Roblox Anti-Cheat",
						avatar_url = "https://i.imgur.com/7QbI8yN.png"
					})
				)
				RateLimiter.lastSendTime = now
				table.remove(RateLimiter.queue, 1)
			end)
			if not success then
				if string.find(tostring(err), "429") then
					RateLimiter.cooldown = math.min(RateLimiter.cooldown + 5, RateLimiter.maxCooldown)
				end
				break
			end
		else
			task.wait(RateLimiter.cooldown - (now - RateLimiter.lastSendTime))
		end
	end
	RateLimiter.isProcessing = false
end

local function onCheatDetected(player, cheatData)
	if not player or not player:IsDescendantOf(Players) then return end

	warn("[Anti-Cheat] "..player.Name.." detected for "..cheatData.type)

	local embed = createAntiCheatEmbed(player, cheatData.type, cheatData.details or "No details")
	table.insert(RateLimiter.queue, embed)
	if not RateLimiter.isProcessing then
		task.spawn(processQueue)
	end
end

AntiCheatRemote.OnServerEvent:Connect(onCheatDetected)
warn("Silent's AntiCheat v1.3")