local DB = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService") -- Added HttpService

local data_version = "0.0.2"
local datastores = {
    PlayerStats = DB:GetDataStore("PlayerStats_test" .. data_version),
    BadgeDatas = DB:GetDataStore("BadgeDatas_test" .. data_version),
}


local DataStoreMgr = {}

DataStoreMgr.PlayerStats = {}
DataStoreMgr.BadgeDatas = {}

function DataStoreMgr:GetPlayerStats(playerId)
    local res = self:FetchData(datastores.PlayerStats, playerId)
    -- print("DataStoreMgr:GetPlayerStats: Fetched data for player "..tostring(playerId)..":", res)
    return self:FetchData(datastores.PlayerStats, playerId)
end

function DataStoreMgr:SavePlayerStats(playerId, data)
    if type(data) ~= "table" then data = {} end
    data.last_logout_time = os.time()
    return self:PushData(datastores.PlayerStats,playerId,data)
end

function DataStoreMgr:GetPlayerBadgeDatas(playerId)
    return self:FetchData(datastores.BadgeDatas, playerId)
end

function DataStoreMgr:SavePlayerBadgeDatas(playerId, badgeDatas)
    self:PushData(datastores.BadgeDatas,playerId,badgeDatas)
end

local MAX_RETRIES = 5 -- Maximum number of retry attempts
local INITIAL_RETRY_DELAY = 0.2 -- Initial delay in seconds before the first retry

function DataStoreMgr:FetchData(datastore, key)
    for retryCount = 1, MAX_RETRIES do
        local success, result = pcall(function()
            return datastore:GetAsync(key)
        end)

        if success then
            if result and type(result) == "string" then
                -- Attempt to decode JSON string
                local decodeSuccess, decodedData = pcall(HttpService.JSONDecode, HttpService, result)
                if decodeSuccess then
                    -- Reconstruction logic removed, will be handled in GrowServerController after loading
                    return decodedData -- Return the decoded Lua table
                else
                    warn(string.format("FetchData succeeded for key '%s', but JSONDecode failed. Error: %s",
                        tostring(key), tostring(decodedData))) -- Log decode error specifically
                    -- Decide how to handle decode failure: return nil or the raw string? Returning nil is safer.
                    return nil
                end
            elseif result then
                 -- DataStore returned something other than a string (unexpected but possible)
                 warn(string.format("FetchData for key '%s' returned non-string data: %s", tostring(key), typeof(result)))
                 return result -- Return the raw data as is, though it might cause issues later
            else
                 -- DataStore returned nil (key doesn't exist or empty)
                 return nil
            end
        else
            warn(string.format("FetchData GetAsync failed for key '%s'. Attempt %d/%d. Error: %s",
                tostring(key), retryCount, MAX_RETRIES, tostring(result)))

            if retryCount < MAX_RETRIES then
                local delay = INITIAL_RETRY_DELAY * (2 ^ (retryCount - 1)) -- Exponential backoff
                task.wait(delay)
            else
                warn(string.format("FetchData failed for key '%s' after %d attempts. Giving up.",
                    tostring(key), MAX_RETRIES))
                return nil -- Indicate failure after all retries
            end
        end
    end
    -- Should technically be unreachable if MAX_RETRIES >= 1, but return nil just in case
    return nil
end

function DataStoreMgr:ClearPlayerData(playerId)
    self.PlayerStats[playerId] = nil
    self.BadgeDatas[playerId] = nil
end

-- Private helper to convert Vector3 to a JSON-safe table
local function PrepareDataForJSON(data)
    if type(data) ~= "table" then return data end

    local preparedData = {}
    for k, v in pairs(data) do
        if typeof(v) == "Vector3" then
            preparedData[k] = { X = v.X, Y = v.Y, Z = v.Z }
        elseif type(v) == "table" then
            preparedData[k] = PrepareDataForJSON(v) -- Recurse for nested tables
        else
            preparedData[k] = v
        end
    end
    return preparedData
end

function DataStoreMgr:PushData(datastore, key, value)
    -- Prepare the data by converting Vector3 to tables
    local dataToEncode = PrepareDataForJSON(value)

    -- Attempt to encode the Lua table to JSON
    local encodeSuccess, jsonValue = pcall(HttpService.JSONEncode, HttpService, dataToEncode)

    if not encodeSuccess then
        warn(string.format("PushData failed for key '%s' during JSONEncode. Error: %s",
            tostring(key), tostring(jsonValue)))
        return false -- Indicate failure due to encoding error
    end

    -- Proceed with saving the JSON string
    for retryCount = 1, MAX_RETRIES do
        local success, result = pcall(function()
            datastore:SetAsync(key, jsonValue) -- Save the encoded JSON string
        end)

        if success then
            -- print("PushData successful for key '"..tostring(key).."' on attempt "..tostring(retryCount)..".")
            return true -- Indicate success
        else
            -- Log the specific error from SetAsync pcall result
            warn(string.format("PushData SetAsync failed for key '%s'. Attempt %d/%d. Error: %s",
                tostring(key), retryCount, MAX_RETRIES, tostring(result)))

            if retryCount < MAX_RETRIES then
                local delay = INITIAL_RETRY_DELAY * (2 ^ (retryCount - 1)) -- Exponential backoff
                task.wait(delay)
            else
                warn(string.format("PushData failed for key '%s' after %d attempts. Giving up.",
                    tostring(key), MAX_RETRIES))
                return false -- Indicate failure after all retries
            end
        end
    end
    -- Should technically be unreachable if MAX_RETRIES >= 1, but return false just in case
    return false
end

return DataStoreMgr
