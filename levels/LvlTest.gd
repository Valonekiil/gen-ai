# LvlTest.gd
# Test level playable: movement + reality switch
extends Node2D

@onready var reality_a: Node2D = $RealityA
@onready var reality_b: Node2D = $RealityB
@onready var terrain_a: TileMapLayer = $RealityA/TerrainA
@onready var terrain_b: TileMapLayer = $RealityB/TerrainB
@onready var character: CharacterBody2D = $Character
@onready var spawn: Node2D = $Spawner
@onready var reality_manager: Node = $RealityManager
@onready var pip_viewport: SubViewport = $UI/PiPViewport/SubViewport
@onready var pip_camera: Camera2D = $UI/PiPViewport/SubViewport/PipCamera
@onready var phcam: Camera2D = $phcam

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

func _on_character_switched(new_active: String, _previous: String) -> void:
	_set_reality_active(new_active)

func _set_reality_active(active: String) -> void:
	var a_active := active == "A"
	reality_a.visible = a_active
	reality_b.visible = not a_active

	# Matikan collision & proses realita non-aktif
	terrain_a.collision_enabled = a_active
	terrain_b.collision_enabled = not a_active

	reality_a.process_mode = Node.PROCESS_MODE_INHERIT if a_active else Node.PROCESS_MODE_DISABLED
	reality_b.process_mode = Node.PROCESS_MODE_DISABLED if a_active else Node.PROCESS_MODE_INHERIT
