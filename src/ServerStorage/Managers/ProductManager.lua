local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local ServerStorage = game:GetService("ServerStorage")

local Datas = require(ReplicatedStorage.Source.Datas)
local LobbyPlaceID = 73815599780531

local Communication = require(ReplicatedStorage.Source.CommonFunctions.Communication)
local yhfServerCenter = require(ServerStorage.MyServerCenter)

local Product = {
	GiftTable = {}
}

local purchaseHistoryStore = DataStoreService:GetDataStore("PurchaseHistory")

-- 表格相关设置，含有产品 ID 和处理购买操作的函数
local productFunctions = {}
-- 装饰物相关

-- 核心 ‘ProcessReceipt’ 回调函数
local function processReceipt(receiptInfo)
	--self.GAService:ProcessReceiptCallback(receiptInfo)
	-- 检查数据存储，判断产品是否已经发放  
	local playerProductKey = receiptInfo.PlayerId .. "_" .. receiptInfo.PurchaseId
	local purchased = false
	local success, errorMessage = pcall(function()
		purchased = purchaseHistoryStore:GetAsync(playerProductKey)
	end)

	-- 如果购买流程被记录下来，则说明产品已发放
	if success and purchased then
		--print("记录")
		return Enum.ProductPurchaseDecision.PurchaseGranted
	elseif not success then
		error("Data store error:" .. errorMessage)
	end

	-- 找到服务器中进行购买的玩家
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		-- 玩家可能离开了游戏
		-- 玩家返回游戏时将会再次调用回调函数
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- 从上面的 ‘productFunctions’ 表格中查找处理函数
	local handler = productFunctions[receiptInfo.ProductId]
	
	-- 调用处理函数并捕捉错误
	local success, result = pcall(handler, receiptInfo, player)
	if not success or not result then
		warn("Error occurred while processing a product purchase")
		print("\nProductId:", receiptInfo.ProductId)
		print("\nPlayer:", player)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	--在数据存储中记录好交易内容，确保同样的产品不会被再次发放
	local success, errorMessage = pcall(function()
		purchaseHistoryStore:SetAsync(playerProductKey, true)
	end)
	if not success then
		error("Cannot save purchase data:" .. errorMessage)
	end
	-- 重要：告知 Roblox 购买流程已被成功处理
	return Enum.ProductPurchaseDecision.PurchaseGranted
end
-- 设置回调函数，这个设置只能由服务器上的一个脚本进行一次！ 
MarketplaceService.ProcessReceipt = processReceipt


local function onPromptPurchaseFinished(UserId, productId, isPurchased, receiptInfo)
	if productId == 3316848392 and not isPurchased then
		task.wait(3)
		yhfServerCenter.GetManager("TeleportManager").Teleport(LobbyPlaceID, {Players:GetPlayerByUserId(UserId)})
	end
end

MarketplaceService.PromptProductPurchaseFinished:Connect(onPromptPurchaseFinished)

-- game.Players.PlayerAdded:Connect(function(player)
-- 	if MarketplaceService:UserOwnsGamePassAsync(player.UserId, 1176140222) then
-- 		PlayerDataManager.SavePlayerBoughtGamePass(player.UserId, 1176140222)
-- 	end
-- end)

-- MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player,punchasePassID,purchaseSuccess)
-- 	if purchaseSuccess == true and punchasePassID == 1176140222 then
-- 		PlayerDataManager.SavePlayerBoughtGamePass(player.UserId, punchasePassID)
-- 	end
-- end)


-- local function BuyShop(userId,types,id,num)
-- 	if types == 1 then
-- 		PlayerDataManager.AddSeedToBackpack(userId,id,num)
-- 	elseif types == 2 then
-- 		PlayerDataManager.AddCoinsToBackpack(userId, num)
-- 	elseif types == 4 then
-- 		PlayerDataManager.AddToolToBackpack(userId, id, num)
-- 	end
-- end

--购买种子
-- for id,info in pairs(StoreConfig) do
-- 	if info.productID then
-- 		productFunctions[info.productID] = function(receipt, player)
-- 			if Product.GiftTable[player] then
-- 				if receipt.ProductId == Product.GiftTable[player].productId then
-- 					warn("Gift - "..receipt.ProductId.."- "..player.UserId.." tO ".. Product.GiftTable[player].recipient.UserId)
-- 					if info.type == 1 then
-- 						PlayerDataManager.AddSeedToBackpack(Product.GiftTable[player].recipient.UserId,info.itemID,1)
-- 					elseif info.type == 2 then
-- 						PlayerDataManager.AddToolToBackpack(Product.GiftTable[player].recipient.UserId,info.itemID,1)
-- 					elseif info.type == 3 then
-- 						BackpackManager.AddAnimalEggToBackpack(Product.GiftTable[player].recipient.UserId, info.itemID, 1)
-- 					end
-- 					yhfServerCenter.GetManager("BadgeManager").UpdateBadgeData(player, "SendFriendSeed", 1)
-- 				end
-- 			else
-- 				if info.type == 1 then
-- 					PlayerDataManager.AddSeedToBackpack(player.UserId,info.itemID,1)
-- 				elseif info.type == 2 then
-- 					PlayerDataManager.AddToolToBackpack(player.UserId,info.itemID,1)
-- 				elseif info.type == 3 then
-- 					BackpackManager.AddAnimalEggToBackpack(player.UserId, info.itemID, 1)
-- 				end
-- 			end
-- 			return true
-- 		end
-- 	end
-- end

-- grow all
-- productFunctions[3273544553] = function(receipt, player)
-- 	--warn(receipt)
-- 	PlayerDataManager.MatureAllTrees(player.UserId)
-- 	return true
-- end

-- -- pick all
-- productFunctions[3282280453] = function(receipt, player)
-- 	PlayerDataManager.HarvestAllRipeFruits(player.UserId)
-- 	return true
-- end

-- steal
-- productFunctions[3273542213] = function(receipt, player)
-- 	PlayerDataManager.ExecuteSteal(player.UserId)
-- 	yhfServerCenter.GetManager("BadgeManager").UpdateBadgeData(player, "StealFruit", 1)
-- 	return true
-- end

--local productIdToDecorationId = {}
-- decoration
-- local DecorationConfigs = Datas:GetConfigDatas("DecorationsConfig")
-- for id, info in DecorationConfigs do
-- 	if info.productID then
-- 		--productIdToDecorationId[info.productID] = id
-- 		productFunctions[info.productID] = function(receipt, player)
-- 			DecorationManager.AddDecorationToPlayer(player, tostring(id))
-- 			return true
-- 		end
-- 	end
-- end

-- for id,info in pairs(RobuxStoreConfig) do
-- 	if info.types == 1 or not info.productID then continue end
-- 	productFunctions[info.productID] = function(receipt, player)
-- 		for _,v in pairs(info.reward) do
-- 			BuyShop(player.UserId,v.types,v.id,v.num)
-- 		end
-- 		if info.types == 2 or info.types == 3 then
-- 			Communication.FireClient("ForeverGiftBuyCompleted",player,id)
-- 			ServerCenter.GetSignal("UpdateForeverPack"):Fire(player.UserId,info.id)
-- 		end
-- 		return true
-- 	end
-- end

productFunctions[3316848392] = function(receipt, player)
	return yhfServerCenter.GetManager("BattleManager").PlayerReborn(player)
end

productFunctions[3317561025] = function(receipt, player) -- 加速
	return yhfServerCenter.GetManager("PlayerDataManager").AddGamePass(player, "ExtraSpeed")
end

productFunctions[3319647571] = function(receipt, player) -- 二段跳
	return yhfServerCenter.GetManager("PlayerDataManager").AddGamePass(player, "MultiJump")
end

productFunctions[3319880895] = function(receipt, player) -- donate 10r
	local newDonated = yhfServerCenter.GetManager("PlayerDataManager").UpdatePlayerDonate(player, 10)
	if newDonated then
		yhfServerCenter.GetManager("LeaderBoardManager").UpdatePlayerScore(player, "Donated", newDonated)
		return true
	else
		warn("Update Donated Failed for player "..tostring(player.UserId))
		return false
	end
end

productFunctions[3319881104] = function(receipt, player) -- donate 50r
	local newDonated = yhfServerCenter.GetManager("PlayerDataManager").UpdatePlayerDonate(player, 50)
	if newDonated then
		yhfServerCenter.GetManager("LeaderBoardManager").UpdatePlayerScore(player, "Donated", newDonated)
		return true
	else
		warn("Update Donated Failed for player "..tostring(player.UserId))
		return false
	end
end

productFunctions[3319881231] = function(receipt, player) -- donate 100r
	local newDonated = yhfServerCenter.GetManager("PlayerDataManager").UpdatePlayerDonate(player, 100)
	if newDonated then
		yhfServerCenter.GetManager("LeaderBoardManager").UpdatePlayerScore(player, "Donated", newDonated)
		return true
	else
		warn("Update Donated Failed for player "..tostring(player.UserId))
		return false
	end
end

productFunctions[3319881365] = function(receipt, player) -- donate 500r
	local newDonated = yhfServerCenter.GetManager("PlayerDataManager").UpdatePlayerDonate(player, 500)
	if newDonated then
		yhfServerCenter.GetManager("LeaderBoardManager").UpdatePlayerScore(player, "Donated", newDonated)
		return true
	else
		warn("Update Donated Failed for player "..tostring(player.UserId))
		return false
	end
end

productFunctions[3319881485] = function(receipt, player) -- donate 1000r
	local newDonated = yhfServerCenter.GetManager("PlayerDataManager").UpdatePlayerDonate(player, 1000)
	if newDonated then
		yhfServerCenter.GetManager("LeaderBoardManager").UpdatePlayerScore(player, "Donated", newDonated)
		return true
	else
		warn("Update Donated Failed for player "..tostring(player.UserId))
		return false
	end
end

productFunctions[3319881668] = function(receipt, player) -- donate 10000r
	local newDonated = yhfServerCenter.GetManager("PlayerDataManager").UpdatePlayerDonate(player, 10000)
	if newDonated then
		yhfServerCenter.GetManager("LeaderBoardManager").UpdatePlayerScore(player, "Donated", newDonated)
		return true
	else
		warn("Update Donated Failed for player "..tostring(player.UserId))
		return false
	end
end

function Product:Init()
	-- Communication.OnServerInvoke("Gift",function(trigger,recipient,productId)
	-- 	if not recipient or not recipient:IsA("Player") then
	-- 		Product.GiftTable[trigger] = nil
	-- 	else
	-- 		Product.GiftTable[trigger] = {recipient = recipient,productId = productId}
	-- 	end
	-- 	return true
	-- end)

	-- Communication.OnServerInvoke("GetFreeShop",function(player,shopId)
	-- 	local shopInfo = RobuxStoreConfig[shopId]
	-- 	if not shopInfo then return false end
	-- 	for _,v in pairs(shopInfo.reward) do
	-- 		BuyShop(player.UserId,v.types,v.id,v.num)
	-- 	end
	-- 	ServerCenter.GetSignal("UpdateForeverPack"):Fire(player.UserId,shopInfo.id)
	-- 	return true
	-- end)

	-- Communication.OnServerInvoke("CheckAutoFishingPass",function(player)
	-- 	return PlayerDataManager.CheckPlayerOwnedGamePass(player.UserId, 1176140222)
	-- end)

	Communication.OnServerEvent("BuyGamePass",function(player,gamePassId)
		local hasPass = false
		local success,message = pcall(function()
			hasPass = MarketplaceService:UserOwnsGamePassAsync(player.UserId,gamePassId)
		end)
		if hasPass then
			MarketplaceService:PromptGamePassPurchase(player,gamePassId)
		else
			MarketplaceService:PromptGamePassPurchase(player,gamePassId)
		end
	end)
end

function Product:PlayerRemoving(player)
	Product.GiftTable[player] = nil
end

return Product