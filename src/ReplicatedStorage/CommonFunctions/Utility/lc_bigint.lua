--author:landy
--大数类
--使用方式：
--可以进行简单的+,-,*,/,^,-(负号)操作，参数可以是数字，可以转化的字符串，大数类
--可以做>,<,==,>=,<=比较，但与数字或字符串比较需要显示转化tobigint
--不支持#,可以用self:__len()查询长度（不计算负号）
-------------------------------------
lc_bigint ={}
lc_bigint.__index = lc_bigint
lc_bigint.__newindex = function(t,k,v) assert(false) end
lc_bigint.__metatable="lc_bigint"
--转化
function tobigint(num)
	local ok,str=lc_bigint.checkvalue(num)
	if not ok then
		assert(false,tostring(num))
	end
	return lc_bigint:New({str=str})
end
--创建
function lc_bigint:New(c)
	local new_bigint=c or {str="0"}
	if new_bigint.str=="-0" then
		new_bigint.str="0"
	end
	setmetatable(new_bigint,self)
	return new_bigint
end
--转化为字符串
function lc_bigint:__tostring()
	return self.str
end
--验证
function lc_bigint.checkvalue(data)
	local str=tostring(data)
	if str =="" then
		return false,str
	end
	local _,pos2=string.find(str,"^[0]+")
	if pos2 then
		str = string.sub(str,pos2+1)
		if str == "" then
			str = "0"
		end
	end
	if string.find(str,"^[%d]+$") then
		return true,str
	end
	if string.find(str,"^%-[%d]+$") then
		return true,str
	end
	return false,str
end
--普通加
function lc_bigint.add(str1,str2)
	local index=1
	local add = 0
	local str=""
	local max_len = math.max(#str1,#str2)
	for i=1,max_len do
		local char1=#str1-i+1>0 and string.sub(str1,#str1-i+1,#str1-i+1) or "0"
		local char2=#str2-i+1>0 and string.sub(str2,#str2-i+1,#str2-i+1) or "0"
		local num = string.byte(char1)+string.byte(char2)+add-96
		str = math.fmod(num,10)..str
		add = num>9 and 1 or 0
	end
	if add>0 then
		str=add..str
	end
	return str
end
--普通减
function lc_bigint.sub(str1,str2)
	local index=1
	local add = 0
	local str=""
	local max_len = math.max(#str1,#str2)
	for i=1,max_len do
		local char1=#str1-i+1>0 and string.sub(str1,#str1-i+1,#str1-i+1) or "0"
		local char2=#str2-i+1>0 and string.sub(str2,#str2-i+1,#str2-i+1) or "0"
		local num = string.byte(char1)-string.byte(char2)-add
		str = (num < 0 and 10+num or num)..str
		add = num<0 and 1 or 0
	end
	if add>0 then
		return "-"..lc_bigint.sub(str2,str1)
	end
	local _,pos2=string.find(str,"^[0]+")
	if pos2 then
		str = string.sub(str,pos2+1)
		if str == "" then
			str = "0"
		end
	end
	return str
end
--加法运算
function lc_bigint.__add(data1,data2)
	local ok,str1 = lc_bigint.checkvalue(data1)
	if not ok then
		assert(false,tostring(data1))
	end
	ok,str2 = lc_bigint.checkvalue(data2)
	if not ok then
		assert(false,tostring(data2))
	end

	if string.sub(str1,1,1) == "-" and string.sub(str2,1,1) == "-" then
		str = "-"..lc_bigint.add(string.sub(str1,2),string.sub(str2,2))
	elseif string.sub(str1,1,1) == "-" and string.sub(str2,1,1) ~= "-" then
		str = lc_bigint.sub(str2,string.sub(str1,2))
	elseif string.sub(str1,1,1) ~= "-" and string.sub(str2,1,1) == "-" then
		str = lc_bigint.sub(str1,string.sub(str2,2))
	else
		str = lc_bigint.add(str1,str2)
	end
	return lc_bigint:New({str=str}).str
end
--减法运算
function lc_bigint.__sub(data1,data2)
	local ok,str1 = lc_bigint.checkvalue(data1)
	if not ok then
		assert(false,tostring(data1))
	end
	ok,str2 = lc_bigint.checkvalue(data2)
	if not ok then
		assert(false,tostring(data2))
	end
	if string.sub(str1,1,1) == "-" and string.sub(str2,1,1) == "-" then
		str = lc_bigint.sub(string.sub(str1,2),string.sub(str2,2))
	elseif string.sub(str1,1,1) == "-" and string.sub(str2,1,1) ~= "-" then
		str = "-"..lc_bigint.add(string.sub(str1,2),str2)
	elseif string.sub(str1,1,1) ~= "-" and string.sub(str2,1,1) == "-" then
		str = lc_bigint.add(str1,string.sub(str2,2))
	else
		str = lc_bigint.sub(str1,str2)
	end
	return lc_bigint:New({str=str}).str
end
--乘法运算
--普通计算方式，可以用傅立叶变换得到更快的计算
function lc_bigint.__mul(data1,data2)
	local ok,str1 = lc_bigint.checkvalue(data1)
	if not ok then
		assert(false,tostring(data1))
	end
	ok,str2 = lc_bigint.checkvalue(data2)
	if not ok then
		assert(false,tostring(data2))
	end
	local sign = ""
	if string.sub(str1,1,1) == "-" and string.sub(str2,1,1) == "-" then
		str1 = string.sub(str1,2)
		str2 = string.sub(str2,2)
	elseif string.sub(str1,1,1) == "-" and string.sub(str2,1,1) ~= "-" then
		str1 = string.sub(str1,2)
		sign = "-"
	elseif string.sub(str1,1,1) ~= "-" and string.sub(str2,1,1) == "-" then
		str2 = string.sub(str2,2)
		sign = "-"
	end
	local str="0"
	for i=#str2,1,-1 do
		local num=string.byte(string.sub(str2,#str2-i+1,#str2-i+1))-48
		local str3=str1..(i>1 and string.rep("0",i-1) or "")
		for j=1,num do
			str = lc_bigint.add(str,str3)
		end
	end
	str = sign..str
	return lc_bigint:New({str=str}).str
end
--除法运算
function lc_bigint.__div(data1,data2)
	local ok,str1 = lc_bigint.checkvalue(data1)
	if not ok then
		assert(false,tostring(data1))
	end
	ok,str2 = lc_bigint.checkvalue(data2)
	if not ok then
		assert(false,tostring(data2))
	end
	local sign = ""
	if string.sub(str1,1,1) == "-" and string.sub(str2,1,1) == "-" then
		str1 = string.sub(str1,2)
		str2 = string.sub(str2,2)
	elseif string.sub(str1,1,1) == "-" and string.sub(str2,1,1) ~= "-" then
		str1 = string.sub(str1,2)
		sign = "-"
	elseif string.sub(str1,1,1) ~= "-" and string.sub(str2,1,1) == "-" then
		str2 = string.sub(str2,2)
		sign = "-"
	end
	if lc_bigint:New({str=str1}) < lc_bigint:New({str=str2}) then
		return lc_bigint:New({str="0"}),lc_bigint:New({str=str1})
	end
	local str="0"
	local temp_bigint=lc_bigint:New({str=string.sub(str1,1,#str2-1)})
	local temp_bigint2=lc_bigint:New({str=str2})
	for i=#str2,#str1 do
		temp_bigint.str = temp_bigint.str..string.sub(str1,i,i)
		local num=0
		for i=1,9 do
			if temp_bigint >= temp_bigint2 then
				num = num + 1
				temp_bigint=temp_bigint-temp_bigint2
			else
				break
			end
		end
		str = str..num
	end
	local _,pos2=string.find(str,"^[0]+")
	if pos2 then
		str = string.sub(str,pos2+1)
		if str == "" then
			str = "0"
		end
	end
	str = sign..str
	return lc_bigint:New({str=str}).str,temp_bigint
end
--等于
function lc_bigint.__eq(data1,data2)
	local ok,str1 = lc_bigint.checkvalue(data1)
	if not ok then
		assert(false,tostring(data1))
	end
	ok,str2 = lc_bigint.checkvalue(data2)
	if not ok then
		assert(false,tostring(data2))
	end
	if #str1~=#str2 then
		return false
	end
	for i=1,#str1 do
		if string.sub(str1,i,i) ~= string.sub(str2,i,i) then
			return false
		end
	end
	return true
end
--小于
function lc_bigint.__lt(data1,data2)
	local ok,str1 = lc_bigint.checkvalue(data1)
	if not ok then
		assert(false,tostring(data1))
	end
	ok,str2 = lc_bigint.checkvalue(data2)
	if not ok then
		assert(false,tostring(data2))
	end
	if string.sub(str1,1,1) == "-" and string.sub(str2,1,1) == "-" then
		if #str1 > #str2 then
			return false
		elseif #str1 < #str2 then
			return true
		else
			for i=1,#str1 do
				local num1 = string.byte(string.sub(str1,i,i))
				local num2 = string.byte(string.sub(str2,i,i))
				if num1>num2 then
					return true
				elseif num1 < num2 then
					return false
				end
			end
			return false
		end
	elseif string.sub(str1,1,1) == "-" and string.sub(str2,1,1) ~= "-" then
		return true
	elseif string.sub(str1,1,1) ~= "-" and string.sub(str2,1,1) == "-" then
		return false
	end
	if #str1 > #str2 then
		return false
	elseif #str1 < #str2 then
		return true
	else
		for i=1,#str1 do
			local num1 = string.byte(string.sub(str1,i,i))
			local num2 = string.byte(string.sub(str2,i,i))
			if num1>num2 then
				return false
			elseif num1 < num2 then
				return true
			end
		end
		return false
	end
end
--小于等于
function lc_bigint.__le(data1,data2)
	local ok,str1 = lc_bigint.checkvalue(data1)
	if not ok then
		assert(false,tostring(data1))
	end
	ok,str2 = lc_bigint.checkvalue(data2)
	if not ok then
		assert(false,tostring(data2))
	end
	if string.sub(str1,1,1) == "-" and string.sub(str2,1,1) == "-" then
		if #str1 > #str2 then
			return false
		elseif #str1 < #str2 then
			return true
		else
			for i=1,#str1 do
				local num1 = string.byte(string.sub(str1,i,i))
				local num2 = string.byte(string.sub(str2,i,i))
				if num1 > num2 then
					return true
				elseif num1 < num2 then
					return false
				end
			end
			return true
		end
	elseif string.sub(str1,1,1) == "-" and string.sub(str2,1,1) ~= "-" then
		return true
	elseif string.sub(str1,1,1) ~= "-" and string.sub(str2,1,1) == "-" then
		return false
	end
	if #str1 > #str2 then
		return false
	elseif #str1 < #str2 then
		return true
	else
		for i=1,#str1 do
			local num1 = string.byte(string.sub(str1,i,i))
			local num2 = string.byte(string.sub(str2,i,i))
			if num1>num2 then
				return false
			elseif num1 < num2 then
				return true
			end
		end
		return true
	end
end

--取负
function lc_bigint.__unm(data1)
	local ok,str1 = lc_bigint.checkvalue(data1)
	if not ok then
		assert(false,tostring(data1))
	end
	if string.sub(str1,1,1)=="-" then
		return lc_bigint:New({str=string.sub(str1,2)}).str
	else
		return lc_bigint:New({str="-"..str1}).str
	end
end
--幂
function lc_bigint.__pow(data1,data2)
	local ok,str1 = lc_bigint.checkvalue(data1)
	if not ok then
		assert(false,tostring(data1))
	end
	ok,str2 = lc_bigint.checkvalue(data2)
	if not ok then
		assert(false,tostring(data2))
	end
	local temp_bigint=lc_bigint:New({str=str2})
	local temp_bigint1=lc_bigint:New({str=str1})
	local temp_bigint_0 = lc_bigint:New({str="0"})
	local temp_bigint_1 = lc_bigint:New({str="1"})
	if temp_bigint == temp_bigint_0 then
		return lc_bigint:New({str="1"})
	end
	if temp_bigint < temp_bigint_0 then
		return temp_bigint_0
	end
	if temp_bigint1 == temp_bigint_0 then
		return lc_bigint:New({str="0"})
	end
	if temp_bigint1 < temp_bigint_1 then
		return temp_bigint1
	end
	local temp_table={}
	local temp_mod
	while temp_bigint > temp_bigint_0 do
		temp_bigint,temp_mod = lc_bigint.__div(temp_bigint,2)
		if temp_mod ~= temp_bigint_0 then
			table.insert(temp_table,0)
		else
			table.insert(temp_table,1)
		end
	end
	local result_bigint=lc_bigint:New({str="1"})
	if temp_table[1] == 0 then
		temp_table[1] = temp_bigint1
	end
	for i=2,#(temp_table) do
		temp_bigint1 = temp_bigint1 * temp_bigint1
		if temp_table[i] == 0 then
			temp_table[i] = temp_bigint1
		end
	end
	for i,v in ipairs(temp_table) do
		result_bigint = result_bigint * v
	end
	return result_bigint.str
end
--长度
function lc_bigint.__len(data1)
	local ok,str1 = lc_bigint.checkvalue(data1)
	if not ok then
		assert(false,tostring(data1))
	end
	if string.sub(str1,1,1) == "-" then
		return #str1-1
	else
		return #str1
	end
end


return lc_bigint
