class_name HtnPrimitiveTaskTests
extends Object

static func add_condition__expected_behavior() -> void:
	var task = HtnPrimitiveTask.new("Test")

	var t = task.add_condition(HtnFuncCondition.new(MyContext, "TestCondition", func (context):
		return !context.is_done()))

	HtnError.add_assert(t == task)
	HtnError.add_assert(1 == task.get_conditions().size())
	HtnError.add_assert("" == HtnError.get_message())

static func add_executing_condition__expected_behavior() -> void:
	var task = HtnPrimitiveTask.new("Test")

	var t = task.add_executing_condition(HtnFuncCondition.new(MyContext, "TestCondition", func (context):
		return !context.is_done()))

	HtnError.add_assert(t == task)
	HtnError.add_assert(1 == task.get_executing_conditions().size())
	HtnError.add_assert("" == HtnError.get_message())

static func add_effect__expected_behavior() -> void:
	var task = HtnPrimitiveTask.new("Test")

	var t = task.add_effect(HtnActionEffect.new(MyContext, "TestEffect", Htn.EffectType.PERMANENT, func (context, _type):
		context.set_done(true)))

	HtnError.add_assert(t == task)
	HtnError.add_assert(1 == task.get_effects().size())
	HtnError.add_assert("" == HtnError.get_message())

static func set_operator__expected_behavior() -> void:
	var task = HtnPrimitiveTask.new("Test")

	var result = task.set_operator(HtnFuncOperator.new(MyContext, null, null, null))

	HtnError.add_assert(result)
	HtnError.add_assert(null != task.get_operator())
	HtnError.add_assert("" == HtnError.get_message())

static func set_operator_throws_exception_if_already_set__expected_behavior() -> void:
	var task = HtnPrimitiveTask.new("Test")
	task.set_operator(HtnFuncOperator.new(MyContext, null, null, null))

	var result = task.set_operator(HtnFuncOperator.new(MyContext, null))

	HtnError.add_assert(!result)
	HtnError.add_assert("A Primitive Task can only contain a single Operator!" == HtnError.get_message())

static func apply_effects__expected_behavior() -> void:
	var ctx = MyContext.new()
	var task = HtnPrimitiveTask.new("Test")
	task.add_effect(HtnActionEffect.new(MyContext, "TestEffect", Htn.EffectType.PERMANENT, func (context, _type):
		context.set_done(true)))

	task.apply_effects(ctx)

	HtnError.add_assert(ctx.is_done())
	HtnError.add_assert("" == HtnError.get_message())

static func stop_with_valid_operator__expected_behavior() -> void:
	var ctx = MyContext.new()
	var task = HtnPrimitiveTask.new("Test")
	task.set_operator(HtnFuncOperator.new(MyContext, null, func (context):
		context.set_done(true)))

	var result = task.stop(ctx)

	HtnError.add_assert(result)
	HtnError.add_assert(null != task.get_operator())
	HtnError.add_assert(ctx.is_done())
	HtnError.add_assert("" == HtnError.get_message())

static func aborted_with_valid_operator__expected_behavior() -> void:
	var ctx = MyContext.new()
	var task = HtnPrimitiveTask.new("Test")
	task.set_operator(HtnFuncOperator.new(MyContext, null, null, func (context):
		context.set_done(true)))

	var result = task.aborted(ctx)

	HtnError.add_assert(result)
	HtnError.add_assert(null != task.get_operator())
	HtnError.add_assert(ctx.is_done())
	HtnError.add_assert("" == HtnError.get_message())

static func stop_with_null_operator__expected_behavior() -> void:
	var ctx = MyContext.new()
	var task = HtnPrimitiveTask.new("Test")

	var result = task.stop(ctx)

	HtnError.add_assert(!result)
	HtnError.add_assert("" == HtnError.get_message())

static func aborted_with_null_operator__expected_behavior() -> void:
	var ctx = MyContext.new()
	var task = HtnPrimitiveTask.new("Test")

	var result = task.aborted(ctx)

	HtnError.add_assert(!result)
	HtnError.add_assert("" == HtnError.get_message())

static func is_valid__expected_behavior() -> void:
	var ctx = MyContext.new()
	var task = HtnPrimitiveTask.new("Test")

	task.add_condition(HtnFuncCondition.new(MyContext, "Done == false", func (context):
		return !context.is_done()))
	var expect_true = task.is_valid(ctx)
	task.add_condition(HtnFuncCondition.new(MyContext, "Done == true", func (context):
		return context.is_done()))
	var expect_false = task.is_valid(ctx)

	HtnError.add_assert(expect_true)
	HtnError.add_assert(!expect_false)

static func run() -> void:
	HtnError.reset_message()
	add_condition__expected_behavior()
	HtnError.reset_message()
	add_executing_condition__expected_behavior()
	HtnError.reset_message()
	add_effect__expected_behavior()
	HtnError.reset_message()
	set_operator__expected_behavior()
	HtnError.reset_message()
	set_operator_throws_exception_if_already_set__expected_behavior()
	HtnError.reset_message()
	apply_effects__expected_behavior()
	HtnError.reset_message()
	stop_with_valid_operator__expected_behavior()
	HtnError.reset_message()
	aborted_with_valid_operator__expected_behavior()
	HtnError.reset_message()
	stop_with_null_operator__expected_behavior()
	HtnError.reset_message()
	aborted_with_null_operator__expected_behavior()
	HtnError.reset_message()
	is_valid__expected_behavior()
