class_name HtnPausePlanTask
extends HtnITask

#region PROPERTIES

var _name: String
var _parent: HtnICompoundTask
var _conditions: Array[HtnICondition] = []
var _effects: Array[HtnIEffect] = []

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

func get_effects() -> Array[HtnIEffect]:
	return _effects

#endregion

func _init(name: String = "") -> void:
	_name = name

#region checking task type

func get_type() -> Htn.TaskType:
	return Htn.TaskType.PAUSE_PLAN

#endregion

#region VALIDITY

func on_is_valid_failed(_ctx: HtnIContext) -> Htn.DecompositionStatus:
	return Htn.DecompositionStatus.FAILED

#endregion

#region ADDERS

func add_condition(_condition: HtnICondition) -> HtnITask:
	HtnError.set_message("Pause Plan tasks does not support conditions.")
	return null

func add_effects(_effect: HtnIEffect) -> HtnITask:
	HtnError.set_message("Pause Plan tasks does not support effects.")
	return null

#endregion

#region FUNCTIONALITY

func apply_effects(_ctx: HtnIContext) -> void:
	pass

#endregion

#region VALIDITY

func is_valid(ctx: HtnIContext) -> bool:
	if ctx.is_log_decomposition():
		_log(ctx, "PausePlanTask.IsValid:Success!")

	return true

#endregion

#region LOGGING

func _log(ctx: HtnIContext, description: String) -> void:
	ctx.log_task(_name, description, ctx.get_current_decomposition_depth(), self)

#endregion
