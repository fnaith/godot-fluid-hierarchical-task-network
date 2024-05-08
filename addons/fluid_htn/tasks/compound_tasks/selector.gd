class_name HtnSelector
extends HtnCompoundTask

#region FIELDS

var _plan: HtnPlan = HtnPlan.new()

#endregion

func _init(name: String = "") -> void:
	_name = name

#region VALIDITY

func is_valid(ctx: HtnIContext) -> bool:
	# Check that our preconditions are valid first.
	if !super.is_valid(ctx):
		if ctx.is_log_decomposition():
			_log(ctx, "Selector.IsValid:Failed:Preconditions not met!")

		return false

	# Selector requires there to be at least one sub-task to successfully select from.
	if _subtasks.is_empty():
		if ctx.is_log_decomposition():
			_log(ctx, "Selector.IsValid:Failed:No sub-tasks!")

		return false

	if ctx.is_log_decomposition():
		_log(ctx, "Selector.IsValid:Success!")

	return true

func beats_last_mtr(ctx: HtnIContext, task_index: int, current_decomposition_index: int) -> bool:
	# If the last plan's traversal record for this decomposition layer
	# has a smaller index than the current task index we're about to
	# decompose, then the new decomposition can't possibly beat the
	# running plan, so we cancel finding a new plan.
	if ctx.get_last_mtr()[current_decomposition_index] < task_index:
		# But, if any of the earlier records beat the record in LastMTR, we're still good, as we're on a higher priority branch.
		# This ensures that [0,0,1] can beat [0,1,0]
		var length = ctx.get_method_traversal_record().size()
		for i in length:
			var diff = ctx.get_method_traversal_record()[i] - ctx.get_last_mtr()[i]

			if diff < 0:
				return true

			if 0 < diff:
				# We should never really be able to get here, but just in case.
				return false

		return false

	return true

#endregion

#region DECOMPOSITION

## In a Selector decomposition, just a single sub-task must be valid and successfully decompose for the Selector to be
## successfully decomposed.
func on_decompose(ctx: HtnIContext, start_index: int,\
		result: HtnPlan) -> Htn.DecompositionStatus:
	_plan.clear()

	for task_index in range(start_index, _subtasks.size()):
		var task = _subtasks[task_index]

		if ctx.is_log_decomposition():
			var name = task.get_name()
			_log(ctx, "Selector.OnDecompose:Task index: %d: %s" % [task_index, name])

		# If the last plan is still running, we need to check whether the
		# new decomposition can possibly beat it.
		if !ctx.get_last_mtr().is_empty():
			if ctx.get_method_traversal_record().size() < ctx.get_last_mtr().size():
				var current_decomposition_index = ctx.get_method_traversal_record().size()
				if !beats_last_mtr(ctx, task_index, current_decomposition_index):
					ctx.get_method_traversal_record().append(-1)
					if ctx.is_debug_mtr():
						ctx.get_mtr_debug().append("REPLAN FAIL %s" % task.get_name())

					if ctx.is_log_decomposition():
						_log(ctx, "Selector.OnDecompose:Rejected:Index %d is beat by last method traversal record!" % current_decomposition_index)

					result.invalidate()
					return Htn.DecompositionStatus.REJECTED

		var status = on_decompose_task(ctx, task, task_index, [], result)
		match status:
			Htn.DecompositionStatus.REJECTED, Htn.DecompositionStatus.SUCCEEDED, Htn.DecompositionStatus.PARTIAL:
				return status
			Htn.DecompositionStatus.FAILED, _:
				continue

	result.copy(_plan)
	return Htn.DecompositionStatus.FAILED if result.is_empty() else Htn.DecompositionStatus.SUCCEEDED

func on_decompose_task(ctx: HtnIContext, task: HtnITask, task_index: int, _old_stack_depth: Array[int], result: HtnPlan) -> Htn.DecompositionStatus:
	if !task.is_valid(ctx):
		if ctx.is_log_decomposition():
			_log(ctx, "Selector.OnDecomposeTask:Failed:Task %s.IsValid returned false!" % task.get_name())

		result.copy(_plan)
		return task.on_is_valid_failed(ctx)

	if Htn.TaskType.COMPOUND == task.get_type():
		var compound_task: HtnICompoundTask = task
		return on_decompose_compound_task(ctx, compound_task, task_index, [], result)

	if Htn.TaskType.PRIMITIVE == task.get_type():
		var primitive_task: HtnIPrimitiveTask = task
		on_decompose_primitive_task(ctx, primitive_task, task_index, [], result)

	if Htn.TaskType.SLOT == task.get_type():
		var slot: HtnSlot = task
		return on_decompose_slot(ctx, slot, task_index, [], result)

	result.copy(_plan)
	var status = Htn.DecompositionStatus.FAILED if result.is_empty() else Htn.DecompositionStatus.SUCCEEDED

	if ctx.is_log_decomposition():
		_log(ctx, "Selector.OnDecomposeTask:%s!" % ["Succeeded" if status == Htn.DecompositionStatus.SUCCEEDED else
				"PARTIAL" if status == Htn.DecompositionStatus.PARTIAL else
				"Failed" if status == Htn.DecompositionStatus.FAILED else
				"Rejected" if status == Htn.DecompositionStatus.REJECTED else
				"???"])

	return status

func on_decompose_primitive_task(ctx: HtnIContext, task: HtnIPrimitiveTask, task_index: int, _old_stack_depth: Array[int], result: HtnPlan) -> void:
	# We need to record the task index before we decompose the task,
	# so that the traversal record is set up in the right order.
	ctx.get_method_traversal_record().append(task_index)
	if ctx.is_debug_mtr():
		ctx.get_mtr_debug().append(task.get_name())

	if ctx.is_log_decomposition():
		_log(ctx, "Selector.OnDecomposeTask:Pushed %s to plan!" % task.get_name())

	task.apply_effects(ctx)
	_plan.enqueue(task)
	result.copy(_plan)

func on_decompose_compound_task(ctx: HtnIContext, task: HtnICompoundTask, task_index: int, _old_stack_depth: Array[int], result: HtnPlan) -> Htn.DecompositionStatus:
	# We need to record the task index before we decompose the task,
	# so that the traversal record is set up in the right order.
	ctx.get_method_traversal_record().append(task_index)

	if ctx.is_debug_mtr():
		ctx.get_mtr_debug().append(task.get_name())

	var sub_plan: HtnPlan = HtnPlan.new()
	var status = task.decompose(ctx, 0, sub_plan)

	# If status is rejected, that means the entire planning procedure should cancel.
	if Htn.DecompositionStatus.REJECTED == status:
		if ctx.is_log_decomposition():
			_log(ctx, "Selector.OnDecomposeCompoundTask:%s: Decomposing %s was rejected." % ["Rejected", task.get_name()])

		result.invalidate()
		return Htn.DecompositionStatus.REJECTED

	# If the decomposition failed
	if Htn.DecompositionStatus.FAILED == status:
		# Remove the taskIndex if it failed to decompose.
		ctx.get_method_traversal_record().pop_back()
		if ctx.is_debug_mtr():
			ctx.get_mtr_debug().pop_back()

		if ctx.is_log_decomposition():
			_log(ctx, "Selector.OnDecomposeCompoundTask:%s: Decomposing %s failed." % ["Failed", task.get_name()])

		result.copy(_plan)
		return Htn.DecompositionStatus.FAILED

	while !sub_plan.is_empty():
		var p = sub_plan.dequeue()
		if ctx.is_log_decomposition():
			_log(ctx, "Selector.OnDecomposeCompoundTask:Decomposing %s:Pushed %s to plan!" % [task.get_name(), p.get_name()])

		_plan.enqueue(p)

	if ctx.has_paused_partial_plan():
		if ctx.is_log_decomposition():
			_log(ctx, "Selector.OnDecomposeCompoundTask:Return partial plan at index %d!" % task_index)

		result.copy(_plan)
		return Htn.DecompositionStatus.PARTIAL

	result.copy(_plan)
	var s = Htn.DecompositionStatus.FAILED if result.is_empty() else Htn.DecompositionStatus.SUCCEEDED

	if ctx.is_log_decomposition():
		var s1 = "Succeeded" if s == Htn.DecompositionStatus.SUCCEEDED else "Failed"
		_log(ctx, "Selector.OnDecomposeCompoundTask:%s!" % s1)

	return s

func on_decompose_slot(ctx: HtnIContext, task: HtnSlot, task_index: int, _old_stack_depth: Array[int], result: HtnPlan) -> Htn.DecompositionStatus:
	# We need to record the task index before we decompose the task,
	# so that the traversal record is set up in the right order.
	ctx.get_method_traversal_record().append(task_index)

	if ctx.is_debug_mtr():
		ctx.get_mtr_debug().append(task.get_name())

	var sub_plan: HtnPlan = HtnPlan.new()
	var status = task.decompose(ctx, 0, sub_plan)

	# If status is rejected, that means the entire planning procedure should cancel.
	if Htn.DecompositionStatus.REJECTED == status:
		if ctx.is_log_decomposition():
			_log(ctx, "Selector.OnDecomposeSlot:%s: Decomposing %s was rejected." % ["Rejected", task.get_name()])

		result.invalidate()
		return Htn.DecompositionStatus.REJECTED

	# If the decomposition failed
	if Htn.DecompositionStatus.FAILED == status:
		# Remove the taskIndex if it failed to decompose.
		ctx.get_method_traversal_record().pop_back()
		if ctx.is_debug_mtr():
			ctx.get_mtr_debug().pop_back()

		if ctx.is_log_decomposition():
			_log(ctx, "Selector.OnDecomposeSlot:%s: Decomposing %s failed." % ["Failed", task.get_name()])

		result.invalidate()
		return Htn.DecompositionStatus.FAILED

	while !sub_plan.is_empty():
		var p = sub_plan.dequeue()

		if ctx.is_log_decomposition():
			_log(ctx, "Selector.OnDecomposeSlot:Decomposing %s:Pushed %s to plan!" % [task.get_name(), p.get_name()])

		_plan.enqueue(p)

	if ctx.has_paused_partial_plan():
		if ctx.is_log_decomposition():
			_log(ctx, "Selector.OnDecomposeSlot:Return partial plan!")

		result.copy(_plan)
		return Htn.DecompositionStatus.PARTIAL

	result.copy(_plan)
	var s = Htn.DecompositionStatus.FAILED if result.is_empty() else Htn.DecompositionStatus.SUCCEEDED

	if ctx.is_log_decomposition():
		var s1 = "Succeeded" if result else "Failed"
		_log(ctx, "Selector.OnDecomposeSlot:%s!" % s1)

	return s

#endregion
