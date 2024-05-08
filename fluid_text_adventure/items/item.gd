class_name TaItem
extends RefCounted

var _domain: HtnDomain
var _keywords_to_action: Dictionary = {}

func get_domain() -> HtnDomain:
	return _domain

func get_keywords_to_action() -> Dictionary:
	return _keywords_to_action

func get_description() -> String:
	assert(false, "Don't use TaItem.get_description")
	return ""

func _init(domain: HtnDomain) -> void:
	_domain = domain
