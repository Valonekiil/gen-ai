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

# Cari realita tempat node berada (lewat ancestor bernama RealityA/RealityB)
func _reality_of(node: Node) -> String:
	var n: Node = node
	while n:
		var nm := String(n.name)
		if nm == "RealityA" or nm == "RealityB":
			return nm.substr(7, 1)
		n = n.get_parent()
	return ""

func _on_body_entered(body: Node) -> void:
	if pressed:
		return
	if not (body is CharacterController):
		return
	var reality := _reality_of(self)
	if reality_manager:
		if reality == "A" and reality_manager.state != RealityManager.State.RunningA:
			return
		if reality == "B" and reality_manager.state != RealityManager.State.RunningB:
			return
	pressed = true
	if _off_sprite:
		_off_sprite.visible = false
	if _on_sprite:
		_on_sprite.visible = true

	if target_door_path != NodePath(""):
		var door := get_node_or_null(target_door_path)
		if door and door.has_method("open_door"):
			door.open_door()
			# Resonansi hanya kalau tombol & pintu beda dimensi; sama -> UIDoor
			var door_reality := _reality_of(door)
			var sfx := "UIDoor" if door_reality == "" or door_reality == reality else "UIResonance"
			AudioManager.play_sfx(sfx)
	print("[Button] Ditekan di realita ", reality)
