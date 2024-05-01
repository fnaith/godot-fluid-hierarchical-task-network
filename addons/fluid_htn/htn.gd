class_name Htn
extends Object

## The state our context can be in. This is essentially planning or execution state.
enum ContextState {
	PLANNING = 0,
	EXECUTING = 1,
}

enum LogEntryType {
	TASK = 0,
	CONDITION = 1,
	EFFECT = 2,
}

enum EffectType {
	PLAN_AND_EXECUTE = 0,
	PLAN_ONLY = 1,
	PERMANENT = 2,
}

enum TaskStatus {
	CONTINUE = 0,
	SUCCESS = 1,
	FAILURE = 2,
}

enum TaskType {
	PRIMITIVE = 0,
	COMPOUND = 1,
	PAUSE_PLAN = 2,
	SLOT = 3,
}

enum DecompositionStatus {
	SUCCEEDED = 0,
	PARTIAL = 1,
	FAILED = 2,
	REJECTED = 3,
}
