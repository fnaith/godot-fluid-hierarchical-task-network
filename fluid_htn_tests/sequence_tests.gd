class_name HtnSequenceTests
extends Object

static func add_condition__expected_behavior() -> void:
	var task = HtnSequence.new("Test")

	var t = task.add_condition(HtnFuncCondition.new(MyContext, "TestCondition", func (context):
		return !context.is_done()))

	HtnError.add_assert(t == task)
	HtnError.add_assert(1 == task.get_conditions().size())
	HtnError.add_assert("" == HtnError.get_message())

static func add_subtask__expected_behavior() -> void:
	var task = HtnSequence.new("Test")

	var t = task.add_subtask(HtnPrimitiveTask.new("Sub-task"))

	HtnError.add_assert(t == task)
	HtnError.add_assert(1 == task.get_subtasks().size())
	HtnError.add_assert("" == HtnError.get_message())

static func is_valid_fails_without_subtasks__expected_behavior() -> void:
	var ctx = MyContext.new()
	var task = HtnSequence.new("Test")

	var result = task.is_valid(ctx)

	HtnError.add_assert(!result)
	HtnError.add_assert("" == HtnError.get_message())

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
