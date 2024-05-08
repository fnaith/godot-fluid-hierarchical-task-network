class_name FluidSmartObjects
extends Node

func _ready() -> void:
	print("At location 0")

	var world = SoWorld.new()
	var player = SoPlayer.new(world)

	player.think()
	player.think()

	print("The End!")
