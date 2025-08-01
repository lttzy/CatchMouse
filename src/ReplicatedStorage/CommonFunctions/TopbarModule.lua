local RunService = game:GetService("RunService")
if RunService:IsServer() then return {} end

local SocialService = game:GetService("SocialService")
local Players = game:GetService("Players")

local TopbarPlus = script.Parent.TopbarPlus
local Icon_Module = require(TopbarPlus:WaitForChild("Icon"))

local player = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):wait()

local module = {}

local function inviteFriend()
	Icon_Module.new()
		:setImage("rbxassetid://14610717507")
		:setCaption("InviteFriends")
		:align("Right")
		:oneClick()
		:bindEvent("selected", function()
			local success,result = pcall(function()
				return SocialService:CanSendGameInviteAsync(player)
			end)

			if result == true then SocialService:PromptGameInvite(player) end
		end)
end

local function gameVersion()
	Icon_Module.new()
		:setImage("")
		:setLabel("Version Beta0.01")
		:setCaption("Game Version")
		:align("Right")
	--:setDropdown({
	--Icon_Module.new()
	--:setLabel("Version Beta0.06")
	--:oneClick()
	--:bindEvent("selected", function()

	--end),

	--Icon_Module.new()
	--:setLabel("Version Beta0.02")
	--:oneClick()
	--:bindEvent("selected", function()

	--end),
	--})
end

module.inviteFriend = inviteFriend
module.gameVersion = gameVersion

return module
