class_name RealityManager
extends Node

enum State { RunningA, RunningB, Switching, LevelReset }
const SWITCH_COOLDOWN := 2.0

var state: State = State.RunningA
var _cooldown_timer: float = 0.0

@export var character_a: CharacterController
@export var character_b: CharacterController
@export var camera_a: Camera2D
@export var camera_b: Camera2D
@export var terrain_a: TileMapLayer
@export var terrain_b: TileMapLayer

func _process(delta: float) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta

func can_switch() -> bool:
	if _cooldown_timer > 0.0:
		return false
	if state not in [State.RunningA, State.RunningB]:
		return false
	# Realita target harus benar-benar bisa dimasuki (tidak ada tembok/collider)
	var active := "A" if state == State.RunningA else "B"
	var target := "B" if state == State.RunningA else "A"
	return not _would_collide_with_terrain(_get_char(active), _get_terrain(target))

func _would_collide_with_terrain(character: CharacterController, terrain: TileMapLayer) -> bool:
	if not character or not terrain:
		return false

	var shape_node := character.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if not shape_node or not shape_node.shape:
		return false

	var shape: Shape2D = shape_node.shape
	var shape_transform := character.global_transform * shape_node.transform

	# 1) Cek tile solid pada terrain target (sinkron, tidak bergantung timing physics)
	var rect := shape.get_rect()
	var corners := [
		rect.position,
		rect.position + Vector2(rect.size.x, 0.0),
		rect.position + rect.size,
		rect.position + Vector2(0.0, rect.size.y)
	]
	var min_x := INF
	var max_x := -INF
	var min_y := INF
	var max_y := -INF
	for c in corners:
		var lp := terrain.to_local(shape_transform * c)
		min_x = min(min_x, lp.x)
		max_x = max(max_x, lp.x)
		min_y = min(min_y, lp.y)
		max_y = max(max_y, lp.y)
	var min_cell := terrain.local_to_map(Vector2(min_x, min_y))
	var max_cell := terrain.local_to_map(Vector2(max_x, max_y))
	for x in range(min_cell.x, max_cell.x + 1):
		for y in range(min_cell.y, max_cell.y + 1):
			var td := terrain.get_cell_tile_data(Vector2i(x, y))
			if td and td.get_collision_polygons_count(0) > 0:
				return true

	# 2) Cek collider non-terrain pada realita target (pintu, crate, spike, dll.)
	var other_terrain: TileMapLayer = terrain_a if terrain == terrain_b else terrain_b
	var was_enabled := terrain.collision_enabled
	terrain.collision_enabled = true
	var space_state := terrain.get_world_2d().direct_space_state
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = shape_transform
	params.collide_with_areas = true
	params.collide_with_bodies = true
	var hits := space_state.intersect_shape(params)
	for hit in hits:
		var collider: Object = hit.collider
		if collider == character:
			continue
		if collider == terrain or collider.get_parent() == terrain or collider.owner == terrain:
			continue
		if collider == other_terrain or collider.get_parent() == other_terrain or collider.owner == other_terrain:
			continue
		terrain.collision_enabled = was_enabled
		return true
	terrain.collision_enabled = was_enabled
	return false

func request_switch() -> void:
	if _cooldown_timer > 0.0 or state not in [State.RunningA, State.RunningB]:
		return

	var previous_active: String
	var new_active: String

	if state == State.RunningA:
		previous_active = "A"
		new_active = "B"
	else:
		previous_active = "B"
		new_active = "A"

	var char := _get_char(previous_active)
	var target_terrain := _get_terrain(new_active)
	if _would_collide_with_terrain(char, target_terrain):
		print("[RealityManager] Switch diblokir: karakter bertabrakan dengan collision realita ", new_active)
		return

	state = State.Switching
	_cooldown_timer = SWITCH_COOLDOWN

	char.velocity = Vector2.ZERO
	char.set_input_enabled(false)
	char.state = CharacterController.State.INACTIVE_FROZEN

	var inactive_char := _get_char(new_active)
	inactive_char.set_input_enabled(true)
	inactive_char.state = CharacterController.State.ACTIVE_CONTROLLED

	get_node("/root/SignalBus").character_switched.emit(new_active, previous_active)

	state = State.RunningA if new_active == "A" else State.RunningB

func _get_char(reality: String) -> CharacterController:
	if reality == "A":
		return character_a
	return character_b

func _get_terrain(reality: String) -> TileMapLayer:
	if reality == "A":
		return terrain_a
	return terrain_b
