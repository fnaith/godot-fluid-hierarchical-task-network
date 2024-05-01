class_name HtnError
extends Object

static var _message: String = ""

static var _under_testing: bool = false
static var _reset_message_count: int = 0
static var _assert_count: int = 0

static func set_message(message: String) -> void:
	_message = message
	if !_under_testing:
		assert(false, _message)

#region for testing

static func set_under_testing(under_testing: bool) -> void:
	_under_testing = under_testing

static func reset_message() -> void:
	_message = ""
	_reset_message_count += 1

static func get_message() -> String:
	return _message

static func get_reset_message_count() -> int:
	return _reset_message_count

static func add_assert(condition: bool) -> void:
	assert(condition)
	_assert_count += 1

static func get_assert_count() -> int:
	return _assert_count

#endregion
