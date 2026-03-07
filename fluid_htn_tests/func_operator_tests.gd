class_name HtnFuncOperatorTests
extends Object

static func start_does_nothing_without_function_ptr__expected_behavior() -> void:
	var ctx = MyContext.new()
	var e = HtnFuncOperator.new(MyContext, null)

	var status = e.start(ctx)

	HtnError.add_assert(Htn.TaskStatus.CONTINUE == status)
	HtnError.add_assert("" == HtnError.get_message())

static func update_does_nothing_without_function_ptr__expected_behavior() -> void:
	var ctx = MyContext.new()
	var e = HtnFuncOperator.new(MyContext, null)

	var status = e.update(ctx)

	HtnError.add_assert(Htn.TaskStatus.FAILURE == status)
	HtnError.add_assert("" == HtnError.get_message())

static func stop_does_nothing_without_function_ptr__expected_behavior() -> void:
	var ctx = MyContext.new()
	var e = HtnFuncOperator.new(MyContext, null)

	var result = e.stop(ctx)

	HtnError.add_assert(!result)
	HtnError.add_assert("" == HtnError.get_message())

static func abort_does_nothing_without_function_ptr__expected_behavior() -> void:
	var ctx = MyContext.new()
	var e = HtnFuncOperator.new(MyContext, null)

	var result = e.abort(ctx)

	HtnError.add_assert(!result)
	HtnError.add_assert("" == HtnError.get_message())

static func start_throws_if_bad_context__expected_behavior() -> void:
	var e = HtnFuncOperator.new(MyContext, null)

	var status = e.start(null)

	HtnError.add_assert(Htn.TaskStatus.FAILURE == status)
	HtnError.add_assert("Unexpected context type!" == HtnError.get_message())

static func update_throws_if_bad_context__expected_behavior() -> void:
	var e = HtnFuncOperator.new(MyContext, null)

	var status = e.update(null)

	HtnError.add_assert(Htn.TaskStatus.FAILURE == status)
	HtnError.add_assert("Unexpected context type!" == HtnError.get_message())

static func stop_throws_if_bad_context__expected_behavior() -> void:
	var e = HtnFuncOperator.new(MyContext, null)

	var result = e.stop(null)

	HtnError.add_assert(!result)
	HtnError.add_assert("Unexpected context type!" == HtnError.get_message())

static func abort_throws_if_bad_context__expected_behavior() -> void:
	var e = HtnFuncOperator.new(MyContext, null)

	var result = e.abort(null)

	HtnError.add_assert(!result)
	HtnError.add_assert("Unexpected context type!" == HtnError.get_message())

static func start_returns_status_internal_functionPtr__expected_behavior() -> void:
	var ctx = MyContext.new()
	var e = HtnFuncOperator.new(MyContext, null, func (_context):
		return Htn.TaskStatus.SUCCESS)

	var status = e.start(ctx)

	HtnError.add_assert(Htn.TaskStatus.SUCCESS == status)
	HtnError.add_assert("" == HtnError.get_message())

static func update_returns_status_internal_functionPtr__expected_behavior() -> void:
	var ctx = MyContext.new()
	var e = HtnFuncOperator.new(MyContext, func (_context):
		return Htn.TaskStatus.SUCCESS)

	var status = e.update(ctx)

	HtnError.add_assert(Htn.TaskStatus.SUCCESS == status)
	HtnError.add_assert("" == HtnError.get_message())

static func stop_calls_internal_function_ptr__expected_behavior() -> void:
	var ctx = MyContext.new()
	var e = HtnFuncOperator.new(MyContext, null, null, func (context):
		context.set_done(true), null)

	var result = e.stop(ctx)

	HtnError.add_assert(result)
	HtnError.add_assert(ctx.is_done())
	HtnError.add_assert("" == HtnError.get_message())

static func abort_calls_internal_function_ptr__expected_behavior() -> void:
	var ctx = MyContext.new()
	var e = HtnFuncOperator.new(MyContext, null, null, null, func (context):
		context.set_done(true))

	var result = e.abort(ctx)

	HtnError.add_assert(result)
	HtnError.add_assert(ctx.is_done())
	HtnError.add_assert("" == HtnError.get_message())

static func run() -> void:
	HtnError.reset_message()
	start_does_nothing_without_function_ptr__expected_behavior()
	HtnError.reset_message()
	update_does_nothing_without_function_ptr__expected_behavior()
	HtnError.reset_message()
	stop_does_nothing_without_function_ptr__expected_behavior()
	HtnError.reset_message()
	abort_does_nothing_without_function_ptr__expected_behavior()
	HtnError.reset_message()
	start_throws_if_bad_context__expected_behavior()
	HtnError.reset_message()
	update_throws_if_bad_context__expected_behavior()
	HtnError.reset_message()
	stop_throws_if_bad_context__expected_behavior()
	HtnError.reset_message()
	abort_throws_if_bad_context__expected_behavior()
	HtnError.reset_message()
	start_returns_status_internal_functionPtr__expected_behavior()
	HtnError.reset_message()
	update_returns_status_internal_functionPtr__expected_behavior()
	HtnError.reset_message()
	stop_calls_internal_function_ptr__expected_behavior()
	HtnError.reset_message()
	abort_calls_internal_function_ptr__expected_behavior()
