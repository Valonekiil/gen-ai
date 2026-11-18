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

func _on_exit_entered(body: Node) -> void:
	if _transitioning:
		return
	if not (body is CharacterController):
		return
	_transitioning = true
	_go_to_next_level()

func _go_to_next_level() -> void:
	var current_path := scene_file_path
	var next_path := ""
	if current_path.ends_with("Lvl_1.tscn"):
		next_path = "res://levels/Lvl_2.tscn"
	elif current_path.ends_with("Lvl_2.tscn"):
		next_path = "res://levels/Lvl_3.tscn"
	if next_path == "":
		print("[Level] Tidak ada level berikutnya")
		_transitioning = false
		return
	print("[Level] Memuat: ", next_path)
	get_tree().change_scene_to_file(next_path)

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
