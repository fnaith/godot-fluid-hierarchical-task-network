class_name HtnPlannerTests
extends Object

## Verifies that calling Planner.Tick() with null parameters throws a NullReferenceException.
## The planner requires both a valid domain and context to execute the planning cycle.
## Both parameters are essential: the domain contains the task hierarchy and the context holds world state and planner callbacks.
## This test ensures the planner fails fast with a clear exception when given invalid parameters rather than producing silent failures.
static func tick_with_null_parameters_throws_nre__expected_behavior() -> void:
	var planner = HtnPlanner.new()

	planner.tick(null, null)

	HtnError.add_assert("Context was not existed!" == HtnError.get_message())

## Verifies that calling Planner.Tick() with a null domain but valid context throws an exception.
## The domain is essential as it contains the task hierarchy that defines the planner's decomposition logic.
## Without a domain, the planner cannot find or execute any tasks, making it impossible to generate a valid plan.
## This test validates that the planner enforces the domain requirement through exception throwing.
static func tick_with_null_domain_throws_exception__expected_behavior() -> void:
	var ctx = MyContext.new()
	var planner = HtnPlanner.new()

	planner.tick(null, ctx)

	HtnError.add_assert("Domain was not existed!" == HtnError.get_message())

## Verifies that calling Planner.Tick() with an uninitialized context throws an exception.
## The context must be initialized by calling Init() to set up the internal data structures required for planning and execution.
## Initialization creates the necessary collections for the plan queue, decomposition logging, and world state management.
## This test validates that the planner requires proper context initialization, preventing usage errors.
static func tick_without_initialized_context_throws_exception__expected_behavior() -> void:
	var ctx = MyContext.new()
	var domain = HtnDomain.new("Test")
	var planner = HtnPlanner.new()

	planner.tick(domain, ctx)

	HtnError.add_assert("Context was not initialized!" == HtnError.get_message())

## Verifies that the planner can handle a domain with no tasks without throwing an exception.
## A domain with only a root task and no subtasks is valid but results in an empty plan queue and no executable tasks.
## This test demonstrates that the planner gracefully handles empty domains, completing without error or plan generation.
## This capability is useful for testing and for dynamic domains that start empty and have tasks added at runtime.
static func tick_with_empty_domain__expected_behavior() -> void:
	var ctx = MyContext.new()
	ctx.init()
	var domain = HtnDomain.new("Test")
	var planner = HtnPlanner.new()

	planner.tick(domain, ctx)

	HtnError.add_assert("" == HtnError.get_message())

## Verifies that when a primitive task is selected but has no operator assigned, the planner fails the task appropriately.
## Operators are required to execute primitive tasks during plan execution, so a missing operator is a configuration error.
## When an operator is missing, the task cannot be executed and the planner marks it as failed, failing the entire plan.
## This test demonstrates that the planner validates operator presence and handles missing operators gracefully.
static func tick_with_primitive_task_without_operator__expected_behavior() -> void:
	var ctx = MyContext.new()
	ctx.init()
	var planner = HtnPlanner.new()
	var domain = HtnDomain.new("Test")
	var task1 = HtnSelector.new("Test")
	var task2 = HtnPrimitiveTask.new("Sub-task")
	domain.add_subtask(domain.get_root(), task1)
	domain.add_subtask(task1, task2)

	planner.tick(domain, ctx)

	HtnError.add_assert(null == ctx.get_planner_state().get_current_task())
	HtnError.add_assert(Htn.TaskStatus.FAILURE == ctx.get_planner_state().get_last_status())
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that a FuncOperator with a null function pointer results in task failure when executed.
## FuncOperator is a lambda-based operator implementation that wraps a user-provided function.
## If the function pointer is null, the operator cannot execute and the task fails.
## This test demonstrates that the planner handles null operator functions gracefully by failing the affected task.
static func tick_with_func_operator_with_null_func__expected_behavior() -> void:
	var ctx = MyContext.new()
	ctx.init()
	var planner = HtnPlanner.new()
	var domain = HtnDomain.new("Test")
	var task1 = HtnSelector.new("Test")
	var task2 = HtnPrimitiveTask.new("Sub-task")
	task2.set_operator(HtnFuncOperator.new(MyContext, null))
	domain.add_subtask(domain.get_root(), task1)
	domain.add_subtask(task1, task2)

	planner.tick(domain, ctx)

	HtnError.add_assert(null == ctx.get_planner_state().get_current_task())
	HtnError.add_assert(Htn.TaskStatus.FAILURE == ctx.get_planner_state().get_last_status())
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that a primitive task with an operator that returns Success completes without stack overflow or infinite loops.
## When a task's operator returns Success, the planner pops it from the plan queue and moves to the next task.
## This test ensures proper task completion handling prevents infinite loops or recursion issues.
## The test validates that successful task completion is handled efficiently without performance issues.
static func tick_with_default_success_operator_wont_stack_overflows__expected_behavior() -> void:
	var ctx = MyContext.new()
	ctx.init()
	var planner = HtnPlanner.new()
	var domain = HtnDomain.new("Test")
	var task1 = HtnSelector.new("Test")
	var task2 = HtnPrimitiveTask.new("Sub-task")
	task2.set_operator(HtnFuncOperator.new(MyContext, func (_context):
		return Htn.TaskStatus.SUCCESS))
	domain.add_subtask(domain.get_root(), task1)
	domain.add_subtask(task1, task2)

	planner.tick(domain, ctx)

	HtnError.add_assert(null == ctx.get_planner_state().get_current_task())
	HtnError.add_assert(Htn.TaskStatus.SUCCESS == ctx.get_planner_state().get_last_status())
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that a primitive task with an operator that returns Continue remains active in the plan for the next tick.
## When a task's operator returns Continue, the task is not removed from the plan and remains the current task.
## Continue is used for long-running or multi-tick operations that need to maintain state across multiple planning cycles.
## This test validates that the planner properly maintains task state across ticks when tasks return Continue.
static func tick_with_default_continue_operator__expected_behavior() -> void:
	var ctx = MyContext.new()
	ctx.init()
	var planner = HtnPlanner.new()
	var domain = HtnDomain.new("Test")
	var task1 = HtnSelector.new("Test")
	var task2 = HtnPrimitiveTask.new("Sub-task")
	task2.set_operator(HtnFuncOperator.new(MyContext, func (_context):
		return Htn.TaskStatus.CONTINUE))
	domain.add_subtask(domain.get_root(), task1)
	domain.add_subtask(task1, task2)

	planner.tick(domain, ctx)

	HtnError.add_assert(null != ctx.get_planner_state().get_current_task())
	HtnError.add_assert(Htn.TaskStatus.CONTINUE == ctx.get_planner_state().get_last_status())
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that the OnNewPlan callback is invoked when the planner generates a new plan during decomposition.
## Callbacks are the primary mechanism for applications to observe and react to planning events.
## OnNewPlan fires when the domain decomposition succeeds and produces a new plan queue containing tasks to execute.
## This test demonstrates that callbacks are properly invoked during the planning cycle, enabling external observation of plan generation.
static func on_new_plan__expected_behavior() -> void:
	var result = { "test": false }
	var ctx = MyContext.new()
	ctx.init()
	var planner = HtnPlanner.new()
	ctx.get_planner_state().on_new_plan = func (p):
		result["test"] = (1 == p.size())
	var domain = HtnDomain.new("Test")
	var task1 = HtnSelector.new("Test")
	var task2 = HtnPrimitiveTask.new("Sub-task")
	task2.set_operator(HtnFuncOperator.new(MyContext, func (_context):
		return Htn.TaskStatus.CONTINUE))
	domain.add_subtask(domain.get_root(), task1)
	domain.add_subtask(task1, task2)

	planner.tick(domain, ctx)

	HtnError.add_assert(result["test"])
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that the OnReplacePlan callback is invoked when the planner generates a new plan to replace the currently executing plan.
## OnReplacePlan is triggered during replanning when world state changes invalidate the current plan or a better plan becomes available.
## The callback receives the old plan, the current task being replaced, and the new plan, enabling applications to handle plan transitions.
## This test demonstrates that replanning callbacks work correctly when conditions change during execution.
static func on_replace_plan__expected_behavior() -> void:
	var result = { "test": false }
	var ctx = MyContext.new()
	ctx.init()
	var planner = HtnPlanner.new()
	ctx.get_planner_state().on_replace_plan = func (op, ct, p):
		result["test"] = (op.is_empty() and null != ct and 1 == p.size())
	var domain = HtnDomain.new("Test")
	var task1 = HtnSelector.new("Test1")
	var task2 = HtnSelector.new("Test2")
	var task3 = HtnPrimitiveTask.new("Sub-task1").add_condition(HtnFuncCondition.new(MyContext, "TestCondition", func (context):
		return !context.is_done()))
	var task4 = HtnPrimitiveTask.new("Sub-task2")
	task3.set_operator(HtnFuncOperator.new(MyContext, func (_context):
		return Htn.TaskStatus.CONTINUE))
	task4.set_operator(HtnFuncOperator.new(MyContext, func (_context):
		return Htn.TaskStatus.CONTINUE))
	domain.add_subtask(domain.get_root(), task1)
	domain.add_subtask(domain.get_root(), task2)
	domain.add_subtask(task1, task3)
	domain.add_subtask(task2, task4)

	ctx.set_done(true)
	planner.tick(domain, ctx)

	ctx.set_done(false)
	ctx.set_dirty(true)
	planner.tick(domain, ctx)

	HtnError.add_assert(result["test"])
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that the OnNewTask callback is invoked when the planner pops a new task from the plan queue for execution.
## OnNewTask fires each time a task becomes the current executable task, providing hooks for task-level event handling.
## This callback allows applications to log, monitor, or trigger side effects whenever a new task begins execution.
## This test demonstrates that task-level callbacks are properly invoked during the execution phase of the planner tick.
static func on_new_task__expected_behavior() -> void:
	var result = { "test": false }
	var ctx = MyContext.new()
	ctx.init()
	var planner = HtnPlanner.new()
	ctx.get_planner_state().on_new_task = func (t):
		result["test"] = ("Sub-task" == t.get_name())
	var domain = HtnDomain.new("Test")
	var task1 = HtnSelector.new("Test")
	var task2 = HtnPrimitiveTask.new("Sub-task")
	task2.set_operator(HtnFuncOperator.new(MyContext, func (_context):
		return Htn.TaskStatus.CONTINUE))
	domain.add_subtask(domain.get_root(), task1)
	domain.add_subtask(task1, task2)

	planner.tick(domain, ctx)

	HtnError.add_assert(result["test"])
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that the OnNewTaskConditionFailed callback is invoked when a task's planning conditions fail during decomposition.
## During planning, the planner evaluates conditions to determine which tasks are valid decomposition paths.
## When a condition fails, the task is rejected and the planner explores alternative paths in the hierarchy.
## This test demonstrates that planning-level condition failure callbacks work correctly during domain decomposition.
static func on_new_task_condition_failed__expected_behavior() -> void:
	var result = { "test": false }
	var ctx = MyContext.new()
	ctx.init()
	var planner = HtnPlanner.new()
	ctx.get_planner_state().on_new_task_condition_failed = func (t, _c):
		result["test"] = ("Sub-task1" == t.get_name())
	var domain = HtnDomain.new("Test")
	var task1 = HtnSelector.new("Test1")
	var task2 = HtnSelector.new("Test2")
	var task3 = HtnPrimitiveTask.new("Sub-task1").add_condition(HtnFuncCondition.new(MyContext, "TestCondition", func (context):
		return !context.is_done()))
	var task4 = HtnPrimitiveTask.new("Sub-task2")
	task3.set_operator(HtnFuncOperator.new(MyContext, func (_context):
		return Htn.TaskStatus.SUCCESS))
	# Note that one should not use AddEffect on types that's not part of WorldState unless you
	# know what you're doing. Outside of the WorldState, we don't get automatic trimming of
	# state change. This method is used here only to invoke the desired callback, not because
	# its correct practice.
	task3.add_effect(HtnActionEffect.new(MyContext, "TestEffect", Htn.EffectType.PLAN_AND_EXECUTE, func (context, _type):
		context.set_done(true)))
	task4.set_operator(HtnFuncOperator.new(MyContext, func (_context):
		return Htn.TaskStatus.CONTINUE))
	domain.add_subtask(domain.get_root(), task1)
	domain.add_subtask(domain.get_root(), task2)
	domain.add_subtask(task1, task3)
	domain.add_subtask(task2, task4)

	ctx.set_done(true)
	planner.tick(domain, ctx)

	ctx.set_done(false)
	ctx.set_dirty(true)
	planner.tick(domain, ctx)

	HtnError.add_assert(result["test"])
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that the OnCurrentTaskStarted callback is invoked when a primitive task's operator Start method is called.
## Operators have a Start method that is called once when a task becomes active, separate from the Update method called each tick.
## This callback allows applications to perform one-time initialization when a task begins execution.
## This test demonstrates that operator lifecycle callbacks work correctly during task execution startup.
static func on_start_new_task__expected_behavior() -> void:
	var result = { "test": false }
	var ctx = MyContext.new()
	ctx.init()
	var planner = HtnPlanner.new()
	ctx.get_planner_state().on_current_task_started = func (t):
		result["test"] = ("Sub-task" == t.get_name())
	var domain = HtnDomain.new("Test")
	var task1 = HtnSelector.new("Test")
	var task2 = HtnPrimitiveTask.new("Sub-task")
	task2.set_operator(HtnFuncOperator.new(MyContext, func (_context):
		return Htn.TaskStatus.CONTINUE, func (_context):
		return Htn.TaskStatus.CONTINUE))
	domain.add_subtask(domain.get_root(), task1)
	domain.add_subtask(task1, task2)

	planner.tick(domain, ctx)

	HtnError.add_assert(result["test"])
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that a primitive task can complete successfully during its Start method, before the Update method is called.
## The Start method is not limited to initialization—operators can perform complete work and return Success immediately.
## This feature enables efficient single-tick operations and allows task completion to happen at startup.
## This test demonstrates that task lifecycle callbacks properly reflect successful completion from the Start phase.
static func start_new_task_can_complete_task__expected_behavior() -> void:
	var result = { "test": false }
	var ctx = MyContext.new()
	ctx.init()
	var planner = HtnPlanner.new()
	ctx.get_planner_state().on_current_task_completed_successfully = func (t):
		result["test"] = ("Sub-task" == t.get_name())
	var domain = HtnDomain.new("Test")
	var task1 = HtnSelector.new("Test")
	var task2 = HtnPrimitiveTask.new("Sub-task")
	task2.set_operator(HtnFuncOperator.new(MyContext, func (_context):
		return Htn.TaskStatus.CONTINUE, func (_context):
		return Htn.TaskStatus.SUCCESS))
	domain.add_subtask(domain.get_root(), task1)
	domain.add_subtask(task1, task2)

	planner.tick(domain, ctx)

	HtnError.add_assert(result["test"])
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that a primitive task can fail during its Start method, causing immediate failure without Update calls.
## Operators can determine during initialization that they cannot proceed and return Failure to abort the task.
## This early failure detection enables quick rejection of invalid task executions.
## This test demonstrates that task lifecycle callbacks properly reflect failure initiated from the Start phase.
static func start_new_task_can_fail_task__expected_behavior() -> void:
	var result = { "test": false }
	var ctx = MyContext.new()
	ctx.init()
	var planner = HtnPlanner.new()
	ctx.get_planner_state().on_current_task_failed = func (t):
		result["test"] = ("Sub-task" == t.get_name())
	var domain = HtnDomain.new("Test")
	var task1 = HtnSelector.new("Test")
	var task2 = HtnPrimitiveTask.new("Sub-task")
	task2.set_operator(HtnFuncOperator.new(MyContext, func (_context):
		return Htn.TaskStatus.CONTINUE, func (_context):
		return Htn.TaskStatus.FAILURE))
	domain.add_subtask(domain.get_root(), task1)
	domain.add_subtask(task1, task2)

	planner.tick(domain, ctx)

	HtnError.add_assert(result["test"])
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that the OnStopCurrentTask callback is invoked when a task is stopped due to replanning or plan changes.
## When the plan is replaced, the currently executing task must be stopped to clean up its state and resources.
## The Stop method on the operator is called to perform cleanup before the task is replaced.
## This test demonstrates that task stop callbacks work correctly during plan transitions.
static func on_stop_current_task__expected_behavior() -> void:
	var result = { "test": false }
	var ctx = MyContext.new()
	ctx.init()
	var planner = HtnPlanner.new()
	ctx.get_planner_state().on_stop_current_task = func (t):
		result["test"] = ("Sub-task2" == t.get_name())
	var domain = HtnDomain.new("Test")
	var task1 = HtnSelector.new("Test1")
	var task2 = HtnSelector.new("Test2")
	var task3 = HtnPrimitiveTask.new("Sub-task1").add_condition(HtnFuncCondition.new(MyContext, "TestCondition", func (context):
		return !context.is_done()))
	var task4 = HtnPrimitiveTask.new("Sub-task2")
	task3.set_operator(HtnFuncOperator.new(MyContext, func (_context):
		return Htn.TaskStatus.CONTINUE))
	task4.set_operator(HtnFuncOperator.new(MyContext, func (_context):
		return Htn.TaskStatus.CONTINUE))
	domain.add_subtask(domain.get_root(), task1)
	domain.add_subtask(domain.get_root(), task2)
	domain.add_subtask(task1, task3)
	domain.add_subtask(task2, task4)

	ctx.set_done(true)
	planner.tick(domain, ctx)

	ctx.set_done(false)
	ctx.set_dirty(true)
	planner.tick(domain, ctx)

	HtnError.add_assert(result["test"])
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that the OnCurrentTaskCompletedSuccessfully callback is invoked when a task's operator returns Success.
## This callback fires when a task completes its execution successfully, allowing applications to react to task completion.
## Successful task completion triggers effects and removes the task from the plan queue.
## This test demonstrates that successful task completion callbacks work correctly during plan execution.
static func on_current_task_completed_successfully__expected_behavior() -> void:
	var result = { "test": false }
	var ctx = MyContext.new()
	ctx.init()
	var planner = HtnPlanner.new()
	ctx.get_planner_state().on_current_task_completed_successfully = func (t):
		result["test"] = ("Sub-task1" == t.get_name())
	var domain = HtnDomain.new("Test")
	var task1 = HtnSelector.new("Test1")
	var task2 = HtnSelector.new("Test2")
	var task3 = HtnPrimitiveTask.new("Sub-task1").add_condition(HtnFuncCondition.new(MyContext, "TestCondition", func (context):
		return !context.is_done()))
	var task4 = HtnPrimitiveTask.new("Sub-task2")
	task3.set_operator(HtnFuncOperator.new(MyContext, func (_context):
		return Htn.TaskStatus.SUCCESS))
	task4.set_operator(HtnFuncOperator.new(MyContext, func (_context):
		return Htn.TaskStatus.CONTINUE))
	domain.add_subtask(domain.get_root(), task1)
	domain.add_subtask(domain.get_root(), task2)
	domain.add_subtask(task1, task3)
	domain.add_subtask(task2, task4)

	ctx.set_done(true)
	planner.tick(domain, ctx)

	ctx.set_done(false)
	ctx.set_dirty(true)
	planner.tick(domain, ctx)

	HtnError.add_assert(result["test"])
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that the OnApplyEffect callback is invoked when effects are applied to the context during task completion.
## Effects modify world state when tasks complete, and the planner invokes callbacks for each effect application.
## This callback enables applications to monitor and react to state changes made by task effects.
## This test demonstrates that effect application callbacks work correctly when tasks complete successfully.
static func on_apply_effect__expected_behavior() -> void:
	var result = { "test": false }
	var ctx = MyContext.new()
	ctx.init()
	var planner = HtnPlanner.new()
	ctx.get_planner_state().on_apply_effect = func (e):
		result["test"] = ("TestEffect" == e.get_name())
	var domain = HtnDomain.new("Test")
	var task1 = HtnSelector.new("Test1")
	var task2 = HtnSelector.new("Test2")
	var task3 = HtnPrimitiveTask.new("Sub-task1").add_condition(HtnFuncCondition.new(MyContext, "TestCondition", func (context):
		return !context.has_bool_state(MyContext.WorldState.HAS_A)))
	var task4 = HtnPrimitiveTask.new("Sub-task2")
	task3.set_operator(HtnFuncOperator.new(MyContext, func (_context):
		return Htn.TaskStatus.SUCCESS))
	task3.add_effect(HtnActionEffect.new(MyContext, "TestEffect", Htn.EffectType.PLAN_AND_EXECUTE, func (context, type):
		return context.set_bool_state(MyContext.WorldState.HAS_A, true, type)))
	task4.set_operator(HtnFuncOperator.new(MyContext, func (_context):
		return Htn.TaskStatus.CONTINUE))
	domain.add_subtask(domain.get_root(), task1)
	domain.add_subtask(domain.get_root(), task2)
	domain.add_subtask(task1, task3)
	domain.add_subtask(task2, task4)

	ctx.set_context_state(Htn.ContextState.EXECUTING)
	ctx.set_bool_state(MyContext.WorldState.HAS_A, true, Htn.EffectType.PERMANENT)
	planner.tick(domain, ctx)

	ctx.set_context_state(Htn.ContextState.EXECUTING)
	ctx.set_bool_state(MyContext.WorldState.HAS_A, false, Htn.EffectType.PERMANENT)
	planner.tick(domain, ctx)

	HtnError.add_assert(result["test"])
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that the OnCurrentTaskFailed callback is invoked when a task's operator returns Failure.
## Task failure triggers replanning because the current plan path is no longer viable.
## The callback allows applications to respond to task failures and monitor plan instability.
## This test demonstrates that task failure callbacks work correctly during plan execution.
static func on_current_task_failed__expected_behavior() -> void:
	var result = { "test": false }
	var ctx = MyContext.new()
	ctx.init()
	var planner = HtnPlanner.new()
	ctx.get_planner_state().on_current_task_failed = func (t):
		result["test"] = ("Sub-task" == t.get_name())
	var domain = HtnDomain.new("Test")
	var task1 = HtnSelector.new("Test")
	var task2 = HtnPrimitiveTask.new("Sub-task")
	task2.set_operator(HtnFuncOperator.new(MyContext, func (_context):
		return Htn.TaskStatus.FAILURE))
	domain.add_subtask(domain.get_root(), task1)
	domain.add_subtask(task1, task2)

	planner.tick(domain, ctx)

	HtnError.add_assert(result["test"])
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that the OnCurrentTaskContinues callback is invoked when a task's operator returns Continue.
## Continue indicates that a task needs more time and will remain the current task in the next planning cycle.
## The callback allows applications to monitor long-running task progress and multi-tick operations.
## This test demonstrates that task continuation callbacks work correctly during plan execution.
static func on_current_task_continues__expected_behavior() -> void:
	var result = { "test": false }
	var ctx = MyContext.new()
	ctx.init()
	var planner = HtnPlanner.new()
	ctx.get_planner_state().on_current_task_continues = func (t):
		result["test"] = ("Sub-task" == t.get_name())
	var domain = HtnDomain.new("Test")
	var task1 = HtnSelector.new("Test")
	var task2 = HtnPrimitiveTask.new("Sub-task")
	task2.set_operator(HtnFuncOperator.new(MyContext, func (_context):
		return Htn.TaskStatus.CONTINUE))
	domain.add_subtask(domain.get_root(), task1)
	domain.add_subtask(task1, task2)

	planner.tick(domain, ctx)

	HtnError.add_assert(result["test"])
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that the OnCurrentTaskExecutingConditionFailed callback is invoked when an executing condition fails at runtime.
## Executing conditions are checked before each task update and allow runtime task invalidation when conditions change.
## When an executing condition fails, the task is stopped and replanning is triggered.
## This test demonstrates that executing condition failure callbacks enable dynamic task invalidation during execution.
static func on_current_task_executing_condition_failed__expected_behavior() -> void:
	var result = { "test": false }
	var ctx = MyContext.new()
	ctx.init()
	var planner = HtnPlanner.new()
	ctx.get_planner_state().on_current_task_executing_condition_failed = func (t, c):
		result["test"] = ("Sub-task" == t.get_name() and "TestCondition" == c.get_name())
	var domain = HtnDomain.new("Test")
	var task1 = HtnSelector.new("Test")
	var task2 = HtnPrimitiveTask.new("Sub-task")
	task2.set_operator(HtnFuncOperator.new(MyContext, func (_context):
		return Htn.TaskStatus.CONTINUE))
	task2.add_executing_condition(HtnFuncCondition.new(MyContext, "TestCondition", func (context):
		return context.is_done()))
	domain.add_subtask(domain.get_root(), task1)
	domain.add_subtask(task1, task2)

	planner.tick(domain, ctx)

	HtnError.add_assert(result["test"])
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that the planner can find a better plan when planning conditions change and the current operator returns Continue.
## When world state changes affect planning conditions, the planner can trigger replanning while a task continues executing.
## The planner uses Method Traversal Record (MTR) comparison to decide whether new plans are better than existing ones.
## This test demonstrates that replanning works correctly when conditions improve during task execution.
static func find_plan_if_condition_change_and_operator_is_continuous__expected_behavior() -> void:
	var ctx = MyContext.new()
	ctx.init()

	var planner = HtnPlanner.new()
	var domain = HtnDomain.new("Test")
	var select = HtnSelector.new("Test Select")

	var action_a = HtnPrimitiveTask.new("Test Action A")
	action_a.add_condition(HtnFuncCondition.new(MyContext, "Can choose A", func (context):
		return context.is_done()))
	action_a.add_executing_condition(HtnFuncCondition.new(MyContext, "Can choose A", func (context):
		return context.is_done()))
	action_a.set_operator(MyOperator.new())
	var action_b = HtnPrimitiveTask.new("Test Action B")
	action_b.add_condition(HtnFuncCondition.new(MyContext, "Can not choose A", func (context):
		return !context.is_done()))
	action_b.add_executing_condition(HtnFuncCondition.new(MyContext, "Can not choose A", func (context):
		return !context.is_done()))
	action_b.set_operator(MyOperator.new())

	domain.add_subtask(domain.get_root(), select)
	domain.add_subtask(select, action_a)
	domain.add_subtask(select, action_b)

	planner.tick(domain, ctx, false)
	var plan = ctx.get_planner_state().get_plan()
	var current_task = ctx.get_planner_state().get_current_task()

	HtnError.add_assert(plan.is_valid())
	HtnError.add_assert(plan.is_empty())
	HtnError.add_assert("Test Action B" == current_task.get_name())
	HtnError.add_assert(2 == ctx.get_method_traversal_record().size())
	HtnError.add_assert(0 == ctx.get_method_traversal_record()[0])
	HtnError.add_assert(1 == ctx.get_method_traversal_record()[1])

	# When we change the condition to Done = true, we should now be able to find a better plan!
	ctx.set_done(true)

	planner.tick(domain, ctx, true)
	plan = ctx.get_planner_state().get_plan()
	current_task = ctx.get_planner_state().get_current_task()

	HtnError.add_assert(plan.is_valid())
	HtnError.add_assert(plan.is_empty())
	HtnError.add_assert("Test Action A" == current_task.get_name())
	HtnError.add_assert(2 == ctx.get_method_traversal_record().size())
	HtnError.add_assert(0 == ctx.get_method_traversal_record()[0])
	HtnError.add_assert(0 == ctx.get_method_traversal_record()[1])
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that the planner finds a better plan when world state changes affect task preconditions during continuous execution.
## World state changes can make different tasks valid, triggering the planner to find alternative plans.
## The planner compares MTR values to ensure it only switches to genuinely better plans, not equivalent ones.
## This test demonstrates that replanning responds to world state changes while maintaining plan stability through MTR comparison.
static func find_plan_if_world_state_change_and_operator_is_continuous__expected_behavior() -> void:
	var ctx = MyContext.new()
	ctx.init()

	var planner = HtnPlanner.new()
	var domain = HtnDomain.new("Test")
	var select = HtnSelector.new("Test Select")

	var action_a = HtnPrimitiveTask.new("Test Action A")
	action_a.add_condition(HtnFuncCondition.new(MyContext, "Can choose A", func (context):
		return context.has_bool_state(MyContext.WorldState.HAS_A)))
	action_a.set_operator(MyOperator.new())
	var action_b = HtnPrimitiveTask.new("Test Action B")
	action_b.add_condition(HtnFuncCondition.new(MyContext, "Can not choose A", func (context):
		return !context.has_bool_state(MyContext.WorldState.HAS_A)))
	action_b.set_operator(MyOperator.new())

	domain.add_subtask(domain.get_root(), select)
	domain.add_subtask(select, action_a)
	domain.add_subtask(select, action_b)

	planner.tick(domain, ctx, false)
	var plan = ctx.get_planner_state().get_plan()
	var current_task = ctx.get_planner_state().get_current_task()

	HtnError.add_assert(plan.is_valid())
	HtnError.add_assert(plan.is_empty())
	HtnError.add_assert("Test Action B" == current_task.get_name())
	HtnError.add_assert(2 == ctx.get_method_traversal_record().size())
	HtnError.add_assert(0 == ctx.get_method_traversal_record()[0])
	HtnError.add_assert(1 == ctx.get_method_traversal_record()[1])

	# When we change the condition to Done = true, we should now be able to find a better plan!
	ctx.set_bool_state(MyContext.WorldState.HAS_A, true, Htn.EffectType.PERMANENT)

	planner.tick(domain, ctx, true)
	plan = ctx.get_planner_state().get_plan()
	current_task = ctx.get_planner_state().get_current_task()

	HtnError.add_assert(plan.is_valid())
	HtnError.add_assert(plan.is_empty())
	HtnError.add_assert("Test Action A" == current_task.get_name())
	HtnError.add_assert(2 == ctx.get_method_traversal_record().size())
	HtnError.add_assert(0 == ctx.get_method_traversal_record()[0])
	HtnError.add_assert(0 == ctx.get_method_traversal_record()[1])
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that the planner correctly finds an alternative plan when world state changes make the current plan invalid.
## When the current plan becomes impossible (not just suboptimal), the planner must find any viable alternative.
## The planner triggers replanning and may switch to worse MTR plans if the current plan is completely invalid.
## This test demonstrates that replanning handles forced transitions to suboptimal but valid plans correctly.
static func find_plan_if_world_state_change_to_worse_mtr_and_operator_is_continuous__expected_behavior() -> void:
	var ctx = MyContext.new()
	ctx.init()

	var planner = HtnPlanner.new()
	var domain = HtnDomain.new("Test")
	var select = HtnSelector.new("Test Select")

	var action_a = HtnPrimitiveTask.new("Test Action A")
	action_a.add_condition(HtnFuncCondition.new(MyContext, "Can choose A", func (context):
		return !context.has_bool_state(MyContext.WorldState.HAS_A)))
	action_a.add_executing_condition(HtnFuncCondition.new(MyContext, "Can choose A", func (context):
		return !context.has_bool_state(MyContext.WorldState.HAS_A)))
	action_a.set_operator(MyOperator.new())
	var action_b = HtnPrimitiveTask.new("Test Action B")
	action_b.add_condition(HtnFuncCondition.new(MyContext, "Can not choose A", func (context):
		return context.has_bool_state(MyContext.WorldState.HAS_A)))
	action_b.add_executing_condition(HtnFuncCondition.new(MyContext, "Can not choose A", func (context):
		return context.has_bool_state(MyContext.WorldState.HAS_A)))
	action_b.set_operator(MyOperator.new())

	domain.add_subtask(domain.get_root(), select)
	domain.add_subtask(select, action_a)
	domain.add_subtask(select, action_b)

	planner.tick(domain, ctx, false)
	var plan = ctx.get_planner_state().get_plan()
	var current_task = ctx.get_planner_state().get_current_task()

	HtnError.add_assert(plan.is_valid())
	HtnError.add_assert(plan.is_empty())
	HtnError.add_assert("Test Action A" == current_task.get_name())
	HtnError.add_assert(2 == ctx.get_method_traversal_record().size())
	HtnError.add_assert(0 == ctx.get_method_traversal_record()[0])
	HtnError.add_assert(0 == ctx.get_method_traversal_record()[1])

	# When we change the condition to Done = true, the first plan should no longer be allowed, we should find the second plan instead!
	ctx.set_bool_state(MyContext.WorldState.HAS_A, true, Htn.EffectType.PERMANENT)

	planner.tick(domain, ctx, true)
	plan = ctx.get_planner_state().get_plan()
	current_task = ctx.get_planner_state().get_current_task()

	HtnError.add_assert(plan.is_valid())
	HtnError.add_assert(plan.is_empty())
	HtnError.add_assert("Test Action B" == current_task.get_name())
	HtnError.add_assert(2 == ctx.get_method_traversal_record().size())
	HtnError.add_assert(0 == ctx.get_method_traversal_record()[0])
	HtnError.add_assert(1 == ctx.get_method_traversal_record()[1])
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that toggling between plans using only planning conditions (without executing conditions) results in unstable plan switching.
## Planning conditions are evaluated once during decomposition, but world state changes during execution don't re-evaluate them.
## Therefore, a task with a failed planning condition can still remain the current task if conditions change after decomposition.
## This test demonstrates the limitation of relying only on planning conditions and the need for executing conditions.
static func toggle_between_two_plans_with_only_planner_condition_wont_work__expected_behavior() -> void:
	var c = MyContext.new()
	c.init()

	var planner = HtnPlanner.new()
	var builder = HtnDomainBuilder.new(MyContext, "Test")
	builder.action("A")
	builder.condition("Is True", func (ctx):
		return ctx.has_bool_state(MyContext.WorldState.HAS_A))
	builder.do(func (ctx):
		ctx.set_done(true)
		return Htn.TaskStatus.CONTINUE)
	builder.end()
	builder.action("B")
	builder.condition("Is False", func (ctx):
		return !ctx.has_bool_state(MyContext.WorldState.HAS_A))
	builder.do(func (ctx):
		ctx.set_done(false)
		return Htn.TaskStatus.CONTINUE)
	builder.end()
	var domain = builder.build()

	c.set_bool_state(MyContext.WorldState.HAS_A, true, Htn.EffectType.PERMANENT)
	planner.tick(domain, c)
	HtnError.add_assert(c.is_done()) # We're running Action A

	c.set_bool_state(MyContext.WorldState.HAS_A, false, Htn.EffectType.PERMANENT)
	planner.tick(domain, c)
	HtnError.add_assert(c.is_done()) # Our change triggered a replan, but B can't beat A due to MTR. So A won't get invalidated.

## Verifies that using executing conditions enables smooth toggling between different plans as conditions change at runtime.
## Executing conditions are re-evaluated on each planner tick, allowing tasks to be invalidated when world state changes.
## When an executing condition fails, the planner triggers replanning and can switch to alternative tasks.
## This test demonstrates that executing conditions enable dynamic and responsive plan switching based on runtime conditions.
static func toggle_between_two_plans_with_executing_condition_will_work__expected_behavior() -> void:
	var c = MyContext.new()
	c.init()

	var planner = HtnPlanner.new()
	var builder = HtnDomainBuilder.new(MyContext, "Test")
	builder.action("A")
	builder.condition("Is True", func (ctx):
		return ctx.has_bool_state(MyContext.WorldState.HAS_A))
	builder.executing_condition("Is True", func (ctx):
		return ctx.has_bool_state(MyContext.WorldState.HAS_A))
	builder.do(func (ctx):
		ctx.set_done(true)
		return Htn.TaskStatus.CONTINUE)
	builder.end()
	builder.action("B")
	builder.condition("Is False", func (ctx):
		return !ctx.has_bool_state(MyContext.WorldState.HAS_A))
	builder.executing_condition("Is True", func (ctx):
		return !ctx.has_bool_state(MyContext.WorldState.HAS_A))
	builder.do(func (ctx):
		ctx.set_done(false)
		return Htn.TaskStatus.CONTINUE)
	builder.end()
	var domain = builder.build()

	c.set_bool_state(MyContext.WorldState.HAS_A, true, Htn.EffectType.PERMANENT)
	planner.tick(domain, c)
	HtnError.add_assert(c.is_done()) # We're running A

	c.set_bool_state(MyContext.WorldState.HAS_A, false, Htn.EffectType.PERMANENT)
	planner.tick(domain, c)
	HtnError.add_assert(!c.is_done()) # Out executing condition will realize that A is no longer valid, and we find B instead.

	c.set_bool_state(MyContext.WorldState.HAS_A, true, Htn.EffectType.PERMANENT)
	planner.tick(domain, c)
	HtnError.add_assert(c.is_done()) # We're running A

## Reproduces a corner-case where a primitive task's operator executes twice when a plan completes
## with allowImmediateReplanAndExecute=true.
## 
## When a primitive task's operator returns Success and the plan queue becomes empty,
## the planner triggers an immediate replan with allowImmediateReplanAndExecute=true (default).
## If the task's conditions still pass (e.g., an always-true condition that doesn't check world state),
## the same task may be selected again and executed a second time in the recursive Tick call.
##
## This test demonstrates the corner-case by:
## 1. Creating a selector with a condition that always returns true
## 2. Adding an action that increments ExecutionCount, sets Done flag, and returns Success
## 3. Calling Planner.Tick() once with default allowImmediateReplanAndExecute=true
## 4. Asserting that ExecutionCount should be 2
## 5. We then reset the ExecutionCount and tick the planner again with allowImmediateReplanAndExecute=false
## 6. Assert that ExecutionCount should be 1
##
## This test serves as corner-case documentation to clarify expected behavior.
static func operator_executed_only_once_when_plan_completes__expected_behavior() -> void:
	var ctx = MyContext.new()
	ctx.init()
	ctx.set_execution_count(0) # Track operator executions

	var planner = HtnPlanner.new()
	var domain = HtnDomain.new("Test")

	# Build a simple domain: selector with one action that always succeeds
	# The condition is always true, not checking any world state
	var select = HtnSelector.new("Root Selector")
	var action = HtnPrimitiveTask.new("Complete Action")
	action.add_condition(HtnFuncCondition.new(MyContext, "Always True", func (_context):
		return true))
	action.set_operator(HtnFuncOperator.new(MyContext, func (context):
		var count = context.get_execution_count() + 1
		context.set_execution_count(count)
		context.set_done(true)
		return Htn.TaskStatus.SUCCESS))

	domain.add_subtask(domain.get_root(), select)
	domain.add_subtask(select, action)

	# Execute a single tick with default allowImmediateReplanAndExecute=true
	planner.tick(domain, ctx)

	# EXPECTED: Operator should execute twice because planner is ticked with allowImmediateReplanAndExecute, and the action has
	#           no condition (always true) and return Success immediately, which will trigger immediate replan and select
	#           the same action again. We only replan immediately once in a single planner tick, which prevents this from
	#           going into an infinite loop.
	HtnError.add_assert(2 == ctx.get_execution_count()) # "Operator should execute exactly once, but executed " + ctx.ExecutionCount + " times"
	HtnError.add_assert(ctx.is_done()) # "Task should have completed"
	HtnError.add_assert(ctx.get_planner_state().get_current_task() == null) # "No current task after plan completion"
	HtnError.add_assert(Htn.TaskStatus.SUCCESS == ctx.get_planner_state().get_last_status()) # "Last status should be Success"

	# Reset execution count
	ctx.set_execution_count(0)

	# Execute a single tick with allowImmediateReplanAndExecute=false
	planner.tick(domain, ctx, false)

	# EXPECTED: Operator should execute exactly once now that we don't allow immediate replan.
	HtnError.add_assert(1 == ctx.get_execution_count()) # "Operator should execute exactly once, but executed " + ctx.ExecutionCount + " times"
	HtnError.add_assert(ctx.is_done()) # "Task should have completed"
	HtnError.add_assert(ctx.get_planner_state().get_current_task() == null) # "No current task after plan completion"
	HtnError.add_assert(Htn.TaskStatus.SUCCESS == ctx.get_planner_state().get_last_status()) # "Last status should be Success"

## Verifies that operators can detect condition changes and return Success to enable task switching without executing conditions.
## Operators have access to the context and can check conditions manually during execution.
## If an operator detects that conditions no longer support the current task, it can return Success to complete the task and trigger replanning.
## This test demonstrates an alternative approach to plan switching where operators detect and respond to condition changes.
static func toggle_between_two_plans_with_condition_success_in_operator_will_work__expected_behavior() -> void:
	var c = MyContext.new()
	c.init()

	var planner = HtnPlanner.new()
	var builder = HtnDomainBuilder.new(MyContext, "Test")
	builder.action("A")
	builder.condition("Is True", func (ctx):
		return ctx.has_bool_state(MyContext.WorldState.HAS_A))
	builder.do(func (ctx):
		if !ctx.has_bool_state(MyContext.WorldState.HAS_A):
			return Htn.TaskStatus.SUCCESS
		ctx.set_done(true)
		return Htn.TaskStatus.CONTINUE)
	builder.end()
	builder.action("B")
	builder.condition("Is False", func (ctx):
		return !ctx.has_bool_state(MyContext.WorldState.HAS_A))
	builder.do(func (ctx):
		if ctx.has_bool_state(MyContext.WorldState.HAS_A):
			return Htn.TaskStatus.SUCCESS
		ctx.set_done(false)
		return Htn.TaskStatus.CONTINUE)
	builder.end()
	var domain = builder.build()

	c.set_bool_state(MyContext.WorldState.HAS_A, true, Htn.EffectType.PERMANENT)
	planner.tick(domain, c)
	HtnError.add_assert(c.is_done()) # We're running A

	c.set_bool_state(MyContext.WorldState.HAS_A, false, Htn.EffectType.PERMANENT)
	planner.tick(domain, c)
	HtnError.add_assert(!c.is_done()) # Out executing condition will realize that A is no longer valid, and we find B instead.

	c.set_bool_state(MyContext.WorldState.HAS_A, true, Htn.EffectType.PERMANENT)
	planner.tick(domain, c)
	HtnError.add_assert(c.is_done()) # We're running A

## Verifies that operators returning Failure does not directly enable plan switching in the same way as Success.
## While Failure does trigger replanning, the semantics are different from Success (task failure vs. task completion).
## This test demonstrates the distinction between task failure (which occurs due to errors) and task success (completion).
## Understanding these semantics is important for designing responsive replanning behaviors.
static func toggle_between_two_plans_with_condition_failure_in_operator_wont_work__expected_behavior() -> void:
	var c = MyContext.new()
	c.init()

	var planner = HtnPlanner.new()
	var builder = HtnDomainBuilder.new(MyContext, "Test")
	builder.action("A")
	builder.condition("Is True", func (ctx):
		return ctx.has_bool_state(MyContext.WorldState.HAS_A))
	builder.do(func (ctx):
		if !ctx.has_bool_state(MyContext.WorldState.HAS_A):
			return Htn.TaskStatus.FAILURE
		ctx.set_done(true)
		return Htn.TaskStatus.CONTINUE)
	builder.end()
	builder.action("B")
	builder.condition("Is False", func (ctx):
		return !ctx.has_bool_state(MyContext.WorldState.HAS_A))
	builder.do(func (ctx):
		if ctx.has_bool_state(MyContext.WorldState.HAS_A):
			return Htn.TaskStatus.FAILURE
		ctx.set_done(false)
		return Htn.TaskStatus.CONTINUE)
	builder.end()
	var domain = builder.build()

	c.set_bool_state(MyContext.WorldState.HAS_A, true, Htn.EffectType.PERMANENT)
	planner.tick(domain, c)
	HtnError.add_assert(c.is_done()) # We're running A

	c.set_bool_state(MyContext.WorldState.HAS_A, false, Htn.EffectType.PERMANENT)
	planner.tick(domain, c)
	HtnError.add_assert(!c.is_done()) # Out executing condition will realize that A is no longer valid, and we find B instead.

	c.set_bool_state(MyContext.WorldState.HAS_A, true, Htn.EffectType.PERMANENT)
	planner.tick(domain, c)
	HtnError.add_assert(c.is_done()) # We're running A

static func run() -> void:
	HtnError.reset_message()
	tick_with_null_parameters_throws_nre__expected_behavior()
	HtnError.reset_message()
	tick_with_null_domain_throws_exception__expected_behavior()
	HtnError.reset_message()
	tick_without_initialized_context_throws_exception__expected_behavior()
	HtnError.reset_message()
	tick_with_empty_domain__expected_behavior()
	HtnError.reset_message()
	tick_with_primitive_task_without_operator__expected_behavior()
	HtnError.reset_message()
	tick_with_func_operator_with_null_func__expected_behavior()
	HtnError.reset_message()
	tick_with_default_success_operator_wont_stack_overflows__expected_behavior()
	HtnError.reset_message()
	tick_with_default_continue_operator__expected_behavior()
	HtnError.reset_message()
	on_new_plan__expected_behavior()
	HtnError.reset_message()
	on_replace_plan__expected_behavior()
	HtnError.reset_message()
	on_new_task__expected_behavior()
	HtnError.reset_message()
	on_new_task_condition_failed__expected_behavior()
	HtnError.reset_message()
	on_start_new_task__expected_behavior()
	HtnError.reset_message()
	start_new_task_can_complete_task__expected_behavior()
	HtnError.reset_message()
	start_new_task_can_fail_task__expected_behavior()
	HtnError.reset_message()
	on_stop_current_task__expected_behavior()
	HtnError.reset_message()
	on_current_task_completed_successfully__expected_behavior()
	HtnError.reset_message()
	on_apply_effect__expected_behavior()
	HtnError.reset_message()
	on_current_task_failed__expected_behavior()
	HtnError.reset_message()
	on_current_task_continues__expected_behavior()
	HtnError.reset_message()
	on_current_task_executing_condition_failed__expected_behavior()
	HtnError.reset_message()
	find_plan_if_condition_change_and_operator_is_continuous__expected_behavior()
	HtnError.reset_message()
	find_plan_if_world_state_change_and_operator_is_continuous__expected_behavior()
	HtnError.reset_message()
	find_plan_if_world_state_change_to_worse_mtr_and_operator_is_continuous__expected_behavior()
	HtnError.reset_message()
	toggle_between_two_plans_with_only_planner_condition_wont_work__expected_behavior()
	HtnError.reset_message()
	toggle_between_two_plans_with_executing_condition_will_work__expected_behavior()
	HtnError.reset_message()
	operator_executed_only_once_when_plan_completes__expected_behavior()
	HtnError.reset_message()
	toggle_between_two_plans_with_condition_success_in_operator_will_work__expected_behavior()
	HtnError.reset_message()
	toggle_between_two_plans_with_condition_failure_in_operator_wont_work__expected_behavior()
