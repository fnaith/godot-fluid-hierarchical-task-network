class_name HtnBaseContextTests
extends Object

## Verifies that a newly created context initializes with a ContextState of Executing by default.
## The context state tracks whether the planner is in Planning mode (building a new plan) or Executing mode (running the current plan).
## Executing is the default state because the planner typically starts in execution mode before transitioning to planning when needed.
## This test ensures the context begins in the correct state without requiring explicit initialization for typical use cases.
static func default_context_state_is_executing__expected_behavior() -> void:
	var ctx = MyContext.new()

	HtnError.add_assert(Htn.ContextState.EXECUTING == ctx.get_context_state())
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that Init properly initializes the context's world state tracking structures without enabling debug facilities.
## Init must be called before planning/execution to set up the WorldStateChangeStack, a collection that tracks all state modifications made during planning.
## The stack array has one entry per world state enum value, allowing the planner to rewind state changes when backtracking during decomposition.
## This test confirms Init creates the necessary collections while leaving debug logging disabled (debugging must be explicitly enabled in derived contexts).
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

## Verifies that Init initializes debug logging collections when the context has debug flags enabled.
## Derived contexts can override DebugMTR and LogDecomposition flags to enable detailed decomposition tracing.
## When debug is enabled, Init allocates MTRDebug (Method Traversal Record for selector choices), LastMTRDebug (previous MTR for comparison), and DecompositionLog (detailed decomposition trace).
## This test confirms that debug contexts properly initialize all logging infrastructure to support detailed plan analysis during development.
static func init_initialize_debug_collections__expected_behavior() -> void:
	var ctx = MyDebugContext.new()

	ctx.init()

	HtnError.add_assert(ctx.is_debug_mtr())
	HtnError.add_assert(ctx.is_log_decomposition())
	HtnError.add_assert(ctx.get_mtr_debug().is_empty())
	HtnError.add_assert(ctx.get_last_mtr_debug().is_empty())
	HtnError.add_assert(ctx.get_decomposition_log().is_empty())
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that HasState correctly checks if a world state value is currently true based on the context's world state representation.
## HasState is a convenience method that checks the byte array representation of world state, treating non-zero values as true.
## The context tracks world state using enum-indexed byte arrays for type safety and performance, where each state can be either 0 (false) or 1 (true).
## This test demonstrates that HasState accurately reflects the current world state after modifications have been applied.
static func has_state__expected_behavior() -> void:
	var ctx = MyContext.new()

	ctx.init()
	ctx.set_bool_state(MyContext.WorldState.HAS_B, true, Htn.EffectType.PERMANENT)

	HtnError.add_assert(!ctx.has_bool_state(MyContext.WorldState.HAS_A))
	HtnError.add_assert(ctx.has_bool_state(MyContext.WorldState.HAS_B))
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that SetState in Planning context mode tracks state changes on the WorldStateChangeStack without modifying the actual WorldState array.
## During planning, effects are applied speculatively to explore decomposition paths; the change stack records these modifications so they can be rolled back.
## SetState pushes the effect and value onto the state's stack but leaves the WorldState byte array unchanged, allowing the planner to rewind changes.
## This test confirms the critical planning behavior: state changes are tracked for lookahead without modifying the actual state until execution.
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

## Verifies that SetState in Executing context mode immediately modifies the WorldState array without tracking changes on the stack.
## During execution, effects are applied directly to the world state because there is no need to track them for rollback.
## Executing context treats SetState as a direct state mutation, with changes immediately visible in the WorldState byte array.
## This test confirms that execution properly applies effects to the actual world state for normal game/application logic.
static func set_state_executing_context__expected_behavior() -> void:
	var ctx = MyContext.new()

	ctx.init()
	ctx.set_context_state(Htn.ContextState.EXECUTING)
	ctx.set_bool_state(MyContext.WorldState.HAS_B, true, Htn.EffectType.PERMANENT)

	HtnError.add_assert(ctx.has_bool_state(MyContext.WorldState.HAS_B))
	HtnError.add_assert(ctx.get_world_state_change_stack()[MyContext.WorldState.HAS_B].is_empty())
	HtnError.add_assert(1 == ctx.get_world_state()[MyContext.WorldState.HAS_B])
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that GetState in Planning context returns the effect-modified value from the change stack, providing lookahead during decomposition.
## GetState checks if there are pending changes in the change stack and returns the modified value if found, otherwise returns the base state.
## This enables conditions to evaluate the speculative world state during planning, allowing the planner to make decisions based on what the world would be after planned effects.
## This test confirms that GetState properly implements the lookahead mechanism for informed task selection during decomposition.
static func get_state_planning_context__expected_behavior() -> void:
	var ctx = MyContext.new()

	ctx.init()
	ctx.set_context_state(Htn.ContextState.PLANNING)
	ctx.set_bool_state(MyContext.WorldState.HAS_B, true, Htn.EffectType.PERMANENT)

	HtnError.add_assert(0 == ctx.get_state(MyContext.WorldState.HAS_A))
	HtnError.add_assert(1 == ctx.get_state(MyContext.WorldState.HAS_B))
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that GetState in Executing context returns the actual world state from the WorldState byte array.
## During execution, there is no change stack to consult—GetState simply returns the current world state values directly.
## This ensures tasks executing see the real, current world state, not a speculative state for planning purposes.
## This test confirms that GetState provides accurate state information during task execution for proper behavior control.
static func get_state_executing_context__expected_behavior() -> void:
	var ctx = MyContext.new()

	ctx.init()
	ctx.set_context_state(Htn.ContextState.EXECUTING)
	ctx.set_bool_state(MyContext.WorldState.HAS_B, true, Htn.EffectType.PERMANENT)

	HtnError.add_assert(0 == ctx.get_state(MyContext.WorldState.HAS_A))
	HtnError.add_assert(1 == ctx.get_state(MyContext.WorldState.HAS_B))
	HtnError.add_assert("" == HtnError.get_message())

## Verifies that GetWorldStateChangeDepth correctly captures the current depth of the change stack for each world state.
## GetWorldStateChangeDepth creates a snapshot of the stack depths that can be used to restore the state to this point later via TrimToStackDepth.
## During executing, no changes are tracked so all depths remain zero; during planning, depths reflect the number of effects applied to each state.
## This test demonstrates the snapshot mechanism that enables the planner to backtrack and explore alternative decomposition paths.
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

## Verifies that TrimForExecution removes PlanOnly effects and applies selected effects to the world state, preparing the context for execution.
## TrimForExecution is called after a successful plan to clean up planning artifacts and apply the actual world state changes from the plan.
## PlanOnly effects are removed (they were only for planning lookahead), Permanent effects stay in the stack, and PlanAndExecute effects transition from stack to world state.
## This test demonstrates the critical transition from planning mode to execution mode, where speculative changes become actual world modifications.
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

## Verifies that TrimForExecution throws an exception when called in Executing context state rather than Planning.
## TrimForExecution is only meaningful during Planning mode when there is a change stack to process; calling it during Execution indicates a programming error.
## The exception prevents accidental state corruption by rejecting transitions that only make sense in Planning mode.
## This test ensures the context validates its state and fails fast rather than silently performing invalid operations.
static func trim_for_execution_throws_exception_if_wrong_context_state__expected_behavior() -> void:
	var ctx = MyContext.new()

	ctx.init()
	ctx.set_context_state(Htn.ContextState.EXECUTING)
	ctx.trim_for_execution()

	HtnError.add_assert("Can not trim a context when in execution mode" == HtnError.get_message())

## Verifies that TrimToStackDepth correctly restores the change stack to a previously captured depth, enabling backtracking during decomposition.
## TrimToStackDepth is used by the planner when backtracking to explore alternative task decompositions after one path fails.
## It pops changes from the stack until each state's stack matches the provided depth array, effectively undoing speculative changes made during exploration.
## This test demonstrates the backtracking mechanism that enables the planner to explore multiple task decomposition paths in a single planning cycle.
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

## Verifies that TrimToStackDepth throws an exception when called in Executing context state rather than Planning.
## TrimToStackDepth is only meaningful during Planning mode when there is a change stack to manage; calling it during Execution is a programming error.
## The exception prevents accidental state corruption by rejecting backtracking operations that only make sense during plan exploration.
## This test ensures the context validates its state for all planning-specific operations and fails fast on invalid usage patterns.
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
