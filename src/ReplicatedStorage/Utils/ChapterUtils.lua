-- ChapterUtils.lua
local ConfigDatas = require(script.Parent.Parent.Datas)

local ChapterUtils = {}

-- 缓存已查询的配置数据
local configCache = setmetatable({}, { __mode = "v" })

-- 根据配置类型和ID获取配置，采用弱引用缓存
function ChapterUtils.GetCachedConfig(configType, id)
    local cacheKey = configType .. ":" .. tostring(id)
    if not configCache[cacheKey] then
        configCache[cacheKey] = ConfigDatas:GetConfigData(configType, id)
    end
    return configCache[cacheKey]
end

-----------------------------------------------------------------
-- 修改后的方法：检查指定关卡在指定难度下是否完成（即满足解锁条件）
--
-- 解锁规则说明：
--
-- 1. 简单难度（hard_level==1）：  
--    当前关卡完成要求：该关卡的简单数据（level1）为 true。
--
-- 2. 普通难度（hard_level==2）：  
--    (a) 如果是第一张地图的第一关，则只需要该关卡的简单数据（level1）为 true；  
--    (b) 否则，当前关卡“完成”要求为：当前关卡的简单数据（level1）为 true，
--        且在当前地图中，该关卡之前的所有关卡均已通过普通难度（即每个前面关卡的 level2 为 true）。
--
-- 3. 困难难度（hard_level==3）：  
--    (a) 如果是第一张地图的第一关，则只需要该关卡的普通数据（level2）为 true；  
--    (b) 否则，当前关卡完成要求为：当前关卡的普通数据（level2）为 true，
--        且在当前地图中，该关卡之前的所有关卡均已通过困难难度（即每个前面关卡的 level3 为 true）。
--
-- 参数：
--    map_id          -- 地图ID（数字）
--    stage_id        -- 当前关卡ID（取自 MapInfos.stages 内的一个值）
--    hard_level      -- 目标难度（1：简单，2：普通，3：困难）
--    map_locked_data -- 关卡数据（格式： { [map_id] = { [stage_id] = { level1 = true, level2 = true, level3 = true } } } ）
-----------------------------------------------------------------
-- 修改后的 CheckStageDifficultyUnlocked（用于判断“是否解锁”）
-- 这里的实现仅针对简单难度 hard_level==1 做了修改，
-- 逻辑：如果当前关卡早已通关，或正是紧接在连续通关后的一关，则认为当前关卡解锁
function ChapterUtils.CheckStageDifficultyUnlocked(map_id, stage_id, hard_level, map_locked_data)
    local mapInfo = ChapterUtils.GetCachedConfig("MapInfos", map_id)
    if not mapInfo or not mapInfo.stages then
        return false
    end

    -- 查找当前关卡在 mapInfo.stages 中的索引位置
    local stageIndex = nil
    for i, sid in ipairs(mapInfo.stages) do
        if sid == stage_id then
            stageIndex = i
            break
        end
    end
    if not stageIndex then return false end

    if hard_level == 1 then
        -- 对简单难度，我们构建一个“连续通关关卡数”
        local passedCount = 0
        for i, sid in ipairs(mapInfo.stages) do
            local stageKey = tostring(sid)
            local stageData = map_locked_data[map_id] and map_locked_data[map_id][stageKey]
            if stageData and stageData["level1"] then
                passedCount = i
            else
                -- 遇到第一关未通关则退出循环
                break
            end
        end
        -- 如果当前关卡序号不超过已通关数，则是已通关（自然也处于解锁状态）
        if stageIndex <= passedCount then
            return true
        -- 如果当前关卡正好是下一关（passedCount+1），则处于解锁状态，但注意此时玩家还未通关
        elseif stageIndex == passedCount + 1 then
            return true
        else
            return false
        end

    elseif hard_level == 2 then
        if map_id == 1 and stageIndex == 1 then
            -- 第一张地图第一关的普通难度：只需简单数据（level1）为 true
            return map_locked_data[map_id] and map_locked_data[map_id][tostring(stage_id)] and
                   map_locked_data[map_id][tostring(stage_id)]["level1"] or false
        else
            -- 其余关卡：必须本关 simple 数据为 true，并且前面所有关卡均已通过普通难度
            local curStageData = map_locked_data[map_id] and map_locked_data[map_id][tostring(stage_id)]
            if not (curStageData and curStageData["level1"]) then
                return false
            end
            for i = 1, stageIndex - 1 do
                local prevStageKey = tostring(mapInfo.stages[i])
                local prevStageData = map_locked_data[map_id] and map_locked_data[map_id][prevStageKey]
                if not (prevStageData and prevStageData["level2"]) then
                    return false
                end
            end
            return true
        end

    elseif hard_level == 3 then
        if map_id == 1 and stageIndex == 1 then
            -- 第一张地图第一关的困难难度：只需普通数据（level2）为 true
            return map_locked_data[map_id] and map_locked_data[map_id][tostring(stage_id)] and 
                   map_locked_data[map_id][tostring(stage_id)]["level2"] or false
        else
            local curStageData = map_locked_data[map_id] and map_locked_data[map_id][tostring(stage_id)]
            if not (curStageData and curStageData["level2"]) then
                return false
            end
            for i = 1, stageIndex - 1 do
                local prevStageKey = tostring(mapInfo.stages[i])
                local prevStageData = map_locked_data[map_id] and map_locked_data[map_id][prevStageKey]
                if not (prevStageData and prevStageData["level3"]) then
                    return false
                end
            end
            return true
        end
    end

    return false
end

-----------------------------------------------------------------
-- 保留并原样提供星级统计相关方法
--
-- 方法1：获取指定关卡、指定难度下的星级数量
-- 参数：
--   map_id       -- 地图ID
--   stage_id     -- 关卡ID（字符串或数字，需要转换为字符串）
--   hard_level   -- 目标难度（1：简单，2：普通，3：困难）
--   chapter_data -- 数据格式应与原有的一致，例如：
--                  { [map_id] = { [stage_id] = { level1 = { key = true, ... }, ... } } }
-----------------------------------------------------------------
function ChapterUtils.GetStarCount(map_id, stage_id, hard_level, chapter_data)
    if not chapter_data then
        return 0
    end
    stage_id = tostring(stage_id)
    local difficulty = "level" .. tostring(hard_level)
    if not chapter_data[map_id]
       or not chapter_data[map_id][stage_id]
       or not chapter_data[map_id][stage_id][difficulty]
       or next(chapter_data[map_id][stage_id][difficulty]) == nil then
        return 0
    end

    local count = 0
    for _, v in pairs(chapter_data[map_id][stage_id][difficulty]) do
        if v == true then
            count = count + 1
        end
    end
    return count
end

-----------------------------------------------------------------
-- 新增方法1：
-- 根据 hard_level 和 chapter_data，统计所有地图中指定难度下已获得的星星总数
-- 遍历 chapter_data 中的每个 map 和 stage 累加 GetStarCount 的结果
-----------------------------------------------------------------
function ChapterUtils.GetTotalStarsByDifficulty(hard_level, chapter_data)
    local totalStars = 0
    local maximum = 0
    if not chapter_data then
        return 0
    end

    for map_id, data in ConfigDatas:GetConfigDatas("MapInfos") do
        if typeof(data) == "table" and data.stages then
            for _, stage_id in ipairs(data.stages) do
                totalStars = totalStars + ChapterUtils.GetStarCount(map_id, stage_id, hard_level, chapter_data)
                maximum = maximum + 3
            end
        end
    end
    return totalStars, maximum
end

-----------------------------------------------------------------
-- 新增方法2：
-- 根据 map_id、hard_level 和 chapter_data，统计当前地图指定难度下已获得的星星总数以及该地图能获得的最大星星数量
--
-- 这里假设每个 stage 在指定难度下最多能获得3颗星（如无特殊配置，可根据实际业务调整）
-----------------------------------------------------------------
function ChapterUtils.GetMapStarData(map_id, hard_level, chapter_data)
    local acquired = 0
    local maximum = 0
    local mapInfo = ChapterUtils.GetCachedConfig("MapInfos", map_id)
    if not mapInfo or not mapInfo.stages then
        return { acquired = 0, maximum = 0 }
    end

    for _, stage_id in ipairs(mapInfo.stages) do
        acquired = acquired + ChapterUtils.GetStarCount(map_id, stage_id, hard_level, chapter_data)
        maximum = maximum + 3
    end

    return acquired, maximum
end

-----------------------------------------------------------------
-- 修改后的方法：判断地图是否解锁（CheckMapUnLocked）
--
-- 规则：第一张地图始终解锁；否则必须要求前一张地图在相同难度下已完成
--
-- 参数：
--    map_id          -- 地图ID（数字）
--    hard_level      -- 目标难度
--    map_locked_data -- 数据格式同上
-----------------------------------------------------------------
function ChapterUtils.CheckMapUnLocked(map_id, hard_level, map_locked_data)
    if map_id == 1 then
        return true
    else
        return ChapterUtils.CheckMapFinishedByDifficulty(map_id - 1, hard_level, map_locked_data)
    end
end

-- 新增：判断指定关卡是否真正通过（即数据存在且达到难度要求）
function ChapterUtils.CheckStagePassedByDifficulty(map_id, stage_id, hard_level, map_locked_data)
    local mapInfo = ChapterUtils.GetCachedConfig("MapInfos", map_id)
    if not mapInfo or not mapInfo.stages then
        return false
    end

    -- 查找当前关卡索引
    local stageIndex = nil
    for i, sid in ipairs(mapInfo.stages) do
        if sid == stage_id then
            stageIndex = i
            break
        end
    end
    if not stageIndex then return false end

    local curStageData = map_locked_data[map_id] and map_locked_data[map_id][tostring(stage_id)]
    
    if hard_level == 1 then
        return curStageData and curStageData["level1"] or false
    elseif hard_level == 2 then
        if map_id == 1 and stageIndex == 1 then
            return curStageData and curStageData["level1"] or false
        else
            if not (curStageData and curStageData["level1"]) then
                return false
            end
            for i = 1, stageIndex - 1 do
                local prevKey = tostring(mapInfo.stages[i])
                local prevData = map_locked_data[map_id] and map_locked_data[map_id][prevKey]
                if not (prevData and prevData["level2"]) then
                    return false
                end
            end
            return true
        end
    elseif hard_level == 3 then
        if map_id == 1 and stageIndex == 1 then
            return curStageData and curStageData["level2"] or false
        else
            if not (curStageData and curStageData["level2"]) then
                return false
            end
            for i = 1, stageIndex - 1 do
                local prevKey = tostring(mapInfo.stages[i])
                local prevData = map_locked_data[map_id] and map_locked_data[map_id][prevKey]
                if not (prevData and prevData["level3"]) then
                    return false
                end
            end
            return true
        end
    end

    return false
end

-----------------------------------------------------------------
-- 增加新的方法：检查整个地图在指定难度下是否完成
--
-- 遍历 MapInfos 中该地图所有关卡，只有全部满足指定难度下的完成（CheckStageDifficultyUnlocked 为 true），才认为地图完成
--
-- 参数：
--    map_id          -- 地图ID
--    hard_level      -- 目标难度（1：简单，2：普通，3：困难）
--    map_locked_data -- 数据格式同上
-----------------------------------------------------------------
function ChapterUtils.CheckMapFinishedByDifficulty(map_id, hard_level, map_locked_data)
    local mapInfo = ChapterUtils.GetCachedConfig("MapInfos", map_id)
    if not mapInfo or not mapInfo.stages or not map_locked_data[map_id] then
        return false
    end
    for _, stage_id in ipairs(mapInfo.stages) do
        if not ChapterUtils.CheckStagePassedByDifficulty(map_id, stage_id, hard_level, map_locked_data) then
            return false
        end
    end
    return true
end


return ChapterUtils