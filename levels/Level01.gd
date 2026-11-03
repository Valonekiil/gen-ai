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
reality_manager.character_a = get_node("CharacterA")
reality_manager.character_b = get_node("CharacterB")
reality_manager.camera_a = get_node("RealityA/CameraA")
reality_manager.camera_b = get_node("RealityB/CameraB")

var camera_director := get_node("CameraDirector")
camera_director.pip_camera = get_node("UI/PiPViewport/SubViewport/PiPCamera")
camera_director.camera_a = get_node("RealityA/CameraA")
camera_director.camera_b = get_node("RealityB/CameraB")

var ui_director := get_node("UIDirector")
ui_director.reality_label = get_node("UI/RealityIndicator")
ui_director.cooldown_bar = get_node("UI/SwitchCooldownBar")
ui_director.reality_a_root = get_node("RealityA")
ui_director.reality_b_root = get_node("RealityB")
ui_director.reality_manager = reality_manager

# Spawn Plate di Room 1A di posisi (8,7) - baris 8, kolom 7
# Posisi tile (col=8, row=7) -> world = (8*32+16, 7*32+16) = (272, 240)
var plate_node = InteractableBase.new()
plate_node.link_id = "plate_1a"
plate_node.position = Vector2(272, 240)
get_node("RealityA").add_child(plate_node)

 func _create_tileset() -> TileSet:
var tileset := TileSet.new()

# Tile 0 = Wall (coklat, collision solid)
var wall_img := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
wall_img.fill(Color(0.545, 0.353, 0.169, 1.0))  # #8B5A2B
var wall_tex := ImageTexture.create_from_image(wall_img)
tileset.create_tile(0)
tileset.tile_set_texture(0, wall_tex)

var wall_shape := RectangleShape2D.new()
wall_shape.size = Vector2(TILE_SIZE, TILE_SIZE)
tileset.tile_set_physics_shape(0, wall_shape, 0)
tileset.tile_set_navigation_layer(0, 0, false)
tileset.tile_set_occluder_layer(0, 0, false)

# Tile 1 = Floor (kuning hangat, tanpa collision)
var floor_img := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
floor_img.fill(Color(0.910, 0.784, 0.478, 1.0))  # #E8C87A
var floor_tex := ImageTexture.create_from_image(floor_img)
tileset.create_tile(1)
tileset.tile_set_texture(1, floor_tex)

return tileset

func _populate_tilemap(tilemap: TileMapLayer, layout: Array[String]) -> void:
for row_idx in range(layout.size()):
var row := layout[row_idx]
for col_idx in range(row.length()):
var char := row.substr(col_idx, 1)
var cell := Vector2i(col_idx, row_idx)
if char == "#":
tilemap.set_cell(cell, 0)
else:
tilemap.set_cell(cell, 1)
