local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Utils = require(ReplicatedStorage.Source.Utils)
local BaseClass = require(ReplicatedStorage.Source.Entities)
local ConfigDatas = require(ReplicatedStorage.Source.Datas)
local Maid = require(ReplicatedStorage.Source.CommonFunctions.Maid)
local TableUtil = require(ReplicatedStorage.Source.CommonFunctions.TableUtil)
local CameraShaker = require(ReplicatedStorage.Source.CommonFunctions.CameraShaker)
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local PlayerEntity = BaseClass:extends()

function PlayerEntity:TeleportToPart(targetPart: BasePart, offset: Vector3)
	self.player.Character.HumanoidRootPart.CFrame = targetPart.CFrame * CFrame.new(offset or Vector3.zero)
	if self.ShoulderCamera then
		self.ShoulderCamera:SetCameraOrientationAbsolute(targetPart.CFrame)
	end
end

function PlayerEntity.new(player, player_data)
	local self = setmetatable(PlayerEntity:super(player.UserId), PlayerEntity)
	self.player = player
	self.playerData = player_data
	self.Maid = Maid.new()
	if player == localPlayer then
		self.localP = true
	end
	self:EntityInit()
	if self.localP then
	end

	return self
end

PlayerEntity.Enum = {}


function PlayerEntity:UpdateAllData(data)
	self.playerData = data
	-- if self.humanoid then
	-- 	self.humanoid.JumpPower = self.playerData.movement_data.jump_power
	-- 	self.humanoid.WalkSpeed = self.playerData.movement_data.walk_speed
	-- end
end

function PlayerEntity:EntityInit()
	-- 参数初始化
	self.char = self.player.Character or self.player.CharacterAdded:Wait()
	self.humanoid = self.char:WaitForChild("Humanoid")
	self.root = self.char:WaitForChild("HumanoidRootPart")
end


function PlayerEntity:Hide()
	self.char.Parent = nil
end

function PlayerEntity:Show()
	self.char.Parent = workspace
end

return PlayerEntity
