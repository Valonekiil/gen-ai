extends Area2D

# Bintang koleksi. Realitas diambil otomatis dari ancestor RealityA/RealityB
# supaya tidak perlu mengisi @export satu per satu di scene.
# @export reality dipakai sebagai fallback kalau tidak ada ancestor.
@export var reality: String = "A"

var _own_reality: String = "A"
var _taken: bool = false

func _ready() -> void:
	_own_reality = _detect_reality()
	body_entered.connect(_on_body_entered)
	# monitoring sengaja dibiarkan aktif: mengaktifkannya lagi setelah
	# dinonaktifkan tidak selalu membuat Area2D mendeteksi body yang masuk.
	# Penentuan realitas aktif dilakukan lewat is_visible_in_tree().
	monitoring = true
	var sb := get_node_or_null("/root/SignalBus")
	if sb:
		sb.character_switched.connect(_on_character_switched)

func _process(_delta: float) -> void:
	# Cadangan: pada node yang pernah DINONAKTIFKAN lewat process_mode,
	# body_entered bisa gagal dipancarkan. Cek eksplisit tetap aman.
	if not _taken and is_visible_in_tree():
		_check_overlap_now()

func _detect_reality() -> String:
	var n: Node = self
	while n:
		var nm := String(n.name)
		if nm == "RealityA" or nm == "RealityB":
			return nm.substr(7, 1)
		n = n.get_parent()
	return reality

func _on_character_switched(new_active: String, _previous: String) -> void:
	if new_active == _own_reality and not _taken:
		# Pemain bisa saja sudah berdiri di atas bintang saat realita aktif;
		# body_entered tidak akan terpicu dalam kasus itu.
		call_deferred("_check_overlap_now")

func _check_overlap_now() -> void:
	if _taken or not is_visible_in_tree():
		return
	var cs := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs == null or cs.shape == null:
		return
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = cs.shape
	params.transform = cs.global_transform
	params.collision_mask = collision_mask
	params.collide_with_bodies = true
	params.collide_with_areas = false
	var hits: Array = get_world_2d().direct_space_state.intersect_shape(params, 16)
	for hit in hits:
		if hit.get("collider") is CharacterController:
			_collect()
			return

func _on_body_entered(body: Node2D) -> void:
	if _taken or not is_visible_in_tree():
		return
	if body is CharacterController:
		_collect()

func _collect() -> void:
	if _taken:
		return
	_taken = true
	set_deferred("monitoring", false)
	var sb := get_node_or_null("/root/SignalBus")
	if sb:
		sb.star_collected.emit()
	queue_free()
