class_name HtnCompoundTask
extends HtnICompoundTask

#region PROPERTIES

var _name: String
var _parent: HtnICompoundTask
var _conditions: Array[HtnICondition] = []
var _subtasks: Array[HtnITask] = []

func get_name() -> String:
	return _name
func set_name(name: String) -> void:
	_name = name

func get_parent() -> HtnICompoundTask:
	return _parent
func set_parent(parent: HtnICompoundTask) -> void:
	_parent = parent

func get_conditions() -> Array[HtnICondition]:
	return _conditions

func get_subtasks() -> Array[HtnITask]:
	return _subtasks

#endregion

#region VALIDITY

func on_is_valid_failed(_ctx: HtnIContext) -> Htn.DecompositionStatus:
	return Htn.DecompositionStatus.FAILED

#endregion

#region ADDERS

func add_condition(condition: HtnICondition) -> HtnITask:
	_conditions.append(condition)
	return self

func add_subtask(subtask: HtnITask) -> HtnICompoundTask:
	_subtasks.append(subtask)
	return self

#endregion

#region DECOMPOSITION

func decompose(ctx: HtnIContext, start_index: int,\
		result: HtnPlan) -> Htn.DecompositionStatus:
	if ctx.is_log_decomposition():
		ctx.set_current_decomposition_depth(ctx.get_current_decomposition_depth() + 1)
	var status = on_decompose(ctx, start_index, result)
	if ctx.is_log_decomposition():
		ctx.set_current_decomposition_depth(ctx.get_current_decomposition_depth() - 1)
	return status

func on_decompose(_ctx: HtnIContext, _start_index: int,\
		_result: HtnPlan) -> Htn.DecompositionStatus:
	assert(false, "Don't use HtnCompoundTask.on_decompose")
	return 0

func on_decompose_task(_ctx: HtnIContext, _task: HtnITask, _task_index: int,\
		_old_stack_depth: Array[int], _result: HtnPlan) -> Htn.DecompositionStatus:
	assert(false, "Don't use HtnCompoundTask.on_decompose_task")
	return 0

func on_decompose_primitive_task(_ctx: HtnIContext, _task: HtnIPrimitiveTask, _task_index: int,\
		_old_stack_depth: Array[int], _result: HtnPlan) -> void:
	assert(false, "Don't use HtnCompoundTask.on_decompose_primitive_task")

func on_decompose_compound_task(_ctx: HtnIContext, _task: HtnICompoundTask, _task_index: int,\
		_old_stack_depth: Array[int], _result: HtnPlan) -> Htn.DecompositionStatus:
	assert(false, "Don't use HtnCompoundTask.on_decompose_compound_task")
	return 0

func on_decompose_slot(_ctx: HtnIContext, _task: HtnSlot, _task_index: int,\
		_old_stack_depth: Array[int], _result: HtnPlan) -> Htn.DecompositionStatus:
	assert(false, "Don't use HtnCompoundTask.on_decompose_slot")
	return 0

#endregion

#region VALIDITY

func is_valid(ctx: HtnIContext) -> bool:
	for condition in _conditions:
		var result = condition.is_valid(ctx)
		if ctx.is_log_decomposition():
			var s1 = "Success" if result else "Failed"
			var s2 = "" if result else " not"
			_log(ctx, "CompoundTask.IsValid:%s:%s is%s valid!" % [s1, condition.get_name(), s2])
		if !result:
			return false
	return true

#endregion

#region LOGGING

func _log(ctx: HtnIContext, description: String) -> void:
	ctx.log_task(_name, description, ctx.get_current_decomposition_depth(), self)

#endregion
