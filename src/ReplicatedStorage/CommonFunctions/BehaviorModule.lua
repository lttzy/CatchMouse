---@diagnostic disable: undefined-type
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModuleScripts = ReplicatedStorage:WaitForChild("ModuleScripts")
local CommonModule = ModuleScripts:WaitForChild("CommonModule")
local Promise = require(CommonModule:WaitForChild("Promise"))

local module = {}

--myModel 触发者   target 目标   dot 扇形角度(-1~1)正面为正数,背面为负数  distance 距离  backDistance 背面距离
local function CheckAttackSight(myModel:Model,target:Model,dot:number,distance:number,backDistance:number):boolean --检查攻击范围(扇形)
	if not myModel or not target then return end
	local myModelRootPart = myModel:FindFirstChild("HumanoidRootPart")
	local targetRootPart = target:FindFirstChild("HumanoidRootPart")
	local myModelHead = myModel:FindFirstChild("Head")
	if not myModelRootPart or not targetRootPart or not myModelHead then return end

	local unit = (targetRootPart.Position - myModelRootPart.Position).Unit
	local look = myModelHead.CFrame.LookVector
	local dotProduct = unit:Dot(look)
	if dotProduct >= dot then
		if (target:GetPivot().Position - myModelRootPart.Position).Magnitude <= distance then
			return true
		end
	else
		if (target:GetPivot().Position - myModelRootPart.Position).Magnitude <= backDistance then
			return true
		end
	end
	return false
end

--myPart 触发块  targetList 目标表
local function GetNearestTarget(myPart:BasePart,targetList:Instances):BasePart --检查最近目标
	assert(type(targetList) == "table", "First argument must be a table")
	if not myPart then return end
	local nearestTarget = nil
	local nearestDistance = math.huge
	local targetPart = nil
	for _,target in pairs(targetList) do
		if target:IsA("Model") then
			targetPart = target.PrimaryPart
		elseif target:IsA("BasePart") then
			targetPart = target
		end
		if not targetPart then
			assert(targetPart,"targetPart must be a Model or BasePart")
		end

		if targetPart and myPart then
			local Distance = (targetPart.Position - myPart.Position).Magnitude
			if Distance < nearestDistance then 
				nearestTarget = targetPart
				nearestDistance = Distance
			end
		end	
	end
	return nearestTarget
end

--myPart 触发块  targetPart 目标块   distance 距离 filterType黑名单或者白名单  filterDescendantsInstances 黑或白名单
local function CheckSight(myPart:BasePart,targetPart:BasePart,distance:number,filterType:boolean,filterDescendantsInstances:Instances):boolean--检查目标是否在视野范围内
	if not myPart or not targetPart then return false end
	local rayOrigin = myPart.Position
	local rayDirection = (targetPart.Position - myPart.Position).Unit * distance

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {filterDescendantsInstances}
	if filterType == false then
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	else
		raycastParams.FilterType = Enum.RaycastFilterType.Include
	end
	local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	if raycastResult and raycastResult.Instance then
		if raycastResult.Instance:IsDescendantOf(targetPart.Parent) then
			return true
		end
	end
	return false
end

--startPart 触发块  endPart 目标块
local function LookAtTarget(startPart:BasePart,endPart:BasePart) --面向目标
	if not startPart or not endPart then return end
	local bodyGyro = startPart:FindFirstChild("BodyGyro")
	if bodyGyro then
		bodyGyro.CFrame = CFrame.new(startPart.Position,endPart.Position)
	else
		bodyGyro = Instance.new("BodyGyro")
		bodyGyro.MaxTorque = Vector3.new(0,50000,0)
		bodyGyro.P = 10000
		bodyGyro.CFrame = CFrame.new(startPart.Position,endPart.Position)
		bodyGyro.Parent = startPart
	end
	game.Debris:AddItem(bodyGyro,.2)
end

--track:动画Track speed:播放速度 bool:是否等待完成
local function AnimPlay(track:AnimationTrack,speed:number,bool:boolean)
	if track then
		track:Play()
		track:AdjustSpeed(speed)
		if bool then
			track.Stopped:Wait()
		end
	end
end

--track:动画
local function AnimStop(track:AnimationTrack)
	if track then
		track:Stop()
	end
end

--获取模型高度
local function GetY(instance:Instance,pos:Vector3,yOffset:number,ray:RaycastParams)
	if not instance then return 0 end
	local target = instance:IsA("Model") and instance.PrimaryPart or instance
	if not target or not target.Position then return 0 end
	local rayResult = workspace:Raycast((pos or target.Position) + Vector3.new(0,100,0),Vector3.new(0,-1000,0),ray)
	if rayResult then
		return rayResult.Position.Y + (yOffset or 0)
	else
		return target.Position.Y + (yOffset or 0)
	end
end

local function Tween(obj:Instance, tweenInfo:TweenInfo, props:{string})
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

module.CheckAttackSight = CheckAttackSight--检查攻击范围(扇形)
module.GetNearestTarget = GetNearestTarget--检查最近目标
module.CheckSight = CheckSight--检查目标是否在视野范围内
module.LookAtTarget = LookAtTarget--面向目标
module.AnimPlay = AnimPlay--播放动画
module.AnimStop = AnimStop--停止动画
module.GetY = GetY--获取模型高度
module.Tween = Tween--播放动画

return module
