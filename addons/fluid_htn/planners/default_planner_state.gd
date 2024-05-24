class_name HtnDefaultPlannerState
extends HtnIPlannerState

func _init() -> void:
	super._init()

#region PROPERTIES

var _current_task: HtnITask
var _plan: HtnPlan = HtnPlan.new()
var _last_status: Htn.TaskStatus

func get_current_task() -> HtnITask:
	return _current_task
func set_current_task(current_task: HtnITask) -> void:
	_current_task = current_task

func get_plan() -> HtnPlan:
	return _plan
func set_plan(plan: HtnPlan) -> void:
	_plan = plan

func get_last_status() -> Htn.TaskStatus:
	return _last_status
func set_last_status(last_status: Htn.TaskStatus) -> void:
	_last_status = last_status

#endregion
