extends Node

func _ready() -> void:
	add_to_group("promise_board")
	Events.dawn.connect(_on_dawn)

func accept(npc_id: String, display_name: String, home: Vector2, keeper: Node) -> bool:
	if Clock.phase == Clock.PHASE_NIGHT:
		return false
	for entry: Dictionary in GameState.promises:
		if String(entry.get("npc_id", "")) == npc_id:
			return false
	GameState.promises.append({
		"npc_id": npc_id,
		"name": display_name,
		"home": home,
		"keeper_name": String(keeper.name),
		"lit": 0.0,
		"required": float(Data.require_value("promise.lit_seconds")),
	})
	return true

func _physics_process(delta: float) -> void:
	if Clock.phase != Clock.PHASE_NIGHT:
		return
	for entry: Dictionary in GameState.promises:
		if _home_lit(entry.get("home", Vector2.ZERO)):
			entry["lit"] = float(entry.get("lit", 0.0)) + delta

func _home_lit(home: Vector2) -> bool:
	var radius := float(Data.require_value("promise.lit_radius"))
	for node in get_tree().get_nodes_in_group("keepers"):
		var keeper := node as Node2D
		if keeper != null and keeper.has_method("is_lantern_on") and keeper.is_lantern_on():
			if keeper.global_position.distance_to(home) <= radius:
				return true
	for field in get_tree().get_nodes_in_group("daylight_fields"):
		if field.has_method("is_point_lit") and field.is_point_lit(home):
			return true
	return false

func _on_dawn() -> void:
	for entry: Dictionary in GameState.promises:
		var kept := float(entry.get("lit", 0.0)) >= float(entry.get("required", 0.0))
		_settle(entry, kept)
	GameState.promises.clear()

func _settle(entry: Dictionary, kept: bool) -> void:
	var trust_path := "promise.trust_kept" if kept else "promise.trust_broken"
	GameState.trust += int(Data.require_value(trust_path))
	if kept:
		var keeper := _keeper_named(String(entry.get("keeper_name", "")))
		if keeper != null:
			var shadow := keeper.get_node_or_null("ShadowComponent")
			if shadow != null:
				shadow.maximum = minf(1.0, float(shadow.maximum) + float(Data.require_value("promise.max_shadow_bonus")))
		Events.promise_kept.emit()
	else:
		Events.promise_broken.emit()

func _keeper_named(keeper_name: String) -> Node:
	for node in get_tree().get_nodes_in_group("keepers"):
		if String(node.name) == keeper_name:
			return node
	return null
