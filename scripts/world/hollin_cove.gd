extends Node2D

const WALKER_SCENE := preload("res://scenes/creatures/walker.tscn")
const LURKER_SCENE := preload("res://scenes/creatures/lurker.tscn")
const WORLD_SIZE := Vector2(1280, 720)
const WALL_THICKNESS := 16.0

@export var spawning_enabled := true
@export var walker_spawn_points: Array[Vector2] = [Vector2(70, 170), Vector2(1210, 150), Vector2(1180, 570)]
@export var lurker_spawn_points: Array[Vector2] = [Vector2(1040, 590), Vector2(420, 130), Vector2(90, 550)]

var wave := 0
var spawn_elapsed := 0.0
var creature_serial := 0

var _maren: Node
var _ivo: Node
var _switcher: Node
var _camera: Camera2D
var _stats: Node
var _summary: Node
var _text_box: Node
var _initial_states := {}
var _toast_left := 0.0

@onready var toast_label: Label = $UI/Controls/Toast
@onready var nightfall_button: Button = $UI/Controls/NightfallButton

func _ready() -> void:
	add_to_group("slice")
	_maren = $Maren
	_ivo = $Ivo
	_switcher = $KeeperSwitch
	_camera = $Camera2D
	_stats = $NightStats
	_summary = $UI/DawnSummary
	_text_box = $UI/TextBox
	_build_collision()
	_remember_initial_states()
	_maren.interacted.connect(_on_keeper_interacted)
	_ivo.interacted.connect(_on_keeper_interacted)
	nightfall_button.pressed.connect(_skip_to_night)
	Events.night_started.connect(_on_night_started)
	Events.dawn.connect(_on_dawn)
	var args := OS.get_cmdline_args() + OS.get_cmdline_user_args()
	if args.has("--m10-load") and SaveSystem.has_save():
		# Load before the first tick without adding children to a busy parent.
		get_tree().paused = true
		_load_on_start.call_deferred()
	else:
		reset_slice()

func _load_on_start() -> void:
	SaveSystem.load_game()
	get_tree().paused = false

func _physics_process(delta: float) -> void:
	nightfall_button.visible = Clock.phase == Clock.PHASE_DAY
	var dialogue := get_tree().get_first_node_in_group("dialogue_boxes")
	nightfall_button.disabled = dialogue != null and dialogue.is_open()
	if _toast_left > 0.0:
		_toast_left -= delta
		toast_label.visible = _toast_left > 0.0
	if not spawning_enabled or Clock.phase != Clock.PHASE_NIGHT:
		return
	spawn_elapsed += delta * Clock.time_scale
	var interval := float(Data.require_value("slice.spawn_interval"))
	if spawn_elapsed >= interval:
		spawn_elapsed = maxf(0.0, spawn_elapsed - interval)
		spawn_wave()

func reset_slice() -> void:
	clear_transients()
	GameState.trust = 0
	GameState.bonds.clear()
	GameState.inventory.clear()
	GameState.flags.clear()
	GameState.sleepers.clear()
	GameState.sleepers.append("absent")
	GameState.promises.clear()
	GameState.houses.clear()
	GameState.last_dawn = {}
	for house in get_tree().get_nodes_in_group("houses"):
		GameState.houses[String(house.get("npc_id"))] = "home"
	Clock.day = 1
	Clock.phase = Clock.PHASE_DAY
	Clock.game_seconds = 0.0
	Clock.phase_elapsed = 0.0
	Clock.dawnglass_charge = 0.0
	Rng.seed_rng(int(Data.require_value("slice.seed")))
	wave = 0
	spawn_elapsed = 0.0
	creature_serial = 0
	for id in _initial_states:
		var entry: Dictionary = _initial_states[id]
		var actor: Node = entry["node"]
		if is_instance_valid(actor) and actor.has_method("restore_state"):
			actor.restore_state(entry["state"])
	_switcher.select_keeper(_maren)
	_camera.global_position = _maren.global_position
	_stats.reset()
	_summary.dismiss()
	_summary.last_report = {}
	Events.state_loaded.emit()

func spawn_wave() -> void:
	var maximum := int(Data.require_value("slice.max_creatures"))
	if get_tree().get_nodes_in_group("creatures").size() >= maximum:
		return
	_spawn_creatures(WALKER_SCENE, "Walker", walker_spawn_points, int(Data.require_value("slice.walkers_per_wave")))
	_spawn_creatures(LURKER_SCENE, "Lurker", lurker_spawn_points, int(Data.require_value("slice.lurkers_per_wave")))
	wave += 1

func clear_transients() -> void:
	for group_name in ["creatures", "glint_bursts"]:
		for node in get_tree().get_nodes_in_group(group_name):
			var parent := node.get_parent()
			if parent != null:
				parent.remove_child(node)
				node.queue_free()

func capture_state() -> Dictionary:
	return {
		"id": "slice",
		"wave": wave,
		"spawn_elapsed": spawn_elapsed,
		"creature_serial": creature_serial,
	}

func restore_state(state: Dictionary) -> void:
	wave = int(state.get("wave", wave))
	spawn_elapsed = float(state.get("spawn_elapsed", spawn_elapsed))
	creature_serial = int(state.get("creature_serial", creature_serial))

func _spawn_creatures(scene: PackedScene, kind: String, points: Array[Vector2], count: int) -> void:
	if points.is_empty():
		return
	for _index in range(count):
		if get_tree().get_nodes_in_group("creatures").size() >= int(Data.require_value("slice.max_creatures")):
			return
		creature_serial += 1
		var creature := scene.instantiate()
		creature.name = "%s_%d_%d" % [kind, Clock.day, creature_serial]
		get_tree().current_scene.add_child(creature)
		creature.global_position = points[Rng.randi_range(0, points.size() - 1)]

func _build_collision() -> void:
	var half := WALL_THICKNESS * 0.5
	_add_boundary("TopWall", Vector2(WORLD_SIZE.x * 0.5, half), Vector2(WORLD_SIZE.x, WALL_THICKNESS))
	_add_boundary("BottomWall", Vector2(WORLD_SIZE.x * 0.5, WORLD_SIZE.y - half), Vector2(WORLD_SIZE.x, WALL_THICKNESS))
	_add_boundary("LeftWall", Vector2(half, WORLD_SIZE.y * 0.5), Vector2(WALL_THICKNESS, WORLD_SIZE.y))
	_add_boundary("RightWall", Vector2(WORLD_SIZE.x - half, WORLD_SIZE.y * 0.5), Vector2(WALL_THICKNESS, WORLD_SIZE.y))
	var sign_shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 16.0
	sign_shape.shape = circle
	sign_shape.position = Vector2(0, -34)
	$Notice.add_child(sign_shape)

func _add_boundary(boundary_name: String, at: Vector2, size: Vector2) -> void:
	var wall := StaticBody2D.new()
	wall.name = boundary_name
	wall.position = at
	wall.collision_layer = 1
	wall.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	shape.shape = rectangle
	wall.add_child(shape)
	add_child(wall)

func _remember_initial_states() -> void:
	for group_name in ["persons", "townsfolk", "houses"]:
		for node in get_tree().get_nodes_in_group(group_name):
			if not node.has_method("capture_state"):
				continue
			var state: Dictionary = node.capture_state()
			_initial_states[String(state.get("id", node.name))] = {"node": node, "state": state.duplicate(true)}

func _on_night_started() -> void:
	wave = 0
	spawn_elapsed = 0.0
	if spawning_enabled:
		spawn_wave()

func _on_dawn() -> void:
	clear_transients()

func _on_keeper_interacted(text: String) -> void:
	_text_box.show_text(text)

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.physical_keycode == KEY_F5:
		_save()
		get_viewport().set_input_as_handled()
	elif key.physical_keycode == KEY_F9:
		_load()
		get_viewport().set_input_as_handled()
	elif key.physical_keycode == KEY_N:
		_skip_to_night()
		get_viewport().set_input_as_handled()

func _skip_to_night() -> void:
	if Clock.phase != Clock.PHASE_DAY or _summary.visible:
		return
	var dialogue := get_tree().get_first_node_in_group("dialogue_boxes")
	if dialogue != null and dialogue.is_open():
		return
	var dusk_left := float(Data.require_value("slice.nightfall_dusk_seconds"))
	if Clock.skip_day(dusk_left):
		nightfall_button.visible = false
		_toast("NIGHTFALL")

func _save() -> void:
	if SaveSystem.save_game():
		_toast("SAVED")
	else:
		_toast("SAVE FAILED")

func _load() -> void:
	if not SaveSystem.has_save():
		_toast("NO SAVE")
		return
	if SaveSystem.load_game():
		_toast("LOADED")
	else:
		_toast("LOAD FAILED")

func _toast(text: String) -> void:
	toast_label.text = text
	toast_label.visible = true
	_toast_left = float(Data.require_value("slice.toast_seconds"))
