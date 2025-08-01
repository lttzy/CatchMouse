local MyMath = {}

function adaptive_simpson(f, a, b, eps, max_depth)
    local function _simpson(l, r)
        local mid = (l + r) / 2
        return (r - l) / 6 * (f(l) + 4*f(mid) + f(r))
    end

    local function _adaptive(l, r, whole, eps, depth)
        local mid = (l + r) / 2
        local left = _simpson(l, mid)
        local right = _simpson(mid, r)
        local diff = (left + right - whole)
        if depth <= 0 or math.abs(diff) <= 15*eps then
            return left + right + diff/15
        end
        return _adaptive(l, mid, left, eps/2, depth-1) + 
               _adaptive(mid, r, right, eps/2, depth-1)
    end

    local whole = _simpson(a, b)
    return _adaptive(a, b, whole, eps or 1e-6, max_depth or 20)
end

-- 示例：计算 ∫x² dx 从0到1（理论值1/3）
-- local result = adaptive_simpson(function(x) return x^2 end, 0, 1)
-- print(result) -- 输出约0.333333
MyMath.adaptive_simpson = adaptive_simpson
return MyMath