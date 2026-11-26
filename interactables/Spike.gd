extends Area2D

# Interval (detik): lama spike terlihat (ON) dan tersembunyi (OFF)
@export var visible_interval: float = 1.0
@export var invisible_interval: float = 1.0

@onready var sprite_on: Sprite2D = $ON
@onready var sprite_off: Sprite2D = $OFF
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _is_visible: bool = true
var _time_left: float = 0.0
var _initialized: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_apply_state(true)
	_time_left = visible_interval

func _process(delta: float) -> void:
	_time_left -= delta
	if _time_left > 0.0:
		return
	if _is_visible:
		_apply_state(false)
		_time_left = invisible_interval
	else:
		_apply_state(true)
		_time_left = visible_interval

# Terapkan state ON/OFF: sprite, monitoring, dan collision shape mengikuti
func _apply_state(value: bool) -> void:
	_is_visible = value
	sprite_on.visible = value
	sprite_off.visible = not value
	# monitoring/collision di-deferred supaya aman saat dipanggil dari physics callback
	set_deferred("monitoring", value)
	collision_shape.set_deferred("disabled", not value)
	if value:
		# Pop hanya saat transisi OFF->ON (bukan saat scene baru dimuat),
		# dan hanya jika realitas spike ini sedang aktif.
		if _initialized and is_visible_in_tree():
			AudioManager.play_sfx_2d("SpikePop", global_position)
		_initialized = true
		# Saat spike muncul, pemain yang sudah di area langsung kalah
		_check_overlap_now()

# Cek pemain yang sudah berada di area tepat saat spike terlihat
func _check_overlap_now() -> void:
	var shape := collision_shape.shape
	if shape == null:
		return
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = collision_shape.global_transform
	params.collision_mask = collision_mask
	params.collide_with_bodies = true
	params.collide_with_areas = false
	var hits := get_world_2d().direct_space_state.intersect_shape(params, 16)
	for hit in hits:
		if hit.collider is CharacterController:
			_lose()
			return

func _on_body_entered(body: Node2D) -> void:
	if not _is_visible:
		return
	if body is CharacterController:
		_lose()

func _lose() -> void:
	# Suara kena spike + suara kalah, keduanya bersifat 2D di posisi spike
	AudioManager.play_sfx_2d("SpikePop", global_position)
	AudioManager.play_sfx_2d("Death", global_position)
	# Cegah trigger berulang
	set_process(false)
	set_deferred("monitoring", false)
	collision_shape.set_deferred("disabled", true)
	print("[Spike] Pemain kalah — reload scene")
	# Reload scene saat ini (mempermudah testing)
	if get_tree().current_scene:
		get_tree().call_deferred("reload_current_scene")
