class_name HtnIDomain
extends RefCounted

func get_root() -> HtnTaskRoot:
	assert(false, "Don't use HtnIDomain.get_root")
	return null

func add_subtask(_parent: HtnICompoundTask, _subtask: HtnITask) -> void:
	assert(false, "Don't use HtnIDomain.add_subtask")

func add_slot(_parent: HtnICompoundTask, _slot: HtnSlot) -> void:
	assert(false, "Don't use HtnIDomain.add_slot")
