# LvlTest.gd
# Test level playable: movement + reality switch
extends Node2D

@onready var reality_a: Node2D = $RealityA
@onready var reality_b: Node2D = $RealityB
@onready var terrain_a: TileMapLayer = $RealityA/TerrainA
@onready var terrain_b: TileMapLayer = $RealityB/TerrainB
@onready var walls_a: StaticBody2D = get_node_or_null("RealityA/WallsA")
@onready var walls_b: StaticBody2D = get_node_or_null("RealityB/WallsB")
@onready var character: CharacterBody2D = $Character
@onready var spawn: Node2D = $Spawner
@onready var reality_manager: Node = $RealityManager
@onready var pip_viewport: SubViewport = $UI/PiPViewport/SubViewport
@onready var pip_camera: Camera2D = $UI/PiPViewport/SubViewport/PipCamera
@onready var phcam: Camera2D = $phcam

var _transitioning: bool = false

# --- Timer & Bintang ---
# Batas waktu (detik) sebelum bintang ke-3 hilang. Bisa diatur per level di Inspector.
@export var level_time_limit: float = 60.0
const STAR_ICON_FILLED := "res://Assets/UI/Component/GStar_UI.png"
const STAR_ICON_EMPTY := "res://Assets/UI/Component/PStar_UI.png"

var elapsed: float = 0.0
var star_collected: bool = false
var level_stars: int = 0
var _finished: bool = false
# Bintang langsung memakai node yang ada di scene level (UI/HBoxContainer)
@onready var _star1: TextureRect = $UI/HBoxContainer/Star1
@onready var _star2: TextureRect = $UI/HBoxContainer/Star2
@onready var _star3_bar: TextureProgressBar = $UI/HBoxContainer/TextureProgressBar
@onready var _pause_button: TextureButton = $UI/PauseButton

# Urutan level siklik sekarang di SignalBus (dipakai juga LevelComplete)
const LEVEL_COMPLETE := "res://ui/LevelComplete.tscn"
const PAUSED_SCENE := "res://ui/Paused.tscn"

func _ready() -> void:
	# Wiring RealityManager
	reality_manager.character_a = character
	reality_manager.character_b = character
	reality_manager.terrain_a = terrain_a
	reality_manager.terrain_b = terrain_b

	var cam_a := get_node_or_null("RealityA/CameraA")
	if cam_a:
		reality_manager.camera_a = cam_a
	var cam_b := get_node_or_null("RealityB/CameraB")
	if cam_b:
		reality_manager.camera_b = cam_b

	# Initial state: A aktif, B mati
	_set_reality_active("A")
	character.position = spawn.position

	# Listen to switch
	var sb := get_node_or_null("/root/SignalBus")
	if sb:
		sb.character_switched.connect(_on_character_switched)
	pip_viewport.world_2d = get_viewport().world_2d
	pip_camera.global_position = phcam.global_position
	pip_camera.zoom = phcam.zoom

	# Wiring Button -> Door (Lvl 2)
	var door_node := get_node_or_null("Door")
	var button_node := get_node_or_null("RealityB/Button")
	if button_node and door_node:
		button_node.target_door_path = door_node.get_path()
		button_node.reality_manager = reality_manager

	# Exit transition
	var exit_node := get_node_or_null("Exit")
	if exit_node:
		exit_node.body_entered.connect(_on_exit_entered)

	# Timer & bintang
	_update_hud()
	if _pause_button:
		_pause_button.pressed.connect(_pause)
	if sb:
		sb.star_collected.connect(_on_star_collected)

	# Preload level berikutnya di background supaya transisi tidak lag
	# (tekstur level ~17MB/lembar; load sinkron bikin freeze ~2-3 detik)
	# Delay sebentar: load_threaded_request saat scene sedang diganti kadang gagal parse
	var timer := get_tree().create_timer(0.5)
	timer.timeout.connect(_preload_next_level)

func _on_exit_entered(body: Node) -> void:
	if _transitioning:
		return
	if not (body is CharacterController):
		return
	_transitioning = true
	_finished = true
	level_stars = _compute_stars()
	# Simpan hasil untuk scene LevelComplete (reusable di semua level)
	SignalBus.last_completed_level = scene_file_path
	SignalBus.last_completed_stars = level_stars
	SignalBus.last_completed_time = elapsed
	GameProgress.record_completion(scene_file_path, level_stars)
	print("[Level] Selesai: ", scene_file_path, " bintang=", level_stars, " waktu=", _format_time(elapsed))
	var sb := get_node_or_null("/root/SignalBus")
	if sb:
		sb.level_completed.emit(scene_file_path, level_stars)
	_update_hud()
	_go_to_level_complete()

# --- Timer & Bintang: implementasi ---

func _process(delta: float) -> void:
	if _transitioning:
		return
	elapsed += delta
	_update_hud()

# --- Pause ---
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_P:
		get_viewport().set_input_as_handled()
		_pause()

func _pause() -> void:
	if _transitioning or get_tree().paused:
		return
	get_tree().paused = true
	var paused: Control = load(PAUSED_SCENE).instantiate()
	paused.process_mode = Node.PROCESS_MODE_ALWAYS
	get_node("UI").add_child(paused)

func _on_star_collected() -> void:
	if star_collected:
		return
	star_collected = true
	_update_hud()

# Bintang 1: selesai level | Bintang 2: ambil bintang | Bintang 3: dentro batas waktu
func _compute_stars() -> int:
	var s := 0
	if _finished:
		s += 1
	if star_collected:
		s += 1
	if elapsed <= level_time_limit:
		s += 1
	return s

func _format_time(t: float) -> String:
	var total := int(max(0.0, t))
	return "%02d:%02d" % [total / 60, total % 60]

func _update_hud() -> void:
	var filled: Texture2D = load(STAR_ICON_FILLED)
	var empty: Texture2D = load(STAR_ICON_EMPTY)
	if _star1:
		_star1.texture = filled if _finished else empty
	if _star2:
		_star2.texture = filled if star_collected else empty
	if _star3_bar:
		# Bintang 3 = progress bar: penuh saat mulai, kosong saat lewat batas waktu
		var frac: float = 0.0
		if level_time_limit > 0.0:
			frac = clampf((level_time_limit - elapsed) / level_time_limit, 0.0, 1.0)
		_star3_bar.value = frac * _star3_bar.max_value

func _get_next_level_path() -> String:
	return SignalBus.next_level_path(scene_file_path)

func _preload_next_level() -> void:
	var st := ResourceLoader.load_threaded_get_status(_get_next_level_path())
	if st == ResourceLoader.THREAD_LOAD_IN_PROGRESS or st == ResourceLoader.THREAD_LOAD_LOADED:
		return
	ResourceLoader.load_threaded_request(_get_next_level_path())

# Transisi ke scene LevelComplete, bukan langsung ke level berikutnya
func _go_to_level_complete() -> void:
	print("[Level] Memuat: ", LEVEL_COMPLETE)
	get_tree().call_deferred("change_scene_to_file", LEVEL_COMPLETE)

func _on_character_switched(new_active: String, _previous: String) -> void:
	_set_reality_active(new_active)

func _set_reality_active(active: String) -> void:
	var a_active := active == "A"
	reality_a.visible = a_active
	reality_b.visible = not a_active

	# Matikan collision & proses realita non-aktif
	terrain_a.collision_enabled = a_active
	terrain_b.collision_enabled = not a_active

	# StaticBody2D tembok tidak ikut tertoggle otomatis, jadi toggle manual.
	# Opsional: scene tanpa WallsA/WallsB (level lain) dilewati.
	if walls_a:
		walls_a.collision_layer = 1 if a_active else 0
	if walls_b:
		walls_b.collision_layer = 0 if a_active else 1

	reality_a.process_mode = Node.PROCESS_MODE_INHERIT if a_active else Node.PROCESS_MODE_DISABLED
	reality_b.process_mode = Node.PROCESS_MODE_DISABLED if a_active else Node.PROCESS_MODE_INHERIT
