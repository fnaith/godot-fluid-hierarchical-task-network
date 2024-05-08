class_name TaBottle
extends TaItem

func _init(set_goal: Callable) -> void:
	super._init(_define_domain())
	_keywords_to_action[["get", "bottle"]] = func (ctx) -> TaGameScreen:
		return set_goal.call(ctx, Ta.GoalState.GET_BOTTLE)
	_keywords_to_action[["open", "bottle"]] = func (ctx) -> TaGameScreen:
		return set_goal.call(ctx, Ta.GoalState.OPEN_BOTTLE)
	_keywords_to_action[["drink", "bottle"]] = func (ctx) -> TaGameScreen:
		return set_goal.call(ctx, Ta.GoalState.DRINK_BOTTLE)
	_keywords_to_action[["break", "bottle"]] = func (ctx) -> TaGameScreen:
		return set_goal.call(ctx, Ta.GoalState.BREAK_BOTTLE)
	_keywords_to_action[["throw", "bottle"]] = func (ctx) -> TaGameScreen:
		return set_goal.call(ctx, Ta.GoalState.THROW_BOTTLE)
	_keywords_to_action[["slash", "bottle"]] = func (ctx) -> TaGameScreen:
		return set_goal.call(ctx, Ta.GoalState.SLASH_BOTTLE)
	_keywords_to_action[["drop", "bottle"]] = func (ctx) -> TaGameScreen:
		return set_goal.call(ctx, Ta.GoalState.DROP_BOTTLE)

func get_description() -> String:
	return "In front of you there is a little bottle on a table. Around the neck of the bottle there is a paper label, with the words 'DRINK ME' beautifully printed on it in large letters."

func _define_domain() -> HtnDomain:
	var get_bottle_domain = HtnDomainBuilder.new(TaContext, "Get Bottle Sub-domain")\
		.select("Get Bottle")\
			.condition("GOAL: Get Bottle", func (ctx): return ctx.has_goal(Ta.GoalState.GET_BOTTLE))\
			.action("Get Bottle")\
				.condition("Has NOT Bottle", func (ctx): return ctx.has_bool_state(TaContext.WorldState.HAS_BOTTLE, false))\
				.do(TaActions.get_bottle)\
				.effect("Has Bottle", Htn.EffectType.PLAN_AND_EXECUTE, func (ctx, type): ctx.set_bool_state(TaContext.WorldState.HAS_BOTTLE, true, type))\
				.effect("Try Complete Goal", Htn.EffectType.PLAN_AND_EXECUTE, func (ctx, type): TaActions.try_complete_goal(ctx, Ta.GoalState.GET_BOTTLE, type))\
			.end()\
		.end()\
		.build()

	var drop_bottle_domain = HtnDomainBuilder.new(TaContext, "Drop Bottle Sub-domain")\
		.select("Drop Bottle")\
			.condition("GOAL: Drop Bottle", func (ctx): return ctx.has_goal(Ta.GoalState.DROP_BOTTLE))\
			.action("Drop Bottle")\
				.condition("Has Bottle", func (ctx): return ctx.has_bool_state(TaContext.WorldState.HAS_BOTTLE))\
				.do(TaActions.drop_bottle)\
				.effect("Has NOT Bottle", Htn.EffectType.PLAN_AND_EXECUTE, func (ctx, type): ctx.set_bool_state(TaContext.WorldState.HAS_BOTTLE, false, type))\
				.effect("Try Complete Goal", Htn.EffectType.PLAN_AND_EXECUTE, func (ctx, type): TaActions.try_complete_goal(ctx, Ta.GoalState.DROP_BOTTLE, type))\
			.end()\
		.end()\
		.build()

	var open_bottle_action_domain = HtnDomainBuilder.new(TaContext, "Open Bottle Action Sub-domain")\
		.action("Open Bottle")\
			.condition("Has Bottle", func (ctx): return ctx.has_bool_state(TaContext.WorldState.HAS_BOTTLE))\
			.condition("Bottle is NOT Open", func (ctx): return ctx.has_bool_state(TaContext.WorldState.BOTTLE_IS_OPEN, false))\
			.do(TaActions.open_bottle)\
			.effect("Open Bottle", Htn.EffectType.PLAN_AND_EXECUTE, func (ctx, type): ctx.set_bool_state(TaContext.WorldState.BOTTLE_IS_OPEN, true, type))\
			.effect("Try Complete Goal", Htn.EffectType.PLAN_AND_EXECUTE, func (ctx, type): TaActions.try_complete_goal(ctx, Ta.GoalState.OPEN_BOTTLE, type))\
		.end()\
		.build()

	var open_bottle_domain = HtnDomainBuilder.new(TaContext, "Open Bottle Sub-domain")\
		.select("Open Bottle")\
			.condition("GOAL: Open Bottle", func (ctx): return ctx.has_goal(Ta.GoalState.OPEN_BOTTLE))\
			.select("Already Has Bottle?")\
				.splice(open_bottle_action_domain)\
				.sequence("Get bottle and open it")\
					.action("Temporary change goal")\
						.effect("Get Bottle Goal", Htn.EffectType.PLAN_ONLY, func (ctx, type): TaActions.change_goal(ctx, type, Ta.GoalState.GET_BOTTLE))\
					.end()\
					.splice(get_bottle_domain)\
					.action("Temporary change goal")\
						.effect("Open Bottle Goal", Htn.EffectType.PLAN_ONLY, func (ctx, type): TaActions.change_goal(ctx, type, Ta.GoalState.OPEN_BOTTLE))\
					.end()\
					.splice(open_bottle_action_domain)\
				.end()\
			.end()\
		.end()\
		.build()

	var drink_bottle_action_domain = HtnDomainBuilder.new(TaContext, "Drink Bottle Action Sub-domain")\
		.action("Drink Bottle")\
			.condition("Has Bottle", func (ctx): return ctx.has_bool_state(TaContext.WorldState.HAS_BOTTLE))\
			.condition("Bottle is Open", func (ctx): return ctx.has_bool_state(TaContext.WorldState.BOTTLE_IS_OPEN))\
			.condition("Bottle is NOT Empty", func (ctx): return ctx.has_bool_state(TaContext.WorldState.BOTTLE_IS_EMPTY, false))\
			.do(TaActions.sip_bottle)\
			.effect("Drink Bottle", Htn.EffectType.PLAN_AND_EXECUTE, func (ctx, type): ctx.set_bool_state(TaContext.WorldState.BOTTLE_IS_EMPTY, true, type))\
			.effect("Try Complete Goal", Htn.EffectType.PLAN_AND_EXECUTE, func (ctx, type): TaActions.try_complete_goal(ctx, Ta.GoalState.DRINK_BOTTLE, type))\
		.end()\
		.build()

	var drink_bottle_domain = HtnDomainBuilder.new(TaContext, "Drink Bottle Sub-domain")\
		.select("Drink Bottle")\
			.condition("GOAL: Drink Bottle", func (ctx): return ctx.has_goal(Ta.GoalState.DRINK_BOTTLE))\
			.select("Already Has Opened Bottle?")\
				.splice(drink_bottle_action_domain)\
				.sequence("Get bottle, open it, then drink it!")\
					.action("Temporary change goal")\
						.effect("Open Bottle Goal", Htn.EffectType.PLAN_ONLY, func (ctx, type): TaActions.change_goal(ctx, type, Ta.GoalState.OPEN_BOTTLE))\
					.end()\
					.splice(open_bottle_domain)\
					.action("Temporary change goal")\
						.effect("Drink Bottle Goal", Htn.EffectType.PLAN_ONLY, func (ctx, type): TaActions.change_goal(ctx, type, Ta.GoalState.DRINK_BOTTLE))\
					.end()\
					.splice(drink_bottle_action_domain)\
				.end()\
			.end()\
		.end()\
		.build()

	var throw_bottle_domain = HtnDomainBuilder.new(TaContext, "Throw Bottle Sub-domain")\
		.action("Throw the bottle")\
			.condition("Has Bottle", func (ctx): return ctx.has_bool_state(TaContext.WorldState.HAS_BOTTLE))\
			.do(TaActions.throw_full_bottle)\
			.effect("Break Bottle", Htn.EffectType.PLAN_AND_EXECUTE, func (ctx, type): ctx.set_bool_state(TaContext.WorldState.BOTTLE_IS_BROKEN, true, type))\
			.effect("Complete Goal", Htn.EffectType.PLAN_AND_EXECUTE, func (ctx, type): return ctx.set_goal(Ta.GoalState.NONE, true, type))\
		.end()\
		.build()

	var cut_bottle_domain = HtnDomainBuilder.new(TaContext, "Cut Bottle Sub-domain")\
		.action("Cut the bottle?")\
			.condition("Has NOT Bottle", func (ctx): return ctx.has_bool_state(TaContext.WorldState.HAS_BOTTLE, false))\
			.condition("Has Weapon", func (ctx): return ctx.has_bool_state(TaContext.WorldState.HAS_WEAPON))\
			.do(TaActions.slash_bottle)\
			.effect("Break Bottle", Htn.EffectType.PLAN_AND_EXECUTE, func (ctx, type): ctx.set_bool_state(TaContext.WorldState.BOTTLE_IS_BROKEN, true, type))\
			.effect("Complete Goal", Htn.EffectType.PLAN_AND_EXECUTE, func (ctx, type): return ctx.set_goal(Ta.GoalState.NONE, true, type))\
		.end()\
		.build()

	var break_bottle_domain = HtnDomainBuilder.new(TaContext, "Break Bottle Sub-domain")\
		.select("Break Bottle")\
			.condition("GOAL: Break Bottle", func (ctx): return ctx.has_goal(Ta.GoalState.BREAK_BOTTLE))\
			.condition("Bottle NOT already broken", func (ctx): return ctx.has_bool_state(TaContext.WorldState.BOTTLE_IS_BROKEN, false))\
			.splice(throw_bottle_domain)\
			.splice(cut_bottle_domain)\
			.compound_task(HtnRandomSelector, "Select random")\
				.sequence("Get bottle and throw it")\
					.action("Temporary change goal")\
						.effect("Get Bottle Goal", Htn.EffectType.PLAN_ONLY, func (ctx, type): TaActions.change_goal(ctx, type, Ta.GoalState.GET_BOTTLE))\
					.end()\
					.splice(get_bottle_domain)\
					.action("Temporary change goal")\
						.effect("Break Bottle Goal", Htn.EffectType.PLAN_ONLY, func (ctx, type): TaActions.change_goal(ctx, type, Ta.GoalState.BREAK_BOTTLE))\
					.end()\
					.splice(throw_bottle_domain)\
				.end()\
				.sequence("Get sword and cut bottle")\
					.action("Get Sword")\
						.condition("Has NOT Weapon", func (ctx): return ctx.has_bool_state(TaContext.WorldState.HAS_WEAPON, false))\
						.do(TaActions.get_sword)\
						.effect("Has Weapon", Htn.EffectType.PLAN_AND_EXECUTE, func (ctx, type): ctx.set_bool_state(TaContext.WorldState.HAS_WEAPON, true, type))\
					.end()\
					.splice(cut_bottle_domain)\
				.end()\
			.end()\
		.end()\
		.select("Throw Bottle")\
			.condition("GOAL: Throw Bottle", func (ctx): return ctx.has_goal(Ta.GoalState.THROW_BOTTLE))\
			.condition("Bottle NOT already broken", func (ctx): return ctx.has_bool_state(TaContext.WorldState.BOTTLE_IS_BROKEN, false))\
			.splice(throw_bottle_domain)\
			.sequence("Get bottle and throw it")\
				.action("Temporary change goal")\
					.effect("Get Bottle Goal", Htn.EffectType.PLAN_ONLY, func (ctx, type): TaActions.change_goal(ctx, type, Ta.GoalState.GET_BOTTLE))\
				.end()\
				.splice(get_bottle_domain)\
				.action("Temporary change goal")\
					.effect("Throw Bottle Goal", Htn.EffectType.PLAN_ONLY, func (ctx, type): TaActions.change_goal(ctx, type, Ta.GoalState.THROW_BOTTLE))\
				.end()\
				.splice(throw_bottle_domain)\
			.end()\
		.end()\
		.select("Slash Bottle")\
			.condition("GOAL: Slash Bottle", func (ctx): return ctx.has_goal(Ta.GoalState.SLASH_BOTTLE))\
			.condition("Bottle NOT already broken", func (ctx): return ctx.has_bool_state(TaContext.WorldState.BOTTLE_IS_BROKEN, false))\
			.splice(cut_bottle_domain)\
			.sequence("Get sword and cut bottle")\
				.action("Get Sword")\
					.condition("Has NOT Weapon", func (ctx): return ctx.has_bool_state(TaContext.WorldState.HAS_WEAPON, false))\
					.do(TaActions.get_sword)\
					.effect("Has Weapon", Htn.EffectType.PLAN_AND_EXECUTE, func (ctx, type): ctx.set_bool_state(TaContext.WorldState.HAS_WEAPON, true, type))\
				.end()\
				.splice(cut_bottle_domain)\
			.end()\
			.sequence("Set down bottle and slash it")\
				.action("Drop bottle")\
					.condition("Has Bottle", func (ctx): return ctx.has_bool_state(TaContext.WorldState.HAS_BOTTLE))\
					.do(TaActions.drop_bottle)\
					.effect("Has NOT Bottle", Htn.EffectType.PLAN_AND_EXECUTE, func (ctx, type): ctx.set_bool_state(TaContext.WorldState.HAS_BOTTLE, false, type))\
				.end()\
				.splice(cut_bottle_domain)\
			.end()\
		.end()\
		.build()

	return HtnDomainBuilder.new(TaContext, "Bottle sub-domain")\
		.action("Bottle is broken")\
		.condition("GOAL: * Bottle", func (ctx): return ctx.get_goal() > Ta.GoalState.NONE and ctx.get_goal() <= Ta.GoalState.THROW_BOTTLE)\
			.condition("Bottle is broken", func (ctx): return ctx.has_bool_state(TaContext.WorldState.BOTTLE_IS_BROKEN))\
			.do(func (ctx): return TaActions.write(ctx, "But the bottle lies shattered on the ground!"))\
			.effect("Complete Goal", Htn.EffectType.PLAN_AND_EXECUTE, func (ctx, type): return ctx.set_goal(Ta.GoalState.NONE, true, type))\
		.end()\
		.splice(get_bottle_domain)\
		.splice(open_bottle_domain)\
		.splice(drink_bottle_domain)\
		.splice(break_bottle_domain)\
		.splice(drop_bottle_domain)\
		.action("Already has bottle")\
			.condition("GOAL: Get Bottle", func (ctx): return ctx.has_goal(Ta.GoalState.GET_BOTTLE))\
			.condition("Has Bottle", func (ctx): return ctx.has_bool_state(TaContext.WorldState.HAS_BOTTLE))\
			.do(func (ctx): return TaActions.write(ctx, "But you already hold the bottle!"))\
			.effect("Complete Goal", Htn.EffectType.PLAN_AND_EXECUTE, func (ctx, type): return ctx.set_goal(Ta.GoalState.NONE, true, type))\
		.end()\
		.action("Already opened bottle")\
			.condition("GOAL: Open Bottle", func (ctx): return ctx.has_goal(Ta.GoalState.OPEN_BOTTLE))\
			.condition("Bottle is open", func (ctx): return ctx.has_bool_state(TaContext.WorldState.BOTTLE_IS_OPEN))\
				.do(func (ctx): return TaActions.write(ctx, "But you already opened the bottle!"))\
			.effect("Complete Goal", Htn.EffectType.PLAN_AND_EXECUTE, func (ctx, type): return ctx.set_goal(Ta.GoalState.NONE, true, type))\
		.end()\
		.action("Already emptied bottle")\
			.condition("GOAL: Drink Bottle", func (ctx): return ctx.has_goal(Ta.GoalState.DRINK_BOTTLE))\
			.condition("Bottle is empty", func (ctx): return ctx.has_bool_state(TaContext.WorldState.BOTTLE_IS_EMPTY))\
				.do(func (ctx): return TaActions.write(ctx, "But the bottle is empty!"))\
			.effect("Complete Goal", Htn.EffectType.PLAN_AND_EXECUTE, func (ctx, type): return ctx.set_goal(Ta.GoalState.NONE, true, type))\
		.end()\
		.action("Not holding bottle to drop")\
			.condition("GOAL: Drop Bottle", func (ctx): return ctx.has_goal(Ta.GoalState.DROP_BOTTLE))\
			.condition("Has NOT Bottle", func (ctx): return ctx.has_bool_state(TaContext.WorldState.HAS_BOTTLE, false))\
				.do(func (ctx): return TaActions.write(ctx, "But you're not holding the bottle!"))\
			.effect("Complete Goal", Htn.EffectType.PLAN_AND_EXECUTE, func (ctx, type): return ctx.set_goal(Ta.GoalState.NONE, true, type))\
		.end()\
		.build()
