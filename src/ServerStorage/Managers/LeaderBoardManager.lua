-- LeaderBoardManager.lua

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Communication = require(ReplicatedStorage.Source.CommonFunctions.Communication)

-- 用于测试的数据版本，更改此值可重置所有排行榜
local DATA_VERSION = 1

local LEADERBOARD_CONFIG = {
    Wins = { DisplayName = "Wins" },
    Donated = { DisplayName = "Donated" },
}

local LeaderBoardManager = {
    _leaderboardDataCache = {},
}

function LeaderBoardManager._getStore(boardName)
    -- 在 DataStore 名称中包含版本号，便于重置
    return DataStoreService:GetOrderedDataStore(boardName .. "_Leaderboard_V" .. DATA_VERSION)
end

function LeaderBoardManager.Activated()
    Communication.OnServerInvoke("GetInitialLeaderboards", function(player)
        return LeaderBoardManager._leaderboardDataCache
    end)

    Communication.GetRemoteEvent("UpdateLeaderboards")
    LeaderBoardManager.UpdateAllLeaderboards()

    task.spawn(function()
        while task.wait(300) do -- 每5分钟
            LeaderBoardManager.UpdateAllLeaderboards()
        end
    end)
end

function LeaderBoardManager.UpdateAllLeaderboards()
    local allBoardsData = {
        Version = tick(), -- 使用 tick() 作为动态版本号
        Boards = {},
    }

    for boardName, config in pairs(LEADERBOARD_CONFIG) do
        local success, pages = pcall(function()
            local store = LeaderBoardManager._getStore(boardName)
            return store:GetSortedAsync(false, 100)
        end)

        if success then
            local boardData = {}
            local currentPage = pages:GetCurrentPage()
            for rank, data in ipairs(currentPage) do
                table.insert(boardData, {
                    UserId = tonumber(data.key),
                    Score = data.value,
                    Rank = rank,
                })
            end
            allBoardsData.Boards[boardName] = boardData
        else
            warn(string.format("Get leaderboard '%s' Failed: %s", boardName, tostring(pages)))
        end
    end
    LeaderBoardManager._leaderboardDataCache = allBoardsData
    Communication.FireAllClients("UpdateLeaderboards", LeaderBoardManager._leaderboardDataCache)
end

-- 全量更新玩家分数
function LeaderBoardManager.UpdatePlayerScore(player, boardName, newScore)
    if not LEADERBOARD_CONFIG[boardName] then
        warn("Invalid board name:", boardName)
        return
    end

    local success, err = pcall(function()
        local store = LeaderBoardManager._getStore(boardName)
        -- 使用 SetAsync 进行全量更新
        store:SetAsync(tostring(player.UserId), newScore)
    end)

    if not success then
        warn(string.format("Update Failed for player %d in board '%s' err: %s", player.UserId, boardName, tostring(err)))
    end
end

return LeaderBoardManager
