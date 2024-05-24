class_name HtnBaseContext
extends HtnIContext

var LogEntry = preload("res://addons/fluid_htn/debug/decomposition_log_entry.gd")

#region PROPERTIES

var _initialized: bool = false
var _dirty: bool = false
var _context_state: Htn.ContextState = Htn.ContextState.EXECUTING
var _current_decomposition_depth: int = 0
var _planner_state: HtnIPlannerState
var _method_traversal_record: Array[int] = []
var _last_mtr: Array[int] = []
var _mtr_debug: Array[String] = []
var _last_mtr_debug: Array[String] = []
var _debug_mtr: bool = false
var _decomposition_log: Array[HtnDecompositionLogEntry] = []
var _log_decomposition: bool = false
var _partial_plan_queue: Array[HtnPartialPlanEntry] = []
var _paused_partial_plan: bool = false

var _world_state: PackedByteArray = PackedByteArray()
var _world_state_change_stack: Array[Array] = []

func is_initialized() -> bool:
	return _initialized

func is_dirty() -> bool:
	return _dirty
func set_dirty(dirty: bool) -> void:
	_dirty = dirty

func get_context_state() -> Htn.ContextState:
	return _context_state
func set_context_state(context_state: Htn.ContextState) -> void:
	_context_state = context_state

func get_current_decomposition_depth() -> int:
	return _current_decomposition_depth
func set_current_decomposition_depth(i: int) -> void:
	_current_decomposition_depth = i

func get_planner_state() -> HtnIPlannerState:
	return _planner_state

func get_method_traversal_record() -> Array[int]:
	return _method_traversal_record
func set_method_traversal_record(a: Array[int]) -> void:
	_method_traversal_record = a

func get_last_mtr() -> Array[int]:
	return _last_mtr

func get_mtr_debug() -> Array[String]:
	return _mtr_debug
func set_mtr_debug(a: Array[String]) -> void:
	_mtr_debug = a

func get_last_mtr_debug() -> Array[String]:
	return _last_mtr_debug
func set_last_mtr_debug(a: Array[String]) -> void:
	_last_mtr_debug = a

func is_debug_mtr() -> bool:
	return _debug_mtr

func get_decomposition_log() -> Array[HtnDecompositionLogEntry]:
	return _decomposition_log
func set_decomposition_log(a: Array[HtnDecompositionLogEntry]) -> void:
	_decomposition_log = a

func is_log_decomposition() -> bool:
	return _log_decomposition

func get_partial_plan_queue() -> Array[HtnPartialPlanEntry]:
	return _partial_plan_queue
func set_partial_plan_queue(a: Array[HtnPartialPlanEntry]) -> void:
	_partial_plan_queue = a

func has_paused_partial_plan() -> bool:
	return _paused_partial_plan
func set_paused_partial_plan(b: bool) -> void:
	_paused_partial_plan = b

func get_world_state() -> PackedByteArray:
	return _world_state

func get_world_state_change_stack() -> Array[Array]:
	return _world_state_change_stack

#endregion

#region INITIALIZATION

func init() -> void:
	var length = _world_state.size()
	if _world_state_change_stack.size() < length:
		_world_state_change_stack.resize(length)
		for i in length:
			_world_state_change_stack[i] = []

	_initialized = true

#endregion

#region STATE HANDLING

func has_state(state: int, byte_value: int) -> bool:
	return byte_value == get_state(state)

func get_state(state: int) -> int:
	if Htn.ContextState.EXECUTING == _context_state:
		return _world_state[state]

	var stack = _world_state_change_stack[state]
	if stack.is_empty():
		return _world_state[state]

	return stack.back()[1]

func set_state(state: int, byte_value: int, set_as_dirty: bool = true,\
		e: Htn.EffectType = Htn.EffectType.PERMANENT) -> void:
	assert(0 <= byte_value and byte_value <= 255)
	if Htn.ContextState.EXECUTING == _context_state:
		# Prevent setting the world state dirty if we're not changing anything.
		if byte_value == _world_state[state]:
			return

		_world_state[state] = byte_value
		if set_as_dirty:
			# When a state change during execution, we need to mark the context dirty for replanning!
			_dirty = true
	else:
		_world_state_change_stack[state].append([e, byte_value])

#endregion

#region STATE STACK HANDLING

func get_world_state_change_depth() -> Array[int]:
	var length = _world_state_change_stack.size()
	var stack_depth: Array[int] = []
	stack_depth.resize(length)

	for i in length:
		var stack = _world_state_change_stack[i]
		stack_depth[i] = 0 if null == stack else stack.size()

	return stack_depth

func trim_for_execution() -> void:
	if Htn.ContextState.EXECUTING == _context_state:
		HtnError.set_message("Can not trim a context when in execution mode")
		return

	for stack in _world_state_change_stack:
		while !stack.is_empty() and Htn.EffectType.PERMANENT != stack.back()[0]:
			stack.pop_back()

func trim_to_stack_depth(stack_depth: Array[int]) -> void:
	if Htn.ContextState.EXECUTING == _context_state:
		HtnError.set_message("Can not trim a context when in execution mode")
		return

	var length = stack_depth.size()
	for i in length:
		var stack = _world_state_change_stack[i]
		while stack_depth[i] < stack.size():
			stack.pop_back()

#endregion

#region STATE RESET

func reset() -> void:
	_method_traversal_record.clear()
	_last_mtr.clear()

	if _debug_mtr:
		_mtr_debug.clear()
		_last_mtr_debug.clear()

	_initialized = false

#endregion

#region DECOMPOSITION LOGGING

func log_task(name: String, description: String, depth: int, task: HtnITask) -> void:
	if !is_log_decomposition():
		return
	var entry = LogEntry.new(name, description, depth, Htn.LogEntryType.TASK, task)
	_decomposition_log.append(entry)

func log_condition(name: String, description: String, depth: int, condition: HtnICondition) -> void:
	if !is_log_decomposition():
		return
	var entry = LogEntry.new(name, description, depth, Htn.LogEntryType.CONDITION, condition)
	_decomposition_log.append(entry)

func log_effect(name: String, description: String, depth: int, effect: HtnIEffect):
	if !is_log_decomposition():
		return
	var entry = LogEntry.new(name, description, depth, Htn.LogEntryType.EFFECT, effect)
	_decomposition_log.append(entry)

#endregion
