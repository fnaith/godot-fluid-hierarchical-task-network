class_name HtnPartialPlanEntry
extends RefCounted

var task: HtnICompoundTask
var task_index: int

func _init(t: HtnICompoundTask, i: int) -> void:
	task = t
	task_index = i
