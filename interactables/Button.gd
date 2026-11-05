# Button.gd
# Tombol one-shot (Splitbound)
extends Area2D

class_name ButtonInteract

var _off_sprite: Sprite2D
var _on_sprite: Sprite2D
var pressed: bool = false

@export var target_door_path: NodePath
@export var reality_manager: RealityManager

func _ready() -> void:
	_off_sprite = get_node_or_null("OFF") as Sprite2D
	_on_sprite = get_node_or_null("ON") as Sprite2D
	if _on_sprite:
		_on_sprite.visible = false
	if _off_sprite:
		_off_sprite.visible = true
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if pressed:
		return
	if not (body is CharacterController):
		return
	# Hanya aktif di realita kedua (B)
	if reality_manager and reality_manager.state != RealityManager.State.RunningB:
		return
	pressed = true
	if _off_sprite:
		_off_sprite.visible = false
	if _on_sprite:
		_on_sprite.visible = true
	# Buka pintu target
	if target_door_path != NodePath(""):
		var door := get_node_or_null(target_door_path)
		if door and door.has_method("open_door"):
			door.open_door()
	print("[Button] Ditekan")
