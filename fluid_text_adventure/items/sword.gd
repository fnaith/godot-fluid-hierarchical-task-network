class_name TaSword
extends TaItem

func _init(set_goal: Callable) -> void:
	super._init(_define_domain())
	_keywords_to_action[["get", "sword"]] = func (ctx) -> TaGameScreen:
		return set_goal.call(ctx, Ta.GoalState.GET_SWORD)
	_keywords_to_action[["slash", "sword"]] = func (ctx) -> TaGameScreen:
		return set_goal.call(ctx, Ta.GoalState.SLASH_AIR)
	_keywords_to_action[["slash"]] = func (ctx) -> TaGameScreen:
		return set_goal.call(ctx, Ta.GoalState.SLASH_AIR)
	_keywords_to_action[["drop", "sword"]] = func (ctx) -> TaGameScreen:
		return set_goal.call(ctx, Ta.GoalState.DROP_SWORD)

func get_description() -> String:
	return "On the ground lies a rusty, old sword."

func _define_domain() -> HtnDomain:
	var get_sword_domain = HtnDomainBuilder.new(TaContext, "Get Sword Sub-domain")\
		.select("Get Sword")\
			.condition("GOAL: Get Sword", func (ctx): return ctx.has_goal(Ta.GoalState.GET_SWORD))\
			.action("Get Sword")\
				.condition("Has NOT Weapon", func (ctx): return ctx.has_bool_state(TaContext.WorldState.HAS_WEAPON, false))\
				.do(TaActions.get_sword)\
				.effect("Has Weapon", Htn.EffectType.PLAN_AND_EXECUTE, func (ctx, type): ctx.set_bool_state(TaContext.WorldState.HAS_WEAPON, true, type))\
				.effect("Try Complete Goal", Htn.EffectType.PLAN_AND_EXECUTE, func (ctx, type): TaActions.try_complete_goal(ctx, Ta.GoalState.GET_SWORD, type))\
			.end()\
		.end()\
		.build()
		
	var drop_sword_domain = HtnDomainBuilder.new(TaContext, "Drop Sword Sub-domain")\
		.select("Drop Sword")\
			.condition("GOAL: Drop Sword", func (ctx): return ctx.has_goal(Ta.GoalState.DROP_SWORD))\
			.action("Drop Sword")\
				.condition("Has Weapon", func (ctx): return ctx.has_bool_state(TaContext.WorldState.HAS_WEAPON))\
				.do(TaActions.drop_sword)\
				.effect("Has NOT Weapon", Htn.EffectType.PLAN_AND_EXECUTE, func (ctx, type): ctx.set_bool_state(TaContext.WorldState.HAS_WEAPON, false, type))\
				.effect("Try Complete Goal", Htn.EffectType.PLAN_AND_EXECUTE, func (ctx, type): TaActions.try_complete_goal(ctx, Ta.GoalState.DROP_SWORD, type))\
			.end()\
		.end()\
		.build()

	var slash_air_action_domain = HtnDomainBuilder.new(TaContext, "Slash Air Action Sub-domain")\
		.action("Slash Air")\
			.condition("GOAL: Slash Air", func (ctx): return ctx.has_goal(Ta.GoalState.SLASH_AIR))\
			.condition("Has Weapon", func (ctx): return ctx.has_bool_state(TaContext.WorldState.HAS_WEAPON))\
			.do(func (ctx): return TaActions.write(ctx, "You slash your sword through the air elegantly!"))\
			.effect("Try Complete Goal", Htn.EffectType.PLAN_AND_EXECUTE, func (ctx, type): TaActions.try_complete_goal(ctx, Ta.GoalState.SLASH_AIR, type))\
		.end()\
		.build()

	return HtnDomainBuilder.new(TaContext, "Sword sub-domain")\
		.splice(get_sword_domain)\
		.splice(drop_sword_domain)\
		.action("Already has sword")\
			.condition("GOAL: Get Sword", func (ctx): return ctx.has_goal(Ta.GoalState.GET_SWORD))\
			.condition("Has Weapon", func (ctx): return ctx.has_goal(TaContext.WorldState.HAS_WEAPON))\
			.do(func (ctx): return TaActions.write(ctx, "But you're already wielding the sword!"))\
			.effect("Complete Goal", Htn.EffectType.PLAN_AND_EXECUTE, func (ctx, type): return ctx.set_goal(Ta.GoalState.NONE, true, type))\
		.end()\
		.action("Not holding sword to drop")\
			.condition("GOAL: Drop Sword", func (ctx): return ctx.has_goal(Ta.GoalState.DROP_SWORD))\
			.condition("Has NOT Weapon", func (ctx): return !ctx.has_goal(TaContext.WorldState.HAS_WEAPON))\
			.do(func (ctx): return TaActions.write(ctx, "But you're not holding a sword!"))\
			.effect("Complete Goal", Htn.EffectType.PLAN_AND_EXECUTE, func (ctx, type): return ctx.set_goal(Ta.GoalState.NONE, true, type))\
		.end()\
		.select("Slash")\
			.condition("GOAL: Slash Air", func (ctx): return ctx.has_goal(Ta.GoalState.SLASH_AIR))\
			.splice(slash_air_action_domain)\
			.sequence("Pick up sword, then slash with it")\
				.action("Temporary change goal")\
					.effect("Get Sword Goal", Htn.EffectType.PLAN_ONLY, func (ctx, type): TaActions.change_goal(ctx, type, Ta.GoalState.GET_SWORD))\
				.end()\
				.splice(get_sword_domain)\
				.action("Temporary change goal")\
					.effect("Slash Air Goal", Htn.EffectType.PLAN_ONLY, func (ctx, type): TaActions.change_goal(ctx, type, Ta.GoalState.SLASH_AIR))\
				.end()\
				.splice(slash_air_action_domain)\
			.end()\
		.end()\
		.build()
