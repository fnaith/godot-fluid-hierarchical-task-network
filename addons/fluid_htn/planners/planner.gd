## A planner is a responsible for handling the management of finding plans in a domain, replan when the state of the
## running plan
## demands it, or look for a new potential plan if the world state gets dirty.
class_name HtnPlanner
extends RefCounted

#region FIELDS

var _current_task: HtnITask
var _plan: HtnPlan = HtnPlan.new()

#endregion

#region FIELDS

var _last_status: Htn.TaskStatus

func get_last_status() -> Htn.TaskStatus:
	return _last_status
func set_last_status(last_status: Htn.TaskStatus) -> void:
	_last_status = last_status

#endregion

#region CALLBACKS

## OnNewPlan(newPlan) is called when we found a new plan, and there is no
## old plan to replace.
var on_new_plan = func (new_plan: HtnPlan):
	pass

## OnReplacePlan(oldPlan, currentTask, newPlan) is called when we're about to replace the
## current plan with a new plan.
var on_replace_plan = func (old_plan: HtnPlan, current_task: HtnITask, new_plan: HtnPlan):
	pass

## OnNewTask(task) is called after we popped a new task off the current plan.
var on_new_task = func (task: HtnITask):
	pass

## OnNewTaskConditionFailed(task, failedCondition) is called when we failed to
## validate a condition on a new task.
var on_new_task_condition_failed = func (task: HtnITask, failed_condition: HtnICondition):
	pass

## OnStopCurrentTask(task) is called when the currently running task was stopped
## forcefully.
var on_stop_current_task = func (task: HtnITask):
	pass

## OnCurrentTaskCompletedSuccessfully(task) is called when the currently running task
## completes successfully, and before its effects are applied.
var on_current_task_completed_successfully = func (task: HtnITask):
	pass

## OnApplyEffect(effect) is called for each effect of the type PlanAndExecute on a
## completed task.
var on_apply_effect = func (effect: HtnIEffect):
	pass

## OnCurrentTaskFailed(task) is called when the currently running task fails to complete.
var on_current_task_failed = func (_task: HtnITask):
	pass

## OnCurrentTaskContinues(task) is called every tick that a currently running task
## needs to continue.
var on_current_task_continues = func (_task: HtnITask):
	pass

## OnCurrentTaskExecutingConditionFailed(task, condition) is called if an Executing Condition
## fails. The Executing Conditions are checked before every call to task.Operator.Update(...).
var on_current_task_executing_condition_failed = func (_task: HtnITask, _condition: HtnICondition):
	pass

#endregion

func _init() -> void:
	on_new_plan = null
	on_replace_plan = null
	on_new_task = null
	on_new_task_condition_failed = null
	on_stop_current_task = null
	on_current_task_completed_successfully = null
	on_apply_effect = null
	on_current_task_failed = null
	on_current_task_continues = null
	on_current_task_executing_condition_failed = null

#region TICK PLAN

## Call this with a domain and context instance to have the planner manage plan and task handling for the domain at
## runtime.
## If the plan completes or fails, the planner will find a new plan, or if the context is marked dirty, the planner
## will attempt
## a replan to see whether we can find a better plan now that the state of the world has changed.
## This planner can also be used as a blueprint for writing a custom planner.
func tick(domain: HtnIDomain, ctx: HtnIContext, allow_immediate_replan: bool = true) -> void:
	if null == ctx:
		HtnError.set_message("Context was not existed!")
		return
	if null == domain:
		HtnError.set_message("Domain was not existed!")
		return
	if !ctx.is_initialized():
		HtnError.set_message("Context was not initialized!")
		return

	var decomposition_status = Htn.DecompositionStatus.FAILED
	var is_trying_to_replace_plan = false
	# Check whether state has changed or the current plan has finished running.
	# and if so, try to find a new plan.
	if (null == _current_task and _plan.is_empty()) or ctx.is_dirty():
		var last_partial_plan_queue = null

		var world_state_dirty_replan = ctx.is_dirty()
		ctx.set_dirty(false)

		if world_state_dirty_replan:
			# If we're simply re-evaluating whether to replace the current plan because
			# some world state got dirt, then we do not intend to continue a partial plan
			# right now, but rather see whether the world state changed to a degree where
			# we should pursue a better plan. Thus, if this replan fails to find a better
			# plan, we have to add back the partial plan temps cached above.
			if ctx.has_paused_partial_plan():
				ctx.set_paused_partial_plan(false)
				last_partial_plan_queue = []
				while !ctx.get_partial_plan_queue().is_empty():
					last_partial_plan_queue.append(ctx.get_partial_plan_queue().pop_front())

				# We also need to ensure that the last mtr is up to date with the on-going MTR of the partial plan,
				# so that any new potential plan that is decomposing from the domain root has to beat the currently
				# running partial plan.
				ctx.get_last_mtr().clear()
				for record in ctx.get_method_traversal_record():
					ctx.get_last_mtr().append(record)

				if ctx.is_debug_mtr():
					ctx.get_last_mtr_debug().clear()
					for record in ctx.get_mtr_debug():
						ctx.get_last_mtr_debug().append(record)

		var new_plan = HtnPlan.new()
		decomposition_status = domain.find_plan(ctx, new_plan)
		is_trying_to_replace_plan = !_plan.is_empty()
		if Htn.DecompositionStatus.SUCCEEDED == decomposition_status or Htn.DecompositionStatus.PARTIAL == decomposition_status:
			if null != on_replace_plan and (!_plan.is_empty() or null != _current_task):
				on_replace_plan.call(_plan, _current_task, new_plan)
			elif null != on_new_plan and _plan.is_empty():
				on_new_plan.call(new_plan)

			_plan.clear()
			while !new_plan.is_empty():
				_plan.enqueue(new_plan.dequeue())

			if null != _current_task and Htn.TaskType.PRIMITIVE == _current_task.get_type():
				var t: HtnIPrimitiveTask = _current_task
				if null != on_stop_current_task:
					on_stop_current_task.call(t)
				t.stop(ctx)
				_current_task = null

			# Copy the MTR into our LastMTR to represent the current plan's decomposition record
			# that must be beat to replace the plan.
			if null != ctx.get_method_traversal_record():
				ctx.get_last_mtr().clear()
				for record in ctx.get_method_traversal_record():
					ctx.get_last_mtr().append(record)

				if ctx.is_debug_mtr():
					ctx.get_last_mtr_debug().clear()
					for record in ctx.get_mtr_debug():
						ctx.get_last_mtr_debug().append(record)
		elif null != last_partial_plan_queue:
			ctx.set_paused_partial_plan(true)
			ctx.get_partial_plan_queue().clear()
			while !last_partial_plan_queue.is_empty():
				ctx.get_partial_plan_queue().append(last_partial_plan_queue.pop_front())

			if !ctx.get_last_mtr().is_empty():
				ctx.get_method_traversal_record().clear()
				for record in ctx.get_last_mtr():
					ctx.get_method_traversal_record().append(record)
				ctx.get_last_mtr().clear()

				if ctx.is_debug_mtr():
					ctx.get_mtr_debug().clear()
					for record in ctx.get_last_mtr_debug():
						ctx.get_mtr_debug().append(record)
					ctx.get_last_mtr_debug().clear()

	if null == _current_task and !_plan.is_empty():
		_current_task = _plan.dequeue()
		if null != _current_task:
			if null != on_new_task:
				on_new_task.call(_current_task)

			for condition in _current_task.get_conditions():
				# If a condition failed, then the plan failed to progress! A replan is required.
				if !condition.is_valid(ctx):
					if null != on_new_task_condition_failed:
						on_new_task_condition_failed.call(_current_task, condition)

					if Htn.TaskType.PRIMITIVE == _current_task.get_type():
						var task: HtnIPrimitiveTask = _current_task
						task.aborted(ctx)

					_current_task = null
					_plan.clear()

					ctx.get_last_mtr().clear()

					if ctx.is_debug_mtr():
						ctx.get_last_mtr_debug().clear()

					ctx.set_paused_partial_plan(false)
					ctx.get_partial_plan_queue().clear()
					ctx.set_dirty(false)

					return

	if null != _current_task:
		if Htn.TaskType.PRIMITIVE == _current_task.get_type():
			var task: HtnIPrimitiveTask = _current_task
			if null != task.get_operator():
				for condition in task.get_executing_conditions():
					# If a condition failed, then the plan failed to progress! A replan is required.
					if !condition.is_valid(ctx):
						if null != on_current_task_executing_condition_failed:
							on_current_task_executing_condition_failed.call(task, condition)

						task.aborted(ctx)

						_current_task = null
						_plan.clear()

						ctx.get_last_mtr().clear()

						if ctx.is_debug_mtr():
							ctx.get_last_mtr_debug().clear()

						ctx.set_paused_partial_plan(false)
						ctx.get_partial_plan_queue().clear()
						ctx.set_dirty(false)

						if allow_immediate_replan:
							tick(domain, ctx, false)

						return

				_last_status = task.get_operator().update(ctx)

				# If the operation finished successfully, we set task to null so that we dequeue the next task in the plan the following tick.
				if Htn.TaskStatus.SUCCESS == _last_status:
					if null != on_current_task_completed_successfully:
						on_current_task_completed_successfully.call(task)

					# All effects that is a result of running this task should be applied when the task is a success.
					for effect in task.get_effects():
						if Htn.EffectType.PLAN_AND_EXECUTE == effect.get_type():
							if null != on_apply_effect:
								on_apply_effect.call(effect)
							effect.apply(ctx)

					_current_task = null
					if _plan.is_empty():
						ctx.get_last_mtr().clear()

						if ctx.is_debug_mtr():
							ctx.get_last_mtr_debug().clear()

						ctx.set_dirty(false)

						if allow_immediate_replan:
							tick(domain, ctx, false)

				# If the operation failed to finish, we need to fail the entire plan, so that we will replan the next tick.
				elif Htn.TaskStatus.FAILURE == _last_status:
					if null != on_current_task_failed:
						on_current_task_failed.call(task)

					task.aborted(ctx)

					_current_task = null
					_plan.clear()

					ctx.get_last_mtr().clear()

					if ctx.is_debug_mtr():
						ctx.get_last_mtr_debug().clear()

					ctx.set_paused_partial_plan(false)
					ctx.get_partial_plan_queue().clear()
					ctx.set_dirty(false)

				# Otherwise the operation isn't done yet and need to continue.
				else:
					if null != on_current_task_continues:
						on_current_task_continues.call(task)
			else:
				# This should not really happen if a domain is set up properly.
				task.aborted(ctx)
				_current_task = null
				_last_status = Htn.TaskStatus.FAILURE

	if null == _current_task and _plan.is_empty() and !is_trying_to_replace_plan and\
		(Htn.DecompositionStatus.FAILED == decomposition_status or Htn.DecompositionStatus.REJECTED == decomposition_status):
		_last_status = Htn.TaskStatus.FAILURE

#endregion

#region RESET

func reset(ctx: HtnIContext) -> void:
	_plan.clear()

	if null != _current_task and Htn.TaskType.PRIMITIVE == _current_task.get_type():
		var task: HtnIPrimitiveTask = _current_task
		task.stop(ctx)

	_current_task = null

#endregion

#region GETTERS

## Get the current plan. This is not a copy of the running plan, so treat it as read-only.
func get_plan() -> HtnPlan:
	return _plan

## Get the current task.
func get_current_task() -> HtnITask:
	return _current_task

#endregion
