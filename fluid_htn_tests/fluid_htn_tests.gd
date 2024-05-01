class_name FluidHtnTests
extends Node

@onready var _label = $RichTextLabel

func _ready():
	HtnError.set_under_testing(true)
	HtnBaseContextTests.run()
	HtnFuncConditionTests.run()
	HtnFuncOperatorTests.run()
	HtnActionEffectTests.run()
	HtnPrimitiveTaskTests.run()
	HtnSequenceTests.run()
	HtnSelectorTests.run()
	HtnDomainTests.run()
	HtnPlannerTests.run()
	HtnDomainBuilderTests.run()
	HtnError.set_under_testing(false)

	_label.text = """htn tests : %d
htn asserts : %d""" % [HtnError.get_reset_message_count(), HtnError.get_assert_count()]
