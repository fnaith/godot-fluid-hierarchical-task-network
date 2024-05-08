class_name TaIntroScreen
extends TaGameScreen

func _init() -> void:
	var _set_goal = func (context: TaContext, goal: Ta.GoalState) -> TaGameScreen:
		return set_goal(context, goal)
	_items.append(TaBottle.new(_set_goal))
	_items.append(TaSword.new(_set_goal))

	super.initialize(_define_domain(_items))

	write("""You're standing in an empty room of white tapestries. There's no doors or windows here.
[Enter]

In front of you there is a little bottle on a table. Around the neck of the bottle there is a paper label, with the words 'DRINK ME' beautifully printed on it in large letters.
[Enter]

On the ground lies a rusty, old sword.
[Enter]

Now, what to do..?""")

func set_goal(context: TaContext, goal: Ta.GoalState) -> TaGameScreen:
	context.set_goal(goal)
	context.get_player().think(_domain)
	return context.get_current_screen()

func _define_domain(items_in_screen: Array[TaItem]) -> HtnDomain:
	var item_domain_builder = HtnDomainBuilder.new(TaContext, "Item Sub-domains")
	for item in items_in_screen:
		item_domain_builder.splice(item.get_domain())

	return HtnDomainBuilder.new(TaContext, "Intro Screen Domain")\
		.splice(item_domain_builder.build())\
		.action("Failed")\
			.condition("Failed to address goal", func (ctx): return !ctx.has_goal(Ta.GoalState.NONE))\
			.do(TaActions.failed)\
			.effect("Complete Goal", Htn.EffectType.PLAN_AND_EXECUTE, func (ctx, type): ctx.set_goal(Ta.GoalState.NONE, true, type))\
		.end()\
		.action("Idle")\
			.do(func (_ctx): return Htn.TaskStatus.CONTINUE)\
		.end()\
		.build()
