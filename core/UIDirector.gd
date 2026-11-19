# UIDirector.gd
# class_name UIDirector — dengar SignalBus, update UI (Splitbound)
# S1-07: Arsitektur §12; Mekanik v2.0 §2.5
# Hanya baca SignalBus, tidak punya logika game.

class_name UIDirector
extends Node

@export var reality_label: Label
@export var cooldown_bar: TextureProgressBar
@export var reality_a_root: Node2D
@export var reality_b_root: Node2D
@export var reality_manager: RealityManager

# tekstur "over" simpan di sini supaya bisa di-hide/show tanpa hilang
var _over_texture: Texture2D = null

const COLOR_ACTIVE := Color(1, 1, 1)
const COLOR_INACTIVE := Color(0.6, 0.6, 0.7)
const COLOR_REALITY_A := Color(1, 0.7, 0.3)  # hangat
const COLOR_REALITY_B := Color(0.3, 0.7, 1)  # dingin

func _ready() -> void:
	get_node("/root/SignalBus").character_switched.connect(_on_character_switched)
	if reality_label:
		_update_ui("A")

func _on_character_switched(new_active: String, _previous: String) -> void:
	_update_ui(new_active)

func _update_ui(new_active: String) -> void:
	if not reality_label:
		return
	# Update label
	if new_active == "A":
		reality_label.text = "REALITA A"
		reality_label.modulate = COLOR_REALITY_A
	else:
		reality_label.text = "REALITA B"
		reality_label.modulate = COLOR_REALITY_B

	# Desaturasi realita inactive via CanvasModulate (per Node2D root realita)
	if reality_a_root and reality_b_root:
		if new_active == "A":
			reality_a_root.modulate = COLOR_ACTIVE
			reality_b_root.modulate = COLOR_INACTIVE
		else:
			reality_a_root.modulate = COLOR_INACTIVE
			reality_b_root.modulate = COLOR_ACTIVE

func _process(delta: float) -> void:
	if not cooldown_bar:
		return

	var timer := 0.0
	var can_switch_now := true
	if reality_manager:
		timer = reality_manager._cooldown_timer
		can_switch_now = reality_manager.can_switch()

	# Bar terisi seiring cooldown berjalan; penuh saat cooldown selesai
	var max_cd := RealityManager.SWITCH_COOLDOWN
	var progress := 1.0
	if timer > 0.0 and max_cd > 0.0:
		progress = 1.0 - clamp(timer / max_cd, 0.0, 1.0)
	cooldown_bar.value = progress * cooldown_bar.max_value

	# texture_over hanya terlihat saat player bisa berpindah dimensi
	if cooldown_bar.texture_over and _over_texture == null:
		_over_texture = cooldown_bar.texture_over
	cooldown_bar.texture_over = _over_texture if can_switch_now else null
