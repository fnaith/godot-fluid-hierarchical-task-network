## A compound task that will pick a random sub-task to decompose.
class_name HtnRandomSelector
extends HtnSelector

#region FIELDS

var _random: RandomNumberGenerator = RandomNumberGenerator.new()

#endregion

#region DECOMPOSITION

## In a Random Selector decomposition, we simply select a sub-task randomly, and stick with it for the duration of the
## plan as if it was the only sub-task.
## So if the sub-task fail to decompose, that means the entire Selector failed to decompose (we don't try to decompose
## any other sub-tasks).
## Because of the nature of the Random Selector, we don't do any MTR tracking for it, since it doesn't do any real
## branching.
func on_decompose(ctx: HtnIContext, _start_index: int,\
		result: HtnPlan) -> Htn.DecompositionStatus:
	_plan.clear()

	var task_index = _random.randi_range(0, _subtasks.size() - 1)
	var task = _subtasks[task_index]

	return on_decompose_task(ctx, task, task_index, [], result)

#endregion
