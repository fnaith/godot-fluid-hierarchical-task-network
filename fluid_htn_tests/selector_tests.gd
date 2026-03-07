class_name HtnSelectorTests
extends Object

## Verifies that a Selector correctly adds a condition to its conditions collection and returns itself for method chaining.
## A Selector is a compound task that decomposes by attempting its subtasks in order until one succeeds, implementing a choice point in the task hierarchy.
## Conditions are evaluated before decomposition to determine whether a selector is applicable in the current world state.
## This test ensures the fluent builder pattern works correctly for selectors by confirming conditions are stored and the method returns the task instance for continued chaining.
static func add_condition__expected_behavior() -> void:
	var task = HtnSelector.new("Test")

	var t = task.add_condition(HtnFuncCondition.new(MyContext, "TestCondition", func (context):
		context.set_done(false)))

	HtnError.add_assert(t == task)
	HtnError.add_assert(1 == task.get_conditions().size())
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that a Selector correctly adds a subtask to its subtasks collection and returns itself for method chaining.
## Selectors maintain an ordered list of subtasks that represent alternative decomposition paths.
## The selector tries each subtask in order during decomposition until one successfully decomposes, implementing first-match semantics.
## This test confirms the fluent builder pattern allows chaining subtask additions and that each subtask is properly stored in the collection.
static func add_subtask__expected_behavior() -> void:
	var task = HtnSelector.new("Test")

	var t = task.add_subtask(HtnPrimitiveTask.new("Sub-task"))

	HtnError.add_assert(t == task)
	HtnError.add_assert(1 == task.get_subtasks().size())
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that a Selector with no subtasks is considered invalid and cannot be decomposed.
## A selector requires at least one subtask option to be a valid decomposition point; an empty selector has nothing to choose from.
## During decomposition validation, the planner checks if a selector is valid before attempting decomposition, rejecting invalid selectors early.
## This test ensures selectors properly validate their structure and reject empty selectors that would cause decomposition failures.
static func is_valid_fails_without_subtasks__expected_behavior() -> void:
	var ctx = MyContext.new()
	var task = HtnSelector.new("Test")

	var result = task.is_valid(ctx)

	HtnError.add_assert(!result)
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that a Selector with subtasks is considered valid and can proceed to decomposition.
## A selector is valid when it has at least one subtask to attempt during decomposition.
## The planner uses IsValid as a gating check before attempting decomposition, enabling early rejection of unsuitable tasks.
## This test confirms that selectors with subtasks properly report validity, allowing decomposition to proceed.
static func is_valid__expected_behavior() -> void:
	var ctx = MyContext.new()
	var task = HtnSelector.new("Test")
	task.add_subtask(HtnPrimitiveTask.new("Sub-task"))

	var result = task.is_valid(ctx)

	HtnError.add_assert(result)
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that attempting to decompose a Selector with no subtasks returns Failed status and an empty plan.
## Decomposition is the process of breaking down a compound task into executable primitive tasks based on the current world state.
## When a selector has no subtasks, there are no alternatives to try, so decomposition fails with an empty plan queue.
## This test confirms the selector properly handles the edge case of an empty subtask list by returning Failed without crashing.
static func decompose_with_no_subtasks__expected_behavior() -> void:
	var ctx = MyContext.new()
	var task = HtnSelector.new("Test")

	var plan = HtnPlan.new()
	var status = task.decompose(ctx, 0, plan)

	HtnError.add_assert(Htn.DecompositionStatus.FAILED == status)
	HtnError.add_assert(plan.is_valid())
	HtnError.add_assert(plan.is_empty())
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that a Selector with valid subtasks successfully decomposes by selecting the first subtask.
## Selectors implement first-match semantics, attempting subtasks in order until one succeeds and produces a non-empty plan.
## Since primitive tasks always decompose successfully, the first subtask in the selector's list gets selected and added to the plan.
## This test demonstrates the basic selector decomposition behavior and confirms the first valid subtask becomes the next task to execute.
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

## Verifies that a Selector skips invalid subtasks and uses the next valid one for decomposition.
## When the first subtask (a selector with no children) is invalid, the selector tries the next alternative.
## This demonstrates the selector's backtracking behavior: it iterates through subtasks until finding one that is both valid and decomposes successfully.
## This test shows that selectors properly skip alternatives that cannot be decomposed, implementing robust fallback behavior.
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

## Verifies that a Selector properly evaluates conditions on subtasks and skips those that fail condition checks.
## Conditions gate whether a task can be selected during decomposition based on the current world state.
## The first subtask has a condition (Done == true) that fails since Done is false, so the selector moves to the next alternative.
## This test demonstrates how conditions implement data-driven task selection, allowing the planner to choose task alternatives based on environmental state.
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

## Verifies that a Selector rejects decomposition when the Method Traversal Record (MTR) indicates an alternative that fails.
## The MTR is a sequence of indices tracking which subtask was selected at each selector in the previous plan, used to prevent infinite replanning loops.
## When the LastMTR indicates the first subtask (index 0) should be chosen, but that subtask has a failing condition, the selector records -1 and rejects the entire decomposition.
## This test demonstrates how the MTR mechanism prevents the planner from repeatedly trying the same failing task alternatives, enforcing progress toward different solutions.
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

## Verifies that MTR failure rejection is properly logged in debug contexts for troubleshooting.
## Debug contexts record detailed decomposition traces in MTRDebug logs, providing visibility into planner decision-making for analysis and debugging.
## When MTR-based rejection occurs, the debug log captures "REPLAN FAIL" messages that identify which alternative was attempted and why the plan was rejected.
## This test demonstrates how debug logging helps developers understand replanning behavior and diagnose issues where the planner cannot find valid task decompositions.
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

## Verifies that a Selector succeeds when the MTR-indicated subtask successfully decomposes.
## The MTR provides hints about which subtask was previously chosen; when that subtask still decomposes successfully, the selector can continue with the same decomposition.
## If the MTR indicates subtask index 1 (Sub-task2), and that task is valid and decomposes successfully, the decomposition proceeds without rejection.
## This test demonstrates how the MTR mechanism enables the planner to reuse previous decomposition decisions when they remain valid, improving efficiency by avoiding redundant searches.
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

## Verifies that a Selector can decompose nested compound tasks (selectors within selectors) and correctly records MTR choices at each level.
## Compound tasks can contain other compound tasks, creating hierarchical decomposition: the outer selector tries its first subtask (an inner selector), which then decomposes.
## The MTR records the decomposition path: [0, 1] means the outer selector tried option 0 (inner selector), which tried option 1 (Sub-task2).
## This test demonstrates multi-level decomposition and MTR tracking, showing how the planner navigates complex task hierarchies and records the complete choice path.
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

## Verifies that when a nested selector fails to decompose, the outer selector backtracks and tries its next subtask.
## The nested selector task2 has all its subtasks failing conditions, so it cannot provide a valid decomposition.
## When nested decomposition fails, the outer selector moves to its next alternative (Sub-task3), which succeeds.
## This test demonstrates backtracking behavior across nesting levels: the planner explores the first alternative fully, and when it fails entirely, moves to the next option.
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

## Verifies that backtracking works correctly through multiple nesting levels when deeply nested selectors fail.
## The hierarchy has task (selector) -> task2 (selector) -> task3 (selector) -> all failing conditions.
## When the entire nested chain task2/task3 fails to produce a valid decomposition, the outer selector abandons the entire branch and tries its next alternative.
## This test demonstrates deep backtracking: failures at any nesting level trigger complete backtracking to the outer selector, which then tries its next option.
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

## Verifies that a better (earlier) decomposition path can override the last MTR hint, allowing the planner to find improvements.
## The LastMTR indicates [1] (outer selector's second option), but the planner discovers [0, 1] (outer option 0 -> inner option 1) as a valid decomposition.
## MTR comparison uses lexicographic ordering: [0, 1] is considered "better" (more preferred) than [1] because index 0 comes before index 1.
## This test demonstrates MTR-based replanning: the planner can find superior alternatives by exploring earlier decomposition indices, enabling progressive improvement.
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

## Verifies that when the new decomposition path equals the LastMTR, the planner accepts the identical solution.
## The LastMTR is [0] (try outer option 0), and the planner generates [0, 1] (outer option 0 -> inner option 1).
## Since the new path is not identical but shares the same first index, it's considered acceptable and not rejected.
## This test demonstrates MTR equality handling when decomposition paths extend or match the previous solution, ensuring consistent planning behavior.
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

## Verifies that the planner rejects decomposition when the new path is lexicographically worse (larger indices) than the LastMTR.
## The LastMTR indicates [0] (first option), but the planner would need to use [1] (second option, nested selector).
## Since [1] is lexicographically greater than [0], this represents a degradation in choice quality, and the decomposition is rejected to prevent backtracking to worse solutions.
## This test demonstrates the MTR mechanism's role in enforcing progress: the planner rejects decompositions that would constitute a backwards step compared to previous attempts.
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

## Verifies that the planner accepts a superior (lexicographically earlier) decomposition path even when longer and more complex.
## The LastMTR is [0, 1, 0] from a previous plan, but the planner discovers [0, 0, 1] as the new decomposition.
## Although [0, 0, 1] is one element longer, it beats [0, 1, 0] at the second level: 0 is lexicographically smaller than 1.
## This test demonstrates sophisticated MTR comparison logic: the planner compares paths element by element and accepts longer paths if they achieve earlier choices at any position.
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

## Verifies that the planner rejects a decomposition path that is lexicographically worse at any comparison point.
## The LastMTR is [0, 1, 0], and the planner would generate [0, 1, 1] by choosing option 1 at the last level instead of 0.
## Since at the third position, 1 > 0, the new path [0, 1, 1] is lexicographically worse and is rejected.
## This test demonstrates the strictness of MTR ordering: even partial agreement with the first elements doesn't help if a later element is worse.
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
