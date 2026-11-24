extends Control

@onready var keeper_label: Label = $Panel/Keeper
@onready var shadow_label: Label = $Panel/Shadow
@onready var shadow_bar: ColorRect = $Panel/ShadowBar
@onready var glint_label: Label = $Panel/Glint
@onready var dawnglass_bar: ColorRect = $Panel/DawnglassBar
@onready var time_label: Label = $Panel/Time

func _physics_process(_delta: float) -> void:
	var keeper := _active_keeper()
	if keeper == null:
		return
	keeper_label.text = String(keeper.name).to_upper()
	var shadow := keeper.get_node_or_null("ShadowComponent")
	if shadow == null:
		shadow_label.text = "SHADOW NONE"
		shadow_bar.scale.x = 0.0
	else:
		var stage := String(shadow.stage()).to_upper()
		var ratio := float(shadow.value) / maxf(float(shadow.maximum), 0.001)
		shadow_label.text = "SHADOW " + stage
		shadow_bar.scale.x = clampf(ratio, 0.0, 1.0)
		shadow_bar.self_modulate = _stage_color(stage)
	var maximum := maxi(1, int(Data.require_value("lighting.glint_charges")))
	var charges := clampi(int(keeper.get("glint_charges")), 0, maximum)
	glint_label.text = "GLINT " + _pips(charges, maximum)
	dawnglass_bar.scale.x = clampf(Clock.dawnglass_charge, 0.0, 1.0)
	time_label.text = "DAY %d · %s" % [Clock.day, Clock.phase.to_upper()]

func _active_keeper() -> Node:
	var switcher := get_tree().get_first_node_in_group("keeper_switcher")
	if switcher != null:
		return switcher.active_keeper()
	return get_tree().get_first_node_in_group("keepers")

func _pips(charges: int, maximum: int) -> String:
	var text := ""
	for index in range(maximum):
		text += "◆" if index < charges else "◇"
	return text

func _stage_color(stage: String) -> Color:
	match stage:
		"FLICKERING":
			return Color("#FFB84D")
		"FAINT":
			return Color("#E67E22")
		"GONE":
			return Color("#26354D")
	return Color("#7CA5B8")
