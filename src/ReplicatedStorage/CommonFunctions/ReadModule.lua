local ContentProvider = game:GetService("ContentProvider")

local module = {}

local function TraverseTreePaths(node,path,callback)
	if not path then path = {} end
	
	table.insert(path,node)
	if #node:GetChildren() == 0 then
		callback(path)
	else
		for _,child in ipairs(node:GetChildren()) do
			TraverseTreePaths(child,path,callback)
		end
	end
	
	table.remove(path)
end

local function GetAssets(folder,assetsType)
	local function checkType(theAssets)
		for _,typeString in pairs(assetsType) do
			if theAssets:IsA(typeString) then
				return true
			end
		end
		return false
	end

	local assetsList = {}
	TraverseTreePaths(folder, nil,function(path)
		for _,theAssets in pairs(path) do
			if not checkType(theAssets) then continue end
			if assetsList[theAssets.Name] then continue end
			assetsList[theAssets.Name] = theAssets
		end
	end)
	return assetsList
end

local function GetScripts(folder)
	local scriptsList = {}
	TraverseTreePaths(folder, nil,function(path)
		for _,theScript in pairs(path) do
			if not theScript:IsA("ModuleScript") then continue end
			if scriptsList[theScript.Name] then continue end
			scriptsList[theScript.Name] = require(theScript)
		end
	end)
	return scriptsList
end

local function LoadAssets(loadTable)
	local startTime = os.clock()
	ContentProvider:PreloadAsync(loadTable)
	local deltaTime = os.clock() - startTime
	print(("Preloading complete, took %.2f seconds"):format(deltaTime))
end

local function LoadAnimation(animator:Animator,animName:string,animId):AnimationTrack
	local anim = Instance.new('Animation')
	anim.Name = animName
	if string.match(tostring(animId),"rbxassetid://") then
		anim.AnimationId = animId
	else
		anim.AnimationId = "rbxassetid://"..animId
	end
	
	local theAnimation = animator:LoadAnimation(anim)
	anim = nil
	return theAnimation
end

type array = {
	any:any
}
--表转字典 array:需要转换的表 key:key值 bool:是否在表中删掉key值
local function ConvertTableToDictionary(array:array,key:string,bool:boolean):array
	local result = {}
	for _, v in array do
		if not v[key] then continue end
		result[v[key]] = v
		if bool then result[v[key]][key] = nil end
	end
	return result
end

--获取字典key的数量
local function GetDictionaryNum(array:array):number
	local num = 0
	for _,v in pairs(array) do
		num += 1
	end
	return num
end

--获取分割字符串 bafter:true为保留后半段,false为保留前半段
local function InterceptString(strurl:string, strchar:string, bafter:boolean):string
	if not strurl or not strchar then return "" end
	local ts = string.reverse(strurl)
	local param1, param2 = string.find(ts, strchar)
	local m = string.len(strurl) - param2 + 1   
	local result
	if (bafter == true) then
		result = string.sub(strurl, m+1, string.len(strurl)) 	
	else
		result = string.sub(strurl, 1, m-1) 	
	end
	return result
end


local charset = {} 
for i = 48,  57 do table.insert(charset, string.char(i)) end -- 添加 0-9
for i = 65,  90 do table.insert(charset, string.char(i)) end -- 添加 A-Z
for i = 97, 122 do table.insert(charset, string.char(i)) end -- 添加 a-z
--获取唯一标识符 length长度
local function GetUniqueId(length:number)
	if length > #charset then
		return nil -- 长度超出字符集大小
	end

	local str = ""
	for i = 1, length do
		local randomIndex = math.random(1, #charset)
		str = str .. charset[randomIndex]
	end

	return str
end

--将表根据输入数字分割 array:需要分割的表 number:单个表最大元素数量
function SplitTableIntoSubtables(array,number:number)
	local subtables = {}
	local index = 1
	local subtable = {}

	for i = 1, #array do
		table.insert(subtable, array[i])
		if #subtable == number then
			table.insert(subtables, subtable)
			subtable = {}
		end
	end

	-- 如果最后一个子表不满指定数量的元素，也将其加入到结果中
	if #subtable > 0 then
		table.insert(subtables, subtable)
	end

	return subtables
end

--寻找表里是否已经存在某个值
function IndexOf(array:{}, value:any)
	for i = 1, #array do
		if array[i] == value then
			return i -- 返回找到的值的索引，而非布尔值。如果需要布尔值，可以稍后根据索引判断。
		end
	end
	return nil -- 未找到时返回nil或-1等表示不存在的值。
end

module.LoadAssets = LoadAssets
module.LoadAnimation = LoadAnimation
module.ConvertTableToDictionary = ConvertTableToDictionary
module.GetDictionaryNum = GetDictionaryNum
module.InterceptString = InterceptString
module.GetUniqueId = GetUniqueId
module.SplitTableIntoSubtables = SplitTableIntoSubtables
module.IndexOf = IndexOf

return module