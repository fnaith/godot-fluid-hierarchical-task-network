class_name MyOperator
extends HtnIOperator

func update(_ctx: HtnIContext) -> Htn.TaskStatus:
	return Htn.TaskStatus.CONTINUE

func stop(_ctx: HtnIContext) -> bool:
	return false

func aborted(_ctx: HtnIContext) -> bool:
	return false
