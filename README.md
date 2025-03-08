# godot-fluid-hierarchical-task-network

An [addon](https://godotengine.org/asset-library/asset/2944) for [Godot 4](https://godotengine.org/) that copycats [Fluid HTN](https://github.com/ptrefall/fluid-hierarchical-task-network) by [@ptrefall](https://github.com/ptrefall). The latest checked version is [500e692](https://github.com/ptrefall/fluid-hierarchical-task-network/commit/500e692fd844ec43d8c0bb4b5c1c476901dbd5de)

![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)
![Stars](https://img.shields.io/github/stars/fnaith/godot-fluid-hierarchical-task-network.svg)
![Forks](https://img.shields.io/github/forks/fnaith/godot-fluid-hierarchical-task-network.svg)
![Issues](https://img.shields.io/github/issues/fnaith/godot-fluid-hierarchical-task-network.svg)

## Features

See Fluid HTN's [Features](https://github.com/ptrefall/fluid-hierarchical-task-network/tree/master?tab=readme-ov-file#features) for more details.

## Support

Please share your feedback and use case in [Issues](https://github.com/fnaith/godot-fluid-hierarchical-task-network/issues).

## Getting started

See Fluid HTN's [Getting started](https://github.com/ptrefall/fluid-hierarchical-task-network/tree/master?tab=readme-ov-file#getting-started) for more details.

## Examples

- [fluid_htn_tests](https://github.com/fnaith/godot-fluid-hierarchical-task-network/tree/main/fluid_htn_tests) : test cases of [Fluid HTN](https://github.com/ptrefall/fluid-hierarchical-task-network/tree/master/Fluid-HTN.UnitTests) implemented in GDScript.
- [fluid_smart_objects](https://github.com/fnaith/godot-fluid-hierarchical-task-network/tree/main/fluid_smart_objects) : a simplified [Fluid Smart Objects](https://github.com/ptrefall/fluid-smart-objects) implemented in GDScript.
- [fluid_text_adventure](https://github.com/fnaith/godot-fluid-hierarchical-task-network/tree/main/fluid_text_adventure) : a simplified [Fluid Text Adventure](https://github.com/ptrefall/fluid-text-adventure) implemented in GDScript.

## Changes

### Naming Changes

- All names are following [GDScript naming conventions](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html#naming-conventions).

### Changes for GDScript

Because GDScript doesn't support :
- Namespace : so all classes are added a prefix `Htn`.
- Interface : so all C# interfaces are replaced by a base class with assertions.
- Properties Access Modifier : so all C# properties are replaced by access functions.
- Function Overloading : so type names are added to functions.
- Generic : so Script objects are being used to check the IContext type in debug builds. (checking class info hurts performance)
- Globally Accessible Enum : so all eunm types are moved into `Htn` class.
- Nullable Typed Array : so all array variables are initialized with an empty array rather than null.
- Advenced Data Structure : so `Array` is being used to present List, Queue, Stack and KeyValuePair.
- Exception Handling : so `HtnError` is being used to record error message and test assertion.

### Changes for Godot

- Remove Factory : because object pooling might not be useful in Godot.
- Remove ConsoleColor from log functions : because Godot doesn't have such things.

### Interface Changes

- `Queue<ITask>` : repalced by `HtnPlan`, for better abstraction.
- `IDecomposeAll` : merged into `ICompoundTask`, because checking class info hurts performance.
- `IOperator`
  - Stop : return false if action failed.
  - Aborted : return false if action failed.
- `IEffect`
  - Apply : return false if action failed.
- `ITask`
  - Use `TaskType` to check task type rather than use class info.
  - Stop : return false if _operator is null.
  - Aborted : return false if _operator is null.
- `IPrimitiveTask`
  - set_operator : return false if _operator isn't null.
- `BaseDomainBuilder`
  - `CompoundTask<P>(string name, P task)` : renamed to add_subtask
- `DecompositionLogEntry`
  - depth_to_string : add the `indent` parameter

### Renamed Tests

- `HtnBaseContextTests` : rename `initinitialize_collections__expected_behavior` to `init_initialize_collections__expected_behavior`
- `HtnPlannerTests` : rename `find_plan_if_world_state_change_to_worse_mrt_and_operator_is_continuous__expected_behavior` to `find_plan_if_world_state_change_to_worse_mtr_and_operator_is_continuous__expected_behavior`

### Changed Tests

- `HtnSequenceTests` : change `DecomposeRequiresContextInitFails_ExpectedBehavior` to `decompose_without_context_init__expected_behavior`, because GDScript can't init _world_state_change_stack as null

### Deleted Tests

- `DomainTests` : delete `MTRNullThrowsException_ExpectedBehavior`, because GDScript can't set `Array` to null

### New Tests

- `HtnBaseContextTests` : `is_script__expected_behavior`
- `HtnFuncOperatorTests` : `aborted_does_nothing_without_function_ptr__expected_behavior`
- `HtnFuncOperatorTests` : `aborted_throws_if_bad_context__expected_behavior`
- `HtnFuncOperatorTests` : `aborted_calls_internal_function_ptr__expected_behavior`
- `HtnPrimitiveTaskTests` : `aborted_with_valid_operator__expected_behavior`
- `HtnPrimitiveTaskTests` : `aborted_with_null_operator__expected_behavior`

## Checked Classes

- contexts
  - IContext
  - BaseContext
  - PartialPlanEntry
- debug
  - DecompositionLogEntry
- conditions
  - IContext
  - FuncCondition
- operators
  - IOperator
  - FuncOperator
- effects
  - EffectType
  - IEffect
- tasks
  - TaskStatus
  - ITask
  - IPrimitiveTask
  - PrimitiveTask
  - DecompositionStatus
  - IDecomposeAll
  - PausePlanTask
  - ICompoundTask
  - CompoundTask
  - Selector
  - Sequence
  - TaskRoot
  - Slot
- domain
  - IDomain
  - Domain
- planners
  - Planner
- domain_builder
  - BaseDomainBuilder
  - DomainBuilder
- fluid_htn_tests
  - MyContext
  - MyDebugContext
  - BaseContextTests
  - FuncConditionTests
  - FuncOperatorTests
  - ActionEffectTests
  - PrimitiveTaskTests
  - SelectorTests
  - SequenceTests
  - DomainTests
  - PlannerTests
  - BaseDomainBuilder

## TODO

- Minor optimization : remove while loop, remove temp array, add HtnIPlannerState bool functions, etc
- Add extended selectors from [Fluid HTN Extension library](https://github.com/ptrefall/fluid-hierarchical-task-network-ext).
- Add examples : Fluid Goap Coffai
- Remove debug info when exporting project by putting related code into `assert()`
