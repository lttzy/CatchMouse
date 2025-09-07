local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MyServerCenter = require(ServerStorage.MyServerCenter)

local TimerManager = {
    TimerList = {},
}

function TimerManager.AddTimer(TimerName, Time)
    if TimerManager.TimerList[TimerName] and TimerManager.TimerList[TimerName] then
        task.cancel(TimerManager.TimerList[TimerName])
    end
    TimerManager.TimerList[TimerName] = task.spawn(function()
        while task.wait(1) do
            Time = Time - 1
            MyServerCenter.SetConfiguration("Timer", {Timer = Time})
            if Time <= 0 then
                TimerManager.TimerList[TimerName] = nil
                break
            end
        end
    end)
end

return TimerManager