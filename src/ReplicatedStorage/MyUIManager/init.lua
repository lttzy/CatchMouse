local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local PLAYER_GUI = Players.LocalPlayer and Players.LocalPlayer:WaitForChild("PlayerGui")


local UIManager = {}
UIManager._uiControllers = {} -- Table to store UI Controller instances {Name = ControllerInstance}

-- List of UI Controllers to manage (Maps name to the module)
local UI_CONTROLLERS_TO_LOAD = {
    LeftMenuUI = require(script.LeftMenuUI),
    StoreUI = require(script.StoreUI),
}

local HIDE_IGNORE = {
    -- LeftMenuUI = true,
}

-- Initializes the UIManager and all managed UI Controllers
function UIManager:Activated()
    self._uiControllers = {} -- Clear previous controllers if re-initializing

    -- Initialize specific UI controllers
    for name, controllerModule in pairs(UI_CONTROLLERS_TO_LOAD) do

        if controllerModule and controllerModule.new then
            local controllerInstance = controllerModule.new(name) -- Pass the instance if needed by New()
            if controllerInstance then
                 self._uiControllers[name] = controllerInstance
                 -- Optionally hide all UIs initially
                 if controllerInstance.Hide then
                     controllerInstance:Hide()
                 end
            else
                 warn(string.format("[UIManager] Failed to create controller instance for: %s", name))
            end
        elseif not controllerModule then
             warn(string.format("[UIManager] Module not found or invalid for controller: %s", name))
        elseif not controllerModule.new then
             warn(string.format("[UIManager] Module for '%s' does not have a New() function.", name))
        end
    end

end

function UIManager:HideAll()
    for name, controller in pairs(self._uiControllers) do
        if HIDE_IGNORE[name] then
            continue
        end
        if controller and controller.Hide then
            controller:Hide()
        end
    end
end

-- Function to get a specific UI Controller instance
-- @param name string The name of the UI Controller (e.g., "QuestUI")
-- @return table or nil The controller instance
function UIManager:GetController(name)
    local controllerInstance = self._uiControllers[name]
    if not controllerInstance then
        warn("[UIManager] GetController: Controller with name", name, "not found.")
    end
    return controllerInstance -- This will be nil if not found, and the caller should handle that.
end

-- Destroys all managed UI Controllers and element wrappers
function UIManager:Destroy()
    -- Destroy UI Controllers
    for name, controller in pairs(self._uiControllers) do
        if controller and controller.Destroy then
            -- print(string.format(" - Destroying UI Controller: %s", name))
            pcall(function() controller:Destroy() end) -- Wrap in pcall
        end
    end
    self._uiControllers = {}
end


return UIManager
