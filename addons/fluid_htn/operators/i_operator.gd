class_name HtnIOperator
extends RefCounted

func update(_ctx: HtnIContext) -> Htn.TaskStatus:
	assert(false, "Don't use HtnIOperator.update")
	return Htn.TaskStatus.SUCCESS

func stop(_ctx: HtnIContext) -> bool:
	assert(false, "Don't use HtnIOperator.stop")
	return false

func aborted(_ctx: HtnIContext) -> bool:
	assert(false, "Don't use HtnIOperator.aborted")
	return false
