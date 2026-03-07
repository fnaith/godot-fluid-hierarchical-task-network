class_name HtnSequenceTests
extends Object

## Verifies that a Sequence correctly adds a condition to its conditions collection and returns itself for method chaining.
## A Sequence is a compound task that decomposes by executing all subtasks in strict order, unlike a Selector which tries alternatives.
## Conditions gate whether a sequence is applicable before decomposition begins, evaluated against the current world state.
## This test ensures the fluent builder pattern works correctly for sequences by confirming conditions are stored and the method returns the task instance.
static func add_condition__expected_behavior() -> void:
	var task = HtnSequence.new("Test")

	var t = task.add_condition(HtnFuncCondition.new(MyContext, "TestCondition", func (context):
		return !context.is_done()))

	HtnError.add_assert(t == task)
	HtnError.add_assert(1 == task.get_conditions().size())
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that a Sequence correctly adds a subtask to its subtasks collection and returns itself for method chaining.
## Sequences maintain an ordered list of subtasks that must all decompose successfully in sequence (AND semantics).
## Unlike selectors which try alternatives until one succeeds, sequences must decompose every subtask in order.
## This test confirms the fluent builder pattern allows chaining subtask additions and that each subtask is properly stored.
static func add_subtask__expected_behavior() -> void:
	var task = HtnSequence.new("Test")

	var t = task.add_subtask(HtnPrimitiveTask.new("Sub-task"))

	HtnError.add_assert(t == task)
	HtnError.add_assert(1 == task.get_subtasks().size())
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that a Sequence with no subtasks is considered invalid and cannot be decomposed.
## A sequence requires at least one subtask to execute in sequence; an empty sequence has nothing to accomplish.
## During decomposition validation, the planner checks if a sequence is valid before attempting decomposition, rejecting invalid sequences early.
## This test ensures sequences properly validate their structure and reject empty sequences that would cause decomposition failures.
static func is_valid_fails_without_subtasks__expected_behavior() -> void:
	var ctx = MyContext.new()
	var task = HtnSequence.new("Test")

	var result = task.is_valid(ctx)

	HtnError.add_assert(!result)
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that a Sequence with subtasks is considered valid and can proceed to decomposition.
## A sequence is valid when it has at least one subtask to execute in the sequence.
## The planner uses IsValid as a gating check before attempting decomposition, enabling early rejection of unsuitable tasks.
## This test confirms that sequences with subtasks properly report validity, allowing decomposition to proceed.
static func is_valid__expected_behavior() -> void:
	var ctx = MyContext.new()
	var task = HtnSequence.new("Test")
	task.add_subtask(HtnPrimitiveTask.new("Sub-task"))

	var result = task.is_valid(ctx)

	HtnError.add_assert(result)
	HtnError.add_assert("" == HtnError.get_message())

static func decompose_without_context_init__expected_behavior() -> void:
	var ctx = MyContext.new()
	var task = HtnSequence.new("Test")

	var plan = HtnPlan.new()
	task.decompose(ctx, 0, plan)

	HtnError.add_assert("" == HtnError.get_message())

## Verifies that attempting to decompose a Sequence with no subtasks returns Failed status and an empty plan.
## Decomposition breaks down compound tasks into executable primitives based on the current world state.
## When a sequence has no subtasks, there are no tasks to execute in sequence, so decomposition fails with an empty plan queue.
## This test confirms the sequence properly handles the edge case of an empty subtask list by returning Failed without crashing.
static func decompose_with_no_subtasks__expected_behavior() -> void:
	var ctx = MyContext.new()
	ctx.init()
	var task = HtnSequence.new("Test")

	var plan = HtnPlan.new()
	var status = task.decompose(ctx, 0, plan)

	HtnError.add_assert(Htn.DecompositionStatus.FAILED == status)
	HtnError.add_assert(plan.is_valid())
	HtnError.add_assert(plan.is_empty())
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that a Sequence with valid subtasks successfully decomposes all of them into the plan in order.
## Sequences implement AND semantics, requiring all subtasks to decompose successfully and adding all results to the plan.
## Since both primitive tasks always decompose successfully, both are added to the plan in sequence order.
## This test demonstrates basic sequence decomposition behavior and confirms all subtasks are included in the plan queue.
static func decompose_with_subtasks__expected_behavior() -> void:
	var ctx = MyContext.new()
	ctx.init()
	var task = HtnSequence.new("Test")
	task.add_subtask(HtnPrimitiveTask.new("Sub-task1"))
	task.add_subtask(HtnPrimitiveTask.new("Sub-task2"))

	var plan = HtnPlan.new()
	var status = task.decompose(ctx, 0, plan)

	HtnError.add_assert(Htn.DecompositionStatus.SUCCEEDED == status)
	HtnError.add_assert(plan.is_valid())
	HtnError.add_assert(2 == plan.size())
	HtnError.add_assert("Sub-task1" == plan.peek().get_name())
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that a Sequence can decompose nested compound tasks (selectors containing selectors) in sequence.
## Sequences recursively decompose all their subtasks in order, including decomposing nested compound tasks.
## The nested selector task2/task3 decomposes and produces Sub-task2, which is added to the plan along with Sub-task4 from the sequence.
## This test demonstrates that sequences handle complex nesting and properly collect results from all nested decompositions in order.
static func decompose_nested_subtasks__expected_behavior() -> void:
	var ctx = MyContext.new()
	ctx.init()

	var task = HtnSequence.new("Test")
	var task2 = HtnSelector.new("Test2")
	var task3 = HtnSelector.new("Test3")
	task3.add_subtask(HtnPrimitiveTask.new("Sub-task1").add_condition(HtnFuncCondition.new(MyContext, "Done == true", func (context):
		return context.is_done())))
	task3.add_subtask(HtnPrimitiveTask.new("Sub-task2"))

	task2.add_subtask(task3)
	task2.add_subtask(HtnPrimitiveTask.new("Sub-task3"))

	task.add_subtask(task2)
	task.add_subtask(HtnPrimitiveTask.new("Sub-task4"))

	var plan = HtnPlan.new()
	var status = task.decompose(ctx, 0, plan)

	HtnError.add_assert(Htn.DecompositionStatus.SUCCEEDED == status)
	HtnError.add_assert(plan.is_valid())
	HtnError.add_assert(2 == plan.size())
	HtnError.add_assert("Sub-task2" == plan.dequeue().get_name())
	HtnError.add_assert("Sub-task4" == plan.dequeue().get_name())
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that a Sequence fails decomposition when any subtask cannot be decomposed.
## Sequences require ALL subtasks to decompose successfully for the overall decomposition to succeed (AND semantics).
## When the second subtask fails its condition, the sequence cannot proceed and returns Failed with an empty plan.
## This test demonstrates the strict sequencing requirement: even if some subtasks decompose, if one fails, the entire sequence fails.
static func decompose_with_subtasks_one_fail__expected_behavior() -> void:
	var ctx = MyContext.new()
	ctx.init()
	ctx.set_context_state(Htn.ContextState.PLANNING)

	var task = HtnSequence.new("Test")
	task.add_subtask(HtnPrimitiveTask.new("Sub-task1"))
	task.add_subtask(HtnPrimitiveTask.new("Sub-task2").add_condition(HtnFuncCondition.new(MyContext, "Done == true", func (context):
		return context.is_done())))

	var plan = HtnPlan.new()
	var status = task.decompose(ctx, 0, plan)

	HtnError.add_assert(Htn.DecompositionStatus.FAILED == status)
	HtnError.add_assert(plan.is_valid())
	HtnError.add_assert(plan.is_empty())
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that a Sequence fails decomposition when a nested compound task cannot decompose.
## Nested compound tasks (like empty selectors) may fail to decompose if they have no valid alternatives.
## When a nested compound subtask fails, the entire sequence decomposition fails, and no plan is returned.
## This test demonstrates that sequences properly propagate failures from nested decompositions, maintaining AND semantics across nesting levels.
static func decompose_with_subtasks_compound_subtask_fails__expected_behavior() -> void:
	var ctx = MyContext.new()
	ctx.init()
	ctx.set_context_state(Htn.ContextState.PLANNING)

	var task = HtnSequence.new("Test")
	task.add_subtask(HtnSelector.new("Sub-task1"))
	task.add_subtask(HtnPrimitiveTask.new("Sub-task2"))

	var plan = HtnPlan.new()
	var status = task.decompose(ctx, 0, plan)

	HtnError.add_assert(Htn.DecompositionStatus.FAILED == status)
	HtnError.add_assert(plan.is_valid())
	HtnError.add_assert(plan.is_empty())
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that when a Sequence fails decomposition, all applied effects are rolled back to restore the previous world state.
## During planning, effects applied during subtask decomposition are tracked on the WorldStateChangeStack for rollback capability.
## When a sequence fails (because a later subtask fails), the planner must undo all effects applied during the failed decomposition attempt.
## This test demonstrates rollback mechanism: despite effects being applied during the first subtask, they're rolled back when the sequence ultimately fails, maintaining planning consistency.
static func decompose_failure_return_to_previous_world_state__expected_behavior() -> void:
	var ctx = MyContext.new()
	ctx.init()
	ctx.set_context_state(Htn.ContextState.PLANNING)
	ctx.set_bool_state(MyContext.WorldState.HAS_A, true, Htn.EffectType.PLAN_AND_EXECUTE)
	ctx.set_bool_state(MyContext.WorldState.HAS_B, true, Htn.EffectType.PERMANENT)
	ctx.set_bool_state(MyContext.WorldState.HAS_C, true, Htn.EffectType.PLAN_ONLY)

	var task = HtnSequence.new("Test")
	var e = HtnActionEffect.new(MyContext, "TestEffect", Htn.EffectType.PERMANENT, func (context, _type):
		context.set_bool_state(MyContext.WorldState.HAS_A, false, Htn.EffectType.PLAN_ONLY))
	task.add_subtask(HtnPrimitiveTask.new("Sub-task1").add_effect(e))
	task.add_subtask(HtnSelector.new("Sub-task2"))

	var plan = HtnPlan.new()
	var status = task.decompose(ctx, 0, plan)

	HtnError.add_assert(Htn.DecompositionStatus.FAILED == status)
	HtnError.add_assert(plan.is_valid())
	HtnError.add_assert(plan.is_empty())
	HtnError.add_assert(1 == ctx.get_world_state_change_stack()[MyContext.WorldState.HAS_A].size())
	HtnError.add_assert(1 == ctx.get_world_state_change_stack()[MyContext.WorldState.HAS_B].size())
	HtnError.add_assert(1 == ctx.get_world_state_change_stack()[MyContext.WorldState.HAS_C].size())
	HtnError.add_assert(1 == ctx.get_state(MyContext.WorldState.HAS_A))
	HtnError.add_assert(1 == ctx.get_state(MyContext.WorldState.HAS_B))
	HtnError.add_assert(1 == ctx.get_state(MyContext.WorldState.HAS_C))
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that a Sequence rejects decomposition when a nested selector's MTR choice fails.
## Sequences decompose all subtasks in order, tracking MTR choices for each nested selector encountered.
## The LastMTR indicates [0, 0] was previously used, but when attempting the same path, the nested selector fails at index 0 and records -1.
## This test demonstrates MTR-based rejection in nested sequences: if a previously successful decomposition path no longer works, the sequence rejects.
static func decompose_nested_compound_subtask_lose_to_mtr__expected_behavior() -> void:
	var ctx = MyContext.new()
	ctx.init()
	ctx.set_context_state(Htn.ContextState.PLANNING)

	var task = HtnSequence.new("Test")
	var task2 = HtnSelector.new("Test2")
	var task3 = HtnSelector.new("Test3")
	task3.add_subtask(HtnPrimitiveTask.new("Sub-task1").add_condition(HtnFuncCondition.new(MyContext, "Done == true", func (context):
		return context.is_done())))
	task3.add_subtask(HtnPrimitiveTask.new("Sub-task2"))

	task2.add_subtask(task3)
	task2.add_subtask(HtnPrimitiveTask.new("Sub-task3"))

	task.add_subtask(task2)
	task.add_subtask(HtnPrimitiveTask.new("Sub-task4"))

	ctx.get_last_mtr().append(0)
	ctx.get_last_mtr().append(0)

	var plan = HtnPlan.new()
	var status = task.decompose(ctx, 0, plan)

	HtnError.add_assert(Htn.DecompositionStatus.REJECTED == status)
	HtnError.add_assert(!plan.is_valid())
	HtnError.add_assert(2 == ctx.get_method_traversal_record().size())
	HtnError.add_assert(0 == ctx.get_method_traversal_record()[0])
	HtnError.add_assert(-1 == ctx.get_method_traversal_record()[1])
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that a Sequence rejects decomposition when a different nested selector's MTR choice fails.
## Each selector in the task hierarchy contributes to the MTR path, and sequences must track all of them.
## The LastMTR is [1, 0], but when decomposing, the second nested selector at index 0 fails and records -1.
## This test demonstrates that MTR rejection cascades through sequence decomposition: one nested selector's failure rejects the entire sequence.
static func decompose_nested_compound_subtask_lose_to_mtr2__expected_behavior() -> void:
	var ctx = MyContext.new()
	ctx.init()
	ctx.set_context_state(Htn.ContextState.PLANNING)

	var task = HtnSequence.new("Test")
	var task2 = HtnSelector.new("Test2")
	var task3 = HtnSelector.new("Test3")
	task3.add_subtask(HtnPrimitiveTask.new("Sub-task1").add_condition(HtnFuncCondition.new(MyContext, "Done == true", func (context):
		return context.is_done())))
	task3.add_subtask(HtnPrimitiveTask.new("Sub-task2"))

	task2.add_subtask(HtnPrimitiveTask.new("Sub-task3").add_condition(HtnFuncCondition.new(MyContext, "Done == true", func (context):
		return context.is_done())))
	task2.add_subtask(task3)

	task.add_subtask(task2)
	task.add_subtask(HtnPrimitiveTask.new("Sub-task4"))

	ctx.get_last_mtr().append(1)
	ctx.get_last_mtr().append(0)

	var plan = HtnPlan.new()
	var status = task.decompose(ctx, 0, plan)

	HtnError.add_assert(Htn.DecompositionStatus.REJECTED == status)
	HtnError.add_assert(!plan.is_valid())
	HtnError.add_assert(2 == ctx.get_method_traversal_record().size())
	HtnError.add_assert(1 == ctx.get_method_traversal_record()[0])
	HtnError.add_assert(-1 == ctx.get_method_traversal_record()[1])
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that a Sequence succeeds decomposition when nested selector MTR choices match and decompose successfully.
## When the LastMTR indicates [1, 1] (second option at each selector level), and both nested selectors can decompose to those options, the sequence succeeds.
## The plan includes Sub-task3 from the first selector and Sub-task4 from the sequence, matching the MTR-indicated choices.
## This test demonstrates that sequences properly handle MTR-constrained decomposition when all nested selectors can satisfy the MTR path.
static func decompose_nested_compound_subtask_equal_to_mtr__expected_behavior() -> void:
	var ctx = MyContext.new()
	ctx.init()

	var task = HtnSequence.new("Test")
	var task2 = HtnSelector.new("Test2")
	var task3 = HtnSelector.new("Test3")
	task3.add_subtask(HtnPrimitiveTask.new("Sub-task2").add_condition(HtnFuncCondition.new(MyContext, "Done == true", func (context):
		return context.is_done())))
	task3.add_subtask(HtnPrimitiveTask.new("Sub-task3"))

	task2.add_subtask(HtnPrimitiveTask.new("Sub-task1").add_condition(HtnFuncCondition.new(MyContext, "Done == true", func (context):
		return context.is_done())))
	task2.add_subtask(task3)

	task.add_subtask(task2)
	task.add_subtask(HtnPrimitiveTask.new("Sub-task4"))

	ctx.get_last_mtr().append(1)
	ctx.get_last_mtr().append(1)

	var plan = HtnPlan.new()
	var status = task.decompose(ctx, 0, plan)

	HtnError.add_assert(Htn.DecompositionStatus.SUCCEEDED == status)
	HtnError.add_assert(plan.is_valid())
	HtnError.add_assert(2 == plan.size())
	HtnError.add_assert(2 == ctx.get_method_traversal_record().size())
	HtnError.add_assert(1 == ctx.get_method_traversal_record()[0])
	HtnError.add_assert(1 == ctx.get_method_traversal_record()[1])
	HtnError.add_assert("Sub-task3" == plan.dequeue().get_name())
	HtnError.add_assert("Sub-task4" == plan.dequeue().get_name())
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that when a Sequence rejects decomposition due to MTR failure, all applied effects are rolled back to restore previous state.
## Effects are applied during decomposition and tracked on the change stack for potential rollback if decomposition fails later.
## When a nested selector rejects due to MTR conflict, all effects applied by previous subtasks must be undone to restore consistency.
## This test demonstrates combined mechanics: MTR-based rejection coupled with state rollback, ensuring planning maintains a consistent state despite decomposition failures.
static func decompose_nested_compound_subtask_lose_to_mtr_return_to_previous_world_state__expected_behavior() -> void:
	var ctx = MyContext.new()
	ctx.init()
	ctx.set_context_state(Htn.ContextState.PLANNING)
	ctx.set_bool_state(MyContext.WorldState.HAS_A, true, Htn.EffectType.PLAN_AND_EXECUTE)
	ctx.set_bool_state(MyContext.WorldState.HAS_B, true, Htn.EffectType.PERMANENT)
	ctx.set_bool_state(MyContext.WorldState.HAS_C, true, Htn.EffectType.PLAN_ONLY)

	var task = HtnSequence.new("Test")
	var task2 = HtnSelector.new("Test2")
	var task3 = HtnSelector.new("Test3")
	task3.add_subtask(HtnPrimitiveTask.new("Sub-task2").add_condition(HtnFuncCondition.new(MyContext, "Done == true", func (context):
		return context.is_done())))
	task3.add_subtask(HtnPrimitiveTask.new("Sub-task3").add_effect(HtnActionEffect.new(MyContext, "TestEffect", Htn.EffectType.PERMANENT, func (context, _type):
		context.set_bool_state(MyContext.WorldState.HAS_A, false, Htn.EffectType.PLAN_ONLY))))

	task2.add_subtask(task3)
	task2.add_subtask(HtnPrimitiveTask.new("Sub-task4").add_effect(HtnActionEffect.new(MyContext, "TestEffect", Htn.EffectType.PERMANENT, func (context, _type):
		context.set_bool_state(MyContext.WorldState.HAS_B, false, Htn.EffectType.PLAN_ONLY))))

	task.add_subtask(HtnPrimitiveTask.new("Sub-task1").add_effect(HtnActionEffect.new(MyContext, "TestEffect", Htn.EffectType.PERMANENT, func (context, _type):
		context.set_bool_state(MyContext.WorldState.HAS_A, false, Htn.EffectType.PLAN_ONLY))))
	task.add_subtask(task2)
	task.add_subtask(HtnPrimitiveTask.new("Sub-task5").add_effect(HtnActionEffect.new(MyContext, "TestEffect", Htn.EffectType.PERMANENT, func (context, _type):
		context.set_bool_state(MyContext.WorldState.HAS_C, false, Htn.EffectType.PLAN_ONLY))))

	ctx.get_last_mtr().append(0)
	ctx.get_last_mtr().append(0)

	var plan = HtnPlan.new()
	var status = task.decompose(ctx, 0, plan)

	HtnError.add_assert(Htn.DecompositionStatus.REJECTED == status)
	HtnError.add_assert(!plan.is_valid())
	HtnError.add_assert(2 == ctx.get_method_traversal_record().size())
	HtnError.add_assert(0 == ctx.get_method_traversal_record()[0])
	HtnError.add_assert(-1 == ctx.get_method_traversal_record()[1])
	HtnError.add_assert(1 == ctx.get_world_state_change_stack()[MyContext.WorldState.HAS_A].size())
	HtnError.add_assert(1 == ctx.get_world_state_change_stack()[MyContext.WorldState.HAS_B].size())
	HtnError.add_assert(1 == ctx.get_world_state_change_stack()[MyContext.WorldState.HAS_C].size())
	HtnError.add_assert(1 == ctx.get_state(MyContext.WorldState.HAS_A))
	HtnError.add_assert(1 == ctx.get_state(MyContext.WorldState.HAS_B))
	HtnError.add_assert(1 == ctx.get_state(MyContext.WorldState.HAS_C))
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that when a Sequence fails decomposition due to nested sequence failure, all applied effects are rolled back.
## Nested sequences themselves must decompose successfully for the outer sequence to continue.
## When a deeply nested sequence fails (because its subtasks have failing conditions), all effects applied during attempts must be undone.
## This test demonstrates comprehensive rollback: all effects applied during the entire failed decomposition attempt are rolled back, restoring the initial state exactly.
static func decompose_nested_compound_subtask_fail_return_to_previous_world_state__expected_behavior() -> void:
	var ctx = MyContext.new()
	ctx.init()
	ctx.set_context_state(Htn.ContextState.PLANNING)
	ctx.set_bool_state(MyContext.WorldState.HAS_A, true, Htn.EffectType.PLAN_AND_EXECUTE)
	ctx.set_bool_state(MyContext.WorldState.HAS_B, true, Htn.EffectType.PERMANENT)
	ctx.set_bool_state(MyContext.WorldState.HAS_C, true, Htn.EffectType.PLAN_ONLY)

	var task = HtnSequence.new("Test")
	var task2 = HtnSequence.new("Test2")
	var task3 = HtnSequence.new("Test3")
	task3.add_subtask(HtnPrimitiveTask.new("Sub-task2").add_condition(HtnFuncCondition.new(MyContext, "Done == true", func (context):
		return context.is_done())))
	task3.add_subtask(HtnPrimitiveTask.new("Sub-task3").add_effect(HtnActionEffect.new(MyContext, "TestEffect", Htn.EffectType.PERMANENT, func (context, _type):
		context.set_bool_state(MyContext.WorldState.HAS_A, false, Htn.EffectType.PLAN_ONLY))))

	task2.add_subtask(task3)
	task2.add_subtask(HtnPrimitiveTask.new("Sub-task4").add_effect(HtnActionEffect.new(MyContext, "TestEffect", Htn.EffectType.PERMANENT, func (context, _type):
		context.set_bool_state(MyContext.WorldState.HAS_B, false, Htn.EffectType.PLAN_ONLY))))

	task.add_subtask(HtnPrimitiveTask.new("Sub-task1").add_effect(HtnActionEffect.new(MyContext, "TestEffect", Htn.EffectType.PERMANENT, func (context, _type):
		context.set_bool_state(MyContext.WorldState.HAS_A, false, Htn.EffectType.PLAN_ONLY))))
	task.add_subtask(task2)
	task.add_subtask(HtnPrimitiveTask.new("Sub-task5").add_effect(HtnActionEffect.new(MyContext, "TestEffect", Htn.EffectType.PERMANENT, func (context, _type):
		context.set_bool_state(MyContext.WorldState.HAS_C, false, Htn.EffectType.PLAN_ONLY))))

	var plan = HtnPlan.new()
	var status = task.decompose(ctx, 0, plan)

	HtnError.add_assert(Htn.DecompositionStatus.FAILED == status)
	HtnError.add_assert(plan.is_valid())
	HtnError.add_assert(plan.is_empty())
	HtnError.add_assert(1 == ctx.get_world_state_change_stack()[MyContext.WorldState.HAS_A].size())
	HtnError.add_assert(1 == ctx.get_world_state_change_stack()[MyContext.WorldState.HAS_B].size())
	HtnError.add_assert(1 == ctx.get_world_state_change_stack()[MyContext.WorldState.HAS_C].size())
	HtnError.add_assert(1 == ctx.get_state(MyContext.WorldState.HAS_A))
	HtnError.add_assert(1 == ctx.get_state(MyContext.WorldState.HAS_B))
	HtnError.add_assert(1 == ctx.get_state(MyContext.WorldState.HAS_C))
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that a Sequence stops decomposition when encountering a PausePlanTask and returns a partial plan.
## PausePlanTask is a special task that interrupts decomposition, allowing the planner to resume later at a specific point.
## The sequence decomposes up to the pause point (Sub-task1), returns that as a plan, and queues the remaining decomposition for later resumption.
## This test demonstrates partial planning: the planner can decompose incrementally, execute some tasks, and resume decomposition from a saved point.
static func pause_plan__expected_behavior() -> void:
	var ctx = MyContext.new()
	ctx.init()

	var task = HtnSequence.new("Test")
	task.add_subtask(HtnPrimitiveTask.new("Sub-task1"))
	task.add_subtask(HtnPausePlanTask.new())
	task.add_subtask(HtnPrimitiveTask.new("Sub-task2"))

	var plan = HtnPlan.new()
	var status = task.decompose(ctx, 0, plan)

	HtnError.add_assert(Htn.DecompositionStatus.PARTIAL == status)
	HtnError.add_assert(plan.is_valid())
	HtnError.add_assert(1 == plan.size())
	HtnError.add_assert("Sub-task1" == plan.peek().get_name())
	HtnError.add_assert(ctx.has_paused_partial_plan())
	HtnError.add_assert(1 == ctx.get_partial_plan_queue().size())
	HtnError.add_assert(task == ctx.get_partial_plan_queue().front().task)
	HtnError.add_assert(2 == ctx.get_partial_plan_queue().front().task_index)
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that resuming a paused sequence decomposition continues from the saved point and completes the plan.
## When a sequence is paused, the context maintains a queue of partially decomposed tasks with their resume indices.
## Resuming decomposition resumes the paused sequence from the saved index, completing the remaining subtasks.
## This test demonstrates the complete pause/resume cycle: pause to get Sub-task1, resume to decompose Sub-task2, combining for the full plan.
static func continue_paused_plan__expected_behavior() -> void:
	var ctx = MyContext.new()
	ctx.init()

	var task = HtnSequence.new("Test")
	task.add_subtask(HtnPrimitiveTask.new("Sub-task1"))
	task.add_subtask(HtnPausePlanTask.new())
	task.add_subtask(HtnPrimitiveTask.new("Sub-task2"))

	var plan = HtnPlan.new()
	var status = task.decompose(ctx, 0, plan)

	HtnError.add_assert(Htn.DecompositionStatus.PARTIAL == status)
	HtnError.add_assert(plan.is_valid())
	HtnError.add_assert(1 == plan.size())
	HtnError.add_assert("Sub-task1" == plan.dequeue().get_name())
	HtnError.add_assert(ctx.has_paused_partial_plan())
	HtnError.add_assert(1 == ctx.get_partial_plan_queue().size())
	HtnError.add_assert(task == ctx.get_partial_plan_queue().front().task)
	HtnError.add_assert(2 == ctx.get_partial_plan_queue().front().task_index)

	ctx.set_paused_partial_plan(false)
	plan = HtnPlan.new()
	while !ctx.get_partial_plan_queue().is_empty():
		var kvp = ctx.get_partial_plan_queue().pop_front()
		var p = HtnPlan.new()
		var s = kvp.task.decompose(ctx, kvp.task_index, p)
		if Htn.DecompositionStatus.SUCCEEDED == s or Htn.DecompositionStatus.PARTIAL == s:
			while !p.is_empty():
				plan.enqueue(p.dequeue())

	HtnError.add_assert(plan.is_valid())
	HtnError.add_assert(1 == plan.size())
	HtnError.add_assert("Sub-task2" == plan.peek().get_name())
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that pause points in nested tasks are queued in the correct order for later resumption.
## When nested sequences encounter pause points, each pause level must maintain its own decomposition state.
## The pause queue tracks multiple paused tasks: the innermost paused sequence task3 and the outer sequence task, enabling proper resumption order.
## This test demonstrates pause point stacking: pauses at different nesting levels are queued and can be resumed in sequence to complete the entire plan.
static func nested_pause_plan__expected_behavior() -> void:
	var ctx = MyContext.new()
	ctx.init()

	var task = HtnSequence.new("Test")
	var task2 = HtnSelector.new("Test2")
	var task3 = HtnSequence.new("Test3")
	task3.add_subtask(HtnPrimitiveTask.new("Sub-task1"))
	task3.add_subtask(HtnPausePlanTask.new())
	task3.add_subtask(HtnPrimitiveTask.new("Sub-task2"))

	task2.add_subtask(task3)
	task2.add_subtask(HtnPrimitiveTask.new("Sub-task3"))

	task.add_subtask(task2)
	task.add_subtask(HtnPrimitiveTask.new("Sub-task4"))

	var plan = HtnPlan.new()
	var status = task.decompose(ctx, 0, plan)

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

## Verifies that resuming nested pause points decomposes in the correct order and produces the complete plan.
## When resuming paused nested sequences, each pause level is resumed in the proper order (innermost first).
## Resuming the innermost pause (task3 at index 2) produces Sub-task2, then continuing produces Sub-task4 from the outer sequence.
## This test demonstrates complete nested pause/resume execution: pauses at multiple levels are resumed in sequence to produce the full plan incrementally.
static func continue_nested_pause_plan__expected_behavior() -> void:
	var ctx = MyContext.new()
	ctx.init()

	var task = HtnSequence.new("Test")
	var task2 = HtnSelector.new("Test2")
	var task3 = HtnSequence.new("Test3")
	task3.add_subtask(HtnPrimitiveTask.new("Sub-task1"))
	task3.add_subtask(HtnPausePlanTask.new())
	task3.add_subtask(HtnPrimitiveTask.new("Sub-task2"))

	task2.add_subtask(task3)
	task2.add_subtask(HtnPrimitiveTask.new("Sub-task3"))

	task.add_subtask(task2)
	task.add_subtask(HtnPrimitiveTask.new("Sub-task4"))

	var plan = HtnPlan.new()
	var status = task.decompose(ctx, 0, plan)

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

	ctx.set_paused_partial_plan(false)
	plan = HtnPlan.new()
	while !ctx.get_partial_plan_queue().is_empty():
		var kvp = ctx.get_partial_plan_queue().pop_front()
		var p = HtnPlan.new()
		var s = kvp.task.decompose(ctx, kvp.task_index, p)

		if Htn.DecompositionStatus.SUCCEEDED == s or Htn.DecompositionStatus.PARTIAL == s:
			while !p.is_empty():
				plan.enqueue(p.dequeue())

		if ctx.has_paused_partial_plan():
			break

	HtnError.add_assert(plan.is_valid())
	HtnError.add_assert(2 == plan.size())
	HtnError.add_assert("Sub-task2" == plan.dequeue().get_name())
	HtnError.add_assert("Sub-task4" == plan.dequeue().get_name())
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that multiple pause points at different nesting levels are correctly queued and resumed in proper order.
## Partial planning with multiple pauses requires managing a stack of paused decomposition points at different levels.
## The sequence encounters pauses at nested levels (task3 and task4), queueing them and resuming them in sequence to progressively expand the plan.
## This test demonstrates multi-phase partial planning: pauses at different depths are resumed incrementally, eventually producing the complete plan across multiple decomposition phases.
static func continue_multiple_nested_pause_plan__expected_behavior() -> void:
	var ctx = MyContext.new()
	ctx.init()

	var task = HtnSequence.new("Test")
	var task2 = HtnSelector.new("Test2")
	var task3 = HtnSequence.new("Test3")
	var task4 = HtnSequence.new("Test4")
	task3.add_subtask(HtnPrimitiveTask.new("Sub-task1"))
	task3.add_subtask(HtnPausePlanTask.new())
	task3.add_subtask(HtnPrimitiveTask.new("Sub-task2"))

	task2.add_subtask(task3)
	task2.add_subtask(HtnPrimitiveTask.new("Sub-task3"))

	task4.add_subtask(HtnPrimitiveTask.new("Sub-task5"))
	task4.add_subtask(HtnPausePlanTask.new())
	task4.add_subtask(HtnPrimitiveTask.new("Sub-task6"))

	task.add_subtask(task2)
	task.add_subtask(HtnPrimitiveTask.new("Sub-task4"))
	task.add_subtask(task4)
	task.add_subtask(HtnPrimitiveTask.new("Sub-task7"))

	var plan = HtnPlan.new()
	var status = task.decompose(ctx, 0, plan)

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

	ctx.set_paused_partial_plan(false)
	plan = HtnPlan.new()
	while !ctx.get_partial_plan_queue().is_empty():
		var kvp = ctx.get_partial_plan_queue().pop_front()
		var p = HtnPlan.new()
		var s = kvp.task.decompose(ctx, kvp.task_index, p)

		if Htn.DecompositionStatus.SUCCEEDED == s or Htn.DecompositionStatus.PARTIAL == s:
			while !p.is_empty():
				plan.enqueue(p.dequeue())

		if ctx.has_paused_partial_plan():
			break

	HtnError.add_assert(plan.is_valid())
	HtnError.add_assert(3 == plan.size())
	HtnError.add_assert("Sub-task2" == plan.dequeue().get_name())
	HtnError.add_assert("Sub-task4" == plan.dequeue().get_name())
	HtnError.add_assert("Sub-task5" == plan.dequeue().get_name())

	ctx.set_paused_partial_plan(false)
	plan = HtnPlan.new()
	while !ctx.get_partial_plan_queue().is_empty():
		var kvp = ctx.get_partial_plan_queue().pop_front()
		var p = HtnPlan.new()
		var s = kvp.task.decompose(ctx, kvp.task_index, p)

		if Htn.DecompositionStatus.SUCCEEDED == s or Htn.DecompositionStatus.PARTIAL == s:
			while !p.is_empty():
				plan.enqueue(p.dequeue())

		if ctx.has_paused_partial_plan():
			break

	HtnError.add_assert(plan.is_valid())
	HtnError.add_assert(2 == plan.size())
	HtnError.add_assert("Sub-task6" == plan.dequeue().get_name())
	HtnError.add_assert("Sub-task7" == plan.dequeue().get_name())
	HtnError.add_assert("" == HtnError.get_message())

static func run() -> void:
	HtnError.reset_message()
	add_condition__expected_behavior()
	HtnError.reset_message()
	add_subtask__expected_behavior()
	HtnError.reset_message()
	is_valid_fails_without_subtasks__expected_behavior()
	HtnError.reset_message()
	is_valid__expected_behavior()
	HtnError.reset_message()
	decompose_without_context_init__expected_behavior()
	HtnError.reset_message()
	decompose_with_no_subtasks__expected_behavior()
	HtnError.reset_message()
	decompose_with_subtasks__expected_behavior()
	HtnError.reset_message()
	decompose_nested_subtasks__expected_behavior()
	HtnError.reset_message()
	decompose_with_subtasks_one_fail__expected_behavior()
	HtnError.reset_message()
	decompose_with_subtasks_compound_subtask_fails__expected_behavior()
	HtnError.reset_message()
	decompose_failure_return_to_previous_world_state__expected_behavior()
	HtnError.reset_message()
	decompose_nested_compound_subtask_lose_to_mtr__expected_behavior()
	HtnError.reset_message()
	decompose_nested_compound_subtask_lose_to_mtr2__expected_behavior()
	HtnError.reset_message()
	decompose_nested_compound_subtask_equal_to_mtr__expected_behavior()
	HtnError.reset_message()
	decompose_nested_compound_subtask_lose_to_mtr_return_to_previous_world_state__expected_behavior()
	HtnError.reset_message()
	decompose_nested_compound_subtask_fail_return_to_previous_world_state__expected_behavior()
	HtnError.reset_message()
	pause_plan__expected_behavior()
	HtnError.reset_message()
	continue_paused_plan__expected_behavior()
	HtnError.reset_message()
	nested_pause_plan__expected_behavior()
	HtnError.reset_message()
	continue_nested_pause_plan__expected_behavior()
	HtnError.reset_message()
	continue_multiple_nested_pause_plan__expected_behavior()
