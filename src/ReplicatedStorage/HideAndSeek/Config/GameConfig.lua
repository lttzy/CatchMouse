--!strict
--[=[
	@class GameConfig
	躲猫猫游戏核心配置
	整合现有系统架构
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = {}

-- ============ 游戏全局设置 ============
GameConfig.GameSettings = {
	MaxPlayers = 20, -- 单局最大人数
	MinPlayers = 4, -- 最小开始人数
	GameDuration = 300, -- 游戏时长（5分钟）
	LobbyWaitTime = 30, -- 大厅等待时间
	PrepareTime = 15, -- 准备时间（躲藏者提前进入）
	ResultTime = 20, -- 结算展示时间
}

-- ============ 阵营设置 ============
GameConfig.TeamSettings = {
	HiderRatio = 0.6, -- 躲藏者比例 60%
	SeekerRatio = 0.4, -- 找寻者比例 40%
	Teams = {
		Hiders = {
			Name = "躲藏者",
			Color = Color3.fromRGB(0, 162, 255), -- 蓝色
			SpawnDelay = 0, -- 立即进入
		},
		Seekers = {
			Name = "找寻者",
			Color = Color3.fromRGB(255, 89, 89), -- 红色
			SpawnDelay = 15, -- 延迟15秒进入
		},
	},
}

-- ============ 基础数值设置 ============
GameConfig.BaseStats = {
	-- 躲藏者数值
	Hider = {
		MaxHealth = 100,
		WalkSpeed = 16,
		RunSpeed = 24,
		JumpPower = 50,
		StaminaMax = 100,
		StaminaRegen = 10, -- 每秒恢复
	},
	-- 找寻者数值
	Seeker = {
		WalkSpeed = 16,
		RunSpeed = 24,
		JumpPower = 50,
		WeaponDamage = 25, -- 4发淘汰
		FireRate = 0.5, -- 射击间隔
		ReloadTime = 2, -- 换弹时间
		AmmoCapacity = 12, -- 弹夹容量
		VisionRange = 80, -- 视野范围(studs)
		HearingRange = 40, -- 听觉范围(studs)
	},
}

-- ============ 经济系统设置 ============
GameConfig.Economy = {
	-- 基础奖励
	BaseRewards = {
		Participation = {
			Experience = 50,
			Gold = 30,
		},
		Victory = {
			Experience = 100,
			Gold = 60,
		},
		Defeat = {
			Experience = 25,
			Gold = 15,
		},
	},
	-- 表现奖励
	PerformanceRewards = {
		FirstElimination = { -- 首杀
			Experience = 50,
			Gold = 30,
		},
		Elimination = { -- 每次淘汰
			Experience = 25,
			Gold = 15,
		},
		Survival = { -- 每分钟生存
			Experience = 10,
			Gold = 5,
		},
		MVP = { -- MVP奖励
			Experience = 100,
			Gold = 50,
		},
	},
	-- VIP加成
	VIPBonus = {
		[1] = { ExpMultiplier = 1.1, GoldMultiplier = 1.1 },
		[2] = { ExpMultiplier = 1.2, GoldMultiplier = 1.2 },
		[3] = { ExpMultiplier = 1.3, GoldMultiplier = 1.3 },
		[4] = { ExpMultiplier = 1.4, GoldMultiplier = 1.4 },
		[5] = { ExpMultiplier = 1.5, GoldMultiplier = 1.5 },
	},
}

-- ============ 等级系统 ============
GameConfig.LevelSystem = {
	MaxLevel = 20,
	ExpRequired = { -- 每级所需经验
		[1] = 0,
		[2] = 100,
		[3] = 250,
		[4] = 450,
		[5] = 700,
		[6] = 1000,
		[7] = 1400,
		[8] = 1900,
		[9] = 2500,
		[10] = 3200,
		[11] = 4000,
		[12] = 4900,
		[13] = 5900,
		[14] = 7000,
		[15] = 8200,
		[16] = 9500,
		[17] = 11000,
		[18] = 12700,
		[19] = 14600,
		[20] = 17000,
	},
	-- 技能解锁等级
	SkillUnlockLevels = {1, 5, 10, 15, 20},
}

-- ============ 任务系统 ============
GameConfig.Missions = {
	Daily = {
		{
			id = "play_3_games",
			name = "新手试炼",
			description = "参与3局游戏",
			requirement = { type = "play_games", count = 3 },
			reward = { Gold = 100, Experience = 50 },
		},
		{
			id = "eliminate_5",
			name = "追捕专家",
			description = "淘汰5名躲藏者",
			requirement = { type = "eliminate", count = 5 },
			reward = { Gold = 150, Experience = 75 },
		},
		{
			id = "survive_once",
			name = "生存大师",
			description = "作为躲藏者存活到结束",
			requirement = { type = "survive_full_game", count = 1 },
			reward = { Gold = 150, Experience = 75 },
		},
		{
			id = "use_items_10",
			name = "道具收集",
			description = "使用10个道具",
			requirement = { type = "use_items", count = 10 },
			reward = { Gold = 100, Experience = 50 },
		},
		{
			id = "assist_3",
			name = "团队协作",
			description = "协助队友3次",
			requirement = { type = "assists", count = 3 },
			reward = { Gold = 120, Experience = 60 },
		},
	},
	Weekly = {
		{
			id = "play_20_games",
			name = "周末战士",
			description = "本周游戏20局",
			requirement = { type = "play_games", count = 20 },
			reward = { Gold = 500, Experience = 250 },
		},
		{
			id = "win_10_same_role",
			name = "角色精通",
			description = "使用同一角色赢10局",
			requirement = { type = "win_with_character", count = 10 },
			reward = { Gold = 800, Experience = 400 },
		},
		{
			id = "collect_all_items",
			name = "收藏家",
			description = "收集所有类型道具",
			requirement = { type = "collect_item_types", count = 15 },
			reward = { Gold = 600, Experience = 300 },
		},
		{
			id = "mvp_5",
			name = "MVP荣耀",
			description = "获得5次MVP",
			requirement = { type = "get_mvp", count = 5 },
			reward = { Gold = 1000, Experience = 500 },
		},
	},
}

-- ============ 地图设置 ============
GameConfig.Maps = {
	{
		id = "CityStreet",
		name = "城市街区",
		description = "建筑物密集，垂直空间多",
		minPlayers = 4,
		maxPlayers = 20,
		spawnPoints = {
			Hiders = 20,
			Seekers = 8,
		},
	},
	{
		id = "ShoppingMall",
		name = "购物中心",
		description = "室内环境，道具丰富",
		minPlayers = 4,
		maxPlayers = 16,
		spawnPoints = {
			Hiders = 16,
			Seekers = 6,
		},
	},
	{
		id = "ForestPark",
		name = "森林公园",
		description = "自然遮挡，视野受限",
		minPlayers = 4,
		maxPlayers = 20,
		spawnPoints = {
			Hiders = 20,
			Seekers = 8,
		},
	},
}

-- ============ 动态事件 ============
GameConfig.DynamicEvents = {
	{
		id = "item_drop",
		name = "道具空投",
		triggerTime = 60, -- 游戏开始后60秒
		duration = 10,
		description = "地图随机位置出现稀有道具",
	},
	{
		id = "zone_shrink",
		name = "安全区缩圈",
		triggerTime = 240, -- 最后1分钟
		duration = 60,
		description = "活动范围逐渐缩小",
	},
	{
		id = "double_speed",
		name = "极速时刻",
		triggerTime = 180, -- 第3分钟
		duration = 15,
		description = "所有玩家移速+20%",
	},
}

-- ============ 音效配置 ============
GameConfig.Sounds = {
	-- 复用现有的SoundController
	BGM = {
		Lobby = "LobbyBGM",
		InGame = "GameBGM",
		Victory = "VictoryBGM",
		Defeat = "DefeatBGM",
	},
	SFX = {
		Shoot = "GunShoot",
		Hit = "HitMarker",
		Transform = "TransformSound",
		ItemPickup = "ItemPickup",
		Footstep = "Footstep",
		Countdown = "Countdown",
	},
}

-- ============ UI配置 ============
GameConfig.UI = {
	-- 复用现有的UIManager
	HUD = {
		ShowTimer = true,
		ShowTeamCount = true,
		ShowMinimap = false, -- 躲猫猫不显示小地图
		ShowKillFeed = true,
		ShowItemSlots = true,
	},
	Colors = {
		Primary = Color3.fromRGB(255, 170, 0), -- 橙色
		Secondary = Color3.fromRGB(85, 170, 255), -- 浅蓝
		Success = Color3.fromRGB(85, 255, 127), -- 绿色
		Danger = Color3.fromRGB(255, 85, 85), -- 红色
		Warning = Color3.fromRGB(255, 255, 85), -- 黄色
	},
}

return GameConfig