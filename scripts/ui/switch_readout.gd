extends Label

func _physics_process(_delta: float) -> void:
	var switcher := get_node_or_null("../../../KeeperSwitch")
	if switcher == null:
		return
	var active: Node = switcher.active_keeper()
	text = "Active %s   Maren %d%%   Ivo %d%%   Beam %s" % [
		active.name if active != null else "-",
		_shadow_percent(get_node_or_null("../../../Maren")),
		_shadow_percent(get_node_or_null("../../../Ivo")),
		_beam_mode(),
	]

func _shadow_percent(keeper: Node) -> int:
	if keeper == null:
		return 0
	var shadow: Node = keeper.get_node_or_null("ShadowComponent")
	return int(round(float(shadow.value) * 100.0)) if shadow != null else 0

func _beam_mode() -> String:
	var beam := get_node_or_null("../../../Lighthouse/Beam")
	if beam == null:
		return "-"
	return "AUTO" if (beam.operator != null and not beam.manual_control) else "MANUAL"
