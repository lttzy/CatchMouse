local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):wait()

local GuideBeam = script:WaitForChild("GuideBeam")
local NPCTalking = script:WaitForChild("NPCTalking")

local module = {}

local function AddBeam()
	local character = player.Character
	if not character then return end
	local RootPart = character:FindFirstChild("HumanoidRootPart")
	if not RootPart then return end
	local Attachment0 = RootPart:FindFirstChild("GuidePoint") or Instance.new("Attachment",RootPart)
	Attachment0.Name = "GuidePoint"
	local beam = RootPart:FindFirstChild("GuideBeam") or GuideBeam:Clone()
	beam.Parent = RootPart
	beam.Attachment0 = RootPart.GuidePoint
	return beam
end


local function CheckBeam(beam,targetObject)
	if beam.Attachment0 == nil or beam.Attachment1 == nil then
		repeat
			task.wait()
			beam = AddBeam()
			local Attachment1 = targetObject:FindFirstChild("GuidePoint") or Instance.new("Attachment",targetObject)
			Attachment1.Name = "GuidePoint"
			beam.Attachment1 = Attachment1
		until beam.Attachment0 ~= nil and beam.Attachment1 ~= nil
	end 
end

local function RemoveBeam(char)
	local character = char or player.Character
	if not character then return end
	local RootPart = character:FindFirstChild("HumanoidRootPart")
	if RootPart then
		local Attachment0 = RootPart:FindFirstChild("GuidePoint")
		if Attachment0 then Attachment0:Destroy() end

		local beam = RootPart:FindFirstChild("GuideBeam")
		if beam then beam:Destroy() end
	end
end

local function ConnectionBeam(targetObject)
	local character = player.Character
	if not character then return end
	local RootPart = character:FindFirstChild("HumanoidRootPart")
	if not RootPart or not targetObject then return end
	local beam = RootPart:FindFirstChild("GuideBeam")
	if not beam then
		beam = AddBeam()
	end
	local Attachment1 = targetObject:FindFirstChild("GuidePoint") or Instance.new("Attachment",targetObject)
	Attachment1.Name = "GuidePoint"
	beam.Attachment1 = Attachment1
	CheckBeam(beam,targetObject)
end

local writeDeltaTime = 0
local writeTask = nil
local wirteFinishedTask = nil
local function Typewrite(label:string,icon:string,UIPosition:UDim2)
	if writeTask then writeTask:Disconnect() end
	if wirteFinishedTask then wirteFinishedTask:Disconnect() end
	local ScreenGui = player.PlayerGui:FindFirstChild("NPCTalking") and player.PlayerGui.NPCTalking or NPCTalking:Clone()
	ScreenGui.Parent = player.PlayerGui
	ScreenGui.Frame.DialogBox.Position = UIPosition or UDim2.new(.5, 0,.95, 0)
	ScreenGui.Frame.DialogBox.Icon.Image = icon or "rbxassetid://135592463244864"
	ScreenGui.Frame.DialogBox.TextLabel.Text = ""
	ScreenGui.Frame.DialogBox.NextTips.Visible = false
	ScreenGui.Enabled = true
	
	local nowTextNum = 1
	
	writeTask = RunService.RenderStepped:Connect(function(dt)
		writeDeltaTime += dt
		if writeDeltaTime >= .02 then
			writeDeltaTime = 0
			if nowTextNum <= #label then
				ScreenGui.Frame.DialogBox.TextLabel.Text = string.sub(label,1,nowTextNum)
				nowTextNum += 1
			else
				writeTask:DoCleaning()
				ScreenGui.Frame.DialogBox.NextTips.Visible = true
				wirteFinishedTask = ScreenGui.Frame.DialogBox.MouseButton1Down:Connect(function()
					ScreenGui.Frame.DialogBox.TextLabel.Text = ""
					ScreenGui.Enabled = false
					wirteFinishedTask:Disconnect()
				end)
			end
		end
	end)
end


local UIElement = require(ReplicatedStorage.Source.MyUIManager.UIElement)
local GuideIcon = UIElement.New(script.GuideIcon, UIElement.Enum.UIType.Image)
local currentGuideConnection = nil

--- 新增方法：指引到UI按钮
-- @param buttonElement UIElement对象，需要指引的UI按钮
-- @param callback function 可选的回调函数，在点击按钮后执行
-- @param direction string 可选的指引方向 ("Up" 或 "Down")，默认为 "Up"
local function GuideToUIButton(buttonElement, callback, direction)
	if not buttonElement or not buttonElement.Parent then
		warn("GuideToUIButton: Invalid buttonElement provided.")
		return
	end

	-- 将 GuideIcon 的父元素设置为目标按钮
	GuideIcon.instance.Parent = buttonElement

	-- 根据指引方向设置 GuideIcon 的旋转和位置
	local guideDirection = direction or "Up" -- 默认为上方

	if guideDirection == "Up" then
		GuideIcon.instance.Rotation = 180
		GuideIcon.instance.Position = UDim2.new(0.5, 0, -0.2, 0)
	elseif guideDirection == "Down" then
		GuideIcon.instance.Rotation = 0
		GuideIcon.instance.Position = UDim2.new(0.5, 0, 1.7, 0)
	end

	-- 监听按钮点击事件
	-- Store the connection in a controller variable
	if currentGuideConnection then
		currentGuideConnection:Disconnect() -- Disconnect previous if any
	end
	currentGuideConnection = buttonElement.MouseButton1Click:Connect(function()
		-- 断开连接
		currentGuideConnection:Disconnect()
		currentGuideConnection = nil -- Clear the stored connection
		-- 点击后将 GuideIcon 的父元素设置回 script
		GuideIcon.instance.Parent = script

		-- 如果存在回调函数，则执行
		if callback then
			callback()
		end
	end)
end

--- 取消指引到UI按钮
-- 断开事件连接并将 GuideIcon 的父元素设置回 script
local function CancelGuideToUIButton()
	-- 检查是否存在当前的指引连接
	if currentGuideConnection then
		-- 断开连接
		currentGuideConnection:Disconnect()
		-- 清除存储的连接
		currentGuideConnection = nil
	end

	-- 将 GuideIcon 的父元素设置回 script
	-- 检查 GuideIcon.instance 是否有效，避免错误
	if GuideIcon and GuideIcon.instance then
		GuideIcon.instance.Parent = script
	end
end
module.ConnectionBeam = ConnectionBeam
module.RemoveBeam = RemoveBeam
module.Typewrite = Typewrite
module.GuideToUIButton = GuideToUIButton
module.CancelGuideToUIButton = CancelGuideToUIButton

return module