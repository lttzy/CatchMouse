local CollectionService = game:GetService("CollectionService")
local Maid = require(script.Parent.Maid)

local TagListener = {}
TagListener.__index = TagListener

--[=[
  --- @function new
  --- @param tagName string
  --- @param handleFunc function
  --- @param remoeFunc function
  --- @return TagListener

  Creates a new TagListener

  ```lua
  local listener = TagListener.new("Tag", function(instance)
      print(instance.Name .. " added")
  end， function(instance)
      print(instance.Name .. " removed")
  )
  ```
]=]
function TagListener.new(tagName, handleFunc, remoeFunc)
	local self = setmetatable({}, TagListener)
	self.TagName = tagName
	self.HandleFunc = handleFunc
    self.Maid = Maid.new()
	self.instances = CollectionService:GetTagged(tagName)

	if handleFunc then
        self.Maid:GiveTask(CollectionService:GetInstanceAddedSignal(tagName):Connect(function(instance)
            handleFunc(instance)
            if not self.instances then
                self.instances = {}
            end
            table.insert(self.instances, instance)
        end))
        for _, instance in self.instances do
		handleFunc(instance)
	end
    end

	if remoeFunc then
		self.Maid:GiveTask(CollectionService:GetInstanceRemovedSignal(tagName):Connect(function(instance)
			remoeFunc(instance)
			if not self.instances then
				self.instances = {}
			end
			if table.find(self.instances, instance) then
				table.remove(self.instances, table.find(self.instances, instance))
			end
		end))
	end

	
	return self
end

function TagListener:Destroy()
	self.Maid:DoCleaning()
	for _, instance in self.instances do
		instance:Destroy()
	end
	self = nil
end

return TagListener
