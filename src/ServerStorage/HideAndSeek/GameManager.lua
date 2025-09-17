--!strict
--[=[
	@class GameManager
	躲猫猫游戏主管理器
	继承自BaseManager，负责游戏流程控制
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local RunService = game:GetService("RunService")

local BaseManager = require(ReplicatedStorage.Source.CommonFunctions.BaseManager)
local GameConfig = require(ReplicatedStorage.Source.HideAndSeek.Config.GameConfig)
local Signal = require(ReplicatedStorage.Source.CommonFunctions.Signal)
local TableUtil = require(ReplicatedStorage.Source.CommonFunctions.TableUtil)
local Communication = require(ReplicatedStorage.Source.CommonFunctions.Communication)

-- 继承BaseManager
local GameManager = BaseManager.extend("HideAndSeekGameManager")

-- 游戏状态枚举
GameManager.GameState = {
	WAITING = "Waiting",
	STARTING = "Starting",
	PREPARING = "Preparing",
	IN_PROGRESS = "InProgress",
	ENDING = "Ending",
}

-- 构造函数
function GameManager:Constructor()
	-- 游戏状态
	self.gameState = GameManager.GameState.WAITING
	self.gameTimer = 0
	self.prepareTimer = 0
	self.winningTeam = nil
	self.roundNumber = 0

	-- 玩家管理
	self.players = {}
	self.teams = {
		Seekers = {},
		Hiders = {},
	}
	self.eliminatedPlayers = {} -- 已淘汰玩家

	-- 子模块引用
	self.characterManager = nil
	self.itemManager = nil
	self.skillManager = nil
	
	-- 额外的信号
	self.GameStarted = Signal.new()
	self.GameEnded = Signal.new()
	self.PlayerEliminated = Signal.new()
	self.TeamAssigned = Signal.new()
	
	-- 启用调试模式
	self:SetDebug(true)
	
	-- 创建团队
	self:_createTeams()
end

-- ============ 重写基类方法 ============

function GameManager:OnInitialize()
	-- 注册子模块
	local CharacterManager = require(ServerStorage.HideAndSeek.CharacterManager)
	local ItemManager = require(ServerStorage.HideAndSeek.ItemManager)
	local SkillManager = require(ServerStorage.HideAndSeek.SkillManager)

	self.characterManager = CharacterManager.new()
	self.itemManager = ItemManager.new()
	self.skillManager = SkillManager.new()

	self:RegisterModule("CharacterManager", self.characterManager)
	self:RegisterModule("ItemManager", self.itemManager)
	self:RegisterModule("SkillManager", self.skillManager)

	-- 初始化子模块
	self.characterManager:Initialize()
	self.itemManager:Initialize()
	self.skillManager:Initialize()

	-- 监听玩家加入/离开
	self.Maid:GiveTask(Players.PlayerAdded:Connect(function(player)
		self:AddPlayer(player)
	end))

	self.Maid:GiveTask(Players.PlayerRemoving:Connect(function(player)
		self:RemovePlayer(player)
	end))

	-- 监听玩家死亡
	self.Maid:GiveTask(Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			local humanoid = character:WaitForChild("Humanoid")
			humanoid.Died:Connect(function()
				self:OnPlayerDied(player)
			end)
		end)
	end))

	-- 设置更新循环
	self.Maid:GiveTask(RunService.Heartbeat:Connect(function(dt)
		self:OnUpdate(dt)
	end))

	-- 注册通信事件
	self:RegisterCommunication()

	self:_log("游戏管理器初始化完成")
end

function GameManager:OnStart()
	self:_log("游戏管理器启动")

	-- 启动子模块
	self.characterManager:Start()
	self.itemManager:Start()
	self.skillManager:Start()

	self.gameState = GameManager.GameState.WAITING

	-- 检查已在游戏中的玩家
	for _, player in ipairs(Players:GetPlayers()) do
		self:AddPlayer(player)
	end
end

function GameManager:OnStop()
	self:_log("游戏管理器停止")
	self:ResetGame()
end

function GameManager:OnDestroy()
	-- 清理团队
	if Teams:FindFirstChild("Seekers") then
		Teams.Seekers:Destroy()
	end
	if Teams:FindFirstChild("Hiders") then
		Teams.Hiders:Destroy()
	end
	
	-- 清理信号
	self.GameStarted:Destroy()
	self.GameEnded:Destroy()
	self.PlayerEliminated:Destroy()
	self.TeamAssigned:Destroy()
end

function GameManager:OnUpdate(deltaTime: number)
	-- 根据当前状态更新游戏
	if self.gameState == GameManager.GameState.WAITING then
		self:_updateWaiting(deltaTime)
	elseif self.gameState == GameManager.GameState.STARTING then
		self:_updateStarting(deltaTime)
	elseif self.gameState == GameManager.GameState.PREPARING then
		self:_updatePreparing(deltaTime)
	elseif self.gameState == GameManager.GameState.IN_PROGRESS then
		self:_updateInProgress(deltaTime)
	elseif self.gameState == GameManager.GameState.ENDING then
		self:_updateEnding(deltaTime)
	end
end

-- ============ 状态更新方法 ============

function GameManager:_updateWaiting(dt: number)
	-- 检查是否满足开始条件
	if #self.players >= GameConfig.GameSettings.MinPlayers then
		self:StartGame()
	end
end

function GameManager:_updateStarting(dt: number)
	self.prepareTimer -= dt
	if self.prepareTimer <= 0 then
		self:_setState(GameManager.GameState.PREPARING)
		self:_spawnHiders()
		self.prepareTimer = GameConfig.GameSettings.PrepareTime
	end
end

function GameManager:_updatePreparing(dt: number)
	self.prepareTimer -= dt
	if self.prepareTimer <= 0 then
		self:_setState(GameManager.GameState.IN_PROGRESS)
		self:_spawnSeekers()
		self.gameTimer = GameConfig.GameSettings.GameDuration
	end
end

function GameManager:_updateInProgress(dt: number)
	self.gameTimer -= dt
	
	-- 检查胜利条件
	if self:CheckVictoryConditions() then
		self:EndGame(self.winningTeam)
	elseif self.gameTimer <= 0 then
		-- 时间结束，躲藏者获胜
		self:EndGame("Hiders")
	end
end

function GameManager:_updateEnding(dt: number)
	self.prepareTimer -= dt
	if self.prepareTimer <= 0 then
		self:ResetGame()
		self:_setState(GameManager.GameState.WAITING)
	end
end

-- ============ 游戏控制方法 ============

function GameManager:StartGame()
	if self.gameState ~= GameManager.GameState.WAITING then
		return
	end

	self:_log("游戏开始")
	self.roundNumber = self.roundNumber + 1
	self.eliminatedPlayers = {}
	self:_setState(GameManager.GameState.STARTING)
	self:AssignTeams()
	self.prepareTimer = GameConfig.GameSettings.LobbyWaitTime

	-- 通知所有玩家
	Communication.FireAllClients("GameStarted", {
		roundNumber = self.roundNumber,
		teams = {
			Seekers = self.teams.Seekers,
			Hiders = self.teams.Hiders
		}
	})

	self.GameStarted:Fire()
end

function GameManager:EndGame(winningTeam: string)
	self:_log("游戏结束，获胜方: " .. winningTeam)
	self.winningTeam = winningTeam
	self:_setState(GameManager.GameState.ENDING)
	self:CalculateRewards()
	self.prepareTimer = GameConfig.GameSettings.ResultTime
	self.GameEnded:Fire(winningTeam)
end

function GameManager:ResetGame()
	self:_log("重置游戏")

	-- 重置状态
	self.gameTimer = 0
	self.prepareTimer = 0
	self.winningTeam = nil
	self.eliminatedPlayers = {}

	-- 清空团队
	self.teams.Seekers = {}
	self.teams.Hiders = {}

	-- 重置所有玩家
	for _, player in ipairs(self.players) do
		player.Team = nil
		if player.Character then
			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.Health = humanoid.MaxHealth
			end
		end
		-- TODO: 传送回大厅
	end

	-- 清理道具
	self.itemManager:ClearAllItems()

	-- 重置技能使用次数
	for _, player in ipairs(self.players) do
		self.skillManager:ResetSkillUses(player)
	end

	-- 通知客户端
	Communication.FireAllClients("GameReset")
end

-- ============ 团队管理 ============

function GameManager:_createTeams()
	-- 创建找寻者团队
	if not Teams:FindFirstChild("Seekers") then
		local seekerTeam = Instance.new("Team")
		seekerTeam.Name = "Seekers"
		seekerTeam.TeamColor = BrickColor.new(GameConfig.TeamSettings.Teams.Seekers.Color)
		seekerTeam.Parent = Teams
	end
	
	-- 创建躲藏者团队  
	if not Teams:FindFirstChild("Hiders") then
		local hiderTeam = Instance.new("Team")
		hiderTeam.Name = "Hiders"
		hiderTeam.TeamColor = BrickColor.new(GameConfig.TeamSettings.Teams.Hiders.Color)
		hiderTeam.Parent = Teams
	end
end

function GameManager:AssignTeams()
	local allPlayers = TableUtil.Copy(self.players)
	TableUtil.Shuffle(allPlayers)
	
	local totalPlayers = #allPlayers
	local numHiders = math.floor(totalPlayers * GameConfig.TeamSettings.HiderRatio)
	
	-- 清空团队
	self.teams.Hiders = {}
	self.teams.Seekers = {}
	
	-- 分配躲藏者
	for i = 1, numHiders do
		local player = allPlayers[i]
		if player then
			table.insert(self.teams.Hiders, player)
			player.Team = Teams.Hiders
			self.TeamAssigned:Fire(player, "Hiders")
		end
	end
	
	-- 分配找寻者
	for i = numHiders + 1, totalPlayers do
		local player = allPlayers[i]
		if player then
			table.insert(self.teams.Seekers, player)
			player.Team = Teams.Seekers
			self.TeamAssigned:Fire(player, "Seekers")
		end
	end
	
	self:_log(string.format("团队分配完成 - 躲藏者: %d, 找寻者: %d", 
		#self.teams.Hiders, #self.teams.Seekers))
end

-- ============ 玩家管理 ============

function GameManager:AddPlayer(player: Player)
	if not table.find(self.players, player) then
		table.insert(self.players, player)
		self:_log("玩家加入: " .. player.Name)
		
		-- 如果游戏正在进行，将玩家设为观察者
		if self.gameState == GameManager.GameState.IN_PROGRESS then
			-- TODO: 设置为观察者模式
		end
	end
end

function GameManager:RemovePlayer(player: Player)
	local index = table.find(self.players, player)
	if index then
		table.remove(self.players, index)
		self:_log("玩家离开: " .. player.Name)
	end
	
	-- 从团队中移除
	local hiderIndex = table.find(self.teams.Hiders, player)
	if hiderIndex then
		table.remove(self.teams.Hiders, hiderIndex)
	end
	
	local seekerIndex = table.find(self.teams.Seekers, player)
	if seekerIndex then
		table.remove(self.teams.Seekers, seekerIndex)
	end
	
	-- 检查游戏是否需要结束
	if self.gameState == GameManager.GameState.IN_PROGRESS then
		if #self.players < 2 then
			self:EndGame("Draw")
		end
	end
end

-- ============ 玩家死亡处理 ============

function GameManager:OnPlayerDied(player: Player)
	if self.gameState ~= GameManager.GameState.IN_PROGRESS then
		return
	end

	local team = self:GetPlayerTeam(player)
	if team == "Hiders" then
		-- 躲藏者被淘汰
		table.insert(self.eliminatedPlayers, player)
		self.PlayerEliminated:Fire(player)

		-- 通知所有玩家
		Communication.FireAllClients("PlayerEliminated", player, team)

		-- 检查胜利条件
		if self:CheckVictoryConditions() then
			self:EndGame(self.winningTeam)
		end
	elseif team == "Seekers" then
		-- 找寻者死亡（通常不会发生）
		task.wait(3) -- 等待重生
		if player.Character then
			local spawnPoint = self:GetSeekerSpawnPoint()
			if spawnPoint then
				player.Character.HumanoidRootPart.CFrame = spawnPoint
			end
		end
	end
end

-- ============ 武器系统 ============

function GameManager:GiveSeekerWeapon(player: Player)
	-- 创建简单的射击工具
	local tool = Instance.new("Tool")
	tool.Name = "SeekerGun"
	tool.RequiresHandle = true

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1, 1, 2)
	handle.Material = Enum.Material.Neon
	handle.BrickColor = BrickColor.new("Really red")
	handle.Parent = tool

	-- 添加射击功能
	local clickConnection
	tool.Activated:Connect(function()
		self:OnSeekerShoot(player)
	end)

	tool.Parent = player.Backpack
end

function GameManager:OnSeekerShoot(shooter: Player)
	local character = shooter.Character
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	-- 创建射线检测
	local rayDirection = (character.Head.CFrame.LookVector * 100)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {character}
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

	local result = workspace:Raycast(humanoidRootPart.Position, rayDirection, raycastParams)

	if result and result.Instance then
		local hitCharacter = result.Instance:FindFirstAncestorOfClass("Model")
		if hitCharacter then
			local hitHumanoid = hitCharacter:FindFirstChildOfClass("Humanoid")
			if hitHumanoid then
				local hitPlayer = Players:GetPlayerFromCharacter(hitCharacter)
				if hitPlayer and self:GetPlayerTeam(hitPlayer) == "Hiders" then
					-- 造成伤害
					hitHumanoid:TakeDamage(GameConfig.BaseStats.Seeker.WeaponDamage)
					Communication.FireClient(hitPlayer, "TookDamage", GameConfig.BaseStats.Seeker.WeaponDamage)
				end
			end
		end
	end

	-- 创建射击特效
	local beam = Instance.new("Part")
	beam.Name = "Beam"
	beam.Size = Vector3.new(0.2, 0.2, rayDirection.Magnitude)
	beam.CFrame = CFrame.lookAt(humanoidRootPart.Position + rayDirection/2, humanoidRootPart.Position + rayDirection)
	beam.Material = Enum.Material.Neon
	beam.BrickColor = BrickColor.new("Really red")
	beam.Anchored = true
	beam.CanCollide = false
	beam.Parent = workspace

	game:GetService("Debris"):AddItem(beam, 0.1)
end

-- ============ 出生点管理 ============

function GameManager:GetHiderSpawnPoint(): CFrame?
	-- TODO: 从地图获取实际出生点
	return CFrame.new(math.random(-20, 20), 5, math.random(-20, 20))
end

function GameManager:GetSeekerSpawnPoint(): CFrame?
	-- TODO: 从地图获取实际出生点
	return CFrame.new(0, 5, 0)
end

-- ============ 生成逻辑 ============

function GameManager:_spawnHiders()
	self:_log("生成躲藏者")
	for _, player in ipairs(self.teams.Hiders) do
		if player.Character then
			-- 应用躲藏者角色能力
			self.characterManager:ApplyCharacterAbilities(player, "Hiders")

			-- 传送到躲藏者出生点
			local spawnPoint = self:GetHiderSpawnPoint()
			if spawnPoint then
				player.Character.HumanoidRootPart.CFrame = spawnPoint
			end

			-- 给予初始道具
			-- self.itemManager:GiveStarterItems(player, "Hiders")
		end
	end

	-- 通知客户端
	Communication.FireAllClients("HidersSpawned")
end

function GameManager:_spawnSeekers()
	self:_log("生成找寻者")
	for _, player in ipairs(self.teams.Seekers) do
		if player.Character then
			-- 应用找寻者角色能力
			self.characterManager:ApplyCharacterAbilities(player, "Seekers")

			-- 传送到找寻者出生点
			local spawnPoint = self:GetSeekerSpawnPoint()
			if spawnPoint then
				player.Character.HumanoidRootPart.CFrame = spawnPoint
			end

			-- 给予找寻者武器
			self:GiveSeekerWeapon(player)
		end
	end

	-- 开始道具生成
	self.itemManager:SpawnRandomItems()

	-- 通知客户端
	Communication.FireAllClients("SeekersReleased")
end

-- ============ 胜利条件 ============

function GameManager:CheckVictoryConditions(): boolean
	-- 检查是否所有躲藏者被淘汰
	local hidersAlive = 0
	for _, player in ipairs(self.teams.Hiders) do
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			local humanoid = player.Character.Humanoid
			if humanoid.Health > 0 then
				hidersAlive += 1
			end
		end
	end
	
	-- 找寻者获胜条件：所有躲藏者被淘汰
	if hidersAlive == 0 and #self.teams.Hiders > 0 then
		self.winningTeam = "Seekers"
		return true
	end
	
	return false
end

-- ============ 奖励系统 ============

function GameManager:CalculateRewards()
	local winningTeam = self.winningTeam == "Seekers" and self.teams.Seekers or self.teams.Hiders
	local losingTeam = self.winningTeam == "Seekers" and self.teams.Hiders or self.teams.Seekers
	
	-- 胜利团队奖励
	for _, player in ipairs(winningTeam) do
		self:_giveReward(player, GameConfig.Economy.BaseRewards.Victory)
	end
	
	-- 失败团队奖励
	for _, player in ipairs(losingTeam) do
		self:_giveReward(player, GameConfig.Economy.BaseRewards.Defeat)
	end
	
	-- TODO: 计算MVP和其他表现奖励
end

function GameManager:_giveReward(player: Player, reward: {Experience: number, Gold: number})
	-- TODO: 调用现有的RewardManager
	self:_log(string.format("给予玩家 %s 奖励: %d金币, %d经验", 
		player.Name, reward.Gold, reward.Experience))
end

-- ============ 工具方法 ============

function GameManager:_setState(state: string)
	local oldState = self.gameState
	self.gameState = state
	self:_log("状态切换: " .. oldState .. " -> " .. state)
	self.StateChanged:Fire(state, oldState)
end

function GameManager:GetGameState(): string
	return self.gameState
end

function GameManager:GetTimeRemaining(): number
	return math.max(0, self.gameTimer)
end

function GameManager:GetPlayerTeam(player: Player): string?
	if table.find(self.teams.Seekers, player) then
		return "Seekers"
	elseif table.find(self.teams.Hiders, player) then
		return "Hiders"
	end
	return nil
end

-- ============ 通信注册 ============

function GameManager:RegisterCommunication()
	-- 客户端请求游戏状态
	Communication.OnServerInvoke("GetGameState", function(player)
		return {
			state = self.gameState,
			timeRemaining = self:GetTimeRemaining(),
			team = self:GetPlayerTeam(player),
			roundNumber = self.roundNumber,
			teams = {
				Seekers = #self.teams.Seekers,
				Hiders = #self.teams.Hiders
			}
		}
	end)

	-- 客户端请求玩家列表
	Communication.OnServerInvoke("GetPlayerList", function(player)
		local playerList = {}
		for _, p in ipairs(self.players) do
			table.insert(playerList, {
				player = p,
				team = self:GetPlayerTeam(p),
				isEliminated = table.find(self.eliminatedPlayers, p) ~= nil
			})
		end
		return playerList
	end)

	-- 管理员命令
	Communication.OnServerEvent("AdminCommand", function(player, command, ...)
		-- TODO: 检查管理员权限
		if command == "StartGame" then
			self:StartGame()
		elseif command == "EndGame" then
			self:EndGame("Admin")
		elseif command == "ResetGame" then
			self:ResetGame()
		end
	end)
end

-- ============ 调试功能 ============

function GameManager:PrintStatus()
	print("========== GameManager Status ==========")
	print(string.format("状态: %s", self.gameState))
	print(string.format("回合: %d", self.roundNumber))
	print(string.format("剩余时间: %.1f秒", self:GetTimeRemaining()))
	print(string.format("玩家数: %d", #self.players))
	print(string.format("找寻者: %d, 躲藏者: %d", #self.teams.Seekers, #self.teams.Hiders))
	print(string.format("已淘汰: %d", #self.eliminatedPlayers))
	print("==========================================")
end

return GameManager