-- Services
local TweenService = game:GetService("TweenService")

-- Modules
local UIElementEffect = require(script.Parent.UIElementEffect)

-- Simple OOP implementation
local UIElement = {}
UIElement.__index = UIElement

UIElement.Enum = {}
UIElement.Enum.UIType = {
	Frame = 1,
	Image = 2,
	Text = 3,
	ScreenGui = 4,
}

-- Constructor
-- @param UIInstance The Roblox UI Instance (Frame, ImageLabel, TextLabel, etc.)
-- @param UIType UIElement.Enum.UIType
-- @param ParentInstance Optional Parent Instance
-- @param eventCallbacks Optional table of callbacks { EventName = function(self, ...) }
function UIElement.new(UIInstance, UIType, ParentInstance, eventCallbacks)
	local self = setmetatable({}, UIElement)
	self.instance = UIInstance
	self.ui_type = UIType
	self.Priority = UIInstance:GetAttribute("Priority") or 0 -- Default priority
	self.instance.Parent = ParentInstance or self.instance.Parent -- Simplified assignment

	if
		self.ui_type == self.Enum.UIType.Frame
		or self.ui_type == self.Enum.UIType.Image
		or self.ui_type == self.Enum.UIType.Text
	then
		self.start_x_scale = math.max(self.instance.Size.X.Scale, 0)
		self.start_y_scale = math.max(self.instance.Size.Y.Scale, 0)
	end

	-- Connect event callbacks if provided
	if eventCallbacks then
		for eventName, callback in pairs(eventCallbacks) do
			if self.instance[eventName] and typeof(self.instance[eventName]) == "RBXScriptSignal" then
				self.instance[eventName]:Connect(function(...)
					callback(self, ...) -- Pass self as the first argument
				end)
			else
				warn("UIElement.New: Invalid event name or not a signal:", eventName)
			end
		end
	end

	-- Handle specific tags directly
	if self.instance:HasTag("HoverExpand") then
		self.instance.MouseEnter:Connect(function()
			self:LittleExpand() -- Call method directly
		end)
		self.instance.MouseLeave:Connect(function()
			self:LittleShrink() -- Call method directly
		end)
	end

	if self.instance:HasTag("BreathUI") then
		self:Breath() -- Start breathing animation

		-- Handle shining effect if BreathUI tag is present (assuming this is intended)
		task.spawn(function()
			self.shining = true -- Flag for the shining loop
			self.shining_Bg = self:GetChild("ShiningBG", true)
			if not self.shining_Bg then
				self.shining = false
				return
			end
			self.shining_gradient = self.shining_Bg:FindFirstChild("ShiningGradient")
			if not self.shining_gradient then
				self.shining = false
				return
			end
			self.shining_Bg.Visible = true
			while self.shining do
				local dt = task.wait()
				self.shining_gradient.Offset += Vector2.new(dt * 2.5, 0)
				if self.shining_gradient.Offset.X >= 1.8 then
					self.shining_gradient.Offset = Vector2.new(-1.8, 0)
				end
			end
		end)
	end
	return self
end

-- Methods (PascalCase)
function UIElement:Breath()
	local BreathTime = self.instance:GetAttribute("BreathTime") or 1
	local EndScale = self.instance:GetAttribute("EndScale") or 1
	self:TweenSize(UDim2.new(EndScale * self.start_x_scale, 0, EndScale * self.start_y_scale, 0), BreathTime) -- Call PascalCase TweenSize
	local con
	con = self.sizeTween.Completed:Connect(function()
		con:Disconnect()
		self:TweenSize(UDim2.new(1 * self.start_x_scale, 0, 1 * self.start_y_scale, 0), BreathTime) -- Call PascalCase TweenSize
		local con1
		con1 = self.sizeTween.Completed:Connect(function()
			con1:Disconnect()
			self:Breath() -- Recursive call
		end)
	end)
end

function UIElement:Expand()
	self:TweenSize(UDim2.new(1.1 * self.start_x_scale, 0, 1.1 * self.start_y_scale, 0)) -- Call PascalCase TweenSize
end

function UIElement:Shrink()
	self:TweenSize(UDim2.new(self.start_x_scale, 0, self.start_y_scale, 0)) -- Call PascalCase TweenSize
end

function UIElement:LittleExpand()
	self:TweenSize(UDim2.new(1.05 * self.start_x_scale, 0, 1.05 * self.start_y_scale, 0)) -- Call PascalCase TweenSize
end

function UIElement:LittleShrink()
	self:TweenSize(UDim2.new(self.start_x_scale, 0, self.start_y_scale, 0)) -- Call PascalCase TweenSize
end

function UIElement:ShiningExpand()
	self:TweenSize(UDim2.new(1.1 * self.start_x_scale, 0, 1.1 * self.start_y_scale, 0)) -- Call PascalCase TweenSize
	self.shining = true
	self.shining_Bg = self:GetChild("ShiningBG", true) -- Call PascalCase GetChild
	if not self.shining_Bg then
		self.shining = false
		return
	end
	self.shining_gradient = self.shining_Bg:FindFirstChild("ShiningGradient")
	if not self.shining_gradient then
		self.shining = false
		return
	end
	self.shining_Bg.Visible = true
	while self.shining do
		local dt = task.wait()
		self.shining_gradient.Offset += Vector2.new(dt * 2.5, 0)
		if self.shining_gradient.Offset.X >= 1.8 then
			self.shining_gradient.Offset = Vector2.new(-1.8, 0)
		end
	end
end

function UIElement:ContentExpand()
	local ContentExpandBG = self:GetChild("ContentExpandBG", true) -- Call PascalCase GetChild
	if ContentExpandBG then
		if self.ContentExpandTween then
			self.ContentExpandTween:Cancel()
		end
		-- local ContentExpandBG = self:GetChild("ContentExpandBG", true) -- Already got it
		ContentExpandBG.Size = UDim2.new(1, 0, 1, 0)
		ContentExpandBG.BackgroundColor3 = self.instance.BackgroundColor3
		ContentExpandBG.BackgroundTransparency = 0.3
		ContentExpandBG.ZIndex = self.instance.ZIndex - 1
		ContentExpandBG.Visible = true
		self.ContentExpandTween =
			TweenService:Create(ContentExpandBG, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
				Size = UDim2.new(1.2, 0, 1.3, 0),
				BackgroundTransparency = 1,
			})
		self.ContentExpandTween:Play()
	end
end

function UIElement:ShiningShrink()
	self:TweenSize(UDim2.new(math.max(self.start_x_scale, 0), 0, math.max(self.start_y_scale, 0), 0)) -- Call PascalCase TweenSize
	self.shining = false
	if self.shining_Bg then
		self.shining_Bg.Visible = false
	end
end

function UIElement:Destroy()
	-- Stop any running tweens or effects
	if self.sizeTween then
		self.sizeTween:Cancel()
		self.sizeTween = nil
	end
	if self.ContentExpandTween then
		self.ContentExpandTween:Cancel()
		self.ContentExpandTween = nil
	end
	if self.EffectCon then
		task.cancel(self.EffectCon)
		self.EffectCon = nil
	end
	self:RemoveEffect() -- Call PascalCase RemoveEffect
	self.shining = false -- Stop shining loop if running

	-- Destroy instance
	if self.instance then
		self.instance:Destroy()
		self.instance = nil
	end
	-- Clear metatable to break cycles? (Not strictly necessary in modern Lua GC)
	-- setmetatable(self, nil)
end

function UIElement:SetText(new_text, priority)
	assert(self.ui_type == self.Enum.UIType.Text, "UIElement:SetText - Not a Text element")
	self.instance.Text = new_text
	if priority then
		self:SetPriorityText(priority) -- Call PascalCase SetPriorityText
	end
end

function UIElement:SetFontFamily(new_font_family)
	assert(self.ui_type == self.Enum.UIType.Text, "UIElement:SetFontFamily - Not a Text element")
	assert(new_font_family, "UIElement:SetFontFamily - FontFamily is nil")
	self.instance.FontFace = Font.fromName(new_font_family)
end

-- TODO: Decouple from ConfigDatas or pass font info directly
function UIElement:SetPriorityText(priority)
	assert(self.ui_type == self.Enum.UIType.Text, "UIElement:SetPriorityText - Not a Text element")
	-- local PriorityFontInfos = ConfigDatas:GetConfigData("PriorityFontInfos", Priority) -- Removed ConfigDatas dependency
	local PriorityFontInfos = nil -- Placeholder
	if PriorityFontInfos then
		self:SetFontFamily(PriorityFontInfos.FontStyle) -- Call PascalCase SetFontFamily
		self:SetTextGradient(PriorityFontInfos) -- Call PascalCase SetTextGradient
	else
		warn("UIElement:SetPriorityText - PriorityFontInfos not found for priority:", priority)
		-- Maybe apply a default style or remove gradient if info is missing
		self:SetTextGradient(nil) -- Call PascalCase SetTextGradient
	end
end

-- TODO: Decouple from specific PriorityFontInfos structure
function UIElement:SetTextGradient(fontInfo)
	assert(self.ui_type == self.Enum.UIType.Text, "UIElement:SetTextGradient - Not a Text element")
	local gradient = self:GetChild("UIGradient", true) or Instance.new("UIGradient") -- Call PascalCase GetChild
	gradient.Name = "UIGradient" -- Ensure name for GetChild
	gradient.Parent = self.instance -- Ensure parent is set

	if fontInfo then
		-- Assuming fontInfo has the necessary color points and time positions
		-- Example structure check (adapt as needed):
		if fontInfo.timePos1 and fontInfo.colorPoint1 then
			local colorSequence = ColorSequence.new({
				ColorSequenceKeypoint.new(fontInfo.timePos1, Color3.fromHex(fontInfo.colorPoint1)),
				ColorSequenceKeypoint.new(fontInfo.timePos2, Color3.fromHex(fontInfo.colorPoint2)),
				ColorSequenceKeypoint.new(fontInfo.timePos3, Color3.fromHex(fontInfo.colorPoint3)),
				ColorSequenceKeypoint.new(fontInfo.timePos4, Color3.fromHex(fontInfo.colorPoint4)),
				ColorSequenceKeypoint.new(fontInfo.timePos5, Color3.fromHex(fontInfo.colorPoint5)),
			})
			gradient.Enabled = true
			gradient.Rotation = 90
			gradient.Color = colorSequence
		else
			warn("UIElement:SetTextGradient - Invalid fontInfo structure provided.")
			gradient.Enabled = false
		end
	else
		gradient.Enabled = false
	end
end

function UIElement:SetImage(new_image_id)
	assert(self.ui_type == self.Enum.UIType.Image, "UIElement:SetImage - Not an Image element")
	assert(new_image_id, "UIElement:SetImage - ImageId is nil")
	self.instance.Image = new_image_id
end

--- Sets background color
---@param new_color Color3
function UIElement:SetBackgroundColor(new_color)
	assert(self.instance.BackgroundColor3, "UIElement:SetBackgroundColor - Instance does not have BackgroundColor3 property")
	self.instance.BackgroundColor3 = new_color
end

function UIElement:SetProperties(properties)
	for property, value in pairs(properties) do
		self.instance[property] = value
	end
end

-- List of children class names to ignore when clearing
local CLEAR_IGNORE_LIST = {
	["UIGridLayout"] = true,
	["UIListLayout"] = true,
	["UIPadding"] = true,
	["UIStroke"] = true,
	["UICorner"] = true,
	["UIAspectRatioConstraint"] = true,
	["UITextSizeConstraint"] = true,
	["UIPageLayout"] = true,
	["UITableLayout"] = true,
}

-- Clears children of the UI element's instance
-- @param strict boolean If true, uses ClearAllChildren, otherwise iterates and checks ignore list.
function UIElement:ClearChildren(strict)
	if strict then
		self.instance:ClearAllChildren()
	else
		for _, child in ipairs(self.instance:GetChildren()) do -- Use ipairs for arrays
			if child.Name == "Unclear" then
				continue
			end
			if not CLEAR_IGNORE_LIST[child.ClassName] then
				child:Destroy()
			end
		end
	end
end

-- Sets the visibility of the UI element's instance
-- @param visible boolean
function UIElement:SetVisible(visible)
	self.instance.Visible = visible
end

-- Gets a child of the UI element's instance
-- @param childName string The name of the child to find.
-- @param strict boolean If true, uses FindFirstChild, otherwise uses WaitForChild.
-- @return Instance or nil
function UIElement:GetChild(childName, strict)
	if strict then
		return self.instance:FindFirstChild(childName)
	else
		-- Consider adding a timeout to WaitForChild to prevent infinite yields
		return self.instance:WaitForChild(childName)
	end
end

-- Effect methods (delegating to UIElementEffect)
function UIElement:AddEffect()
	UIElementEffect:AddEffect(self)
end

function UIElement:RemoveEffect()
	UIElementEffect:RemoveEffect(self)
end

function UIElement:AddSelectedEffect()
	UIElementEffect:AddSelectedEffect(self)
end

function UIElement:RemoveSelectedEffect()
	UIElementEffect:RemoveSelectedEffect(self)
end

function UIElement:AddDeleteEffect()
	UIElementEffect:AddDeleteEffect(self)
end

function UIElement:RemoveDeleteEffect()
	UIElementEffect:RemoveDeleteEffect(self)
end

-- Tweening method (delegating to UIElementEffect)
function UIElement:TweenSize(endSize, duration)
	UIElementEffect:TweenSize(self, endSize, duration)
end

return UIElement
