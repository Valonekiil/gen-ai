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
const LEVEL_TIME_LIMIT := 60.0
const STAR_SCENE := "res://Scene/Star.tscn"
const STAR_ICON_PATH := "res://Assets/sprites/Star.png"
const FONT_PATH := "res://Assets/TitanOne-Regular.ttf"

var elapsed: float = 0.0
var star_collected: bool = false
var level_stars: int = 0
var _finished: bool = false
var _hud_timer: Label = null
var _star_icons: Array[TextureRect] = []

# Urutan level siklik: level terakhir kembali ke level pertama
const LEVEL_SEQUENCE := [
	"res://levels/Lvl_0.tscn",
	"res://levels/Lvl_1.tscn",
	"res://levels/Lvl_2.tscn",
	"res://levels/Lvl_3.tscn",
]

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

	# Timer & bintang koleksi
	_setup_hud()
	_spawn_star()
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
	print("[Level] Selesai: ", scene_file_path, " bintang=", level_stars, " waktu=", _format_time(elapsed))
	var sb := get_node_or_null("/root/SignalBus")
	if sb:
		sb.level_completed.emit(scene_file_path, level_stars)
	_update_hud()
	_go_to_next_level()

# --- Timer & Bintang: implementasi ---

func _process(delta: float) -> void:
	if _transitioning:
		return
	elapsed += delta
	_update_hud()

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
	if elapsed <= LEVEL_TIME_LIMIT:
		s += 1
	return s

func _format_time(t: float) -> String:
	var total := int(max(0.0, t))
	return "%02d:%02d" % [total / 60, total % 60]

func _setup_hud() -> void:
	var ui := get_node_or_null("UI")
	if not ui:
		return
	var font: Font = load(FONT_PATH)

	_hud_timer = Label.new()
	_hud_timer.name = "TimerLabel"
	_hud_timer.position = Vector2(20, 150)
	if font:
		_hud_timer.add_theme_font_override("font", font)
	_hud_timer.add_theme_font_size_override("font_size", 28)
	ui.add_child(_hud_timer)

	var row := HBoxContainer.new()
	row.name = "StarsRow"
	row.position = Vector2(20, 200)
	row.add_theme_constant_override("separation", 6)
	var tex: Texture2D = load(STAR_ICON_PATH)
	for i in 3:
		var tr := TextureRect.new()
		tr.name = "Star%d" % (i + 1)
		tr.texture = tex
		tr.custom_minimum_size = Vector2(48, 48)
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.modulate = Color(0.35, 0.35, 0.35)
		row.add_child(tr)
		_star_icons.append(tr)
	ui.add_child(row)
	_update_hud()

func _update_hud() -> void:
	if _hud_timer:
		var remaining: float = max(0.0, LEVEL_TIME_LIMIT - elapsed)
		_hud_timer.text = "SISA WAKTU %s" % _format_time(remaining)
	for i in _star_icons.size():
		var lit := false
		match i:
			0: lit = _finished          # bintang 1: selesai level
			1: lit = star_collected     # bintang 2: ambil bintang
			2: lit = elapsed <= LEVEL_TIME_LIMIT  # bintang 3: dalam batas waktu
		_star_icons[i].modulate = Color(1, 1, 1) if lit else Color(0.35, 0.35, 0.35)

# Bintang dipasang acak di sel kosong milik RealityA atau RealityB
func _spawn_star() -> void:
	var reality: String = "A" if randi() % 2 == 0 else "B"
	var terrain: TileMapLayer = terrain_a if reality == "A" else terrain_b
	var parent: Node2D = reality_a if reality == "A" else reality_b
	if not terrain or not parent:
		return
	var free: Array[Vector2i] = []
	for cell in terrain.get_used_cells():
		var td: TileData = terrain.get_cell_tile_data(cell)
		if td == null or td.get_collision_polygons_count(0) == 0:
			free.append(cell)
	if free.is_empty():
		return
	var cell: Vector2i = free[randi() % free.size()]
	var star: Area2D = load(STAR_SCENE).instantiate()
	star.reality = reality
	star.position = terrain.map_to_local(cell)
	parent.add_child(star)
	print("[Level] Bintang dipasang di realita ", reality, " cell ", cell)

func _get_next_level_path() -> String:
	var idx := LEVEL_SEQUENCE.find(scene_file_path)
	# Scene di luar urutan (mis. Lvl_test) dianggap tidak punya level lanjutan -> mulai dari Lvl_0
	if idx == -1:
		return LEVEL_SEQUENCE[0]
	return LEVEL_SEQUENCE[(idx + 1) % LEVEL_SEQUENCE.size()]

func _preload_next_level() -> void:
	var st := ResourceLoader.load_threaded_get_status(_get_next_level_path())
	if st == ResourceLoader.THREAD_LOAD_IN_PROGRESS or st == ResourceLoader.THREAD_LOAD_LOADED:
		return
	ResourceLoader.load_threaded_request(_get_next_level_path())

func _go_to_next_level() -> void:
	var next_path := _get_next_level_path()
	print("[Level] Memuat: ", next_path)
	# Deferred: body_entered adalah physics callback, membuang scene di dalamnya
	# menyebabkan error "Removing a CollisionObject node during a physics callback"
	get_tree().call_deferred("change_scene_to_file", next_path)

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
