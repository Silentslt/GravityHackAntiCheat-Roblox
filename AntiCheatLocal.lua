local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local originalGravity = Workspace.Gravity

local AntiCheatRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("AntiCheat")

local function reportCheat(cheatType, details)
	local success, err = pcall(function()
		AntiCheatRemote:FireServer({
			type = cheatType,
			details = details,
			timestamp = os.time(),
			playerId = player.UserId
		})
	end)

	if not success then
		warn("Cheat report failed: " .. tostring(err))
	end
end

local function checkGravity()
	if Workspace.Gravity ~= originalGravity then
		reportCheat(
			"Gravity Hack",
			string.format("Changed from %d to %d", originalGravity, Workspace.Gravity)
		)
		Workspace.Gravity = originalGravity
	end
end

RunService.Heartbeat:Connect(function()
	checkGravity()
end)
