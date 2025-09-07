local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local MyServerCenter = require(ServerStorage.MyServerCenter)
local Data = require(ReplicatedStorage.Source.Datas.RewardsConfig)

local RewardManager = {}

function RewardManager.Reward(player, rewardId)
    local rewardConfig
    for _, config in ipairs(Data) do
        if config.id == rewardId then
            rewardConfig = config
            break
        end
    end

    if not rewardConfig then
        warn("Reward config not found for id", rewardId)
        return false
    end

    local rewardKey
    if rewardConfig.rewardType == 1 then
        rewardKey = "Coins"
    elseif rewardConfig.rewardType == 2 then
        rewardKey = "ReviveCoins"
    elseif rewardConfig.rewardType == 3 then
        rewardKey = "Wins"
    else
        return false
    end

    local success, err = pcall(function()
        local rewardValue = MyServerCenter.GetManager("PlayerDataManager").GetPlayerData(player, rewardKey)
        rewardValue += rewardConfig.rewardNum
        MyServerCenter.GetManager("PlayerDataManager").SetPlayerData(player, rewardKey, rewardValue)
        if rewardKey == "Coins" or rewardKey == "ReviveCoins" or rewardKey == "Wins" then
            player:SetAttribute(rewardKey, rewardValue)
        end
        if rewardKey == "Wins" then
            MyServerCenter.GetManager("LeaderBoardManager").UpdatePlayerScore(player, "Wins", rewardValue)
        end
    end)
    return success
end

return RewardManager