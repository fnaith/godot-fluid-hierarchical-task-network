class_name HtnSlot
extends HtnITask

#region PROPERTIES

var _slot_id: int
var _name: String
var _parent: HtnICompoundTask
var _conditions: Array[HtnICondition] = []
var _subtask: HtnICompoundTask = null

func get_slot_id() -> int:
	return _slot_id
func set_slot_id(slot_id: int) -> void:
	_slot_id = slot_id

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

func get_subtask() -> HtnICompoundTask:
	return _subtask

#endregion

func _init(slot_id: int, name: String) -> void:
	_slot_id = slot_id
	_name = name

#region checking task type

func get_type() -> Htn.TaskType:
	return Htn.TaskType.SLOT

#endregion

#region VALIDITY

func on_is_valid_failed(_ctx: HtnIContext) -> Htn.DecompositionStatus:
	return Htn.DecompositionStatus.FAILED

#endregion

#region ADDERS

func add_condition(_condition: HtnICondition) -> HtnITask:
	HtnError.set_message("Slot tasks does not support conditions.")
	return null

#endregion

#region SET / REMOVE

func set_subtask(subtask: HtnICompoundTask) -> bool:
	if null != _subtask:
		return false
	_subtask = subtask
	return true

func clear_subtask() -> void:
	_subtask = null

#endregion

#region DECOMPOSITION

func decompose(ctx: HtnIContext, start_index: int,\
		result: HtnPlan) -> Htn.DecompositionStatus:
	if null != _subtask:
		return _subtask.decompose(ctx, start_index, result)

	result.invalidate()
	return Htn.DecompositionStatus.FAILED

#endregion

#region VALIDITY

func is_valid(ctx: HtnIContext) -> bool:
	var result = (null != _subtask)

	if ctx.is_log_decomposition():
		var ok = "Success" if result else "Failed"
		_log(ctx, "Slot.IsValid:%s!" % ok)

	return result

#endregion

#region LOGGING

func _log(ctx: HtnIContext, description: String) -> void:
	ctx.log_task(_name, description, ctx.get_current_decomposition_depth(), self)

#endregion
