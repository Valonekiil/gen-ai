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
"#......P.......#",
"#..............#",
"#............E.#",
"################",
]

# Layout Room 1B (16 kolom × 12 baris)
var LAYOUT_B: Array[String] = [
"################",
"#S.............#",
"#..............#",
"########D#######",
"#..............#",
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
var wall_shape_rid := wall_shape.get_rid()
var wall_physics := PhysicsShape2D.new()
wall_physics.shape = wall_shape_rid
tileset.tile_set_physics_shape(0, wall_physics, 0)
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
