class_name HtnFuncConditionTests
extends Object

## Verifies that a FuncCondition correctly stores and exposes the name parameter provided during construction.
## In hierarchical task network planning, conditions are boolean validators that gate task decomposition and execution.
## Each condition requires a unique name for debugging and logging decomposition decisions.
## This test ensures the condition's Name property returns exactly what was passed to the constructor.
static func sets_name__expected_behavior() -> void:
	var c = HtnFuncCondition.new(MyContext, "Name", null)

	HtnError.add_assert("Name" == c.get_name())
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that a FuncCondition returns false when no validation function is provided, representing an invalid state.
## FuncCondition is a lambda-based wrapper that encapsulates a boolean validation check to be evaluated during planning.
## When a condition has no function pointer, it cannot validate the world state, so returning false signals that the condition cannot be satisfied.
## This test ensures that null function conditions consistently report as invalid rather than throwing exceptions or causing undefined behavior.
static func is_valid_fails_without_function_ptr__expected_behavior() -> void:
	var ctx = MyContext.new()
	var c = HtnFuncCondition.new(MyContext, "Name", null)

	var result = c.is_valid(ctx)

	HtnError.add_assert(!result)
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that a FuncCondition throws an exception when IsValid is called with a null context parameter.
## The context object represents the planner's world state and is essential for conditions to evaluate their validation logic.
## Conditions depend on accessing the context to check state variables and make decomposition decisions during planning.
## This test ensures that the condition validates its input and fails fast with a clear exception when given invalid parameters rather than causing silent failures.
static func is_valid_throws_if_bad_context__expected_behavior() -> void:
	var c = HtnFuncCondition.new(MyContext, "Name", null)

	var result = c.is_valid(null)

	HtnError.add_assert(!result)
	HtnError.add_assert("Unexpected context type!" == HtnError.get_message())

## Verifies that a FuncCondition correctly invokes the lambda function provided during construction when IsValid is called.
## FuncCondition wraps a user-defined boolean function that receives the context and evaluates whether a condition is satisfied in the current world state.
## The lambda is executed during decomposition to gate whether a task is valid for selection, enabling data-driven planning decisions.
## This test confirms that the condition mechanism properly executes the enclosed function and returns the boolean result that reflects the actual world state.
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
