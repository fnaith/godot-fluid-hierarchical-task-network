class_name FluidTextAdventure
extends Node

@onready var _line_text = $LineEdit

var _player: TaPlayer

func _ready() -> void:
	_player = TaPlayer.new()
	_player.get_context().set_current_screen(TaIntroScreen.new())

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("The End!")

func _on_line_edit_text_submitted(new_text: String) -> void:
	_line_text.clear()
	print(new_text)
	print()
	var screen = _player.get_context().get_current_screen()
	screen.perform_action(_player.get_context(), new_text)
