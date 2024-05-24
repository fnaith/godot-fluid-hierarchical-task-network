class_name HtnPlannerTests
extends Object

static func tick_with_null_parameters_throws_nre__expected_behavior() -> void:
	var planner = HtnPlanner.new()

	planner.tick(null, null)

	HtnError.add_assert("Context was not existed!" == HtnError.get_message())

static func tick_with_null_domain_throws_exception__expected_behavior() -> void:
	var ctx = MyContext.new()
	var planner = HtnPlanner.new()

	planner.tick(null, ctx)

	HtnError.add_assert("Domain was not existed!" == HtnError.get_message())

static func tick_without_initialized_context_throws_exception__expected_behavior() -> void:
	var ctx = MyContext.new()
	var domain = HtnDomain.new("Test")
	var planner = HtnPlanner.new()

	planner.tick(domain, ctx)

	HtnError.add_assert("Context was not initialized!" == HtnError.get_message())

static func tick_with_empty_domain__expected_behavior() -> void:
	var ctx = MyContext.new()
	ctx.init()
	var domain = HtnDomain.new("Test")
	var planner = HtnPlanner.new()

	planner.tick(domain, ctx)

	HtnError.add_assert("" == HtnError.get_message())

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
