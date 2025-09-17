--!strict
--[=[
	@class SkillManager
	技能管理器 - 管理角色技能的使用、冷却和效果
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local BaseManager = require(ReplicatedStorage.Source.CommonFunctions.BaseManager)
local HideAndSeekCharacters = require(ReplicatedStorage.Source.Datas.HideAndSeekCharacters)
local Signal = require(ReplicatedStorage.Source.CommonFunctions.Signal)
local Communication = require(ReplicatedStorage.Source.CommonFunctions.Communication)
local TableUtil = require(ReplicatedStorage.Source.CommonFunctions.TableUtil)

-- 继承BaseManager
local SkillManager = BaseManager.extend("SkillManager")

-- 构造函数
function SkillManager:Constructor()
	-- 技能数据
	self.playerSkillData = {} -- { [Player] = { skillName = { cooldown, lastUsed, charges } } }
	self.activeSkills = {} -- { [Player] = { skillName = { startTime, duration, data } } }

	-- 技能效果
	self.skillEffects = {} -- 正在进行的技能效果

	-- 信号
	self.SkillUsed = Signal.new()
	self.SkillCooldownStarted = Signal.new()
	self.SkillCooldownEnded = Signal.new()
	self.SkillEffectStarted = Signal.new()
	self.SkillEffectEnded = Signal.new()

	-- 启用调试
	self:SetDebug(true)
end

-- ============ 重写基类方法 ============

function SkillManager:OnInitialize()
	-- 监听玩家事件
	self.Maid:GiveTask(Players.PlayerAdded:Connect(function(player)
		self:InitializePlayerSkills(player)
	end))

	self.Maid:GiveTask(Players.PlayerRemoving:Connect(function(player)
		self:CleanupPlayerSkills(player)
	end))

	-- 注册通信事件
	self:RegisterCommunication()

	-- 设置更新循环
	self.Maid:GiveTask(RunService.Heartbeat:Connect(function(dt)
		self:OnUpdate(dt)
	end))

	self:_log("技能管理器初始化完成")
end

function SkillManager:OnStart()
	-- 为已在游戏中的玩家初始化
	for _, player in ipairs(Players:GetPlayers()) do
		self:InitializePlayerSkills(player)
	end

	self:_log("技能管理器启动")
end

function SkillManager:OnUpdate(dt: number)
	-- 更新技能冷却
	self:UpdateCooldowns(dt)

	-- 更新激活的技能效果
	self:UpdateActiveSkills(dt)
end

-- ============ 玩家技能初始化 ============

function SkillManager:InitializePlayerSkills(player: Player)
	self.playerSkillData[player] = {}
	self.activeSkills[player] = {}

	self:_log(string.format("初始化玩家 %s 的技能", player.Name))
end

function SkillManager:CleanupPlayerSkills(player: Player)
	-- 清理所有激活的技能
	for skillName, _ in pairs(self.activeSkills[player] or {}) do
		self:EndSkillEffect(player, skillName)
	end

	self.playerSkillData[player] = nil
	self.activeSkills[player] = nil

	self:_log(string.format("清理玩家 %s 的技能", player.Name))
end

-- ============ 技能使用 ============

function SkillManager:UseSkill(player: Player, skillId: number): boolean
	-- 获取玩家角色类型
	local characterType = self:GetPlayerCharacterType(player)
	if not characterType then
		warn("玩家没有选择角色")
		return false
	end

	-- 获取角色数据
	local characterData = HideAndSeekCharacters.Characters[characterType]
	if not characterData or not characterData.Skills then
		warn("角色数据或技能不存在")
		return false
	end

	-- 获取技能列表（按等级排序）
	local skills = {}
	for skillName, skillData in pairs(characterData.Skills) do
		table.insert(skills, {name = skillName, data = skillData})
	end
	table.sort(skills, function(a, b)
		return a.data.UnlockLevel < b.data.UnlockLevel
	end)

	-- 根据ID获取技能
	if skillId < 1 or skillId > #skills then
		warn(string.format("无效的技能ID: %d", skillId))
		return false
	end

	local skill = skills[skillId]
	local skillName = skill.name
	local skillData = skill.data

	-- 检查等级要求
	local playerLevel = self:GetPlayerLevel(player)
	if playerLevel < skillData.UnlockLevel then
		Communication.FireClient(player, "ShowNotification", string.format("需要等级 %d 才能使用此技能", skillData.UnlockLevel))
		return false
	end

	-- 检查冷却
	if self:IsSkillOnCooldown(player, skillName) then
		local remaining = self:GetCooldownRemaining(player, skillName)
		Communication.FireClient(player, "ShowNotification", string.format("技能冷却中 (%.1f秒)", remaining))
		return false
	end

	-- 检查技能使用次数限制
	if skillData.MaxUses then
		local uses = self:GetSkillUses(player, skillName)
		if uses >= skillData.MaxUses then
			Communication.FireClient(player, "ShowNotification", "技能使用次数已达上限")
			return false
		end
	end

	-- 执行技能效果
	self:ExecuteSkill(player, skillName, skillData)

	-- 设置冷却
	if skillData.Cooldown and skillData.Cooldown > 0 then
		self:StartCooldown(player, skillName, skillData.Cooldown)
	end

	-- 记录使用次数
	if skillData.MaxUses then
		self:IncrementSkillUses(player, skillName)
	end

	self.SkillUsed:Fire(player, skillName)
	Communication.FireAllClients("SkillUsed", player, skillName)

	self:_log(string.format("玩家 %s 使用了技能 %s", player.Name, skillName))
	return true
end

-- ============ 技能执行 ============

function SkillManager:ExecuteSkill(player: Player, skillName: string, skillData: table)
	local character = player.Character
	if not character then return end

	local characterType = self:GetPlayerCharacterType(player)
	if not characterType then return end

	-- 根据角色类型和技能名称执行不同的效果
	if characterType == "Scout" then
		self:ExecuteScoutSkills(player, skillName, skillData)
	elseif characterType == "Interceptor" then
		self:ExecuteInterceptorSkills(player, skillName, skillData)
	elseif characterType == "Sniper" then
		self:ExecuteSniperSkills(player, skillName, skillData)
	elseif characterType == "Heavy" then
		self:ExecuteHeavySkills(player, skillName, skillData)
	elseif characterType == "Engineer" then
		self:ExecuteEngineerSkills(player, skillName, skillData)
	elseif characterType == "Handler" then
		self:ExecuteHandlerSkills(player, skillName, skillData)
	elseif characterType == "Shifter" then
		self:ExecuteShifterSkills(player, skillName, skillData)
	elseif characterType == "Illusionist" then
		self:ExecuteIllusionistSkills(player, skillName, skillData)
	elseif characterType == "Shadow" then
		self:ExecuteShadowSkills(player, skillName, skillData)
	elseif characterType == "Trickster" then
		self:ExecuteTricksterSkills(player, skillName, skillData)
	elseif characterType == "Healer" then
		self:ExecuteHealerSkills(player, skillName, skillData)
	elseif characterType == "Runner" then
		self:ExecuteRunnerSkills(player, skillName, skillData)
	end
end

-- ============ 找寻者技能实现 ============

function SkillManager:ExecuteScoutSkills(player: Player, skillName: string, skillData: table)
	local character = player.Character
	if not character then return end

	if skillName == "RadarScan" then
		-- 雷达扫描 - 显示范围内躲藏者
		self:RadarScan(player, 10, 2)

	elseif skillName == "MarkShot" then
		-- 标记射击 - 命中后目标发光
		self:EnableMarkShot(player, 3)

	elseif skillName == "GlobalScan" then
		-- 全图扫描 - 显示所有躲藏者位置1秒
		self:GlobalScan(player, 1)
	end
end

function SkillManager:ExecuteInterceptorSkills(player: Player, skillName: string, skillData: table)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	if skillName == "Sprint" then
		-- 冲刺
		local originalSpeed = humanoid.WalkSpeed
		humanoid.WalkSpeed = humanoid.WalkSpeed * 1.5
		self:StartSkillEffect(player, skillName, 3)

		task.delay(3, function()
			if humanoid and humanoid.Parent then
				humanoid.WalkSpeed = originalSpeed
			end
		end)

	elseif skillName == "FlashBang" then
		-- 闪光弹
		self:CreateFlashBang(player, 5)

	elseif skillName == "StunShot" then
		-- 定身射击
		self:EnableStunShot(player, 2)

	elseif skillName == "EMPBlast" then
		-- EMP干扰
		self:CreateEMPBlast(player, 10, 5)
	end
end

-- ============ 躲藏者技能实现 ============

function SkillManager:ExecuteShifterSkills(player: Player, skillName: string, skillData: table)
	if skillName == "ObjectTransform" then
		-- 物品变形
		self:TransformToObject(player)

	elseif skillName == "FakeDecoy" then
		-- 假身残影
		self:CreateFakeDecoy(player)
	end
end

function SkillManager:ExecuteShadowSkills(player: Player, skillName: string, skillData: table)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	if skillName == "Invisibility" then
		-- 短暂隐身
		self:ApplyInvisibility(player, 2)

	elseif skillName == "SwiftStep" then
		-- 疾风步
		local originalSpeed = humanoid.WalkSpeed
		humanoid.WalkSpeed = humanoid.WalkSpeed * 1.3
		self:StartSkillEffect(player, skillName, 3)

		task.delay(3, function()
			if humanoid and humanoid.Parent then
				humanoid.WalkSpeed = originalSpeed
			end
		end)

	elseif skillName == "SmokeEscape" then
		-- 烟雾消失
		self:CreateSmokeEscape(player)
	end
end

-- ============ 技能效果方法 ============

function SkillManager:RadarScan(player: Player, range: number, duration: number)
	-- 扫描范围内的躲藏者
	local character = player.Character
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	-- 创建扫描效果
	local scanPart = Instance.new("Part")
	scanPart.Name = "RadarScan"
	scanPart.Size = Vector3.new(range * 2, 0.5, range * 2)
	scanPart.Position = humanoidRootPart.Position - Vector3.new(0, 3, 0)
	scanPart.Transparency = 0.8
	scanPart.BrickColor = BrickColor.new("Cyan")
	scanPart.Material = Enum.Material.ForceField
	scanPart.CanCollide = false
	scanPart.Anchored = true
	scanPart.Parent = Workspace

	Debris:AddItem(scanPart, duration)

	-- 寻找范围内的躲藏者
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player then
			local otherCharacter = otherPlayer.Character
			if otherCharacter then
				local otherHRP = otherCharacter:FindFirstChild("HumanoidRootPart")
				if otherHRP then
					local distance = (otherHRP.Position - humanoidRootPart.Position).Magnitude
					if distance <= range then
						-- 标记躲藏者
						self:MarkTarget(otherPlayer, duration)
					end
				end
			end
		end
	end
end

function SkillManager:GlobalScan(player: Player, duration: number)
	-- 显示所有躲藏者位置
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player then
			local team = self:GetPlayerTeam(otherPlayer)
			if team == "Hiders" then
				self:MarkTarget(otherPlayer, duration)
			end
		end
	end
end

function SkillManager:MarkTarget(target: Player, duration: number)
	local character = target.Character
	if not character then return end

	-- 创建高亮效果
	local highlight = Instance.new("Highlight")
	highlight.Name = "MarkHighlight"
	highlight.FillColor = Color3.new(1, 0, 0)
	highlight.OutlineColor = Color3.new(1, 0.5, 0)
	highlight.FillTransparency = 0.5
	highlight.OutlineTransparency = 0
	highlight.Parent = character

	Debris:AddItem(highlight, duration)
end

function SkillManager:CreateFlashBang(player: Player, range: number)
	local character = player.Character
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	-- 创建闪光效果
	local flashPart = Instance.new("Part")
	flashPart.Name = "FlashBang"
	flashPart.Size = Vector3.new(1, 1, 1)
	flashPart.Position = humanoidRootPart.Position
	flashPart.Transparency = 0
	flashPart.BrickColor = BrickColor.new("Institutional white")
	flashPart.Material = Enum.Material.Neon
	flashPart.CanCollide = false
	flashPart.Anchored = true
	flashPart.Parent = Workspace

	-- 扩展动画
	local tween = game:GetService("TweenService"):Create(
		flashPart,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = Vector3.new(range * 2, range * 2, range * 2), Transparency = 1}
	)
	tween:Play()

	Debris:AddItem(flashPart, 1)

	-- 影响范围内的玩家
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player then
			local otherCharacter = otherPlayer.Character
			if otherCharacter then
				local otherHRP = otherCharacter:FindFirstChild("HumanoidRootPart")
				if otherHRP then
					local distance = (otherHRP.Position - humanoidRootPart.Position).Magnitude
					if distance <= range then
						-- 致盲效果
						Communication.FireClient(otherPlayer, "ApplyBlindEffect", 2)
					end
				end
			end
		end
	end
end

function SkillManager:ApplyInvisibility(player: Player, duration: number)
	local character = player.Character
	if not character then return end

	-- 存储原始透明度
	local originalTransparency = {}
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			originalTransparency[part] = part.Transparency
			part.Transparency = 0.95 -- 几乎完全透明
		end
	end

	self:StartSkillEffect(player, "Invisibility", duration)

	-- 延迟恢复
	task.delay(duration, function()
		for part, transparency in pairs(originalTransparency) do
			if part and part.Parent then
				part.Transparency = transparency
			end
		end
	end)
end

function SkillManager:CreateSmokeEscape(player: Player)
	local character = player.Character
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	-- 创建大范围烟雾
	for i = 1, 5 do
		local smokePart = Instance.new("Part")
		smokePart.Name = "SmokeEscape"
		smokePart.Size = Vector3.new(10, 10, 10)
		smokePart.Position = humanoidRootPart.Position + Vector3.new(math.random(-5, 5), 0, math.random(-5, 5))
		smokePart.Transparency = 0.3
		smokePart.BrickColor = BrickColor.new("Dark stone grey")
		smokePart.Material = Enum.Material.Smoke
		smokePart.CanCollide = false
		smokePart.Anchored = true
		smokePart.Parent = Workspace

		Debris:AddItem(smokePart, 5)
	end

	-- 立即隐身
	self:ApplyInvisibility(player, 3)
end

-- ============ 冷却管理 ============

function SkillManager:StartCooldown(player: Player, skillName: string, cooldown: number)
	if not self.playerSkillData[player] then
		self.playerSkillData[player] = {}
	end

	self.playerSkillData[player][skillName] = {
		cooldown = cooldown,
		lastUsed = tick(),
		cooldownEnd = tick() + cooldown
	}

	self.SkillCooldownStarted:Fire(player, skillName, cooldown)
end

function SkillManager:IsSkillOnCooldown(player: Player, skillName: string): boolean
	local skillData = self.playerSkillData[player]
	if not skillData or not skillData[skillName] then
		return false
	end

	return tick() < skillData[skillName].cooldownEnd
end

function SkillManager:GetCooldownRemaining(player: Player, skillName: string): number
	local skillData = self.playerSkillData[player]
	if not skillData or not skillData[skillName] then
		return 0
	end

	local remaining = skillData[skillName].cooldownEnd - tick()
	return math.max(0, remaining)
end

function SkillManager:UpdateCooldowns(dt: number)
	local currentTime = tick()

	for player, skills in pairs(self.playerSkillData) do
		for skillName, data in pairs(skills) do
			if data.cooldownEnd and currentTime >= data.cooldownEnd then
				data.cooldownEnd = nil
				self.SkillCooldownEnded:Fire(player, skillName)
			end
		end
	end
end

-- ============ 技能效果管理 ============

function SkillManager:StartSkillEffect(player: Player, skillName: string, duration: number)
	if not self.activeSkills[player] then
		self.activeSkills[player] = {}
	end

	self.activeSkills[player][skillName] = {
		startTime = tick(),
		duration = duration,
		endTime = tick() + duration
	}

	self.SkillEffectStarted:Fire(player, skillName, duration)
end

function SkillManager:EndSkillEffect(player: Player, skillName: string)
	if self.activeSkills[player] then
		self.activeSkills[player][skillName] = nil
	end

	self.SkillEffectEnded:Fire(player, skillName)
end

function SkillManager:UpdateActiveSkills(dt: number)
	local currentTime = tick()

	for player, skills in pairs(self.activeSkills) do
		for skillName, data in pairs(skills) do
			if currentTime >= data.endTime then
				self:EndSkillEffect(player, skillName)
			end
		end
	end
end

-- ============ 技能使用次数管理 ============

function SkillManager:GetSkillUses(player: Player, skillName: string): number
	local skillData = self.playerSkillData[player]
	if not skillData or not skillData[skillName] then
		return 0
	end

	return skillData[skillName].uses or 0
end

function SkillManager:IncrementSkillUses(player: Player, skillName: string)
	if not self.playerSkillData[player] then
		self.playerSkillData[player] = {}
	end

	if not self.playerSkillData[player][skillName] then
		self.playerSkillData[player][skillName] = {}
	end

	local data = self.playerSkillData[player][skillName]
	data.uses = (data.uses or 0) + 1
end

function SkillManager:ResetSkillUses(player: Player)
	if self.playerSkillData[player] then
		for _, skillData in pairs(self.playerSkillData[player]) do
			skillData.uses = 0
		end
	end
end

-- ============ 辅助方法 ============

function SkillManager:GetPlayerCharacterType(player: Player): string?
	-- TODO: 从CharacterManager获取
	local character = player.Character
	if character then
		local characterTypeValue = character:FindFirstChild("CharacterType")
		if characterTypeValue and characterTypeValue:IsA("StringValue") then
			return characterTypeValue.Value
		end
	end
	return nil
end

function SkillManager:GetPlayerLevel(player: Player): number
	-- TODO: 从CharacterManager获取
	return 20 -- 暂时返回最高级别用于测试
end

function SkillManager:GetPlayerTeam(player: Player): string?
	-- TODO: 从GameManager获取
	return player.Team and player.Team.Name or nil
end

function SkillManager:TransformToObject(player: Player)
	-- TODO: 调用CharacterManager的变形功能
	Communication.FireClient(player, "ShowNotification", "变形功能开发中...")
end

function SkillManager:CreateFakeDecoy(player: Player)
	-- TODO: 创建假身
	Communication.FireClient(player, "ShowNotification", "假身功能开发中...")
end

function SkillManager:EnableMarkShot(player: Player, duration: number)
	-- TODO: 启用标记射击模式
	Communication.FireClient(player, "ShowNotification", string.format("标记射击已启用 (%d秒)", duration))
end

function SkillManager:EnableStunShot(player: Player, duration: number)
	-- TODO: 启用定身射击模式
	Communication.FireClient(player, "ShowNotification", string.format("定身射击已启用 (%d秒)", duration))
end

function SkillManager:CreateEMPBlast(player: Player, range: number, duration: number)
	-- TODO: 创建EMP爆炸效果
	Communication.FireClient(player, "ShowNotification", "EMP爆炸！")
end

-- ============ 通信注册 ============

function SkillManager:RegisterCommunication()
	-- 客户端请求使用技能
	Communication.OnServerEvent("UseSkill", function(player, skillId)
		self:UseSkill(player, skillId)
	end)

	-- 客户端请求技能信息
	Communication.OnServerInvoke("GetSkillInfo", function(player)
		local skills = self.playerSkillData[player] or {}
		local active = self.activeSkills[player] or {}

		return {
			skills = skills,
			activeEffects = active
		}
	end)

	-- 客户端请求冷却信息
	Communication.OnServerInvoke("GetSkillCooldowns", function(player)
		local cooldowns = {}
		local skills = self.playerSkillData[player] or {}

		for skillName, data in pairs(skills) do
			if data.cooldownEnd then
				cooldowns[skillName] = self:GetCooldownRemaining(player, skillName)
			end
		end

		return cooldowns
	end)
end

-- ============ 调试功能 ============

function SkillManager:PrintStatus()
	print("========== SkillManager Status ==========")
	print("玩家技能数据:")
	for player, skills in pairs(self.playerSkillData) do
		print(string.format("  %s:", player.Name))
		for skillName, data in pairs(skills) do
			local cooldown = self:GetCooldownRemaining(player, skillName)
			if cooldown > 0 then
				print(string.format("    %s: 冷却中 (%.1f秒)", skillName, cooldown))
			else
				print(string.format("    %s: 就绪", skillName))
			end
		end
	end
	print("激活的技能效果:")
	for player, effects in pairs(self.activeSkills) do
		if next(effects) then
			print(string.format("  %s:", player.Name))
			for skillName, data in pairs(effects) do
				local remaining = data.endTime - tick()
				print(string.format("    %s: %.1f秒剩余", skillName, remaining))
			end
		end
	end
	print("==========================================")
end

return SkillManager