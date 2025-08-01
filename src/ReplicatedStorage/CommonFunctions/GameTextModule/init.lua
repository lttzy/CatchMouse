local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ModuleScripts = ReplicatedStorage:WaitForChild("ModuleScripts")
local CommonModule = ModuleScripts:WaitForChild("CommonModule")
local Utility = require(CommonModule:WaitForChild("Utility"))
local Promise = require(CommonModule:WaitForChild("Promise"))

local BoardFolder = game.Workspace:FindFirstChild("Board")
if not BoardFolder then
	BoardFolder = Instance.new("Folder")
	BoardFolder.Name = "Board"
	BoardFolder.Parent = game.Workspace
end

local function tween(obj:Instance, tweenInfo:TweenInfo, props:{ [string]: any })
	return Promise.new(function(resolve, reject, onCancel)
		local tween = TweenService:Create(obj, tweenInfo, props)
		onCancel(function()
			tween:Cancel()
			--tween:Pause()
		end)
		tween.Completed:Connect(resolve)
		tween:Play()
	end)
end

local function showWait(lifeTime)
	return Promise.new(function(resolve, reject, onCancel)
		local deltaTime = 0
		local Con = nil
		Con = RunService.RenderStepped:Connect(function(dt)
			deltaTime += dt
			if deltaTime >= lifeTime then
				resolve()
				Con:Disconnect()
				Con = nil
			end
		end)

		onCancel(function()
			if Con then Con:Disconnect() Con = nil end
		end)
	end)
end

local function GetPart(position,name)
	local part = Instance.new("Part")
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Transparency = 1
	part.Size = Vector3.new(1,1,1)
	part.Position = position
	part.Anchored = true
	part.Name = name
	part.Parent = BoardFolder
	return part
end

local module = {}

local tweenInfo = {
	damageText = TweenInfo.new(.1,Enum.EasingStyle.Bounce,Enum.EasingDirection.Out,0,false,0)
}
local damageTextBoard = {
	[0] = script.Normal_Hit,
	[1] = script.Fire_Hit,
	[2] = script.Water_Hit,
	[3] = script.Grass_Hit,
	[4] = script.Thunder_Hit,
	[5] = script.Earth_Hit,
}
local damageTextList = {}
local damageInitSize = UDim2.new(0,150,0,50)
local damageTweenSize = UDim2.new(0,225,0,75)
local function SetDamageText(uniqueId:number,value:number,worldPosition:Vector3,typesId:number&string)
	if not damageTextList[uniqueId] then
		damageTextList[uniqueId] = {
			instance = damageTextBoard[typesId]:Clone(),
			tweenList = {},
			lifeTime = 1,
			value = 0,
			offset = Vector3.new(math.random(-200,200)/100,0,math.random(-200,200)/100),
		}
	end
	local board = damageTextList[uniqueId]
	if not board then return end
	
	if board.tweenList["TextSize"] then
		board.tweenList["TextSize"]:cancel()
		if board.tweenList["ShowWait"] then board.tweenList["ShowWait"]:cancel() end
	end
	if board.tweenList["StudsOffset"] then board.tweenList["StudsOffset"]:cancel() end
	if board.tweenList["UIStrokeTransparency"] then board.tweenList["UIStrokeTransparency"]:cancel() end
	if board.tweenList["TextTransparency"] then board.tweenList["TextTransparency"]:cancel() end
	
	board.value += value
	board.instance.StudsOffset = Vector3.new(0,0,0) + board.offset
	board.instance.Size = damageInitSize
	board.instance.Value.UIStroke.Transparency = 0
	board.instance.Value.TextTransparency = 0
	board.instance.Enabled = true
	board.instance.Value.Text = "-"..Utility:ShowGoldNum(board.value)
	board.instance.Parent = GetPart(worldPosition,uniqueId)
	
	board.tweenList["TextSize"] = tween(board.instance,tweenInfo.damageText,{Size = damageTweenSize})
		:andThen(function()
			board.tweenList["TextSize"] = tween(board.instance,tweenInfo.damageText,{Size = damageInitSize})
			:andThen(function()
				board.tweenList["ShowWait"] = showWait(board.lifeTime)
				:andThen(function()
					board.tweenList["StudsOffset"] = tween(board.instance,TweenInfo.new(.5),{StudsOffset = board.instance.StudsOffset+Vector3.new(0,5,0)})
					board.tweenList["UIStrokeTransparency"] = tween(board.instance.Value.UIStroke,TweenInfo.new(.5),{Transparency = 1})
					board.tweenList["TextTransparency"] = tween(board.instance.Value,TweenInfo.new(.5),{TextTransparency = 1}):andThen(function()
						board.value = 0
					end)
				end)
			end)
		end)
end

local CRITTextList = {}
local CRITInitSize = UDim2.new(0,150,0,50)
local CRITTweenSize = UDim2.new(0,225,0,75)
local function SetCRITText(uniqueId:number,value:number,worldPosition:Vector3,typesId:number&string)
	if not CRITTextList[uniqueId] then
		CRITTextList[uniqueId] = {
			instance = damageTextBoard[typesId]:Clone(),
			tweenList = {},
			lifeTime = 1,
			value = 0,
			offset = Vector3.new(math.random(-200,200)/100,0,math.random(-200,200)/100),
		}
	end
	local board = CRITTextList[uniqueId]
	if not board then return end

	if board.tweenList["TextSize"] then
		board.tweenList["TextSize"]:cancel()
		if board.tweenList["ShowWait"] then board.tweenList["ShowWait"]:cancel() end
	end
	if board.tweenList["StudsOffset"] then board.tweenList["StudsOffset"]:cancel() end
	if board.tweenList["IconTransparency"] then board.tweenList["IconTransparency"]:cancel() end
	if board.tweenList["UIStrokeTransparency"] then board.tweenList["UIStrokeTransparency"]:cancel() end
	if board.tweenList["TextTransparency"] then board.tweenList["TextTransparency"]:cancel() end
	
	board.instance.CRIT.Visible = true
	board.value += value
	board.instance.StudsOffset = Vector3.new(0,5,0) + board.offset
	board.instance.Size = CRITInitSize
	board.instance.CRIT.ImageTransparency = 0
	board.instance.Value.UIStroke.Transparency = 0
	board.instance.Value.TextTransparency = 0
	board.instance.Enabled = true
	board.instance.Value.Text = "-"..Utility:ShowGoldNum(board.value)
	board.instance.Parent = GetPart(worldPosition,uniqueId)

	board.tweenList["TextSize"] = tween(board.instance,tweenInfo.damageText,{Size = CRITTweenSize})
		:andThen(function()
			board.tweenList["TextSize"] = tween(board.instance,tweenInfo.damageText,{Size = CRITInitSize})
			:andThen(function()
				board.tweenList["ShowWait"] = showWait(board.lifeTime)
				:andThen(function()
					board.tweenList["StudsOffset"] = tween(board.instance,TweenInfo.new(.5),{StudsOffset = board.instance.StudsOffset+Vector3.new(0,5,0)})
					board.tweenList["IconTransparency"] = tween(board.instance.CRIT,TweenInfo.new(.5),{ImageTransparency = 1})
					board.tweenList["UIStrokeTransparency"] = tween(board.instance.Value.UIStroke,TweenInfo.new(.5),{Transparency = 1})
					board.tweenList["TextTransparency"] = tween(board.instance.Value,TweenInfo.new(.5),{TextTransparency = 1}):andThen(function()
						board.value = 0
					end)
				end)
			end)
		end)
end

local function ClearDamageText(uniqueId:number&string)
	delay(2,function()
		local boradPart = BoardFolder:FindFirstChild(uniqueId)
		if boradPart then
			boradPart:Destroy()
		end
		damageTextList[uniqueId] = nil
	end)	
end

local function ClearCRITText(uniqueId:number&string)
	delay(2,function()
		local boradPart = BoardFolder:FindFirstChild(uniqueId)
		if boradPart then
			boradPart:Destroy()
		end
		CRITTextList[uniqueId] = nil
	end)
end

module.SetDamageText = SetDamageText
module.SetCRITText = SetCRITText
module.ClearDamageText = ClearDamageText
module.ClearCRITText = ClearCRITText

--local function EndTween(index)
--	local tweenInfo = TweenInfo.new(.8,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,false,0)

--	index.instance.StudsOffset = Vector3.new(0,0,0)
--	index.instance.ValueText.TextTransparency = 0
--	index.instance.ValueText.UIStroke.Transparency = 0
--	index.instance.CRIT.ImageTransparency = 0

--	index.tweenTask["position"] = TweenService:Create(index.instance, tweenInfo,{StudsOffset = index.instance.StudsOffset+Vector3.new(0,3,0)})
--	index.tweenTask["text"] = TweenService:Create(index.instance.ValueText, tweenInfo,{TextTransparency = 1})
--	index.tweenTask["uiStroke"] = TweenService:Create(index.instance.ValueText.UIStroke, tweenInfo,{Transparency = 1})
--	index.tweenTask["CRITIcon"] = TweenService:Create(index.instance.CRIT, tweenInfo,{ImageTransparency = 1})

--	index.tweenTask["position"]:Play()
--	index.tweenTask["text"]:Play()
--	index.tweenTask["uiStroke"]:Play()
--	index.tweenTask["CRITIcon"]:Play()
--	index.tweenTask["position"].Completed:Wait()
--end

--local function Init(index)
--	index.StudsOffset = Vector3.new(0,0,0)
--	index.ValueText.TextTransparency = 0
--	index.ValueText.UIStroke.Transparency = 0
--	index.CRIT.ImageTransparency = 0
--end

--local function SetCRIT(target,typesId,startPos,damage)
--	task.defer(function()
--		if not CRITTable[target] then
--			CRITTable[target] = {}
--		end
--		if not CRITTable[target][typesId] then
--			CRITTable[target][typesId] = {}
--			CRITTable[target][typesId]["task"] = nil
--			CRITTable[target][typesId]["instance"] = damageTextList[typesId]:Clone()
--			CRITTable[target][typesId]["lifeTime"] = 1
--			CRITTable[target][typesId]["debounce"] = true
--			CRITTable[target][typesId]["tweenTask"] = {}
--		end
--		local CRITImage = CRITTable[target][typesId]
--		if not CRITImage then return end
--		CRITImage.instance.Size = CRITTweenSize
--		local tween = TweenService:Create(CRITImage.instance, TweenInfo.new(.25),{Size = CRITInitSize}):Play()
--		CRITImage.instance.StudsOffsetWorldSpace = startPos + Vector3.new(0,3,0)
--		Init(CRITImage.instance)
--		CRITImage.debounce = true
--		CRITImage.lifeTime = 1
--		if CRITImage.task then CRITImage.task:Disconnect() CRITImage.task = nil end
--		CRITImage.instance.CRIT.Visible = true
--		CRITImage.instance.ValueText.Text = Utility:ShowGoldNum(damage)
--		CRITImage.instance.Parent = hitTextTable[target][typesId].part
		
--		CRITImage.task = RunService.RenderStepped:Connect(function(dt)
--			if not target or not target.Parent or not target:IsDescendantOf(game.Workspace) then
--				if CRITImage.task then CRITImage.task:Disconnect() CRITImage.task = nil end
--				EndTween(CRITImage)
--				CRITImage.instance:Destroy()
--				CRITTable[target] = nil
--				return
--			end

--			CRITImage.lifeTime -= dt
--			if CRITImage.lifeTime <= 0 and CRITImage.debounce == true then
--				CRITImage.debounce = false
--				if not CRITImage or not CRITImage.instance then return end
--				EndTween(CRITImage)
--			end
--		end)
--	end)
--end

----伤害数字
--local function Activated(target:Instance,damage:number,typesId:number,CRIT:boolean)
--	if not hitTextTable[target] then
--		hitTextTable[target] = {}
--	end
--	local position = Vector3.zero
--	local cframe = CFrame.new(0,0,0)
--	if target:IsA("BasePart") then
--		position = target.Position
--		cframe = target.CFrame
--	elseif target:IsA("Model") then
--		position = target.PrimaryPart.Position
--		cframe = target:GetPivot()
--	end
--	if not hitTextTable[target][typesId] then
--		hitTextTable[target][typesId] = {}
--		hitTextTable[target][typesId]["task"] = nil
--		hitTextTable[target][typesId]["instance"] = damageTextList[typesId]:Clone()
--		hitTextTable[target][typesId]["part"] = GetPart(position)
--		hitTextTable[target][typesId]["lifeTime"] = 1
--		hitTextTable[target][typesId]["offset"] = Vector3.new(math.random(-200,200)/100,0,math.random(-200,200)/100)
--		hitTextTable[target][typesId]["debounce"] = true
--		hitTextTable[target][typesId]["tweenTask"] = {}
--	end
	
--	local hitText = hitTextTable[target][typesId]
--	if not hitText then return end
--	hitText.instance.Size = tweenSize
--	--hitText.instance.Adornee = hitText.part
--	local tween = TweenService:Create(hitText.instance, TweenInfo.new(.25),{Size = initSize}):Play()
--	tween = nil
--	Init(hitText.instance)
--	hitTextTable[target][typesId]["part"].Position = position
--	--hitText.instance.StudsOffsetWorldSpace = position + cframe.RightVector*2.5 + hitText.offset
--	hitText.instance.StudsOffsetWorldSpace = cframe.RightVector*2.5 + hitText.offset
--	hitText.lifeTime = 1
--	hitText.debounce = true
	
--	if hitText.task then hitText.task:Disconnect() hitText.task = nil end
	
--	if CRIT then
--		SetCRIT(target,typesId,hitText.instance.StudsOffsetWorldSpace,damage)
--	end
--	hitText.instance:SetAttribute("Value",hitText.instance:GetAttribute("Value") + math.floor(damage + 0.5))
--	hitText.instance.ValueText.Text = "-"..Utility:ShowGoldNum(hitText.instance:GetAttribute("Value"))
--	hitText.instance.Parent = hitText.part
	
--	hitText.task = RunService.RenderStepped:Connect(function(dt)
--		if not target or not target.Parent or not target:IsDescendantOf(game.Workspace) then
--			if hitText.task then hitText.task:Disconnect() hitText.task = nil end
--			EndTween(hitText)
--			hitText.part:Destroy()
--			hitTextTable[target] = nil
--			return
--		end
		
--		hitText.lifeTime -= dt
--		if hitText.lifeTime <= 0 and hitText.debounce == true then
--			hitText.debounce = false
--			if not hitText or not hitText.instance then return end
--			hitText.instance:SetAttribute("Value",0)
--			EndTween(hitText)
--		end
--	end)
--end

--module.Activated = Activated

return module
