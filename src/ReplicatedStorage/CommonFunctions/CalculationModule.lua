local TweenService = game:GetService("TweenService")

local module = {}

--拆分数字 num:被拆分的数值 numRandomNumbers:拆分数量
local function SplitIntoRandomNumbers(num:number,numRandomNumbers:number)
	local array = {}
	local maxNum = num

	for i=1,numRandomNumbers do
		if i == numRandomNumbers then
			table.insert(array, num)
		else
			if num < 1 then num = 1 end
			local min,max = 80*maxNum/numRandomNumbers,120*maxNum/numRandomNumbers
			local random = math.random(min, max)/100
			random = random > max and max or random
			table.insert(array, random)
			num = num - random
		end
	end
	return array
end

local maxSeed = 2147483647
--获取随机结果 proTable:需要处理的表
local function GetRandomResult(proTable:{value:string,pro:number,[any]:any})
	local seed = math.random(maxSeed)
	local generator = Random.new(seed)

	local probabilityTable = {}
	local num = 0
	local added = 0
	for i,config in pairs(proTable) do
		num += config.pro
		if i == 1 then
			probabilityTable[config.value] = {min = string.format("%.4f",(i-1) * num + 1-added),max = string.format("%.4f",num-added)}
		elseif i == #proTable then
			probabilityTable[config.value] = {min = string.format("%.4f",probabilityTable[proTable[i-1].value].max + 0.0001),max = string.format("%.4f",num)}
		else
			probabilityTable[config.value] = {min = string.format("%.4f",probabilityTable[proTable[i-1].value].max + 0.0001),max = string.format("%.4f",num-added)}
		end
	end
	local random = generator:NextInteger(1*10000, num*10000)/10000
	for value,pro in pairs(probabilityTable) do
		if random >= tonumber(pro.min) and random <= tonumber(pro.max) then
			return value
		end
	end
end

--数值缓动动画 startNumber:起始数 targetNumber:结果数
local function NumberValueTween(startNumber:NumberValue,targetNumber:number)
	TweenService:Create(startNumber, TweenInfo.new(1), {Value = targetNumber}):Play()
end

--将给定数组转化成1~100的出现概率 返回{value:实例,pro:权重}
local function CalculateProbabilities(arry:{{value:any,pro:number}}):{value:any,pro:number}
	local total = 0
	local probabilities = {}
	for _, config in ipairs(arry) do
		total = total + config.pro
	end
	for _, config in ipairs(arry) do
		table.insert(probabilities,{value = config.value,pro = string.format("%.4f", (config.pro / total) * 100)})
	end
	table.sort(probabilities,function(a,b)
		return a.pro>b.pro
	end)

	return probabilities
end

--比例转化_表 将一组数字按最大最小值转化成0~1之间 numbers:数组
local function NormalizeNumbers_Table(numbers:{number}):{number}
	local min = math.min(table.unpack(numbers))
	local max = math.max(table.unpack(numbers))
	local range = max - min
	local normalized_numbers = {}
	for _, number in ipairs(numbers) do
		table.insert(normalized_numbers, (number - min) / range)
	end
	return normalized_numbers
end

--[[ normalizeNumbers 示例使用
local numbers = {10, 20, 30, 40, 50}
local normalized_numbers = normalize_numbers(numbers)
for _, number in ipairs(normalized_numbers) do
	print(number)
end
]]

--比例转化_数字 将范围内数字按最大最小值转化成0~1之间 min、max:范围区间 targetNumber:目标数字
local function NormalizeNumbers_Number(min:number,max:number,targetNumber:number):number
	assert(targetNumber>=min,"The number must be greater than min")
	assert(targetNumber<=max,"The number must be smaller than max")
	local range = max - min
	return (targetNumber - min) / range
end

--将数字从一个区间按比例转化到另一个区间 value:目标数字 oldMin、oldMax:原区间 newMin、newMax：新区间
function RescaleNumber(value:number, oldMin:number, oldMax:number, newMin:number, newMax:number):number
	assert(oldMax>oldMin,"oldMax must be greater than oldMin")
	assert(newMax>newMin,"NewMax must be smaller than newMin")
	-- 计算原范围和目标范围的宽度
	local oldWidth = oldMax - oldMin
	local newWidth = newMax - newMin
	-- 计算比例
	local scale = (newWidth / oldWidth)
	-- 将值从原始范围转换为目标范围
	local rescaledValue = (value - oldMin) * scale + newMin
	return rescaledValue
end

local function GetModelHeight(model)
	local highestPoint = -math.huge
	local lowestPoint = math.huge

	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			local size = part.Size
			local cframe = part.CFrame

			local corners = {
				cframe * Vector3.new(size.X / 2, size.Y / 2, size.Z / 2),
				cframe * Vector3.new(size.X / 2, size.Y / 2, -size.Z / 2),
				cframe * Vector3.new(size.X / 2, -size.Y / 2, size.Z / 2),
				cframe * Vector3.new(size.X / 2, -size.Y / 2, -size.Z / 2),
				cframe * Vector3.new(-size.X / 2, size.Y / 2, size.Z / 2),
				cframe * Vector3.new(-size.X / 2, size.Y / 2, -size.Z / 2),
				cframe * Vector3.new(-size.X / 2, -size.Y / 2, size.Z / 2),
				cframe * Vector3.new(-size.X / 2, -size.Y / 2, -size.Z / 2)
			}

			for _, corner in ipairs(corners) do
				if corner.Y > highestPoint then
					highestPoint = corner.Y
				end
				if corner.Y < lowestPoint then
					lowestPoint = corner.Y
				end
			end
		end
	end

	local height = highestPoint - lowestPoint
	return height
end

module.SplitIntoRandomNumbers = SplitIntoRandomNumbers
module.GetRandomResult = GetRandomResult
module.NumberValueTween = NumberValueTween
module.CalculateProbabilities = CalculateProbabilities
module.NormalizeNumbers_Table = NormalizeNumbers_Table
module.NormalizeNumbers_Number = NormalizeNumbers_Number
module.RescaleNumber = RescaleNumber
module.GetModelHeight = GetModelHeight

return module
