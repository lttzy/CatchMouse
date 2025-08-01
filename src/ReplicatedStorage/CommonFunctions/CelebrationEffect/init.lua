local RunService = game:GetService("RunService")
local CelebrationEffectPart = script:WaitForChild("CelebrationEffect")
local Camera = workspace.CurrentCamera

local screenCorners = {
	[0] = Vector2.new(0.5, 0.5),
	[1] = Vector2.new(0, 0), -- 左上
	[2] = Vector2.new(1, 0), -- 右上
	[3] = Vector2.new(0, 1), -- 左下
	[4] = Vector2.new(1, 1), -- 右下
}

local function get3DPosition(screenPoint)
	local ray = Camera:ViewportPointToRay(screenPoint.X * Camera.ViewportSize.X, screenPoint.Y * Camera.ViewportSize.Y)
	-- 假设你想要在距离摄像机10个单位的位置找到3D点
	local distance = 10
	local worldPoint = ray.Origin + ray.Direction * distance
	return worldPoint
end

local cornerParts = {}
for i = 1, 4 do
	local part = CelebrationEffectPart:Clone()
	part.Size = Vector3.new(0.1, 0.1, 0.1)
	part.CanCollide = false
	part.Parent = Camera
	part.Transparency = 1
	part.Name = i
	table.insert(cornerParts, part)
end

local module = {}

local Activated = function()
    module.activing = true
    if module.StepCon then
        module.StepCon:Disconnect()
    end
    module.StepCon = RunService:BindToRenderStep("CameraCornerPartFollow", 100, function(dt)
        if not Camera then
            return
        end
        for i, part in ipairs(cornerParts) do
            if i > 4 then
                break
            end -- 只处理前四个Part
            part.CFrame = CFrame.new(get3DPosition(screenCorners[i]), get3DPosition(screenCorners[0]))
        end
    end)
end

local function StopCelebrate()
	for _, part in pairs(cornerParts) do
		for _, entry in pairs(part:GetDescendants()) do
			if entry:IsA("ParticleEmitter") then
				entry.Enabled = false
			end
		end
	end
end

local function Celebrate()
    if not module.activing then
        module.Activated()
    end
	for _, part in pairs(cornerParts) do
		for _, entry in pairs(part:GetDescendants()) do
			if entry:IsA("ParticleEmitter") then
				entry.Enabled = true
			end
		end
	end
	task.delay(1, StopCelebrate)
end

module.Activated = Activated
module.Celebrate = Celebrate

return module