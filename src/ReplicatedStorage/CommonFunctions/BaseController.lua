--!strict
--[=[
	@class BaseController
	通用Controller基类模板
	提供客户端控制器的基础功能和生命周期管理
]=]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(script.Parent.Signal)
local Maid = require(script.Parent.Maid)
local Communication = require(script.Parent.Communication)

local BaseController = {}
BaseController.__index = BaseController

-- Controller优先级枚举
BaseController.Priority = {
	LOW = 1,
	NORMAL = 5,
	HIGH = 10,
	CRITICAL = 100,
}

function BaseController.new(name: string?)
	local self = setmetatable({}, BaseController)
	
	-- 基础属性
	self.Name = name or "BaseController"
	self.Player = Players.LocalPlayer
	self.Enabled = false
	self.Priority = BaseController.Priority.NORMAL
	self.Maid = Maid.new()
	
	-- 事件信号
	self.Initialized = Signal.new()
	self.Started = Signal.new()
	self.Stopped = Signal.new()
	self.Destroyed = Signal.new()
	
	-- 组件容器
	self._components = {}
	self._connections = {}
	self._updateConnection = nil
	
	-- 调试模式
	self._debug = false
	
	return self
end

-- ============ 生命周期方法 ============

function BaseController:Initialize()
	if self.Enabled then
		warn(self.Name .. " 已经初始化")
		return
	end
	
	self:_log("正在初始化...")
	
	-- 子类初始化
	self:OnInitialize()
	
	-- 设置更新循环
	if self.OnUpdate then
		self:_setupUpdateLoop()
	end
	
	self.Enabled = true
	self.Initialized:Fire()
	self:_log("初始化完成")
end

function BaseController:Start()
	if not self.Enabled then
		self:Initialize()
	end
	
	self:_log("正在启动...")
	self:OnStart()
	self.Started:Fire()
	self:_log("启动完成")
end

function BaseController:Stop()
	if not self.Enabled then
		return
	end
	
	self:_log("正在停止...")
	
	-- 停止更新循环
	if self._updateConnection then
		self._updateConnection:Disconnect()
		self._updateConnection = nil
	end
	
	self:OnStop()
	self.Enabled = false
	self.Stopped:Fire()
	self:_log("已停止")
end

function BaseController:Destroy()
	if not self.Enabled and not self.Maid then
		return
	end
	
	self:_log("正在销毁...")
	
	-- 停止运行
	if self.Enabled then
		self:Stop()
	end
	
	-- 清理所有组件
	for name, component in pairs(self._components) do
		if component.Destroy then
			component:Destroy()
		end
	end
	self._components = {}
	
	-- 清理所有连接
	for _, connection in pairs(self._connections) do
		if connection then
			connection:Disconnect()
		end
	end
	self._connections = {}
	
	-- 子类清理
	self:OnDestroy()
	
	-- 清理事件和Maid
	self.Maid:Destroy()
	self.Initialized:Destroy()
	self.Started:Destroy()
	self.Stopped:Destroy()
	
	self.Destroyed:Fire()
	self.Destroyed:Destroy()
	
	self:_log("已销毁")
end

-- ============ 虚方法（子类重写） ============

function BaseController:OnInitialize()
	-- 子类重写此方法进行初始化
end

function BaseController:OnStart()
	-- 子类重写此方法进行启动逻辑
end

function BaseController:OnStop()
	-- 子类重写此方法进行停止逻辑
end

function BaseController:OnDestroy()
	-- 子类重写此方法进行销毁逻辑
end

function BaseController:OnUpdate(deltaTime: number)
	-- 子类重写此方法进行更新逻辑
end

function BaseController:OnRender(deltaTime: number)
	-- 子类重写此方法进行渲染逻辑（RenderStepped）
end

function BaseController:OnPhysics(deltaTime: number)
	-- 子类重写此方法进行物理逻辑（Stepped）
end

-- ============ 组件管理 ============

function BaseController:AddComponent(name: string, component: any)
	if self._components[name] then
		warn(self.Name .. ": 组件 " .. name .. " 已存在")
		return
	end
	
	self._components[name] = component
	self:_log("添加组件: " .. name)
	
	-- 如果组件有Initialize方法，自动调用
	if component.Initialize and self.Enabled then
		component:Initialize()
	end
end

function BaseController:GetComponent(name: string)
	return self._components[name]
end

function BaseController:RemoveComponent(name: string)
	local component = self._components[name]
	if component then
		if component.Destroy then
			component:Destroy()
		end
		self._components[name] = nil
		self:_log("移除组件: " .. name)
	end
end

-- ============ 连接管理 ============

function BaseController:Connect(name: string, event: RBXScriptSignal, callback: (...any) -> ())
	if self._connections[name] then
		self._connections[name]:Disconnect()
	end
	
	self._connections[name] = event:Connect(callback)
	self.Maid:GiveTask(self._connections[name])
	
	return self._connections[name]
end

function BaseController:Disconnect(name: string)
	local connection = self._connections[name]
	if connection then
		connection:Disconnect()
		self._connections[name] = nil
	end
end

-- ============ 远程通信 (使用Communication模块) ============

function BaseController:FireServer(eventName: string, ...: any)
	Communication.FireServer(eventName, ...)
end

function BaseController:InvokeServer(functionName: string, ...: any)
	return Communication.InvokeServer(functionName, ...)
end

function BaseController:OnServerEvent(eventName: string, callback: (...any) -> ())
	Communication.OnClientEvent(eventName, callback)
	-- 添加到Maid进行自动清理
	local connection = Communication.GetRemoteEvent(eventName).OnClientEvent:Connect(callback)
	self.Maid:GiveTask(connection)
	return connection
end

function BaseController:OnServerInvoke(functionName: string, callback: (...any) -> any)
	Communication.OnClientInvoke(functionName, callback)
end

-- 不可靠远程事件（用于高频率更新）
function BaseController:UnreliableFireServer(eventName: string, ...: any)
	Communication.UnreliableFireServer(eventName, ...)
end

function BaseController:OnUnreliableServerEvent(eventName: string, callback: (...any) -> ())
	Communication.UnreliableOnClientEvent(eventName, callback)
	-- 添加到Maid进行自动清理
	local connection = Communication.GetUnreliableRemoteEvent(eventName).OnClientEvent:Connect(callback)
	self.Maid:GiveTask(connection)
	return connection
end

-- ============ 工具方法 ============

function BaseController:_setupUpdateLoop()
	-- 根据需要的更新类型设置循环
	if self.OnRender then
		self._updateConnection = RunService.RenderStepped:Connect(function(dt)
			if self.Enabled then
				self:OnRender(dt)
			end
		end)
	elseif self.OnPhysics then
		self._updateConnection = RunService.Stepped:Connect(function(_, dt)
			if self.Enabled then
				self:OnPhysics(dt)
			end
		end)
	elseif self.OnUpdate then
		self._updateConnection = RunService.Heartbeat:Connect(function(dt)
			if self.Enabled then
				self:OnUpdate(dt)
			end
		end)
	end
	
	if self._updateConnection then
		self.Maid:GiveTask(self._updateConnection)
	end
end

function BaseController:_log(message: string)
	if self._debug then
		print(string.format("[%s]: %s", self.Name, message))
	end
end

function BaseController:SetDebug(enabled: boolean)
	self._debug = enabled
end

function BaseController:SetEnabled(enabled: boolean)
	if enabled and not self.Enabled then
		self:Start()
	elseif not enabled and self.Enabled then
		self:Stop()
	end
end

function BaseController:IsEnabled(): boolean
	return self.Enabled
end

-- ============ 静态方法 ============

function BaseController.extend(className: string?)
	local SubClass = {}
	SubClass.__index = SubClass
	setmetatable(SubClass, BaseController)
	
	function SubClass.new(...)
		local self = setmetatable(BaseController.new(className or "SubClass"), SubClass)
		if SubClass.Constructor then
			SubClass.Constructor(self, ...)
		end
		return self
	end
	
	return SubClass
end

-- ============ 工具函数 ============

function BaseController:WaitForChild(parent: Instance, childName: string, timeout: number?): Instance?
	local child = parent:WaitForChild(childName, timeout or 5)
	if not child then
		warn(self.Name .. ": 找不到子对象 " .. childName)
	end
	return child
end

function BaseController:GetCharacter(): Model?
	return self.Player.Character or self.Player.CharacterAdded:Wait()
end

function BaseController:GetHumanoid(): Humanoid?
	local character = self:GetCharacter()
	if character then
		return character:FindFirstChildOfClass("Humanoid")
	end
	return nil
end

function BaseController:GetRootPart(): BasePart?
	local character = self:GetCharacter()
	if character then
		return character:FindFirstChild("HumanoidRootPart") :: BasePart
	end
	return nil
end

return BaseController