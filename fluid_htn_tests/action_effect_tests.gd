class_name HtnActionEffectTests
extends Object

static func sets_name__expected_behavior() -> void:
	var e = HtnActionEffect.new(MyContext, "Name", Htn.EffectType.PLAN_ONLY, null)

	HtnError.add_assert("Name" == e.get_name())
	HtnError.add_assert("" == HtnError.get_message())

static func sets_type__expected_behavior() -> void:
	var e = HtnActionEffect.new(MyContext, "Name", Htn.EffectType.PLAN_ONLY, null)

	HtnError.add_assert(Htn.EffectType.PLAN_ONLY == e.get_type())
	HtnError.add_assert("" == HtnError.get_message())

static func apply_does_nothing_without_function_ptr__expected_behavior() -> void:
	var ctx = MyContext.new()
	var e = HtnActionEffect.new(MyContext, "Name", Htn.EffectType.PLAN_ONLY, null)

	var result = e.apply(ctx)

	HtnError.add_assert(!result)
	HtnError.add_assert("" == HtnError.get_message())

static func apply_throws_if_bad_context__expected_behavior() -> void:
	var e = HtnActionEffect.new(MyContext, "Name", Htn.EffectType.PLAN_ONLY, null)

	var result = e.apply(null)

	HtnError.add_assert(!result)
	HtnError.add_assert("Unexpected context type!" == HtnError.get_message())

static func apply_calls_internal_functionPtr__expected_behavior() -> void:
	var ctx = MyContext.new()
	var e = HtnActionEffect.new(MyContext, "Name", Htn.EffectType.PLAN_ONLY, func (c, _et):
		c.set_done(true))

	var result = e.apply(ctx)

	HtnError.add_assert(ctx.is_done())
	HtnError.add_assert(result)
	HtnError.add_assert("" == HtnError.get_message())

static func run() -> void:
	HtnError.reset_message()
	sets_name__expected_behavior()
	HtnError.reset_message()
	sets_type__expected_behavior()
	HtnError.reset_message()
	apply_does_nothing_without_function_ptr__expected_behavior()
	HtnError.reset_message()
	apply_throws_if_bad_context__expected_behavior()
	HtnError.reset_message()
	apply_calls_internal_functionPtr__expected_behavior()
