class_name HtnITask
extends RefCounted

#region checking task type

func get_type() -> Htn.TaskType:
	assert(false, "Don't use HtnITask.get_type")
	return Htn.TaskType.PRIMITIVE

#endregion

## Used for debugging and identification purposes
func get_name() -> String:
	assert(false, "Don't use HtnITask.get_name")
	return ""
func set_name(_name: String) -> void:
	assert(false, "Don't use HtnITask.set_name")

## The parent of this task in the hierarchy
func get_parent() -> HtnICompoundTask:
	assert(false, "Don't use HtnITask.get_parent")
	return null
func set_parent(_parent: HtnICompoundTask) -> void:
	assert(false, "Don't use HtnITask.set_parent")

## The conditions that must be satisfied for this task to pass as valid.
func get_conditions() -> Array[HtnICondition]:
	assert(false, "Don't use HtnITask.get_conditions")
	return []

## Add a new condition to the task.
func add_condition(_condition: HtnICondition) -> HtnITask:
	assert(false, "Don't use HtnITask.add_condition")
	return null

## Check the task's preconditions, returns true if all preconditions are valid.
func is_valid(_ctx: HtnIContext) -> bool:
	assert(false, "Don't use HtnITask.is_valid")
	return false

func on_is_valid_failed(_ctx: HtnIContext) -> Htn.DecompositionStatus:
	assert(false, "Don't use HtnITask.on_is_valid_failed")
	return 0
