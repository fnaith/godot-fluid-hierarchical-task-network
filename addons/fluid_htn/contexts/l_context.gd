class_name HtnIContext
extends RefCounted

#region checking context type

static var _script_to_inheritance_set: Dictionary = {}

## traverse and collect the inheritance tree of given script into a set
static func _build_inheritance_script_set(script: Script) -> Dictionary:
	var script_set = {}
	while null != script:
		script_set[script] = true
		script = script.get_base_script()
	return script_set

## for any new script, build a inheritance set for type checking
static func _register_script(script: Script) -> bool:
	if !_script_to_inheritance_set.has(script):
		_script_to_inheritance_set[script] = _build_inheritance_script_set(script)
	return true

## register script, but only in debug builds
func _init() -> void:
	assert(_register_script(get_script()))

func is_script(script: Script) -> bool:
	var inheritance_set = _script_to_inheritance_set[get_script()]
	return inheritance_set.has(script)

#endregion

func is_initialized() -> bool:
	assert(false, "Don't use HtnIContext.is_initialized")
	return false

func is_dirty() -> bool:
	assert(false, "Don't use HtnIContext.is_dirty")
	return false
func set_dirty(_b: bool) -> void:
	assert(false, "Don't use HtnIContext.set_dirty")

func get_context_state() -> Htn.ContextState:
	assert(false, "Don't use HtnIContext.get_context_state")
	return 0
func set_context_state(_context_state: Htn.ContextState) -> void:
	assert(false, "Don't use HtnIContext.set_context_state")

func get_current_decomposition_depth() -> int:
	assert(false, "Don't use HtnIContext.get_current_decomposition_depth")
	return 0
func set_current_decomposition_depth(_i: int) -> void:
	assert(false, "Don't use HtnIContext.set_current_decomposition_depth")

## The Method Traversal Record is used while decomposing a domain and
## records the valid decomposition indices as we go through our
## decomposition process.
## It "should" be enough to only record decomposition traversal in Selectors.
## This can be used to compare LastMTR with the MTR, and reject
## a new plan early if it is of lower priority than the last plan.
## It is the user's responsibility to set the instance of the MTR, so that
## the user is free to use pooled instances, or whatever optimization they
## see fit.
func get_method_traversal_record() -> Array[int]:
	assert(false, "Don't use HtnIContext.get_method_traversal_record")
	return []
func set_method_traversal_record(_a: Array[int]) -> void:
	assert(false, "Don't use HtnIContext.set_method_traversal_record")

func get_mtr_debug() -> Array[String]:
	assert(false, "Don't use HtnIContext.get_mtr_debug")
	return []
func set_mtr_debug(_a: Array[String]) -> void:
	assert(false, "Don't use HtnIContext.set_mtr_debug")

## The Method Traversal Record that was recorded for the currently
## running plan.
## If a plan completes successfully, this should be cleared.
## It is the user's responsibility to set the instance of the MTR, so that
## the user is free to use pooled instances, or whatever optimization they
## see fit.
func get_last_mtr() -> Array[int]:
	assert(false, "Don't use HtnIContext.get_last_mtr")
	return []

func get_last_mtr_debug() -> Array[String]:
	assert(false, "Don't use HtnIContext.get_last_mtr_debug")
	return []
func set_last_mtr_debug(_a: Array[String]) -> void:
	assert(false, "Don't use HtnIContext.set_last_mtr_debug")

## Whether the planning system should collect debug information about our Method Traversal Record.
func is_debug_mtr() -> bool:
	assert(false, "Don't use HtnIContext.is_debug_mtr")
	return false

func get_decomposition_log() -> Array[HtnDecompositionLogEntry]: # Queue[]
	assert(false, "Don't use HtnIContext.get_decomposition_log")
	return []
func set_decomposition_log(_a: Array[HtnDecompositionLogEntry]) -> void:
	assert(false, "Don't use HtnIContext.set_decomposition_log")

## Whether our planning system should log our decomposition. Specially condition success vs failure.
func is_log_decomposition() -> bool:
	assert(false, "Don't use HtnIContext.is_log_decomposition")
	return false

func get_partial_plan_queue() -> Array[HtnPartialPlanEntry]: # Queue[]
	assert(false, "Don't use HtnIContext.get_partial_plan_queue")
	return []
func set_partial_plan_queue(_a: Array[HtnPartialPlanEntry]) -> void:
	assert(false, "Don't use HtnIContext.set_partial_plan_queue")

func has_paused_partial_plan() -> bool:
	assert(false, "Don't use HtnIContext.has_paused_partial_plan")
	return false
func set_paused_partial_plan(_b: bool) -> void:
	assert(false, "Don't use HtnIContext.set_paused_partial_plan")

func get_world_state() -> PackedByteArray:
	assert(false, "Don't use HtnIContext.get_world_state")
	return PackedByteArray()

## A stack of changes applied to each world state entry during planning.
## This is necessary if one wants to support planner-only and plan&execute effects.
func get_world_state_change_stack() -> Array[Array]: # Array[Stack[Pair[EffectType, byte]]
	assert(false, "Don't use HtnIContext.get_world_state_change_stack")
	return []

## Reset the context state to default values.
func reset() -> void:
	assert(false, "Don't use HtnIContext.reset")

func trim_for_execution() -> void:
	assert(false, "Don't use trim_for_execution.trim_for_execution")
func trim_to_stack_depth(_stack_depth: Array[int]) -> void:
	assert(false, "Don't use HtnIContext.trim_to_stack_depth")

func has_state(_state: int, _byte_value: int) -> bool:
	assert(false, "Don't use HtnIContext.has_state")
	return false
func get_state(_state: int) -> int:
	assert(false, "Don't use HtnIContext.get_state")
	return 0
func set_state(_state: int, _byte_value: int, _set_as_dirty: bool = true,\
		_e: Htn.EffectType = Htn.EffectType.PERMANENT) -> void:
	assert(false, "Don't use HtnIContext.set_state")

func get_world_state_change_depth() -> Array[int]:
	assert(false, "Don't use HtnIContext.get_world_state_change_depth")
	return []

func log_task(_name: String, _description: String, _depth: int, _task: HtnITask) -> void:
	assert(false, "Don't use HtnIContext.log_task")
func log_condition(_name: String, _description: String, _depth: int,\
		_condition: HtnICondition) -> void:
	assert(false, "Don't use HtnIContext.log_condition")
func log_effect(_name: String, _description: String, _depth: int, _effect: HtnIEffect):
	assert(false, "Don't use HtnIContext.log_effect")
