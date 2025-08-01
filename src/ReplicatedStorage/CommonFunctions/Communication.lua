local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteFolder = ReplicatedStorage:FindFirstChild("Remote")
if not RemoteFolder then
	RemoteFolder = Instance.new("Folder")
	RemoteFolder.Name = "Remote"
	RemoteFolder.Parent = ReplicatedStorage
end
local FolderList = {
	"RemoteEvent","UnreliableRemoteEvent","RemoteFunction","BindableEvent","BindableFunction",
}
for _,folderName in pairs(FolderList) do
	local folder = RemoteFolder:FindFirstChild(folderName)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = folderName
		folder.Parent = RemoteFolder
	end
end

local module = {}

local function IsCallable(value)
	if type(value) == "function" then
		return true
	end
	if type(value) == "table" then
		local metatable = getmetatable(value)
		if metatable and type(rawget(metatable, "__call")) == "function" then
			return true
		end
	end
	return false
end

local function DuplicateError(name)
	return "There are instances with duplicate names and incorrect types!!!error name:"..name
end

local function ClientError(name)
	return "Please declare the instance on the server first!!!error name:"..name
end

local function GetRemoteEvent(name:string)
	local remote = RemoteFolder.RemoteEvent:FindFirstChild(name)
	if RunService:IsServer() then
		if not remote then
			remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = RemoteFolder.RemoteEvent
			return remote
		else
			assert(remote:IsA("RemoteEvent"), DuplicateError(name))
			return remote
		end
	else
		assert(remote, ClientError(name))
		return remote
	end
end

local function GetUnreliableRemoteEvent(name:string)
	local remote = RemoteFolder.UnreliableRemoteEvent:FindFirstChild(name)
	if RunService:IsServer() then
		if not remote then
			remote = Instance.new("UnreliableRemoteEvent")
			remote.Name = name
			remote.Parent = RemoteFolder.UnreliableRemoteEvent
			return remote
		else
			assert(remote:IsA("UnreliableRemoteEvent"), DuplicateError(name))
			return remote
		end
	else
		assert(remote, ClientError(name))
		return remote
	end
end

local function GetRemoteFunction(name:string)
	local remote = RemoteFolder.RemoteFunction:FindFirstChild(name)
	if RunService:IsServer() then
		if not remote then
			remote = Instance.new("RemoteFunction")
			remote.Name = name
			remote.Parent = RemoteFolder.RemoteFunction
			return remote
		else
			assert(remote:IsA("RemoteFunction"), DuplicateError(name))
			return remote
		end
	else
		assert(remote, ClientError(name))
		return remote
	end
end

local function GetBindableEvent(name:string)
	local remote = RemoteFolder.BindableEvent:FindFirstChild(name)
	if RunService:IsServer() then
		if not remote then
			remote = Instance.new("BindableEvent")
			remote.Name = name
			remote.Parent = RemoteFolder.BindableEvent
			return remote
		else
			assert(remote:IsA("BindableEvent"), DuplicateError(name))
			return remote
		end
	else
		assert(remote, ClientError(name))
		return remote
	end
end

local function GetBindableFunction(name:string)
	local remote = RemoteFolder.BindableFunction:FindFirstChild(name)
	if RunService:IsServer() then
		if not remote then
			remote = Instance.new("BindableFunction")
			remote.Name = name
			remote.Parent = RemoteFolder.BindableFunction
			return remote
		else
			assert(remote:IsA("BindableFunction"), DuplicateError(name))
			return remote
		end
	else
		assert(remote, ClientError(name))
		return remote
	end
end

--RemoteEvent
------------------------------------------------------------------------------------------------------------------------
local function FireServer(name:string,...)
	local event = GetRemoteEvent(name)
	event:FireServer(...)
end

local function FireClient(name:string,...)
	local event = GetRemoteEvent(name)
	event:FireClient(...)
end

local function FireAllClients(name:string,...)
	local event = GetRemoteEvent(name)
	event:FireAllClients(...)
end

local function OnClientEvent(name:string,callback)
	assert(IsCallable(callback), "callback must be a function")
	local event = GetRemoteEvent(name)
	event.OnClientEvent:Connect(callback)
end

local function OnServerEvent(name:string,callback)
	assert(IsCallable(callback), "callback must be a function")
	local event = GetRemoteEvent(name)
	event.OnServerEvent:Connect(callback)
end
------------------------------------------------------------------------------------------------------------------------

--UnreliableRemoteEvent
------------------------------------------------------------------------------------------------------------------------
local function UnreliableFireServer(name:string,...)
	local event = GetUnreliableRemoteEvent(name)
	event:FireServer(...)
end

local function UnreliableFireClient(name:string,...)
	local event = GetUnreliableRemoteEvent(name)
	event:FireClient(...)
end

local function UnreliableFireAllClients(name:string,...)
	local event = GetUnreliableRemoteEvent(name)
	event:FireAllClients(...)
end

local function UnreliableOnClientEvent(name:string,callback)
	assert(IsCallable(callback), "callback must be a function")
	local event = GetUnreliableRemoteEvent(name)
	event.OnClientEvent:Connect(callback)
end

local function UnreliableOnServerEvent(name:string,callback)
	assert(IsCallable(callback), "callback must be a function")
	local event = GetUnreliableRemoteEvent(name)
	event.OnServerEvent:Connect(callback)
end
------------------------------------------------------------------------------------------------------------------------

--RemoteFunction
------------------------------------------------------------------------------------------------------------------------
local function InvokeServer(name:string,...)
	local event = GetRemoteFunction(name)
	return event:InvokeServer(...)
end

local function InvokeClient(name:string,...)
	local event = GetRemoteFunction(name)
	return event:InvokeClient(...)
end

local function OnClientInvoke(name:string,callback)
	assert(IsCallable(callback), "callback must be a function")
	local event = GetRemoteFunction(name)
	event.OnClientInvoke = callback
end

local function OnServerInvoke(name:string,callback)
	assert(IsCallable(callback), "callback must be a function")
	local event = GetRemoteFunction(name)
	event.OnServerInvoke = callback
end
------------------------------------------------------------------------------------------------------------------------

--BindableEvent
------------------------------------------------------------------------------------------------------------------------
local function Fire(name:string,...)
	local event = GetBindableEvent(name)
	event:Fire(...)
end

local function Event(name:string,callback)
	assert(IsCallable(callback), "callback must be a function")
	local event = GetBindableEvent(name)
	event.Event:Connect(callback)
end
------------------------------------------------------------------------------------------------------------------------

--BindableFunction
------------------------------------------------------------------------------------------------------------------------
local function Invoke(name:string,...)
	local event = GetBindableFunction(name)
	return event:Invoke(...)
end

local function OnInvoke(name:string,callback)
	assert(IsCallable(callback), "callback must be a function")
	local event = GetBindableFunction(name)
	event.OnInvoke = callback
end
------------------------------------------------------------------------------------------------------------------------
--Get Instance------------------------------------------------------------------------------------------------------------------------
module.GetRemoteEvent = GetRemoteEvent
module.GetUnreliableRemoteEvent = GetUnreliableRemoteEvent
module.GetRemoteFunction = GetRemoteFunction
module.GetBindableEvent = GetBindableEvent
module.GetBindableFunction = GetBindableFunction
--RemoteEvent------------------------------------------------------------------------------------------------------------------------
module.FireServer = FireServer
module.FireClient = FireClient
module.FireAllClients = FireAllClients
module.OnClientEvent = OnClientEvent
module.OnServerEvent = OnServerEvent
--UnreliableRemoteEvent------------------------------------------------------------------------------------------------------------------------
module.UnreliableFireServer = UnreliableFireServer
module.UnreliableFireClient = UnreliableFireClient
module.UnreliableFireAllClients = UnreliableFireAllClients
module.UnreliableOnClientEvent = UnreliableOnClientEvent
module.UnreliableOnServerEvent = UnreliableOnServerEvent
--RemoteFunction------------------------------------------------------------------------------------------------------------------------
module.InvokeServer = InvokeServer
module.InvokeClient = InvokeClient
module.OnClientInvoke = OnClientInvoke
module.OnServerInvoke = OnServerInvoke
--BindableEvent------------------------------------------------------------------------------------------------------------------------
module.Fire = Fire
module.Event = Event
--BindableFunction------------------------------------------------------------------------------------------------------------------------
module.Invoke = Invoke
module.OnInvoke = OnInvoke
return module