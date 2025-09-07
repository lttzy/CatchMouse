--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local UIElement = require(script.Parent.UIElement)
local UITemplate = require(script.Parent.UITemplate)
local ClientCenter = require(ReplicatedStorage.Source.ClientCenter)

local LeftMenuUI = UITemplate:Extend("LeftMenuUI")

function LeftMenuUI:Init(Name)
	UITemplate.Init(self, Name)
end

function LeftMenuUI:_InitRefrences()
	self.MainFrame = UIElement.new(self.Gui:WaitForChild("MainFrame"), UIElement.Enum.UIType.Frame)
	-- self.CoinsFrame = UIElement.new(self.MainFrame:GetChild("CoinsFrame"), UIElement.Enum.UIType.Frame)
	-- self.CoinsNumText = UIElement.new(self.CoinsFrame:GetChild("Number"), UIElement.Enum.UIType.Text)


	-- self:_AddAttributeListener(player, "Coins", function(coins)
	-- 	self.CoinsNumText:SetText(tostring(coins or 0))
	-- end)
	self.StoreBtn = UIElement.new(self.MainFrame:GetChild("Store"), UIElement.Enum.UIType.Image, nil, {
		MouseButton1Click = function()
			ClientCenter.GetSignal("ShowStore"):Fire()
		end
	})
end

function LeftMenuUI:_InitConnections()
	-- self.Maid:GiveTask(self.CloseBtn.MouseButton1Click:Connect(function()
	--     self:Hide()
	-- end))

	-- Communication.OnClientEvent("StoreRefreshed", function(storeName)
	--     if storeName == "EggStore" and self.Gui.Enabled then
	--         self:UpdateStore()
	--     end
	-- end)
end


function LeftMenuUI:_Refresh()

end

return LeftMenuUI
