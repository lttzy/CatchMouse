local Action = {}

Action.Status = {
	RUNNING = "RUNNING", -- 进行中
	TERMINATED = "TERMINATED", -- 终止
	UNINIIALIZED = "UNINIIALIZED" -- 未初始化
}

Action.Type = "Action"


timer = 0

function SoldierActions_IdleCleanUp(userData)
	print("SoldierActions_IdleCleanUp data is "..userData)
	timer = 0
end

function SoldierActions_IdleInitialize(userData)
	print("SoldierActions_IdleInitialize data is "..userData)
	timer = 0
end

function SoldierActions_IdleUpdate(deltaTimeInMillis,userData)
	print("SoldierActions_IdleUpdate data is "..userData)
	timer = (timer + 1)
	if timer > 3 then
		return Action.Status.TERMINATED
	end

	return Action.Status.RUNNING
end


function SoldierActions_DieCleanUp(userData)
	print("SoldierActions_DieCleanUp data is "..userData)
	timer = 0
end

function SoldierActions_DieInitialize(userData)
	print("SoldierActions_DieInitialize data is "..userData)
	timer = 0
end

function SoldierActions_DieUpdate(deltaTimeInMillis,userData)
	print("SoldierActions_DieUpdate data is "..userData)
	timer = (timer + 1)
	if timer > 3 then
		return Action.Status.TERMINATED
	end

	return Action.Status.RUNNING
end

function SoldierEvaluators_True(userData)
	print("SoldierEvaluators_True data is "..userData)
	return true
end

function SoldierEvaluators_False(userData)
	print("SoldierEvaluators_True data is "..userData)
	return false
end


--require "SoldierActions"
--require "FiniteStateMachine"
--require "SoldierEvaluators"

local FiniteStateMachine = require(script.Parent)

local function IdleAction(userData)
	return Action.new(
		"idle",
		SoldierActions_IdleInitialize,
		SoldierActions_IdleUpdate,
		SoldierActions_IdleCleanUp,
		userData
	)
end


local function DieAction(userData)
	return Action.new(
		"die",
		SoldierActions_DieInitialize,
		SoldierActions_DieUpdate,
		SoldierActions_DieCleanUp,
		userData
	)
end

function SoldierLogic_FiniteStateMachine(userData)
	local fsm = FiniteStateMachine.new(userData)
	fsm:AddState("idle",IdleAction(userData))
	fsm:AddState("die",    DieAction(userData))

	fsm:AddTransition("idle","die",SoldierEvaluators_True)
	fsm:AddTransition("die","idle",SoldierEvaluators_True)

	fsm:SetState('idle')

	return fsm
end

return nil
