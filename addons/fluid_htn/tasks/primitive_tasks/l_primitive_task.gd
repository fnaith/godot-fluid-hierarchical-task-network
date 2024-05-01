class_name HtnIPrimitiveTask
extends HtnITask

#region checking task type

func get_type() -> Htn.TaskType:
	return Htn.TaskType.PRIMITIVE

#endregion

## Executing conditions are validated before every call to Operator.Update(...)
func get_executing_conditions() -> Array[HtnICondition]:
	assert(false, "Don't use HtnIPrimitiveTask.get_executing_conditions")
	return []

## Add a new executing condition to the primitive task. This will be checked before
## every call to Operator.Update(...)
func add_executing_condition(_condition: HtnICondition) -> HtnITask:
	assert(false, "Don't use HtnIPrimitiveTask.add_executing_condition")
	return null

func get_operator() -> HtnIOperator:
	assert(false, "Don't use HtnIPrimitiveTask.get_operator")
	return null
func set_operator(_operator: HtnIOperator) -> bool:
	assert(false, "Don't use HtnIPrimitiveTask.get_operator")
	return false

func get_effects() -> Array[HtnIEffect]:
	assert(false, "Don't use HtnIPrimitiveTask.get_effects")
	return []
func add_effect(_effect: HtnIEffect) -> HtnITask:
	assert(false, "Don't use HtnIPrimitiveTask.add_effect")
	return null
func apply_effects(_ctx: HtnIContext) -> void:
	assert(false, "Don't use HtnIPrimitiveTask.add_effect")

func stop(_ctx: HtnIContext) -> bool:
	assert(false, "Don't use HtnIPrimitiveTask.stop")
	return false

func aborted(_ctx: HtnIContext) -> bool:
	assert(false, "Don't use HtnIPrimitiveTask.aborted")
	return false
