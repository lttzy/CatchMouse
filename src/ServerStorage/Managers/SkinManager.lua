local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RSource = ReplicatedStorage:WaitForChild("Source")
local CommonFunctions = RSource:WaitForChild("CommonFunctions")
local Communication = require(CommonFunctions:WaitForChild("Communication"))
local AttributeListener = require(CommonFunctions:WaitForChild("AttributeListener"))
local ServerStorage = game:GetService("ServerStorage")
local ConfigDatas = require(ReplicatedStorage.Source.Datas)
local Utils = require(ReplicatedStorage.Source.Utils)

local SkinManager = {
    Name = "SkinManager",
    SkinIDListeners = {},
}

function SkinManager.Activated()
    Players.PlayerAdded:Connect(function(player)
        if not SkinManager.SkinIDListeners[player.UserId] then
            SkinManager.SkinIDListeners[player.UserId] = AttributeListener.new(player, "SkinID", function(value)
                SkinManager.PlayerChangeSkinById(player, value)
            end)
        end
    end)

    for _, player in pairs(Players:GetPlayers()) do
        if not SkinManager.SkinIDListeners[player.UserId] then
            SkinManager.SkinIDListeners[player.UserId] = AttributeListener.new(player, "SkinID", function(value)
                SkinManager.PlayerChangeSkinById(player, value)
            end)
        end
    end

    Players.PlayerRemoving:Connect(function(player)
        if SkinManager.SkinIDListeners[player.UserId] then
            SkinManager.SkinIDListeners[player.UserId]:Destroy()
            SkinManager.SkinIDListeners[player.UserId] = nil
        end
    end)
end

function SkinManager.PlayerChangeSkinById(player,hero_id)
    if not hero_id then
        local cframe = player.Character.PrimaryPart.CFrame
        player:LoadCharacter()
        player.Character:SetPrimaryPartCFrame(cframe)
        return true
    end
    local heroData = ConfigDatas:GetConfigData("HeroInfos", hero_id)
    if not heroData then
        return false
    end
    SkinManager.PlayerChangeModel(player, heroData.hero_name)
    return true
end

function SkinManager.PlayerChangeModel(player,model_name)
    local oldCharacter = player.Character or player.CharacterAdded:Wait()
	oldCharacter.Parent = game.ReplicatedStorage
	local animateClone = oldCharacter:WaitForChild("Animate"):Clone()
	local cframe = oldCharacter:GetPrimaryPartCFrame()
	local newCharacterModel = game:GetService("ReplicatedStorage").HeroModels:WaitForChild(model_name):Clone()
	player.Character = newCharacterModel
	player.Character.Parent = workspace
	animateClone.Parent = player.Character
	player.Character:SetPrimaryPartCFrame(cframe)
	player.Character.Humanoid.WalkSpeed = 30
    player.Character.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
    player.Character.Humanoid.NameDisplayDistance = 100
    player.Character.Humanoid.DisplayName = player.Name
	oldCharacter:Destroy()
end

return SkinManager