class_name HtnPrimitiveTaskTests
extends Object

## Verifies that a primitive task correctly adds a condition to its conditions collection and returns the task itself for method chaining.
## Conditions are validators evaluated during task decomposition to determine whether a task is applicable in the current world state.
## Planning conditions gate whether a task can be selected and included in the plan, enabling data-driven task selection.
## This test ensures the fluent builder pattern works correctly by confirming the method returns the task instance and the condition is stored.
static func add_condition__expected_behavior() -> void:
	var task = HtnPrimitiveTask.new("Test")

	var t = task.add_condition(HtnFuncCondition.new(MyContext, "TestCondition", func (context):
		return !context.is_done()))

	HtnError.add_assert(t == task)
	HtnError.add_assert(1 == task.get_conditions().size())
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that a primitive task correctly adds an executing condition to its executing conditions collection and returns the task itself for method chaining.
## Executing conditions are runtime validators checked before each task execution tick to ensure the task remains valid during execution.
## Unlike planning conditions which gate task selection, executing conditions can invalidate a task mid-execution if world state changes, triggering replanning.
## This test ensures executing conditions are properly stored and that the fluent API pattern returns the task for continued builder usage.
static func add_executing_condition__expected_behavior() -> void:
	var task = HtnPrimitiveTask.new("Test")

	var t = task.add_executing_condition(HtnFuncCondition.new(MyContext, "TestCondition", func (context):
		return !context.is_done()))

	HtnError.add_assert(t == task)
	HtnError.add_assert(1 == task.get_executing_conditions().size())
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that a primitive task correctly adds an effect to its effects collection and returns the task itself for method chaining.
## Effects are world state modifications applied when a task completes, representing the task's impact on the world.
## Effects can be PlanOnly (applied during planning for lookahead), PlanAndExecute (applied during both phases), or Permanent (persist across both phases).
## This test ensures effects are properly collected and that the fluent builder pattern allows chained configuration of effects.
static func add_effect__expected_behavior() -> void:
	var task = HtnPrimitiveTask.new("Test")

	var t = task.add_effect(HtnActionEffect.new(MyContext, "TestEffect", Htn.EffectType.PERMANENT, func (context, _type):
		context.set_done(true)))

	HtnError.add_assert(t == task)
	HtnError.add_assert(1 == task.get_effects().size())
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that a primitive task correctly stores an operator when SetOperator is called, making it available for execution.
## The operator is the execution mechanism that implements the actual work of the primitive task when it is selected for execution.
## Operators manage the task lifecycle (Start for initialization, Update for execution loop, Stop for cleanup) and return TaskStatus to indicate progress.
## This test ensures the task properly retains the operator for later invocation during plan execution.
static func set_operator__expected_behavior() -> void:
	var task = HtnPrimitiveTask.new("Test")

	var result = task.set_operator(HtnFuncOperator.new(MyContext, null, null, null))

	HtnError.add_assert(result)
	HtnError.add_assert(null != task.get_operator())
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that a primitive task throws an exception if SetOperator is called more than once, preventing accidental operator replacement.
## Each primitive task should have exactly one operator for its execution mechanism, as multiple operators would create ambiguity about which should execute.
## Allowing operator replacement could silently introduce bugs where a task's implementation is accidentally overwritten during builder construction.
## This test ensures tasks enforce single-operator semantics by rejecting attempts to set a second operator with a clear exception.
static func set_operator_throws_exception_if_already_set__expected_behavior() -> void:
	var task = HtnPrimitiveTask.new("Test")
	task.set_operator(HtnFuncOperator.new(MyContext, null, null, null))

	var result = task.set_operator(HtnFuncOperator.new(MyContext, null))

	HtnError.add_assert(!result)
	HtnError.add_assert("A Primitive Task can only contain a single Operator!" == HtnError.get_message())

## Verifies that a primitive task correctly applies all its effects to the context when ApplyEffects is called.
## Effects represent the consequences of a task completing and modify the world state to reflect what the task accomplished.
## ApplyEffects is called when a task completes successfully, allowing each effect to update the context based on its type and user-defined logic.
## This test confirms that the task properly iterates through its effects collection and applies each one to the provided context.
static func apply_effects__expected_behavior() -> void:
	var ctx = MyContext.new()
	var task = HtnPrimitiveTask.new("Test")
	task.add_effect(HtnActionEffect.new(MyContext, "TestEffect", Htn.EffectType.PERMANENT, func (context, _type):
		context.set_done(true)))

	task.apply_effects(ctx)

	HtnError.add_assert(ctx.is_done())
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that a primitive task correctly calls its operator's Stop method when Stop is called, allowing the operator to perform cleanup.
## Stop is invoked when a task completes or is interrupted, giving the operator an opportunity to finalize state and perform resource cleanup.
## The operator's Stop function can modify world state to record final results or trigger side effects that persist after task completion.
## This test confirms that the task delegates to its operator's Stop method and that state changes made in Stop are preserved in the context.
static func stop_with_valid_operator__expected_behavior() -> void:
	var ctx = MyContext.new()
	var task = HtnPrimitiveTask.new("Test")
	task.set_operator(HtnFuncOperator.new(MyContext, null, null, func (context):
		context.set_done(true), null))

	var result = task.stop(ctx)

	HtnError.add_assert(result)
	HtnError.add_assert(null != task.get_operator())
	HtnError.add_assert(ctx.is_done())
	HtnError.add_assert("" == HtnError.get_message())

static func abort_with_valid_operator__expected_behavior() -> void:
	var ctx = MyContext.new()
	var task = HtnPrimitiveTask.new("Test")
	task.set_operator(HtnFuncOperator.new(MyContext, null, null, null, func (context):
		context.set_done(true)))

	var result = task.abort(ctx)

	HtnError.add_assert(result)
	HtnError.add_assert(null != task.get_operator())
	HtnError.add_assert(ctx.is_done())
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that a primitive task handles Stop gracefully when no operator is assigned, treating it as a valid no-op.
## Tasks may be created without operators for planning purposes or as intermediate task structures not meant for direct execution.
## Calling Stop on a taskless operator should not throw an exception but rather complete safely without executing any cleanup logic.
## This test ensures tasks are defensive about missing operators and do not fail catastrophically when lifecycle methods are called prematurely.
static func stop_with_null_operator__expected_behavior() -> void:
	var ctx = MyContext.new()
	var task = HtnPrimitiveTask.new("Test")

	var result = task.stop(ctx)

	HtnError.add_assert(!result)
	HtnError.add_assert("" == HtnError.get_message())

static func abort_with_null_operator__expected_behavior() -> void:
	var ctx = MyContext.new()
	var task = HtnPrimitiveTask.new("Test")

	var result = task.abort(ctx)

	HtnError.add_assert(!result)
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that a primitive task's IsValid method returns true only when all its planning conditions are satisfied by the current world state.
## IsValid is called during decomposition to determine whether a task can be selected and included in the plan.
## A task is valid only if every condition it has returns true when evaluated against the context; a single failing condition makes the task invalid.
## This test demonstrates the AND semantics of multiple conditions and shows how adding contradictory conditions (Done == true when Done is false) invalidates the task.
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
	abort_with_valid_operator__expected_behavior()
	HtnError.reset_message()
	stop_with_null_operator__expected_behavior()
	HtnError.reset_message()
	abort_with_null_operator__expected_behavior()
	HtnError.reset_message()
	is_valid__expected_behavior()
