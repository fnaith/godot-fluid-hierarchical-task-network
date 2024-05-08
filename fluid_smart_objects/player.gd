class_name SoPlayer
extends RefCounted

var _planner: HtnPlanner
var _context: SoContext
var _domain: HtnDomain

func get_context() -> SoContext:
	return _context

func _init(world: SoWorld) -> void:
	_planner = HtnPlanner.new()
	_context = SoContext.new(self, world)
	_context.init()

	_domain = _build_domain()

func think() -> void:
	_planner.tick(_domain, _context)

	if _context.is_log_decomposition():
		print("---------------------- DECOMP LOG --------------------------")
		while !_context.get_decomposition_log().is_empty():
			var entry = _context.get_decomposition_log().pop_front()
			var depth = HtnDecompositionLogEntry.depth_to_string(entry.get_depth(), "        ")
			print("%s%s: %s" % [depth, entry.get_name(), entry.get_description()])
		print("-------------------------------------------------------------")

func subscribe(smart_object: SoSmartObject) -> void:
	_domain.try_set_slot_domain(smart_object.get_slot(), smart_object.get_domain())

func unsubscribe(smart_object: SoSmartObject) -> void:
	_domain.clear_slot(smart_object.get_slot())

func _build_domain() -> HtnDomain:
	return HtnDomainBuilder.new(SoContext, "Player")\
		.slot(So.DomainSlots.HIGH_PRIORITY)\
		.select("Walk about")\
			.action("Walk about action")\
				.condition("At location 0", func (context): return context.get_state(SoContext.WorldState.LOCATION) == 0)\
				.do(_on_arrive_at_location)\
				.effect("At location 1", Htn.EffectType.PLAN_AND_EXECUTE, func (context, type): context.set_bool_state(SoContext.WorldState.LOCATION, 1, type))\
			.end()\
		.end()\
		.select("Idle")\
			.action("Idle action")\
				.do(_on_idle)\
			.end()\
		.end()\
		.build()

func _on_arrive_at_location(context: SoContext) -> Htn.TaskStatus:
	print("Arrived at location 1")
	context.get_player().subscribe(context.get_world().get_important_thing())
	return Htn.TaskStatus.SUCCESS

func _on_idle(_ctx: SoContext) -> Htn.TaskStatus:
	print("Idle")
	return Htn.TaskStatus.CONTINUE
