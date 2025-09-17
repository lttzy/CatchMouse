--!strict
--[=[
	@class CharacterManager
	角色管理器 - 管理角色的选择、等级、能力和变身
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local BaseManager = require(ReplicatedStorage.Source.CommonFunctions.BaseManager)
local HideAndSeekCharacters = require(ReplicatedStorage.Source.Datas.HideAndSeekCharacters)
local Signal = require(ReplicatedStorage.Source.CommonFunctions.Signal)
local TableUtil = require(ReplicatedStorage.Source.CommonFunctions.TableUtil)
local Communication = require(ReplicatedStorage.Source.CommonFunctions.Communication)

-- 继承BaseManager
local CharacterManager = BaseManager.extend("CharacterManager")

-- 角色类型枚举
CharacterManager.CharacterType = {
	-- 找寻者角色
	SCOUT = "Scout",
	INTERCEPTOR = "Interceptor",
	SNIPER = "Sniper",
	HEAVY = "Heavy",
	ENGINEER = "Engineer",
	HANDLER = "Handler",

	-- 躲藏者角色
	SHIFTER = "Shifter",
	ILLUSIONIST = "Illusionist",
	SHADOW = "Shadow",
	TRICKSTER = "Trickster",
	HEALER = "Healer",
	RUNNER = "Runner",
}

-- 构造函数
function CharacterManager:Constructor()
	-- 玩家角色数据
	self.playerCharacters = {} -- { [Player] = { characterType, level, experience, skills } }
	self.playerTransforms = {} -- { [Player] = { isTransformed, transformObject } }

	-- 角色选择状态
	self.characterSelections = {} -- { [Player] = characterType }

	-- 信号
	self.CharacterSelected = Signal.new()
	self.CharacterLevelUp = Signal.new()
	self.CharacterTransformed = Signal.new()
	self.SkillUnlocked = Signal.new()

	-- 启用调试
	self:SetDebug(true)
end

-- ============ 重写基类方法 ============

function CharacterManager:OnInitialize()
	-- 监听玩家事件
	self.Maid:GiveTask(Players.PlayerAdded:Connect(function(player)
		self:InitializePlayerCharacter(player)
	end))

	self.Maid:GiveTask(Players.PlayerRemoving:Connect(function(player)
		self:CleanupPlayerCharacter(player)
	end))

	-- 注册通信事件
	self:RegisterCommunication()

	self:_log("角色管理器初始化完成")
end

function CharacterManager:OnStart()
	-- 为已在游戏中的玩家初始化
	for _, player in ipairs(Players:GetPlayers()) do
		self:InitializePlayerCharacter(player)
	end

	self:_log("角色管理器启动")
end

-- ============ 玩家角色管理 ============

function CharacterManager:InitializePlayerCharacter(player: Player)
	-- 从数据存储加载角色数据（这里先用默认值）
	self.playerCharacters[player] = {
		characterType = nil,
		level = 1,
		experience = 0,
		skills = {},
		unlockedCharacters = {CharacterManager.CharacterType.SCOUT, CharacterManager.CharacterType.SHIFTER}, -- 默认解锁两个角色
	}

	self:_log(string.format("初始化玩家 %s 的角色数据", player.Name))
end

function CharacterManager:CleanupPlayerCharacter(player: Player)
	self.playerCharacters[player] = nil
	self.playerTransforms[player] = nil
	self.characterSelections[player] = nil

	self:_log(string.format("清理玩家 %s 的角色数据", player.Name))
end

-- ============ 角色选择 ============

function CharacterManager:SelectCharacter(player: Player, characterType: string): boolean
	local playerData = self.playerCharacters[player]
	if not playerData then
		warn("玩家数据不存在")
		return false
	end

	-- 检查角色是否解锁
	if not table.find(playerData.unlockedCharacters, characterType) then
		warn(string.format("玩家 %s 尚未解锁角色 %s", player.Name, characterType))
		return false
	end

	-- 检查角色类型是否有效
	local characterData = HideAndSeekCharacters.Characters[characterType]
	if not characterData then
		warn(string.format("无效的角色类型: %s", characterType))
		return false
	end

	-- 设置选择的角色
	self.characterSelections[player] = characterType
	self.CharacterSelected:Fire(player, characterType)

	self:_log(string.format("玩家 %s 选择了角色 %s", player.Name, characterType))
	return true
end

function CharacterManager:GetPlayerCharacter(player: Player): string?
	return self.characterSelections[player]
end

function CharacterManager:GetCharacterData(characterType: string)
	return HideAndSeekCharacters.Characters[characterType]
end

-- ============ 角色能力应用 ============

function CharacterManager:ApplyCharacterAbilities(player: Player, team: string)
	local characterType = self.characterSelections[player]
	if not characterType then
		-- 随机分配一个默认角色
		local availableCharacters = team == "Seekers"
			and {"Scout", "Interceptor", "Sniper", "Heavy", "Engineer", "Handler"}
			or {"Shifter", "Illusionist", "Shadow", "Trickster", "Healer", "Runner"}
		characterType = availableCharacters[math.random(#availableCharacters)]
		self.characterSelections[player] = characterType
	end

	local characterData = self:GetCharacterData(characterType)
	if not characterData then return end

	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- 应用基础属性
	local stats = characterData.BaseStats
	if stats then
		if stats.WalkSpeed then
			humanoid.WalkSpeed = stats.WalkSpeed
		end
		if stats.JumpPower then
			humanoid.JumpPower = stats.JumpPower
		end
		if stats.MaxHealth then
			humanoid.MaxHealth = stats.MaxHealth
			humanoid.Health = stats.MaxHealth
		end
	end

	-- 存储角色类型到Character中
	local characterTypeValue = Instance.new("StringValue")
	characterTypeValue.Name = "CharacterType"
	characterTypeValue.Value = characterType
	characterTypeValue.Parent = character

	self:_log(string.format("为玩家 %s 应用角色 %s 的能力", player.Name, characterType))
end

-- ============ 等级系统 ============

function CharacterManager:AddExperience(player: Player, amount: number)
	local playerData = self.playerCharacters[player]
	if not playerData then return end

	playerData.experience = playerData.experience + amount

	-- 检查升级
	local requiredExp = self:GetRequiredExperience(playerData.level)
	while playerData.experience >= requiredExp do
		playerData.experience = playerData.experience - requiredExp
		playerData.level = playerData.level + 1

		-- 解锁新技能
		self:UnlockSkills(player, playerData.level)

		self.CharacterLevelUp:Fire(player, playerData.level)
		self:_log(string.format("玩家 %s 升级到 %d 级", player.Name, playerData.level))

		requiredExp = self:GetRequiredExperience(playerData.level)
	end
end

function CharacterManager:GetRequiredExperience(level: number): number
	-- 升级所需经验公式
	return 100 + (level - 1) * 50
end

function CharacterManager:GetPlayerLevel(player: Player): number
	local playerData = self.playerCharacters[player]
	return playerData and playerData.level or 1
end

-- ============ 技能系统 ============

function CharacterManager:UnlockSkills(player: Player, level: number)
	local characterType = self.characterSelections[player]
	if not characterType then return end

	local characterData = self:GetCharacterData(characterType)
	if not characterData or not characterData.Skills then return end

	local playerData = self.playerCharacters[player]
	if not playerData then return end

	-- 检查每个技能的解锁等级
	for skillName, skillData in pairs(characterData.Skills) do
		if skillData.UnlockLevel <= level and not playerData.skills[skillName] then
			playerData.skills[skillName] = {
				unlocked = true,
				cooldown = 0,
			}
			self.SkillUnlocked:Fire(player, skillName)
			self:_log(string.format("玩家 %s 解锁技能 %s", player.Name, skillName))
		end
	end
end

function CharacterManager:IsSkillUnlocked(player: Player, skillName: string): boolean
	local playerData = self.playerCharacters[player]
	if not playerData then return false end

	local skill = playerData.skills[skillName]
	return skill and skill.unlocked or false
end

function CharacterManager:GetPlayerSkills(player: Player)
	local playerData = self.playerCharacters[player]
	if not playerData then return {} end

	return playerData.skills
end

-- ============ 变形系统（躲藏者专用）============

function CharacterManager:TransformPlayer(player: Player, targetObject: string): boolean
	local characterType = self.characterSelections[player]
	if not characterType then return false end

	-- 检查是否是可以变形的角色
	local characterData = self:GetCharacterData(characterType)
	if not characterData or characterData.Team ~= "Hiders" then
		return false
	end

	-- 特别检查是否是变形师
	if characterType ~= "Shifter" then
		-- 其他躲藏者角色可能有限制
		return false
	end

	local character = player.Character
	if not character then return false end

	-- 如果已经变形，先恢复
	if self.playerTransforms[player] and self.playerTransforms[player].isTransformed then
		self:RevertTransform(player)
	end

	-- 执行变形逻辑
	self.playerTransforms[player] = {
		isTransformed = true,
		transformObject = targetObject,
		originalTransparency = {},
	}

	-- 隐藏角色模型（简化版实现）
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			self.playerTransforms[player].originalTransparency[part] = part.Transparency
			part.Transparency = 1
		end
	end

	-- TODO: 创建伪装物品模型

	self.CharacterTransformed:Fire(player, targetObject)
	self:_log(string.format("玩家 %s 变形为 %s", player.Name, targetObject))
	return true
end

function CharacterManager:RevertTransform(player: Player)
	local transformData = self.playerTransforms[player]
	if not transformData or not transformData.isTransformed then return end

	local character = player.Character
	if not character then return end

	-- 恢复原始透明度
	for part, transparency in pairs(transformData.originalTransparency) do
		if part and part.Parent then
			part.Transparency = transparency
		end
	end

	-- TODO: 移除伪装物品模型

	self.playerTransforms[player] = nil
	self.CharacterTransformed:Fire(player, nil)
	self:_log(string.format("玩家 %s 恢复原形", player.Name))
end

function CharacterManager:IsTransformed(player: Player): boolean
	local transformData = self.playerTransforms[player]
	return transformData and transformData.isTransformed or false
end

-- ============ 通信注册 ============

function CharacterManager:RegisterCommunication()
	-- 客户端请求选择角色
	Communication.OnServerEvent("SelectCharacter", function(player, characterType)
		local success = self:SelectCharacter(player, characterType)
		Communication.FireClient(player, "SelectCharacterResult", success)
	end)

	-- 客户端请求角色信息
	Communication.OnServerInvoke("GetCharacterInfo", function(player)
		local playerData = self.playerCharacters[player]
		if not playerData then return nil end

		return {
			characterType = self.characterSelections[player],
			level = playerData.level,
			experience = playerData.experience,
			skills = playerData.skills,
			unlockedCharacters = playerData.unlockedCharacters,
		}
	end)

	-- 客户端请求变形
	Communication.OnServerEvent("RequestTransform", function(player, targetObject)
		self:TransformPlayer(player, targetObject)
	end)
end

-- ============ 调试功能 ============

function CharacterManager:PrintStatus()
	print("========== CharacterManager Status ==========")
	print("玩家角色数据:")
	for player, data in pairs(self.playerCharacters) do
		print(string.format("  %s: 角色=%s, 等级=%d, 经验=%d",
			player.Name,
			self.characterSelections[player] or "未选择",
			data.level,
			data.experience
		))
	end
	print("==========================================")
end

return CharacterManager