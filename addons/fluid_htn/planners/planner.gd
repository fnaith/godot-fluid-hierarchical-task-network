## A planner is a responsible for handling the management of finding plans in a domain, replan when the state of the
## running plan
## demands it, or look for a new potential plan if the world state gets dirty.
class_name HtnPlanner
extends RefCounted

#region TICK PLAN

## Call this with a domain and context instance to have the planner manage plan and task handling for the domain at
## runtime.
## If the plan completes or fails, the planner will find a new plan, or if the context is marked dirty, the planner
## will attempt
## a replan to see whether we can find a better plan now that the state of the world has changed.
## This planner can also be used as a blueprint for writing a custom planner.
func tick(domain: HtnIDomain, ctx: HtnIContext, allow_immediate_replan: bool = true) -> void:
	if null == ctx:
		HtnError.set_message("Context was not existed!")
		return
	if null == domain:
		HtnError.set_message("Domain was not existed!")
		return
	if !ctx.is_initialized():
		HtnError.set_message("Context was not initialized!")
		return

	var decomposition_status = Htn.DecompositionStatus.FAILED
	var is_trying_to_replace_plan = false
	# Check whether state has changed or the current plan has finished running.
	# and if so, try to find a new plan.
	if _should_find_new_plan(ctx):
		decomposition_status = _try_find_new_plan(domain, ctx, decomposition_status)
		is_trying_to_replace_plan = !ctx.get_planner_state().get_plan().is_empty()

	# If the plan has more tasks, we try to select the next one.
	if _can_select_next_task_in_plan(ctx):
		# Select the next task, but check whether the conditions of the next task failed to validate.
		if !_select_next_task_in_plan(domain, ctx):
			return

	# If the current task is a primitive task, we try to tick its operator.
	var current_task = ctx.get_planner_state().get_current_task()
	if null != current_task and Htn.TaskType.PRIMITIVE == current_task.get_type():
		var task: HtnIPrimitiveTask = current_task
		if !_try_tick_primitive_task_operator(domain, ctx, task, allow_immediate_replan):
			return

	# Check whether the planner failed to find a plan
	if _has_failed_to_find_plan(is_trying_to_replace_plan, decomposition_status, ctx):
		ctx.get_planner_state().set_last_status(Htn.TaskStatus.FAILURE)

## Check whether state has changed or the current plan has finished running.
## and if so, try to find a new plan.
func  _should_find_new_plan(ctx: HtnIContext) -> bool:
	return ctx.is_dirty() or (null == ctx.get_planner_state().get_current_task() and ctx.get_planner_state().get_plan().is_empty())

func _try_find_new_plan(domain: HtnDomain, ctx: HtnIContext, decomposition_status: Htn.DecompositionStatus) -> Htn.DecompositionStatus:
	var last_partial_plan_queue = _prepare_dirty_world_state_for_replan(ctx)

	var new_plan = HtnPlan.new()
	decomposition_status = domain.find_plan(ctx, new_plan)

	if _has_found_new_plan(decomposition_status):
		_on_found_new_plan(ctx, new_plan)
	elif null != last_partial_plan_queue:
		_restore_last_partial_plan(ctx, last_partial_plan_queue)
		_restore_last_method_traversal_record(ctx)

	return decomposition_status

## If we're simply re-evaluating whether to replace the current plan because
## some world state got dirty, then we do not intend to continue a partial plan
## right now, but rather see whether the world state changed to a degree where
## we should pursue a better plan.
func _prepare_dirty_world_state_for_replan(ctx: HtnIContext) -> Variant: # Queue<PartialPlanEntry>
	if !ctx.is_dirty():
		return null

	ctx.set_dirty(false)

	var last_partial_plan = _cache_last_partial_plan(ctx)
	if null == last_partial_plan:
		return null

	# We also need to ensure that the last mtr is up to date with the on-going MTR of the partial plan,
	# so that any new potential plan that is decomposing from the domain root has to beat the currently
	# running partial plan.
	_copy_mtr_to_last_mtr(ctx)

	return last_partial_plan

func _cache_last_partial_plan(ctx: HtnIContext) -> Variant: # Queue<PartialPlanEntry>
	if !ctx.has_paused_partial_plan():
		return null

	ctx.set_paused_partial_plan(false)
	var last_partial_plan_queue: Array[HtnPartialPlanEntry] = []

	while !ctx.get_partial_plan_queue().is_empty():
		last_partial_plan_queue.append(ctx.get_partial_plan_queue().pop_front())

	return last_partial_plan_queue

func _restore_last_partial_plan(ctx: HtnIContext, last_partial_plan_queue: Array[HtnPartialPlanEntry]) -> void:
	ctx.set_paused_partial_plan(true)
	ctx.get_partial_plan_queue().clear()

	while !last_partial_plan_queue.is_empty():
		ctx.get_partial_plan_queue().append(last_partial_plan_queue.pop_front())

func _has_found_new_plan(decomposition_status: Htn.DecompositionStatus) -> bool:
	return decomposition_status == Htn.DecompositionStatus.SUCCEEDED or\
			decomposition_status == Htn.DecompositionStatus.PARTIAL

func _on_found_new_plan(ctx: HtnIContext, new_plan: HtnPlan) -> void:
	var planner_state = ctx.get_planner_state()
	var plan = planner_state.get_plan()
	var current_task = planner_state.get_current_task()
	if null != planner_state.on_replace_plan and (!plan.is_empty() or null != current_task):
		planner_state.on_replace_plan.call(plan, current_task, new_plan)
	elif null != planner_state.on_new_plan and plan.is_empty():
		planner_state.on_new_plan.call(new_plan)

	plan.clear()
	while !new_plan.is_empty():
		plan.enqueue(new_plan.dequeue())

	# If a task was running from the previous plan, we stop it.
	if null != current_task and Htn.TaskType.PRIMITIVE == current_task.get_type():
		var t: HtnIPrimitiveTask = current_task
		if null != planner_state.on_stop_current_task:
			planner_state.on_stop_current_task.call(t)
		t.stop(ctx)
		planner_state.set_current_task(null)

	# Copy the MTR into our LastMTR to represent the current plan's decomposition record
	# that must be beat to replace the plan.
	_copy_mtr_to_last_mtr(ctx)

## Copy the MTR into our LastMTR to represent the current plan's decomposition record
## that must be beat to replace the plan.
func _copy_mtr_to_last_mtr(ctx: HtnIContext) -> void:
	if null != ctx.get_method_traversal_record():
		ctx.get_last_mtr().clear()
		for record in ctx.get_method_traversal_record():
			ctx.get_last_mtr().append(record)
		
		if ctx.is_debug_mtr():
			ctx.get_last_mtr_debug().clear()
			for record in ctx.get_mtr_debug():
				ctx.get_last_mtr_debug().append(record)

## Copy the Last MTR back into our MTR. This is done during rollback when a new plan
## failed to beat the last plan.
func _restore_last_method_traversal_record(ctx: HtnIContext) -> void:
	if !ctx.get_last_mtr().is_empty():
		ctx.get_method_traversal_record().clear()
		for record in ctx.get_last_mtr():
			ctx.get_method_traversal_record().append(record)
		ctx.get_last_mtr().clear()

		if !ctx.is_debug_mtr():
			return

		ctx.get_mtr_debug().clear()
		for record in ctx.get_last_mtr_debug():
			ctx.get_mtr_debug().append(record)
		ctx.get_last_mtr_debug().clear()

## If current task is null, we need to verify that the plan has more tasks queued.
func _can_select_next_task_in_plan(ctx: HtnIContext) -> bool:
	var planner_state = ctx.get_planner_state()
	return null == planner_state.get_current_task() and !planner_state.get_plan().is_empty()

## Dequeues the next task of the plan and checks its conditions. If a condition fails, we require a replan.
func _select_next_task_in_plan(domain: HtnDomain, ctx: HtnIContext) -> bool:
	var planner_state = ctx.get_planner_state()
	var plan = planner_state.get_plan()
	var current_task = plan.dequeue()
	planner_state.set_current_task(current_task)
	if null != current_task:
		if null != planner_state.on_new_task:
			planner_state.on_new_task.call(current_task)

		return _is_conditions_valid(ctx)

	return true

## While we have a valid primitive task running, we should tick it each tick of the plan execution.
func _try_tick_primitive_task_operator(domain: HtnDomain, ctx: HtnIContext, task: HtnIPrimitiveTask, allow_immediate_replan: bool) -> bool:
	var planner_state = ctx.get_planner_state()
	if null != task.get_operator():
		if !_is_executing_conditions_valid(domain, ctx, task, allow_immediate_replan):
			return false

		var last_status = task.get_operator().update(ctx)
		planner_state.set_last_status(last_status)

		# If the operation finished successfully, we set task to null so that we dequeue the next task in the plan the following tick.
		if Htn.TaskStatus.SUCCESS == last_status:
			_on_operator_finished_successfully(domain, ctx, task, allow_immediate_replan)
			return true

		# If the operation failed to finish, we need to fail the entire plan, so that we will replan the next tick.
		if Htn.TaskStatus.FAILURE == last_status:
			_fail_entire_plan(ctx, task)
			return true

		# Otherwise the operation isn't done yet and need to continue.
		if null != planner_state.on_current_task_continues:
			planner_state.on_current_task_continues.call(task)
		return true

	# This should not really happen if a domain is set up properly.
	task.aborted(ctx)
	planner_state.set_current_task(null)
	planner_state.set_last_status(Htn.TaskStatus.FAILURE)
	return true

## Ensure conditions are valid when a new task is selected from the plan
func _is_conditions_valid(ctx: HtnIContext) -> bool:
	var planner_state = ctx.get_planner_state()
	var current_task = planner_state.get_current_task()
	for condition in current_task.get_conditions():
		# If a condition failed, then the plan failed to progress! A replan is required.
		if !condition.is_valid(ctx):
			if null != planner_state.on_new_task_condition_failed:
				planner_state.on_new_task_condition_failed.call(current_task, condition)
			_abort_task(ctx, current_task)

			return false

	return true

## When a task is aborted (due to failed condition checks),
## we prepare the context for a replan next tick.
func _abort_task(ctx: HtnIContext, task: HtnIPrimitiveTask) -> void:
	if null != task:
		task.aborted(ctx)
	_clear_plan_for_replan(ctx)

## If the operation finished successfully, we set task to null so that we dequeue the next task in the plan the following tick.
func _on_operator_finished_successfully(domain: HtnDomain, ctx: HtnIContext, task: HtnIPrimitiveTask, allow_immediate_replan: bool) -> void:
	var planner_state = ctx.get_planner_state()
	if null != planner_state.on_current_task_completed_successfully:
		planner_state.on_current_task_completed_successfully.call(task)

	# All effects that is a result of running this task should be applied when the task is a success.
	for effect in task.get_effects():
		if Htn.EffectType.PLAN_AND_EXECUTE == effect.get_type():
			if null != planner_state.on_apply_effect:
				planner_state.on_apply_effect.call(effect)
			effect.apply(ctx)

	planner_state.set_current_task(null)
	if planner_state.get_plan().is_empty():
		ctx.get_last_mtr().clear()

		if ctx.is_debug_mtr():
			ctx.get_last_mtr_debug().clear()

		ctx.set_dirty(false)

		if allow_immediate_replan:
			tick(domain, ctx, false)

## Ensure executing conditions are valid during plan execution
func _is_executing_conditions_valid(domain: HtnDomain, ctx: HtnIContext, task: HtnIPrimitiveTask, allow_immediate_replan: bool) -> bool:
	var on_current_task_executing_condition_failed = ctx.get_planner_state().on_current_task_executing_condition_failed
	for condition in task.get_executing_conditions():
		# If a condition failed, then the plan failed to progress! A replan is required.
		if !condition.is_valid(ctx):
			if null != on_current_task_executing_condition_failed:
				on_current_task_executing_condition_failed.call(task, condition)

			_abort_task(ctx, task)

			if allow_immediate_replan:
				tick(domain, ctx, false)

			return false

	return true

## If the operation failed to finish, we need to fail the entire plan, so that we will replan the next tick.
func _fail_entire_plan(ctx: HtnIContext, task: HtnIPrimitiveTask) -> void:
	var planner_state = ctx.get_planner_state()
	if null != planner_state.on_current_task_failed:
		planner_state.on_current_task_failed.call(task)

	task.aborted(ctx)
	_clear_plan_for_replan(ctx)

## Prepare the planner state and context for a clean replan
func _clear_plan_for_replan(ctx: HtnIContext) -> void:
	var planner_state = ctx.get_planner_state()
	planner_state.set_current_task(null)
	planner_state.get_plan().clear()

	ctx.get_last_mtr().clear()

	if ctx.is_debug_mtr():
		ctx.get_last_mtr_debug().clear()

	ctx.set_paused_partial_plan(false)
	ctx.get_partial_plan_queue().clear()
	ctx.set_dirty(false)

## If current task is null, and plan is empty, and we're not trying to replace the current plan, and decomposition failed or was rejected, then the planner failed to find a plan.
func _has_failed_to_find_plan(is_trying_to_replace_plan: bool, decomposition_status: Htn.DecompositionStatus, ctx: HtnIContext) -> bool:
	var planner_state = ctx.get_planner_state()
	var current_task = planner_state.get_current_task()
	var plan = planner_state.get_plan()
	return null == current_task and plan.is_empty() and !is_trying_to_replace_plan and\
			(Htn.DecompositionStatus.FAILED == decomposition_status or Htn.DecompositionStatus.REJECTED == decomposition_status)

#endregion

#region RESET

func reset(ctx: HtnIContext) -> void:
	var planner_state = ctx.get_planner_state()
	var current_task = planner_state.get_current_task()
	planner_state.get_plan().clear()

	if null != current_task and Htn.TaskType.PRIMITIVE == current_task.get_type():
		var task: HtnIPrimitiveTask = current_task
		task.stop(ctx)

	_clear_plan_for_replan(ctx)

#endregion
