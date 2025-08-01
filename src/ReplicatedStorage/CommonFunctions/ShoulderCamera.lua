local CLASS = {}

--// SERVICES //--
local REPLICATED_STORAGE = game:GetService("ReplicatedStorage")
local PLAYERS_SERVICE = game:GetService("Players")
local RUN_SERVICE = game:GetService("RunService")
local USER_INPUT_SERVICE = game:GetService("UserInputService")

--// CONSTANTS //--

local LOCAL_PLAYER = PLAYERS_SERVICE.LocalPlayer
local MOUSE = LOCAL_PLAYER:GetMouse()

local UPDATE_UNIQUE_KEY = "OTS_CAMERA_SYSTEM_UPDATE"

--// VARIABLES //--
local Knit = require(REPLICATED_STORAGE.Packages.Knit)


--// CONSTRUCTOR //--

function CLASS.new()

	--// Events //--
	local activeCameraSettingsChangedEvent = Instance.new("BindableEvent")
	local characterAlignmentChangedEvent = Instance.new("BindableEvent")
	local mouseStepChangedEvent = Instance.new("BindableEvent")
	local shoulderDirectionChangedEvent = Instance.new("BindableEvent")
	local enabledEvent = Instance.new("BindableEvent")
	local disabledEvent = Instance.new("BindableEvent")
	----

	local dataTable = setmetatable(
		{
			--// Properties //--
			SavedCameraSettings = nil,
			SavedMouseBehavior = nil,
			ActiveCameraSettings = nil,
			HorizontalAngle = 0,
			VerticalAngle = 0,
			ShoulderDirection = 1,
			----

			--// Flags //--
			IsCharacterAligned = false,
			IsMouseSteppedIn = false,
			IsEnabled = false,
			----

			--// Events //--
			ActiveCameraSettingsChangedEvent = activeCameraSettingsChangedEvent,
			ActiveCameraSettingsChanged = activeCameraSettingsChangedEvent.Event,
			CharacterAlignmentChangedEvent = characterAlignmentChangedEvent,
			CharacterAlignmentChanged = characterAlignmentChangedEvent.Event,
			MouseStepChangedEvent = mouseStepChangedEvent,
			MouseStepChanged = mouseStepChangedEvent.Event,
			ShoulderDirectionChangedEvent = shoulderDirectionChangedEvent,
			ShoulderDirectionChanged = shoulderDirectionChangedEvent.Event,
			EnabledEvent = enabledEvent,
			Enabled = enabledEvent.Event,
			DisabledEvent = disabledEvent,
			Disabled = disabledEvent.Event,
			----

			--// Configurations //--
			VerticalAngleLimits = NumberRange.new(-80, 80),
			----

			--// Camera Settings //--
			CameraSettings = {

				DefaultShoulder = {
					FieldOfView = 70,
					Offset = Vector3.new(2.5, 4, 8),
					Sensitivity = 6,
					LerpSpeed = 0.9
				},

				ZoomedShoulder = {
					FieldOfView = 40,
					Offset = Vector3.new(1.5, 1.5, 6),
					Sensitivity = 1.5,
					LerpSpeed = 0.5
				}

			}
			----

		},
		CLASS
	)
	local proxyTable = setmetatable(
		{

		},
		{
			__index = function(self, index)
				return dataTable[index]
			end,
			__newindex = function(self, index, newValue)
				dataTable[index] = newValue
			end
		}
	)

	return proxyTable
end

--// FUNCTIONS //--

local function Lerp(x, y, a)
	return x + (y - x) * a
end

--// METHODS //--

--// //--
function CLASS:SetActiveCameraSettings(cameraSettings)
	assert(cameraSettings ~= nil, "OTS Camera System Argument Error: Argument 1 nil or missing")
	assert(typeof(cameraSettings) == "string", "OTS Camera System Argument Error: string expected, got " .. typeof(cameraSettings))
	assert(self.CameraSettings[cameraSettings] ~= nil, "OTS Camera System Argument Error: Attempt to set unrecognized camera settings " .. cameraSettings)
	if (self.IsEnabled == false) then
		warn("OTS Camera System Logic Warning: Attempt to change active camera settings without enabling OTS camera system")
		return
	end

	self.ActiveCameraSettings = cameraSettings
	self.ActiveCameraSettingsChangedEvent:Fire(cameraSettings)
end
function CLASS:SetCameraOrientationAbsolute(newCFrame)
    assert(typeof(newCFrame) == "CFrame", "OTS Camera System Argument Error: CFrame expected, got " .. typeof(newCFrame))
	
    local currentCamera = workspace.CurrentCamera
    local character = LOCAL_PLAYER.Character
    if not character then
        warn("无法设置镜头朝向：角色不存在")
        return
    end
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        warn("无法设置镜头朝向：角色缺少 HumanoidRootPart")
        return
    end

	if not self.IsEnabled then
		currentCamera.CFrame = CFrame.new(humanoidRootPart.Position + Vector3.new(0, 1.5, 0) - humanoidRootPart.CFrame.LookVector * 5, humanoidRootPart.Position)
		return
	end

    -- 从传入的 CFrame 获取 LookVector，并归一化
    local lookVector = newCFrame.LookVector.Unit
    -- 计算水平角：基于默认相机朝向为 (0,0,-1)，所以使用 -lookVector.X 与 -lookVector.Z
    local horizontalAngle = math.atan2(-lookVector.X, -lookVector.Z)
    -- 计算垂直角：直接利用 Y 分量（注意：当 Y 为正时视角上扬）
    local verticalAngle = math.asin(lookVector.Y)
    
    -- 更新内部角度，确保后续 Update 计算保持一致
    self.HorizontalAngle = horizontalAngle
    self.VerticalAngle = verticalAngle
    
    -- 使用当前激活的相机设置以及肩部偏移计算新的相机 CFrame
    local activeCameraSettings = self.CameraSettings[self.ActiveCameraSettings]
    local offset = activeCameraSettings.Offset
    offset = Vector3.new(offset.X * self.ShoulderDirection, offset.Y, offset.Z)
    
    local newCameraCFrame = CFrame.new(humanoidRootPart.Position) *
        CFrame.Angles(0, self.HorizontalAngle, 0) *
        CFrame.Angles(self.VerticalAngle, 0, 0) *
        CFrame.new(offset)
    
    -- 立即更新当前相机的 CFrame
    currentCamera.CFrame = newCameraCFrame
end


-- 在 CLASS 中新增方法 SetCameraOrientation
function CLASS:SetCameraOrientation(newCFrame)
    assert(typeof(newCFrame) == "CFrame", "OTS Camera System Argument Error: CFrame expected, got " .. typeof(newCFrame))
    -- 使用 CFrame:ToOrientation() 提取角度，这里返回的顺序是 (vertical, horizontal, roll)
    local vertical, horizontal, _ = newCFrame:ToOrientation()
    -- 直接设置水平和垂直角度（注意当前代码的 Update 中使用的是 self.HorizontalAngle 与 self.VerticalAngle）
    self.HorizontalAngle = horizontal
    self.VerticalAngle = vertical
	print("Set Camera Orientation:", self.HorizontalAngle, self.VerticalAngle)
end

function CLASS:SetCharacterAlignment(aligned)
	assert(aligned ~= nil, "OTS Camera System Argument Error: Argument 1 nil or missing")
	assert(typeof(aligned) == "boolean", "OTS Camera System Argument Error: boolean expected, got " .. typeof(aligned))
	if (self.IsEnabled == false) then
		warn("OTS Camera System Logic Warning: Attempt to change character alignment without enabling OTS camera system")
		return
	end

	local character = LOCAL_PLAYER.Character
	local humanoid = (character ~= nil) and (character:FindFirstChild("Humanoid"))
	if (humanoid == nil) then
		return
	end

	humanoid.AutoRotate = not aligned
	self.IsCharacterAligned = aligned
	self.CharacterAlignmentChangedEvent:Fire(aligned)
end

function CLASS:SetMouseStep(steppedIn)
	assert(steppedIn ~= nil, "OTS Camera System Argument Error: Argument 1 nil or missing")
	assert(typeof(steppedIn) == "boolean", "OTS Camera System Argument Error: boolean expected, got " .. typeof(steppedIn))
	if (self.IsEnabled == false) then
		warn("OTS Camera System Logic Warning: Attempt to change mouse step without enabling OTS camera system")
		return
	end

	self.IsMouseSteppedIn = steppedIn
	self.MouseStepChangedEvent:Fire(steppedIn)
	if (steppedIn == true) then
		USER_INPUT_SERVICE.MouseBehavior = Enum.MouseBehavior.LockCenter
	else
		USER_INPUT_SERVICE.MouseBehavior = Enum.MouseBehavior.Default
	end
end

function CLASS:SetShoulderDirection(shoulderDirection)
	assert(shoulderDirection ~= nil, "OTS Camera System Argument Error: Argument 1 nil or missing")
	assert(typeof(shoulderDirection) == "number", "OTS Camera System Argument Error: number expected, got " .. typeof(shoulderDirection))
	assert(math.abs(shoulderDirection) == 1, "OTS Camera System Argument Error: Attempt to set unrecognized shoulder direction " .. shoulderDirection)
	if (self.IsEnabled == false) then
		warn("OTS Camera System Logic Warning: Attempt to change shoulder direction without enabling OTS camera system")
		return
	end

	self.ShoulderDirection = shoulderDirection
	self.ShoulderDirectionChangedEvent:Fire(shoulderDirection)
end
----

--// //--
function CLASS:SaveCameraSettings()
	local currentCamera = workspace.CurrentCamera
	self.SavedCameraSettings = {
		FieldOfView = currentCamera.FieldOfView,
		CameraSubject = currentCamera.CameraSubject,
		CameraType = currentCamera.CameraType
	}
end

function CLASS:LoadCameraSettings()
	local currentCamera = workspace.CurrentCamera
	for setting, value in pairs(self.SavedCameraSettings) do
		currentCamera[setting] = value
	end
end
----

--// //--
function CLASS:Update()
	local currentCamera = workspace.CurrentCamera
	local activeCameraSettings = self.CameraSettings[self.ActiveCameraSettings]

	--// Address mouse behavior and camera type //--
	if (self.IsMouseSteppedIn == true) then
		USER_INPUT_SERVICE.MouseBehavior = Enum.MouseBehavior.LockCenter
	else
		USER_INPUT_SERVICE.MouseBehavior = Enum.MouseBehavior.Default
	end
	currentCamera.CameraType = Enum.CameraType.Scriptable
	---

	--// Address mouse input //--
	if not USER_INPUT_SERVICE.TouchEnabled then
		local mouseDelta = USER_INPUT_SERVICE:GetMouseDelta() * ( LOCAL_PLAYER:GetAttribute("Throwing") and 0 or activeCameraSettings.Sensitivity)

		self.HorizontalAngle -=  mouseDelta.X/currentCamera.ViewportSize.X
		self.VerticalAngle -= mouseDelta.Y/currentCamera.ViewportSize.Y
		self.VerticalAngle = math.rad(math.clamp(math.deg(self.VerticalAngle), self.VerticalAngleLimits.Min, self.VerticalAngleLimits.Max))
		----
	end

	local character = LOCAL_PLAYER.Character
	local humanoidRootPart = (character ~= nil) and (character:FindFirstChild("HumanoidRootPart"))
	if (humanoidRootPart ~= nil) then

		--// Lerp field of view //--
		currentCamera.FieldOfView = Lerp(
			currentCamera.FieldOfView, 
			activeCameraSettings.FieldOfView, 
			activeCameraSettings.LerpSpeed
		)
		----

		--// Address shoulder direction //--
		local offset = activeCameraSettings.Offset
		offset = Vector3.new(offset.X * self.ShoulderDirection, offset.Y, offset.Z)
		----

		--// Calculate new camera cframe //--
		local newCameraCFrame = CFrame.new(humanoidRootPart.Position) *
			CFrame.Angles(0, self.HorizontalAngle, 0) *
			CFrame.Angles(self.VerticalAngle, 0, 0) *
			CFrame.new(offset)

		newCameraCFrame = currentCamera.CFrame:Lerp(newCameraCFrame, activeCameraSettings.LerpSpeed)
		----

		--// Raycast for obstructions //--
		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = {character, workspace}
		raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
		local raycastResult = workspace:Raycast(
			humanoidRootPart.Position,
			newCameraCFrame.p - humanoidRootPart.Position,
			raycastParams
		)
		----

		--// Address obstructions if any //--
		if (raycastResult ~= nil) then
			local obstructionDisplacement = (raycastResult.Position - humanoidRootPart.Position)
			local obstructionPosition = humanoidRootPart.Position + (obstructionDisplacement.Unit * (obstructionDisplacement.Magnitude - 0.1))
			local x,y,z,r00,r01,r02,r10,r11,r12,r20,r21,r22 = newCameraCFrame:components()
			newCameraCFrame = CFrame.new(obstructionPosition.x, obstructionPosition.y, obstructionPosition.z, r00, r01, r02, r10, r11, r12, r20, r21, r22)
		end
		----

		--// Address character alignment //--
		if (self.IsCharacterAligned == true) then
			local newHumanoidRootPartCFrame = CFrame.new(humanoidRootPart.Position) *
				CFrame.Angles(0, self.HorizontalAngle, 0)
			humanoidRootPart.CFrame = humanoidRootPart.CFrame:Lerp(newHumanoidRootPartCFrame, activeCameraSettings.LerpSpeed/2)
		end
		----

		currentCamera.CFrame = newCameraCFrame

	else
		self:Disable()
	end
end

function CLASS:ConfigureStateForEnabled()
	self:SaveCameraSettings()
	self.SavedMouseBehavior = USER_INPUT_SERVICE.MouseBehavior
	self:SetActiveCameraSettings("DefaultShoulder")
	self:SetCharacterAlignment(true)
	self:SetMouseStep(true)
	self:SetShoulderDirection(1)

	--// Calculate angles //--
	local cameraCFrame = workspace.CurrentCamera.CFrame
	local x, y, z = cameraCFrame:ToOrientation()
	local horizontalAngle = y
	local verticalAngle = x
	----

	self.HorizontalAngle = horizontalAngle
	self.VerticalAngle = verticalAngle
end

function CLASS:ConfigureStateForDisabled()
	self:LoadCameraSettings()
	USER_INPUT_SERVICE.MouseBehavior = self.SavedMouseBehavior
	self:SetActiveCameraSettings("DefaultShoulder")
	self:SetCharacterAlignment(false)
	self:SetMouseStep(false)
	self:SetShoulderDirection(1)
	self.HorizontalAngle = 0
	self.VerticalAngle = 0
end

function CLASS:Enable()
	if (self.IsEnabled == true) then
		return
	end
	-- assert(self.IsEnabled == false, "OTS Camera System Logic Error: Attempt to enable without disabling")

	self.IsEnabled = true
	self.EnabledEvent:Fire()
	self:ConfigureStateForEnabled()

	USER_INPUT_SERVICE.MouseIconEnabled = false
	RUN_SERVICE:BindToRenderStep(
		UPDATE_UNIQUE_KEY,
		Enum.RenderPriority.Camera.Value - 10,
		function()
			if (self.IsEnabled == true) then
				self:Update()
			end
		end
	)
	self.TouchCon = USER_INPUT_SERVICE.TouchMoved:Connect(function(touch, gameProcessedEvent)
		self.UIController = self.UIController or Knit.GetController("UIController")
        if not self.UIController:IsPressOnThrowBtn(touch.Position) and gameProcessedEvent then
            return
        end
		local Delta = touch.Delta * self.CameraSettings[self.ActiveCameraSettings].Sensitivity
		self.HorizontalAngle -= Delta.X/workspace.CurrentCamera.ViewportSize.X
		self.VerticalAngle -= Delta.Y/workspace.CurrentCamera.ViewportSize.Y
		self.VerticalAngle = math.rad(math.clamp(math.deg(self.VerticalAngle), self.VerticalAngleLimits.Min, self.VerticalAngleLimits.Max))
    end)

end

function CLASS:Disable()
	if (self.IsEnabled == false) then
		return
	end
	-- assert(self.IsEnabled == true, "OTS Camera System Logic Error: Attempt to disable without enabling")
	USER_INPUT_SERVICE.MouseIconEnabled = true
	self:ConfigureStateForDisabled()
	self.IsEnabled = false
	self.DisabledEvent:Fire()

	self.TouchCon:Disconnect()
	RUN_SERVICE:UnbindFromRenderStep(UPDATE_UNIQUE_KEY)
end
----

--// INSTRUCTIONS //--

CLASS.__index = CLASS

local singleton = CLASS.new()

-- USER_INPUT_SERVICE.InputBegan:Connect(function(inputObject, gameProcessedEvent)
-- 	if (gameProcessedEvent == false) and (singleton.IsEnabled == true) then
-- 		if (inputObject.KeyCode == Enum.KeyCode.Q) then
-- 			singleton:SetShoulderDirection(-1)
-- 		elseif (inputObject.KeyCode == Enum.KeyCode.E) then
-- 			singleton:SetShoulderDirection(1)
-- 		end
-- 		-- if (inputObject.UserInputType == Enum.UserInputType.MouseButton2) then
-- 		-- 	singleton:SetActiveCameraSettings("ZoomedShoulder")
-- 		-- end

-- 		if (inputObject.KeyCode == Enum.KeyCode.LeftControl) then
-- 			if (singleton.IsEnabled == true) then
-- 				singleton:SetMouseStep(not singleton.IsMouseSteppedIn)
-- 			end
-- 		end
-- 	end
-- end)

-- USER_INPUT_SERVICE.InputEnded:Connect(function(inputObject, gameProcessedEvent)
-- 	if (gameProcessedEvent == false) and (singleton.IsEnabled == true) then
-- 		if (inputObject.UserInputType == Enum.UserInputType.MouseButton2) then
-- 			singleton:SetActiveCameraSettings("DefaultShoulder")
-- 		end
-- 	end
-- end)


return singleton