class_name HtnBaseDomainBuilder
extends RefCounted

#region FIELDS

var _context_script: Script
var _domain: HtnDomain
var _pointers: Array[HtnITask] = []

#endregion

#region CONSTRUCTION

func _init(context_script: Script, domain_name: String):
	_context_script = context_script
	_domain = HtnDomain.new(domain_name)
	_pointers.append(_domain.get_root())

#endregion

#region PROPERTIES

func get_pointer() -> HtnITask:
	if _pointers.is_empty():
		return null

	return _pointers.back()

#endregion

#region HIERARCHY HANDLING

## Compound tasks are where HTN get their “hierarchical” nature. You can think of a compound task as
## a high level task that has multiple ways of being accomplished. There are primarily two types of
## compound tasks. Selectors and Sequencers. A Selector must be able to decompose a single sub-task,
## while a Sequence must be able to decompose all its sub-tasks successfully for itself to have decomposed
## successfully. There is nothing stopping you from extending this toolset with RandomSelect, UtilitySelect,
## etc. These tasks are decomposed until we're left with only Primitive Tasks, which represent a final plan.
## Compound tasks are comprised of a set of subtasks and a set of conditions.
## http://www.gameaipro.com/GameAIPro/GameAIPro_Chapter12_Exploring_HTN_Planners_through_Example.pdf
func compound_task(compound_task_script: Script, name: String) -> HtnDomainBuilder:
	var parent = compound_task_script.new()
	return add_subtask(name, parent)

## Compound tasks are where HTN get their “hierarchical” nature. You can think of a compound task as
## a high level task that has multiple ways of being accomplished. There are primarily two types of
## compound tasks. Selectors and Sequencers. A Selector must be able to decompose a single sub-task,
## while a Sequence must be able to decompose all its sub-tasks successfully for itself to have decomposed
## successfully. There is nothing stopping you from extending this toolset with RandomSelect, UtilitySelect,
## etc. These tasks are decomposed until we're left with only Primitive Tasks, which represent a final plan.
## Compound tasks are comprised of a set of subtasks and a set of conditions.
## http://www.gameaipro.com/GameAIPro/GameAIPro_Chapter12_Exploring_HTN_Planners_through_Example.pdf
func add_subtask(name: String, task: HtnICompoundTask) -> HtnDomainBuilder:
	if null != task:
		var pointer = get_pointer()
		if Htn.TaskType.COMPOUND == pointer.get_type():
			var compound_task: HtnICompoundTask = pointer
			task.set_name(name)
			_domain.add_subtask(compound_task, task)
			_pointers.append(task)
		else:
			HtnError.set_message("Pointer is not a compound task type. Did you forget an End() after a Primitive Task Action was defined?")
			return null
	else:
		HtnError.set_message("task")
		return null

	return self

## Primitive tasks represent a single step that can be performed by our AI. A set of primitive tasks is
## the plan that we are ultimately getting out of the HTN. Primitive tasks are comprised of an operator,
## a set of effects, a set of conditions and a set of executing conditions.
## http://www.gameaipro.com/GameAIPro/GameAIPro_Chapter12_Exploring_HTN_Planners_through_Example.pdf
func primitive_task(primitive_task_script: Script, name: String) -> HtnDomainBuilder:
	var pointer = get_pointer()
	if Htn.TaskType.COMPOUND == pointer.get_type():
		var compound_task: HtnICompoundTask = pointer
		var parent = primitive_task_script.new(name)
		_domain.add_subtask(compound_task, parent)
		_pointers.append(parent)
	else:
		HtnError.set_message("Pointer is not a compound task type. Did you forget an End() after a Primitive Task Action was defined?")
		return null

	return self

## Partial planning is one of the most powerful features of HTN. In simplest terms, it allows
## the planner the ability to not fully decompose a complete plan. HTN is able to do this because
## it uses forward decomposition or forward search to find plans. That is, the planner starts with
## the current world state and plans forward in time from that. This allows the planner to only
## plan ahead a few steps.
## http://www.gameaipro.com/GameAIPro/GameAIPro_Chapter12_Exploring_HTN_Planners_through_Example.pdf
func pause_plan_task() -> HtnDomainBuilder:
	var pointer = get_pointer()
	if Htn.TaskType.COMPOUND == pointer.get_type() and pointer.is_decompose_all():
		var compound_task: HtnICompoundTask = pointer
		var parent = HtnPausePlanTask.new("Pause Plan")
		_domain.add_subtask(compound_task, parent)
	else:
		HtnError.set_message("Pointer is not a decompose-all compound task type, like a Sequence. Maybe you tried to Pause Plan a Selector, or forget an End() after a Primitive Task Action was defined?")
		return null

	return self
#endregion

#region COMPOUND TASKS

## A compound task that requires all sub-tasks to be valid.
## Sub-tasks can be sequences, selectors or actions.
func sequence(name: String) -> HtnDomainBuilder:
	return compound_task(HtnSequence, name)

## A compound task that requires a single sub-task to be valid.
## Sub-tasks can be sequences, selectors or actions.
func select(name: String) -> HtnDomainBuilder:
	return compound_task(HtnSelector, name)

#endregion

#region PRIMITIVE TASKS

## A primitive task that can contain conditions, an operator and effects.
func action(name: String) -> HtnDomainBuilder:
	return primitive_task(HtnPrimitiveTask, name)

#endregion

#region CONDITIONS

## A precondition is a boolean statement required for the parent task to validate.
func condition(name: String, condition: Callable) -> HtnDomainBuilder:
	var cond = HtnFuncCondition.new(_context_script, name, condition)
	get_pointer().add_condition(cond)

	return self

## An executing condition is a boolean statement validated before every call to the current
## primitive task's operator update tick. It's only supported inside primitive tasks / Actions.
## Note that this condition is never validated during planning, only during execution.
func executing_condition(name: String, condition: Callable) -> HtnDomainBuilder:
	var pointer = get_pointer()
	if Htn.TaskType.PRIMITIVE == pointer.get_type():
		var task: HtnIPrimitiveTask = pointer
		var cond = HtnFuncCondition.new(_context_script, name, condition)
		task.add_executing_condition(cond)
	else:
		HtnError.set_message("Tried to add an Executing Condition, but the Pointer is not a Primitive Task!")
		return null

	return self

#endregion

#region OPERATORS

## The operator of an Action / primitive task.
func do(action, force_stop_action = null) -> HtnDomainBuilder:
	var pointer = get_pointer()
	if Htn.TaskType.PRIMITIVE == pointer.get_type():
		var task: HtnIPrimitiveTask = pointer
		var op = HtnFuncOperator.new(_context_script, action, force_stop_action)
		task.set_operator(op)
	else:
		HtnError.set_message("Tried to add an Operator, but the Pointer is not a Primitive Task!")
		return null

	return self

#endregion

#region EFFECTS

## Effects can be added to an Action / primitive task.
func effect(name: String, effect_type: Htn.EffectType, action: Callable) -> HtnDomainBuilder:
	var pointer = get_pointer()
	if Htn.TaskType.PRIMITIVE == pointer.get_type():
		var task: HtnIPrimitiveTask = pointer
		var effect = HtnActionEffect.new(_context_script, name, effect_type, action)
		task.add_effect(effect)
	else:
		HtnError.set_message("Tried to add an Effect, but the Pointer is not a Primitive Task!")
		return null

	return self

#endregion

#region OTHER OPERANDS

## Every task encapsulation must end with a call to End(), otherwise subsequent calls will be applied wrong.
func end() -> HtnDomainBuilder:
	_pointers.pop_back()
	return self

## We can splice multiple domains together, allowing us to define reusable sub-domains.
func splice(domain: HtnDomain) -> HtnDomainBuilder:
	var pointer = get_pointer()
	if Htn.TaskType.COMPOUND == pointer.get_type():
		var compound_task: HtnICompoundTask = pointer
		_domain.add_subtask(compound_task, domain.get_root())
	else:
		HtnError.set_message("Pointer is not a compound task type. Did you forget an End()?")
		return null

	return self

## The identifier associated with a slot can be used to splice
## sub-domains onto the domain, and remove them, at runtime.
## Use TrySetSlotDomain and ClearSlot on the domain instance at
## runtime to manage this feature. SlotId can typically be implemented
## as an enum.
func slot(slot_id: int) -> HtnDomainBuilder:
	var pointer = get_pointer()
	if Htn.TaskType.COMPOUND == pointer.get_type():
		var compound_task: HtnICompoundTask = pointer
		var slot = HtnSlot.new(slot_id, "Slot %d" % slot_id)
		_domain.add_slot(compound_task, slot)
	else:
		HtnError.set_message("Pointer is not a compound task type. Did you forget an End()?")
		return null

	return self

## We can add a Pause Plan when in a sequence in our domain definition,
## and this will give us partial planning.
## It means that we can tell our planner to only plan up to a certain point,
## then stop. If the partial plan completes execution successfully, the next
## time we try to find a plan, we will continue planning where we left off.
## Typical use cases is to split after we navigate toward a location, since
## this is often time consuming, it's hard to predict the world state when
## we have reached the destination, and thus there's little point wasting
## milliseconds on planning further into the future at that point. We might
## still want to plan what to do when reaching the destination, however, and
## this is where partial plans come into play.
func pause_plan() -> HtnDomainBuilder:
	return pause_plan_task()

## Build the designed domain and return a domain instance.
func build() -> HtnDomain:
	var pointer = get_pointer()
	if pointer != _domain.get_root():
		HtnError.set_message("The domain definition lacks one or more End() statements. Pointer is '%s', but expected '%s'." % [pointer.get_name(), _domain.get_root().get_name()])
		return null

	_pointers.clear()

	return _domain

#endregion
