class_name HtnFuncConditionTests
extends Object

static func sets_name__expected_behavior() -> void:
	var c = HtnFuncCondition.new(MyContext, "Name", null)

	HtnError.add_assert("Name" == c.get_name())
	HtnError.add_assert("" == HtnError.get_message())

static func is_valid_fails_without_function_ptr__expected_behavior() -> void:
	var ctx = MyContext.new()
	var c = HtnFuncCondition.new(MyContext, "Name", null)

	var result = c.is_valid(ctx)

	HtnError.add_assert(!result)
	HtnError.add_assert("" == HtnError.get_message())

static func is_valid_throws_if_bad_context__expected_behavior() -> void:
	var c = HtnFuncCondition.new(MyContext, "Name", null)

	var result = c.is_valid(null)

	HtnError.add_assert(!result)
	HtnError.add_assert("Unexpected context type!" == HtnError.get_message())

static func is_valid_calls_internal_function_ptr__expected_behavior() -> void:
	var ctx = MyContext.new()
	var c = HtnFuncCondition.new(MyContext, "Done == false", func (context):
		return !context.is_done())

	var result = c.is_valid(ctx)

	HtnError.add_assert(result)
	HtnError.add_assert("" == HtnError.get_message())

static func run() -> void:
	HtnError.reset_message()
	sets_name__expected_behavior()
	HtnError.reset_message()
	is_valid_fails_without_function_ptr__expected_behavior()
	HtnError.reset_message()
	is_valid_throws_if_bad_context__expected_behavior()
	HtnError.reset_message()
	is_valid_calls_internal_function_ptr__expected_behavior()
