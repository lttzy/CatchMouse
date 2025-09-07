local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):wait()

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MyUIManager = require(ReplicatedStorage.Source.MyUIManager)

local Zone = require(script.Parent)

local EggStore = {}
setmetatable(EggStore,Zone)
EggStore.__index = EggStore

function EggStore.new(instance:Instance,collisionGroup:string)
	local self = Zone.new(instance.CFrame,Vector3.new(8.63, 6.202, 8.235),collisionGroup)
	setmetatable(self,EggStore)
	
	self.instance = instance
	self.id = instance.Name
	return self
end

function EggStore:Enter(triggerer)
	local plr = Players:GetPlayerFromCharacter(triggerer)
	if plr == player then
        local controller = MyUIManager:GetController("EggStoreUI")
        if controller then
            controller:Show()
        end
	end
end

function EggStore:Leave(triggerer)
	local plr = Players:GetPlayerFromCharacter(triggerer)
	if plr == player then
        local controller = MyUIManager:GetController("EggStoreUI")
        if controller then
            controller:Hide()
        end
	end
end

return EggStore
