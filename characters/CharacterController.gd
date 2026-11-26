# CharacterController.gd — update: tambah deteksi Tab/Q untuk switch realita
# class_name CharacterController — gerak 4-arah, facing, state karakter (Splitbound)
# S1-04: Arsitektur §4, §18; Mekanik v2.0 §2.2
# Tanpa gravity, tanpa jump, tanpa is_on_floor().

class_name CharacterController
extends CharacterBody2D

@export var SPEED := 800.0

enum State { ACTIVE_CONTROLLED, INACTIVE_FROZEN, INACTIVE_ON_MOVING_SURFACE, REPOSITIONING, DEAD }
enum Facing { UP, DOWN, LEFT, RIGHT }

# Aset sprite menghadap (RIGHT memakai sprite LEFT + flip horizontal)
const FACING_DOWN_PATH := "res://Assets/sprites/FacingDown.png"
const FACING_TOP_PATH := "res://Assets/sprites/FacingTop.png"
const FACING_LEFT_PATH := "res://Assets/sprites/FacingLeft.png"

var state: State = State.ACTIVE_CONTROLLED
var facing: Facing = Facing.DOWN
var reality: String = "A"
var input_enabled: bool = true

var _last_axis: String = ""
var _facing_textures: Dictionary = {}

func _ready() -> void:
	var listener := get_node_or_null("AudioListener2D") as AudioListener2D
	if listener:
		listener.make_current()
	_facing_textures[Facing.DOWN] = load(FACING_DOWN_PATH)
	_facing_textures[Facing.UP] = load(FACING_TOP_PATH)
	_facing_textures[Facing.LEFT] = load(FACING_LEFT_PATH)
	if not _has_sprite_child():
		var sprite := Sprite2D.new()
		sprite.name = "SpritePlaceholder"
		var img := Image.create(24, 24, false, Image.FORMAT_RGBA8)
		img.fill(Color(1, 1, 1, 1))
		var tex := ImageTexture.create_from_image(img)
		sprite.texture = tex
		add_child(sprite)
	_update_facing_sprite()

func _input(event: InputEvent) -> void:
	if not input_enabled or state != State.ACTIVE_CONTROLLED:
		return
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_W, KEY_UP:    _last_axis = "y"
			KEY_S, KEY_DOWN:  _last_axis = "y"
			KEY_A, KEY_LEFT:  _last_axis = "x"
			KEY_D, KEY_RIGHT: _last_axis = "x"
			KEY_TAB, KEY_Q:
				get_tree().current_scene.get_node("RealityManager").request_switch()

func _physics_process(delta: float) -> void:
	if state != State.ACTIVE_CONTROLLED or not input_enabled:
		velocity = Vector2.ZERO
		return

	var input_dir := _get_input_dir()
	velocity = Vector2(input_dir.x, input_dir.y) * SPEED
	move_and_slide()

	if input_dir != Vector2i.ZERO:
		var new_facing := Grid.delta_to_facing(input_dir)
		if new_facing != facing:
			facing = new_facing
			_update_facing_sprite()
			get_node("/root/SignalBus").character_facing_changed.emit(reality, int(facing))

# Ganti sprite sesuai arah hadap; RIGHT = sprite LEFT di-flip horizontal
func _update_facing_sprite() -> void:
	var sprite := _get_sprite()
	if not sprite:
		return
	var tex: Texture2D = null
	var flip := false
	match facing:
		Facing.UP:
			tex = _facing_textures.get(Facing.UP)
		Facing.LEFT:
			tex = _facing_textures.get(Facing.LEFT)
		Facing.RIGHT:
			tex = _facing_textures.get(Facing.LEFT)
			flip = true
		_:
			tex = _facing_textures.get(Facing.DOWN)
	if tex:
		sprite.texture = tex
	sprite.flip_h = flip

func _get_sprite() -> Sprite2D:
	for child in get_children():
		if child is Sprite2D:
			return child
	return null

func _get_input_dir() -> Vector2i:
	var dir := Vector2i.ZERO
	var has_x := _action_pressed("move_left", "ui_left") or _action_pressed("move_right", "ui_right")
	var has_y := _action_pressed("move_up", "ui_up") or _action_pressed("move_down", "ui_down")

	if has_x and has_y:
		if _last_axis == "x":
			has_y = false
		else:
			has_x = false

	if has_x:
		if _action_pressed("move_right", "ui_right"):
			dir.x = 1
		elif _action_pressed("move_left", "ui_left"):
			dir.x = -1
	if has_y:
		if _action_pressed("move_down", "ui_down"):
			dir.y = 1
		elif _action_pressed("move_up", "ui_up"):
			dir.y = -1

	return dir

func _action_pressed(action: String, fallback: String) -> bool:
	var res := Input.is_action_pressed(action) if InputMap.has_action(action) else Input.is_action_pressed(fallback)
	return res

func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled
	if not enabled:
		velocity = Vector2.ZERO

func is_position_valid() -> bool:
	# Stub per S1-04 — validasi lengkap (wall, objek solid, spike) di S4-01
	return true

func _has_sprite_child() -> bool:
	for child in get_children():
		if child is Sprite2D:
			return true
	return false
