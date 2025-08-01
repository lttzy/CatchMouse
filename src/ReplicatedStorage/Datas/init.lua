local ConfigDatas = {}

ConfigDatas.Datas = {}

function ConfigDatas:Init(key)
	local res = {}
    local items = require(script:FindFirstChild(key))
	for _, itemValue in items do
		if itemValue.id then
			res[itemValue.id] = itemValue
		end
	end
	self.Datas[key] = res
end

function ConfigDatas:GetConfigData(key, id)
	if not self.Datas[key] then
        self:Init(key)
	end
	return self.Datas[key][id]
end

function ConfigDatas:GetConfigDatas(key)
	if not self.Datas[key] then
        self:Init(key)
	end
	return self.Datas[key]
end

return ConfigDatas
