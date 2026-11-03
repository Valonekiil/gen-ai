# UIDirector.gd
# class_name UIDirector — dengar SignalBus, update UI (Splitbound)
# S1-07: Arsitektur §12; Mekanik v2.0 §2.5
# Hanya baca SignalBus, tidak punya logika game.

class_name UIDirector
extends Node

@export var reality_label: Label
@export var cooldown_bar: ProgressBar
@export var reality_a_root: Node2D
@export var reality_b_root: Node2D
@export var reality_manager: RealityManager

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
	if reality_manager and cooldown_bar:
		var progress := 1.0
		if reality_manager._cooldown_timer > 0.0:
			progress = 1.0 - (reality_manager._cooldown_timer / 0.25)
		cooldown_bar.value = progress * 100.0
