local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Manager = ServerStorage:WaitForChild("Managers")
local Signal = require(ReplicatedStorage.Source.CommonFunctions.Signal)

local ServerCenter = {}
local LoadModules = {}
local LoadSignals = {}

function ServerCenter.GetManager(moduleName)
    if not LoadModules[moduleName] then
        LoadModules[moduleName] = require(Manager:WaitForChild(moduleName))
    end
    return LoadModules[moduleName]
end

function ServerCenter.GetSignal(signalName)
    if not LoadSignals[signalName] then
        LoadSignals[signalName] = Signal.new()
    end
    return LoadSignals[signalName]
end

local dataTypeToClassName = {
    ["string"] = "StringValue",
    ["number"] = "NumberValue",
    ["boolean"] = "BoolValue"
}
function ServerCenter.SetConfiguration(ConfigurationName, Properties)
    local Configuration = ReplicatedStorage.Configurations:FindFirstChild(ConfigurationName)
    if not Configuration then
        Configuration = Instance.new("Configuration", ReplicatedStorage.Configurations)
        Configuration.Name = ConfigurationName
    end
    for k, v in pairs(Properties) do
        if not Configuration:FindFirstChild(k) then
            if not dataTypeToClassName[typeof(v)] then
                continue
            end
            Instance.new( dataTypeToClassName[typeof(v)], Configuration).Name = k
        else
            Configuration:WaitForChild(k).Value = v
        end
    end
end

return ServerCenter