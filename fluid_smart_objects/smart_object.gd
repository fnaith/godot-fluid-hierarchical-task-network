class_name SoSmartObject
extends RefCounted

var _name: String
var _domain: HtnDomain
var _slot: So.DomainSlots

func get_name() -> String:
	return _name

func get_domain() -> HtnDomain:
	return _domain

func get_slot() -> So.DomainSlots:
	return _slot

func _init(name: String, slot: So.DomainSlots) -> void:
	_name = name
	_slot = slot
	_domain = _build_domain()

func _build_domain() -> HtnDomain:
	return HtnDomainBuilder.new(SoContext, _name)\
		.select("Walk away")\
			.action("Walk away")\
				.condition("At location 1", func (context): return context.get_state(SoContext.WorldState.LOCATION) == 1)\
				.do(_on_arrive_at_location)\
				.effect("At location 2", Htn.EffectType.PLAN_AND_EXECUTE, func (context, type): context.set_bool_state(SoContext.WorldState.LOCATION, 2, type))\
			.end()\
		.end()\
		.build()

func _on_arrive_at_location(context: SoContext) -> Htn.TaskStatus:
	print("Arrived at location 2")
	context.get_player().unsubscribe(context.get_world().get_important_thing())
	return Htn.TaskStatus.SUCCESS
