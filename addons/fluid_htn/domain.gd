class_name HtnDomain
extends HtnIDomain

#region FIELDS

var _slots: Dictionary = {}
var _root: HtnTaskRoot

#endregion

#region CONSTRUCTION

func _init(name: String) -> void:
	_root = HtnTaskRoot.new(name)

#endregion

#region PROPERTIES

func get_root() -> HtnTaskRoot:
	return _root

#endregion

#region HIERARCHY HANDLING

func add_subtask(parent: HtnICompoundTask, subtask: HtnITask) -> void:
	if parent == subtask:
		HtnError.set_message("Parent-task and Sub-task can't be the same instance!")
		return

	parent.add_subtask(subtask)
	subtask.set_parent(parent)

func add_slot(parent: HtnICompoundTask, slot: HtnSlot) -> void:
	if _slots.has(slot.get_slot_id()):
		HtnError.set_message("This slot id already exist in the domain definition!")
		return

	parent.add_subtask(slot)
	slot.set_parent(parent)

	_slots[slot.get_slot_id()] = slot

#endregion

#region PLANNING

func find_plan(ctx: HtnIContext, plan: HtnPlan) -> Htn.DecompositionStatus:
	if null == ctx:
		HtnError.set_message("Context was not existed!")
		return Htn.DecompositionStatus.FAILED

	if !ctx.is_initialized():
		HtnError.set_message("Context was not initialized!")
		return Htn.DecompositionStatus.FAILED

	ctx.set_context_state(Htn.ContextState.PLANNING)

	plan.invalidate()
	var status = Htn.DecompositionStatus.REJECTED

	# We first check whether we have a stored start task. This is true
	# if we had a partial plan pause somewhere in our plan, and we now
	# want to continue where we left off.
	# If this is the case, we don't erase the MTR, but continue building it.
	# However, if we have a partial plan, but LastMTR is not 0, that means
	# that the partial plan is still running, but something triggered a replan.
	# When this happens, we have to plan from the domain root (we're not
	# continuing the current plan), so that we're open for other plans to replace
	# the running partial plan.
	if ctx.has_paused_partial_plan() and ctx.get_last_mtr().is_empty():
		status = _on_paused_partial_plan(ctx, plan, status)
	else:
		status = _on_replan_during_partial_planning(ctx, plan, status)

	# If this MTR equals the last MTR, then we need to double-check whether we ended up
	# just finding the exact same plan. During decomposition each compound task can't check
	# for equality, only for less than, so this case needs to be treated after the fact.
	if _has_found_same_plan(ctx):
		plan.invalidate()
		status = Htn.DecompositionStatus.REJECTED

	if _has_decomposition_succeeded(status):
		# Apply permanent world state changes to the actual world state used during plan execution.
		_apply_permanent_world_state_stack_changes(ctx)
	else:
		# Clear away any changes that might have been applied to the stack
		# No changes should be made or tracked further when the plan failed.
		_clear_world_state_stack_changes(ctx)

	ctx.set_context_state(Htn.ContextState.EXECUTING)
	return status

## We first check whether we have a stored start task. This is true
## if we had a partial plan pause somewhere in our plan, and we now
## want to continue where we left off.
## If this is the case, we don't erase the MTR, but continue building it.
## However, if we have a partial plan, but LastMTR is not 0, that means
## that the partial plan is still running, but something triggered a replan.
## When this happens, we have to plan from the domain root (we're not
## continuing the current plan), so that we're open for other plans to replace
## the running partial plan.
func _on_replan_during_partial_planning(ctx: HtnIContext, plan: HtnPlan, status: Htn.DecompositionStatus) -> Htn.DecompositionStatus:
	var last_partial_plan_queue = _cache_last_partial_plan(ctx)

	_clear_method_traversal_record(ctx)

	# Replan through decomposition of the hierarchy
	status = _root.decompose(ctx, 0, plan)

	if _has_decomposition_failed(status):
		_restore_last_partial_plan(ctx, last_partial_plan_queue, status)

	return status

## If there is a paused partial plan, we cache it to a last partial plan queue.
## This is useful when we want to perform a replan, but don't know yet if it will
## win over the current plan.
func _cache_last_partial_plan(ctx: HtnIContext) -> Variant: # Array[HtnPartialPlanEntry]
	if !ctx.has_paused_partial_plan():
		return null

	ctx.HasPausedPartialPlan = false
	var last_partial_plan_queue: Array[HtnPartialPlanEntry] = []

	while !ctx.get_partial_plan_queue().is_empty():
		last_partial_plan_queue.append(ctx.get_partial_plan_queue().pop_front())

	return last_partial_plan_queue

## If we failed to find a new plan, we have to restore the old plan,
## if it was a partial plan.
func _restore_last_partial_plan(ctx: HtnIContext, last_partial_plan_queue: Variant, status: Htn.DecompositionStatus) -> void:
	if null == last_partial_plan_queue:
		return

	ctx.set_paused_partial_plan(true)
	ctx.get_partial_plan_queue().clear()

	while !last_partial_plan_queue.is_empty():
		ctx.get_partial_plan_queue().append(last_partial_plan_queue.pop_front())

## We only erase the MTR if we start from the root task of the domain.
func _clear_method_traversal_record(ctx: HtnIContext) -> void:
	ctx.get_method_traversal_record().clear()

	if ctx.is_debug_mtr():
		ctx.get_mtr_debug().clear()

## If decomposition status is failed or rejected, the replan failed.
func _has_decomposition_failed(status: Htn.DecompositionStatus) -> bool:
	return status == Htn.DecompositionStatus.REJECTED or status == Htn.DecompositionStatus.FAILED

## If decomposition status is failed or rejected, the replan failed.
func _has_decomposition_succeeded(status: Htn.DecompositionStatus) -> bool:
	return status == Htn.DecompositionStatus.SUCCEEDED or status == Htn.DecompositionStatus.PARTIAL

## We first check whether we have a stored start task. This is true
## if we had a partial plan pause somewhere in our plan, and we now
## want to continue where we left off.
## If this is the case, we don't erase the MTR, but continue building it.
func _on_paused_partial_plan(ctx: HtnIContext, plan: HtnPlan, status: Htn.DecompositionStatus) -> Htn.DecompositionStatus:
	ctx.set_paused_partial_plan(false)
	while !ctx.get_partial_plan_queue().is_empty():
		var kvp = ctx.get_partial_plan_queue().pop_front()
		if !plan.is_valid():
			status = kvp.task.decompose(ctx, kvp.task_index, plan)
		else:
			var sub_plan = HtnPlan.new()
			status = kvp.task.decompose(ctx, kvp.task_index, sub_plan)
			if _has_decomposition_succeeded(status):
				_enqueue_to_existing_plan(plan, sub_plan)

		# While continuing a partial plan, we might encounter
		# a new pause.
		if ctx.has_paused_partial_plan():
			break

	# If we failed to continue the paused partial plan,
	# then we have to start planning from the root.
	if _has_decomposition_failed(status):
		_clear_method_traversal_record(ctx)

		status = _root.decompose(ctx, 0, plan)

	return status

## Enqueues the sub plan's queue onto the existing plan
func _enqueue_to_existing_plan(plan: HtnPlan, sub_plan: HtnPlan) -> void:
	while !sub_plan.is_empty():
		plan.enqueue(sub_plan.dequeue())

## If this MTR equals the last MTR, then we need to double-check whether we ended up
## just finding the exact same plan. During decomposition each compound task can't check
## for equality, only for less than, so this case needs to be treated after the fact.
func _has_found_same_plan(ctx: HtnIContext) -> bool:
	var is_mtrs_equal = ctx.get_method_traversal_record().size() == ctx.get_last_mtr().size()
	if is_mtrs_equal:
		var length = ctx.get_method_traversal_record().size()
		for i in length:
			if ctx.get_method_traversal_record()[i] < ctx.get_last_mtr()[i]:
				is_mtrs_equal = false
				break

		return is_mtrs_equal

	return false

## Apply permanent world state changes to the actual world state used during plan execution.
func _apply_permanent_world_state_stack_changes(ctx: HtnIContext) -> void:
	# Trim away any plan-only or plan&execute effects from the world state change stack, that only
	# permanent effects on the world state remains now that the planning is done.
	ctx.trim_for_execution()
	
	var length = ctx.get_world_state_change_stack().size()
	for i in length:
		var stack = ctx.get_world_state_change_stack()[i]
		if null != stack and !stack.is_empty():
			ctx.get_world_state()[i] = stack.back()[1]
			stack.clear()

## Clear away any changes that might have been applied to the stack
func _clear_world_state_stack_changes(ctx: HtnIContext) -> void:
	var length = ctx.get_world_state_change_stack().size()
	for i in length:
		var stack = ctx.get_world_state_change_stack()[i]
		if null != stack and !stack.is_empty():
			stack.clear()

#endregion

#region SLOTS

## At runtime, set a sub-domain to the slot with the given id.
## This can be used with Smart Objects, to extend the behavior
## of an agent at runtime.
func try_set_slot_domain(slot_id: int, sub_domain: HtnIDomain) -> bool:
	var slot = _slots.get(slot_id, null)
	if null != slot:
		return slot.set_subtask(sub_domain.get_root())

	return false

## At runtime, clear the sub-domain from the slot with the given id.
## This can be used with Smart Objects, to extend the behavior
## of an agent at runtime.
func clear_slot(slot_id: int) -> void:
	var slot = _slots.get(slot_id, null)
	if null != slot:
		slot.clear_subtask()

#endregion
