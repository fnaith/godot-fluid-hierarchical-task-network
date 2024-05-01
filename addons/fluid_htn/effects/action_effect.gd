class_name HtnActionEffect
extends HtnIEffect

#region default callback

static var _DEFAULT_ACT: Callable = func (_ctx: HtnIContext, _effect_type: Htn.EffectType) -> void:
	return

#endregion

#region checking context type

var _context_script: Script
var _expected_context_type: bool = true

## check context type, but only in debug builds

func is_context_script(ctx: HtnIContext) -> bool:
	_expected_context_type = false if null == ctx else ctx.is_script(_context_script)
	return true

#endregion

#region FIELDS

var _name: String
var _type: Htn.EffectType
var _action = _DEFAULT_ACT

#endregion

#region CONSTRUCTION

func _init(context_script: Script, name: String, type: Htn.EffectType, action) -> void:
	_context_script = context_script
	_name = name
	_type = type
	_action = action

#endregion

#region PROPERTIES

func get_name() -> String:
	return _name

func get_type() -> Htn.EffectType:
	return _type

#endregion

#region FUNCTIONALITY

func apply(ctx: HtnIContext) -> bool:
	assert(is_context_script(ctx))
	if _expected_context_type:
		if ctx.is_log_decomposition():
			ctx.log_effect(_name, "ActionEffect.Apply:%s" % ["PlanAndExecute" if _type == Htn.EffectType.PLAN_AND_EXECUTE else
					"PlanOnly" if _type == Htn.EffectType.PLAN_ONLY else
					"Permanent" if _type == Htn.EffectType.PERMANENT else
					"???"], ctx.get_current_decomposition_depth() + 1, self)
		if null != _action:
			_action.call(ctx, _type)
			return true
		return false
	HtnError.set_message("Unexpected context type!")
	return false

#endregion
