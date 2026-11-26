# Door.gd
# Pintu yang bisa dibuka (sprite + collision) (Splitbound)
extends Node2D

class_name Door

var _close_sprite: Sprite2D
var _open_sprite: Sprite2D
var _collision_shape: CollisionShape2D
var _collision_body: StaticBody2D
var is_open: bool = false
var _active_reality: String = "A"

func _ready() -> void:
	_close_sprite = get_node_or_null("Close") as Sprite2D
	_open_sprite = get_node_or_null("Open") as Sprite2D
	_collision_body = get_node_or_null("Close/StaticBody2D") as StaticBody2D
	if _collision_body:
		_collision_shape = _collision_body.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if _open_sprite:
		_open_sprite.visible = false
	if _close_sprite:
		_close_sprite.visible = true
	var sb := get_node_or_null("/root/SignalBus")
	if sb:
		sb.character_switched.connect(_on_character_switched)
	_apply_reality()

# Cari realita tempat pintu ini berada (lewat ancestor bernama RealityA/RealityB)
func _get_reality() -> String:
	var n: Node = self
	while n:
		var nm := String(n.name)
		if nm == "RealityA" or nm == "RealityB":
			return nm.substr(7, 1)
		n = n.get_parent()
	return ""

# Pintu hanya menabrak saat realita tempatnya sedang aktif
func _on_character_switched(new_active: String, _previous: String) -> void:
	_active_reality = new_active
	_apply_reality()

func _apply_reality() -> void:
	if _collision_body:
		_collision_body.collision_layer = 1 if _get_reality() == _active_reality else 0

func open_door() -> void:
	if is_open:
		return
	is_open = true
	if _close_sprite:
		_close_sprite.visible = false
	if _open_sprite:
		_open_sprite.visible = true
	if _collision_shape:
		_collision_shape.set_deferred("disabled", true)
	print("[Door] Terbuka")

func close_door() -> void:
	if not is_open:
		return
	is_open = false
	if _close_sprite:
		_close_sprite.visible = true
	if _open_sprite:
		_open_sprite.visible = false
	if _collision_shape:
		_collision_shape.set_deferred("disabled", false)
	print("[Door] Tertutup")
