# GridTest.gd
# Unit test sederhana untuk Grid.gd (S1-03)
# Jalankan scene yang memuat skrip ini, lihat output di Godot debugger.
# Semua test harus mencetak PASS.

class_name GridTest
extends Node

func _ready() -> void:
	var failed := 0
	var lines: Array[String] = []

	# --- Test 1: world_to_grid(grid_to_world(cell)) == cell untuk 5 cell random ---
	var cells: Array[Vector2i] = [
		Vector2i(0, 0),
		Vector2i(5, -3),
		Vector2i(-2, 7),
		Vector2i(10, 10),
		Vector2i(-4, -1)
	]
	for cell in cells:
		var world := Grid.grid_to_world(cell)
		var back := Grid.world_to_grid(world)
		if back == cell:
			lines.append("PASS: roundtrip cell=" + str(cell) + " -> world=" + str(world) + " -> cell=" + str(back))
		else:
			lines.append("FAIL: roundtrip cell=" + str(cell) + " -> world=" + str(world) + " -> cell=" + str(back) + " (expected=" + str(cell) + ")")
			failed += 1

	# --- Test 2: facing_to_delta(delta_to_facing(delta)) == delta untuk 4 arah ---
	var deltas: Array[Vector2i] = [
		Vector2i(0, -1),  # UP
		Vector2i(0, 1),   # DOWN
		Vector2i(-1, 0),  # LEFT
		Vector2i(1, 0)    # RIGHT
	]
	for delta in deltas:
		var facing := Grid.delta_to_facing(delta)
		var back := Grid.facing_to_delta(facing)
		if back == delta:
			lines.append("PASS: facing roundtrip delta=" + str(delta) + " -> facing=" + str(facing) + " -> delta=" + str(back))
		else:
			lines.append("FAIL: facing roundtrip delta=" + str(delta) + " -> facing=" + str(facing) + " -> delta=" + str(back) + " (expected=" + str(delta) + ")")
			failed += 1

	# --- Test 3: is_snapped benar untuk posisi grid, salah untuk offset 20px ---
	for cell in cells:
		var grid_pos := Grid.grid_to_world(cell)
		if Grid.is_snapped(grid_pos):
			lines.append("PASS: is_snapped grid_pos=" + str(grid_pos) + " (cell=" + str(cell) + ")")
		else:
			lines.append("FAIL: is_snapped grid_pos=" + str(grid_pos) + " (cell=" + str(cell) + ") expected=true")
			failed += 1

		# Offset 20px di sumbu X (lebih dari SNAP_TOLERANCE=6.0)
		var offset_pos := grid_pos + Vector2(20.0, 0.0)
		if not Grid.is_snapped(offset_pos):
			lines.append("PASS: is_snapped offset=" + str(offset_pos) + " expected=false")
		else:
			lines.append("FAIL: is_snapped offset=" + str(offset_pos) + " expected=false")
			failed += 1

	if failed == 0:
		lines.append("=== Semua test Grid lulus ===")
	else:
		lines.append("=== " + str(failed) + " test GAGAL ===")

	# Tulis hasil ke file (bypass stdout capture issue di headless)
	var f := FileAccess.open("user://grid_test_results.txt", FileAccess.WRITE)
	if f:
		for line in lines:
			f.store_line(line)
		f.close()
		print("Test results written to user://grid_test_results.txt")

	# Auto-quit setelah test selesai
	get_tree().quit()
