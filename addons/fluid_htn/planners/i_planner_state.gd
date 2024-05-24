class_name HtnIPlannerState
extends RefCounted

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

#region PROPERTIES

func get_current_task() -> HtnITask:
	assert(false, "Don't use HtnIPlannerState.get_current_task")
	return null
func set_current_task(_current_task: HtnITask) -> void:
	assert(false, "Don't use HtnIPlannerState.set_current_task")

func get_plan() -> HtnPlan:
	assert(false, "Don't use HtnIPlannerState.get_plan")
	return null
func set_plan(_plan: HtnPlan) -> void:
	assert(false, "Don't use HtnIPlannerState.set_plan")

func get_last_status() -> Htn.TaskStatus:
	assert(false, "Don't use HtnIPlannerState.get_last_status")
	return Htn.TaskStatus.FAILURE
func set_last_status(_last_status: Htn.TaskStatus) -> void:
	assert(false, "Don't use HtnIPlannerState.set_last_status")

#endregion

#region CALLBACKS

## OnNewPlan(newPlan) is called when we found a new plan, and there is no
## old plan to replace.
var on_new_plan = func (_new_plan: HtnPlan):
	pass

## OnReplacePlan(oldPlan, currentTask, newPlan) is called when we're about to replace the
## current plan with a new plan.
var on_replace_plan = func (_old_plan: HtnPlan, _current_task: HtnITask, _new_plan: HtnPlan):
	pass

## OnNewTask(task) is called after we popped a new task off the current plan.
var on_new_task = func (_task: HtnITask):
	pass

## OnNewTaskConditionFailed(task, failedCondition) is called when we failed to
## validate a condition on a new task.
var on_new_task_condition_failed = func (_task: HtnITask, _failed_condition: HtnICondition):
	pass

## OnStopCurrentTask(task) is called when the currently running task was stopped
## forcefully.
var on_stop_current_task = func (_task: HtnIPrimitiveTask):
	pass

## OnCurrentTaskCompletedSuccessfully(task) is called when the currently running task
## completes successfully, and before its effects are applied.
var on_current_task_completed_successfully = func (_task: HtnIPrimitiveTask):
	pass

## OnApplyEffect(effect) is called for each effect of the type PlanAndExecute on a
## completed task.
var on_apply_effect = func (_effect: HtnIEffect):
	pass

## OnCurrentTaskFailed(task) is called when the currently running task fails to complete.
var on_current_task_failed = func (_task: HtnIPrimitiveTask):
	pass

## OnCurrentTaskContinues(task) is called every tick that a currently running task
## needs to continue.
var on_current_task_continues = func (_task: HtnIPrimitiveTask):
	pass

## OnCurrentTaskExecutingConditionFailed(task, condition) is called if an Executing Condition
## fails. The Executing Conditions are checked before every call to task.Operator.Update(...).
var on_current_task_executing_condition_failed = func (_task: HtnIPrimitiveTask, _condition: HtnICondition):
	pass

#endregion
