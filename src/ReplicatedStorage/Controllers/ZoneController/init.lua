local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ZoneClass = {
	-- ["EggStore"] = require(script.Zone.EggStore),
	-- ["Prepare"] = require(script.Zone.Prepare),
}

local Zone = {}
local tag = "Zone"
Zone.instances = {}

local checkTask = {}

local function onInstanceAdded(object)
	if object:IsDescendantOf(game.Workspace) then
		if not Zone.instances[object] then
			Zone.instances[object] = ZoneClass[object.Name].new(object,"Zone")
		end
	else
		CollectionService:RemoveTag(object,tag)
	end
	if not checkTask[object] then
		checkTask[object] = object.AncestryChanged:Connect(function(parent)
			if parent:IsDescendantOf(game.Workspace) then
				CollectionService:AddTag(object,tag)
			else
				CollectionService:RemoveTag(object,tag)
			end
		end)
	end
end

local function onInstanceRemoved(object)
	if Zone.instances[object] then
		Zone.instances[object] = nil
	end
end

function Zone:Activated()
	CollectionService:GetInstanceAddedSignal(tag):Connect(onInstanceAdded)
	CollectionService:GetInstanceRemovedSignal(tag):Connect(onInstanceRemoved)

	for _, object in pairs(CollectionService:GetTagged(tag)) do
		onInstanceAdded(object)
	end
end

return Zone