-- 有限状态机，来源《Lua游戏AI开发指南》

------ 状态动作类 开始
local Action = {}

Action.Status = {
	RUNNING = "RUNNING", -- 进行中
	TERMINATED = "TERMINATED", -- 终止
	UNINIIALIZED = "UNINIIALIZED" -- 未初始化
}

Action.Type = "Action"

function Action.new(name, initializeFunction, updateFunction, cleanUpFunction, userData)
	local action = {}

	action.cleanUpFunction_ = cleanUpFunction
	action.initializeFunction_ = initializeFunction
	action.updateFunction_  = updateFunction
	action.name_ = name or ""
	action.status_ = Action.Status.UNINIIALIZED
	action.type_ = Action.Type
	action.userData_ = userData

	action.CleanUp = Action.CleanUp
	action.Initialize = Action.Initialize
	action.Update = Action.Update

	return action
end

function Action:Initialize()
	if self.status_ == Action.Status.UNINIIALIZED then
		if self.initializeFunction_ then
			self.initializeFunction_(self.userData_)
		end
	end

	self.status_ = Action.Status.RUNNING
end

function Action:Update(dt)
	if self.status_ == Action.Status.TERMINATED then
		return Action.Status.TERMINATED
	elseif self.status_ == Action.Status.RUNNING then
		if self.updateFunction_ then
			self.status_ = self.updateFunction_(dt,self.userData_)
			assert(self.status_)
		else
			self.status_ = Action.Status.TERMINATED
		end
	end
	return self.status_
end

function Action:CleanUp()
	if self.status_ == Action.Status.TERMINATED then
		if self.cleanUpFunction_ then
			self.cleanUpFunction_(self.userData_)
		end
	end

	self.status_ = Action.Status.UNINIIALIZED
end
------ 状态动作类 结束

------ 状态迁移类 开始
local FiniteStateTransition = {}

function FiniteStateTransition.new(toStateName, evaluator)
	local transition = {}

	-- 状态转换条件的数据
	transition.evaluator_ = evaluator
	transition.toStateName_ = toStateName

	return transition
end
------ 状态迁移类 结束

------ 状态类 开始
local FiniteState = {}

function FiniteState.new(name, action)
	local state = {}
	-- 状态的数据
	state.name_ = name
	state.action_ = action

	return state
end
------ 状态类 结束

-- 有限状态机 开始
local FiniteStateMachine = {}

FiniteStateMachine.Action = Action

function FiniteStateMachine.new(userData)
	local fsm = {}

	-- 状态机的数据
	fsm.currentState_ = nil
	fsm.states_ = {}
	fsm.transition_ = {}
	fsm.userData_ = userData

	fsm.AddState = FiniteStateMachine.AddState
	fsm.AddTransition = FiniteStateMachine.AddTransition
	fsm.ContainState = FiniteStateMachine.ContainState
	fsm.ContainTransition = FiniteStateMachine.ContainTransition
	fsm.GetCurrentStateName = FiniteStateMachine.GetCurrentStateName
	fsm.GetCurrentStateStatus = FiniteStateMachine.GetCurrentStateStatus
	fsm.SetState = FiniteStateMachine.SetState
	fsm.Update = FiniteStateMachine.Update

	return fsm
end

function FiniteStateMachine:ContainState(stateName)
	return self.states_[stateName] ~= nil
end

function FiniteStateMachine:ContainTransition(fromStateName,toStateName)
	return self.transition_[fromStateName] ~= nil and self.transition_[fromStateName][toStateName] ~= nil
end

function FiniteStateMachine:GetCurrentStateName()
	if self.currentState_ then
		return self.currentState_.name_
	end
end

function FiniteStateMachine:GetCurrentStateStatus()
	if self.currentState_ then
		return self.currentState_.action_.status_
	end
end

function FiniteStateMachine:SetState(stateName)
	if self:ContainState(stateName) then
		if self.currentState_ then
			self.currentState_.action_:CleanUp()
		end

		self.currentState_ = self.states_[stateName]
		self.currentState_.action_:Initialize()
	end
end

function FiniteStateMachine:AddState(name, action)
	self.states_[name] = FiniteState.new(name,action)
end

function FiniteStateMachine:AddTransition(fromStateName,toStateName,evaluator)
	if self:ContainState(fromStateName) and
		self:ContainState(toStateName) then

		if self.transition_[fromStateName] == nil then
			self.transition_[fromStateName] = {}
		end

		table.insert(
			self.transition_[fromStateName],
			FiniteStateTransition.new(toStateName,evaluator)
		)
	end
end

local function EvaluateTransitions(fsm,transitions)
	for index = 1 , #transitions do
		if transitions[index].evaluator_(fsm.userData_) then
			return transitions[index].toStateName_;
		end
	end
end

function FiniteStateMachine:Update(dt: number)
	if self.currentState_ then
		local status = self:GetCurrentStateStatus()

		if status == Action.Status.RUNNING then
			self.currentState_.action_:Update(dt)
		elseif status == Action.Status.TERMINATED then
			local toStateName = EvaluateTransitions(self, self.transition_[self.currentState_.name_])
			if self.states_[toStateName] ~= nil then
				self.currentState_.action_:CleanUp()
				self.currentState_ = self.states_[toStateName]
				self.currentState_.action_:Initialize()
			end
		end
	end
end

return FiniteStateMachine
