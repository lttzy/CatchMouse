local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Wearable = Assets:WaitForChild("Wearable")

local module = {}

local function CreateRigid(att1,att2,parent,rigName)
	local Rigid = parent:FindFirstChild(rigName or "RigidConstraint") and parent.SitRig or Instance.new("RigidConstraint",parent)
	Rigid.Name = rigName or "RigidConstraint"
	Rigid.Attachment0 = att1
	Rigid.Attachment1 = att2
end

local function CreatEquipment(instance,types,id)
	
	local attachments = {
		Weapon = (instance:FindFirstChild("RightHand") or instance:FindFirstChild("Right Arm")):WaitForChild("RightGripAttachment"),
		WeaponL = (instance:FindFirstChild("LeftHand") or instance:FindFirstChild("Left Arm")):WaitForChild("LeftGripAttachment"),
		Wings = (instance:FindFirstChild("UpperTorso") or instance:FindFirstChild("Torso")) :WaitForChild("BodyBackAttachment"),
		Mount = (instance:FindFirstChild("LowerTorso") or instance:FindFirstChild("Torso")) :WaitForChild("WaistCenterAttachment"),
	}
	
	local equipment = Wearable[types][tostring(id)]:Clone()
	if equipment:IsA("Model") then
		local handle = equipment:WaitForChild("Handle")
		CreateRigid(handle.Attachment,attachments[types],handle)
	elseif equipment:IsA("Accessory") then
		local humanoid = instance:FindFirstChild("Humanoid")
		if humanoid then humanoid:AddAccessory(equipment) end
	end
	equipment:SetAttribute("id",id)
	equipment.Name = types
	equipment.Parent = instance
end

local function ChangedEquipment(instance:Instance,types:string,id:number)
	if types and id then
		local equipment = instance:FindFirstChild(types)
		if not equipment then
			CreatEquipment(instance,types,id)
		elseif equipment and equipment:GetAttribute("id") ~= id then
			equipment:Destroy()
			local equipmentL = instance:FindFirstChild(types.."L")
			if equipmentL then equipmentL:Destroy() end
			CreatEquipment(instance,types,id)
		end
	else
		local equipment = instance:FindFirstChild(types)
		if equipment then equipment:Destroy() end
		local equipmentL = instance:FindFirstChild(types.."L")
		if equipmentL then equipmentL:Destroy() end
	end
end

module.ChangedEquipment = ChangedEquipment

return module
