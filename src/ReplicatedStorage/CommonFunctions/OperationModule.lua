local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):wait()

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local ModuleScripts = ReplicatedStorage:WaitForChild("ModuleScripts")
local MyModule = ModuleScripts:WaitForChild("MyModule")
local ReadModule = require(MyModule:WaitForChild("ReadModule"))
local EffectsModule = require(MyModule:WaitForChild("EffectsModule"))

local module = {}

local dashPower = 120
local dashAnimId = 88589521471172

local MultiJumpListen = {
	stateChanged = nil,
	jumpRequest = nil,
}
local MultiJumpEffect = script:WaitForChild("MultiJumpEffect")
local JumpsNum = 0
local Mass = 0
local CanJumpAgain = false
local TIME_BETWEEN_JUMPS = .2
local MAX_JUMPS = 2

local Button_JumpsNum = 0
local Button_MultiJumpListen = {
	diedConn = nil,
	stateChangeConn = nil
}

local MultiJumpAnimId = 77107238893688

local function WorldMovingDirection(dir, MultiDirectional)
	local NewMultiDirectional = MultiDirectional or false
	local angle = math.atan2(dir.X, -dir.Z)--Gives Angle
	local quarterTurn 
	if NewMultiDirectional then--If you want 8 Directional
		quarterTurn =	math.pi/4
	else--You want 4 Directional
		quarterTurn =	math.pi/2--Only want degrees 0-180 [x/2 is 4 dimensional, x/4 is 8 dimensional]
	end

	local CurrectVector = nil
	local MovingDirection
	if dir == Vector3.new(0,0,0) then return Vector3.new(0,0,0) end--If they are standing still they are idle
	angle = -math.round(angle / quarterTurn) * quarterTurn

	local newX =math.round(-math.sin(angle))
	local newZ = math.round(-math.cos(angle))

	if math.abs(newX) <= 1e-10 then newX = 0 end
	if math.abs(newZ) <= 1e-10 then newZ = 0 end
	CurrectVector = Vector3.new(newX, 0, newZ)

	--Dictionary so you dont have to read numbers
	local Directions = {
		['Forward'] = Vector3.new(0, 0, -1),
		['Left'] = Vector3.new(-1, 0, 0),
		['Backwards'] = Vector3.new(0, 0, 1),
		['Right'] = Vector3.new(1, 0, 0)
	}

	if NewMultiDirectional then--If you want 8 directional movement
		Directions["ForwardLeft"] = Vector3.new(-1, 0, -1)
		Directions["ForwardRight"] = Vector3.new(1, 0, -1)
		Directions["BackwardLeft"] = Vector3.new(-1, 0, 1)
		Directions["BackwardRight"] = Vector3.new(1, 0, 1)
	end

	for Direction, Vector in Directions do
		-- Compare Directions
		if CurrectVector == Vector then--If players vector equals a vector in table Directions
			MovingDirection = Vector--Im not explaining this
		end
	end

	return MovingDirection
end

local function OnStateChanged(humanoid, oldState, newState)
	if Enum.HumanoidStateType.Landed == newState then
		humanoid.JumpPower = 120
		JumpsNum = 0
		CanJumpAgain = false
	elseif Enum.HumanoidStateType.Freefall == newState then
		wait(TIME_BETWEEN_JUMPS)
		humanoid.JumpPower = 90
		CanJumpAgain = true
	elseif Enum.HumanoidStateType.Jumping == newState then
		CanJumpAgain = false
		JumpsNum += 1
	end
end

local function OnJumpRequest(character,humanoid)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local animator = humanoid:FindFirstChild("Animator")
	if not rootPart or not animator then return end
	if CanJumpAgain and JumpsNum < MAX_JUMPS then
		local animTrack = ReadModule.LoadAnimation(animator,"DoubleJump",MultiJumpAnimId)
		local multiJumpEffect = rootPart:FindFirstChild("MultiJumpEffect")
		if not multiJumpEffect then
			multiJumpEffect = MultiJumpEffect.MultiJumpEffect:Clone()
			multiJumpEffect.Parent = rootPart
		end
		EffectsModule.EmitEffect(multiJumpEffect)
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		animTrack:Play()
		animTrack:AdjustSpeed(2)
	end
end

local function DashActivated()
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChild("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart then return end

	local dashTrack = ReadModule.LoadAnimation(humanoid.Animator,"Dash",dashAnimId)

	task.defer(function()
		local Direction = WorldMovingDirection(humanoid.MoveDirection,true)
		if dashTrack then dashTrack:Play() end	
		local pos = nil
		if Direction ~= Vector3.new(0,0,0) then
			pos = Direction * dashPower
		else
			pos = rootPart.CFrame.LookVector * dashPower
		end
		local Tween = TweenService:Create(rootPart,TweenInfo.new(.1,Enum.EasingStyle.Linear,Enum.EasingDirection.Out),{Velocity = pos})
		Tween:Play()
		Tween.Completed:Wait()
	end)
end

local function MultiJumpActivated()
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end
	MultiJumpListen.stateChanged = humanoid.StateChanged:Connect(function(oldState, newState)
		OnStateChanged(humanoid, oldState, newState)
	end)
	MultiJumpListen.jumpRequest = UserInputService.JumpRequest:Connect(function()
		OnJumpRequest(character,humanoid)
	end)
end

local function Button_MultiJumpActivated()
	local chara = player.Character
	local root = chara and chara.PrimaryPart
	local hum = chara and chara:FindFirstChildOfClass("Humanoid")
	if not chara or not hum or not root then return end
	if Button_JumpsNum >= 2 or hum:GetState() == Enum.HumanoidStateType.Jumping then return end
	hum:ChangeState(Enum.HumanoidStateType.Jumping)
	Button_JumpsNum += 1
	if Button_JumpsNum == 1 then
		Button_MultiJumpListen.diedConn = hum.Died:Once(function()
			if Button_JumpsNum ~= 0 then
				Button_JumpsNum = 0
			end
		end)
		Button_MultiJumpListen.stateChangeConn = hum.StateChanged:Connect(function(old, newState)
			if
				newState == Enum.HumanoidStateType.Landed or
				newState == Enum.HumanoidStateType.Running then
				if Button_JumpsNum ~= 0 then
					Button_JumpsNum = 0
				end
			end
		end)
	else
		if not hum:GetAttribute("IsRide") then
			local animation = ReadModule.LoadAnimation(hum.Animator,"MultiJump",MultiJumpAnimId)
			local multiJumpEffect = root:FindFirstChild("MultiJumpEffect")
			if not multiJumpEffect then
				multiJumpEffect = MultiJumpEffect.MultiJumpEffect:Clone()
				multiJumpEffect.Parent = root
			end
			EffectsModule.EmitEffect(multiJumpEffect)
			animation:Play()
			animation:AdjustSpeed(1.5)
		end
	end
end

local function MultiJumpStop()
	for _,v in pairs(MultiJumpListen) do
		if v then v:Disconnect() v = nil end
	end
	for _,v in pairs(Button_MultiJumpListen) do
		if v then v:Disconnect() v = nil end
	end
end

module.DashActivated = DashActivated
module.MultiJumpActivated = MultiJumpActivated
module.MultiJumpStop = MultiJumpStop
module.Button_MultiJumpActivated = Button_MultiJumpActivated

return module
