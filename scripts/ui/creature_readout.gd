extends Label

func _physics_process(_delta: float) -> void:
	text = "Creatures %d   Sleepers %d   Lean %s   FPS %d" % [
		get_tree().get_nodes_in_group("creatures").size(),
		GameState.sleepers.size(),
		"ON" if _leaning() else "-",
		Engine.get_frames_per_second(),
	]

func _leaning() -> bool:
	var keeper := get_node_or_null("../../../Maren")
	return keeper != null and keeper.shadow_lean().length() > 0.1
