extends Node

const VERSION := 1
const SAVE_PATH := "user://dawn_save.json"
# JSON decimal parsing can shift a float by one ULP.
const SAVE_PRECISION := 0.000000001
const STATE_GROUPS := ["persons", "townsfolk", "houses", "slice", "creatures", "glint_bursts"]
const TRANSIENT_GROUPS := ["creatures", "glint_bursts"]

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveSystem: could not open %s for writing" % SAVE_PATH)
		return false
	file.store_string(_canonical(capture_state()))
	file.close()
	return true

func load_game() -> bool:
	if not has_save():
		push_error("SaveSystem: no save file at %s" % SAVE_PATH)
		return false
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not parsed is Dictionary:
		push_error("SaveSystem: save root must be an object")
		return false
	var payload: Dictionary = parsed
	if int(payload.get("version", 0)) != VERSION:
		push_error("SaveSystem: unsupported save version")
		return false
	_restore_game_state(payload.get("game_state", {}))
	var clock_state: Dictionary = payload.get("clock", {})
	Clock.day = int(clock_state.get("day", Clock.day))
	Clock.phase = String(clock_state.get("phase", Clock.phase))
	Clock.game_seconds = float(clock_state.get("game_seconds", Clock.game_seconds))
	Clock.phase_elapsed = float(clock_state.get("phase_elapsed", Clock.phase_elapsed))
	Clock.dawnglass_charge = float(clock_state.get("dawnglass_charge", Clock.dawnglass_charge))
	var rng_state: Dictionary = payload.get("rng", {})
	Rng.generator.seed = int(rng_state.get("seed", Rng.generator.seed))
	var saved_rng_state: Variant = rng_state.get("state", Rng.generator.state)
	Rng.generator.state = int(saved_rng_state)
	_restore_active_keeper(String(payload.get("active_keeper", "")))
	_restore_actors(payload.get("actors", {}))
	var stats := get_tree().get_first_node_in_group("night_stats")
	if stats != null and stats.has_method("restore_state"):
		stats.restore_state(payload.get("night", {}))
	Events.state_loaded.emit()
	return true

func canonical_state() -> String:
	return _canonical(capture_state())

func capture_state() -> Dictionary:
	var promises: Array[Dictionary] = []
	for raw in GameState.promises:
		var entry: Dictionary = (raw as Dictionary).duplicate(true)
		var home: Variant = entry.get("home", null)
		if home is Vector2:
			entry["home"] = [home.x, home.y]
		promises.append(entry)
	var game_state := {
		"trust": GameState.trust,
		"bonds": GameState.bonds.duplicate(true),
		"inventory": GameState.inventory.duplicate(true),
		"flags": GameState.flags.duplicate(true),
		"sleepers": GameState.sleepers.duplicate(),
		"promises": promises,
		"houses": GameState.houses.duplicate(true),
		"last_dawn": GameState.last_dawn.duplicate(true),
	}
	var active := ""
	var switcher := get_tree().get_first_node_in_group("keeper_switcher")
	if switcher != null:
		var keeper: Node = switcher.active_keeper()
		if keeper != null and keeper.has_method("person_id"):
			active = String(keeper.person_id())
	var night := {}
	var stats := get_tree().get_first_node_in_group("night_stats")
	if stats != null and stats.has_method("capture_state"):
		night = stats.capture_state()
	return {
		"version": VERSION,
		"game_state": game_state,
		"clock": {
			"day": Clock.day,
			"phase": Clock.phase,
			"game_seconds": Clock.game_seconds,
			"phase_elapsed": Clock.phase_elapsed,
			"dawnglass_charge": Clock.dawnglass_charge,
		},
		"rng": {"seed": Rng.generator.seed, "state": str(Rng.generator.state)},
		"active_keeper": active,
		"actors": _capture_actors(),
		"night": night,
	}

func _canonical(value: Dictionary) -> String:
	return JSON.stringify(_normalize(value), "\t", true, true) + "\n"

func _normalize(value: Variant) -> Variant:
	if value is bool:
		return value
	if value is int:
		return float(value)
	if value is float:
		return snappedf(value, SAVE_PRECISION)
	if value is Dictionary:
		var result := {}
		for key in value:
			result[key] = _normalize(value[key])
		return result
	if value is Array:
		var result := []
		for item in value:
			result.append(_normalize(item))
		return result
	return value

func _restore_game_state(raw: Variant) -> void:
	if not raw is Dictionary:
		return
	var state: Dictionary = raw
	GameState.trust = int(state.get("trust", 0))
	GameState.bonds = Dictionary(state.get("bonds", {})).duplicate(true)
	GameState.inventory = Dictionary(state.get("inventory", {})).duplicate(true)
	GameState.flags = Dictionary(state.get("flags", {})).duplicate(true)
	GameState.houses = Dictionary(state.get("houses", {})).duplicate(true)
	GameState.last_dawn = Dictionary(state.get("last_dawn", {})).duplicate(true)
	GameState.sleepers.clear()
	for id in state.get("sleepers", []):
		GameState.sleepers.append(String(id))
	GameState.promises.clear()
	for raw_entry in state.get("promises", []):
		if not raw_entry is Dictionary:
			continue
		var entry: Dictionary = raw_entry.duplicate(true)
		var home: Variant = entry.get("home", null)
		if home is Array and home.size() >= 2:
			entry["home"] = Vector2(float(home[0]), float(home[1]))
		GameState.promises.append(entry)

func _state_nodes() -> Array[Node]:
	var nodes: Array[Node] = []
	for group_name in STATE_GROUPS:
		for node in get_tree().get_nodes_in_group(group_name):
			if not nodes.has(node) and node.has_method("capture_state"):
				nodes.append(node)
	return nodes

func _capture_actors() -> Dictionary:
	var actors := {}
	for node in _state_nodes():
		var state: Dictionary = node.capture_state()
		actors[String(state.get("id", node.name))] = state
	return actors

func _restore_actors(raw: Variant) -> void:
	if not raw is Dictionary:
		return
	var actors: Dictionary = raw
	_clear_transients()
	for group_name in STATE_GROUPS:
		if TRANSIENT_GROUPS.has(group_name):
			continue
		for node in get_tree().get_nodes_in_group(group_name):
			if not node.has_method("capture_state"):
				continue
			var current: Dictionary = node.capture_state()
			var id := String(current.get("id", node.name))
			if actors.has(id) and node.has_method("restore_state"):
				node.restore_state(actors[id])
	for id in actors:
		var state: Variant = actors[id]
		if state is Dictionary and bool(state.get("transient", false)):
			_instantiate_actor(String(id), state)

func _clear_transients() -> void:
	for group_name in TRANSIENT_GROUPS:
		for node in get_tree().get_nodes_in_group(group_name):
			var parent := node.get_parent()
			if parent != null:
				parent.remove_child(node)
				node.queue_free()

func _instantiate_actor(id: String, state: Dictionary) -> void:
	var path := String(state.get("scene", ""))
	if not ResourceLoader.exists(path):
		push_error("SaveSystem: missing actor scene %s" % path)
		return
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("SaveSystem: could not load actor scene %s" % path)
		return
	var actor := packed.instantiate()
	actor.name = id
	get_tree().current_scene.add_child(actor)
	if actor.has_method("restore_state"):
		actor.restore_state(state)

func _restore_active_keeper(active_id: String) -> void:
	if active_id == "":
		return
	var switcher := get_tree().get_first_node_in_group("keeper_switcher")
	if switcher == null or not switcher.has_method("select_keeper"):
		return
	for keeper in get_tree().get_nodes_in_group("keepers"):
		if keeper.has_method("person_id") and String(keeper.person_id()) == active_id:
			switcher.select_keeper(keeper)
			return
