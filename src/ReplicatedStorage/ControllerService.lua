--!strict
--[=[
	@class ControllerService
	客户端Controller服务定位器
	提供统一的Controller访问接口和数据获取方法
]=]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Source.CommonFunctions.Signal)

local ControllerService = {}
ControllerService.__index = ControllerService

-- 单例模式
local instance = nil

-- Controller注册表
local controllers = {}
local controllerInitOrder = {} -- 初始化顺序

-- 信号缓存
local signals = {}

-- 事件
local ControllerRegistered = Signal.new()
local ControllerUnregistered = Signal.new()
local AllControllersReady = Signal.new()

-- ============ 单例获取 ============

function ControllerService.GetService()
	if not instance then
		instance = ControllerService.new()
	end
	return instance
end

function ControllerService.new()
	local self = setmetatable({}, ControllerService)
	
	self.controllers = controllers
	self.isReady = false
	self.localPlayer = Players.LocalPlayer
	self.ControllerRegistered = ControllerRegistered
	self.ControllerUnregistered = ControllerUnregistered
	self.AllControllersReady = AllControllersReady
	
	return self
end

-- ============ Controller注册与管理 ============

function ControllerService:RegisterController(name: string, controller: any, priority: number?)
	if controllers[name] then
		warn("ControllerService: Controller '" .. name .. "' 已经注册")
		return false
	end
	
	controllers[name] = {
		instance = controller,
		priority = priority or 50,
		initialized = false,
	}
	
	-- 按优先级排序
	table.insert(controllerInitOrder, name)
	table.sort(controllerInitOrder, function(a, b)
		return controllers[a].priority > controllers[b].priority
	end)
	
	ControllerRegistered:Fire(name, controller)
	print("ControllerService: 注册Controller '" .. name .. "'")
	return true
end

function ControllerService:UnregisterController(name: string)
	local controllerData = controllers[name]
	if not controllerData then
		return false
	end
	
	-- 销毁Controller
	if controllerData.instance and controllerData.instance.Destroy then
		controllerData.instance:Destroy()
	end
	
	controllers[name] = nil
	
	-- 从初始化顺序中移除
	local index = table.find(controllerInitOrder, name)
	if index then
		table.remove(controllerInitOrder, index)
	end
	
	ControllerUnregistered:Fire(name)
	print("ControllerService: 注销Controller '" .. name .. "'")
	return true
end

-- ============ Controller访问 ============

function ControllerService:GetController(name: string)
	local controllerData = controllers[name]
	if controllerData then
		return controllerData.instance
	end
	warn("ControllerService: Controller '" .. name .. "' 未找到")
	return nil
end

function ControllerService:GetControllers(): {[string]: any}
	local result = {}
	for name, data in pairs(controllers) do
		result[name] = data.instance
	end
	return result
end

function ControllerService:IsControllerRegistered(name: string): boolean
	return controllers[name] ~= nil
end

function ControllerService:WaitForController(name: string, timeout: number?): any?
	local timeoutValue = timeout or 10
	local startTime = tick()
	
	while not controllers[name] do
		if tick() - startTime > timeoutValue then
			warn("ControllerService: 等待Controller '" .. name .. "' 超时")
			return nil
		end
		task.wait(0.1)
	end
	
	return controllers[name].instance
end

-- ============ 初始化管理 ============

function ControllerService:InitializeAll()
	if self.isReady then
		warn("ControllerService: 所有Controller已经初始化")
		return
	end
	
	print("ControllerService: 开始初始化所有Controller...")
	
	-- 初始化阶段
	for _, name in ipairs(controllerInitOrder) do
		local controllerData = controllers[name]
		if controllerData and not controllerData.initialized then
			local controller = controllerData.instance
			
			if controller.Initialize then
				local success, err = pcall(function()
					controller:Initialize()
				end)
				
				if success then
					controllerData.initialized = true
					print("ControllerService: Controller '" .. name .. "' 初始化成功")
				else
					warn("ControllerService: Controller '" .. name .. "' 初始化失败: " .. tostring(err))
				end
			else
				controllerData.initialized = true
			end
		end
	end
	
	-- 启动阶段
	for _, name in ipairs(controllerInitOrder) do
		local controllerData = controllers[name]
		if controllerData and controllerData.initialized then
			local controller = controllerData.instance
			
			if controller.Start then
				local success, err = pcall(function()
					controller:Start()
				end)
				
				if not success then
					warn("ControllerService: Controller '" .. name .. "' 启动失败: " .. tostring(err))
				end
			end
		end
	end
	
	self.isReady = true
	AllControllersReady:Fire()
	print("ControllerService: 所有Controller初始化完成")
end

-- ============ 数据访问接口 ============

-- 通用数据获取方法
function ControllerService:GetData(controllerName: string, dataPath: string): any?
	local controller = self:GetController(controllerName)
	if not controller then
		return nil
	end
	
	-- 支持点号路径访问
	local keys = string.split(dataPath, ".")
	local current = controller
	
	for _, key in ipairs(keys) do
		if type(current) == "table" then
			current = current[key]
		else
			return nil
		end
	end
	
	return current
end

-- 调用Controller方法
function ControllerService:CallMethod(controllerName: string, methodName: string, ...: any): any?
	local controller = self:GetController(controllerName)
	if not controller then
		return nil
	end
	
	local method = controller[methodName]
	if type(method) == "function" then
		return method(controller, ...)
	else
		warn("ControllerService: 方法 '" .. methodName .. "' 在Controller '" .. controllerName .. "' 中未找到")
		return nil
	end
end

-- ============ 信号管理 ============

function ControllerService:GetSignal(signalName: string)
	if not signals[signalName] then
		signals[signalName] = Signal.new()
		self:_log("创建信号: " .. signalName)
	end
	return signals[signalName]
end

function ControllerService:DestroySignal(signalName: string)
	local signal = signals[signalName]
	if signal then
		signal:Destroy()
		signals[signalName] = nil
		self:_log("销毁信号: " .. signalName)
	end
end

-- ============ 配置管理 ============

function ControllerService:GetConfiguration(configurationName: string): {[string]: any}
	local Configurations = ReplicatedStorage:FindFirstChild("Configurations")
	if not Configurations then
		warn("ControllerService: Configurations文件夹未找到")
		return {}
	end

	local configuration = Configurations:FindFirstChild(configurationName)
	if not configuration then
		warn("ControllerService: 配置 '" .. configurationName .. "' 未找到")
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

function ControllerService:WaitForConfiguration(configurationName: string, timeout: number?): {[string]: any}
	local timeoutValue = timeout or 10
	local startTime = tick()

	local Configurations = ReplicatedStorage:WaitForChild("Configurations", timeoutValue)
	if not Configurations then
		warn("ControllerService: 等待Configurations文件夹超时")
		return {}
	end

	while not Configurations:FindFirstChild(configurationName) do
		if tick() - startTime > timeoutValue then
			warn("ControllerService: 等待配置 '" .. configurationName .. "' 超时")
			return {}
		end
		task.wait(0.1)
	end

	return self:GetConfiguration(configurationName)
end

-- ============ UI Controller快捷访问 ============

function ControllerService:ShowUI(uiName: string)
	local uiController = self:GetController(uiName .. "Controller")
	if uiController and uiController.Show then
		uiController:Show()
	end
end

function ControllerService:HideUI(uiName: string)
	local uiController = self:GetController(uiName .. "Controller")
	if uiController and uiController.Hide then
		uiController:Hide()
	end
end

function ControllerService:ToggleUI(uiName: string)
	local uiController = self:GetController(uiName .. "Controller")
	if uiController and uiController.Toggle then
		uiController:Toggle()
	end
end

function ControllerService:IsUIVisible(uiName: string): boolean
	local uiController = self:GetController(uiName .. "Controller")
	if uiController and uiController.IsVisible then
		return uiController:IsVisible()
	end
	return false
end

-- ============ 输入Controller快捷访问 ============

function ControllerService:GetInputMode(): string?
	return self:CallMethod("InputController", "GetMode")
end

function ControllerService:SetInputMode(mode: string)
	self:CallMethod("InputController", "SetMode", mode)
end

function ControllerService:LockInput(reason: string?)
	self:CallMethod("InputController", "Lock", reason)
end

function ControllerService:UnlockInput(reason: string?)
	self:CallMethod("InputController", "Unlock", reason)
end

-- ============ 相机Controller快捷访问 ============

function ControllerService:GetCameraMode(): string?
	return self:CallMethod("CameraController", "GetMode")
end

function ControllerService:SetCameraMode(mode: string)
	self:CallMethod("CameraController", "SetMode", mode)
end

function ControllerService:ShakeCamera(intensity: number?, duration: number?)
	self:CallMethod("CameraController", "Shake", intensity, duration)
end

-- ============ 批量操作 ============

function ControllerService:EnableAll()
	for _, name in ipairs(controllerInitOrder) do
		local controllerData = controllers[name]
		if controllerData and controllerData.instance.SetEnabled then
			controllerData.instance:SetEnabled(true)
		end
	end
end

function ControllerService:DisableAll()
	for _, name in ipairs(controllerInitOrder) do
		local controllerData = controllers[name]
		if controllerData and controllerData.instance.SetEnabled then
			controllerData.instance:SetEnabled(false)
		end
	end
end

function ControllerService:StopAll()
	for _, name in ipairs(controllerInitOrder) do
		local controllerData = controllers[name]
		if controllerData and controllerData.instance.Stop then
			controllerData.instance:Stop()
		end
	end
end

function ControllerService:DestroyAll()
	-- 反向顺序销毁
	for i = #controllerInitOrder, 1, -1 do
		local name = controllerInitOrder[i]
		self:UnregisterController(name)
	end

	-- 清理信号
	for signalName, signal in pairs(signals) do
		signal:Destroy()
	end
	signals = {}

	controllers = {}
	controllerInitOrder = {}
	self.isReady = false
end

-- ============ 事件广播 ============

function ControllerService:BroadcastEvent(eventName: string, ...: any)
	for _, name in ipairs(controllerInitOrder) do
		local controllerData = controllers[name]
		if controllerData then
			local controller = controllerData.instance
			local handler = controller["On" .. eventName]
			
			if type(handler) == "function" then
				local success, err = pcall(handler, controller, ...)
				if not success then
					warn("ControllerService: 事件处理失败 '" .. eventName .. "' 在 '" .. name .. "': " .. tostring(err))
				end
			end
		end
	end
end

-- ============ 调试功能 ============

function ControllerService:_log(message: string)
	-- 可以根据需要启用详细日志
	-- print(string.format("[ControllerService]: %s", message))
end

function ControllerService:GetDebugInfo(): {[string]: any}
	local info = {
		isReady = self.isReady,
		controllerCount = #controllerInitOrder,
		controllers = {}
	}
	
	for name, data in pairs(controllers) do
		info.controllers[name] = {
			initialized = data.initialized,
			priority = data.priority,
			hasInstance = data.instance ~= nil,
			enabled = data.instance and data.instance.Enabled or false
		}
	end
	
	return info
end

function ControllerService:PrintStatus()
	print("========== ControllerService Status ==========")
	print("Ready:", self.isReady)
	print("Registered Controllers:", #controllerInitOrder)
	
	for _, name in ipairs(controllerInitOrder) do
		local data = controllers[name]
		if data then
			local enabled = data.instance and data.instance.Enabled or false
			print(string.format("  - %s (Priority: %d, Initialized: %s, Enabled: %s)", 
				name, data.priority, tostring(data.initialized), tostring(enabled)))
		end
	end
	
	print("============================================")
end

return ControllerService