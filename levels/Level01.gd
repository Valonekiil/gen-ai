# Level01.gd
# Greybox Level 1 — Room 1A (Reality A) + Room 1B (Reality B)
# S1-05: Level 1 Design §3–4; Arsitektur §2, §11.1
# Hanya greybox + kamera fixed. Tanpa Plate, Door, Link.

extends Node2D

const TILE_SIZE := 32

# Layout Room 1A (16 kolom × 12 baris)
var LAYOUT_A: Array[String] = [
	"################",
	"#S.............#",
	"#..............#",
	"#....####......#",
	"#....#..#......#",
	"#....#..#......#",
	"#....####......#",
	"#..............#",
	"#......P.......#",  # P = Plate di posisi (8,7)
	"#..............#",
	"#............E.#",
	"################",
]

# Layout Room 1B (16 kolom × 12 baris)
var LAYOUT_B: Array[String] = [
	"################",
	"#S.............#",
	"#..............#",
	"########D#######",# D = Door di posisi (3,8)
	"#..............#",
	"#..............#",
	"#..............#",
	"#..............#",
	"#..............#",
	"#............E.#",
	"################",
]

@onready var reality_a: Node2D = $RealityA
@onready var reality_b: Node2D = $RealityB
@onready var character_a_node: CharacterBody2D = $RealityA/CharacterA
@onready var character_b_node: CharacterBody2D = $RealityB/CharacterB

func _ready() -> void:
	var tileset := _create_tileset()

	var terrain_a := get_node("RealityA/TerrainA")
	terrain_a.tile_set = tileset
	_populate_tilemap(terrain_a, LAYOUT_A)

	var terrain_b := get_node("RealityB/TerrainB")
	terrain_b.tile_set = tileset
	_populate_tilemap(terrain_b, LAYOUT_B)

	# Wiring @export references untuk RealityManager, CameraDirector, UIDirector
	var reality_manager := get_node("RealityManager")
	reality_manager.character_a = character_a_node
	reality_manager.character_b = character_b_node
	reality_manager.camera_a = get_node("RealityA/CameraA")
	reality_manager.camera_b = get_node("RealityB/CameraB")

	var camera_director := get_node("CameraDirector")
	camera_director.pip_camera = get_node_or_null("UI/PiPViewport/SubViewport/PiPCamera")
	camera_director.camera_a = get_node("RealityA/CameraA")
	camera_director.camera_b = get_node("RealityB/CameraB")

	var ui_director := get_node("UIDirector")
	ui_director.reality_label = get_node("UI/RealityIndicator")
	ui_director.cooldown_bar = get_node("UI/SwitchCooldownBar")
	ui_director.reality_a_root = reality_a
	ui_director.reality_b_root = reality_b
	ui_director.reality_manager = reality_manager
	ui_director._update_ui("A")

	# Spawn Plate di Room 1A di posisi (8,7) - baris 8, kolom 7
	# Posisi tile (col=8, row=7) -> world = (8*32+16, 7*32+16) = (272, 240)
	var plate_node = InteractableBase.new()
	plate_node.link_id = "plate_1a"
	plate_node.position = Vector2(272, 240)
	get_node("RealityA").add_child(plate_node)

	# Connect switch handler
	var sb := get_node_or_null("/root/SignalBus")
	if sb:
		sb.character_switched.connect(_on_character_switched)

func _on_character_switched(new_active: String, _previous: String) -> void:
	var a_active := new_active == "A"

	# Toggle visibility reality
	reality_a.visible = a_active
	reality_b.visible = not a_active

	# Toggle visibility karakter sesuai reality aktif
	character_a_node.visible = a_active
	character_b_node.visible = not a_active

	# Switch kamera utama ke reality yang aktif
	var cam_a := get_node_or_null("RealityA/CameraA")
	var cam_b := get_node_or_null("RealityB/CameraB")
	if a_active and cam_a:
		cam_a.make_current()
	elif not a_active and cam_b:
		cam_b.make_current()

	# Pindahkan karakter aktif ke spawn posisi reality tersebut
	var active_char := _get_active_char(new_active)
	if active_char:
		var spawn_node := get_node_or_null("Reality" + new_active + "/Spawn" + new_active)
		if spawn_node:
			active_char.global_position = spawn_node.global_position
		active_char.velocity = Vector2.ZERO

func _get_active_char(reality: String) -> CharacterBody2D:
	if reality == "A":
		return character_a_node
	return character_b_node

func _create_tileset() -> TileSet:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	# Wall source (source id 0)
	var wall_img := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	wall_img.fill(Color(0.545, 0.353, 0.169, 1.0))  # #8B5A2B
	var wall_tex := ImageTexture.create_from_image(wall_img)
	var wall_source := TileSetAtlasSource.new()
	wall_source.texture = wall_tex
	wall_source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	wall_source.create_tile(Vector2i(0, 0))
	tileset.add_source(wall_source, 0)

	# Floor source (source id 1)
	var floor_img := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	floor_img.fill(Color(0.910, 0.784, 0.478, 1.0))  # #E8C87A
	var floor_tex := ImageTexture.create_from_image(floor_img)
	var floor_source := TileSetAtlasSource.new()
	floor_source.texture = floor_tex
	floor_source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	floor_source.create_tile(Vector2i(0, 0))
	tileset.add_source(floor_source, 1)

	return tileset

func _populate_tilemap(tilemap: TileMapLayer, layout: Array[String]) -> void:
	for row_idx in range(layout.size()):
		var row := layout[row_idx]
		for col_idx in range(row.length()):
			var char := row.substr(col_idx, 1)
			var cell := Vector2i(col_idx, row_idx)
			if char == "#":
				tilemap.set_cell(cell, 0, Vector2i(0, 0))
			else:
				tilemap.set_cell(cell, 1, Vector2i(0, 0))
