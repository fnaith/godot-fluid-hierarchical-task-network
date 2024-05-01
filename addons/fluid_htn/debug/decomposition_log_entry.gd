class_name HtnDecompositionLogEntry
extends RefCounted

var _name: String
var _description: String
var _depth: int
var _entry_type: Htn.LogEntryType
var _entry: Variant

static func depth_to_string(depth: int) -> String:
	return "        ".repeat(depth) + "- "

func _init(name: String, description: String, depth: int, entry_type: Htn.LogEntryType,\
		entry: Variant) -> void:
	_name = name
	_description = description
	_depth = depth
	_entry_type = entry_type
	_entry = entry

func get_name() -> String:
	return _name
func set_name(name: String) -> void:
	_name = name

func get_description() -> String:
	return _description
func set_description(description: String) -> void:
	_description = description

func get_depth() -> int:
	return _depth
func set_depth(depth: int) -> void:
	_depth = depth

func get_entry() -> Variant:
	return _entry
func set_entry(entry: Variant) -> void:
	_entry = entry
