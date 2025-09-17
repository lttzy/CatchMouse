--!strict
--[=[
	@class BaseManager
	通用Manager基类模板
	提供Manager的基础功能和生命周期管理
]=]

local Signal = require(script.Parent.Signal)
local Maid = require(script.Parent.Maid)
local Communication = require(script.Parent.Communication)

local BaseManager = {}
BaseManager.__index = BaseManager

-- Manager状态枚举
BaseManager.State = {
	IDLE = "Idle",
	INITIALIZING = "Initializing",
	RUNNING = "Running",
	PAUSED = "Paused",
	DESTROYING = "Destroying",
}

function BaseManager.new(name: string?)
	local self = setmetatable({}, BaseManager)
	
	-- 基础属性
	self.Name = name or "BaseManager"
	self.State = BaseManager.State.IDLE
	self.Enabled = false
	self.Maid = Maid.new()
	
	-- 事件信号
	self.StateChanged = Signal.new()
	self.Initialized = Signal.new()
	self.Started = Signal.new()
	self.Stopped = Signal.new()
	self.Destroyed = Signal.new()
	
	-- 子模块容器
	self._modules = {}
	self._services = {}
	
	-- 调试模式
	self._debug = false
	
	return self
end

-- ============ 生命周期方法 ============

function BaseManager:Initialize()
	if self.State ~= BaseManager.State.IDLE then
		warn(self.Name .. " 已经初始化或正在运行")
		return
	end
	
	self:_setState(BaseManager.State.INITIALIZING)
	self:_log("正在初始化...")
	
	-- 子类重写此方法进行初始化
	self:OnInitialize()
	
	self:_setState(BaseManager.State.RUNNING)
	self.Enabled = true
	self.Initialized:Fire()
	self:_log("初始化完成")
end

function BaseManager:Start()
	if not self.Enabled then
		self:Initialize()
	end
	
	if self.State ~= BaseManager.State.RUNNING then
		self:_log("无法启动，当前状态: " .. self.State)
		return
	end
	
	self:_log("正在启动...")
	self:OnStart()
	self.Started:Fire()
	self:_log("启动完成")
end

function BaseManager:Stop()
	if self.State ~= BaseManager.State.RUNNING then
		return
	end
	
	self:_setState(BaseManager.State.PAUSED)
	self:_log("正在停止...")
	self:OnStop()
	self.Stopped:Fire()
	self:_log("已停止")
end

function BaseManager:Destroy()
	if self.State == BaseManager.State.DESTROYING then
		return
	end
	
	self:_setState(BaseManager.State.DESTROYING)
	self:_log("正在销毁...")
	
	-- 清理所有模块
	for name, module in pairs(self._modules) do
		if module.Destroy then
			module:Destroy()
		end
	end
	self._modules = {}
	
	-- 子类清理
	self:OnDestroy()
	
	-- 清理事件和连接
	self.Maid:Destroy()
	self.StateChanged:Destroy()
	self.Initialized:Destroy()
	self.Started:Destroy()
	self.Stopped:Destroy()
	
	self.Destroyed:Fire()
	self.Destroyed:Destroy()
	
	self:_log("已销毁")
end

-- ============ 虚方法（子类重写） ============

function BaseManager:OnInitialize()
	-- 子类重写此方法进行初始化
end

function BaseManager:OnStart()
	-- 子类重写此方法进行启动逻辑
end

function BaseManager:OnStop()
	-- 子类重写此方法进行停止逻辑
end

function BaseManager:OnDestroy()
	-- 子类重写此方法进行销毁逻辑
end

function BaseManager:OnUpdate(deltaTime: number)
	-- 子类重写此方法进行更新逻辑
end

-- ============ 模块管理 ============

function BaseManager:RegisterModule(name: string, module: any)
	if self._modules[name] then
		warn(self.Name .. ": 模块 " .. name .. " 已存在")
		return
	end
	
	self._modules[name] = module
	self:_log("注册模块: " .. name)
	
	-- 如果模块有Initialize方法，自动调用
	if module.Initialize and self.State == BaseManager.State.RUNNING then
		module:Initialize()
	end
end

function BaseManager:GetModule(name: string)
	return self._modules[name]
end

function BaseManager:RemoveModule(name: string)
	local module = self._modules[name]
	if module then
		if module.Destroy then
			module:Destroy()
		end
		self._modules[name] = nil
		self:_log("移除模块: " .. name)
	end
end

-- ============ 服务管理 ============

function BaseManager:RegisterService(name: string, service: any)
	self._services[name] = service
	self:_log("注册服务: " .. name)
end

function BaseManager:GetService(name: string)
	return self._services[name]
end

-- ============ 状态管理 ============

function BaseManager:GetState()
	return self.State
end

function BaseManager:IsRunning()
	return self.State == BaseManager.State.RUNNING
end

function BaseManager:SetEnabled(enabled: boolean)
	if enabled and not self.Enabled then
		self:Start()
	elseif not enabled and self.Enabled then
		self:Stop()
	end
end

-- ============ 工具方法 ============

function BaseManager:_setState(state: string)
	local oldState = self.State
	self.State = state
	self.StateChanged:Fire(state, oldState)
end

function BaseManager:_log(message: string)
	if self._debug then
		print(string.format("[%s]: %s", self.Name, message))
	end
end

function BaseManager:SetDebug(enabled: boolean)
	self._debug = enabled
end

-- ============ 静态方法 ============

function BaseManager.extend(className: string?)
	local SubClass = {}
	SubClass.__index = SubClass
	setmetatable(SubClass, BaseManager)
	
	function SubClass.new(...)
		local self = setmetatable(BaseManager.new(className or "SubClass"), SubClass)
		if SubClass.Constructor then
			SubClass.Constructor(self, ...)
		end
		return self
	end
	
	return SubClass
end

-- ============ 通信方法 (使用Communication模块) ============

function BaseManager:FireClient(player: Player, eventName: string, ...: any)
	Communication.FireClient(eventName, player, ...)
end

function BaseManager:FireAllClients(eventName: string, ...: any)
	Communication.FireAllClients(eventName, ...)
end

function BaseManager:OnClientEvent(eventName: string, callback: (player: Player, ...any) -> ())
	Communication.OnServerEvent(eventName, callback)
end

function BaseManager:InvokeClient(player: Player, functionName: string, ...: any)
	return Communication.InvokeClient(functionName, player, ...)
end

function BaseManager:OnClientInvoke(functionName: string, callback: (player: Player, ...any) -> any)
	Communication.OnServerInvoke(functionName, callback)
end

-- 不可靠远程事件（用于高频率更新）
function BaseManager:UnreliableFireClient(player: Player, eventName: string, ...: any)
	Communication.UnreliableFireClient(eventName, player, ...)
end

function BaseManager:UnreliableFireAllClients(eventName: string, ...: any)
	Communication.UnreliableFireAllClients(eventName, ...)
end

function BaseManager:OnUnreliableClientEvent(eventName: string, callback: (player: Player, ...any) -> ())
	Communication.UnreliableOnServerEvent(eventName, callback)
end

-- 内部通信（BindableEvent/Function）
function BaseManager:FireInternal(eventName: string, ...: any)
	Communication.Fire(eventName, ...)
end

function BaseManager:OnInternalEvent(eventName: string, callback: (...any) -> ())
	Communication.Event(eventName, callback)
end

function BaseManager:InvokeInternal(functionName: string, ...: any)
	return Communication.Invoke(functionName, ...)
end

function BaseManager:OnInternalInvoke(functionName: string, callback: (...any) -> any)
	Communication.OnInvoke(functionName, callback)
end

return BaseManager