class_name TaPlayer
extends RefCounted


var _planner: HtnPlanner
var _context: TaContext

func get_context() -> TaContext:
	return _context

func _init() -> void:
	_planner = HtnPlanner.new()
	_context = TaContext.new(self)
	_context.init()

func think(domain: HtnDomain) -> void:
	var start_goal = _context.get_goal()
	var old_screen = _context.get_current_screen()
	while (_context.get_goal() == start_goal):
		_planner.tick(domain, _context)

		if _context.is_log_decomposition() and old_screen == _context.get_current_screen():
			print("---------------------- DECOMP LOG --------------------------")
			while !_context.get_decomposition_log().is_empty():
				var entry = _context.get_decomposition_log().pop_front()
				var depth = HtnDecompositionLogEntry.depth_to_string(entry.get_depth(), "        ")
				print("%s%s: %s" % [depth, entry.get_name(), entry.get_description()])
			print("-------------------------------------------------------------")
