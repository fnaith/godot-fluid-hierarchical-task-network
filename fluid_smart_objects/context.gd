class_name SoContext
extends HtnBaseContext

enum WorldState {
	LOCATION,
}

var _player: SoPlayer
var _world: SoWorld

func get_player() -> SoPlayer:
	return _player

func get_world() -> SoWorld:
	return _world

func _init(player: SoPlayer, world: SoWorld) -> void:
	_player = player
	_world = world
	super._init()
	for i in WorldState.size():
		_world_state.append(0)
	_planner_state = HtnDefaultPlannerState.new()
	_debug_mtr = true
	_log_decomposition = true

func init() -> void:
	super.init()

	# Custom init of state

func has_bool_state(state: MyContext.WorldState, value: bool = true) -> bool:
	return has_state(state, 1 if value else 0)

func set_bool_state(state: MyContext.WorldState, value: bool, effect_type: int) -> void:
	set_state(state, 1 if value else 0, true, effect_type)
