local RunService = game:GetService("RunService")
local rs = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Knit = require(rs.Packages.Knit)
local Utils = {}

Utils.POS_UPDATE_INTERVAL = 0.15
Utils.TARGET_UPDATE_INTERVAL = 0.3
Utils.MOVE_UPDATE_INTERVAL = 0.1
Utils.ATTACK_UPDATE_INTERVAL = 0.017
Utils.STATE_UPDATE_INTERVAL = 0.017
Utils.DEBUG = false

function Utils:ConvertVec2ToVec3(vec2Table, y)
	return Vector3.new(vec2Table[1], y or 0, vec2Table[2])
end

function Utils:ConvertVec3ToVec2Table(vec3)
	return { vec3.X, vec3.Z }
end

---==== time ====---
-- 秒数转换为分:秒格式的函数
function Utils:FormatSecTimeToMS(seconds)
	-- 确保输入是一个非负整数
	seconds = math.floor(seconds)
	if seconds < 0 then
		return "00:00"
	end

	local minutes = math.floor(seconds / 60)
	local remainingSeconds = seconds % 60

	-- 如果需要，可以限制分钟的显示，例如最多显示99分钟
	-- if minutes > 99 then
	--     minutes = 99
	-- end

	-- 使用 string.format 确保分钟和秒数都是两位数
	return string.format("%02d:%02d", minutes, remainingSeconds)
end

-- 秒数转换为时:分:秒格式的函数
function Utils:FormatSecTimeToHMS(seconds)
	-- 确保输入是一个非负整数
	seconds = math.floor(seconds)
	if seconds < 0 then
		return "00:00:00"
	end

	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local remainingSeconds = seconds % 60

	-- 使用 string.format 确保小时、分钟和秒数都是两位数
	return string.format("%02d:%02d:%02d", hours, minutes, remainingSeconds)
end

function Utils:FormatSecTimeDHMS(seconds)
	seconds = math.floor(seconds)
	if seconds < 0 then
		return "00:00:00:00"
	end

	local days = math.floor(seconds / 86400)
	local hours = math.floor((seconds % 86400) / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local remainingSeconds = seconds % 60

	return string.format("%02d:%02d:%02d:%02d", days, hours, minutes, remainingSeconds)
end

---==== date ====---
-- 辅助函数：获取当前日期和星期
function Utils:GetCurrentDate()
	return os.date("%Y-%m-%d")
end

function Utils:IsWeekend()
	local dayOfWeek = tonumber(os.date("%w")) -- 0 为周日，6 为周六
	return dayOfWeek == 0 or dayOfWeek == 6
end

---==== guid ====---
local guidChars = {}
local guidCharsText = "1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!@#$%^&*()_+./"
for i = 1, #guidCharsText do
	guidChars[i] = guidCharsText:sub(i, i)
end
local randomNamesText = "abcdefghijklmnopqrstuvwxyz"
local randomNamesChars = {}
for i = 1, #randomNamesText do
	randomNamesChars[i] = randomNamesText:sub(i, i)
end
local guidRandom = Random.new()

--- Generates a new GUID
---@return string UID
function Utils:newGuid()
	local guid = ""
	for _ = 1, 10 do
		local char = guidRandom:NextInteger(1, #guidChars)
		guid = guid .. guidChars[char]
	end
	return guid
end

--- Generates a new random name
---@return string name
function Utils:randomNames()
	local guid = ""
	local count = guidRandom:NextInteger(3, 6)
	for _ = 1, count do
		local char = guidRandom:NextInteger(1, #randomNamesChars)
		guid = guid .. randomNamesChars[char]
	end
	return guid
end

---==== debug ====---
function Utils:DebugPrint(...)
	if self.DEBUG then
		print(...)
	end
end

function Utils:DebugWarn(...)
	if self.DEBUG then
		warn(...)
	end
end


function Utils:GetModelFromDescendantPart(part)
	if part.Parent == workspace then
		return nil
	else
		if part.Parent:FindFirstChild("Humanoid") then
			return part.Parent
		else
			return self:GetModelFromDescendantPart(part.Parent)
		end
	end
end

function Utils:GetRandomElementFromVec2Table(tbl, remove)
	-- 计算二维表的总元素数
	local totalElements = 0
	for _, row in pairs(tbl) do
		for _ in pairs(row) do
			totalElements = totalElements + 1
		end
	end

	-- 如果表为空，返回 nil
	if totalElements == 0 then
		return nil
	end

	-- 生成一个随机索引
	local randomIndex = math.random(totalElements)

	-- 查找随机索引对应的元素
	local currentIndex = 0
	for i, row in tbl do
		for j, element in pairs(row) do
			currentIndex = currentIndex + 1
			if currentIndex == randomIndex then
				-- 如果 remove 为 true，则移除该元素
				if remove then
					row[j] = nil
					-- 如果当前行为空，则移除该行
					local rowIsEmpty = true
					for _ in pairs(row) do
						rowIsEmpty = false
						break
					end
					if rowIsEmpty then
						tbl[i] = nil
					end
				end
				return element
			end
		end
	end
end

--- Checks if two players are friends
---@param me Player
---@param plrId number
---@return boolean isFriend
function Utils:friendsWith(me, plrId)
	local isFriend = false
	local succ, report = pcall(function()
		isFriend = me:IsFriendsWith(plrId)
	end)
	return isFriend
end

---==== Zoom ====---
CheckPointInRegionTypeHandlers = {
	[1] = function(point, originPos, sizeArg, lookVec) --ball
		lookVec = lookVec or Vector3.zero
		local offset = sizeArg.offset or 0
		originPos = originPos + offset * lookVec
		return (point - originPos).Magnitude < sizeArg.radius
	end,
	[2] = function(point, originPos, sizeArg, lookVec) -- box
		lookVec = lookVec or Vector3.zero
		local offset = sizeArg.offset or 0
		originPos = originPos + offset * lookVec
		local regionCFrame = CFrame.new(originPos, originPos + lookVec)
		local localPoint = regionCFrame:PointToObjectSpace(point)

		return math.abs(localPoint.X) < sizeArg.X / 2
			and math.abs(localPoint.Z) < sizeArg.Y / 2
			and math.abs(localPoint.Y) < sizeArg.Z / 2
	end,
	[3] = function(point, originPos, sizeArg, lookVec) -- cylinder
		local offset = sizeArg.offset or 0
		lookVec = lookVec or Vector3.zero
		originPos = originPos + offset * lookVec
		local regionCFrame = CFrame.new(originPos) * CFrame.Angles(0, 0, math.rad(90))
		local localPoint = regionCFrame:PointToObjectSpace(point)
		local withinHeight = math.abs(localPoint.Y) < sizeArg.height / 2
		local distanceFromAxis = math.sqrt(localPoint.X ^ 2 + localPoint.Z ^ 2)
		local withinRadius = distanceFromAxis < sizeArg.radius

		return withinHeight and withinRadius
	end,
}

function Utils:CheckPointInRegion(point, originPos, regionType, sizeArg, lookVec)
	if regionType == "Ball" then
		return (point - originPos).Magnitude < sizeArg.radius
	elseif regionType == "Box" then
		local offset = sizeArg.offset or 0
		lookVec = lookVec or Vector3.new(0,1,0)
		originPos = originPos + offset * lookVec
		local regionCFrame = CFrame.new(originPos, originPos + lookVec)
		local localPoint = regionCFrame:PointToObjectSpace(point)

		return math.abs(localPoint.X) < sizeArg.X / 2
			and math.abs(localPoint.Z) < sizeArg.Y / 2
			and math.abs(localPoint.Y) < sizeArg.Z / 2
	elseif regionType == "Cylinder" then
		local regionCFrame = CFrame.new(originPos)
		local localPoint = regionCFrame:PointToObjectSpace(point)
		local withinHeight = math.abs(localPoint.Y) < sizeArg.height / 2
		local distanceFromAxis = math.sqrt(localPoint.X ^ 2 + localPoint.Z ^ 2)
		local withinRadius = distanceFromAxis < sizeArg.radius

		return withinHeight and withinRadius
	end
end

function Utils:GetInRegionNpcs(npcs, originPos, regionType, sizeArg, lookVec)
	local inReigionNpcs = {}
	local count = 0
	for npcId, npc in npcs do
		if CheckPointInRegionTypeHandlers[regionType](npc.model.PrimaryPart.Position, originPos, sizeArg, lookVec) then
			inReigionNpcs[npcId] = npc
			count = count + 1
		end
	end
	return inReigionNpcs, count
end

--- Get distance between two points
function Utils:checkDistance(p1, p2)
	return (p1 - p2).Magnitude
end

function Utils:CheckFloorDistance(p1, p2)
	if not p1 or not p2 then
		return math.huge
	end
	return (Vector2.new(p1.X, p1.Z) - Vector2.new(p2.X, p2.Z)).Magnitude
end

---==== Animation ====---
local aniIDToLength = {
}

function Utils:PrintAniIdToLength()
	print("aniIDToLength", aniIDToLength)
end

--- Play an animation
---@param RigModel Model Rig
---@param animationId string Animation
---@param Aniduration number Animation Duration
---@return AnimationTrack animationTrack
function Utils:PlayAnimation(RigModel, animationId, Aniduration, priority)
	if not animationId then
		error("animationId is nil")
		return
	end
	if typeof(animationId) == "number" then
		animationId = "rbxassetid://" .. tostring(animationId)
	end

	local Animator = RigModel:FindFirstChild("Humanoid") or RigModel:FindFirstChild("Animator", true)
	if Animator then
		local animation = Instance.new("Animation")
		animation.AnimationId = animationId
		local animationTrack = Animator:LoadAnimation(animation)
		local animeSpeed = 1
		animationTrack.Priority = priority or animationTrack.Priority
		if Aniduration then
			if Aniduration == -1 then
				animationTrack.Looped = true
			else
				animationTrack.Looped = false
				if not aniIDToLength[animationId] then
					repeat
						task.wait()
						Aniduration = math.max(32, Aniduration - 17)
					until animationTrack.Length ~= 0
					aniIDToLength[animationId] = animationTrack.Length
				end
				animeSpeed = aniIDToLength[animationId] * 1000 / Aniduration
			end
		end

		animationTrack:Play()
		animationTrack:AdjustSpeed(animeSpeed)
		return animationTrack
	else
		warn("Animator not found")
	end
end

---==== String ====---
function Utils:Split(str, sep)
	local result = {}
	local fieldstart = 1
	repeat
		local nexti = string.find(str, sep, fieldstart)
		table.insert(result, string.sub(str, fieldstart, nexti and nexti - 1))
		fieldstart = nexti and nexti + 1
	until fieldstart == nil
	return result
end

-- 格式化数字格式
function Utils:TransferNumber(number)
	if number < 1000 then
		return number
	elseif number < 1000000 then
		if number % 1000 >= 100 then
			return string.format("%.1f", number / 1000) .. "K"
		else
			return string.format("%.0f", number / 1000) .. "K"
		end
	elseif number < 1000000000 then
		if number % 1000000 >= 100000 then
			return string.format("%.1f", number / 1000000) .. "M"
		else
			return string.format("%.0f", number / 1000000) .. "M"
		end
	elseif number < 1000000000000 then
		if number % 1000000000 >= 100000000 then
			return string.format("%.1f", number / 1000000000) .. "B"
		else
			return string.format("%.0f", number / 1000000000) .. "B"
		end
	elseif number < 1000000000000000 then
		if number % 1000000000000 >= 100000000000 then
			return string.format("%.1f", number / 1000000000000) .. "T"
		else
			return string.format("%.0f", number / 1000000000000) .. "T"
		end
	elseif number < 1000000000000000000 then
		if number % 1000000000000000 >= 100000000000000 then
			return string.format("%.1f", number / 1000000000000000) .. "Q"
		else
			return string.format("%.0f", number / 1000000000000000) .. "Q"
		end
	end
end

--播放伤害飘字动画
function Utils:PlayHarmFloatingAnima(character, harm: number, isSkill: boolean, isCrit: boolean)
	-- isCrit = true
	local root = character.PrimaryPart
	local gui: BillboardGui = rs.Effects.AttackNum:Clone()
	gui.HealthNum.Size = UDim2.new(0, 0, 0, 0)
	local endSize = nil

	if isCrit then
		endSize = UDim2.new(0.8, 0, 0.8, 0)
		gui.HealthNum.UIGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
		})
		gui.HealthNum.CirtIcon.Visible = true
	else
		if not isSkill then
			endSize = UDim2.new(0.5, 0, 0.5, 0)
			gui.HealthNum.UIGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
			})
		else
			endSize = UDim2.new(0.5, 0, 0.5, 0)
			gui.HealthNum.UIGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 85, 0)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
			})
		end
		gui.HealthNum.CirtIcon.Visible = false
	end

	----播放受伤特效
	--local hitEffect=replicatedStorage.Effect.HitEffect:Clone()
	--hitEffect:SetPrimaryPartCFrame(CFrame.new(character.HumanoidRootPart.Position))
	--hitEffect.Parent=character
	--debris:AddItem(hitEffect,0.5)

	gui.HealthNum.Text = "-" .. Utils:TransferNumber(harm)
	gui.StudsOffset = gui.StudsOffset
		+ Vector3.new(math.random(-300, 300) * 0.01, math.random(-1, 1), math.random(-100, 100) * 0.01)
	gui.Parent = root

	local sizeTween = TweenService:Create(gui.HealthNum, TweenInfo.new(0.15, Enum.EasingStyle.Linear), {
		Size = endSize,
	})

	local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, false, 0)
	local billBoardTween = TweenService:Create(gui, tweenInfo, {
		StudsOffset = gui.StudsOffset + Vector3.new(math.random(-500, 500) * 0.01, 7, math.random(-200, 200) * 0.01),
	})

	sizeTween.Completed:Once(function()
		billBoardTween:Play()
	end)

	billBoardTween.Completed:Once(function()
		game.Debris:AddItem(billBoardTween)
		game.Debris:AddItem(gui, 0)
	end)
	sizeTween:Play()
end

---==== Character ====---
function Utils:SetCharacterModelToNoCollision(model)
	if not model or not model.PrimaryPart then
		return
	end
	model.PrimaryPart.CanCollide = false
	if model:FindFirstChild("Head") then
		model.Head.CanCollide = false
	end
end

function Utils:SetCharacterModelToCollision(model)
	if not model or not model.PrimaryPart then
		return
	end
	model.PrimaryPart.CanCollide = true

	if model:FindFirstChild("Head") then
		model.Head.CanCollide = true
	end
end

function Utils:SetModelCollisionGroup(model, groupName)
	for _, entryPart in model:GetDescendants() do
		if entryPart:IsA("BasePart") then
			entryPart.CollisionGroup = groupName
		end
	end
end


--- get the total mass of a part and all connected parts
---@param part Part part
---@return number total_mass
function Utils:GetTotalMass(part)
	if not part then
		return 0
	end
	local allConnected = part:GetConnectedParts(true)
	local total_mass = 0
	for _, v in pairs(allConnected) do
		total_mass = total_mass + v:GetMass()
	end
	return total_mass
end

function Utils:LookAtTarget(npcEntity, targetEntity)
	if not npcEntity or not targetEntity or not npcEntity.alive or not targetEntity.alive then
		return
	end
	local startPart = npcEntity.model.PrimaryPart
	local endPos = targetEntity.model.PrimaryPart.Position
	local bodyGyro = startPart:FindFirstChild("BodyGyro")
	if bodyGyro then
		bodyGyro.CFrame = CFrame.new(startPart.Position, endPos)
	else
		bodyGyro = Instance.new("BodyGyro")
		bodyGyro.MaxTorque = Vector3.new(0, 50000, 0)
		bodyGyro.P = 10000
		bodyGyro.CFrame = CFrame.new(startPart.Position, endPos)
		bodyGyro.Parent = startPart
	end
	game.Debris:AddItem(bodyGyro, 0.2)
	task.wait(0.2)
end

---==== Effect ====---
function Utils:EmitPE(effectModel, duration, destroyType)
	if effectModel:FindFirstChild("RotateModel") then
		local RotateEffectModel = effectModel:FindFirstChild("RotateModel")
		local RotateSpeed = RotateEffectModel:GetAttribute("RotateSpeed") or 1
		task.spawn(function()
			while effectModel and effectModel.Parent and RotateEffectModel do
				RotateEffectModel.PrimaryPart:WaitForChild("RotateWeld").C0 = RotateEffectModel.PrimaryPart:WaitForChild(
					"RotateWeld"
				).C0 * CFrame.Angles(0, 0.016 * RotateSpeed, 0)
				task.wait(0.016)
			end
		end)
	end
	if effectModel:GetAttribute("Animate") then
		for i, v in effectModel:GetChildren() do
			if v:GetAttribute("Ani_Id") then
				local Ani_Id = v:GetAttribute("Ani_Id")
				self:PlayAnimation(v, Ani_Id, -1)
			end
		end
	end
	local EmitCount = effectModel:GetAttribute("EmitCount") or 1
	for i, v in pairs(effectModel:GetDescendants()) do
		if v:IsA("ParticleEmitter") then
			v:Emit(EmitCount)
		end
	end
	if duration and duration > 0 then
		task.delay((duration / 1000) or 0.2, function()
			self:DestroyEffectModel(effectModel, destroyType)
		end)
	end
end

---瞬间爆发的特效
function Utils:EmitEffect(effectModel)
	for _, pe in effectModel:GetDescendants() do
		if pe:IsA("ParticleEmitter") then
			task.delay(pe:GetAttribute("EmitDelay") or 0, function()
				pe:Emit(pe:GetAttribute("EmitCount") or 0)
			end)
		end
	end
end


function Utils:AddEffect(model, effect, duration, destroyType, partName, offset)
	if effect then
		local weld = Instance.new("Weld")
		local alignPart = partName and model:FindFirstChild(partName, true)
			or model.HumanoidRootPart
			or model.PrimaryPart
		weld.Part0 = alignPart
		weld.Part1 = effect.PrimaryPart
		if offset then
			weld.C0 = offset
		end
		weld.Parent = effect
		self:EmitPE(effect, duration, destroyType)
		return effect
	else
		warn("effect is nil")
	end
end

function Utils:AddParticle(part, particleName, delay, duration)
	local pe = rs.Particles:FindFirstChild(particleName)
	if pe then
		local peClone = pe:Clone()
		peClone.Parent = part
		if delay then
			task.delay(math.random(0, 100) / 100, function()
				if peClone then
					peClone:Emit(1)
				end
			end)
		else
			peClone:Emit(1)
		end
		if duration and duration > 0 then
			task.delay(duration, function()
				if peClone then
					peClone.Enabled = false
					task.delay(peClone.Lifetime, function()
						peClone:Destroy()
					end)
				end
			end)
		end
	end
end

function Utils:ClosePE(effectModel)
	for i, v in pairs(effectModel:GetDescendants()) do
		if v:IsA("ParticleEmitter") then
			v.Enabled = false
		end
	end
end

DestroyModelHandler = {
	[1] = function(effectModel) -- 1秒之内缩小到0.01 然后销毁
		local shrinkProgress = 0
		local con
		con = RunService.PostSimulation:Connect(function(dt)
			shrinkProgress = shrinkProgress + math.ceil(dt * 1000)
			effectModel:ScaleTo(effectModel:GetScale() * math.max(1 - shrinkProgress / 1000, 0.01))
			if shrinkProgress >= 1000 or effectModel:GetScale() <= 0.01 then
				effectModel:Destroy()
				con:Disconnect()
			end
		end)
	end,
	[3] = function(effectModel) -- 关闭特效，一秒后销毁
		Utils:ClosePE(effectModel)
		task.delay(1, function()
			effectModel:Destroy()
		end)
	end,
	[2] = function(effectModel) -- 0.3秒之内缩小到0.01 然后销毁
		local shrinkProgress = 0
		local con
		con = RunService.PostSimulation:Connect(function(dt)
			shrinkProgress = shrinkProgress + math.ceil(dt * 1000)
			effectModel:ScaleTo(effectModel:GetScale() * math.max(1 - shrinkProgress / 1000, 0.01))
			if shrinkProgress >= 300 or effectModel:GetScale() <= 0.01 then
				effectModel:Destroy()
				con:Disconnect()
			end
		end)
	end,
	[4] = function(effectModel) -- 关闭特效，0.3秒后销毁
		Utils:ClosePE(effectModel)
		task.delay(0.3, function()
			effectModel:Destroy()
		end)
	end,
}

function Utils:DestroyEffectModel(effectModel, destroyType)
	if not effectModel then
		warn("effectModel is nil")
		return
	end

	if DestroyModelHandler[destroyType] then
		DestroyModelHandler[destroyType](effectModel)
	else
		effectModel:Destroy()
	end
end

function Utils:ScaleModel(model, start_scale, end_scale, duration)
	local startScale = start_scale * model:GetScale()
	local endScale = end_scale * model:GetScale()
	local process = 0
	local con
	con = RunService.PostSimulation:Connect(function(dt)
		process = process + math.ceil(dt * 1000)
		model:ScaleTo(startScale + (endScale - startScale) * process / duration)
		if process >= duration or not model:IsDescendantOf(workspace) then
			con:Disconnect()
			con = nil
		end
	end)
	return con
end

function Utils:ConvertEntitiesToIds(Entities)
	local ids = {}
	for _, entity in pairs(Entities) do
		table.insert(ids, entity.uid)
	end
	return ids
end

---==== Terrain ====---
local Lobby = workspace:WaitForChild("Lobby")
local terrainRayParams = RaycastParams.new()
terrainRayParams.FilterType = Enum.RaycastFilterType.Include
terrainRayParams.FilterDescendantsInstances = { Lobby }
function Utils:GetTerrainFloorPoint(startPoint)
	if not startPoint then
		return Vector3.new(0, -10000, 0)
	end
	local direction = Vector3.new(0, -1000, 0)
	local raycastResult = workspace:Raycast(startPoint + Vector3.new(0, 30, 0), direction, terrainRayParams)
	return raycastResult and raycastResult.Position or startPoint
end

function Utils:GetTargetPointOnFloor(startPoint, targetPoint)
	local direction = (targetPoint - startPoint).Unit * 1000
	local raycastResult = workspace:Raycast(startPoint + Vector3.new(0, 30, 0), direction, terrainRayParams)
	return raycastResult and raycastResult.Position
end

local normalHitIds = {
	-- 77984563537658,
	-- 81923307706463,
	-- 107946892115089,
	111105623951417,
}

EnemyHitHandlers = {
	NormalPunch = function(model)
		-- local primaryPart = model.PrimaryPart
		-- local backVec = -1 * primaryPart.CFrame.LookVector

		-- Utils:PlayAnimation(model, "rbxassetid://111105623951417", 1000, Enum.AnimationPriority.Action3)
		-- primaryPart.AssemblyLinearVelocity = backVec * 50
	end,
	Normal = function(npcEntity, targetEntity, critical)
		if not targetEntity.model or not npcEntity.model then
			return
		end
		-- if critical then
		-- 	targetEntity.hitIndex = 1
		-- 	local bodyVelocity = Instance.new("BodyVelocity")
		-- 	local lookVec = (targetEntity.model.PrimaryPart.Position - npcEntity.model.PrimaryPart.Position).Unit
		-- 	lookVec = (lookVec + Vector3.new(0, 0.5, 0)).Unit
		-- 	bodyVelocity.Parent = targetEntity.model.PrimaryPart
		-- 	bodyVelocity.MaxForce = Vector3.new(50000, 50000, 50000)
		-- 	bodyVelocity.Velocity = lookVec * 50
		-- 	bodyVelocity.P = 500000000
		-- 	if targetEntity.model:FindFirstChild("Humanoid") then
		-- 		targetEntity.model.Humanoid.WalkSpeed = 0
		-- 	end
		-- 	targetEntity.hitIndex = targetEntity.hitIndex or 1
		-- 	targetEntity.HitAniTrack = Utils:PlayAnimation(
		-- 		targetEntity.model,
		-- 		normalHitIds[targetEntity.hitIndex],
		-- 		500,
		-- 		Enum.AnimationPriority.Action
		-- 	)
		-- 	task.delay(0.3, function()
		-- 		if bodyVelocity then
		-- 			bodyVelocity.Velocity = Vector3.new(lookVec.X, -lookVec.Y, lookVec.Z) * 30
		-- 		end
		-- 		task.delay(0.2, function()
		-- 			if bodyVelocity then
		-- 				bodyVelocity:Destroy()
		-- 			end
		-- 			-- if targetEntity and targetEntity.model and targetEntity.model:FindFirstChild("Humanoid") and not targetEntity.stun then
		-- 			-- 	targetEntity.model.Humanoid.WalkSpeed = targetEntity.datas.move_speed
		-- 			-- end
		-- 		end)
		-- 	end)
		-- else
		if targetEntity.HitAniTrack and targetEntity.HitAniTrack.TimePosition < 0.75 then
			return
		elseif targetEntity.HitAniTrack then
			targetEntity.HitAniTrack:Stop()
		end
		targetEntity.hitIndex = targetEntity.hitIndex or 1
		targetEntity.HitAniTrack = Utils:PlayAnimation(
			targetEntity.model,
			normalHitIds[targetEntity.hitIndex],
			1000,
			Enum.AnimationPriority.Action
		)
		-- if targetEntity.model:FindFirstChild("Humanoid") then
		-- targetEntity.model.Humanoid.WalkSpeed = 0
		-- task.delay(0.5,function()
		-- 	if targetEntity and targetEntity.model and targetEntity.model:FindFirstChild("Humanoid") and not targetEntity.stun then
		-- 		-- targetEntity.model.Humanoid.WalkSpeed = targetEntity.datas.move_speed
		-- 	end
		-- end)
		-- end
		targetEntity.hitIndex = targetEntity.hitIndex + 1
		if targetEntity.hitIndex > #normalHitIds then
			targetEntity.hitIndex = 1
		end
		-- end
	end,
	Throw = function(model)
		-- local primaryPart = model.PrimaryPart
		-- local backVec = -1 * primaryPart.CFrame.LookVector

		-- Utils:PlayAnimation(model, "rbxassetid://111105623951417", 1000, Enum.AnimationPriority.Action3)
		-- primaryPart.AssemblyLinearVelocity = backVec * 10
	end,
}

local MyMath = require(script.MyMath)
Utils.math = MyMath

return Utils
