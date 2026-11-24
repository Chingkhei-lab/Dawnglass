extends Node

var promises_kept := 0
var promises_broken := 0
var creatures_destroyed := 0
var sleepers: Array[String] = []

func _ready() -> void:
	add_to_group("night_stats")
	Events.dusk_started.connect(_reset)
	Events.person_taken.connect(_on_person_taken)
	Events.promise_kept.connect(_on_promise_kept)
	Events.promise_broken.connect(_on_promise_broken)
	Events.creature_destroyed.connect(_on_creature_destroyed)
	_reset()

func finalize() -> Dictionary:
	var safe: Array[String] = []
	for node in _people():
		if node.has_method("is_takeable") and not node.is_takeable():
			continue
		var id := _id_for(node)
		if GameState.sleepers.has(id):
			continue
		var label := _label_for_node(node)
		if not safe.has(label):
			safe.append(label)
	safe.sort()
	var asleep: Array[String] = []
	for id in GameState.sleepers:
		var label := _label_for_id(id)
		if not asleep.has(label):
			asleep.append(label)
	asleep.sort()
	sleepers = GameState.sleepers.duplicate()
	return {
		"day": Clock.day,
		"safe": safe,
		"sleepers": asleep,
		"promises_kept": promises_kept,
		"promises_broken": promises_broken,
		"creatures_destroyed": creatures_destroyed,
	}

func capture_state() -> Dictionary:
	return {
		"promises_kept": promises_kept,
		"promises_broken": promises_broken,
		"creatures_destroyed": creatures_destroyed,
		"sleepers": sleepers.duplicate(),
	}

func restore_state(state: Dictionary) -> void:
	promises_kept = int(state.get("promises_kept", promises_kept))
	promises_broken = int(state.get("promises_broken", promises_broken))
	creatures_destroyed = int(state.get("creatures_destroyed", creatures_destroyed))
	sleepers.clear()
	for id in state.get("sleepers", []):
		sleepers.append(String(id))

func _reset() -> void:
	promises_kept = 0
	promises_broken = 0
	creatures_destroyed = 0
	sleepers = GameState.sleepers.duplicate()

func _on_person_taken() -> void:
	sleepers = GameState.sleepers.duplicate()

func _on_promise_kept() -> void:
	promises_kept += 1

func _on_promise_broken() -> void:
	promises_broken += 1

func _on_creature_destroyed() -> void:
	if Clock.phase == Clock.PHASE_DUSK or Clock.phase == Clock.PHASE_NIGHT:
		creatures_destroyed += 1

func _people() -> Array[Node]:
	var people: Array[Node] = []
	people.append_array(get_tree().get_nodes_in_group("persons"))
	for node in get_tree().get_nodes_in_group("townsfolk"):
		if not people.has(node):
			people.append(node)
	return people

func _id_for(node: Node) -> String:
	if node.has_method("person_id"):
		return String(node.person_id())
	return String(node.name)

func _label_for_node(node: Node) -> String:
	if "display_name" in node:
		var display := String(node.get("display_name"))
		if display != "":
			return display
	return _id_for(node).capitalize()

func _label_for_id(id: String) -> String:
	for node in _people():
		if _id_for(node) == id:
			return _label_for_node(node)
	return id.capitalize()
