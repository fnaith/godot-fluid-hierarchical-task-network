class_name HtnSequence
extends HtnCompoundTask

#region FIELDS

var _plan: HtnPlan = HtnPlan.new()

#endregion

func _init(name: String = "") -> void:
	_name = name

func is_decompose_all() -> bool:
	return true

#region VALIDITY

func is_valid(ctx: HtnIContext) -> bool:
	# Check that our preconditions are valid first.
	if !super.is_valid(ctx):
		if ctx.is_log_decomposition():
			_log(ctx, "Sequence.IsValid:Failed:Preconditions not met!")

		return false

	# Selector requires there to be subtasks to successfully select from.
	if _subtasks.is_empty():
		if ctx.is_log_decomposition():
			_log(ctx, "Sequence.IsValid:Failed:No sub-tasks!")

		return false

	if ctx.is_log_decomposition():
		_log(ctx, "Sequence.IsValid:Success!")

	return true

#endregion

#region DECOMPOSITION

## In a Sequence decomposition, all sub-tasks must be valid and successfully decomposed in order for the Sequence to
## be successfully decomposed.
func on_decompose(ctx: HtnIContext, start_index: int, result: HtnPlan) -> Htn.DecompositionStatus:
	_plan.clear()

	var old_stack_depth = ctx.get_world_state_change_depth()

	var length = _subtasks.size()
	for task_index in range(start_index, length):
		var task = _subtasks[task_index]

		if ctx.is_log_decomposition():
			var name = task.get_name()
			_log(ctx, "Sequence.OnDecompose:Task index: %d: %s" % [task_index, name])

		var status = on_decompose_task(ctx, task, task_index, old_stack_depth, result)
		match status:
			Htn.DecompositionStatus.REJECTED, Htn.DecompositionStatus.FAILED, Htn.DecompositionStatus.PARTIAL:
				return status

	result.copy(_plan)
	return Htn.DecompositionStatus.FAILED if result.is_empty() else Htn.DecompositionStatus.SUCCEEDED

func on_decompose_task(ctx: HtnIContext, task: HtnITask, task_index: int, old_stack_depth: Array[int], result: HtnPlan) -> Htn.DecompositionStatus:
	if !task.is_valid(ctx):
		if ctx.is_log_decomposition():
			_log(ctx, "Sequence.OnDecomposeTask:Failed:Task %s.IsValid returned false!" % task.get_name())

		_plan.clear()
		ctx.trim_to_stack_depth(old_stack_depth)
		result.copy(_plan)
		return task.on_is_valid_failed(ctx)

	if Htn.TaskType.COMPOUND == task.get_type():
		var compound_task: HtnICompoundTask = task
		return on_decompose_compound_task(ctx, compound_task, task_index, old_stack_depth, result)

	if Htn.TaskType.PRIMITIVE == task.get_type():
		var primitive_task: HtnIPrimitiveTask = task
		on_decompose_primitive_task(ctx, primitive_task, task_index, old_stack_depth, result)

	elif Htn.TaskType.PAUSE_PLAN == task.get_type():
		if ctx.is_log_decomposition():
			_log(ctx, "Sequence.OnDecomposeTask:Return partial plan at index %d!" % task_index)

		ctx.set_paused_partial_plan(true)
		var entry = HtnPartialPlanEntry.new(self, task_index + 1)
		ctx.get_partial_plan_queue().append(entry)

		result.copy(_plan)
		return Htn.DecompositionStatus.PARTIAL

	elif Htn.TaskType.SLOT == task.get_type():
		var slot: HtnSlot = task
		return on_decompose_slot(ctx, slot, task_index, old_stack_depth, result)

	result.copy(_plan)
	var s = Htn.DecompositionStatus.FAILED if result.is_empty() else Htn.DecompositionStatus.SUCCEEDED

	if ctx.is_log_decomposition():
		var s1 = "Succeeded" if s == Htn.DecompositionStatus.SUCCEEDED else "Failed"
		_log(ctx, "Sequence.OnDecomposeTask:%s!" % s1)

	return s

func on_decompose_primitive_task(ctx: HtnIContext, task: HtnIPrimitiveTask, _task_index: int, _old_stack_depth: Array[int], result: HtnPlan) -> void:
	# We don't add MTR tracking on sequences for primary sub-tasks, since they will always be included, so they're irrelevant to MTR tracking.

	if ctx.is_log_decomposition():
		_log(ctx, "Sequence.OnDecomposeTask:Pushed %s to plan!" % task.get_name())

	task.apply_effects(ctx)
	_plan.enqueue(task)
	result.copy(_plan)

func on_decompose_compound_task(ctx: HtnIContext, task: HtnICompoundTask, task_index: int, old_stack_depth: Array[int], result: HtnPlan) -> Htn.DecompositionStatus:
	var sub_plan: HtnPlan = HtnPlan.new()
	var status = task.decompose(ctx, 0, sub_plan)

	# If result is null, that means the entire planning procedure should cancel.
	if Htn.DecompositionStatus.REJECTED == status:
		if ctx.is_log_decomposition():
			_log(ctx, "Sequence.OnDecomposeCompoundTask:%s: Decomposing %s was rejected." % ["Rejected", task.get_name()])

		_plan.clear()
		ctx.trim_to_stack_depth(old_stack_depth)

		result.invalidate()
		return Htn.DecompositionStatus.REJECTED

	# If the decomposition failed
	if Htn.DecompositionStatus.FAILED == status:
		if ctx.is_log_decomposition():
			_log(ctx, "Sequence.OnDecomposeCompoundTask:%s: Decomposing %s failed." % ["Failed", task.get_name()])

		_plan.clear()
		ctx.trim_to_stack_depth(old_stack_depth)
		result.copy(_plan)
		return Htn.DecompositionStatus.FAILED

	while !sub_plan.is_empty():
		var p = sub_plan.dequeue()

		if ctx.is_log_decomposition():
			_log(ctx, "Sequence.OnDecomposeCompoundTask:Decomposing %s:Pushed %s to plan!" % [task.get_name(), p.get_name()])

		_plan.enqueue(p)

	if ctx.has_paused_partial_plan():
		if ctx.is_log_decomposition():
			_log(ctx, "Sequence.OnDecomposeCompoundTask:Return partial plan at index %d!" % task_index)

		if task_index < _subtasks.size() - 1:
			var entry = HtnPartialPlanEntry.new(self, task_index + 1)
			ctx.get_partial_plan_queue().append(entry)

		result.copy(_plan)
		return Htn.DecompositionStatus.PARTIAL

	result.copy(_plan)

	if ctx.is_log_decomposition():
		_log(ctx, "Sequence.OnDecomposeCompoundTask:Succeeded!")

	return Htn.DecompositionStatus.SUCCEEDED

func on_decompose_slot(ctx: HtnIContext, task: HtnSlot, task_index: int, old_stack_depth: Array[int], result: HtnPlan) -> Htn.DecompositionStatus:
	var sub_plan: HtnPlan = HtnPlan.new()
	var status = task.decompose(ctx, 0, sub_plan)

	# If result is null, that means the entire planning procedure should cancel.
	if Htn.DecompositionStatus.REJECTED == status:
		if ctx.is_log_decomposition():
			_log(ctx, "Sequence.OnDecomposeSlot:%s: Decomposing %s was rejected." % ["Rejected", task.get_name()])

		_plan.clear()
		ctx.trim_to_stack_depth(old_stack_depth)

		result.invalidate()
		return Htn.DecompositionStatus.REJECTED

	# If the decomposition failed
	if Htn.DecompositionStatus.FAILED == status:
		if ctx.is_log_decomposition():
			_log(ctx, "Sequence.OnDecomposeSlot:%s: Decomposing %s failed." % ["Failed", task.get_name()])

		_plan.clear()
		ctx.trim_to_stack_depth(old_stack_depth)
		result.copy(_plan)
		return Htn.DecompositionStatus.FAILED

	while !sub_plan.is_empty():
		var p = sub_plan.dequeue()

		if ctx.is_log_decomposition():
			_log(ctx, "Sequence.OnDecomposeSlot:Decomposing %s:Pushed %s to plan!" % [task.get_name(), p.get_name()])

		_plan.enqueue(p)

	if ctx.has_paused_partial_plan():
		if ctx.is_log_decomposition():
			_log(ctx, "Sequence.OnDecomposeSlot:Return partial plan at index %d!" % task_index)

		if task_index < _subtasks.size() - 1:
			var entry = HtnPartialPlanEntry.new(self, task_index + 1)
			ctx.get_partial_plan_queue().append(entry)

		result.copy(_plan)
		return Htn.DecompositionStatus.PARTIAL

	result.copy(_plan)

	if ctx.is_log_decomposition():
		_log(ctx, "Sequence.OnDecomposeSlot:Succeeded!")

	return Htn.DecompositionStatus.SUCCEEDED

#endregion
