local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local TeleportManager = {
    -- 创建一个BindableEvent作为失败信号
    OnTeleportFailed = Instance.new("BindableEvent")
}

-- TeleportInitFailed事件的处理函数
local function handleFailedTeleport(player, teleportResult, errorMessage, targetPlaceId, teleportOptions)
	warn(("[TeleportManager] Teleport failed for %s: %s (%s). Firing OnTeleportFailed signal."):format(player.Name, teleportResult.Name, errorMessage))
    -- 不再直接重试，而是发出失败信号，让上层逻辑（LobbyManager）来处理
	TeleportManager.OnTeleportFailed:Fire(player)
end

-- 核心传送函数
local function teleportAsync(placeId, players, teleportOptions)
	local success, result = pcall(function()
		-- 这里不需要返回值，因为成功发起不代表最终成功
		TeleportService:TeleportAsync(placeId, players, teleportOptions)
	end)

	if not success then
		warn(("[TeleportManager] TeleportAsync call failed immediately for players to placeId %d. Error: %s"):format(placeId, tostring(result)))
        -- 如果pcall本身就失败了，说明请求连发都没发出去，需要立即将所有玩家标记为失败
        for _, player in ipairs(players) do
            TeleportManager.OnTeleportFailed:Fire(player)
        end
	end
end

-- 公共接口：传送到公共服务器
function TeleportManager.Teleport(placeId, players, teleportOptions)
	task.spawn(function()
		teleportAsync(placeId, players, teleportOptions)
	end)
end

-- 公共接口：传送到私有（预留）服务器
function TeleportManager.TeleportToPrivateServer(placeId, players)
	local options = Instance.new("TeleportOptions")
	options.ShouldReserveServer = true
	task.spawn(function()
		teleportAsync(placeId, players, options)
	end)
end

function TeleportManager.Activated()
	-- 连接失败处理事件
	TeleportService.TeleportInitFailed:Connect(handleFailedTeleport)
end

return TeleportManager
