local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local MyServerCenter = require(ServerStorage.MyServerCenter)
local Utils = require(ReplicatedStorage.Source.Utils)
local Data = require(ReplicatedStorage.Source.Datas.DailyRewardsConfig)

local DailyRewardManager = {}

function DailyRewardManager.HandlePlayerAdded(player)
    local dailyRewardData = MyServerCenter.GetManager("PlayerDataManager").GetPlayerData(player, "DailyRewards")

    local today = Utils:GetCurrentDate()
    if today ~= dailyRewardData.LastLoginDay then
        dailyRewardData.LastLoginDay = today
        dailyRewardData.Streak += 1
        if dailyRewardData.Streak > 7 then
            dailyRewardData.Streak = 1
            dailyRewardData.ClaimedStreak = {}
        end
        dailyRewardData.ClaimedStreak[#dailyRewardData.ClaimedStreak + 1] = dailyRewardData.Streak
    end
    MyServerCenter.GetManager("PlayerDataManager").SetPlayerData(player, "DailyRewards", dailyRewardData)
    -- MyServerCenter.GetManager("PlayerDataManager").SavePlayerData(player)
end

function DailyRewardManager.ClaimStreak(player, streak)
    local dailyRewardData = MyServerCenter.GetManager("PlayerDataManager").GetPlayerData(player, "DailyRewards")

    local idx = table.find(dailyRewardData.ClaimedStreak, streak)
    if idx then
        -- TODO: add reword
        local dailyRewardConfig = Data[streak]
        MyServerCenter.GetManager("RewardManager").Reward(player, dailyRewardConfig.rewardId)

        -- remove rewarded streak
        table.remove(dailyRewardData.ClaimedStreak, idx)

        -- update player data
        MyServerCenter.GetManager("PlayerDataManager").SetPlayerData(player, "DailyRewards", dailyRewardData)
        -- MyServerCenter.GetManager("PlayerDataManager").SavePlayerData(player)
    end
end

function DailyRewardManager.Activated()
    -- TODO 添加事件监听
end

return DailyRewardManager