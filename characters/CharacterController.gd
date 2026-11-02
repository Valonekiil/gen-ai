# CharacterController.gd
# class_name CharacterController — gerak 4-arah, facing, state karakter (Splitbound)
# S1-04: Arsitektur §4, §18; Mekanik v2.0 §2.2
# Tanpa gravity, tanpa jump, tanpa is_on_floor().

class_name CharacterController
extends CharacterBody2D

const SPEED := 200.0

enum State { ACTIVE_CONTROLLED, INACTIVE_FROZEN, INACTIVE_ON_MOVING_SURFACE, REPOSITIONING, DEAD }
enum Facing { UP, DOWN, LEFT, RIGHT }

var state: State = State.ACTIVE_CONTROLLED
var facing: Facing = Facing.DOWN
var reality: String = "A"
var input_enabled: bool = true

var _last_axis: String = ""

func _ready() -> void:
if not _has_sprite_child():
var sprite := Sprite2D.new()
sprite.name = "SpritePlaceholder"
var img := Image.create(24, 24, false, Image.FORMAT_RGBA8)
img.fill(Color(1, 1, 1, 1))
var tex := ImageTexture.create_from_image(img)
sprite.texture = tex
add_child(sprite)

func _input(event: InputEvent) -> void:
if not input_enabled or state != State.ACTIVE_CONTROLLED:
return
if event is InputEventKey and event.pressed:
match event.keycode:
KEY_W, KEY_UP:    _last_axis = "y"
KEY_S, KEY_DOWN:  _last_axis = "y"
KEY_A, KEY_LEFT:  _last_axis = "x"
KEY_D, KEY_RIGHT: _last_axis = "x"

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
SignalBus.character_facing_changed.emit(reality, int(facing))

func _get_input_dir() -> Vector2i:
var dir := Vector2i.ZERO
var has_x := Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right")
var has_y := Input.is_action_pressed("move_up") or Input.is_action_pressed("move_down")

if has_x and has_y:
if _last_axis == "x":
has_y = false
else:
has_x = false

if has_x:
if Input.is_action_pressed("move_right"):
dir.x = 1
elif Input.is_action_pressed("move_left"):
dir.x = -1
if has_y:
if Input.is_action_pressed("move_down"):
dir.y = 1
elif Input.is_action_pressed("move_up"):
dir.y = -1

return dir

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
