--// Utility module by yellowfats 2021 \\--

local module = {}

-- variables
local tweenservice = game:GetService("TweenService")

--// SHARED FUNCTIONS \\--

-- rounds a number to the given decimals (set numdecimals to 0 for an integer)
function module.RoundToDecimal(number, numdecimals)
	local mult = 10^(numdecimals or 0)
	return math.floor(number * mult + 0.5)/mult
end

function module.Distance(a,b)
	return (a-b).Magnitude
end

function module.Weld(part0, part1)
	local w = Instance.new("WeldConstraint")
	w.Part0 = part0
	w.Part1 = part1
	w.Parent = part0
end

function module.NoCollide(part0, part1)
	local w = Instance.new("NoCollisionConstraint")
	w.Part0 = part0
	w.Part1 = part1
	w.Parent = part0
end

function module.Rope(part0, part1, color)
	local a0 = Instance.new("Attachment", part0)
	a0.Name = "RopeA0"
	local a1 = Instance.new("Attachment", part1)
	a1.Name = "RopeA1"
	local distance = module.Distance(part0.Position, part1.Position)
	local r = Instance.new("RopeConstraint")
	r.Attachment0 = a0
	r.Attachment1 = a1
	r.Length = distance
	r.Color = color or Color3.fromRGB(0,0,0)
	r.Parent = part0
	return r
end

function module.Line(a,b, thickness, color) -- draw a part line from a to b
	local distance = module.Distance(a,b)
	local line = Instance.new("Part")
	if thickness == nil then thickness = 0.35 end;
	line.Size = Vector3.new(thickness,thickness,distance)
	line.CFrame = CFrame.new(a,b)
	line.Position = a+(line.CFrame.LookVector*distance/2)
	line.CanCollide = false
	line.CastShadow = false
	line.Anchored = true
	line.BrickColor = color or BrickColor.new("Institutional white")
	line.Parent = workspace
	return line
end

-- vector3:Lerp() but only uses 1 number instead of a vector3
function module.NumberLerp(number, numbergoal, increment)
	return number + (numbergoal - number) * increment
end

function module.Tween(instance, tweeninfo, goal)
	local tween = tweenservice:Create(instance, tweeninfo, goal)
	game.Debris:AddItem(tween, tweeninfo.Time+0.1)
	tween:Play()
end

function module.NumberTween(number, numbergoal, tweeninfo)
	local val = Instance.new("NumberValue")
	val.Value = number
	local tween = tweenservice:Create(val, tweeninfo, {Value = numbergoal})
	game.Debris:AddItem(tween, tweeninfo.Time+0.1)
	game.Debris:AddItem(val, tweeninfo.Time+0.1)
	tween:Play()
	return val
end

function module.ModelTween(model, cfgoal, tweeninfo)
	local val = Instance.new("CFrameValue")
	val.Value = model:GetPivot()
	local tween = tweenservice:Create(val, tweeninfo, {Value = cfgoal})
	game.Debris:AddItem(tween, tweeninfo.Time+0.1)
	game.Debris:AddItem(val, tweeninfo.Time+0.1)
	tween:Play()
	val.Changed:Connect(function()
		model:PivotTo(val.Value)
	end)
end

-- convert studs to meters (metric)
function module.StudsToMeters(distance)
	return distance*0.28
end

-- convert studs to feet (imperial)
function module.StudsToFeet(distance)
	return distance*0.92
end

-- check if a position is inside of a part
function module.IsInPart(part, position)
	if part then
		local startpos = part.Position
		local size = part.Size
		if (position.X > (startpos.X+size.X/2) or position.X < (startpos.X-size.X/2)) or (position.Z > (startpos.Z+size.Z/2) or position.Z < (startpos.Z-size.Z/2))  then
			return false
		else
			return true
		end
	else
		return false
	end
end

return module
