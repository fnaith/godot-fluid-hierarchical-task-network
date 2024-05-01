class_name HtnICompoundTask
extends HtnITask

#region checking task type

func get_type() -> Htn.TaskType:
	return Htn.TaskType.COMPOUND

#endregion

func get_subtasks() -> Array[HtnITask]:
	assert(false, "Don't use HtnICompoundTask.get_subtasks")
	return []
func add_subtask(_subtask: HtnITask) -> HtnICompoundTask:
	assert(false, "Don't use HtnICompoundTask.add_subtask")
	return null

## Decompose the task onto the tasks to process queue, mind it's depth first
func decompose(_ctx: HtnIContext, _start_index: int,\
		_result: HtnPlan) -> Htn.DecompositionStatus:
	assert(false, "Don't use HtnICompoundTask.decompose")
	return Htn.DecompositionStatus.FAILED

## The Decompose All interface is a tag to signify that this compound task type intends to
## decompose all its subtasks.
## For a task to support Pause Plan tasks, needed for partial planning, it must be
## a decompose-all compound task type.
func is_decompose_all() -> bool:
	return false
