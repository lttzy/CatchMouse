--!strict
--[=[
	@class ManagerService
	服务端Manager服务定位器
	提供统一的Manager访问接口和数据获取方法
]=]

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Source.CommonFunctions.Signal)

local ManagerService = {}
ManagerService.__index = ManagerService

-- 单例模式
local instance = nil

-- Manager注册表
local managers = {}
local managerInitOrder = {} -- 初始化顺序

-- 信号缓存
local signals = {}

-- 事件
local ManagerRegistered = Signal.new()
local ManagerUnregistered = Signal.new()
local AllManagersReady = Signal.new()

-- ============ 单例获取 ============

function ManagerService.GetService()
	if not instance then
		instance = ManagerService.new()
	end
	return instance
end

function ManagerService.new()
	local self = setmetatable({}, ManagerService)
	
	self.managers = managers
	self.isReady = false
	self.ManagerRegistered = ManagerRegistered
	self.ManagerUnregistered = ManagerUnregistered
	self.AllManagersReady = AllManagersReady
	
	return self
end

-- ============ Manager注册与管理 ============

function ManagerService:RegisterManager(name: string, manager: any, priority: number?)
	if managers[name] then
		warn("ManagerService: Manager '" .. name .. "' 已经注册")
		return false
	end
	
	managers[name] = {
		instance = manager,
		priority = priority or 50,
		initialized = false,
	}
	
	-- 按优先级排序
	table.insert(managerInitOrder, name)
	table.sort(managerInitOrder, function(a, b)
		return managers[a].priority > managers[b].priority
	end)
	
	ManagerRegistered:Fire(name, manager)
	print("ManagerService: 注册Manager '" .. name .. "'")
	return true
end

function ManagerService:UnregisterManager(name: string)
	local managerData = managers[name]
	if not managerData then
		return false
	end
	
	-- 销毁Manager
	if managerData.instance and managerData.instance.Destroy then
		managerData.instance:Destroy()
	end
	
	managers[name] = nil
	
	-- 从初始化顺序中移除
	local index = table.find(managerInitOrder, name)
	if index then
		table.remove(managerInitOrder, index)
	end
	
	ManagerUnregistered:Fire(name)
	print("ManagerService: 注销Manager '" .. name .. "'")
	return true
end

-- ============ Manager访问 ============

function ManagerService:GetManager(name: string)
	local managerData = managers[name]
	if managerData then
		return managerData.instance
	end
	warn("ManagerService: Manager '" .. name .. "' 未找到")
	return nil
end

function ManagerService:GetManagers(): {[string]: any}
	local result = {}
	for name, data in pairs(managers) do
		result[name] = data.instance
	end
	return result
end

function ManagerService:IsManagerRegistered(name: string): boolean
	return managers[name] ~= nil
end

function ManagerService:WaitForManager(name: string, timeout: number?): any?
	local timeoutValue = timeout or 10
	local startTime = tick()
	
	while not managers[name] do
		if tick() - startTime > timeoutValue then
			warn("ManagerService: 等待Manager '" .. name .. "' 超时")
			return nil
		end
		task.wait(0.1)
	end
	
	return managers[name].instance
end

-- ============ 初始化管理 ============

function ManagerService:InitializeAll()
	if self.isReady then
		warn("ManagerService: 所有Manager已经初始化")
		return
	end
	
	print("ManagerService: 开始初始化所有Manager...")
	
	for _, name in ipairs(managerInitOrder) do
		local managerData = managers[name]
		if managerData and not managerData.initialized then
			local manager = managerData.instance
			
			-- 调用Initialize方法
			if manager.Initialize then
				local success, err = pcall(function()
					manager:Initialize()
				end)
				
				if success then
					managerData.initialized = true
					print("ManagerService: Manager '" .. name .. "' 初始化成功")
				else
					warn("ManagerService: Manager '" .. name .. "' 初始化失败: " .. tostring(err))
				end
			else
				managerData.initialized = true
			end
		end
	end
	
	-- 启动所有Manager
	for _, name in ipairs(managerInitOrder) do
		local managerData = managers[name]
		if managerData and managerData.initialized then
			local manager = managerData.instance
			
			if manager.Start then
				local success, err = pcall(function()
					manager:Start()
				end)
				
				if not success then
					warn("ManagerService: Manager '" .. name .. "' 启动失败: " .. tostring(err))
				end
			end
		end
	end
	
	self.isReady = true
	AllManagersReady:Fire()
	print("ManagerService: 所有Manager初始化完成")
end

-- ============ 数据访问接口 ============

-- 通用数据获取方法
function ManagerService:GetData(managerName: string, dataPath: string): any?
	local manager = self:GetManager(managerName)
	if not manager then
		return nil
	end
	
	-- 支持点号路径访问，如 "GameManager.teams.Seekers"
	local keys = string.split(dataPath, ".")
	local current = manager
	
	for _, key in ipairs(keys) do
		if type(current) == "table" then
			current = current[key]
		else
			return nil
		end
	end
	
	return current
end

-- 调用Manager方法
function ManagerService:CallMethod(managerName: string, methodName: string, ...: any): any?
	local manager = self:GetManager(managerName)
	if not manager then
		return nil
	end
	
	local method = manager[methodName]
	if type(method) == "function" then
		return method(manager, ...)
	else
		warn("ManagerService: 方法 '" .. methodName .. "' 在Manager '" .. managerName .. "' 中未找到")
		return nil
	end
end

-- ============ 特定Manager的快捷访问 ============

-- 游戏管理器快捷访问
function ManagerService:GetGameState(): string?
	return self:CallMethod("GameManager", "GetGameState")
end

function ManagerService:GetGameTime(): number?
	return self:CallMethod("GameManager", "GetTimeRemaining")
end

function ManagerService:GetPlayerTeam(player: Player): string?
	return self:CallMethod("GameManager", "GetPlayerTeam", player)
end

-- 玩家数据管理器快捷访问
function ManagerService:GetPlayerData(player: Player, key: string?): any?
	local manager = self:GetManager("PlayerDataManager")
	if manager and manager.GetPlayerData then
		return manager:GetPlayerData(player, key)
	end
	return nil
end

function ManagerService:SetPlayerData(player: Player, key: string, value: any)
	local manager = self:GetManager("PlayerDataManager")
	if manager and manager.SetPlayerData then
		manager:SetPlayerData(player, key, value)
	end
end

-- ============ 信号管理 ============

function ManagerService:GetSignal(signalName: string)
	if not signals[signalName] then
		signals[signalName] = Signal.new()
		self:_log("创建信号: " .. signalName)
	end
	return signals[signalName]
end

function ManagerService:DestroySignal(signalName: string)
	local signal = signals[signalName]
	if signal then
		signal:Destroy()
		signals[signalName] = nil
		self:_log("销毁信号: " .. signalName)
	end
end

-- ============ 配置管理 ============

local dataTypeToClassName = {
	["string"] = "StringValue",
	["number"] = "NumberValue",
	["boolean"] = "BoolValue"
}

function ManagerService:SetConfiguration(configurationName: string, properties: {[string]: any})
	local Configurations = ReplicatedStorage:FindFirstChild("Configurations")
	if not Configurations then
		Configurations = Instance.new("Folder")
		Configurations.Name = "Configurations"
		Configurations.Parent = ReplicatedStorage
	end

	local configuration = Configurations:FindFirstChild(configurationName)
	if not configuration then
		configuration = Instance.new("Configuration")
		configuration.Name = configurationName
		configuration.Parent = Configurations
	end

	for key, value in pairs(properties) do
		local existingValue = configuration:FindFirstChild(key)
		if not existingValue then
			local className = dataTypeToClassName[typeof(value)]
			if className then
				local valueObj = Instance.new(className)
				valueObj.Name = key
				valueObj.Value = value
				valueObj.Parent = configuration
				self:_log("创建配置值: " .. configurationName .. "." .. key .. " = " .. tostring(value))
			else
				warn("ManagerService: 不支持的配置值类型: " .. typeof(value))
			end
		else
			existingValue.Value = value
			self:_log("更新配置值: " .. configurationName .. "." .. key .. " = " .. tostring(value))
		end
	end
end

function ManagerService:GetConfiguration(configurationName: string): {[string]: any}
	local Configurations = ReplicatedStorage:FindFirstChild("Configurations")
	if not Configurations then
		return {}
	end

	local configuration = Configurations:FindFirstChild(configurationName)
	if not configuration then
		return {}
	end

	local properties = {}
	for _, valueObj in configuration:GetChildren() do
		if valueObj:IsA("ValueBase") then
			properties[valueObj.Name] = valueObj.Value
		end
	end

	return properties
end

-- ============ 批量操作 ============

function ManagerService:StopAll()
	for _, name in ipairs(managerInitOrder) do
		local managerData = managers[name]
		if managerData and managerData.instance.Stop then
			managerData.instance:Stop()
		end
	end
end

function ManagerService:DestroyAll()
	-- 反向顺序销毁
	for i = #managerInitOrder, 1, -1 do
		local name = managerInitOrder[i]
		self:UnregisterManager(name)
	end

	-- 清理信号
	for signalName, signal in pairs(signals) do
		signal:Destroy()
	end
	signals = {}

	managers = {}
	managerInitOrder = {}
	self.isReady = false
end

-- ============ 调试功能 ============

function ManagerService:_log(message: string)
	-- 可以根据需要启用详细日志
	-- print(string.format("[ManagerService]: %s", message))
end

function ManagerService:GetDebugInfo(): {[string]: any}
	local info = {
		isReady = self.isReady,
		managerCount = #managerInitOrder,
		managers = {}
	}
	
	for name, data in pairs(managers) do
		info.managers[name] = {
			initialized = data.initialized,
			priority = data.priority,
			hasInstance = data.instance ~= nil
		}
	end
	
	return info
end

function ManagerService:PrintStatus()
	print("========== ManagerService Status ==========")
	print("Ready:", self.isReady)
	print("Registered Managers:", #managerInitOrder)
	
	for _, name in ipairs(managerInitOrder) do
		local data = managers[name]
		if data then
			print(string.format("  - %s (Priority: %d, Initialized: %s)", 
				name, data.priority, tostring(data.initialized)))
		end
	end
	
	print("==========================================")
end

return ManagerService