local Maid = require(script.Parent.Maid)
local AttributeListener = {}
AttributeListener.__index = AttributeListener

function AttributeListener.new(instance, attributeName, callback)
    local self = setmetatable({}, AttributeListener)
    self.AttributeName = attributeName
    self.Maid = Maid.new()

    self.Maid:GiveTask(instance:GetAttributeChangedSignal(attributeName):Connect(function()
        callback(instance:GetAttribute(attributeName))
    end))
    callback(instance:GetAttribute(attributeName))
    return self
end

function AttributeListener:Destroy()
    self.Maid:DoCleaning()
    self = nil
end

return AttributeListener