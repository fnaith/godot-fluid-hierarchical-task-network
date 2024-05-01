class_name HtnDomainTests
extends Object

static func domain_has_root_with_domain_name__expected_behavior() -> void:
	var domain = HtnDomain.new("Test")

	HtnError.add_assert(null != domain.get_root())
	HtnError.add_assert("Test" == domain.get_root().get_name())
	HtnError.add_assert("" == HtnError.get_message())

static func add_subtask_to_parent__expected_behavior() -> void:
	var domain = HtnDomain.new("Test")
	var task1 = HtnSelector.new("Test")
	var task2 = HtnPrimitiveTask.new("Test")

	domain.add_subtask(task1, task2)

	HtnError.add_assert(task1.get_subtasks().has(task2))
	HtnError.add_assert(task1 == task2.get_parent())
	HtnError.add_assert("" == HtnError.get_message())

static func find_plan_no_ctx_throws_nre__expected_behavior() -> void:
	var domain = HtnDomain.new("Test")

	var plan = HtnPlan.new()
	var status = domain.find_plan(null, plan)

	HtnError.add_assert(Htn.DecompositionStatus.FAILED == status)
	HtnError.add_assert("Context was not existed!" == HtnError.get_message())

static func find_plan_uninitialized_context_throws__expected_behavior() -> void:
	var ctx = MyContext.new()
	var domain = HtnDomain.new("Test")

	var plan = HtnPlan.new()
	var status = domain.find_plan(ctx, plan)

	HtnError.add_assert(Htn.DecompositionStatus.FAILED == status)
	HtnError.add_assert(plan.is_valid())
	HtnError.add_assert(plan.is_empty())
	HtnError.add_assert("Context was not initialized!" == HtnError.get_message())

static func find_plan_no_tasks_then_null_plan__expected_behavior() -> void:
	var ctx = MyContext.new()
	ctx.init()
	var domain = HtnDomain.new("Test")

	var plan = HtnPlan.new()
	var status = domain.find_plan(ctx, plan)

	HtnError.add_assert(Htn.DecompositionStatus.REJECTED == status)
	HtnError.add_assert(!plan.is_valid())
	HtnError.add_assert("" == HtnError.get_message())

static func after_find_plan_context_state_is_executing__expected_behavior() -> void:
	var ctx = MyContext.new()
	ctx.init()
	var domain = HtnDomain.new("Test")

	var plan = HtnPlan.new()
	domain.find_plan(ctx, plan)

	HtnError.add_assert(Htn.ContextState.EXECUTING == ctx.get_context_state())
	HtnError.add_assert("" == HtnError.get_message())

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
