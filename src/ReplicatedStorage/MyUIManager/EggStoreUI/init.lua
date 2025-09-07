--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local Maid = require(ReplicatedStorage.Source.CommonFunctions.Maid)
local ConfigDatas = require(ReplicatedStorage.Source.Datas)
local Communication = require(ReplicatedStorage.Source.CommonFunctions.Communication)

local PLAYER_GUI = player:WaitForChild("PlayerGui")

local EggStoreUI = {}
EggStoreUI.__index = EggStoreUI

function EggStoreUI.new()
    local self = setmetatable({}, EggStoreUI)
    
    self.Maid = Maid.new()
    self.SelectedItem = nil
    self.Items = {}
    self.StoreData = nil

    -- Clone the UI from the script's child
    local guiTemplate = script:FindFirstChild("EggStoreUI")
    assert(guiTemplate, "EggStoreUI template not found as a child of the script.")
    self.Gui = guiTemplate:Clone()
    self.Gui.Parent = PLAYER_GUI

    -- Get references to UI elements
    self.MainFrame = self.Gui:WaitForChild("MainFrame")
    self.Title = self.MainFrame:WaitForChild("Title")
    self.CloseBtn = self.Title:WaitForChild("CloseButton")
    self.ScrollingFrame = self.MainFrame:WaitForChild("ScrollingFrame")
    self.Template = self.MainFrame:WaitForChild("Template")
    self.PurchasePanel = self.MainFrame:WaitForChild("PurchasePanel")
    
    self.Template.Visible = false -- Hide template
    self.PurchasePanel.Parent = self.ScrollingFrame
    self.PurchasePanel.Visible = false -- Hide purchase panel initially

    self:_CreateItems()
    self:_InitConnections()

    return self
end

function EggStoreUI:_InitConnections()
    self.Maid:GiveTask(self.CloseBtn.MouseButton1Click:Connect(function()
        self:Hide()
    end))

    Communication.OnClientEvent("StoreRefreshed", function(storeName)
        if storeName == "EggStore" and self.Gui.Enabled then
            self:UpdateStore()
        end
    end)
end

function EggStoreUI:_CreateItems()
    local eggStoreItems = {}
    for _, item in ConfigDatas:GetConfigDatas("StoreConfig") do
        if item.type == 1 then
            table.insert(eggStoreItems, item)
        end
    end

    table.sort(eggStoreItems, function(a, b)
        return a.order < b.order
    end)

    for _, itemData in ipairs(eggStoreItems) do
        local itemFrame = self.Template:Clone()
        itemFrame.Name = tostring(itemData.id)
        itemFrame.Parent = self.ScrollingFrame
        itemFrame.LayoutOrder = itemData.order * 2
        itemFrame.Visible = true

        local icon = itemFrame:WaitForChild("Icon")
        local nameLabel = itemFrame:WaitForChild("Name")
        local priceLabel = itemFrame:WaitForChild("Price")
        local textButton = itemFrame:WaitForChild("TextButton")

        local rewardData
        for _, r in ConfigDatas:GetConfigDatas("RewardConfig") do
            if r.id == itemData.rewardId then
                rewardData = r
                break
            end
        end

        if not rewardData then
            warn("No reward data found for store item: " .. itemData.name)
            continue
        end

        local eggData
        for _, a in ConfigDatas:GetConfigDatas("EggConfig") do
            if a.id == rewardData.rewardId then
                eggData = a
                break
            end
        end

        if not eggData then
            warn("No egg data found for reward: " .. rewardData.id)
            continue
        end

        icon.Image = eggData.icon or ""
        nameLabel.Text = itemData.name
        priceLabel.Text = tostring(itemData.price) .. "$"

        table.insert(self.Items, { data = itemData, frame = itemFrame })

        self.Maid:GiveTask(textButton.MouseButton1Click:Connect(function()
            self:_OnItemSelected(itemData)
        end))
    end
end

function EggStoreUI:_OnItemSelected(itemData)
    if self.SelectedItem and self.SelectedItem.data.id == itemData.id then
        self.PurchasePanel.Visible = false
        self.SelectedItem = nil
        return
    end

    self.SelectedItem = { data = itemData }
    
    -- Update and show purchase panel
    local priceButton = self.PurchasePanel:WaitForChild("PriceButton")
    local robuxButton = self.PurchasePanel:WaitForChild("RobuxButton")

    local amount = self.StoreData and self.StoreData.items[tostring(itemData.id)] or 0
    if amount > 0 then
        priceButton.Text = tostring(itemData.price) .. "$"
        priceButton.Selectable = true
        robuxButton.Selectable = true
    else
        priceButton.Text = "NO STOCK"
        priceButton.Selectable = false
        robuxButton.Selectable = false
    end
    
    robuxButton.Text = tostring(itemData.robuxPrice)
    self.PurchasePanel.LayoutOrder = itemData.order * 2 + 1
    self.PurchasePanel.Visible = true
end

function EggStoreUI:Show()
	self.Gui.Enabled = true
    self:UpdateStore()
end

function EggStoreUI:Hide()
	self.Gui.Enabled = false
end

function EggStoreUI:Destroy()
	self.Maid:DoCleaning()
	self.Gui:Destroy()
end

function EggStoreUI:UpdateStore()
    self.StoreData = Communication.InvokeServer("GetStoreData", "EggStore")
    local storeData = self.StoreData

    warn("UpdateStore", storeData)
    if not storeData then return end

    -- Update items
    for _, item in ipairs(self.Items) do
        local itemFrame = item.frame
        local itemData = item.data
        local amount = storeData.items[tostring(itemData.id)] or 0
        
        local priceLabel = itemFrame:WaitForChild("Price")
        local countLabel = itemFrame:WaitForChild("Count")
        
        if amount > 0 then
            priceLabel.Text = tostring(itemData.price) .. "$"
            countLabel.Text = "X" .. tostring(amount) .. " Stock"
            priceLabel.Visible = true
        else
            priceLabel.Text = "NO STOCK"
            countLabel.Text = "X0 Stock"
        end
    end

    -- Update countdown
    local countdownLabel = self.Title:FindFirstChild("Countdown")
    if not countdownLabel then
        countdownLabel = Instance.new("TextLabel")
        countdownLabel.Name = "Countdown"
        countdownLabel.Size = UDim2.new(0.5, 0, 1, 0)
        countdownLabel.Position = UDim2.new(0.5, 0, 0, 0)
        countdownLabel.BackgroundTransparency = 1
        countdownLabel.TextColor3 = Color3.new(1, 1, 1)
        countdownLabel.TextSize = 24
        countdownLabel.Font = Enum.Font.SourceSansBold
        countdownLabel.Parent = self.Title
    end

    if self.Countdown then
        self.Countdown:Disconnect()
    end

    self.Countdown = game:GetService("RunService").Heartbeat:Connect(function()
        local remaining = math.max(0, storeData.nextRefreshTime - os.time())
        local minutes = math.floor(remaining / 60)
        local seconds = remaining % 60
        countdownLabel.Text = string.format("New seeds in %d:%02d", minutes, seconds)
    end)
    self.Maid:GiveTask(self.Countdown)
end

return EggStoreUI
