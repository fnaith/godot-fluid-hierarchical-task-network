class_name MyContext
extends HtnBaseContext

enum WorldState {
	HAS_A = 0,
	HAS_B = 1,
	HAS_C = 2,
}

## Custom state
var _done: bool = false

func _init() -> void:
	super._init()
	for i in WorldState.size():
		_world_state.append(0)
	_debug_mtr = false
	_log_decomposition = false

func is_done() -> bool:
	return _done

func set_done(done: bool) -> void:
	_done = done

func init() -> void:
	super.init()
	# Custom init of state

func has_bool_state(state: WorldState, value: bool = true) -> bool:
	return has_state(state, 1 if value else 0)

func set_bool_state(state: WorldState, value: bool, effect_type: int) -> void:
	set_state(state, 1 if value else 0, true, effect_type)
