# Plate.gd
# Plate momentary — aktif selama ada weight di atasnya (Splitbound)
# S2-01: Mekanik v2.0 §3.2, §3.4; Arsitektur §4

class_name Plate
extends InteractableBase

func _ready() -> void:
# Tambah Area2D untuk deteksi
var area := Area2D.new()
area.name = "DetectionArea"
area.position = Vector2(0, 0)
area.scale = Vector2(32, 32)
add_child(area)

# Connect area entered/exited
area.input_event.connect(_on_input_event)

func _on_input_event(node: Node, event: InputEvent) -> void:
if node.name == "DetectionArea":
if event is InputEvent2D:
# Cek apakah yang masuk adalah CharacterController
if node.path.contains("CharacterController") or    node.is_in_group("character_controller"):
_pressed_toggled()

func _pressed_toggled() -> void:
pressed = not pressed
# Visual feedback (placeholder)
print(f"Plate {'pressed' if pressed else 'released'} (link_id={link_id})")
_emit_link_request()
