class_name HtnIOperator
extends RefCounted

func start(_ctx: HtnIContext) -> Htn.TaskStatus:
	assert(false, "Don't use HtnIOperator.start")
	return Htn.TaskStatus.SUCCESS

func update(_ctx: HtnIContext) -> Htn.TaskStatus:
	assert(false, "Don't use HtnIOperator.update")
	return Htn.TaskStatus.SUCCESS

## Graceful end of task execution.
func stop(_ctx: HtnIContext) -> bool:
	assert(false, "Don't use HtnIOperator.stop")
	return false

## Forced termination of task execution.
func abort(_ctx: HtnIContext) -> bool:
	assert(false, "Don't use HtnIOperator.abort")
	return false
