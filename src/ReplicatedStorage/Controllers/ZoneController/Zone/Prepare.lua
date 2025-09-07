local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):wait()

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MyUIManager = require(ReplicatedStorage.Source.MyUIManager)
local Communication = require(ReplicatedStorage.Source.CommonFunctions.Communication)
local Zone = require(script.Parent)

local Prepare = {}
setmetatable(Prepare,Zone)
Prepare.__index = Prepare

function Prepare.new(instance:Instance,collisionGroup:string)
	local self = Zone.new(instance.CFrame,Vector3.new(50, 40, 32),collisionGroup)
	setmetatable(self,Prepare)
	
	self.instance = instance
	self.id = instance.Name
	return self
end

function Prepare:Enter(triggerer)
	local plr = Players:GetPlayerFromCharacter(triggerer)
	if plr == player and not plr:GetAttribute("Teleporting") then
        Communication.FireServer("PlayerPrepared",true)
	end
end

function Prepare:Leave(triggerer)
	local plr = Players:GetPlayerFromCharacter(triggerer)
	if plr == player and not plr:GetAttribute("Teleporting") then
		Communication.FireServer("PlayerPrepared",false)
	end
end

return Prepare
