local RunService = game:GetService("RunService")
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

module.ConnectionBeam = ConnectionBeam
module.RemoveBeam = RemoveBeam
module.Typewrite = Typewrite

return module