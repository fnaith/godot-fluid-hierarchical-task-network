class_name TaActions
extends Object

static var get_bottle: Callable = func (context: TaContext) -> Htn.TaskStatus:
	context.get_current_screen().write("You pick up the bottle")
	return Htn.TaskStatus.SUCCESS

static var drop_bottle: Callable = func (context: TaContext) -> Htn.TaskStatus:
	context.get_current_screen().write("You drop the bottle")
	return Htn.TaskStatus.SUCCESS

static var open_bottle: Callable = func (context: TaContext) -> Htn.TaskStatus:
	context.get_current_screen().write("You unscrew the cork of the bottle")
	return Htn.TaskStatus.SUCCESS

static var sip_bottle: Callable = func (context: TaContext) -> Htn.TaskStatus:
	context.get_current_screen().write("You take a sip from the bottle")
	context.get_current_screen().write("As the liquid runs down your throat and fills your belly, something weird starts happening. Your vision blur!")
	context.get_current_screen().write("[Enter]")
	context.set_current_screen(TaEnlightenedScreen.new())
	return Htn.TaskStatus.SUCCESS

static var throw_full_bottle: Callable = func (context: TaContext) -> Htn.TaskStatus:
	context.get_current_screen().write("You throw the bottle at the wall, it shatters!")
	context.get_current_screen().write("The liquid splashes all over the place, even on you!")
	context.get_current_screen().write("[Enter]")
	context.set_current_screen(TaEnlightenedScreen.new())
	return Htn.TaskStatus.SUCCESS

static var slash_bottle: Callable = func (context: TaContext) -> Htn.TaskStatus:
	context.get_current_screen().write("You swing your sword furiously at the bottle, it shatters!")
	context.get_current_screen().write("The liquid splashes all over the place, even on you!")
	context.get_current_screen().write("[Enter]")
	context.set_current_screen(TaEnlightenedScreen.new())
	return Htn.TaskStatus.SUCCESS

static var sip_empty_bottle: Callable = func (context: TaContext) -> Htn.TaskStatus:
	context.get_current_screen().write("The bottle is empty")
	return Htn.TaskStatus.SUCCESS

static var get_sword: Callable = func (context: TaContext) -> Htn.TaskStatus:
	context.get_current_screen().write("You pick up the sword")
	return Htn.TaskStatus.SUCCESS

static var drop_sword: Callable = func (context: TaContext) -> Htn.TaskStatus:
	context.get_current_screen().write("You drop the sword")
	return Htn.TaskStatus.SUCCESS

static func write(context: TaContext, text: String) -> Htn.TaskStatus:
	context.get_current_screen().write(text)
	return Htn.TaskStatus.SUCCESS

static func failed(context: TaContext) -> Htn.TaskStatus:
	context.get_current_screen().write("Sorry, I don't know how to do that yet!")
	return Htn.TaskStatus.SUCCESS

static func try_complete_goal(context: TaContext, end_of_goal: Ta.GoalState, type: Htn.EffectType) -> void:
	if context.has_goal(end_of_goal):
		context.set_goal(Ta.GoalState.NONE, true, type)

static func change_goal(context: TaContext, type: Htn.EffectType, goal: Ta.GoalState) -> void:
	context.set_goal(goal, true, type)
