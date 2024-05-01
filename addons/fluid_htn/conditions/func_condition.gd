class_name HtnFuncCondition
extends HtnICondition

#region default callback

static var _DEFAULT_FUNC: Callable = func (_ctx: HtnIContext) -> bool:
	return false

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

var _fn = _DEFAULT_FUNC
var _name: String

#endregion

#region CONSTRUCTION

func _init(context_class: Script, name: String, fn = null) -> void:
	_context_script = context_class
	_name = name
	_fn = fn

#endregion

#region PROPERTIES

func get_name() -> String:
	return _name

#endregion

#region VALIDITY

func is_valid(ctx: HtnIContext) -> bool:
	assert(is_context_script(ctx))
	if _expected_context_type:
		var result = (false if null == _fn else _fn.call(ctx))
		if ctx.is_log_decomposition():
			var ok = "True" if result else "False"
			ctx.log_condition(_name, "FuncCondition.IsValid:%s" % ok, ctx.get_current_decomposition_depth() + 1, self)
		return result
	HtnError.set_message("Unexpected context type!")
	return false

#endregion
