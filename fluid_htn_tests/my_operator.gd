class_name MyOperator
extends HtnIOperator

func start(_ctx: HtnIContext) -> Htn.TaskStatus:
	return Htn.TaskStatus.CONTINUE

func update(_ctx: HtnIContext) -> Htn.TaskStatus:
	return Htn.TaskStatus.CONTINUE

func stop(_ctx: HtnIContext) -> bool:
	return false

func abort(_ctx: HtnIContext) -> bool:
	return false
