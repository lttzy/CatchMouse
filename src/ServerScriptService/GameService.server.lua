--!strict
--[=[
	@class GameService
	游戏服务主入口
	负责初始化和管理所有游戏管理器
]=]

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- 引入服务定位器和通信模块
local ManagerService = require(ServerStorage.ManagerService)
local Communication = require(ReplicatedStorage.Source.CommonFunctions.Communication)

-- 引入游戏管理器
local GameManager = require(ServerStorage.HideAndSeek.GameManager)

-- 获取服务实例
local managerService = ManagerService.GetService()

-- ============ 初始化 ============

local function InitializeManagers()
	print("开始初始化游戏服务...")

	-- 注册GameManager（优先级100，最先初始化）
	local gameManager = GameManager.new()
	managerService:RegisterManager("GameManager", gameManager, 100)

	-- 注意：CharacterManager、ItemManager和SkillManager已经在GameManager内部创建和管理
	-- 这里只需要初始化ManagerService中的所有管理器

	-- 初始化所有Manager
	managerService:InitializeAll()

	print("游戏服务初始化完成")
end

-- ============ 调试命令 ============

local function SetupDebugCommands()
	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			-- 管理员调试命令
			if player.UserId == game.CreatorId or player.Name == "Player1" then -- 测试环境中Player1也是管理员
				if message == "/start" then
					local gameManager = managerService:GetManager("GameManager")
					if gameManager then
						gameManager:StartGame()
						print("管理员启动游戏")
					end
				elseif message == "/end" then
					local gameManager = managerService:GetManager("GameManager")
					if gameManager then
						gameManager:EndGame("Admin")
						print("管理员结束游戏")
					end
				elseif message == "/reset" then
					local gameManager = managerService:GetManager("GameManager")
					if gameManager then
						gameManager:ResetGame()
						print("管理员重置游戏")
					end
				elseif message == "/status" then
					managerService:PrintStatus()
					local gameManager = managerService:GetManager("GameManager")
					if gameManager then
						gameManager:PrintStatus()
					end
				elseif message == "/test" then
					-- 测试功能
					print("测试命令执行")
					local gameManager = managerService:GetManager("GameManager")
					if gameManager then
						-- 强制开始游戏（跳过人数检查）
						gameManager.gameState = "Waiting"
						gameManager:StartGame()
					end
				end
			end
		end)
	end)
end

-- ============ 启动游戏服务 ============

-- 初始化通信系统
Communication.Initialize()

-- 初始化所有管理器
InitializeManagers()

-- 设置调试命令
SetupDebugCommands()

-- 通知客户端游戏服务已就绪
task.wait(1)
Communication.FireAllClients("GameServiceReady")

print("===========================================")
print("   躲猫猫游戏服务器启动成功！")
print("   使用 /start 开始游戏")
print("   使用 /status 查看状态")
print("===========================================")