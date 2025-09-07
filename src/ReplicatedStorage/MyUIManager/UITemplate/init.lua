--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local Maid = require(ReplicatedStorage.Source.CommonFunctions.Maid)
local AttributeListener = require(ReplicatedStorage.Source.CommonFunctions.AttributeListener)

local UIElement = require(script.Parent.UIElement)

local PLAYER_GUI = player:WaitForChild("PlayerGui")

local UITemplate = {}
UITemplate.__index = UITemplate

--- 创建子类
---@param ClassName string 子类的名称
---@return table GUIInstance
function UITemplate:Extend(ClassName)
	local NewClass = {}
	NewClass.__index = NewClass
	NewClass.ClassName = ClassName or "SubClass"

	function NewClass.new(...)
		local instance = setmetatable({}, NewClass)
		instance:Init(...)
		return instance
	end

	setmetatable(NewClass, self)

	return NewClass
end

--- 构造函数
--- @param Name string UI实例名称
---@return table GUIInstance
function UITemplate:Init(Name)
	self.Maid = Maid.new()
	self.AttributeListeners = {}
	self.ClassName = self.ClassName or "UITemplate"
	self.GuiName = Name
	self.Gui = script:WaitForChild(self.GuiName):Clone()
	if not self.Gui then
		warn("[UITemplate] Failed to find UI template:", self.GuiName)
		return
	end
	self.Gui.Parent = PLAYER_GUI

	self:_InitRefrences()
	self:_InitConnections()
end

--- 添加属性监听器
---@param Instance Instance 要监听的实例
---@param AttributeName string 属性名称
---@param Callback function 回调函数
function UITemplate:_AddAttributeListener(Instance, AttributeName, Callback)
	local listener = AttributeListener.new(Instance, AttributeName, Callback)
	table.insert(self.AttributeListeners, listener)
	return listener
end

--- 清除属性监听器
function UITemplate:_ClearAttributeListeners()
	for _, listener in ipairs(self.AttributeListeners) do
		listener:Destroy()
	end
end

--- 初始化引用
function UITemplate:_InitRefrences()
	self.MainFrame = UIElement.new(self.Gui:WaitForChild("MainFrame"), UIElement.Enum.UIType.Frame)
	-- self.CoinsFrame = UIElement.new(self.MainFrame:GetChild("CoinsFrame"), UIElement.Enum.UIType.Frame)
	-- self.CoinsNumText = UIElement.new(self.CoinsFrame:GetChild("Number"), UIElement.Enum.UIType.Text)

	-- self:_AddAttributeListener(player, "Coins", function(coins)
	-- 	self.CoinsNumText:SetText(tostring(coins or 0))
	-- end)
end

--- 初始化事件绑定
function UITemplate:_InitConnections()
	-- self.Maid:GiveTask(self.CloseBtn.MouseButton1Click:Connect(function()
	--     self:Hide()
	-- end))

	-- Communication.OnClientEvent("StoreRefreshed", function(storeName)
	--     if storeName == "EggStore" and self.Gui.Enabled then
	--         self:UpdateStore()
	--     end
	-- end)
end

--- 根据模板名创建对应UI元素
---@param TemplateName string 模板名
---@param Parent Instance 父元素
---@param handleFunc function 处理函数, ... 为传入handleFunc的参数
function UITemplate:_CreateTemplate(TemplateName, Parent, handleFunc, ...)
    if not self.Templates then
        self.Templates = UIElement.new(self.Gui:WaitForChild("Templates"), UIElement.Enum.UIType.Frame)
    end
    if not self.Templates or not self.Templates:GetChild(TemplateName) then
        warn("[UITemplate] Failed to find template:", TemplateName)
        return
    end
	local templateClone = self.Templates:GetChild(TemplateName):Clone()
	templateClone.Parent = Parent
	templateClone.Visible = true
	handleFunc(templateClone, ...)
end

--- 用于刷新显示，重置UI
function UITemplate:_Refresh()

end

--- 显示UI，并重置UI
function UITemplate:Show()
	self.Gui.Enabled = true
	self:_Refresh()
end

--- 隐藏UI
function UITemplate:Hide()
	self.Gui.Enabled = false
end

--- 销毁，清理事件与实例
function UITemplate:Destroy()
	self.Maid:DoCleaning()
    self:_ClearAttributeListeners()
	self.Gui:Destroy()
    self = nil
end

return UITemplate
