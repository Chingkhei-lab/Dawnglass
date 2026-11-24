extends Label

func _physics_process(_delta: float) -> void:
	text = "Day %d  %s  Trust %d  Promises %d  Bonds %d" % [
		Clock.day,
		Clock.phase.to_upper(),
		GameState.trust,
		GameState.promises.size(),
		GameState.bonds.size(),
	]
