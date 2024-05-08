class_name SoWorld
extends RefCounted

var _important_thing: SoSmartObject

func get_important_thing() -> SoSmartObject:
	return _important_thing

func _init() -> void:
	_important_thing = SoSmartObject.new("Important thing", So.DomainSlots.HIGH_PRIORITY)
