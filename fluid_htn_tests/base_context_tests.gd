class_name HtnBaseContextTests
extends Object

static func default_context_state_is_executing__expected_behavior() -> void:
	var ctx = MyContext.new()

	HtnError.add_assert(Htn.ContextState.EXECUTING == ctx.get_context_state())
	HtnError.add_assert("" == HtnError.get_message())

static func init_initialize_collections__expected_behavior() -> void:
	var ctx = MyContext.new()

	ctx.init()

	HtnError.add_assert(!ctx.get_world_state_change_stack().is_empty())
	HtnError.add_assert(MyContext.WorldState.size() == ctx.get_world_state_change_stack().size())
	HtnError.add_assert(!ctx.is_debug_mtr())
	HtnError.add_assert(!ctx.is_log_decomposition())
	HtnError.add_assert(ctx.get_mtr_debug().is_empty())
	HtnError.add_assert(ctx.get_last_mtr_debug().is_empty())
	HtnError.add_assert(ctx.get_decomposition_log().is_empty())
	HtnError.add_assert("" == HtnError.get_message())

static func init_initialize_debug_collections__expected_behavior() -> void:
	var ctx = MyDebugContext.new()

	ctx.init()

	HtnError.add_assert(ctx.is_debug_mtr())
	HtnError.add_assert(ctx.is_log_decomposition())
	HtnError.add_assert(ctx.get_mtr_debug().is_empty())
	HtnError.add_assert(ctx.get_last_mtr_debug().is_empty())
	HtnError.add_assert(ctx.get_decomposition_log().is_empty())
	HtnError.add_assert("" == HtnError.get_message())

static func has_state__expected_behavior() -> void:
	var ctx = MyContext.new()

	ctx.init()
	ctx.set_bool_state(MyContext.WorldState.HAS_B, true, Htn.EffectType.PERMANENT)

	HtnError.add_assert(!ctx.has_bool_state(MyContext.WorldState.HAS_A))
	HtnError.add_assert(ctx.has_bool_state(MyContext.WorldState.HAS_B))
	HtnError.add_assert("" == HtnError.get_message())

static func set_state_planning_context__expected_behavior() -> void:
	var ctx = MyContext.new()

	ctx.init()
	ctx.set_context_state(Htn.ContextState.PLANNING)
	ctx.set_bool_state(MyContext.WorldState.HAS_B, true, Htn.EffectType.PERMANENT)

	HtnError.add_assert(ctx.has_bool_state(MyContext.WorldState.HAS_B))
	HtnError.add_assert(0 == ctx.get_world_state_change_stack()[MyContext.WorldState.HAS_A].size())
	HtnError.add_assert(1 == ctx.get_world_state_change_stack()[MyContext.WorldState.HAS_B].size())
	HtnError.add_assert(Htn.EffectType.PERMANENT == ctx.get_world_state_change_stack()[MyContext.WorldState.HAS_B].back()[0])
	HtnError.add_assert(1 == ctx.get_world_state_change_stack()[MyContext.WorldState.HAS_B].back()[1])
	HtnError.add_assert(0 == ctx.get_world_state()[MyContext.WorldState.HAS_B])
	HtnError.add_assert("" == HtnError.get_message())

static func set_state_executing_context__expected_behavior() -> void:
	var ctx = MyContext.new()

	ctx.init()
	ctx.set_context_state(Htn.ContextState.EXECUTING)
	ctx.set_bool_state(MyContext.WorldState.HAS_B, true, Htn.EffectType.PERMANENT)

	HtnError.add_assert(ctx.has_bool_state(MyContext.WorldState.HAS_B))
	HtnError.add_assert(ctx.get_world_state_change_stack()[MyContext.WorldState.HAS_B].is_empty())
	HtnError.add_assert(1 == ctx.get_world_state()[MyContext.WorldState.HAS_B])
	HtnError.add_assert("" == HtnError.get_message())

static func get_state_planning_context__expected_behavior() -> void:
	var ctx = MyContext.new()

	ctx.init()
	ctx.set_context_state(Htn.ContextState.PLANNING)
	ctx.set_bool_state(MyContext.WorldState.HAS_B, true, Htn.EffectType.PERMANENT)

	HtnError.add_assert(0 == ctx.get_state(MyContext.WorldState.HAS_A))
	HtnError.add_assert(1 == ctx.get_state(MyContext.WorldState.HAS_B))
	HtnError.add_assert("" == HtnError.get_message())

static func get_state_executing_context__expected_behavior() -> void:
	var ctx = MyContext.new()

	ctx.init()
	ctx.set_context_state(Htn.ContextState.EXECUTING)
	ctx.set_bool_state(MyContext.WorldState.HAS_B, true, Htn.EffectType.PERMANENT)

	HtnError.add_assert(0 == ctx.get_state(MyContext.WorldState.HAS_A))
	HtnError.add_assert(1 == ctx.get_state(MyContext.WorldState.HAS_B))
	HtnError.add_assert("" == HtnError.get_message())

static func get_world_state_change_depth__expected_behavior() -> void:
	var ctx = MyContext.new()

	ctx.init()
	ctx.set_context_state(Htn.ContextState.EXECUTING)
	ctx.set_bool_state(MyContext.WorldState.HAS_B, true, Htn.EffectType.PERMANENT)
	var change_depth_executing = ctx.get_world_state_change_depth()

	ctx.set_context_state(Htn.ContextState.PLANNING)
	ctx.set_bool_state(MyContext.WorldState.HAS_B, true, Htn.EffectType.PERMANENT)
	var change_depth_planning = ctx.get_world_state_change_depth()

	HtnError.add_assert(ctx.get_world_state_change_stack().size() == change_depth_executing.size())
	HtnError.add_assert(0 == change_depth_executing[MyContext.WorldState.HAS_A])
	HtnError.add_assert(0 == change_depth_executing[MyContext.WorldState.HAS_B])

	HtnError.add_assert(ctx.get_world_state_change_stack().size() == change_depth_planning.size())
	HtnError.add_assert(0 == change_depth_planning[MyContext.WorldState.HAS_A])
	HtnError.add_assert(1 == change_depth_planning[MyContext.WorldState.HAS_B])
	HtnError.add_assert("" == HtnError.get_message())

static func trim_for_execution__expected_behavior() -> void:
	var ctx = MyContext.new()

	ctx.init()
	ctx.set_context_state(Htn.ContextState.PLANNING)
	ctx.set_bool_state(MyContext.WorldState.HAS_A, true, Htn.EffectType.PLAN_AND_EXECUTE)
	ctx.set_bool_state(MyContext.WorldState.HAS_B, true, Htn.EffectType.PERMANENT)
	ctx.set_bool_state(MyContext.WorldState.HAS_C, true, Htn.EffectType.PLAN_ONLY)
	ctx.trim_for_execution()

	HtnError.add_assert(0 == ctx.get_world_state_change_stack()[MyContext.WorldState.HAS_A].size())
	HtnError.add_assert(1 == ctx.get_world_state_change_stack()[MyContext.WorldState.HAS_B].size())
	HtnError.add_assert(0 == ctx.get_world_state_change_stack()[MyContext.WorldState.HAS_C].size())
	HtnError.add_assert("" == HtnError.get_message())

static func trim_for_execution_throws_exception_if_wrong_context_state__expected_behavior() -> void:
	var ctx = MyContext.new()

	ctx.init()
	ctx.set_context_state(Htn.ContextState.EXECUTING)
	ctx.trim_for_execution()

	HtnError.add_assert("Can not trim a context when in execution mode" == HtnError.get_message())

static func trim_to_stack_depth__expected_behavior() -> void:
	var ctx = MyContext.new()

	ctx.init()
	ctx.set_context_state(Htn.ContextState.PLANNING)
	ctx.set_bool_state(MyContext.WorldState.HAS_A, true, Htn.EffectType.PLAN_AND_EXECUTE)
	ctx.set_bool_state(MyContext.WorldState.HAS_B, true, Htn.EffectType.PERMANENT)
	ctx.set_bool_state(MyContext.WorldState.HAS_C, true, Htn.EffectType.PLAN_ONLY)
	var stack_depth = ctx.get_world_state_change_depth()

	ctx.set_bool_state(MyContext.WorldState.HAS_A, false, Htn.EffectType.PLAN_AND_EXECUTE)
	ctx.set_bool_state(MyContext.WorldState.HAS_B, false, Htn.EffectType.PERMANENT)
	ctx.set_bool_state(MyContext.WorldState.HAS_C, false, Htn.EffectType.PLAN_ONLY)
	ctx.trim_to_stack_depth(stack_depth)

	HtnError.add_assert(1 == ctx.get_world_state_change_stack()[MyContext.WorldState.HAS_A].size())
	HtnError.add_assert(1 == ctx.get_world_state_change_stack()[MyContext.WorldState.HAS_B].size())
	HtnError.add_assert(1 == ctx.get_world_state_change_stack()[MyContext.WorldState.HAS_C].size())
	HtnError.add_assert("" == HtnError.get_message())

static func trim_to_stack_depth_throws_exception_if_wrong_context_state__expected_behavior() -> void:
	var ctx = MyContext.new()

	ctx.init()
	ctx.set_context_state(Htn.ContextState.EXECUTING)
	var stack_depth = ctx.get_world_state_change_depth()
	ctx.trim_to_stack_depth(stack_depth)

	HtnError.add_assert("Can not trim a context when in execution mode" == HtnError.get_message())

static func is_script__expected_behavior() -> void:
	var ctx = MyContext.new()
	var debug_ctx = MyDebugContext.new()

	HtnError.add_assert(ctx.is_script(HtnIContext))
	HtnError.add_assert(ctx.is_script(HtnBaseContext))
	HtnError.add_assert(ctx.is_script(MyContext))
	HtnError.add_assert(!ctx.is_script(MyDebugContext))
	HtnError.add_assert(!ctx.is_script(Htn))
	HtnError.add_assert(debug_ctx.is_script(HtnIContext))
	HtnError.add_assert(debug_ctx.is_script(HtnBaseContext))
	HtnError.add_assert(debug_ctx.is_script(MyContext))
	HtnError.add_assert(debug_ctx.is_script(MyDebugContext))
	HtnError.add_assert(!debug_ctx.is_script(Htn))

static func run() -> void:
	HtnError.reset_message()
	default_context_state_is_executing__expected_behavior()
	HtnError.reset_message()
	init_initialize_collections__expected_behavior()
	HtnError.reset_message()
	init_initialize_debug_collections__expected_behavior()
	HtnError.reset_message()
	has_state__expected_behavior()
	HtnError.reset_message()
	set_state_planning_context__expected_behavior()
	HtnError.reset_message()
	set_state_executing_context__expected_behavior()
	HtnError.reset_message()
	get_state_planning_context__expected_behavior()
	HtnError.reset_message()
	get_state_executing_context__expected_behavior()
	HtnError.reset_message()
	get_world_state_change_depth__expected_behavior()
	HtnError.reset_message()
	trim_for_execution__expected_behavior()
	HtnError.reset_message()
	trim_for_execution_throws_exception_if_wrong_context_state__expected_behavior()
	HtnError.reset_message()
	trim_to_stack_depth__expected_behavior()
	HtnError.reset_message()
	trim_to_stack_depth_throws_exception_if_wrong_context_state__expected_behavior()
	HtnError.reset_message()
	is_script__expected_behavior()
