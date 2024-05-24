class_name HtnIEffect
extends RefCounted

func get_name() -> String:
	assert(false, "Don't use HtnIEffect.get_name")
	return ""

func get_type() -> Htn.EffectType:
	assert(false, "Don't use HtnIEffect.get_type")
	return Htn.EffectType.PLAN_AND_EXECUTE

func apply(_ctx: HtnIContext) -> bool:
	assert(false, "Don't use HtnIEffect.apply")
	return false
