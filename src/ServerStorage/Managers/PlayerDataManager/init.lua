local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local MyServerCenter = require(ServerStorage.MyServerCenter)
local TableUtil = require(ReplicatedStorage.Source.CommonFunctions.TableUtil)
local PlayerDataModule = require(script.PlayerDataModule)
local PlayerDataManager = {
    _PlayerDatas = {},
    _PlayerLoaded = {}
}

function PlayerDataManager.LoadPlayerData(player)
    local data = MyServerCenter.GetManager("DataStoreManager"):GetPlayerStats(player.UserId)
    data = TableUtil.Reconcile(data or {}, PlayerDataModule)
    if data then
        PlayerDataManager._PlayerDatas[player.UserId] = data
    else
        PlayerDataManager._PlayerDatas[player.UserId] = {}
    end
    for k, _ in data.OwnedGamePasses do
        player:SetAttribute(k, true)
    end
    PlayerDataManager._PlayerLoaded[player.UserId] = true
end

function PlayerDataManager.AddGamePass(player, GamePassName)
    local data = PlayerDataManager._PlayerDatas[player.UserId]
    data.OwnedGamePasses[GamePassName] = true
    player:SetAttribute(GamePassName, true)
    return true
end

function PlayerDataManager.SavePlayerData(player)
    if not PlayerDataManager._PlayerLoaded[player.UserId] then
        return
    end
    local data = PlayerDataManager._PlayerDatas[player.UserId]
    if data then
        MyServerCenter.GetManager("DataStoreManager"):SavePlayerStats(player.UserId, data)
    end
end

function PlayerDataManager.GetPlayerData(player, key)
    local retryCount = 0
    repeat
        task.wait()
        retryCount = retryCount + 1
    until PlayerDataManager._PlayerLoaded[player.UserId] or retryCount > 60
    if retryCount > 60 then
        warn("GetPlayerData timed out for player "..tostring(player.UserId))
        return nil
    end

    return PlayerDataManager._PlayerDatas[player.UserId][key]
end

function PlayerDataManager.SetPlayerData(player, key, value)
    local retryCount = 0
    repeat
        task.wait()
        retryCount = retryCount + 1
    until PlayerDataManager._PlayerLoaded[player.UserId] or retryCount > 60
    if retryCount > 60 then
        warn("SetPlayerData timed out for player "..tostring(player.UserId))
        return nil
    end

    PlayerDataManager._PlayerDatas[player.UserId][key] = value
end

function PlayerDataManager.UpdatePlayerDonate(player, amount)
    local data = PlayerDataManager._PlayerDatas[player.UserId]
    data.DonatedRobux = data.DonatedRobux + amount
    return data.DonatedRobux
end

return PlayerDataManager