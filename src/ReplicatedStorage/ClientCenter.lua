
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Controllers = ReplicatedStorage:WaitForChild("Source"):WaitForChild("Controllers")
local Signal = require(ReplicatedStorage.Source.CommonFunctions.Signal)

local ClientCenter = {}
local LoadModules = {}
local LoadSignals = {}

function ClientCenter.GetController(moduleName)
    if not LoadModules[moduleName] then
        LoadModules[moduleName] = require(Controllers:WaitForChild(moduleName))
    end
    return LoadModules[moduleName]
end

function ClientCenter.GetSignal(signalName)
    if not LoadSignals[signalName] then
        LoadSignals[signalName] = Signal.new()
    end
    return LoadSignals[signalName]
end

function ClientCenter.GetConfiguration(ConfigurationName)
    local Configuration = ReplicatedStorage.Configurations:FindFirstChild(ConfigurationName)
    if not Configuration then
        return {}
    end
    local Properties = {}
    for _, v in Configuration:GetChildren() do
        Properties[v.Name] = v.Value
    end
    return Properties
end

return ClientCenter