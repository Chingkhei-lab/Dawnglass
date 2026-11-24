extends Label

@export var keeper_path: NodePath = ^"../../../Maren"

func _physics_process(_delta: float) -> void:
	var keeper := get_node_or_null(keeper_path)
	if keeper == null:
		return
	var shadow := keeper.get_node_or_null("ShadowComponent")
	if shadow == null:
		return
	var lantern := keeper.get_node_or_null("Lantern") as PointLight2D
	text = "Shadow %d%%  max %d%%  (%s)    Glint %d    Lantern %s    %s" % [
		roundi(shadow.value * 100.0),
		roundi(shadow.maximum * 100.0),
		shadow.stage().to_upper(),
		keeper.glint_charges,
		"ON" if lantern != null and lantern.enabled else "OFF",
		Clock.phase.to_upper(),
	]
