--!strict
--[=[
	@class ItemManager
	道具管理器 - 管理游戏中的道具生成、拾取和使用
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local BaseManager = require(ReplicatedStorage.Source.CommonFunctions.BaseManager)
local HideAndSeekItems = require(ReplicatedStorage.Source.Datas.HideAndSeekItems)
local Signal = require(ReplicatedStorage.Source.CommonFunctions.Signal)
local Communication = require(ReplicatedStorage.Source.CommonFunctions.Communication)
local TableUtil = require(ReplicatedStorage.Source.CommonFunctions.TableUtil)

-- 继承BaseManager
local ItemManager = BaseManager.extend("ItemManager")

-- 构造函数
function ItemManager:Constructor()
	-- 道具容器
	self.spawnedItems = {} -- { [ItemModel] = itemData }
	self.playerInventories = {} -- { [Player] = { itemType = count } }
	self.itemSpawnPoints = {} -- 道具生成点
	self.activeEffects = {} -- { [Player] = { effectType = endTime } }

	-- 配置
	self.maxItemsPerPlayer = 3
	self.itemSpawnInterval = 30 -- 秒
	self.maxMapItems = 20

	-- 信号
	self.ItemSpawned = Signal.new()
	self.ItemCollected = Signal.new()
	self.ItemUsed = Signal.new()
	self.ItemEffectStarted = Signal.new()
	self.ItemEffectEnded = Signal.new()

	-- 计时器
	self.spawnTimer = 0

	-- 启用调试
	self:SetDebug(true)
end

-- ============ 重写基类方法 ============

function ItemManager:OnInitialize()
	-- 创建道具文件夹
	local itemsFolder = Instance.new("Folder")
	itemsFolder.Name = "SpawnedItems"
	itemsFolder.Parent = Workspace
	self.itemsFolder = itemsFolder

	-- 监听玩家事件
	self.Maid:GiveTask(Players.PlayerAdded:Connect(function(player)
		self:InitializePlayerInventory(player)
	end))

	self.Maid:GiveTask(Players.PlayerRemoving:Connect(function(player)
		self:CleanupPlayerInventory(player)
	end))

	-- 注册通信事件
	self:RegisterCommunication()

	-- 设置更新循环
	self.Maid:GiveTask(RunService.Heartbeat:Connect(function(dt)
		self:OnUpdate(dt)
	end))

	self:_log("道具管理器初始化完成")
end

function ItemManager:OnStart()
	-- 为已在游戏中的玩家初始化
	for _, player in ipairs(Players:GetPlayers()) do
		self:InitializePlayerInventory(player)
	end

	-- 初始化道具生成点
	self:InitializeSpawnPoints()

	self:_log("道具管理器启动")
end

function ItemManager:OnUpdate(dt: number)
	-- 更新道具生成计时器
	self.spawnTimer = self.spawnTimer + dt
	if self.spawnTimer >= self.itemSpawnInterval then
		self:SpawnRandomItems()
		self.spawnTimer = 0
	end

	-- 更新道具效果
	self:UpdateItemEffects(dt)
end

-- ============ 玩家背包管理 ============

function ItemManager:InitializePlayerInventory(player: Player)
	self.playerInventories[player] = {}
	self.activeEffects[player] = {}

	self:_log(string.format("初始化玩家 %s 的背包", player.Name))
end

function ItemManager:CleanupPlayerInventory(player: Player)
	-- 清理所有激活的效果
	for effectType, _ in pairs(self.activeEffects[player] or {}) do
		self:EndItemEffect(player, effectType)
	end

	self.playerInventories[player] = nil
	self.activeEffects[player] = nil

	self:_log(string.format("清理玩家 %s 的背包", player.Name))
end

function ItemManager:GetPlayerInventory(player: Player)
	return self.playerInventories[player] or {}
end

function ItemManager:GetInventoryCount(player: Player): number
	local inventory = self.playerInventories[player]
	if not inventory then return 0 end

	local count = 0
	for _, quantity in pairs(inventory) do
		count = count + quantity
	end
	return count
end

-- ============ 道具生成点管理 ============

function ItemManager:InitializeSpawnPoints()
	-- TODO: 从地图中获取预设的生成点
	-- 这里先创建一些测试生成点
	local basePosition = Vector3.new(0, 5, 0)
	for i = 1, 10 do
		local angle = (i / 10) * math.pi * 2
		local position = basePosition + Vector3.new(
			math.cos(angle) * 30,
			0,
			math.sin(angle) * 30
		)
		table.insert(self.itemSpawnPoints, position)
	end

	self:_log(string.format("初始化了 %d 个道具生成点", #self.itemSpawnPoints))
end

-- ============ 道具生成 ============

function ItemManager:SpawnRandomItems()
	local currentItemCount = 0
	for _ in pairs(self.spawnedItems) do
		currentItemCount = currentItemCount + 1
	end

	if currentItemCount >= self.maxMapItems then
		return
	end

	-- 随机生成3-5个道具
	local spawnCount = math.random(3, 5)
	spawnCount = math.min(spawnCount, self.maxMapItems - currentItemCount)

	for i = 1, spawnCount do
		self:SpawnItem()
	end
end

function ItemManager:SpawnItem(itemType: string?, position: Vector3?)
	-- 如果没有指定类型，随机选择
	if not itemType then
		local itemTypes = {}
		for name, _ in pairs(HideAndSeekItems.Items) do
			table.insert(itemTypes, name)
		end
		itemType = itemTypes[math.random(#itemTypes)]
	end

	local itemData = HideAndSeekItems.Items[itemType]
	if not itemData then
		warn(string.format("无效的道具类型: %s", tostring(itemType)))
		return
	end

	-- 如果没有指定位置，从生成点随机选择
	if not position and #self.itemSpawnPoints > 0 then
		position = self.itemSpawnPoints[math.random(#self.itemSpawnPoints)]
	end

	if not position then
		warn("没有可用的生成点")
		return
	end

	-- 创建道具模型
	local itemModel = self:CreateItemModel(itemType, itemData)
	itemModel.Position = position
	itemModel.Parent = self.itemsFolder

	-- 记录道具
	self.spawnedItems[itemModel] = {
		type = itemType,
		data = itemData,
		spawnTime = tick(),
	}

	-- 添加拾取检测
	self:SetupItemPickup(itemModel)

	self.ItemSpawned:Fire(itemType, position)
	self:_log(string.format("生成道具 %s 在位置 %s", itemType, tostring(position)))
end

function ItemManager:CreateItemModel(itemType: string, itemData: table): Part
	-- 创建简单的道具模型（实际项目中应该从资源加载）
	local part = Instance.new("Part")
	part.Name = itemType
	part.Size = Vector3.new(2, 2, 2)
	part.Material = Enum.Material.Neon
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CanCollide = false
	part.Anchored = true

	-- 根据稀有度设置颜色
	if itemData.Rarity == "Common" then
		part.BrickColor = BrickColor.new("Medium stone grey")
	elseif itemData.Rarity == "Rare" then
		part.BrickColor = BrickColor.new("Bright blue")
	elseif itemData.Rarity == "Epic" then
		part.BrickColor = BrickColor.new("Royal purple")
	elseif itemData.Rarity == "Legendary" then
		part.BrickColor = BrickColor.new("Gold")
	end

	-- 添加发光效果
	local pointLight = Instance.new("PointLight")
	pointLight.Brightness = 2
	pointLight.Range = 10
	pointLight.Color = part.Color
	pointLight.Parent = part

	-- 添加旋转动画
	local bodyPosition = Instance.new("BodyPosition")
	bodyPosition.MaxForce = Vector3.new(4000, 4000, 4000)
	bodyPosition.Position = part.Position
	bodyPosition.Parent = part

	local bodyAngularVelocity = Instance.new("BodyAngularVelocity")
	bodyAngularVelocity.AngularVelocity = Vector3.new(0, 2, 0)
	bodyAngularVelocity.MaxTorque = Vector3.new(0, math.huge, 0)
	bodyAngularVelocity.Parent = part

	return part
end

function ItemManager:SetupItemPickup(itemModel: Part)
	-- 使用触摸检测
	local connection
	connection = itemModel.Touched:Connect(function(hit)
		local humanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end

		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player then return end

		-- 尝试拾取道具
		if self:CollectItem(player, itemModel) then
			connection:Disconnect()
		end
	end)

	-- 添加到清理列表
	self.Maid:GiveTask(connection)
end

-- ============ 道具拾取 ============

function ItemManager:CollectItem(player: Player, itemModel: Part): boolean
	local itemInfo = self.spawnedItems[itemModel]
	if not itemInfo then return false end

	-- 检查背包是否已满
	if self:GetInventoryCount(player) >= self.maxItemsPerPlayer then
		-- 发送背包已满提示
		Communication.FireClient(player, "ShowNotification", "背包已满！")
		return false
	end

	-- 检查队伍限制
	local itemData = itemInfo.data
	if itemData.TeamRestriction then
		local playerTeam = self:GetPlayerTeam(player)
		if playerTeam ~= itemData.TeamRestriction then
			Communication.FireClient(player, "ShowNotification", "该道具仅限" .. itemData.TeamRestriction .. "使用！")
			return false
		end
	end

	-- 添加到背包
	local inventory = self.playerInventories[player]
	inventory[itemInfo.type] = (inventory[itemInfo.type] or 0) + 1

	-- 移除地图上的道具
	self.spawnedItems[itemModel] = nil
	itemModel:Destroy()

	self.ItemCollected:Fire(player, itemInfo.type)
	Communication.FireClient(player, "ItemCollected", itemInfo.type)

	self:_log(string.format("玩家 %s 拾取了道具 %s", player.Name, itemInfo.type))
	return true
end

-- ============ 道具使用 ============

function ItemManager:UseItem(player: Player, itemType: string): boolean
	local inventory = self.playerInventories[player]
	if not inventory or not inventory[itemType] or inventory[itemType] <= 0 then
		return false
	end

	local itemData = HideAndSeekItems.Items[itemType]
	if not itemData then return false end

	-- 检查队伍限制
	if itemData.TeamRestriction then
		local playerTeam = self:GetPlayerTeam(player)
		if playerTeam ~= itemData.TeamRestriction then
			return false
		end
	end

	-- 消耗道具
	inventory[itemType] = inventory[itemType] - 1
	if inventory[itemType] <= 0 then
		inventory[itemType] = nil
	end

	-- 应用道具效果
	self:ApplyItemEffect(player, itemType, itemData)

	self.ItemUsed:Fire(player, itemType)
	Communication.FireClient(player, "ItemUsed", itemType)

	self:_log(string.format("玩家 %s 使用了道具 %s", player.Name, itemType))
	return true
end

-- ============ 道具效果 ============

function ItemManager:ApplyItemEffect(player: Player, itemType: string, itemData: table)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- 根据道具类型应用效果
	if itemData.Effect == "Speed" then
		-- 速度提升
		local originalSpeed = humanoid.WalkSpeed
		humanoid.WalkSpeed = humanoid.WalkSpeed * 1.3
		self:StartItemEffect(player, itemType, itemData.Duration or 5)

		-- 延迟恢复
		task.delay(itemData.Duration or 5, function()
			if humanoid and humanoid.Parent then
				humanoid.WalkSpeed = originalSpeed
			end
		end)

	elseif itemData.Effect == "Invisibility" then
		-- 隐身效果
		self:ApplyInvisibility(player, itemData.Duration or 3)
		self:StartItemEffect(player, itemType, itemData.Duration or 3)

	elseif itemData.Effect == "Shield" then
		-- 护盾效果
		self:ApplyShield(player, itemData.Duration or 10)
		self:StartItemEffect(player, itemType, itemData.Duration or 10)

	elseif itemData.Effect == "Teleport" then
		-- 随机传送
		self:TeleportToRandomLocation(player)

	elseif itemData.Effect == "Heal" then
		-- 治疗效果
		humanoid.Health = math.min(humanoid.Health + 20, humanoid.MaxHealth)

	elseif itemData.Effect == "Smoke" then
		-- 烟雾弹效果
		self:CreateSmokeArea(character.HumanoidRootPart.Position, itemData.Duration or 5)

	elseif itemData.Effect == "Decoy" then
		-- 创建诱饵
		self:CreateDecoy(player)
	end
end

function ItemManager:ApplyInvisibility(player: Player, duration: number)
	local character = player.Character
	if not character then return end

	-- 存储原始透明度
	local originalTransparency = {}
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			originalTransparency[part] = part.Transparency
			part.Transparency = 0.9 -- 半透明
		end
	end

	-- 延迟恢复
	task.delay(duration, function()
		for part, transparency in pairs(originalTransparency) do
			if part and part.Parent then
				part.Transparency = transparency
			end
		end
	end)
end

function ItemManager:ApplyShield(player: Player, duration: number)
	-- 为玩家添加减伤标记
	local character = player.Character
	if not character then return end

	local shieldValue = Instance.new("NumberValue")
	shieldValue.Name = "ShieldReduction"
	shieldValue.Value = 0.3 -- 30%减伤
	shieldValue.Parent = character

	Debris:AddItem(shieldValue, duration)
end

function ItemManager:TeleportToRandomLocation(player: Player)
	local character = player.Character
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	-- 选择随机生成点
	if #self.itemSpawnPoints > 0 then
		local randomPoint = self.itemSpawnPoints[math.random(#self.itemSpawnPoints)]
		humanoidRootPart.CFrame = CFrame.new(randomPoint + Vector3.new(0, 5, 0))
	end
end

function ItemManager:CreateSmokeArea(position: Vector3, duration: number)
	-- 创建烟雾效果区域
	local smokePart = Instance.new("Part")
	smokePart.Name = "SmokeArea"
	smokePart.Size = Vector3.new(15, 15, 15)
	smokePart.Position = position
	smokePart.Transparency = 0.5
	smokePart.BrickColor = BrickColor.new("Medium stone grey")
	smokePart.Material = Enum.Material.Smoke
	smokePart.CanCollide = false
	smokePart.Anchored = true
	smokePart.Parent = self.itemsFolder

	Debris:AddItem(smokePart, duration)
end

function ItemManager:CreateDecoy(player: Player)
	local character = player.Character
	if not character then return end

	-- 创建假人模型
	local decoy = Instance.new("Model")
	decoy.Name = "Decoy_" .. player.Name

	-- 复制角色外观（简化版）
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart then
		local decoyPart = Instance.new("Part")
		decoyPart.Name = "HumanoidRootPart"
		decoyPart.Size = humanoidRootPart.Size
		decoyPart.Position = humanoidRootPart.Position + Vector3.new(5, 0, 0)
		decoyPart.BrickColor = BrickColor.new("Bright blue")
		decoyPart.Material = Enum.Material.Neon
		decoyPart.CanCollide = false
		decoyPart.Anchored = true
		decoyPart.Parent = decoy

		-- 添加人形
		local humanoid = Instance.new("Humanoid")
		humanoid.MaxHealth = 1
		humanoid.Health = 1
		humanoid.Parent = decoy
	end

	decoy.Parent = self.itemsFolder
	Debris:AddItem(decoy, 10) -- 10秒后消失
end

-- ============ 效果管理 ============

function ItemManager:StartItemEffect(player: Player, effectType: string, duration: number)
	if not self.activeEffects[player] then
		self.activeEffects[player] = {}
	end

	self.activeEffects[player][effectType] = tick() + duration
	self.ItemEffectStarted:Fire(player, effectType, duration)
end

function ItemManager:EndItemEffect(player: Player, effectType: string)
	if self.activeEffects[player] then
		self.activeEffects[player][effectType] = nil
	end
	self.ItemEffectEnded:Fire(player, effectType)
end

function ItemManager:UpdateItemEffects(dt: number)
	local currentTime = tick()
	for player, effects in pairs(self.activeEffects) do
		for effectType, endTime in pairs(effects) do
			if currentTime >= endTime then
				self:EndItemEffect(player, effectType)
			end
		end
	end
end

function ItemManager:GetActiveEffects(player: Player)
	return self.activeEffects[player] or {}
end

-- ============ 辅助方法 ============

function ItemManager:GetPlayerTeam(player: Player): string?
	-- TODO: 从GameManager获取玩家队伍
	-- 这里暂时返回nil
	return nil
end

function ItemManager:ClearAllItems()
	for itemModel, _ in pairs(self.spawnedItems) do
		itemModel:Destroy()
	end
	self.spawnedItems = {}
	self:_log("清除所有地图道具")
end

-- ============ 通信注册 ============

function ItemManager:RegisterCommunication()
	-- 客户端请求使用道具
	Communication.OnServerEvent("UseItem", function(player, itemType)
		self:UseItem(player, itemType)
	end)

	-- 客户端请求背包信息
	Communication.OnServerInvoke("GetInventory", function(player)
		return self:GetPlayerInventory(player)
	end)

	-- 客户端请求活跃效果
	Communication.OnServerInvoke("GetActiveEffects", function(player)
		return self:GetActiveEffects(player)
	end)
end

-- ============ 调试功能 ============

function ItemManager:PrintStatus()
	print("========== ItemManager Status ==========")
	print(string.format("地图道具数量: %d", TableUtil.Count(self.spawnedItems)))
	print(string.format("生成点数量: %d", #self.itemSpawnPoints))
	print("玩家背包:")
	for player, inventory in pairs(self.playerInventories) do
		local itemList = {}
		for itemType, count in pairs(inventory) do
			table.insert(itemList, string.format("%s×%d", itemType, count))
		end
		print(string.format("  %s: %s", player.Name, table.concat(itemList, ", ")))
	end
	print("==========================================")
end

return ItemManager