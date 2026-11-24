extends CanvasLayer

@onready var speaker_label: Label = $Panel/Speaker
@onready var body_label: Label = $Panel/Body
@onready var choices_label: Label = $Panel/Choices

var _choices: Array = []
var _npc_id := ""
var _home := Vector2.ZERO

func _ready() -> void:
	add_to_group("dialogue_boxes")
	visible = false

func open(npc_id: String) -> bool:
	var path := "res://data/dialogue/%s.json" % npc_id
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Missing dialogue data: " + path)
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("Malformed dialogue data: " + path)
		return false
	_npc_id = npc_id
	_home = _npc_home(npc_id)
	_choices = parsed.get("choices", [])
	speaker_label.text = String(parsed.get("speaker", npc_id))
	body_label.text = String(parsed.get("text", ""))
	var lines := PackedStringArray()
	for index in range(_choices.size()):
		var choice: Dictionary = _choices[index]
		lines.append("%d. %s" % [index + 1, String(choice.get("text", ""))])
	choices_label.text = "\n".join(lines)
	visible = true
	return true

func choose(index: int) -> bool:
	if not visible or index < 0 or index >= _choices.size():
		return false
	var choice: Dictionary = _choices[index]
	if bool(choice.get("promise", false)):
		if Clock.phase == Clock.PHASE_NIGHT:
			body_label.text = "It is too late tonight."
			return false
		var keeper := _active_keeper()
		var board := get_tree().get_first_node_in_group("promise_board")
		if keeper != null and board != null:
			board.accept(_npc_id, speaker_label.text, _home, keeper)
	GameState.trust += int(choice.get("trust", 0))
	var bond := int(choice.get("bond", 0))
	if bond != 0:
		GameState.bonds[_npc_id] = int(GameState.bonds.get(_npc_id, 0)) + bond
	if choice.has("flag"):
		GameState.flags[String(choice.get("flag"))] = true
	close()
	return true

func close() -> void:
	visible = false

func is_open() -> bool:
	return visible

func speaker_text() -> String:
	return speaker_label.text

func body_text() -> String:
	return body_label.text

func _unhandled_key_input(event: InputEvent) -> void:
	if not visible:
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var index := int(key.keycode) - int(KEY_1)
	if index >= 0 and index < _choices.size():
		choose(index)
		get_viewport().set_input_as_handled()

func _active_keeper() -> Node:
	var switcher := get_tree().get_first_node_in_group("keeper_switcher")
	if switcher != null and switcher.has_method("active_keeper"):
		return switcher.active_keeper()
	var keepers := get_tree().get_nodes_in_group("keepers")
	if keepers.is_empty():
		return null
	return keepers[0]

func _npc_home(npc_id: String) -> Vector2:
	for node in get_tree().get_nodes_in_group("townsfolk"):
		if String(node.get("npc_id")) == npc_id:
			var value = node.get("home")
			return value if value is Vector2 else Vector2.ZERO
	return Vector2.ZERO
