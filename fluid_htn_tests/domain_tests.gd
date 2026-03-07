class_name HtnDomainTests
extends Object

## Verifies that a Domain is created with a TaskRoot as its root task, initialized with the domain's name.
## The domain is the top-level container for the entire HTN task hierarchy, and TaskRoot is the starting point for decomposition.
## TaskRoot is a special compound task that serves as the root of the decomposition tree when the planner begins planning.
## This test confirms that domains properly initialize their root task with the provided domain name for identification.
static func domain_has_root_with_domain_name__expected_behavior() -> void:
	var domain = HtnDomain.new("Test")

	HtnError.add_assert(null != domain.get_root())
	HtnError.add_assert("Test" == domain.get_root().get_name())
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that domain.Add correctly establishes parent-child relationships between tasks.
## Add registers a task as a subtask of a parent task and sets up the parent reference.
## This fluent API enables building task hierarchies where compound tasks contain subtasks that represent alternative or sequential decompositions.
## This test confirms the foundational mechanism for constructing HTN task trees.
static func add_subtask_to_parent__expected_behavior() -> void:
	var domain = HtnDomain.new("Test")
	var task1 = HtnSelector.new("Test")
	var task2 = HtnPrimitiveTask.new("Test")

	domain.add_subtask(task1, task2)

	HtnError.add_assert(task1.get_subtasks().has(task2))
	HtnError.add_assert(task1 == task2.get_parent())
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that FindPlan throws a NullReferenceException when passed a null context parameter.
## FindPlan requires a valid context to access world state and evaluate conditions during decomposition.
## Passing null is a programming error that indicates the planner was not properly initialized.
## This test ensures the domain fails fast with a clear exception rather than allowing silent failures.
static func find_plan_no_ctx_throws_nre__expected_behavior() -> void:
	var domain = HtnDomain.new("Test")

	var plan = HtnPlan.new()
	var status = domain.find_plan(null, plan)

	HtnError.add_assert(Htn.DecompositionStatus.FAILED == status)
	HtnError.add_assert("Context was not existed!" == HtnError.get_message())

## Verifies that FindPlan throws an exception when the context has not been initialized by calling Init.
## Init is required to set up the WorldStateChangeStack and other internal structures that FindPlan depends on.
## Calling FindPlan without initialization indicates a setup error and should fail fast.
## This test ensures the domain validates context state before attempting decomposition.
static func find_plan_uninitialized_context_throws__expected_behavior() -> void:
	var ctx = MyContext.new()
	var domain = HtnDomain.new("Test")

	var plan = HtnPlan.new()
	var status = domain.find_plan(ctx, plan)

	HtnError.add_assert(Htn.DecompositionStatus.FAILED == status)
	HtnError.add_assert(plan.is_valid())
	HtnError.add_assert(plan.is_empty())
	HtnError.add_assert("Context was not initialized!" == HtnError.get_message())

## Verifies that FindPlan returns Rejected status and null plan when the domain has no tasks to decompose.
## An empty domain with only a TaskRoot and no subtasks cannot produce a valid plan since there is no work to be done.
## FindPlan returns Rejected to indicate that no viable plan could be constructed from the given domain structure.
## This test demonstrates graceful handling of empty or invalid domain configurations.
static func find_plan_no_tasks_then_null_plan__expected_behavior() -> void:
	var ctx = MyContext.new()
	ctx.init()
	var domain = HtnDomain.new("Test")

	var plan = HtnPlan.new()
	var status = domain.find_plan(ctx, plan)

	HtnError.add_assert(Htn.DecompositionStatus.REJECTED == status)
	HtnError.add_assert(!plan.is_valid())
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that FindPlan transitions the context state back to Executing after planning completes.
## FindPlan sets context state to Planning during decomposition, then restores it to Executing afterward.
## This ensures the context is in the correct state for the planner to begin executing the resulting plan.
## This test confirms the planning-to-execution state transition is properly managed by the domain.
static func after_find_plan_context_state_is_executing__expected_behavior() -> void:
	var ctx = MyContext.new()
	ctx.init()
	var domain = HtnDomain.new("Test")

	var plan = HtnPlan.new()
	domain.find_plan(ctx, plan)

	HtnError.add_assert(Htn.ContextState.EXECUTING == ctx.get_context_state())
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that FindPlan successfully decomposes a simple domain hierarchy into an executable plan.
## FindPlan recursively decomposes compound tasks into primitive tasks, building a queue of primitive tasks ready for execution.
## The resulting plan queue can be popped to execute tasks in order until completion.
## This test demonstrates the fundamental planning operation where a domain specification becomes an executable task sequence.
static func find_plan__expected_behavior() -> void:
	var ctx = MyContext.new()
	ctx.init()
	var domain = HtnDomain.new("Test")
	var task1 = HtnSelector.new("Test")
	var task2 = HtnPrimitiveTask.new("Sub-task")
	domain.add_subtask(domain.get_root(), task1)
	domain.add_subtask(task1, task2)

	var plan = HtnPlan.new()
	var status = domain.find_plan(ctx, plan)

	HtnError.add_assert(Htn.DecompositionStatus.SUCCEEDED == status)
	HtnError.add_assert(plan.is_valid())
	HtnError.add_assert(1 == plan.size())
	HtnError.add_assert("Sub-task" == plan.peek().get_name())
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that FindPlan correctly trims non-Permanent effects and applies only Permanent effects to world state after planning.
## After successful planning, TrimForExecution removes PlanOnly effects (they're no longer needed) and transitions state changes to execution mode.
## Permanent effects remain and propagate to the actual world state, while PlanAndExecute effects are cleaned from the stack.
## This test demonstrates the effect handling during the transition from planning to execution phase.
static func find_plan_trims_non_permanent_state_change__expected_behavior() -> void:
	var ctx = MyContext.new()
	ctx.init()
	var domain = HtnDomain.new("Test")
	var task1 = HtnSequence.new("Test")
	var task2 = HtnPrimitiveTask.new("Sub-task1").add_effect(HtnActionEffect.new(MyContext, "TestEffect1", Htn.EffectType.PLAN_ONLY, func (context, type):
		context.set_bool_state(MyContext.WorldState.HAS_A, true, type)))
	var task3 = HtnPrimitiveTask.new("Sub-task2").add_effect(HtnActionEffect.new(MyContext, "TestEffect2", Htn.EffectType.PLAN_AND_EXECUTE, func (context, type):
		context.set_bool_state(MyContext.WorldState.HAS_B, true, type)))
	var task4 = HtnPrimitiveTask.new("Sub-task3").add_effect(HtnActionEffect.new(MyContext, "TestEffect3", Htn.EffectType.PERMANENT, func (context, type):
		context.set_bool_state(MyContext.WorldState.HAS_C, true, type)))
	domain.add_subtask(domain.get_root(), task1)
	domain.add_subtask(task1, task2)
	domain.add_subtask(task1, task3)
	domain.add_subtask(task1, task4)

	var plan = HtnPlan.new()
	var status = domain.find_plan(ctx, plan)

	HtnError.add_assert(Htn.DecompositionStatus.SUCCEEDED == status)
	HtnError.add_assert(0 == ctx.get_world_state_change_stack()[MyContext.WorldState.HAS_A].size())
	HtnError.add_assert(0 == ctx.get_world_state_change_stack()[MyContext.WorldState.HAS_B].size())
	HtnError.add_assert(0 == ctx.get_world_state_change_stack()[MyContext.WorldState.HAS_C].size())
	HtnError.add_assert(0 == ctx.get_world_state()[MyContext.WorldState.HAS_A])
	HtnError.add_assert(0 == ctx.get_world_state()[MyContext.WorldState.HAS_B])
	HtnError.add_assert(1 == ctx.get_world_state()[MyContext.WorldState.HAS_C])
	HtnError.add_assert(3 == plan.size())
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that when FindPlan fails to create a plan (Rejected status), all speculative state changes are cleared.
## If planning fails, the world state and change stack must be restored to their original state before planning began.
## This prevents failed planning attempts from corrupting the world state with partial effects.
## This test confirms the rollback mechanism that ensures planning failures don't leave the context in an invalid state.
static func find_plan_clears_state_change_when_plan_is_null__expected_behavior() -> void:
	var ctx = MyContext.new()
	ctx.init()
	var domain = HtnDomain.new("Test")
	var task1 = HtnSequence.new("Test")
	var task2 = HtnPrimitiveTask.new("Sub-task1").add_effect(HtnActionEffect.new(MyContext, "TestEffect1", Htn.EffectType.PLAN_ONLY, func (context, type):
		context.set_bool_state(MyContext.WorldState.HAS_A, true, type)))
	var task3 = HtnPrimitiveTask.new("Sub-task2").add_effect(HtnActionEffect.new(MyContext, "TestEffect2", Htn.EffectType.PLAN_AND_EXECUTE, func (context, type):
		context.set_bool_state(MyContext.WorldState.HAS_B, true, type)))
	var task4 = HtnPrimitiveTask.new("Sub-task3").add_effect(HtnActionEffect.new(MyContext, "TestEffect3", Htn.EffectType.PERMANENT, func (context, type):
		context.set_bool_state(MyContext.WorldState.HAS_C, true, type)))
	var task5 = HtnPrimitiveTask.new("Sub-task4").add_condition(HtnFuncCondition.new(MyContext, "TestCondition", func (context):
		return context.is_done()))
	domain.add_subtask(domain.get_root(), task1)
	domain.add_subtask(task1, task2)
	domain.add_subtask(task1, task3)
	domain.add_subtask(task1, task4)
	domain.add_subtask(task1, task5)

	var plan = HtnPlan.new()
	var status = domain.find_plan(ctx, plan)

	HtnError.add_assert(Htn.DecompositionStatus.REJECTED == status)
	HtnError.add_assert(0 == ctx.get_world_state_change_stack()[MyContext.WorldState.HAS_A].size())
	HtnError.add_assert(0 == ctx.get_world_state_change_stack()[MyContext.WorldState.HAS_B].size())
	HtnError.add_assert(0 == ctx.get_world_state_change_stack()[MyContext.WorldState.HAS_C].size())
	HtnError.add_assert(0 == ctx.get_world_state()[MyContext.WorldState.HAS_A])
	HtnError.add_assert(0 == ctx.get_world_state()[MyContext.WorldState.HAS_B])
	HtnError.add_assert(0 == ctx.get_world_state()[MyContext.WorldState.HAS_C])
	HtnError.add_assert(!plan.is_valid())
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that FindPlan returns Rejected when the Method Traversal Record matches the previous plan's MTR.
## MTR equality indicates that the new decomposition follows the same selector choices as the last plan, making them equivalent.
## Returning the same plan repeatedly would create an infinite loop, so the planner must reject MTR-equal plans to force exploration of alternatives.
## This test demonstrates the MTR-based plan comparison mechanism that prevents repetitive planning cycles.
static func find_plan_if_mtrs_are_equal_then_return_null_plan__expected_behavior() -> void:
	var ctx = MyContext.new()
	ctx.init()
	ctx.get_last_mtr().append(1)
	ctx.get_last_mtr().append(0)

	# Root is a Selector that branch off into task1 selector or task2 sequence.
	# MTR tracks decomposition of compound tasks and priary tasks that are subtasks of selectors,
	# so our MTR is 2 layer deep.
	var domain = HtnDomain.new("Test")
	var task1 = HtnSequence.new("Test1")
	var task2 = HtnSelector.new("Test2")
	var task3 = HtnPrimitiveTask.new("Sub-task1").add_condition(HtnFuncCondition.new(MyContext, "TestCondition", func (context):
		return context.is_done()))
	var task4 = HtnPrimitiveTask.new("Sub-task1")
	var task5 = HtnPrimitiveTask.new("Sub-task2").add_condition(HtnFuncCondition.new(MyContext, "TestCondition", func (context):
		return context.is_done()))
	domain.add_subtask(domain.get_root(), task1)
	domain.add_subtask(domain.get_root(), task2)
	domain.add_subtask(task1, task3)
	domain.add_subtask(task2, task4)
	domain.add_subtask(task2, task5)

	var plan = HtnPlan.new()
	var status = domain.find_plan(ctx, plan)

	HtnError.add_assert(Htn.DecompositionStatus.REJECTED == status)
	HtnError.add_assert(!plan.is_valid())
	HtnError.add_assert(2 == ctx.get_method_traversal_record().size())
	HtnError.add_assert(ctx.get_method_traversal_record()[0] == ctx.get_last_mtr()[0])
	HtnError.add_assert(ctx.get_method_traversal_record()[1] == ctx.get_last_mtr()[1])
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that FindPlan treats plans with equal MTRs as equivalent even if their actual task sequences differ.
## MTR equality is the primary metric for plan comparison; if MTRs are equal, the plans are considered equivalent from a planning perspective.
## This prevents the planner from cycling between different permutations of the same decomposition choices.
## This test confirms that MTR-based equivalence takes precedence over literal task sequence comparison.
static func find_plan_if_plans_are_different_but_mtrs_are_equal_then_return_null_plan__expected_behavior() -> void:
	var ctx = MyContext.new()
	ctx.init()
	ctx.get_last_mtr().append(1)
	ctx.get_last_mtr().append(0)

	# Root is a Selector that branch off into task1 selector or task2 sequence.
	# MTR tracks decomposition of compound tasks and priary tasks that are subtasks of selectors,
	# so our MTR is 2 layer deep.
	var domain = HtnDomain.new("Test")
	var task1 = HtnSequence.new("Test1")
	var task2 = HtnSelector.new("Test2")
	var task3 = HtnPrimitiveTask.new("Sub-task1").add_condition(HtnFuncCondition.new(MyContext, "TestCondition", func (context):
		return context.is_done()))
	var task4 = HtnPrimitiveTask.new("Sub-task1")
	var task5 = HtnPrimitiveTask.new("Sub-task2").add_condition(HtnFuncCondition.new(MyContext, "TestCondition", func (context):
		return context.is_done()))
	domain.add_subtask(domain.get_root(), task1)
	domain.add_subtask(domain.get_root(), task2)
	domain.add_subtask(task1, task3)
	domain.add_subtask(task2, task4)
	domain.add_subtask(task2, task5)

	var plan = HtnPlan.new()
	var status = domain.find_plan(ctx, plan)

	HtnError.add_assert(Htn.DecompositionStatus.REJECTED == status)
	HtnError.add_assert(!plan.is_valid())
	HtnError.add_assert(2 == ctx.get_method_traversal_record().size())
	HtnError.add_assert(ctx.get_method_traversal_record()[0] == ctx.get_last_mtr()[0])
	HtnError.add_assert(ctx.get_method_traversal_record()[1] == ctx.get_last_mtr()[1])
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that FindPlan can find a better plan (with different MTR) when world state changes make it possible.
## When the current MTR is equal to LastMTR, the plan is rejected. However, if world state changes cause a selector to make different choices,
## the new MTR will differ and the new plan will be accepted if valid.
## This test demonstrates the replanning mechanism: state changes can invalidate the last plan, requiring exploration of new decomposition paths.
static func find_plan_if_selector_find_better_primary_task_mtr_change_successfully__expected_behavior() -> void:
	var ctx = MyContext.new()
	ctx.init()
	ctx.get_last_mtr().append(0)
	ctx.get_last_mtr().append(1)

	# Root is a Selector that branch off into two primary tasks.
	# We intend for task3 (Test Action B) to be selected in the first run,
	# but it will be a rejected plan because of LastMTR equality.
	# We then change the Done state to true before we do a replan,
	# and now we intend task 2 (Test Action A) to be selected, since its MTR beast LastMTR score.
	var domain = HtnDomain.new("Test")
	var task1 = HtnSelector.new("Test Select")
	var task2 = HtnPrimitiveTask.new("Test Action A").add_condition(HtnFuncCondition.new(MyContext, "Can choose A", func (context):
		return context.is_done()))
	var task3 = HtnPrimitiveTask.new("Test Action B").add_condition(HtnFuncCondition.new(MyContext, "Can not choose A", func (context):
		return !context.is_done()))
	domain.add_subtask(domain.get_root(), task1)
	domain.add_subtask(task1, task2)
	domain.add_subtask(task1, task3)

	# We expect this to first get rejected, because LastMTR holds [0, 1] which is what we'll get back from the planner.
	var plan = HtnPlan.new()
	var status = domain.find_plan(ctx, plan)

	HtnError.add_assert(Htn.DecompositionStatus.REJECTED == status)
	HtnError.add_assert(!plan.is_valid())
	HtnError.add_assert(2 == ctx.get_method_traversal_record().size())
	HtnError.add_assert(ctx.get_method_traversal_record()[0] == ctx.get_last_mtr()[0])
	HtnError.add_assert(ctx.get_method_traversal_record()[1] == ctx.get_last_mtr()[1])

	# When we change the condition to Done = true, we should now be able to find a better plan!
	ctx.set_done(true)
	status = domain.find_plan(ctx, plan)

	HtnError.add_assert(Htn.DecompositionStatus.SUCCEEDED == status)
	HtnError.add_assert(plan.is_valid())
	HtnError.add_assert(2 == ctx.get_method_traversal_record().size())
	HtnError.add_assert(ctx.get_method_traversal_record()[0] == ctx.get_last_mtr()[0])
	HtnError.add_assert(ctx.get_method_traversal_record()[1] < ctx.get_last_mtr()[1])
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that FindPlan returns Partial status when a PausePlanTask is encountered during decomposition.
## PausePlanTask is a special task that pauses planning, returning control to allow task execution before continuing.
## The context records the pause point with the task and subtask index, enabling continuation later.
## This test demonstrates partial planning where the plan is returned in incremental chunks between pause points.
static func pause_plan__expected_behavior() -> void:
	var ctx = MyContext.new()
	ctx.init()
	var domain = HtnDomain.new("Test")
	var task = HtnSequence.new("Test")
	domain.add_subtask(domain.get_root(), task)
	domain.add_subtask(task, HtnPrimitiveTask.new("Sub-task1"))
	domain.add_subtask(task, HtnPausePlanTask.new())
	domain.add_subtask(task, HtnPrimitiveTask.new("Sub-task2"))

	var plan = HtnPlan.new()
	var status = domain.find_plan(ctx, plan)

	HtnError.add_assert(Htn.DecompositionStatus.PARTIAL == status)
	HtnError.add_assert(plan.is_valid())
	HtnError.add_assert(1 == plan.size())
	HtnError.add_assert("Sub-task1" == plan.peek().get_name())
	HtnError.add_assert(ctx.has_paused_partial_plan())
	HtnError.add_assert(1 == ctx.get_partial_plan_queue().size())
	HtnError.add_assert(task == ctx.get_partial_plan_queue().front().task)
	HtnError.add_assert(2 == ctx.get_partial_plan_queue().front().task_index)
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that calling FindPlan again after a pause resumes decomposition from the pause point.
## The context's PartialPlanQueue tracks where decomposition paused, allowing FindPlan to resume and complete the remaining tasks.
## This enables a two-phase execution model: execute some tasks, then plan the remaining tasks based on execution outcomes.
## This test demonstrates continuation of partial plans and the completion of a paused decomposition.
static func continue_paused_plan__expected_behavior() -> void:
	var ctx = MyContext.new()
	ctx.init()

	var domain = HtnDomain.new("Test")
	var task = HtnSequence.new("Test")
	domain.add_subtask(domain.get_root(), task)
	domain.add_subtask(task, HtnPrimitiveTask.new("Sub-task1"))
	domain.add_subtask(task, HtnPausePlanTask.new())
	domain.add_subtask(task, HtnPrimitiveTask.new("Sub-task2"))

	var plan = HtnPlan.new()
	var status = domain.find_plan(ctx, plan)

	HtnError.add_assert(Htn.DecompositionStatus.PARTIAL == status)
	HtnError.add_assert(plan.is_valid())
	HtnError.add_assert(1 == plan.size())
	HtnError.add_assert("Sub-task1" == plan.peek().get_name())
	HtnError.add_assert(ctx.has_paused_partial_plan())
	HtnError.add_assert(1 == ctx.get_partial_plan_queue().size())
	HtnError.add_assert(task == ctx.get_partial_plan_queue().front().task)
	HtnError.add_assert(2 == ctx.get_partial_plan_queue().front().task_index)

	status = domain.find_plan(ctx, plan)

	HtnError.add_assert(Htn.DecompositionStatus.SUCCEEDED == status)
	HtnError.add_assert(plan.is_valid())
	HtnError.add_assert(1 == plan.size())
	HtnError.add_assert("Sub-task2" == plan.peek().get_name())
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that pauses work correctly with nested compound tasks, maintaining a queue of pause points at multiple nesting levels.
## The PartialPlanQueue is a stack of pause points, each with the task and index where decomposition paused.
## Nested decomposition can pause at multiple levels, and the queue tracks all pause points for proper resumption.
## This test demonstrates partial planning with nested task hierarchies and multiple pause boundaries.
static func nested_pause_plan__expected_behavior() -> void:
	var ctx = MyContext.new()
	ctx.init()

	var domain = HtnDomain.new("Test")
	var task = HtnSequence.new("Test")
	var task2 = HtnSelector.new("Test2")
	var task3 = HtnSequence.new("Test3")

	domain.add_subtask(domain.get_root(), task)
	domain.add_subtask(task, task2)
	domain.add_subtask(task, HtnPrimitiveTask.new("Sub-task4"))

	domain.add_subtask(task2, task3)
	domain.add_subtask(task2, HtnPrimitiveTask.new("Sub-task3"))

	domain.add_subtask(task3, HtnPrimitiveTask.new("Sub-task1"))
	domain.add_subtask(task3, HtnPausePlanTask.new())
	domain.add_subtask(task3, HtnPrimitiveTask.new("Sub-task2"))

	var plan = HtnPlan.new()
	var status = domain.find_plan(ctx, plan)

	HtnError.add_assert(Htn.DecompositionStatus.PARTIAL == status)
	HtnError.add_assert(plan.is_valid())
	HtnError.add_assert(1 == plan.size())
	HtnError.add_assert("Sub-task1" == plan.peek().get_name())
	HtnError.add_assert(ctx.has_paused_partial_plan())
	HtnError.add_assert(2 == ctx.get_partial_plan_queue().size())
	HtnError.add_assert(task3 == ctx.get_partial_plan_queue()[0].task)
	HtnError.add_assert(2 == ctx.get_partial_plan_queue()[0].task_index)
	HtnError.add_assert(task == ctx.get_partial_plan_queue()[1].task)
	HtnError.add_assert(1 == ctx.get_partial_plan_queue()[1].task_index)
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that resuming a nested paused plan correctly continues from all pause points in the queue.
## When continuing, the pause queue is processed in order, resuming each paused task and collecting the remaining tasks.
## This enables multi-level partial execution where different levels of the hierarchy can contribute tasks to the final plan.
## This test demonstrates the full lifecycle of nested partial planning: pause, execute, resume, and completion.
static func continue_nested_pause_plan__expected_behavior() -> void:
	var ctx = MyContext.new()
	ctx.init()
	var domain = HtnDomain.new("Test")

	var task = HtnSequence.new("Test")
	var task2 = HtnSelector.new("Test2")
	var task3 = HtnSequence.new("Test3")

	domain.add_subtask(domain.get_root(), task)
	domain.add_subtask(task, task2)
	domain.add_subtask(task, HtnPrimitiveTask.new("Sub-task4"))

	domain.add_subtask(task2, task3)
	domain.add_subtask(task2, HtnPrimitiveTask.new("Sub-task3"))

	domain.add_subtask(task3, HtnPrimitiveTask.new("Sub-task1"))
	domain.add_subtask(task3, HtnPausePlanTask.new())
	domain.add_subtask(task3, HtnPrimitiveTask.new("Sub-task2"))

	var plan = HtnPlan.new()
	var status = domain.find_plan(ctx, plan)

	HtnError.add_assert(Htn.DecompositionStatus.PARTIAL == status)
	HtnError.add_assert(plan.is_valid())
	HtnError.add_assert(1 == plan.size())
	HtnError.add_assert("Sub-task1" == plan.dequeue().get_name())
	HtnError.add_assert(ctx.has_paused_partial_plan())
	HtnError.add_assert(2 == ctx.get_partial_plan_queue().size())
	HtnError.add_assert(task3 == ctx.get_partial_plan_queue()[0].task)
	HtnError.add_assert(2 == ctx.get_partial_plan_queue()[0].task_index)
	HtnError.add_assert(task == ctx.get_partial_plan_queue()[1].task)
	HtnError.add_assert(1 == ctx.get_partial_plan_queue()[1].task_index)

	status = domain.find_plan(ctx, plan)

	HtnError.add_assert(Htn.DecompositionStatus.SUCCEEDED == status)
	HtnError.add_assert(plan.is_valid())
	HtnError.add_assert(2 == plan.size())
	HtnError.add_assert("Sub-task2" == plan.dequeue().get_name())
	HtnError.add_assert("Sub-task4" == plan.dequeue().get_name())
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that multiple pause points at different nesting levels are correctly queued and resumed in the proper order.
## Partial planning enables breaking decomposition into multiple planning phases via PausePlanTask, where paused decomposition points are stacked.
## When multiple compound tasks have pause points at different nesting levels, the context maintains a stack of pending partial plans that must be resumed in the correct order (innermost depth first, then backing up to outer levels).
## This test demonstrates that the planner correctly manages deep nesting scenarios with multiple pause points, resuming each paused decomposition from the correct task in the correct execution order, ultimately producing a complete plan when all pauses are resumed.
static func continue_multiple_nested_pause__expected_behavior() -> void:
	var ctx = MyContext.new()
	ctx.init()

	var domain = HtnDomain.new("Test")
	var task = HtnSequence.new("Test")
	var task2 = HtnSelector.new("Test2")
	var task3 = HtnSequence.new("Test3")
	var task4 = HtnSequence.new("Test4")

	domain.add_subtask(domain.get_root(), task)

	domain.add_subtask(task3, HtnPrimitiveTask.new("Sub-task1"))
	domain.add_subtask(task3, HtnPausePlanTask.new())
	domain.add_subtask(task3, HtnPrimitiveTask.new("Sub-task2"))

	domain.add_subtask(task2, task3)
	domain.add_subtask(task2, HtnPrimitiveTask.new("Sub-task3"))

	domain.add_subtask(task4, HtnPrimitiveTask.new("Sub-task5"))
	domain.add_subtask(task4, HtnPausePlanTask.new())
	domain.add_subtask(task4, HtnPrimitiveTask.new("Sub-task6"))

	domain.add_subtask(task, task2)
	domain.add_subtask(task, HtnPrimitiveTask.new("Sub-task4"))
	domain.add_subtask(task, task4)
	domain.add_subtask(task, HtnPrimitiveTask.new("Sub-task7"))

	var plan = HtnPlan.new()
	var status = domain.find_plan(ctx, plan)

	HtnError.add_assert(Htn.DecompositionStatus.PARTIAL == status)
	HtnError.add_assert(plan.is_valid())
	HtnError.add_assert(1 == plan.size())
	HtnError.add_assert("Sub-task1" == plan.dequeue().get_name())
	HtnError.add_assert(ctx.has_paused_partial_plan())
	HtnError.add_assert(2 == ctx.get_partial_plan_queue().size())
	HtnError.add_assert(task3 == ctx.get_partial_plan_queue()[0].task)
	HtnError.add_assert(2 == ctx.get_partial_plan_queue()[0].task_index)
	HtnError.add_assert(task == ctx.get_partial_plan_queue()[1].task)
	HtnError.add_assert(1 == ctx.get_partial_plan_queue()[1].task_index)

	status = domain.find_plan(ctx, plan)

	HtnError.add_assert(Htn.DecompositionStatus.PARTIAL == status)
	HtnError.add_assert(plan.is_valid())
	HtnError.add_assert(3 == plan.size())
	HtnError.add_assert("Sub-task2" == plan.dequeue().get_name())
	HtnError.add_assert("Sub-task4" == plan.dequeue().get_name())
	HtnError.add_assert("Sub-task5" == plan.dequeue().get_name())

	status = domain.find_plan(ctx, plan)

	HtnError.add_assert(Htn.DecompositionStatus.SUCCEEDED == status)
	HtnError.add_assert(plan.is_valid())
	HtnError.add_assert(2 == plan.size())
	HtnError.add_assert("Sub-task6" == plan.dequeue().get_name())
	HtnError.add_assert("Sub-task7" == plan.dequeue().get_name())
	HtnError.add_assert("" == HtnError.get_message())

static func run() -> void:
	HtnError.reset_message()
	domain_has_root_with_domain_name__expected_behavior()
	HtnError.reset_message()
	add_subtask_to_parent__expected_behavior()
	HtnError.reset_message()
	find_plan_no_ctx_throws_nre__expected_behavior()
	HtnError.reset_message()
	find_plan_uninitialized_context_throws__expected_behavior()
	HtnError.reset_message()
	find_plan_no_tasks_then_null_plan__expected_behavior()
	HtnError.reset_message()
	after_find_plan_context_state_is_executing__expected_behavior()
	HtnError.reset_message()
	find_plan__expected_behavior()
	HtnError.reset_message()
	find_plan_trims_non_permanent_state_change__expected_behavior()
	HtnError.reset_message()
	find_plan_clears_state_change_when_plan_is_null__expected_behavior()
	HtnError.reset_message()
	find_plan_if_mtrs_are_equal_then_return_null_plan__expected_behavior()
	HtnError.reset_message()
	find_plan_if_plans_are_different_but_mtrs_are_equal_then_return_null_plan__expected_behavior()
	HtnError.reset_message()
	find_plan_if_selector_find_better_primary_task_mtr_change_successfully__expected_behavior()
	HtnError.reset_message()
	pause_plan__expected_behavior()
	HtnError.reset_message()
	continue_paused_plan__expected_behavior()
	HtnError.reset_message()
	nested_pause_plan__expected_behavior()
	HtnError.reset_message()
	continue_nested_pause_plan__expected_behavior()
	HtnError.reset_message()
	continue_multiple_nested_pause__expected_behavior()
