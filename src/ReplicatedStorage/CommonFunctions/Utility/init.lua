local utility = {}
local Players = game:GetService("Players")
local lc_bigint = require(script.lc_bigint)


--金币单位转化
local units = {"K","M","B","T","QU","QA","QD","QT","AA","AB","AC","AD","AE","AF","AG","BA","BB","BC","BD","BE","BF","BG"}
local RomanUnits = {"I","II","III","IV","V","VI","VII","VIII","IX","X","XI","XII","XIII","XIV","XV","XVI","XVII","XVIII","XIX","XX"}

function utility:GetRomanNumerals(id)
	return " "..RomanUnits[id]
end





function utility:FormatDHMS(sec)
	return ('%02i:%02i:%02i:%02i'):format(sec / 86400,sec / 60^2 % 24,sec / 60 % 60,sec % 60)
end

function utility:FormatDHM(sec)
	return ('%02i:%02i:%02i'):format(sec / 86400,sec / 60^2 % 24,sec / 60 % 60)
end

function utility:FormatDHM_Units(sec)
	return ('%id-%ih-%im'):format(sec / 86400,sec / 60^2 % 24,sec / 60 % 60)
end

function utility:FormatDHMS_Units(sec)
	return ('%id:%ih:%im:%is'):format(sec / 86400,sec / 60^2 % 24,sec / 60 % 60,sec % 60)
end


function utility:FormatHMS(sec)
	--if sec >= 3600 then
		return ('%02i:%02i:%02i'):format(sec / 60^2 % 24,sec / 60 % 60,sec % 60)
	--else
		--return ('%02i:%02i'):format(sec / 60 % 60,sec % 60)
	--end
end

function utility:FormatMS(sec)
	return ('%02i:%02i'):format(sec / 60 % 60,sec % 60)
end

function utility:FormatH(sec)
	return ('%02ih'):format(sec / 60^2 % 24)
end

function utility:FormatM(sec)
	return ('%0im'):format(sec / 60)
end

function utility:FormatSMS(s)
	--return ('%i.%i'):format(sec % 60,(sec % 60 * 1000) % 1000)
	local seconds = math.floor(s) % 60
	local milliseconds = (s % 1) * 10 --(seconds * 1000) % 1000
	--seconds = math.floor(seconds)
	return string.format("%.1d.%.1ds", seconds, milliseconds)
end


function utility:RoundDecimals(num, numDecimalPlaces)--保留几位小数
	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end


local function GetPreciseDecimal(nNum, n)
	if type(nNum) ~= "number" then
		return nNum;
	end
	n = n or 0;
	n = math.floor(n)
	if n < 0 then
		n = 0
	end
	local nDecimal = 10 ^ n
	local nTemp = math.floor(nNum * nDecimal)
	local nRet = nTemp / nDecimal
	return nRet
end


function utility:FormatHour(sec)
	--if sec / 60^2 < 1 then
	--	return ('%0.1fh'):format(sec / 60^2)
	--else
	--	return ('%ih'):format(sec / 60^2)
	--end 
	return GetPreciseDecimal((sec / 60^2), 1).."h"
end



function utility:SetCanvasListSize(list,scale)
	list.CanvasSize = UDim2.fromOffset(0,list.UIListLayout.AbsoluteContentSize.Y / (scale and scale.Scale or 1) + 10)
end


function utility:SetCanvasGridSize(list,scale)
	list.CanvasSize = UDim2.fromOffset(0,list.UIGridLayout.AbsoluteContentSize.Y / (scale and scale.Scale or 1) + 10)
end

function utility.formatInteger(amount)
	amount = math.floor(amount + 0.5)
	local formatted = amount
	local numMatches
	repeat
		formatted, numMatches = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
	until numMatches == 0
	return formatted
end

function utility:ShowGoldNum(goldNum)
	if typeof(goldNum) == "number" then
		goldNum = math.ceil(goldNum)
	end
	local str = string.gsub(goldNum, "^%s*(.-)%s*$", "%1")
	local strLen = #str
	if strLen <= 4 then
		return str
	elseif strLen > 100 then
		local unit = units[#units]
		local leftLength = strLen - (3*(math.ceil(strLen/3) - 1))
		--return string.sub(str,1,leftLength).."."..string.sub(str,leftLength+1,leftLength+2)..unit
		return string.sub(str,1,leftLength).."."..string.sub(str,leftLength+1,leftLength+1)..unit
	else
		local unitIndex = math.ceil(strLen/3) - 1
		local unit = units[unitIndex]
		local leftLength = strLen - (3*(math.ceil(strLen/3) - 1))
		--return string.sub(str,1,leftLength).."."..string.sub(str,leftLength+1,leftLength+2)..unit
		if string.sub(str,leftLength+1,leftLength+1) == "0" then
			return string.sub(str,1,leftLength)..unit
		else
			return string.sub(str,1,leftLength).."."..string.sub(str,leftLength+1,leftLength+1)..unit
		end		
	end
end
--数字分割，只能分割12位以内，12位以上变成科学计数法
function utility:formatNum( numTmp )

	local resultNum = numTmp

	local strNum = tostring(numTmp)
	local newStr = ""
	local numLen = string.len( strNum )
	local count = 0
	for i = numLen, 1, -1 do
		if count % 3 == 0 and count ~= 0  then
			newStr = string.format("%s,%s",string.sub( strNum,i,i),newStr) 
		else
			newStr = string.format("%s%s",string.sub( strNum,i,i),newStr) 
		end
		count = count + 1
	end
	resultNum = newStr

	return resultNum
end





function utility.GetGroupRank(plr,groupId)
	if Players:FindFirstChild(plr.Name) then
		local rankId = 0
		local succ,report = pcall(function()
			rankId = plr:GetRankInGroup(groupId)	
		end)			
		return rankId
	end	
end


function utility.InGroup(plr,groupId)
	local result = false
	local succ,report = pcall(function()
		result = plr:IsInGroup(groupId)
	end)			
	return result
end

--大数运算
-- a>=b ture a<b false
function utility:ge(a,b)
	return lc_bigint.__le(b,a)
end
--小于等于
function utility:__le(a,b)
	return lc_bigint.__le(a,b)
end
--小于
function utility:__lt(a,b)
	return lc_bigint.__lt(a,b)
end
--加
function utility:add(a, b)
	return lc_bigint.__add(a, b)
end
--减
function utility:sub(a, b)
	return lc_bigint.__sub(a, b)
end
--乘
function utility:by(a, b)
	return lc_bigint.__mul(a, b)
end

function changeFloat(s)
	local length = #s
	local index = string.find(s,'%.')
	if index and index > 1 then
		local a = string.sub(s,1,index-1)
		local b = string.sub(s,index+1)
		if #b > 4 then
			b = string.sub(b,1,4)
		elseif #b < 4  then
			for i= 1,4-#b do 
				b = b.."0"
			end
		end
		if a ~= "0" then
			return a..b,4
		else
			return b,4
		end
	end
	return s,0
end

function utility:byfloat(a,b)
	local a1 = 0
	local b1 = 0
	a = tostring(a)
	b = tostring(b)
	a,a1 = changeFloat(a)
	b,b1 = changeFloat(b)
	local c = utility:by(a, b)
	c = tostring(c)
	return string.sub(c,1,-1-a1-b1)
end


function utility:tableToStringNum(Table)
	if Table[1] and Table[2] then
		local Num = tostring(Table[2])
		
		for i = 1 ,Table[1] do
			Num = Num.."0"
		end
		
		return Num
	end
	error("Tabel转数字错误")
	return "0"
end

function utility:GetNearPoint(HitPoint,center,size)
	local posList = {}
	local leftUp    = center + Vector3.new(-size.x/2,0,-size.z/2)
	posList[1] = leftUp
	local leftDown  = center + Vector3.new(-size.x/2,0,size.z/2)
	posList[2] = leftDown
	local rightUp   = center + Vector3.new(size.x/2,0,-size.z/2)
	posList[3] = rightUp
	local rightDown = center + Vector3.new(size.x/2,0,size.z/2)
	posList[4] = rightDown
	local nearPoint = posList[1]
	for i = 2, #posList do 
		if (HitPoint - nearPoint).Magnitude > (HitPoint - posList[i]).Magnitude then
			nearPoint = posList[i]
		end 
	end
	return nearPoint
end

return utility
