# Grid.gd
# class_name Grid — helper grid & facing untuk top-down puzzle (Splitbound)
# S1-03: Arsitektur §6.1 + enum Facing (per backlog S1-03)
# Tanpa logika game; murni fungsi konversi koordinat.

class_name Grid

const TILE_SIZE := 32
const SNAP_TOLERANCE := 6.0

enum Facing { UP, DOWN, LEFT, RIGHT }

static func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		floori(world_pos.x / TILE_SIZE),
		floori(world_pos.y / TILE_SIZE)
	)

static func grid_to_world(cell: Vector2i, centered: bool = true) -> Vector2:
	var base := Vector2(cell.x * TILE_SIZE, cell.y * TILE_SIZE)
	if centered:
		base += Vector2(TILE_SIZE, TILE_SIZE) * 0.5
	return base

static func is_snapped(world_pos: Vector2) -> bool:
	var snapped := grid_to_world(world_to_grid(world_pos))
	return world_pos.distance_to(snapped) < SNAP_TOLERANCE

static func facing_to_delta(facing: int) -> Vector2i:
	match facing:
		Facing.UP:    return Vector2i(0, -1)
		Facing.DOWN:  return Vector2i(0, 1)
		Facing.LEFT:  return Vector2i(-1, 0)
		Facing.RIGHT: return Vector2i(1, 0)
	return Vector2i.ZERO

static func delta_to_facing(delta: Vector2i) -> int:
	if delta.x > 0: return Facing.RIGHT
	if delta.x < 0: return Facing.LEFT
	if delta.y > 0: return Facing.DOWN
	if delta.y < 0: return Facing.UP
	return Facing.DOWN  # default
