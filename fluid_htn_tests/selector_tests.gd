class_name HtnSelectorTests
extends Object

static func add_condition__expected_behavior() -> void:
	var task = HtnSelector.new("Test")

	var t = task.add_condition(HtnFuncCondition.new(MyContext, "TestCondition", func (context):
		context.set_done(false)))

	HtnError.add_assert(t == task)
	HtnError.add_assert(1 == task.get_conditions().size())
	HtnError.add_assert("" == HtnError.get_message())

static func add_subtask__expected_behavior() -> void:
	var task = HtnSelector.new("Test")

	var t = task.add_subtask(HtnPrimitiveTask.new("Sub-task"))

	HtnError.add_assert(t == task)
	HtnError.add_assert(1 == task.get_subtasks().size())
	HtnError.add_assert("" == HtnError.get_message())

static func is_valid_fails_without_subtasks__expected_behavior() -> void:
	var ctx = MyContext.new()
	var task = HtnSelector.new("Test")

	var result = task.is_valid(ctx)

	HtnError.add_assert(!result)
	HtnError.add_assert("" == HtnError.get_message())

static func is_valid__expected_behavior() -> void:
	var ctx = MyContext.new()
	var task = HtnSelector.new("Test")
	task.add_subtask(HtnPrimitiveTask.new("Sub-task"))

	var result = task.is_valid(ctx)

	HtnError.add_assert(result)
	HtnError.add_assert("" == HtnError.get_message())

static func decompose_with_no_subtasks__expected_behavior() -> void:
	var ctx = MyContext.new()
	var task = HtnSelector.new("Test")

	var plan = HtnPlan.new()
	var status = task.decompose(ctx, 0, plan)

	HtnError.add_assert(Htn.DecompositionStatus.FAILED == status)
	HtnError.add_assert(plan.is_valid())
	HtnError.add_assert(plan.is_empty())
	HtnError.add_assert("" == HtnError.get_message())

static func decompose_with_subtasks__expected_behavior() -> void:
	var ctx = MyContext.new()
	var task = HtnSelector.new("Test")
	task.add_subtask(HtnPrimitiveTask.new("Sub-task1"))
	task.add_subtask(HtnPrimitiveTask.new("Sub-task2"))

	var plan = HtnPlan.new()
	var status = task.decompose(ctx, 0, plan)

	HtnError.add_assert(Htn.DecompositionStatus.SUCCEEDED == status)
	HtnError.add_assert(plan.is_valid())
	HtnError.add_assert(1 == plan.size())
	HtnError.add_assert("Sub-task1" == plan.peek().get_name())
	HtnError.add_assert("" == HtnError.get_message())

static func decompose_with_subtasks2__expected_behavior():
	var ctx = MyContext.new()
	var task = HtnSelector.new("Test")
	task.add_subtask(HtnSelector.new("Sub-task1"))
	task.add_subtask(HtnPrimitiveTask.new("Sub-task2"))

	var plan = HtnPlan.new()
	var status = task.decompose(ctx, 0, plan)

	HtnError.add_assert(Htn.DecompositionStatus.SUCCEEDED == status)
	HtnError.add_assert(plan.is_valid())
	HtnError.add_assert(1 == plan.size())
	HtnError.add_assert("Sub-task2" == plan.peek().get_name())
	HtnError.add_assert("" == HtnError.get_message())

static func decompose_with_subtasks3__expected_behavior():
	var ctx = MyContext.new()
	var task = HtnSelector.new("Test")
	task.add_subtask(HtnPrimitiveTask.new("Sub-task1").add_condition(HtnFuncCondition.new(MyContext, "Done == true", func (context):
		return context.is_done())))
	task.add_subtask(HtnPrimitiveTask.new("Sub-task2"))

	var plan = HtnPlan.new()
	var status = task.decompose(ctx, 0, plan)

	HtnError.add_assert(Htn.DecompositionStatus.SUCCEEDED == status)
	HtnError.add_assert(plan.is_valid())
	HtnError.add_assert(1 == plan.size())
	HtnError.add_assert("Sub-task2" == plan.peek().get_name())
	HtnError.add_assert("" == HtnError.get_message())

static func decompose_mtr_fails__expected_behavior():
	var ctx = MyContext.new()
	var task = HtnSelector.new("Test")
	task.add_subtask(HtnPrimitiveTask.new("Sub-task1").add_condition(HtnFuncCondition.new(MyContext, "Done == true", func (context):
		return context.is_done())))
	task.add_subtask(HtnPrimitiveTask.new("Sub-task2"))
	ctx.get_last_mtr().append(0)

	var plan = HtnPlan.new()
	var status = task.decompose(ctx, 0, plan)

	HtnError.add_assert(Htn.DecompositionStatus.REJECTED == status)
	HtnError.add_assert(!plan.is_valid())
	HtnError.add_assert(ctx.get_method_traversal_record().size())
	HtnError.add_assert(-1 == ctx.get_method_traversal_record()[0])
	HtnError.add_assert("" == HtnError.get_message())

static func decompose_debug_mtr_fails__expected_behavior():
	var ctx = MyDebugContext.new()
	ctx.init()

	var task = HtnSelector.new("Test")
	task.add_subtask(HtnPrimitiveTask.new("Sub-task1").add_condition(HtnFuncCondition.new(MyContext, "Done == true", func (context):
		return context.is_done())))
	task.add_subtask(HtnPrimitiveTask.new("Sub-task2"))
	ctx.get_last_mtr().append(0)

	var plan = HtnPlan.new()
	var status = task.decompose(ctx, 0, plan)

	HtnError.add_assert(Htn.DecompositionStatus.REJECTED == status)
	HtnError.add_assert(!plan.is_valid())
	HtnError.add_assert(1 == ctx.get_mtr_debug().size())
	HtnError.add_assert(ctx.get_mtr_debug()[0].contains("REPLAN FAIL"))
	HtnError.add_assert(ctx.get_mtr_debug()[0].contains("Sub-task2"))
	HtnError.add_assert("" == HtnError.get_message())

static func decompose_mtr_succeeds_when_equal__expected_behavior():
	var ctx = MyContext.new()
	var task = HtnSelector.new("Test")
	task.add_subtask(HtnPrimitiveTask.new("Sub-task1").add_condition(HtnFuncCondition.new(MyContext, "Done == true", func (context):
		return context.is_done())))
	task.add_subtask(HtnPrimitiveTask.new("Sub-task2"))
	ctx.get_last_mtr().append(1)

	var plan = HtnPlan.new()
	var status = task.decompose(ctx, 0, plan)

	HtnError.add_assert(Htn.DecompositionStatus.SUCCEEDED == status)
	HtnError.add_assert(plan.is_valid())
	HtnError.add_assert(1 == plan.size())
	HtnError.add_assert(1 == ctx.get_method_traversal_record().size())
	HtnError.add_assert(ctx.get_method_traversal_record()[0] == ctx.get_last_mtr()[0])
	HtnError.add_assert("" == HtnError.get_message())

static func decompose_compound_subtask_succeeds__expected_behavior():
	var ctx = MyContext.new()
	var task = HtnSelector.new("Test")
	var task2 = HtnSelector.new("Test2")
	task2.add_subtask(HtnPrimitiveTask.new("Sub-task1").add_condition(HtnFuncCondition.new(MyContext, "Done == true", func (context):
		return context.is_done())))
	task2.add_subtask(HtnPrimitiveTask.new("Sub-task2"))

	task.add_subtask(task2)
	task.add_subtask(HtnPrimitiveTask.new("Sub-task3"))

	var plan = HtnPlan.new()
	var status = task.decompose(ctx, 0, plan)

	HtnError.add_assert(Htn.DecompositionStatus.SUCCEEDED == status)
	HtnError.add_assert(plan.is_valid())
	HtnError.add_assert(1 == plan.size())
	HtnError.add_assert("Sub-task2" == plan.peek().get_name())
	HtnError.add_assert(2 == ctx.get_method_traversal_record().size())
	HtnError.add_assert(0 == ctx.get_method_traversal_record()[0])
	HtnError.add_assert(1 == ctx.get_method_traversal_record()[1])
	HtnError.add_assert("" == HtnError.get_message())

static func decompose_compound_subtask_fails__expected_behavior():
	var ctx = MyContext.new()
	var task = HtnSelector.new("Test")
	var task2 = HtnSelector.new("Test2")
	task2.add_subtask(HtnPrimitiveTask.new("Sub-task1").add_condition(HtnFuncCondition.new(MyContext, "Done == true", func (context):
		return context.is_done())))
	task2.add_subtask(HtnPrimitiveTask.new("Sub-task2").add_condition(HtnFuncCondition.new(MyContext, "Done == true", func (context):
		return context.is_done())))

	task.add_subtask(task2)
	task.add_subtask(HtnPrimitiveTask.new("Sub-task3"))

	var plan = HtnPlan.new()
	var status = task.decompose(ctx, 0, plan)

	HtnError.add_assert(Htn.DecompositionStatus.SUCCEEDED == status)
	HtnError.add_assert(plan.is_valid())
	HtnError.add_assert(1 == plan.size())
	HtnError.add_assert("Sub-task3" == plan.peek().get_name())
	HtnError.add_assert(1 == ctx.get_method_traversal_record().size())
	HtnError.add_assert(1 == ctx.get_method_traversal_record()[0])
	HtnError.add_assert("" == HtnError.get_message())

static func decompose_nested_compound_subtask_fails__expected_behavior():
	var ctx = MyContext.new()
	var task = HtnSelector.new("Test")
	var task2 = HtnSelector.new("Test2")
	var task3 = HtnSelector.new("Test3")
	task3.add_subtask(HtnPrimitiveTask.new("Sub-task1").add_condition(HtnFuncCondition.new(MyContext, "Done == true", func (context):
		return context.is_done())))
	task3.add_subtask(HtnPrimitiveTask.new("Sub-task2").add_condition(HtnFuncCondition.new(MyContext, "Done == true", func (context):
		return context.is_done())))

	task2.add_subtask(task3)
	task2.add_subtask(HtnPrimitiveTask.new("Sub-task3").add_condition(HtnFuncCondition.new(MyContext, "Done == true", func (context):
		return context.is_done())))

	task.add_subtask(task2)
	task.add_subtask(HtnPrimitiveTask.new("Sub-task4"))

	var plan = HtnPlan.new()
	var status = task.decompose(ctx, 0, plan)

	HtnError.add_assert(Htn.DecompositionStatus.SUCCEEDED == status)
	HtnError.add_assert(plan.is_valid())
	HtnError.add_assert(1 == plan.size())
	HtnError.add_assert("Sub-task4" == plan.peek().get_name())
	HtnError.add_assert(1 == ctx.get_method_traversal_record().size())
	HtnError.add_assert(1 == ctx.get_method_traversal_record()[0])
	HtnError.add_assert("" == HtnError.get_message())

static func decompose_compound_subtask_beats_last_mtr__expected_behavior():
	var ctx = MyContext.new()
	var task = HtnSelector.new("Test")
	var task2 = HtnSelector.new("Test2")
	task2.add_subtask(HtnPrimitiveTask.new("Sub-task1").add_condition(HtnFuncCondition.new(MyContext, "Done == true", func (context):
		return context.is_done())))
	task2.add_subtask(HtnPrimitiveTask.new("Sub-task2"))

	task.add_subtask(task2)
	task.add_subtask(HtnPrimitiveTask.new("Sub-task3"))

	ctx.get_last_mtr().append(1)

	var plan = HtnPlan.new()
	var status = task.decompose(ctx, 0, plan)

	HtnError.add_assert(Htn.DecompositionStatus.SUCCEEDED == status)
	HtnError.add_assert(plan.is_valid())
	HtnError.add_assert(1 == plan.size())
	HtnError.add_assert("Sub-task2" == plan.peek().get_name())
	HtnError.add_assert(2 == ctx.get_method_traversal_record().size())
	HtnError.add_assert(0 == ctx.get_method_traversal_record()[0])
	HtnError.add_assert(1 == ctx.get_method_traversal_record()[1])
	HtnError.add_assert("" == HtnError.get_message())

static func decompose_compound_subtask_equal_to_last_mtr__expected_behavior():
	var ctx = MyContext.new()
	var task = HtnSelector.new("Test")
	var task2 = HtnSelector.new("Test2")
	task2.add_subtask(HtnPrimitiveTask.new("Sub-task1").add_condition(HtnFuncCondition.new(MyContext, "Done == true", func (context):
		return context.is_done())))
	task2.add_subtask(HtnPrimitiveTask.new("Sub-task2"))

	task.add_subtask(task2)
	task.add_subtask(HtnPrimitiveTask.new("Sub-task3"))

	ctx.get_last_mtr().append(0)

	var plan = HtnPlan.new()
	var status = task.decompose(ctx, 0, plan)

	HtnError.add_assert(Htn.DecompositionStatus.SUCCEEDED == status)
	HtnError.add_assert(plan.is_valid())
	HtnError.add_assert(1 == plan.size())
	HtnError.add_assert("Sub-task2" == plan.peek().get_name())
	HtnError.add_assert(2 == ctx.get_method_traversal_record().size())
	HtnError.add_assert(0 == ctx.get_method_traversal_record()[0])
	HtnError.add_assert(1 == ctx.get_method_traversal_record()[1])
	HtnError.add_assert("" == HtnError.get_message())

static func decompose_compound_subtask_lose_to_last_mtr__expected_behavior():
	var ctx = MyContext.new()
	var task = HtnSelector.new("Test")
	var task2 = HtnSelector.new("Test2")
	task2.add_subtask(HtnPrimitiveTask.new("Sub-task1").add_condition(HtnFuncCondition.new(MyContext, "Done == true", func (context):
		return context.is_done())))
	task2.add_subtask(HtnPrimitiveTask.new("Sub-task2"))

	task.add_subtask(HtnPrimitiveTask.new("Sub-task1").add_condition(HtnFuncCondition.new(MyContext, "Done == true", func (context):
		return context.is_done())))
	task.add_subtask(task2)

	ctx.get_last_mtr().append(0)

	var plan = HtnPlan.new()
	var status = task.decompose(ctx, 0, plan)

	HtnError.add_assert(Htn.DecompositionStatus.REJECTED == status)
	HtnError.add_assert(!plan.is_valid())
	HtnError.add_assert(1 == ctx.get_method_traversal_record().size())
	HtnError.add_assert(-1 == ctx.get_method_traversal_record()[0])
	HtnError.add_assert("" == HtnError.get_message())

static func decompose_compound_subtask_win_over_last_mtr__expected_behavior():
	var ctx = MyContext.new()
	var root_task = HtnSelector.new("Root")
	var task = HtnSelector.new("Test1")
	var task2 = HtnSelector.new("Test2")
	var task3 = HtnSelector.new("Test3")

	task3.add_subtask(HtnPrimitiveTask.new("Sub-task3-1").add_condition(HtnFuncCondition.new(MyContext, "Done == true", func (context):
		return context.is_done())))
	task3.add_subtask(HtnPrimitiveTask.new("Sub-task3-2"))

	task2.add_subtask(HtnPrimitiveTask.new("Sub-task2-1").add_condition(HtnFuncCondition.new(MyContext, "Done == true", func (context):
		return context.is_done())))
	task2.add_subtask(HtnPrimitiveTask.new("Sub-task2-2"))

	task.add_subtask(task2)
	task.add_subtask(task3)
	task.add_subtask(HtnPrimitiveTask.new("Sub-task1-1").add_condition(HtnFuncCondition.new(MyContext, "Done == false", func (context):
		return !context.is_done())))

	root_task.add_subtask(task)

	ctx.get_last_mtr().append(0)
	ctx.get_last_mtr().append(1)
	ctx.get_last_mtr().append(0)

	# In this test, we prove that [0, 0, 1] beats [0, 1, 0]
	var plan = HtnPlan.new()
	var status = root_task.decompose(ctx, 0, plan)

	HtnError.add_assert(Htn.DecompositionStatus.SUCCEEDED == status)
	HtnError.add_assert("" == HtnError.get_message())

static func decompose_compound_subtask_lose_to_last_mtr2__expected_behavior():
	var ctx = MyContext.new()
	var root_task = HtnSelector.new("Root")
	var task = HtnSelector.new("Test1")
	var task2 = HtnSelector.new("Test2")

	task2.add_subtask(HtnPrimitiveTask.new("Sub-task2-1").add_condition(HtnFuncCondition.new(MyContext, "Done == true", func (context):
		return context.is_done())))
	task2.add_subtask(HtnPrimitiveTask.new("Sub-task2-1"))

	task.add_subtask(HtnPrimitiveTask.new("Sub-task1-1").add_condition(HtnFuncCondition.new(MyContext, "Done == true", func (context):
		return context.is_done())))
	task.add_subtask(task2)

	root_task.add_subtask(task)

	ctx.get_last_mtr().append(0)
	ctx.get_last_mtr().append(1)
	ctx.get_last_mtr().append(0)

	# We expect this test to be rejected, because [0,1,1] shouldn't beat [0,1,0]
	var plan = HtnPlan.new()
	var status = root_task.decompose(ctx, 0, plan)

	HtnError.add_assert(Htn.DecompositionStatus.REJECTED == status)
	HtnError.add_assert(!plan.is_valid())
	HtnError.add_assert(3 == ctx.get_method_traversal_record().size())
	HtnError.add_assert(0 == ctx.get_method_traversal_record()[0])
	HtnError.add_assert(1 == ctx.get_method_traversal_record()[1])
	HtnError.add_assert(-1 == ctx.get_method_traversal_record()[2])
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
	decompose_with_no_subtasks__expected_behavior()
	HtnError.reset_message()
	decompose_with_subtasks__expected_behavior()
	HtnError.reset_message()
	decompose_with_subtasks2__expected_behavior()
	HtnError.reset_message()
	decompose_with_subtasks3__expected_behavior()
	HtnError.reset_message()
	decompose_mtr_fails__expected_behavior()
	HtnError.reset_message()
	decompose_debug_mtr_fails__expected_behavior()
	HtnError.reset_message()
	decompose_mtr_succeeds_when_equal__expected_behavior()
	HtnError.reset_message()
	decompose_compound_subtask_succeeds__expected_behavior()
	HtnError.reset_message()
	decompose_compound_subtask_fails__expected_behavior()
	HtnError.reset_message()
	decompose_nested_compound_subtask_fails__expected_behavior()
	HtnError.reset_message()
	decompose_compound_subtask_beats_last_mtr__expected_behavior()
	HtnError.reset_message()
	decompose_compound_subtask_equal_to_last_mtr__expected_behavior()
	HtnError.reset_message()
	decompose_compound_subtask_lose_to_last_mtr__expected_behavior()
	HtnError.reset_message()
	decompose_compound_subtask_win_over_last_mtr__expected_behavior()
	HtnError.reset_message()
	decompose_compound_subtask_lose_to_last_mtr2__expected_behavior()
