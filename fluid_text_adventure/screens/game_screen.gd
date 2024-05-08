class_name TaGameScreen
extends RefCounted

static var _NULL_ACTION: Callable = func (_context):
	return null

var _domain: HtnDomain
var _items: Array[TaItem]
var _keywords_to_action = {}

func get_domain() -> HtnDomain:
	return _domain

func initialize(domain: HtnDomain) -> void:
	_domain = domain

func write(text: String) -> void:
	print(text)

func perform_action(context: TaContext, action: String) -> TaGameScreen:
	action = action.to_lower()
	var parameters = action.split(" ")
	parameters = splice_known_commands(parameters)
	var fn = find_best_match(parameters)
	var result = fn.call(context)
	if null == result:
		TaActions.failed(context)
		return context.get_current_screen()

	return result

func splice_known_commands(parameters: Array[String]) -> Array[String]:
	var new_parameters: Array[String] = []
	for parameter in parameters:
		if "up" == parameter and !new_parameters.is_empty() and "pick" == new_parameters.back():
			new_parameters.pop_back()
			new_parameters.append("pick up")
		else:
			new_parameters.append(parameter)

	return new_parameters

func find_best_match(parameters: Array[String]) -> Callable:
	var best_match: Callable = _NULL_ACTION
	var best_score = 0
	for keywords in _keywords_to_action:
		if !is_equal(keywords[0], parameters[0]):
			continue

		var score = 0
		for key in keywords:
			for parameter in parameters:
				if is_equal(key, parameter):
					score += 1

		if keywords.size() == parameters.size():
			score *= 10

		if best_score < score:
			best_score = score
			best_match = _keywords_to_action[keywords]

	for item in _items:
		for keywords in item.get_keywords_to_action():
			if !is_equal(keywords[0], parameters[0]):
				continue

			var score = 0
			for key in keywords:
				for parameter in parameters:
					if is_equal(key, parameter):
						score += 1

			if keywords.size() == parameters.size():
				score *= 10

			if best_score < score:
				best_score = score
				best_match = item.get_keywords_to_action()[keywords]

	if 1 == best_score and 1 == parameters.size():
		return best_match

	return best_match if 1 < best_score else _NULL_ACTION

func is_equal(a: String, b: String) -> bool:
	if a == b:
		return true

	if "get" == a:
		if b in ["pick up", "fetch", "hold", "wield", "gather", "acquire", "take"]:
			return true

	if "slash" == a:
		if b in ["swing", "cut", "attack", "hit", "hack", "slice", "slit"]:
			return true

	if "drink" == a:
		if b in ["sip", "gulp", "swallow", "quaff", "taste", "consume", "drain", "slurp", "down"]:
			return true

	if "open" == a:
		if b in ["unscrew", "uncork"]:
			return true

	if "throw" == a:
		if b in ["whirl", "fling", "hurl", "lob", "thrust"]:
			return true

	if "break" == a:
		if b in ["destroy", "shatter", "crack", "crush", "demolish", "fracture", "ruin", "smash", "wreck"]:
			return true

	return false
