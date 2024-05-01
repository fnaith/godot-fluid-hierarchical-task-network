class_name HtnPrimitiveTask
extends HtnIPrimitiveTask

#region PROPERTIES

var _name: String
var _parent: HtnICompoundTask
var _conditions: Array[HtnICondition] = []
var _executing_conditions: Array[HtnICondition] = []
var _operator: HtnIOperator
var _effects: Array[HtnIEffect] = []

func get_name() -> String:
	return _name
func set_name(name: String) -> void:
	_name = name

func get_parent() -> HtnICompoundTask:
	return _parent
func set_parent(parent: HtnICompoundTask) -> void:
	_parent = parent

func get_conditions() -> Array[HtnICondition]:
	return _conditions

func get_executing_conditions() -> Array[HtnICondition]:
	return _executing_conditions

func get_operator() -> HtnIOperator:
	return _operator

func get_effects() -> Array[HtnIEffect]:
	return _effects

#endregion

func _init(name: String) -> void:
	_name = name

#region VALIDITY

func on_is_valid_failed(_ctx: HtnIContext) -> Htn.DecompositionStatus:
	return Htn.DecompositionStatus.FAILED

#endregion

#region ADDERS

func add_condition(condition: HtnICondition) -> HtnITask:
	_conditions.append(condition)
	return self

func add_executing_condition(condition: HtnICondition) -> HtnITask:
	_executing_conditions.append(condition)
	return self

func add_effect(effect: HtnIEffect) -> HtnITask:
	_effects.append(effect)
	return self

#endregion

#region SETTERS

func set_operator(operator: HtnIOperator) -> bool:
	if null != _operator:
		HtnError.set_message("A Primitive Task can only contain a single Operator!")
		return false
	_operator = operator
	return true

#endregion

#region FUNCTIONALITY

func apply_effects(ctx: HtnIContext) -> void:
	if Htn.ContextState.PLANNING == ctx.get_context_state():
		if ctx.is_log_decomposition():
			_log(ctx, "PrimitiveTask.ApplyEffects")
	if ctx.is_log_decomposition():
		ctx.set_current_decomposition_depth(ctx.get_current_decomposition_depth() + 1)
	for effect in _effects:
		effect.apply(ctx)
	if ctx.is_log_decomposition():
		ctx.set_current_decomposition_depth(ctx.get_current_decomposition_depth() - 1)

func stop(ctx: HtnIContext) -> bool:
	if null != _operator:
		_operator.stop(ctx)
		return true
	return false

func aborted(ctx: HtnIContext) -> bool:
	if null != _operator:
		_operator.aborted(ctx)
		return true
	return false

#endregion

#region VALIDITY

func is_valid(ctx: HtnIContext) -> bool:
	if ctx.is_log_decomposition():
		_log(ctx, "PrimitiveTask.IsValid check")

	for condition in _conditions:
		if ctx.is_log_decomposition():
			ctx.set_current_decomposition_depth(ctx.get_current_decomposition_depth() + 1)

		var result = condition.is_valid(ctx)

		if ctx.is_log_decomposition():
			ctx.set_current_decomposition_depth(ctx.get_current_decomposition_depth() - 1)
			var s1 = "Success" if result else "Failed"
			var s2 = "" if result else " not"
			_log(ctx, "PrimitiveTask.IsValid:%s:%s is%s valid!" % [s1, condition.get_name(), s2])

		if !result:
			if ctx.is_log_decomposition():
				_log(ctx, "PrimitiveTask.IsValid:Failed:Preconditions not met!")
			return false

	if ctx.is_log_decomposition():
		_log(ctx, "PrimitiveTask.IsValid:Success!")

	return true

#endregion

#region LOGGING

func _log(ctx: HtnIContext, description: String) -> void:
	ctx.log_task(_name, description, ctx.get_current_decomposition_depth() + 1, self)

#endregion
