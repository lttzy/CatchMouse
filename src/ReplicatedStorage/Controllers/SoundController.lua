local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local BGMFolder = SoundService:WaitForChild("BGM")

local module = {}

local function PlayerDistanceSound(soundGroup:string,soundName:string,postion:Vector3)
	task.defer(function()
		if not game.Workspace:FindFirstChild("Sound") then
			local folder = Instance.new("Folder")
			folder.Name = "Sound"
			folder.Parent = game.Workspace
		end

		local part = game.Workspace.Sound:FindFirstChild(soundName.."Template") or Instance.new("Part")
		part.Name = soundName
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Anchored = true
		part.Transparency = 1
		part.Size = Vector3.new(1,1,1)
		part.Position = postion
		part.Parent = game.Workspace.Sound

		local audio = part:FindFirstChild(soundName) or SoundService[soundGroup][soundName]:Clone()
		audio.Parent = part
		audio:Play()
		task.wait(audio.TimeLength)
		part.Name = soundName.."Template"
	end)	
end

local function PlayGroupSound(soundGroup:string,soundName:string)
	task.defer(function()
		local audio = SoundService[soundGroup]:FindFirstChild(soundName.."Template") or SoundService[soundGroup][soundName]:Clone()
		audio.Name = soundName.."_Clone"
		audio.Parent = SoundService[soundGroup]
		audio:Play()
		task.wait(audio.TimeLength)
		audio.Name = soundName.."Template"
	end)
end

local BGMTable = {}
for _,v in pairs(BGMFolder:GetChildren()) do
	BGMTable[v.Name] = 1
end
local BGMListen = {}

local function CloseAllBGM()
	for _,v in pairs(BGMListen) do
		if v then v:Disconnect() v=nil end
	end
	for _,bgm in pairs(SoundService.BGM:GetDescendants()) do
		if bgm:IsA("Sound") and bgm.Playing == true then
			bgm:Stop()
		end
	end
end

local function PlayBGM(types)
	local BGMGroup = BGMFolder[types]:GetChildren()
	if BGMGroup[BGMTable[types]].Playing == true then return end
	CloseAllBGM()
	local nextBGM = BGMTable[types] + 1
	if nextBGM > #BGMTable then
		nextBGM = 1
	end
	BGMTable[types] = nextBGM
	BGMListen[types] = RunService.RenderStepped:Connect(function()
		if BGMGroup[BGMTable[types]].Playing == false then
			if BGMListen[types] then BGMListen[types]:Disconnect() BGMListen[types]=nil end
			PlayBGM(types)
		end
	end)
	BGMGroup[BGMTable[types]]:Play()
end

module.PlayGroupSound = PlayGroupSound
module.PlayerDistanceSound = PlayerDistanceSound
module.PlayBGM = PlayBGM

return module
