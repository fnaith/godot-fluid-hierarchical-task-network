class_name HtnDomainBuilderTests
extends Object

static func build__forgot_end() -> void:
	# Arrange
	var builder = HtnDomainBuilder.new(MyContext, "Test")

	# Act
	var ptr = builder.get_pointer()
	var domain = builder.build()

	HtnError.add_assert(null != domain.get_root())
	HtnError.add_assert(ptr == domain.get_root())
	HtnError.add_assert("Test" == domain.get_root().get_name())
	HtnError.add_assert("" == HtnError.get_message())

static func build_invalidates_pointer__forgot_end() -> void:
	# Arrange
	var builder = HtnDomainBuilder.new(MyContext, "Test")

	# Act
	builder.build()

	HtnError.add_assert(null == builder.get_pointer())

static func selector__expected_behavior() -> void:
	# Arrange
	var builder = HtnDomainBuilder.new(MyContext, "Test")

	# Act
	builder.select("select test")
	builder.end()

	# Assert
	HtnError.add_assert(builder.get_pointer() is HtnTaskRoot)
	HtnError.add_assert("" == HtnError.get_message())

static func selector__forgot_end() -> void:
	# Arrange
	var builder = HtnDomainBuilder.new(MyContext, "Test")

	# Act
	builder.select("select test")

	# Assert
	HtnError.add_assert(!builder.get_pointer() is HtnTaskRoot)
	HtnError.add_assert(builder.get_pointer() is HtnSelector)
	HtnError.add_assert("" == HtnError.get_message())

static func selector_build__forgot_end() -> void:
	# Arrange
	var builder = HtnDomainBuilder.new(MyContext, "Test")

	# Act
	builder.select("select test")
	builder.build()

	HtnError.add_assert("The domain definition lacks one or more End() statements. Pointer is 'select test', but expected 'Test'." == HtnError.get_message())

static func selector__compound_task() -> void:
	# Arrange
	var builder = HtnDomainBuilder.new(MyContext, "Test")

	# Act
	builder.select("select test")

	# Assert
	HtnError.add_assert(!builder.get_pointer() is HtnTaskRoot)
	HtnError.add_assert(builder.get_pointer() is HtnSelector)
	HtnError.add_assert("" == HtnError.get_message())

static func sequence__expected_behavior() -> void:
	# Arrange
	var builder = HtnDomainBuilder.new(MyContext, "Test")

	# Act
	builder.sequence("sequence test")
	builder.end()

	# Assert
	HtnError.add_assert(builder.get_pointer() is HtnTaskRoot)
	HtnError.add_assert("" == HtnError.get_message())

static func sequence__forgot_end() -> void:
	# Arrange
	var builder = HtnDomainBuilder.new(MyContext, "Test")

	# Act
	builder.sequence("sequence test")

	# Assert
	HtnError.add_assert(builder.get_pointer() is HtnSequence)
	HtnError.add_assert("" == HtnError.get_message())

static func sequence__compound_task() -> void:
	# Arrange
	var builder = HtnDomainBuilder.new(MyContext, "Test")

	# Act
	builder.compound_task(HtnSequence, "sequence test")

	# Assert
	HtnError.add_assert(builder.get_pointer() is HtnSequence)
	HtnError.add_assert("" == HtnError.get_message())

static func action__expected_behavior() -> void:
	# Arrange
	var builder = HtnDomainBuilder.new(MyContext, "Test")

	# Act
	builder.action("sequence test")
	builder.end()

	# Assert
	HtnError.add_assert(builder.get_pointer() is HtnTaskRoot)
	HtnError.add_assert("" == HtnError.get_message())

static func action__forgot_end() -> void:
	# Arrange
	var builder = HtnDomainBuilder.new(MyContext, "Test")

	# Act
	builder.action("sequence test")

	# Assert
	HtnError.add_assert(builder.get_pointer() is HtnPrimitiveTask)
	HtnError.add_assert("" == HtnError.get_message())

static func action__primitive_task() -> void:
	# Arrange
	var builder = HtnDomainBuilder.new(MyContext, "Test")

	# Act
	builder.primitive_task(HtnPrimitiveTask, "sequence test")

	# Assert
	HtnError.add_assert(builder.get_pointer() is HtnPrimitiveTask)
	HtnError.add_assert("" == HtnError.get_message())

static func pause_plan_throws_when_pointer_is_not_decompose_all() -> void:
	# Arrange
	var builder = HtnDomainBuilder.new(MyContext, "Test")

	# Act
	builder.pause_plan()

	HtnError.add_assert("Pointer is not a decompose-all compound task type, like a Sequence. Maybe you tried to Pause Plan a Selector, or forget an End() after a Primitive Task Action was defined?" == HtnError.get_message())

static func pause_plan__expected_behaviour() -> void:
	# Arrange
	var builder = HtnDomainBuilder.new(MyContext, "Test")

	# Act
	builder.sequence("sequence test")
	builder.pause_plan()
	builder.end()

	HtnError.add_assert(builder.get_pointer() is HtnTaskRoot)
	HtnError.add_assert("" == HtnError.get_message())

static func pause_plan__forgot_end() -> void:
	# Arrange
	var builder = HtnDomainBuilder.new(MyContext, "Test")

	# Act
	builder.sequence("sequence test")
	builder.pause_plan()

	HtnError.add_assert(builder.get_pointer() is HtnSequence)
	HtnError.add_assert("" == HtnError.get_message())

static func condition__expected_behaviour() -> void:
	# Arrange
	var builder = HtnDomainBuilder.new(MyContext, "Test")

	# Act
	builder.condition("test", func (_ctx):
		return true)

	HtnError.add_assert(builder.get_pointer() is HtnTaskRoot)
	HtnError.add_assert("" == HtnError.get_message())

static func executing_condition__throws_if_not_primitive_task_pointer() -> void:
	# Arrange
	var builder = HtnDomainBuilder.new(MyContext, "Test")

	# Act
	builder.executing_condition("test", func (_ctx):
		return true)

	HtnError.add_assert("Tried to add an Executing Condition, but the Pointer is not a Primitive Task!" == HtnError.get_message())

static func executing_condition__expected_behavior() -> void:
	# Arrange
	var builder = HtnDomainBuilder.new(MyContext, "Test")

	# Act
	builder.action("test")
	builder.executing_condition("test", func (_ctx):
		return true)
	builder.end()

	HtnError.add_assert(builder.get_pointer() is HtnTaskRoot)
	HtnError.add_assert("" == HtnError.get_message())

static func executing_condition__forgot_end() -> void:
	# Arrange
	var builder = HtnDomainBuilder.new(MyContext, "Test")

	# Act
	builder.action("test")
	builder.executing_condition("test", func (_ctx):
		return true)

	HtnError.add_assert(builder.get_pointer() is HtnPrimitiveTask)
	HtnError.add_assert("" == HtnError.get_message())

static func do__throws_if_not_primitive_task_pointer() -> void:
	# Arrange
	var builder = HtnDomainBuilder.new(MyContext, "Test")

	# Act
	builder.do(func (_ctx):
		return Htn.TaskStatus.SUCCESS)

	HtnError.add_assert("Tried to add an Operator, but the Pointer is not a Primitive Task!" == HtnError.get_message())

static func do__expected_behavior() -> void:
	# Arrange
	var builder = HtnDomainBuilder.new(MyContext, "Test")

	# Act
	builder.action("test")
	builder.do(func (_ctx):
		return Htn.TaskStatus.SUCCESS)
	builder.end()

	HtnError.add_assert(builder.get_pointer() is HtnTaskRoot)
	HtnError.add_assert("" == HtnError.get_message())

static func do__forgot_end() -> void:
	# Arrange
	var builder = HtnDomainBuilder.new(MyContext, "Test")

	# Act
	builder.action("test")
	builder.do(func (_ctx):
		return Htn.TaskStatus.SUCCESS)

	HtnError.add_assert(builder.get_pointer() is HtnPrimitiveTask)
	HtnError.add_assert("" == HtnError.get_message())

static func effect__throws_if_not_primitive_task_pointer() -> void:
	# Arrange
	var builder = HtnDomainBuilder.new(MyContext, "Test")

	# Act
	builder.effect("test", Htn.EffectType.PERMANENT, func (_ctx, _t):
		pass)

	HtnError.add_assert("Tried to add an Effect, but the Pointer is not a Primitive Task!" == HtnError.get_message())

static func effect__expected_behavior() -> void:
	# Arrange
	var builder = HtnDomainBuilder.new(MyContext, "Test")

	# Act
	builder.action("test")
	builder.effect("test", Htn.EffectType.PERMANENT, func (_ctx, _t):
		pass)
	builder.end()

	HtnError.add_assert(builder.get_pointer() is HtnTaskRoot)
	HtnError.add_assert("" == HtnError.get_message())

static func effect__forgot_end() -> void:
	# Arrange
	var builder = HtnDomainBuilder.new(MyContext, "Test")

	# Act
	builder.action("test")
	builder.effect("test", Htn.EffectType.PERMANENT, func (_ctx, _t):
		pass)

	HtnError.add_assert(builder.get_pointer() is HtnPrimitiveTask)
	HtnError.add_assert("" == HtnError.get_message())

static func splice__throws_if_not_compound_pointer() -> void:
	# Arrange
	var builder = HtnDomainBuilder.new(MyContext, "Test")

	# Act
	var domain = HtnDomainBuilder.new(MyContext, "sub-domain").build()
	builder.action("test")
	builder.splice(domain)

	HtnError.add_assert("Pointer is not a compound task type. Did you forget an End()?" == HtnError.get_message())

static func splice__expected_behavior() -> void:
	# Arrange
	var builder = HtnDomainBuilder.new(MyContext, "Test")

	# Act
	var domain = HtnDomainBuilder.new(MyContext, "sub-domain").build()
	builder.splice(domain)

	HtnError.add_assert(builder.get_pointer() is HtnTaskRoot)
	HtnError.add_assert("" == HtnError.get_message())

static func splice__forgot_end() -> void:
	# Arrange
	var builder = HtnDomainBuilder.new(MyContext, "Test")

	# Act
	var domain = HtnDomainBuilder.new(MyContext, "sub-domain").build()
	builder.select("test")
	builder.splice(domain)

	HtnError.add_assert(builder.get_pointer() is HtnSelector)
	HtnError.add_assert("" == HtnError.get_message())

static func slot__throws_if_not_compound_pointer() -> void:
	# Arrange
	var builder = HtnDomainBuilder.new(MyContext, "Test")

	# Act
	builder.action("test")
	builder.slot(1)

	HtnError.add_assert("Pointer is not a compound task type. Did you forget an End()?" == HtnError.get_message())

static func slot__throws_if_slot_id_already_defined() -> void:
	# Arrange
	var builder = HtnDomainBuilder.new(MyContext, "Test")

	# Act
	builder.slot(1)
	builder.slot(1)

	HtnError.add_assert("This slot id already exist in the domain definition!" == HtnError.get_message())

static func slot__expected_behavior() -> void:
	# Arrange
	var builder = HtnDomainBuilder.new(MyContext, "Test")

	# Act
	builder.slot(1)

	HtnError.add_assert(builder.get_pointer() is HtnTaskRoot)

	var domain = builder.build()

	var sub_domain = HtnDomainBuilder.new(MyContext, "sub-domain").build()

	HtnError.add_assert(domain.try_set_slot_domain(1, sub_domain)) # Its valid to add a sub-domain to a slot we have defined in our domain definition, and that is not currently occupied.
	HtnError.add_assert(!domain.try_set_slot_domain(1, sub_domain)) # Need to clear slot before we can attach sub-domain to a currently occupied slot.
	HtnError.add_assert(!domain.try_set_slot_domain(99, sub_domain)) # Need to define slotId in domain definition before we can attach sub-domain to that slot.

	HtnError.add_assert(1 == domain.get_root().get_subtasks().size())
	HtnError.add_assert(domain.get_root().get_subtasks()[0] is HtnSlot)

	var slot: HtnSlot = domain.get_root().get_subtasks()[0]

	HtnError.add_assert(null != slot.get_subtask())
	HtnError.add_assert(slot.get_subtask() is HtnTaskRoot)
	HtnError.add_assert("sub-domain" == slot.get_subtask().get_name())

	domain.clear_slot(1)

	HtnError.add_assert(null == slot.get_subtask())
	HtnError.add_assert("" == HtnError.get_message())

static func slot__forgot_end() -> void:
	# Arrange
	var builder = HtnDomainBuilder.new(MyContext, "Test")

	# Act
	builder.select("test")
	builder.slot(1)

	HtnError.add_assert(builder.get_pointer() is HtnSelector)
	HtnError.add_assert("" == HtnError.get_message())

static func run() -> void:
	HtnError.reset_message()
	build__forgot_end()
	HtnError.reset_message()
	build_invalidates_pointer__forgot_end()
	HtnError.reset_message()
	selector__expected_behavior()
	HtnError.reset_message()
	selector__forgot_end()
	HtnError.reset_message()
	selector_build__forgot_end()
	HtnError.reset_message()
	selector__compound_task()
	HtnError.reset_message()
	sequence__expected_behavior()
	HtnError.reset_message()
	sequence__forgot_end()
	HtnError.reset_message()
	sequence__compound_task()
	HtnError.reset_message()
	action__expected_behavior()
	HtnError.reset_message()
	action__forgot_end()
	HtnError.reset_message()
	action__primitive_task()
	HtnError.reset_message()
	pause_plan_throws_when_pointer_is_not_decompose_all()
	HtnError.reset_message()
	pause_plan__expected_behaviour()
	HtnError.reset_message()
	pause_plan__forgot_end()
	HtnError.reset_message()
	condition__expected_behaviour()
	HtnError.reset_message()
	executing_condition__throws_if_not_primitive_task_pointer()
	HtnError.reset_message()
	executing_condition__expected_behavior()
	HtnError.reset_message()
	executing_condition__forgot_end()
	HtnError.reset_message()
	do__throws_if_not_primitive_task_pointer()
	HtnError.reset_message()
	do__expected_behavior()
	HtnError.reset_message()
	do__forgot_end()
	HtnError.reset_message()
	effect__throws_if_not_primitive_task_pointer()
	HtnError.reset_message()
	effect__expected_behavior()
	HtnError.reset_message()
	effect__forgot_end()
	HtnError.reset_message()
	splice__throws_if_not_compound_pointer()
	HtnError.reset_message()
	splice__expected_behavior()
	HtnError.reset_message()
	splice__forgot_end()
	HtnError.reset_message()
	slot__throws_if_not_compound_pointer()
	HtnError.reset_message()
	slot__throws_if_slot_id_already_defined()
	HtnError.reset_message()
	slot__expected_behavior()
	HtnError.reset_message()
	slot__forgot_end()
