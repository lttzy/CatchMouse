--!strict
-- 躲猫猫游戏角色配置
-- 复用现有的ConfigDatas系统

local Characters = {
	-- ============ 找寻者角色 ============
	{
		id = "Scout",
		name = "追踪者",
		team = "Seeker",
		type = "侦查型",
		baseStats = {
			walkSpeed = 16,
			visionRange = 96, -- 120% of base
		},
		skills = {
			[1] = {
				name = "雷达扫描",
				description = "10米范围内显示躲藏者轮廓2秒",
				cooldown = 30,
				range = 10,
				duration = 2,
			},
			[5] = {
				name = "标记射击",
				description = "命中后目标发光3秒，全队可见",
				cooldown = 20,
				duration = 3,
			},
			[10] = {
				name = "雷达扩展",
				description = "雷达范围+20%",
				passive = true,
				rangeBonus = 0.2,
			},
			[15] = {
				name = "团队共享",
				description = "雷达扫描结果队友共享",
				passive = true,
			},
			[20] = {
				name = "全图扫描",
				description = "显示所有躲藏者位置1秒",
				limited = 1,
				duration = 1,
			},
		},
		price = 0, -- 初始免费
		icon = "rbxassetid://0", -- 需要替换为实际图标ID
	},
	{
		id = "Interceptor",
		name = "拦截者",
		team = "Seeker",
		type = "控制型",
		baseStats = {
			walkSpeed = 16.8, -- 105%
			stamina = 120, -- +20%
		},
		skills = {
			[1] = {
				name = "冲刺",
				description = "速度+50%持续3秒",
				cooldown = 25,
				speedBonus = 0.5,
				duration = 3,
			},
			[5] = {
				name = "闪光弹",
				description = "5米范围致盲2秒",
				cooldown = 30,
				range = 5,
				duration = 2,
			},
			[10] = {
				name = "定身射击",
				description = "命中后锁定移动2秒",
				cooldown = 35,
				duration = 2,
			},
			[15] = {
				name = "冲刺强化",
				description = "冲刺CD-30%",
				passive = true,
				cdReduction = 0.3,
			},
			[20] = {
				name = "EMP干扰",
				description = "10米范围禁用道具5秒",
				cooldown = 60,
				range = 10,
				duration = 5,
			},
		},
		price = 5000,
		icon = "rbxassetid://0",
	},
	{
		id = "Sniper",
		name = "狙击手",
		team = "Seeker",
		type = "精准型",
		baseStats = {
			walkSpeed = 16,
			shootRange = 130, -- +30%
			accuracy = 1.4, -- +40%
		},
		skills = {
			[1] = {
				name = "高精度射击",
				description = "伤害+25%",
				passive = true,
				damageBonus = 0.25,
			},
			[5] = {
				name = "透视镜",
				description = "透视障碍物看到躲藏者2秒",
				cooldown = 40,
				duration = 2,
			},
			[10] = {
				name = "标记爆头",
				description = "爆头额外显形5秒",
				passive = true,
				headshotMark = 5,
			},
			[15] = {
				name = "扩容弹夹",
				description = "弹药+50%",
				passive = true,
				ammoBonus = 0.5,
			},
			[20] = {
				name = "远程标记",
				description = "瞄准3秒后永久标记目标",
				cooldown = 45,
				aimTime = 3,
			},
		},
		price = 5000,
		icon = "rbxassetid://0",
	},
	{
		id = "Heavy",
		name = "重装兵",
		team = "Seeker",
		type = "压制型",
		baseStats = {
			walkSpeed = 14.4, -- 90%
			armor = 0.3, -- 装甲值+30%（减少控制效果）
		},
		skills = {
			[1] = {
				name = "快速换弹",
				description = "换弹速度+50%",
				passive = true,
				reloadSpeed = 1.5,
			},
			[5] = {
				name = "火力压制",
				description = "射速+20%持续3秒",
				cooldown = 30,
				fireRateBonus = 0.2,
				duration = 3,
			},
			[10] = {
				name = "护盾无人机",
				description = "为附近队友提供10%减伤",
				passive = true,
				damageReduction = 0.1,
				range = 10,
			},
			[15] = {
				name = "火力扩展",
				description = "子弹有溅射效果",
				passive = true,
				splash = true,
			},
			[20] = {
				name = "超载模式",
				description = "射速+50%持续10秒",
				limited = 1,
				fireRateBonus = 0.5,
				duration = 10,
			},
		},
		price = 5000,
		icon = "rbxassetid://0",
	},
	{
		id = "Engineer",
		name = "工程师",
		team = "Seeker",
		type = "战术型",
		baseStats = {
			walkSpeed = 16,
			itemEfficiency = 1.15, -- 道具效果+15%
			buildSpeed = 1.3, -- 建造速度+30%
		},
		skills = {
			[1] = {
				name = "感应器",
				description = "部署5米感应装置",
				cooldown = 20,
				range = 5,
			},
			[5] = {
				name = "侦测无人机",
				description = "自动追踪并标记躲藏者",
				cooldown = 45,
			},
			[10] = {
				name = "伪装探测",
				description = "揭露15米内伪装3秒",
				cooldown = 35,
				range = 15,
				duration = 3,
			},
			[15] = {
				name = "道具强化",
				description = "道具使用效率+30%",
				passive = true,
				itemBonus = 0.3,
			},
			[20] = {
				name = "雷达塔",
				description = "部署永久区域侦测装置",
				cooldown = 60,
			},
		},
		price = 5000,
		icon = "rbxassetid://0",
	},
	{
		id = "Handler",
		name = "猎犬师",
		team = "Seeker",
		type = "特殊型",
		baseStats = {
			walkSpeed = 15.2, -- 95%
			petDamage = 1.2, -- 宠物伤害+20%
		},
		skills = {
			[1] = {
				name = "嗅探犬",
				description = "召唤追踪犬，8米感知",
				passive = true,
				detectRange = 8,
			},
			[5] = {
				name = "犬类冲击",
				description = "扑倒躲藏者1秒",
				cooldown = 25,
				stunDuration = 1,
			},
			[10] = {
				name = "强化嗅觉",
				description = "感知范围+50%",
				passive = true,
				rangeBonus = 0.5,
			},
			[15] = {
				name = "双犬巡逻",
				description = "同时存在2只追踪犬",
				passive = true,
				dogCount = 2,
			},
			[20] = {
				name = "自动锁定",
				description = "犬自动追踪最近目标",
				cooldown = 40,
			},
		},
		price = 5000,
		icon = "rbxassetid://0",
	},
	
	-- ============ 躲藏者角色 ============
	{
		id = "Shifter",
		name = "变形师",
		team = "Hider",
		type = "伪装型",
		baseStats = {
			walkSpeed = 16,
			transformSpeed = 1.0,
			disguiseAccuracy = 0.9,
		},
		skills = {
			[1] = {
				name = "物品变形",
				description = "变成场景物品",
				cooldown = 10,
			},
			[5] = {
				name = "快速变形",
				description = "变形CD-30%",
				passive = true,
				cdReduction = 0.3,
			},
			[10] = {
				name = "精准伪装",
				description = "完美复制材质和大小",
				passive = true,
			},
			[15] = {
				name = "假身残影",
				description = "留下假物品迷惑",
				cooldown = 30,
			},
			[20] = {
				name = "多重伪装",
				description = "可储存2个形态快速切换",
				passive = true,
				formCount = 2,
			},
		},
		price = 0, -- 初始免费
		icon = "rbxassetid://0",
	},
	{
		id = "Illusionist",
		name = "幻术师",
		team = "Hider",
		type = "干扰型",
		baseStats = {
			walkSpeed = 16,
			skillEffect = 1.2, -- 技能效果+20%
			illusionDuration = 1.3, -- 幻象持续+30%
		},
		skills = {
			[1] = {
				name = "幻影分身",
				description = "创建1个假身",
				cooldown = 25,
				cloneCount = 1,
			},
			[5] = {
				name = "干扰爆炸",
				description = "闪光+巨响干扰",
				cooldown = 30,
			},
			[10] = {
				name = "三重幻影",
				description = "同时3个分身",
				passive = true,
				maxClones = 3,
			},
			[15] = {
				name = "移动分身",
				description = "分身可自主移动",
				passive = true,
			},
			[20] = {
				name = "全息投影",
				description = "大范围幻影群干扰",
				cooldown = 60,
			},
		},
		price = 5000,
		icon = "rbxassetid://0",
	},
	{
		id = "Shadow",
		name = "忍者",
		team = "Hider",
		type = "潜行型",
		baseStats = {
			walkSpeed = 17.6, -- 110%
			footstepVolume = 0.5, -- 脚步声-50%
		},
		skills = {
			[1] = {
				name = "短暂隐身",
				description = "隐身2秒",
				cooldown = 30,
				duration = 2,
			},
			[5] = {
				name = "疾风步",
				description = "移速+30%持续3秒",
				cooldown = 20,
				speedBonus = 0.3,
				duration = 3,
			},
			[10] = {
				name = "攀爬",
				description = "可攀爬墙面",
				passive = true,
			},
			[15] = {
				name = "长效隐身",
				description = "隐身时间延长至5秒",
				passive = true,
				invisDuration = 5,
			},
			[20] = {
				name = "烟雾消失",
				description = "范围隐身逃脱",
				limited = 1,
			},
		},
		price = 5000,
		icon = "rbxassetid://0",
	},
	{
		id = "Trickster",
		name = "小丑",
		team = "Hider",
		type = "搞怪型",
		baseStats = {
			walkSpeed = 16,
			itemCapacity = 2, -- 道具容量+1
			itemEffect = 1.25, -- 道具效果+25%
		},
		skills = {
			[1] = {
				name = "噪音器",
				description = "制造假音源",
				cooldown = 15,
			},
			[5] = {
				name = "假道具",
				description = "放置爆炸假道具",
				cooldown = 20,
			},
			[10] = {
				name = "笑气弹",
				description = "减速找寻者30%",
				cooldown = 35,
				slowAmount = 0.3,
			},
			[15] = {
				name = "道具大师",
				description = "道具携带+1",
				passive = true,
				extraSlot = 1,
			},
			[20] = {
				name = "终极恶作剧",
				description = "全体找寻者混乱3秒",
				limited = 1,
				duration = 3,
			},
		},
		price = 5000,
		icon = "rbxassetid://0",
	},
	{
		id = "Healer",
		name = "医者",
		team = "Hider",
		type = "辅助型",
		baseStats = {
			walkSpeed = 16,
			hpRegen = 1.5, -- HP恢复速度+50%
			reviveSpeed = 1.3, -- 复活速度+30%
		},
		skills = {
			[1] = {
				name = "自愈",
				description = "恢复20HP",
				cooldown = 20,
				healAmount = 20,
			},
			[5] = {
				name = "治疗光环",
				description = "5米内队友回血",
				passive = true,
				range = 5,
			},
			[10] = {
				name = "复活折扣",
				description = "复活道具价格-30%",
				passive = true,
				discount = 0.3,
			},
			[15] = {
				name = "群体治疗",
				description = "全体躲藏者回20HP",
				cooldown = 60,
				healAmount = 20,
			},
			[20] = {
				name = "不死之身",
				description = "致命伤触发无敌3秒",
				limited = 1,
				invulnDuration = 3,
			},
		},
		price = 5000,
		icon = "rbxassetid://0",
	},
	{
		id = "Runner",
		name = "逃亡者",
		team = "Hider",
		type = "极限生存",
		baseStats = {
			walkSpeed = 18.4, -- 115%
			stamina = 140, -- 耐力+40%
		},
		skills = {
			[1] = {
				name = "冲刺",
				description = "速度+40%持续2秒",
				cooldown = 15,
				speedBonus = 0.4,
				duration = 2,
			},
			[5] = {
				name = "高跳",
				description = "跳跃高度+100%",
				cooldown = 10,
				jumpBonus = 1.0,
			},
			[10] = {
				name = "翻滚",
				description = "快速翻滚躲避",
				cooldown = 8,
			},
			[15] = {
				name = "耐力强化",
				description = "所有技能CD-30%",
				passive = true,
				cdReduction = 0.3,
			},
			[20] = {
				name = "疾风模式",
				description = "速度+100%持续3秒",
				limited = 1,
				speedBonus = 1.0,
				duration = 3,
			},
		},
		price = 5000,
		icon = "rbxassetid://0",
	},
}

return Characters