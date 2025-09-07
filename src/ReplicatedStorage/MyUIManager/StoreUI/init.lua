--!strict
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local UIElement = require(script.Parent.UIElement)
local UITemplate = require(script.Parent.UITemplate)
local ConfigDatas = require(ReplicatedStorage.Source.Datas)
local StoreConfig = ConfigDatas:GetConfigDatas("StoreConfig")
local UpgradesConfig = ConfigDatas:GetConfigDatas("UpgradesConfig")

local ClientCenter = require(ReplicatedStorage.Source.ClientCenter)
local AttributeListener = require(ReplicatedStorage.Source.CommonFunctions.AttributeListener)

local StoreUI = UITemplate:Extend("StoreUI")

function StoreUI:Init(Name)
	UITemplate.Init(self, Name)
	self:_UpdateAllLists()
end

function StoreUI:_InitConnections()
	ClientCenter.GetSignal("ShowStore"):Connect(function()
		self:Show()
	end)
end

function StoreUI:_InitRefrences()
	local TweenService = game:GetService("TweenService")

	self.MainFrame = UIElement.new(self.Gui:WaitForChild("MainFrame"), UIElement.Enum.UIType.Frame)
	self.CloseBtn = UIElement.new(self.MainFrame:GetChild("CloseBtn"), UIElement.Enum.UIType.Image, nil, {
		MouseButton1Click = function()
			self:Hide()
		end,
	})

	local contentFrame = UIElement.new(self.MainFrame:GetChild("ContentFrame"), UIElement.Enum.UIType.Frame)
	self.TopBar = UIElement.new(contentFrame:GetChild("TopBar"), UIElement.Enum.UIType.Frame)
	self.ShopFrame = UIElement.new(contentFrame:GetChild("Shop"), UIElement.Enum.UIType.Frame)

	self.CategoryFrames = {
		Passes = self.ShopFrame:GetChild("Passes"),
		Upgrades = self.ShopFrame:GetChild("Upgrades"),
		Coins = self.ShopFrame:GetChild("Coins"),
	}

	local function switchCategory(categoryName)
		local layout = self.ShopFrame.instance:FindFirstChildOfClass("UIListLayout")
		if not layout then
			warn("StoreUI: UIListLayout not found in ShopFrame.")
			return
		end

		local order = { "Passes", "Upgrades", "Coins" }
		local targetY = 0
		local found = false

		for _, name in ipairs(order) do
			if name == categoryName then
				found = true
				break
			end
			local frame = self.CategoryFrames[name]
			if frame then
				targetY += frame.AbsoluteSize.Y + layout.Padding.Offset
			end
		end

		if not found then
			return
		end

		if math.abs(self.ShopFrame.instance.CanvasPosition.Y - targetY) < 1 then
			return
		end

		local targetPosition = Vector2.new(0, targetY)
		local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local tween = TweenService:Create(self.ShopFrame.instance, tweenInfo, { CanvasPosition = targetPosition })
		tween:Play()
	end

	self.TopBar_Passes = UIElement.new(self.TopBar:GetChild("Passes"), UIElement.Enum.UIType.Frame)
	self.TopBar_PassesBtn = UIElement.new(self.TopBar_Passes:GetChild("PressBtn"), UIElement.Enum.UIType.Text, nil, {
		MouseButton1Click = function()
			switchCategory("Passes")
		end,
	})

	self.TopBar_Upgrades = UIElement.new(self.TopBar:GetChild("Upgrades"), UIElement.Enum.UIType.Frame)
	self.TopBar_UpgradesBtn = UIElement.new(self.TopBar_Upgrades:GetChild("PressBtn"), UIElement.Enum.UIType.Text, nil, {
		MouseButton1Click = function()
			switchCategory("Upgrades")
		end,
	})

	self.TopBar_Coins = UIElement.new(self.TopBar:GetChild("Coins"), UIElement.Enum.UIType.Frame)
	self.TopBar_CoinsBtn = UIElement.new(self.TopBar_Coins:GetChild("PressBtn"), UIElement.Enum.UIType.Text, nil, {
		MouseButton1Click = function()
			switchCategory("Coins")
		end,
	})

	self.Shop_PassesList = UIElement.new(self.ShopFrame:GetChild("Passes"):WaitForChild("ListFrame"), UIElement.Enum.UIType.Frame)
	self.Shop_UpgradesList = UIElement.new(self.ShopFrame:GetChild("Upgrades"):WaitForChild("ListFrame"), UIElement.Enum.UIType.Frame)
	self.Shop_CoinsList = UIElement.new(self.ShopFrame:GetChild("Coins"):WaitForChild("ListFrame"), UIElement.Enum.UIType.Frame)

	-- self.Templates = self.Gui:WaitForChild("Templates")

	-- Set initial category
	task.wait(0.1) -- Wait a bit longer for UI to settle
	switchCategory("Passes")
end


function StoreUI:_UpdateAllLists()
	-- Clear existing items
	self.Shop_CoinsList:ClearChildren()
	self.Shop_PassesList:ClearChildren()
	self.Shop_UpgradesList:ClearChildren()

	-- Create templates from StoreConfig
	for _, itemData in StoreConfig do
		if itemData.types == 1 then -- Coins
			self:_CreateTemplate("StoreCoinTemplate", self.Shop_CoinsList.instance, function(template, data)
				template.Title.TextLabel.Text = data.desc
				template.BuyButton.Text = "R$ " .. data.robuxPrice
				template.BG.Image = data.icon
				self.Maid:GiveTask(template.BuyButton.MouseButton1Click:Connect(function()
					self:HandleStorePurchase(data.productId)
				end))
			end, itemData)
		elseif itemData.types == 2 then -- Passes
			self:_CreateTemplate("StorePassTemplate", self.Shop_PassesList.instance, function(template, data)
				template.Title.TextLabel.Text = data.title
				template.Desc.TextLabel.Text = data.desc
				-- template.PressBtn.Text = "R$ " .. data.robuxPrice
				template.PressBtn.Image = data.icon
				self.Maid:GiveTask(template.PressBtn.MouseButton1Click:Connect(function()
					self:HandleStorePurchase(data.productId)
				end))
				AttributeListener.new(player, data.PassName, function(OwnedPass)
					if OwnedPass and template.Parent and template.PressBtn and template.OwnedMask then
						template.PressBtn.Interactable = false
						template.OwnedMask.Visible = true
					end
				end)
			end, itemData)
		end
	end

	-- Create templates from UpgradesConfig
	for _, upgradeData in UpgradesConfig do
		self:_CreateTemplate("StoreUpgradeTemplate", self.Shop_UpgradesList.instance, function(template, data)
			template.Title.TextLabel.Text = data.title
			template.Desc.TextLabel.Text = data.desc
			template.CurLevel.TextLabel.Text = "Level: 0" -- TODO: Update with player's current level
			template.BuyButton.Text = data.price[1]
			template.BG.Image = data.icon
			self.Maid:GiveTask(template.BuyButton.MouseButton1Click:Connect(function()
				self:HandleUpgradePurchase(data.id)
			end))
		end, upgradeData)
	end
end

function StoreUI:HandleStorePurchase(productId)
	MarketplaceService:PromptProductPurchase(Players.LocalPlayer, productId)
    -- print("Handling store purchase for product ID:", productId)
    -- Server communication logic will be added later
end

function StoreUI:HandleUpgradePurchase(upgradeId)
    print("Handling upgrade purchase for upgrade ID:", upgradeId)
    -- Server communication logic will be added later
end

function StoreUI:_Refresh()
	self:_UpdateAllLists()
end

return StoreUI
