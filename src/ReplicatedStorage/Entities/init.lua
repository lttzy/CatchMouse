-- 定义一个基本的类
BaseClass = {}
BaseClass.__index = BaseClass

-- 构造函数
function BaseClass.new(id, uid)
    local self = setmetatable({}, BaseClass)
    self.uid = uid or "0"
    self.id = id
    return self
end

-- 基本方法
function BaseClass:describe()
    print("This is a base class object named " .. self.uid)
end

-- 定义 extends 方法，用于创建子类
function BaseClass:extends()
    local subclass = {}
    subclass.__index = subclass
    setmetatable(subclass, {__index = self})
    function subclass.new(...)
        local self = setmetatable(self:super(...), subclass)
        return self
    end
    return subclass
end

-- 添加一个 super 方法来调用父类的构造函数
function BaseClass:super(...)
    return BaseClass.new(...)
end


return BaseClass