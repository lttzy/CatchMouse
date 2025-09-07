local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):wait()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

Zone = {}
Zone.__index = Zone

function Zone.new(cframe:CFrame,size:Vector3,collisionGroup:string)
	local self = {}
	setmetatable(self,Zone)
	
	self.listen = {
		enter = nil,
		leave = nil
	}
	
	self.cframe = cframe
	self.size = size

	self.canActivated = true
	self.checkParams = OverlapParams.new()
	self.checkParams.CollisionGroup = collisionGroup or "Default"
	self.checkParams.MaxParts = math.huge

	self:ActivatedEnterTask()
	
	return self
end

function Zone:ActivatedEnterTask()
	if self.listen.enter then self.listen.enter:Disconnect() self.listen.enter = nil end
	self.canActivated = true
	self.listen.enter = RunService.PostSimulation:Connect(function(dt)
		local objectsInSpace = workspace:GetPartBoundsInBox(self.cframe,self.size,self.checkParams)
		if #objectsInSpace > 0 and self.canActivated == true then
			for _,v in pairs(objectsInSpace) do
				if v.Parent:FindFirstChild("Humanoid") then
					local plr = Players:GetPlayerFromCharacter(v.Parent)
					if plr == player then
						if self.listen.enter then self.listen.enter:Disconnect() self.listen.enter = nil end
						self.canActivated = false
						self:Enter(v.Parent)
						self:ActivatedLeaveTask()
						break
					end
				end
			end
		end
	end)
end

function Zone:ActivatedLeaveTask()
	if self.listen.leave then self.listen.leave:Disconnect() self.listen.leave = nil end
	self.listen.leave = RunService.PostSimulation:Connect(function(dt)
		local objectsInSpace = workspace:GetPartBoundsInBox(self.cframe,self.size,self.checkParams)
		if #objectsInSpace < 1 then
			if self.listen.leave then self.listen.leave:Disconnect() self.listen.leave = nil end
			self:Leave(player.Character)
			self:ActivatedEnterTask()
			self.canActivated = true
		else
			local stillStay = false
			for _,v in pairs(objectsInSpace) do
				if v.Parent:FindFirstChild("Humanoid") then
					local plr = Players:GetPlayerFromCharacter(v.Parent)
					if plr == player then
						stillStay = true
					end
				end
			end
			if stillStay == false then
				if self.listen.leave then self.listen.leave:Disconnect() self.listen.leave = nil end
				self:Leave(player.Character)
				self:ActivatedEnterTask()
				self.canActivated = true
			end
		end
	end)
end

function Zone:Enter(triggerer)
end

function Zone:Leave(triggerer)
end

function Zone:Stop()
	for _,v in pairs(self.listen) do
		if v then v:Disconnect() v= nil end
	end
end

return Zone
