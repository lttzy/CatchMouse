--!strict
--[=[
	@class ClientMain
	客户端主入口
	展示如何使用ControllerService和Communication模块
]=]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- 引入模块
local ControllerService = require(ReplicatedStorage.ControllerService)
local Communication = require(ReplicatedStorage.Source.CommonFunctions.Communication)
local BaseController = require(ReplicatedStorage.Source.CommonFunctions.BaseController)

-- 获取服务实例
local controllerService = ControllerService.GetService()
local localPlayer = Players.LocalPlayer

-- ============ 创建示例Controller ============

-- 游戏UI控制器
local GameUIController = BaseController.extend("GameUIController")

function GameUIController:OnInitialize()
	-- 监听服务器事件
	self:OnServerEvent("GameStarted", function()
		print("客户端: 游戏开始")
		self:UpdateUI("GameStarted")
	end)
	
	self:OnServerEvent("GameEnded", function(winningTeam)
		print("客户端: 游戏结束，获胜方:", winningTeam)
		self:UpdateUI("GameEnded", winningTeam)
	end)
	
	-- 监听玩家位置更新（不可靠事件，用于高频更新）
	self:OnUnreliableServerEvent("UpdatePlayerPosition", function(player, position, rotation)
		if player ~= localPlayer then
			-- 更新其他玩家的位置
			self:UpdateOtherPlayerPosition(player, position, rotation)
		end
	end)
end

function GameUIController:UpdateUI(state, data)
	-- TODO: 更新UI显示
	print("更新UI:", state, data)
end

function GameUIController:UpdateOtherPlayerPosition(player, position, rotation)
	-- TODO: 更新其他玩家位置
end

-- 输入控制器
local InputController = BaseController.extend("InputController")

function InputController:OnInitialize()
	-- 设置输入监听
	self:SetupInputs()
end

function InputController:SetupInputs()
	-- 技能使用
	self:Connect("SkillInput", game:GetService("UserInputService").InputBegan, function(input, gameProcessed)
		if gameProcessed then return end
		
		if input.KeyCode == Enum.KeyCode.Q then
			self:UseSkill(1)
		elseif input.KeyCode == Enum.KeyCode.E then
			self:UseSkill(2)
		end
	end)
end

function InputController:UseSkill(skillId: number)
	-- 发送技能使用请求到服务器
	Communication.FireServer("PlayerAction", "UseSkill", {skillId = skillId})
	print("使用技能:", skillId)
end

-- ============ 与服务器通信示例 ============

local function GetGameInfo()
	-- 使用Communication模块调用服务器函数
	local gameState = Communication.InvokeServer("GetManagerData", "GetGameState")
	local playerTeam = Communication.InvokeServer("GetManagerData", "GetPlayerTeam")
	local gameTime = Communication.InvokeServer("GetManagerData", "GetGameTime")
	
	print("游戏信息:")
	print("  状态:", gameState)
	print("  我的队伍:", playerTeam)
	print("  剩余时间:", gameTime)
	
	return {
		state = gameState,
		team = playerTeam,
		timeLeft = gameTime
	}
end

local function SendPlayerMovement()
	-- 发送玩家移动数据（使用不可靠事件以减少延迟）
	RunService.Heartbeat:Connect(function()
		local character = localPlayer.Character
		if character and character:FindFirstChild("HumanoidRootPart") then
			local rootPart = character.HumanoidRootPart
			local position = rootPart.Position
			local rotation = rootPart.CFrame.LookVector
			
			-- 使用不可靠事件发送高频更新
			Communication.UnreliableFireServer("PlayerMovement", position, rotation)
		end
	end)
end

-- ============ 初始化Controllers ============

local function InitializeControllers()
	-- 注册Controllers（按优先级）
	controllerService:RegisterController("GameUIController", GameUIController.new(), 100)
	controllerService:RegisterController("InputController", InputController.new(), 90)
	
	-- 可以继续添加其他Controllers
	-- controllerService:RegisterController("CameraController", CameraController.new(), 80)
	-- controllerService:RegisterController("CharacterController", CharacterController.new(), 70)
	
	-- 初始化所有Controllers
	controllerService:InitializeAll()
	
	print("客户端Controllers初始化完成")
end

-- ============ 设置通信监听 ============

local function SetupCommunicationListeners()
	-- 监听游戏状态变化
	Communication.OnClientEvent("StateChanged", function(newState, oldState)
		print("游戏状态变化:", oldState, "->", newState)
		
		-- 广播给所有Controllers
		controllerService:BroadcastEvent("GameStateChanged", newState, oldState)
	end)
	
	-- 监听团队分配
	Communication.OnClientEvent("TeamAssigned", function(team)
		print("被分配到团队:", team)
		
		-- 更新本地显示
		local uiController = controllerService:GetController("GameUIController")
		if uiController then
			uiController:UpdateUI("TeamAssigned", team)
		end
	end)
	
	-- 监听玩家淘汰
	Communication.OnClientEvent("PlayerEliminated", function(eliminatedPlayer)
		print("玩家被淘汰:", eliminatedPlayer.Name)
		
		if eliminatedPlayer == localPlayer then
			-- 切换到观察者模式
			controllerService:CallMethod("CameraController", "SetMode", "Spectator")
		end
	end)
end

-- ============ 调试功能 ============

local function SetupDebugCommands()
	if RunService:IsStudio() then
		-- 调试快捷键
		game:GetService("UserInputService").InputBegan:Connect(function(input)
			if input.KeyCode == Enum.KeyCode.F1 then
				-- 打印Controller状态
				controllerService:PrintStatus()
				
			elseif input.KeyCode == Enum.KeyCode.F2 then
				-- 获取游戏信息
				GetGameInfo()
				
			elseif input.KeyCode == Enum.KeyCode.F3 then
				-- 获取调试信息
				local debugInfo = controllerService:GetDebugInfo()
				print("Controller调试信息:", debugInfo)
			end
		end)
	end
end

-- ============ 主循环 ============

local function StartClientLoop()
	-- 客户端更新循环
	RunService.RenderStepped:Connect(function(deltaTime)
		-- Controllers的更新已在内部处理
		-- 这里可以处理其他客户端逻辑
	end)
	
	-- 开始发送玩家移动数据
	SendPlayerMovement()
end

-- ============ 启动 ============

local function Start()
	print("客户端启动中...")
	
	-- 等待角色加载
	local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
	
	-- 初始化Controllers
	InitializeControllers()
	
	-- 设置通信监听
	SetupCommunicationListeners()
	
	-- 设置调试命令
	SetupDebugCommands()
	
	-- 启动客户端循环
	StartClientLoop()
	
	-- 获取初始游戏信息
	task.wait(1)
	GetGameInfo()
	
	print("客户端启动完成")
end

-- 启动客户端
Start()

-- ============ 角色重生处理 ============

localPlayer.CharacterAdded:Connect(function(character)
	print("角色重生")
	
	-- 通知所有Controllers角色重生
	controllerService:BroadcastEvent("CharacterSpawned", character)
end)

localPlayer.CharacterRemoving:Connect(function(character)
	print("角色移除")
	
	-- 通知所有Controllers角色移除
	controllerService:BroadcastEvent("CharacterRemoving", character)
end)