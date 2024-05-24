class_name TaContext
extends HtnBaseContext

enum WorldState {
	HAS_BOTTLE,
	BOTTLE_IS_OPEN,
	BOTTLE_IS_EMPTY,
	BOTTLE_IS_BROKEN,
	HAS_WEAPON,
	GOAL,
}

var _player: TaPlayer
var _current_screen: TaGameScreen

func get_player() -> TaPlayer:
	return _player

func get_current_screen() -> TaGameScreen:
	return _current_screen

func set_current_screen(current_screen: TaGameScreen) -> void:
	_current_screen = current_screen

func _init(player: TaPlayer) -> void:
	_player = player
	super._init()
	for i in WorldState.size():
		_world_state.append(0)
	_planner_state = HtnDefaultPlannerState.new()
	_debug_mtr = false
	_log_decomposition = true

func has_goal(goal: Ta.GoalState) -> bool:
	return get_goal() == goal

func get_goal() -> Ta.GoalState:
	return get_state(WorldState.GOAL) as Ta.GoalState

func set_goal(goal: Ta.GoalState, set_as_dirty: bool = true, effect_type: Htn.EffectType = Htn.EffectType.PERMANENT) -> void:
	set_state(WorldState.GOAL, goal, set_as_dirty, effect_type)

func has_bool_state(state: MyContext.WorldState, value: bool = true) -> bool:
	return has_state(state, 1 if value else 0)

func set_bool_state(state: MyContext.WorldState, value: bool, effect_type: int) -> void:
	set_state(state, 1 if value else 0, true, effect_type)
