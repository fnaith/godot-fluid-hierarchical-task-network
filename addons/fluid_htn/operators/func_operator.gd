class_name HtnFuncOperator
extends HtnIOperator

#region default callback

static var _DEFAULT_FUNC: Callable = func (_ctx: HtnIContext) -> Htn.TaskStatus:
	return Htn.TaskStatus.SUCCESS
static var _DEFAULT_ACT: Callable = func (_ctx: HtnIContext) -> void:
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

var _fn = _DEFAULT_FUNC
var _fn_stop = _DEFAULT_ACT
var _fn_aborted = _DEFAULT_ACT

#endregion

#region CONSTRUCTION

func _init(context_script: Script, fn, fn_stop = null, fn_aborted = null) -> void:
	_context_script = context_script
	_fn = fn
	_fn_stop = fn_stop
	_fn_aborted = fn_aborted

#endregion

#region FUNCTIONALITY

func update(ctx: HtnIContext) -> Htn.TaskStatus:
	assert(is_context_script(ctx))
	if _expected_context_type:
		return Htn.TaskStatus.FAILURE if null == _fn else _fn.call(ctx)
	HtnError.set_message("Unexpected context type!")
	return Htn.TaskStatus.FAILURE

func stop(ctx: HtnIContext) -> bool:
	assert(is_context_script(ctx))
	if _expected_context_type:
		if null != _fn_stop:
			_fn_stop.call(ctx)
			return true
		return false
	HtnError.set_message("Unexpected context type!")
	return false

func aborted(ctx: HtnIContext) -> bool:
	assert(is_context_script(ctx))
	if _expected_context_type:
		if null != _fn_aborted:
			_fn_aborted.call(ctx)
			return true
		return false
	HtnError.set_message("Unexpected context type!")
	return false

#endregion
