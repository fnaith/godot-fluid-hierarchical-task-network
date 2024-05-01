class_name HtnPlan
extends RefCounted

var _queue: Array[HtnITask] = []
var _valid: bool = true

func invalidate() -> void:
	_valid = false

func is_valid() -> bool:
	return _valid

func copy(other: HtnPlan) -> void:
	_queue = other._queue
	_valid = true

func is_empty() -> bool:
	return _queue.is_empty()

func size() -> int:
	return _queue.size()

func clear() -> void:
	_queue.clear()

func enqueue(task: HtnITask) -> void:
	_queue.append(task)

func dequeue() -> HtnITask:
	return _queue.pop_front()

func peek() -> HtnITask:
	return _queue.front()
